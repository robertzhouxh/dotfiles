#!/bin/bash

sudo -v
echo -e "\033[40;32m install the emacs ... \033[0m"


# gtags for emacs
#  sudo -H pip install pygments
#  #brew install global --with-exuberant-ctags --with-pygments
#  brew install global

brew tap daviderestivo/emacs-head
brew install emacs-head@26
brew install emacs-head@28 --with-cocoa


rm -rf ~/.emacs
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
lnif() {
    if [ -e "$1" ]; then
        ln -sf "$1" "$2"
    fi

    if [ -e "$1" ]; then
	mkdir -p ~/.emacs.d
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

echo -e "\033[40;32m Done, Happy hacking With The Awesome Emacs \033[0m"
