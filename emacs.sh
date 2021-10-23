#!/bin/bash

sudo -v

echo -e "\033[40;32m install the emacs... \033[0m"

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

lnif() {
    if [ -e "$1" ]; then
        ln -sf "$1" "$2"
    fi
}


echo -e "\033[40;32m Step1: backing up current emacs config \033[0m"
today=`date +%Y%m%d`
for i in $HOME/.emacs $HOME/.emacs.d; do [ -e $i ] && [ ! -L $i ] && mv $i $i.$today; done


echo -e "\033[40;32m Step2: setting up symlinks \033[0m"
lnif "$CURRENT_DIR/.emacs.d" "$HOME/.emacs.d"


cd $CURRENT_DIR

echo -e "\033[40;32m Emacs Install Done! \033[0m"
