a script to compile GAMESS [1] on macOS catalina

[1] https://www.msg.chem.iastate.edu/gamess/

Installation

# prerequisties
macports

# checkout

git clone git clone https://github.com/nakatamaho/gamess-macos

# source code

place 20190930.R2 version of gamess-current.tar.gz to 20190930.R2

# adjust directories and settings

edit and adjust install_gamess.sh for your environment

4. by default, gamess is installed at /opt/gamess

5. rungms

$ export PATH=/opt/gamess:$PATH

$ rungms test01.inp
