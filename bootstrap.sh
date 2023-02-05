#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE}")";

#git pull origin master;

function doIt() {
	rsync --exclude ".git/" \
          --exclude ".DS_Store" \
          --exclude "jumper.expect" \
          --exclude "config" \
          --exclude "bootstrap.sh" \
          --exclude "vim.sh" \
          --exclude "emacs.sh" \
          --exclude "README.md" \
          --exclude "LICENSE-MIT.txt" \
          --exclude ".vimrc" \
          --exclude ".vim" \
          --exclude ".emacs.d" \
          --exclude "brew.sh" \
	  --exclude "apt.sh" \
	  --exclude "rime-settings" \
	  --exclude "squirrel" \
	  --exclude ".macos" \
	  --exclude "polipo.plist" \
          -avh --no-perms . ~;
	source ~/.bash_profile;
}

if [ "$1" == "--force" -o "$1" == "-f" ]; then
	doIt;
else
	read -p "This may overwrite existing files in your home directory. Are you sure? (y/n) " -n 1;
	echo "";
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		doIt;
	fi;
fi;
unset doIt;

sysType=`uname -s`
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo -e "\033[40;32m start to install command line tools for your system ${sysType} \033[0m"
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"

if [ $sysType = "Linux" ]; then
    source ./apt.sh;
elif [ $sysType = "Darwin" ]; then
    source ./brew.sh;
else
    echo -e "\033[40;32m unsupported system, exit \033[0m"
fi

echo -e "\033[40;32m All done, HAPPY HACKING :-) \033[0m"
echo ""
