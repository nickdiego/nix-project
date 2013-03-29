#!/bin/bash

__nix_current_branch ()
{
    local b="$(git symbolic-ref HEAD 2>/dev/null)";
    if [ -n "$b" ]; then
        printf "%s" "${b##refs/heads/}";
    fi
}

NIX=${WEBKIT}/src/nix

if [ -d $NIX ]; then
  export NIX

  . $NIX/Tools/Scripts/webkit-tools-completion.sh
  export WEBKIT_INSPECTOR_SERVER=127.0.0.1:2222
  export NIX_BUILD_DESKTOP_DIR=$WEBKIT/build/nix-build-desktop
  export NIX_INSTALL_DESKTOP_PREFIX_DIR=$HOME/local
  
  export PATH=$PATH:$NIX_INSTALL_DESKTOP_PREFIX_DIR/bin
  export LD_LIBRARY_PATH=$NIX_INSTALL_DESKTOP_PREFIX_DIR/lib:$LD_LIBRARY_PATH

  # configures icecc
  icecc_setup
  
  nix_build_desktop() {
    JOBS=40

    if [ -z $1 ]; then
      CONFIG=release
      NIX_BUILD_CONFIG_DIR=${NIX_BUILD_DESKTOP_DIR}/Release
    else
      CONFIG=$1
      NIX_BUILD_CONFIG_DIR=${NIX_BUILD_DESKTOP_DIR}/Debug
    fi

    #[ -d $NIX_BUILD_CONFIG_DIR ] && rm -r $NIX_BUILD_CONFIG_DIR

    PKG_CONFIG_PATH=$NIX_BUILD_DESKTOP_DIR/Dependencies/Root/lib64/pkgconfig \
    WEBKITOUTPUTDIR=$NIX_BUILD_DESKTOP_DIR \
    ${NIX}/Tools/Scripts/build-webkit --nix --makeargs=-j${JOBS} \
      --prefix=${HOME}/local --${CONFIG} 2>&1 | tee $WEBKIT/build/build-desktop-${CONFIG}.log
  }

  nix_install_desktop() {

    if [ -z $1 ]; then
      CONFIG=release
      NIX_BUILD_CONFIG_DIR=${NIX_BUILD_DESKTOP_DIR}/Release
    else
      CONFIG=$1
      NIX_BUILD_CONFIG_DIR=${NIX_BUILD_DESKTOP_DIR}/Debug
    fi
    
    pushd $NIX_BUILD_CONFIG_DIR
    make install || echo -ne "\n********* ERROR INSTALL NIX\n"
    popd
  }

  nix_update_dependencies() {
    WEBKITOUTPUTDIR=$NIX_BUILD_DESKTOP_DIR \
      ${NIX}/Tools/Scripts/update-webkitnix-libs
  }

  nix_chicken() {
    MiniBrowser --desktop http://localhost:8000/chicken-wranglers-html5/index.html?debug=true &
    X=$!
    while ! nc -z localhost 2222; do
      echo "waiting..."
      sleep 1
    done
    google-chrome http://localhost:2222/inspector.html?page=1;
  }

fi

nix_generate_tags () {
    export NIX_TAGS_FILE=$NIX/../nix-tags
    ctags -f $NIX_TAGS_FILE --sort=yes -R $NIX 2>/dev/null
    ln -sf $NIX_TAGS_FILE ~/.vim/tags/nix
}

##################### Drowser
DROWSER=${WEBKIT}/src/drowser

if [ -d $DROWSER ]; then
  export DROWSER
  export DROWSER_BUILD_DESKTOP_DIR_PREFIX=$WEBKIT/build/drowser-build-desktop
fi

drowser_build() {
  if [ -z $1 ]; then
    CONFIG=release
  else
    CONFIG=$1
  fi

  DROWSER_BUILD_CONFIG_DIR=${DROWSER_BUILD_DESKTOP_DIR_PREFIX}/${CONFIG}
  [ -d $DROWSER_BUILD_CONFIG_DIR ] || mkdir $DROWSER_BUILD_CONFIG_DIR -p

  DEP_PKGCONFIG_PATH=$NIX_BUILD_DESKTOP_DIR/Dependencies/Root/lib64/pkgconfig
  NIX_PKGCONFIG_PATH=$NIX_INSTALL_DESKTOP_PREFIX_DIR/lib/pkgconfig

  #echo $DEP_PKGCONFIG_PATH --- $NIX_PKGCONFIG_PATH
  #return

  pushd $DROWSER_BUILD_CONFIG_DIR 
  PKG_CONFIG_PATH=$NIX_PKGCONFIG_PATH:$DEP_PKGCONFIG_PATH \
  cmake $DROWSER && make
  popd  
}

drowser_run() {
  if [ -z $1 ]; then
    CONFIG=release
  else
    CONFIG=$1
  fi

  DROWSER_BUILD_CONFIG_DIR=${DROWSER_BUILD_DESKTOP_DIR_PREFIX}/${CONFIG}
  LD_LIBRARY_PATH=$HOME/local/lib:$NIX_BUILD_DESKTOP_DIR/Dependencies/Root/lib64 \
  $DROWSER_BUILD_CONFIG_DIR/src/Browser/drowser
}

##################### RPi-related stuff

export RPI_NICK=pi@10.60.69.52

# Mounting nix-src dir in sdk chroot dir
#sudo mount --bind /home/nick/projects/webkit/nix/nix-src /home/nick/projects/webkit/nix/rpi-sdk/home/pi/webkitnix

export RPI_SDK_HOME=${WEBKIT}/rpi/rpi-sdk
alias rpi_sdk_start="sudo ./start-rpi-sdk ${RPI_SDK_HOME}"
