#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Set the colours you can use
black='\033[0;30m'
white='\033[0;37m'
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
blue='\033[0;34m'
magenta='\033[0;35m'
cyan='\033[0;36m'

#  Reset text attributes to normal + without clearing screen.
alias Reset="tput sgr0"

# Color-echo.
# arg $1 = message
# arg $2 = Color
cecho() {
  echo -e "${2}${1}"
  # Reset # Reset to normal.
  return
}

cecho "attension: make sure you have installed the command line tools use: xcode-select --install" $yellow
# cecho "attension: make sure you have installed pip: wget https://bootstrap.pypa.io/get-pip.py && sudo -H python get-pip.py" $yellow
# cecho "attension: make sure you have installed java: brew cask install java" $yellow

# Homebrew
# http://brew.sh
if hash brew 2>/dev/null; then
	cecho "Homebrew already installed" $green
else
	cecho "Installing Homebrew" $yellow
	#/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
	ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
	brew doctor
fi

# Homebrew Cask
# http://caskroom.io
if command brew cask 1>/dev/null; then
	cecho "Homebrew Cask already installed, just conitnue ..." $green
else
	cecho "Installing Homebrew Cask" $yellow
	brew tap homebrew/cask-cask
	#brew install caskroom/cask/brew-cask
fi

# 使用 brew services start|stop|restart SERVICE_NAME 这样的命令来操作一切终端服务了 <=> LaunchRocket
#brew tap homebrew/services

# awesome font for programming
brew tap homebrew/cask-fonts
brew tap laishulu/cask-fonts

#Sarasa Mono SC Nerd
brew cask install font-sarasa-nerd
brew cask install font-source-code-pro
brew cask install font-hack
brew cask install font-fira-code

# Install command-line tools using Homebrew.
# Ask for the administrator password upfront.
# sudo -v

# Keep-alive: update existing `sudo` time stamp until the script has finished.
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

cecho "Updating Homebrew" $yellow
#brew update
#brew upgrade
cecho "Install command-line tools ... " $yellow

# Install GNU core utilities (those that come with OS X are outdated).
# Don’t forget to add `$(brew --prefix coreutils)/libexec/gnubin` to `$PATH`.
# TODO: you'll get sed and a bunch of other GNU versions tar, date, etc installed in /usr/local/bin and given the prefix 'g'
brew install coreutils
# example
# ln -s /usr/local/bin/gsha256sum /usr/local/bin/sha256sum

# Install some other useful utilities like `sponge`.
brew install moreutils
# Install GNU `find`, `locate`, `updatedb`, and `xargs`, `g`-prefixed.
brew install findutils

# for emacs org-pdf
 brew install Pygments

# Install Bash 4.
# Note: don’t forget to add `/usr/local/bin/bash` to `/etc/shells` before
# running `chsh`.
brew install bash
brew install bash-completion2

# Switch to using brew-installed bash as default shell
if ! fgrep -q '/usr/local/bin/bash' /etc/shells; then
  echo '/usr/local/bin/bash' | sudo tee -a /etc/shells;
fi;

brew install wget
brew install openssl

read -p "custom command line tools ? [y/n]" -n 1;
if [[ $REPLY =~ ^[Yy]$ ]]; then
# gnu tools
brew install gnu-sed
brew install gnu-indent
brew install gnutls
brew install grep
brew install gnu-tar
brew install gawk

# other tools
brew install make
brew install graphicsmagick
brew install tree
brew install https://raw.githubusercontent.com/kadwanev/bigboybrew/master/Library/Formula/sshpass.rb
brew install curl --force
brew install git --force
brew install ctags
brew install fzf
brew install trash
brew install pcre
brew install liquidprompt
brew install zsh
brew install zsh-completions
brew install graphviz
brew install plantuml
brew install the_silver_searcher
brew install rg
brew install ccls
brew install imagemagick
brew install pngpaste
brew install z
brew install protobuf
# just abandon thunder
brew install aria2
# cool pdf reader 
brew install aria2
fi;
brew cleanup

apps=(
    alfred
    caffeine
    #appcleaner
    #cheatsheet
    #emacs
    gas-mask
    google-chrome
    #iterm2
    #java
    qq
    smcfancontrol
    #thunder
    vlc
    #licecap
)
cecho "Install My Favorate Apps with brew cask install xxx" $yellow
for item in ${apps[@]}; do
	cecho "> ${item}" $magenta
done
cecho "Enter: y or n To install or not install apps" $yellow
select yn in "Yes" "No"; do
	case $yn in
		Yes )
		    cecho "Ok! installing apps, please wait ... " $yellow
		    brew cask install --appdir="/Applications" ${apps[@]}
		    break;;
		No ) break;;
	esac
done


read -p "Oh-My-ZSH ? [y/n]" -n 1;
if [[ $REPLY =~ ^[Yy]$ ]]; then
  sh -c "$(wget https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"
#  git clone --depth=1 https://gitee.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel10k
#  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
fi;

chsh -s /usr/local/bin/bash
#chsh -s /bin/zsh
cecho "Done!!! you can deploy vim( ./vim.sh ) or emacs( ./emacs.sh ) to bring you into cool coding environment!!!" $green
