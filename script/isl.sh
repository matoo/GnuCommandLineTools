#!/bin/bash
#set -x # devel

PROGRAMNAME="isl-0.14.1"
ARCHIVENAME="$PROGRAMNAME.tar.xz"
MIRRORURL="http://isl.gforge.inria.fr/$ARCHIVENAME"

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
  --disable-dependency-tracking
  --disable-silent-rules
  --with-gmp=system
  --with-gmp-prefix=$TOOLCHAINDIR
  --enable-shared=no
  --enable-static=yes
  CC=$(which clang)
  CXX=$(which clang++)
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
  cc test.c -I$PREFIX/include -L$PREFIX/lib -lgmp -lisl -o test &&
  ./test \
  1>/dev/null 2>/dev/null
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
make $MAKE_ARGS \
1>/dev/null 2>/dev/null
echo "Installing $PROGRAMNAME"
make install \
1>/dev/null 2>/dev/null
post_install
popd 1>/dev/null
