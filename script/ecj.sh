#!/bin/bash
#set -x # devel

PROGRAMNAME="ecj-4.9"
ARCHIVENAME="$PROGRAMNAME.jar"
MIRRORURL="https://mirrors.kernel.org/sources.redhat.com/java/$ARCHIVENAME"

TMPDIR=$1  # e.g. /tmp/GnuCommandLineTools
PREFIX=$2  # e.g. /Library/Developer/GnuCommandLineTools/
MODE=$3    # 0:install 1:uninstall
SRCDIR=$TMPDIR/src
PATCHDIR=$TMPDIR/patch/$PROGRAMNAME
TESTDIR=$TMPDIR/test/$PROGRAMNAME
WORKBENCH=$TMPDIR/workbench
TOOLCHAIN=$TMPDIR/toolchain

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

  echo "Uninstalling $PROGRAMNAME"
  rm -f $PREFIX/share/java/$ARCHIVENAME
  if [ $? -ne 0 ]; then
    echo "Failed to uninstall"
    return 1
  fi

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
  test ! -d $PATCHDIR && mkdir $PATCHDIR
  test ! -d $TESTDIR && mkdir $TESTDIR
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

  mkdir $WORKBENCH/$PROGRAMNAME
  pushd $WORKBENCH/$PROGRAMNAME 1>/dev/null
  cp $SRCDIR/$ARCHIVENAME ecj.jar
  popd 1>/dev/null
  return 0
}

post_install()
{
  pushd $TESTDIR 1>/dev/null
  #echo "Testing $PROGRAMNAME"
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
echo "Installing $PROGRAMNAME"
install -d $PREFIX/share/java 1>/dev/null
install ecj.jar $PREFIX/share/java 1>/dev/null
post_install
popd 1>/dev/null
