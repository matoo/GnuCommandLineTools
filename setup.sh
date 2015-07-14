#!/bin/bash
#set -x # devel

VERSION="1.3"
BASEDIR=$(dirname $0)
if [ $(echo $BASEDIR | cut -c 1) == '.' ];then
  BASEDIR=$PWD/$(dirname $0)
fi
PREFIX="/Users/devel/Prefix" #/Library/Developer/GnuCommandLineTools
COMMANDLINETOOLS=/Library/Developer/CommandLineTools
TMPDIR=/tmp/GnuCommandLineTools
SRCDIR=$TMPDIR/src
PATCHDIR=$TMPDIR/patch
TESTDIR=$TMPDIR/test
TOOLCHAIN=$TMPDIR/toochain
WORKBENCH=$TMPDIR/workbench

OLDPATH=$PATH
OLDCFLAGS=$CFLAGS
OLDCXXFLAGS=$CXXFLAGS
OLDCPPFLAGS=$CPPFLAGS
OLDLDFLAGS=$LDFLAGS
PATH="$TOOLCHAIN/usr/bin:/bin:/sbin:/usr/bin:/usr/sbin"
CFLAGS="-I$TOOLCHAIN/include"
CXXFLAGS="-I$TOOLCHAIN/include"
CPPFLAGS=""
LDFLAGS="-L$TOOLCHAIN/lib"

usage()
{
  echo "Usage:"
  echo "Install:   # sh INSTALLER.sh"
  echo "Uninstall: # sh INSTALLER.sh -u"
  echo "You must execute as root user"
  exit 0
}

trap_err()
{
  #uninstall
  exit 1
}
trap 'trap_err' SIGHUP SIGINT SIGTERM ERR

uninstall()
{
  pushd $BASEDIR/script 1>/dev/null
  #sh pkgconfig.sh $TMPDIR $TMPDIR/toolchain/usr 1 1>/dev/null
  #sh cctools.sh $TMPDIR $TMPDIR/toolchain 1 1>/dev/null
  #sh libtool.sh $TMPDIR $TMPDIR/toolchain/usr 1 1>/dev/null
  #sh autoconf.sh $TMPDIR $TMPDIR/toolchain/usr 1 1>/dev/null
  #sh automake.sh $TMPDIR $TMPDIR/toolchain/usr 1 1>/dev/null
  #sh gmp.sh $BASEDIR $WORKBENCH $TOOLCHAIN uninstall 1>/dev/null
  #sh mpfr.sh $BASEDIR $WORKBENCH $TOOLCHAIN uninstall 1>/dev/null
  #sh mpc.sh $BASEDIR $WORKBENCH $TOOLCHAIN uninstall 1>/dev/null
  #sh isl.sh $BASEDIR $WORKBENCH $TOOLCHAIN uninstall 1>/dev/null
  #sh cloog.sh $BASEDIR $WORKBENCH $TOOLCHAIN uninstall 1>/dev/null
  #sh gcc.sh $BASEDIR $TOOLCHAIN $WORKBENCH $PREFIX uninstall 1>/dev/null
  #test -L /usr/local/bin/gcc-ar && rm -v /usr/local/bin/gcc-ar
  #test -L /usr/local/bin/gcc-nm && rm -v /usr/local/bin/gcc-nm
  #test -L /usr/local/bin/gcc-ranlib && rm -v /usr/local/bin/gcc-ranlib
  #test -L /usr/local/bin/gcj && rm -v /usr/local/bin/gcj
  #test -L /usr/local/bin/gfortran && rm -v /usr/local/bin/gfortran
  test -d $TMPDIR && rm -rf $TMPDIR
  test -d $PREFIX && rm -rf $PREFIX
  popd 1>/dev/null
}

preparation ()
{
  test ! -d $TMPDIR && mkdir -p $TMPDIR
  test ! -d $SRCDIR && mkdir -p $SRCDIR
  test ! -d $PATCHDIR && mkdir -p $PATCHDIR
  test ! -d $TESTDIR && mkdir -p $TESTDIR
  test ! -d $TOOLCHAIN && mkdir -p $TOOLCHAIN/usr
  test ! -d $WORKBENCH && mkdir -p $WORKBENCH
  cp -r $BASEDIR/patch/* $PATCHDIR
  cp -r $BASEDIR/test/* $TESTDIR
  export PATH=$PATH
  export CFLAGS=$CFLAGS
  export CXXFLAGS=$CXXFLAGS
  export CPPFLAGS=$CPPFLAGS
  export LDFLAGS=$LDFLAGS
  echo "Setup $PREFIX Environmnet"
  if [ ! -d $COMMANDLINETOOLSPATH ]; then
    echo 'Installing CommandLineTools'
    xcode-select install
  fi
  rsync -lru --delete $COMMANDLINETOOLS/* $PREFIX
  pushd $PREFIX/usr/bin 1>/dev/null
  mv gcc gcc_llvm
  mv cpp cpp_llvm
  rm -f cc c++ g++ gcov # these are symbolic links
  popd 1>/dev/null
}

# main
while getopts "hu" OPT; do
  case $OPT in
    h) usage ;;
    u) uninstall; exit 1;;
  esac
done

if [ "$1" = "uninstall" ]; then
  export PATH=$OLDPATH
  uninstall
  exit 0
fi

preparation
pushd $BASEDIR/script 1>/dev/null
sh pkgconfig.sh $TMPDIR $TOOLCHAIN/usr 0
#sh cctools.sh $TMPDIR $TOOLCHAIN/USR 0
#sh libtool.sh $TMPDIR $TOOLCHAIN/usr 0
#sh autoconf.sh $TMPDIR $TOOLCHAIN/usr 0
#sh autoconf.sh $TMPDIR $TOOLCHAIN/usr 0
#sh gmp.sh $TMPDIR $TOOLCHAIN 0
#sh mpfr.sh $TMPDIR $TOOLCHAIN 0
#sh mpc.sh $TMPDIR $TOOLCHAIN 0
#sh isl.sh $TMPDIR $TOOLCHAIN 0
#sh ecj.sh $TMPDIR $PREFIX 0
#sh gcc.sh $TMPDIR $PREFIX 0
popd 1>/dev/null
