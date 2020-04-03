diff -ur gamess_orig/comp gamess/comp
--- gamess_orig/comp	2019-10-01 21:36:13.000000000 +0900
+++ gamess/comp	2020-04-03 09:50:36.000000000 +0900
@@ -2336,7 +2336,7 @@
 #     -WB means warn but don't fail on out-of-bounds array references
 #     -ftz flushes underflow results to zero
 #
-      set OPT = '-O2'
+      set OPT = '-xHOST -O2'
       if (".$GMS_DEBUG_FLAGS" != .) set OPT="$GMS_DEBUG_FLAGS"
 #       alas, I'm so tired of hearing about so many versions failing to
 #       diagonalize, that this time critical code is run w/o optimization.
@@ -3291,9 +3291,12 @@
          case 8.1:
          case 8.2:
          case 8.3:
+         case 8.4:
             set EXTRAOPT="$EXTRAOPT -w -fno-aggressive-loop-optimizations -funconstrained-commons"
             breaksw
          case 9.1:
+         case 9.2:
+         case 9.3:
             set EXTRAOPT="$EXTRAOPT -w -fno-aggressive-loop-optimizations -funconstrained-commons"
             breaksw
          default:
@@ -3303,7 +3306,7 @@
       endsw
 
       set echo
-      gfortran -c -m64 -fdefault-integer-8 $GMS_FPE_FLAGS $OPT $EXTRAOPT $MODULE_F
+      %%FORTRAN%% -c -m64 -fdefault-integer-8 $GMS_FPE_FLAGS $OPT $EXTRAOPT $MODULE_F
       unset echo
       breaksw
 
diff -ur gamess_orig/compall gamess/compall
--- gamess_orig/compall	2019-10-01 21:36:13.000000000 +0900
+++ gamess/compall	2020-04-03 09:50:36.000000000 +0900
@@ -385,9 +385,7 @@
 ./comp mod_dft_molgrid
 ./comp mod_dft_fuzzycell
 ./comp mod_dft_gridint
-#
-# gamess-modules-end-section
-#
+cat << EOF > __comp
 ./comp aldeci
 ./comp algnci
 ./comp basccn
@@ -701,6 +699,8 @@
 ./comp zapddi
 ./comp zheev
 ./comp zmatrx
+EOF
+cat __comp | awk '{print $2}' | parallel -j4 -a - 'csh ./comp {}'
 #
 # gamess-base-end-section
 #
@@ -708,6 +708,7 @@
 # msu-cc-start-section
 #
 if ($GMS_MSUCC == true) then
+cat << EOF > __comp
 ./comp ccsd3aacgreorder
 ./comp ccsd3aacgsum
 ./comp ccsd3aacgt1A00
@@ -832,6 +833,8 @@
 ./comp ccsd3aacgt3D111110
 ./comp ccsd3aacgt3D111111
 ./comp ccsd3amain
+EOF
+cat __comp | awk '{print $2}' | parallel -j4 -a - 'csh ./comp {}'
 else
 ./comp stubcc3
 endif

diff -ur gamess_orig/lked gamess/lked
--- gamess_orig/lked	2019-10-01 21:36:13.000000000 +0900
+++ gamess/lked	2020-04-03 09:50:36.000000000 +0900
@@ -497,6 +497,12 @@
       set BLAS=' '
       breaksw
 
+   case openblas
+      #     do a static link so that only compile node needs to install ACML
+      set MATHLIBS="$GMS_MATHLIB_PATH/libopenblas.a"
+      set BLAS=' '
+      breaksw
+
    case none:
    default:
       echo "Warning.  No math library was found, you should install one."
@@ -871,6 +877,10 @@
          endsw
          breaksw
    endsw
+   set BLAS=' '
+   set MATHLIBS="-L$GMS_MATHLIB_PATH -lopenblas"
+   set LIBRARIES=''
+   if ($GMS_OPENMP == true) set LDOPTS="$LDOPTS -fopenmp"
    set VECTOR=' '
    set QUICHE='zunix.o'
 endif
diff -ur gamess_orig/rungms gamess/rungms
--- gamess_orig/rungms	2019-10-01 21:36:13.000000000 +0900
+++ gamess/rungms	2020-04-03 09:50:36.000000000 +0900
@@ -62,9 +62,9 @@
 #       See also a very old LoadLeveler "ll-gms" for some IBM systems.
 #
 set TARGET=sockets
-set SCR=/scr1/$USER
-set USERSCR=~/gamess-devv
-set GMSPATH=~/gamess-devv
+set SCR=.
+set USERSCR=.
+set GMSPATH=/home/maho/freeenergy/gamess
 #
 set JOB=$1      # name of the input file xxx.inp, give only the xxx part
 set VERNO=$2    # revision number of the executable created by 'lked' step
@@ -77,7 +77,7 @@
 #  ---- the top third of the script is input and other file assignments ----
 #
 echo "----- GAMESS execution script 'rungms' -----"
-set master=`hostname`
+set master=localhost
 echo This job is running on host $master
 echo under operating system `uname` at `date`
 #
@@ -358,7 +358,18 @@
 #       2. Sequential execution is sure to be on this very same host
    if ($NCPUS == 1) then
       set NNODES=1
-      set HOSTLIST=(`hostname`)
+      set HOSTLIST=localhost
+   endif
+   if ($NCPUS >= 1) then
+      set NNODES=$NCPUS
+      set HOST=localhost
+      set HOSTLIST=$HOST
+      @ CPU=1
+      while ($CPU < $NNODES)
+         set HOSTLIST=($HOSTLIST $HOST)
+         @ CPU++
+      end
+      unset $CPU
    endif
 #
 #       3. This is an example of how to run on a multi-core SMP enclosure,

--- gamess_orig/ddi/src/shmem_ipc.c	2019-10-01 21:36:13.000000000 +0900
+++ gamess/ddi/src/shmem_ipc.c	2020-04-03 13:45:25.000000000 +0900
@@ -292,7 +292,7 @@
     fprintf(stdout,"error value=%i\n",iret);
     fflush(stdout);
     Fatal_error(911);
-    return; /* never returns */
+    return 0; /* never returns */
   }
   return iret;
 }
