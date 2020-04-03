#!/bin/bash

# compiling GAMESS on macOS catalina

# some settings
TOPDIR=/Volumes/work/gamess
WRKDIR=$TOPDIR/work_gamess
GAMESSVERSION=20190930.R2
NAME=GAMESS-${GAMESSVERSION}
INSTALLDIR=/opt/gamess/
# solve dependencies 
sudo port install openblas
sudo port install gcc8
sudo port install gsed

# settings
OPENMP=true
NUMOFJOBS=4
FORTRAN=gfortran
GFORTRANVERSION=8.4
######################
rm -rf $WRKDIR
mkdir -p $WRKDIR
mkdir -p $WRKDIR/bin
ln -s /opt/local/bin/gfortran-mp-8 $TOPDIR/work_gamess/bin/gfortran
export PATH=$TOPDIR/work_gamess/bin:$PATH
cd $WRKDIR
tar xvfz $TOPDIR/$GAMESSVERSION/gamess-current.tar.gz
mv gamess gamess_orig
tar xvfz $TOPDIR/$GAMESSVERSION/gamess-current.tar.gz
cd gamess
###########
patch -p1 < $TOPDIR/$GAMESSVERSION/patch-gamess.${GAMESSVERSION}
cp $TOPDIR/$GAMESSVERSION/install.info_mac64 install.info

#######################################
gsed -i "s|%%GAMESS_BUILD_DIR%%|$WRKDIR|g"         install.info
gsed -i "s|%%OPENMP%%|$OPENMP|g"                   install.info
gsed -i "s|%%FORTRAN%%|$FORTRAN|g"                 install.info
gsed -i "s|%%GFORTRANVERSION%%|$GFORTRANVERSION|g" install.info
gsed -i "s|%%GFORTRANVERSION%%|$GFORTRANVERSION|g" install.info
gsed -i "s|%%FORTRAN%%|$FORTRAN|g"                 comp
gsed -i "s|%%FORTRAN%%|$FORTRAN|g"                 lked
gsed -i "s|%%NUMOFJOBS%%|$NUMOFJOBS|g"             compall
#######################################

cd tools
cp actvte.code actvte.f
sed -e "s/^\*UNX/    /" actvte.code > actvte.f
$FORTRAN -o actvte.x actvte.f
cd ..

csh -x ./compall 

cd ddi ; ./compddi ; cp ddikick.x ..; cd ..
csh ./lked gamess 00

# installation
cd $WRKDIR/gamess
sudo rm -rf $INSTALLDIR
sudo mkdir -p $INSTALLDIR
gsed -i "s|set GMSPATH.*|set GMSPATH=$INSTALLDIR|g" rungms
sudo cp rungms $INSTALLDIR
sudo cp ddikick.x $INSTALLDIR
sudo cp gamess.00.x $INSTALLDIR
sudo cp gms-files.csh $INSTALLDIR
sudo cp -r auxdata $INSTALLDIR
