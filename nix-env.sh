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

  # !deprecated
  nix_build_desktop() {
    JOBS=100

    if [ -z $1 ]; then
      CONFIG=release
      NIX_BUILD_CONFIG_DIR=${NIX_BUILD_DESKTOP_DIR}/Release
    else
      CONFIG=$1
      NIX_BUILD_CONFIG_DIR=${NIX_BUILD_DESKTOP_DIR}/Debug
    fi

    #[ -d $NIX_BUILD_CONFIG_DIR ] && rm -r $NIX_BUILD_CONFIG_DIR

    # FIXME: Remove PKG_CONFIG_PATH when https://bugs.webkit.org/show_bug.cgi?id=118195 has landed
    #PKG_CONFIG_PATH=$NIX_BUILD_DESKTOP_DIR/Dependencies/Root/lib64/pkgconfig \
    CMD="WEBKIT_OUTPUTDIR=$NIX_BUILD_DESKTOP_DIR ${NIX}/Tools/Scripts/build-webkit --nix --makeargs=-j${JOBS} --prefix=${HOME}/local --${CONFIG} --video 2>&1 | tee $WEBKIT/build/build-desktop-${CONFIG}.log"

    echo -------------
    echo Command: $CMD
    echo ------------
    eval "$CMD"
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
    WEBKIT_OUTPUTDIR=$NIX_BUILD_DESKTOP_DIR \
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

  #echo "PKG_CONFIG_PATH=$NIX_PKGCONFIG_PATH:$DEP_PKGCONFIG_PATH cmake $DROWSER && make"
  #return

  CMAKE_FLAGS='-DCMAKE_BUILD_TYPE:STRING=Debug'

  cd $DROWSER_BUILD_CONFIG_DIR
  echo ***Entered $DROWSER_BUILD_CONFIG_DIR
  echo "PKG_CONFIG_PATH=$NIX_PKGCONFIG_PATH:$DEP_PKGCONFIG_PATH cmake $CMAKE_FLAGS $DROWSER && make"
  PKG_CONFIG_PATH=$NIX_PKGCONFIG_PATH:$DEP_PKGCONFIG_PATH cmake $CMAKE_FLAGS $DROWSER && make
  cd -
}

drowser_run() {
  if [ -z $1 ]; then
    CONFIG=release
  else
    CONFIG=$1
  fi

  DROWSER_BUILD_CONFIG_DIR=${DROWSER_BUILD_DESKTOP_DIR_PREFIX}/${CONFIG}
  LIBRARY_PATH=$HOME/local/lib:$NIX_BUILD_DESKTOP_DIR/Dependencies/Root/lib64
  echo "running drowser with LD_LIBRARY_PATH=$LIBRARY_PATH ..."

  LD_LIBRARY_PATH=$LIBRARY_PATH $DROWSER_BUILD_CONFIG_DIR/src/Browser/drowser $2
}

##################### RPi-related stuff

export RPI_NICK=pi@10.60.69.52

# Mounting nix-src dir in sdk chroot dir
#sudo mount --bind /home/nick/projects/webkit/nix/nix-src /home/nick/projects/webkit/nix/rpi-sdk/home/pi/webkitnix

export RPI_SDK_HOME=${WEBKIT}/rpi/rpi-sdk
alias rpi_sdk_start="sudo ./start-rpi-sdk ${RPI_SDK_HOME}"

alias nix="cd $NIX"
alias webkit="cd $WEBKIT"
alias wk="cd $NIX/Source/WebKit2"
alias killall-web-process='killall -9 WebProcess'


prepare_clang_index() {
    local port=$1
    [ -z $port ] && port=nix
    export CLANG_COMPLETE_CONFIG_PATH=/tmp/$port-clang-completes
    [ -d $CLANG_COMPLETE_CONFIG_PATH ] || mkdir -v $CLANG_COMPLETE_CONFIG_PATH
    rm $CLANG_COMPLETE_CONFIG_PATH/* -r
}

commit_clang_index() {
    cat $CLANG_COMPLETE_CONFIG_PATH/* | sort -u
    # TODO save into $NIX/.clang_complete
    unset CLANG_COMPLETE_CONFIG_PATH
}

# TODO temp solution / move to use only WEBKIT_OUTPUTDIR
to_webkit_port() {
    SRC="$WEBKIT/build/from-port-source-tree/WebKitBuild-$1"
    DST="$NIX/WebKitBuild"

    if [ -f $DST ]; then
        echo "Destination dir \"$DST\" already exists and it's not a symbolic link."
        echo "Aborting.."
        return 1
    fi

    [ -L $DST ] && rm $DST
    ln -sv $SRC $DST
}

alias tonix='to_webkit_port nix'
alias toefl='to_webkit_port efl'
alias togtk='to_webkit_port gtk'

#TODO improve this
efl_build() {
    local opt='--no-webkit1 --cmakeargs="-DSHARED_CORE=ON" --prefix=~/local'
    toefl && $NIX/Tools/Scripts/build-webkit --efl --makeargs=-j100 $opt $@
    notify-send "webkit-efl build finished!"
}

gtk_build() {
    local opt='--no-webkit1 --cmakeargs="-DSHARED_CORE=ON" --prefix=/home/nick/local'
    togtk && $NIX/Tools/Scripts/build-webkit --gtk --makeargs=-j100 $opt $@
    notify-send "webkit-gtk build finished!"
}

nix_build() {
    prepare_clang_index
    CMD="tonix && ${NIX}/Tools/Scripts/build-webkit --nix --makeargs=-j100 --prefix=~/local $@"
    echo -------------
    echo Command: $CMD
    echo ------------
    eval "$CMD" && commit_clang_index
    notify-send "Nix build finished!!"
}

wk_runtime_env() {
  LIBRARY_PATH=$HOME/local/lib:$NIX/WebKitBuild/Dependencies/Root/lib64
  echo "LD_LIBRARY_PATH=$LIBRARY_PATH ..."
  export LD_LIBRARY_PATH=$LIBRARY_PATH
}

## TODO: Layout tests functions
#export WEBKIT_OUTPUTDIR=/home/nick/projects/webkit-nix/build/nix-build-desktop
#rm ../layout-test-results/ -rf && ./Tools/Scripts/run-webkit-tests --no-show-results --no-new-test-results --no-sample-on-timeout --results-directory ../layout-test-results --builder-name 'Nix Linux 64-bit Release' --debug --nix --exit-after-n-crashes-or-timeouts 10 --exit-after-n-failures 500 --build-directory=/home/nick/projects/webkit-nix/build/nix-build-desktop
#strace 2>x.log -- /home/nick/projects/webkit-nix/build/nix-build-desktop/Release/bin/WebKitTestRunner  -

alias sgrep='grep --exclude="*~" --exclude="*ChangeLog*" --exclude="*.order" -n'
