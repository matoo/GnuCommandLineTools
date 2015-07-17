#!/bin/bash
set -x # devel

PROGRAMNAME="gcc-5.1.0"
ARCHIVENAME="$PROGRAMNAME.tar.bz2"
MIRRORURL="https://ftp.gnu.org/gnu/gcc/gcc-5.1.0/$ARCHIVENAME"

TMPDIR=$1  # e.g. /tmp/GnuCommandLineTools
PREFIX=$2  # e.g. /Library/Developer/GnuCommandLineTools/
MODE=$3    # 0:install 1:uninstall
SRCDIR=$TMPDIR/src
PATCHDIR=$TMPDIR/patch/$PROGRAMNAME
TESTDIR=$TMPDIR/test/$PROGRAMNAME
WORKBENCH=$TMPDIR/workbench
TOOLCHAIN=$TMPDIR/toolchain

declare -a CONFIGURE_ARGS=(
  --prefix=$PREFIX
  --enable-languages=c,c++,fortran,java,objc,obj-c++
  --with-gmp=$TOOLCHAIN
  --with-mpfr=$TOOLCHAIN
  --with-mpc=$TOOLCHAIN
  --with-isl=$TOOLCHAIN
  --with-ecj-jar=$PREFIX/share/java/ecj.jar
  --with-system-zlib
  --enable-stage1-checking
  --enable-libstdcxx-time=yes
  --enable-checking=release
  --enable-lto
  --disable-werror
  --enable-plugin
  --disable-multilib
  --with-as=$TOOLCHAIN/usr/bin/as
  --with-ld=$(which ld)
  --with-ar=$TOOLCHAIN/usr/bin/ar
  CC=$(which clang)
  CXX=$(which clang++)
  AR_FOR_TARGET=$TOOLCHAIN/usr/bin/ar 
  AS_FOR_TARGET=$TOOLCHAIN/usr/bin/as
  LD_FOR_TARGET=$(which ld)
  NM_FOR_TARGET=$TOOLCHAIN/usr/bin/nm
  OBJDUMP_FOR_TARGET=$(which objdump)
  RANLIB_FOR_TARGET=$TOOLCHAIN/usr/bin/ranlib
  STRIP_FOR_TARGET=$TOOLCHAIN/usr/bin/strip
  OTOOL=$TOOLCHAIN/usr/bin/otool
  OTOOL64=$TOOLCHAIN/usr/bin/otool
)
MAKE_ARGS="-j $(sysctl -n machdep.cpu.core_count)"

trap_signal()
{
  echo "$0: Catch a signal"
  uninstall
  exit 1
}

trap_error()
{
  local LINENO=$1
  echo "$0: Error at $LINENO"
  uninstall
  exit 2
}
trap 'trap_signal' SIGHUP SIGINT SIGTERM
trap 'trap_error $LINENO' ERR

uninstall()
{
  if [ ! -d $WORKBENCH/$PROGRAMNAME ]; then
    echo "$PROGRAMNAME is already uninstalled"
    return 0
  fi

  pushd $WORKBENCH/$PROGRAMNAME 1>/dev/null
  if [ -r Makefile ]; then
    echo "Uninstalling $PROGRAMNAME"
    make uninstall \
    1>/dev/null 2>/dev/null
    if [ ! $? -eq 0 ]; then
      echo "Failed to uninstall"
      return 1
    fi
  fi
  popd 1>/dev/null

  pushd $WORKBENCH 1>/dev/null
  if [ -d $PROGRAMNAME ]; then
    echo "Removing $PROGRAMNAME from workbench directory"
    rm -rf $PROGRAMNAME
  fi
  popd 1>/dev/null

  return 0
}

preparation()
{
  if [ ! -r $SRCDIR/$ARCHIVENAME ]; then
    pushd $SRCDIR 1>/dev/null
    echo "Downloading $ARCHIVENAME"
    curl -fSsLO $MIRRORURL
    if  [ ! $? -eq 0 ]; then
      echo "Failed to download $ARCHIVENAME"
      return 1
    fi
    popd 1>/dev/null
  fi
  echo "Prepare to build $PROGRAMNAME"
  pushd $WORKBENCH 1>/dev/null
  tar xf $SRCDIR/$ARCHIVENAME
  if [ ! $? -eq 0 ]; then
    echo "Failed to extract $ARCHIVENAME"
    return 2
  fi
  popd 1>/dev/null
  return 0
}

post_install()
{
  pushd $TESTDIR 1>/dev/null
  echo "Testing $PROGRAMNAME"
  $PREFIX/bin/gcc test-c.c -o test-c 1>/dev/null 2>/dev/null &&
  $PREFIX/bin/g++ test-cxx.cxx -o test-cxx 1>/dev/null 2>/dev/null &&
  $PREFIX/bin/gfortran test-f90.f90 -c &&
  $PREFIX/bin/gfortran test-f90.o -o test-f90 &&
  ./test-c 1>/dev/null &&
  ./test-cxx 1>/dev/null &&
  ./test-f90 1>/dev/null
  if [ $? -ne 0 ]; then
    echo "Failed to test $PROGRAMNAME"
    return 1
  fi
  popd 1>/dev/null
}

# main
if [ $MODE -eq 1 ]; then
  uninstall
  exit 0
fi

if [ -d $WORKBENCH/$PROGRAMNAME ]; then
  echo "$PROGRAMNAME is already installed."
  exit 0
fi

preparation
pushd $WORKBENCH/$PROGRAMNAME 1>/dev/null
for p in $(ls $PATCHDIR); do
  patch -p0 < $PATCHDIR/$p 1>/dev/null
done

echo "Configuring $PROGRAMNAME"
./configure ${CONFIGURE_ARGS[@]} \
1>/dev/null 2>/dev/null

echo "Building $PROGRAMNAME"
make bootstrap $MAKE_ARGS \
1>/dev/null 2>/dev/null

echo "Installing $PROGRAMNAME"
make install \
1>/dev/null 2>/dev/null

post_install
popd 1>/dev/null
