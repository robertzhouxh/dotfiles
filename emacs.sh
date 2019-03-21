#!/bin/bash

sudo -v

echo -e "\033[40;32m install the emacs ... \033[0m"
#brew install emacs --HEAD --use-git-head --with-cocoa --with-gnutls --with-rsvg --with-imagemagick
# wget http://mirrors.syringanetworks.net/gnu/emacs/emacs-26.1.tar.gz
# tar -xzvf emacs-26.1.tar.gz
# ./configure --without-x --with-gnutls=no
# make
# sudo make install

echo -e "\033[40;32m emacs installed \033[0m"

rm -rf ~/.emacs
# refer  spf13-vim bootstrap.sh`
# BASEDIR=$(dirname $0)
# cd $BASEDIR
# CURRENT_DIR=`pwd`
# or you can try:
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

lnif() {
    if [ -e "$1" ]; then
        ln -sf "$1" "$2"
    fi
}

echo -e "\033[40;32m Step1: Backing up current emacs config \033[0m"
today=`date +%Y%m%d`
# for i in $HOME/.emacs.d; do [ -e $i ] && [ ! -L $i ] && mv $i $i.$today; done
# for i in $HOME/.emacs.d; do [ -L $i ] && unlink $i ; done
if [ -e "$HOME/.emacs.d" ]; then
  unlink "$HOME/.emacs.d"
fi


echo -e "\033[40;32m Step2: Setting up symlinks \033[0m"
lnif "$CURRENT_DIR/.emacs.d" "$HOME/.emacs.d"


# echo -e "\033[40;32m step 2: Install the cask utility for emacs \033[0m"
# if [ `uname -s` = "Linux" ]; then
#   curl -fsSL https://raw.githubusercontent.com/cask/cask/master/go | python
# elif [ `uname -s` = "Darwin" ]; then
#   echo -e "\033[40;32m already installed the cask in your mac osx system , just continue ... \033[0m"
# else
#   echo -e "\033[40;32m unsupported system, exit \033[0m"
# fi


echo -e "\033[40;32m step 3: Install the emacs plugins with cask \033[0m"
echo -e "\033[40;32m It will take a long time, just be patient! ... \033[0m"
echo -e "\033[40;32m cd $HOME/.emacs.d \033[0m"
cd $HOME/.emacs.d

# echo -e "\033[40;32m install the plugins, this will take a long time ... \033[0m"
# cask install

cd $CURRENT_DIR
echo -e "\033[40;32m Done, Happy hacking With The Awesome Emacs \033[0m"
