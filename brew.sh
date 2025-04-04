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

# Homebrew
if hash brew 2>/dev/null; then
	cecho "Homebrew already installed" $green
else
	cecho "Installing Homebrew" $yellow
	#ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        eval "$(/opt/homebrew/bin/brew shellenv)"
	brew doctor
fi

# For temminal proxy to socks5, brew services restart polipo
# brew install polipo

# Install command-line tools using Homebrew.

# Make sure we’re using the latest Homebrew.
# brew update

# Upgrade any already-installed formulae.
# brew upgrade

# Save Homebrew’s installed location.
BREW_PREFIX=$(brew --prefix)

# Install GNU core utilities (those that come with macOS are outdated).
# Don’t forget to add `$(brew --prefix coreutils)/libexec/gnubin` to `$PATH`.
brew install coreutils
ln -s "${BREW_PREFIX}/bin/gsha256sum" "${BREW_PREFIX}/bin/sha256sum"

# Install some other useful utilities like `sponge`.
brew install moreutils
# Install GNU `find`, `locate`, `updatedb`, and `xargs`, `g`-prefixed.
brew install findutils
# Install GNU `sed`, overwriting the built-in `sed`.
brew install gnu-sed
# Install a modern version of Bash.
brew install bash
brew install bash-completion2

# Switch to using brew-installed bash as default shell
if ! fgrep -q "${BREW_PREFIX}/bin/bash" /etc/shells; then
  echo "${BREW_PREFIX}/bin/bash" | sudo tee -a /etc/shells;
  chsh -s "${BREW_PREFIX}/bin/bash";
fi;

# Install `wget` with IRI support.
#brew install wget --with-iri
brew install wget

# Install GnuPG to enable PGP-signing commits.
#brew install gnupg

# Install more recent versions of some macOS tools.
brew install vim 
brew install grep
brew install openssh

brew tap homebrew/cask-fonts
brew install --cask font-jetbrains-mono-nerd-font
# fc-cache -f -v


# Install other useful binaries.
brew install git
brew install less
brew install git-delta
brew install git-lfs
brew install imagemagick
brew install lua
brew install ssh-copy-id
brew install tree

# ----------------------custom----------------------
brew install graphicsmagick
brew install trash
brew install pcre
brew install liquidprompt
brew install graphviz
brew install plantuml
brew install the_silver_searcher
brew install rg
brew install z
brew install protobuf

## 替换 htop
brew install glances

## Ghostty is a fast, feature-rich, and cross-platform terminal emulator
## rhttps://github.com/ghostty-org/ghostty
brew install --cask ghostty

# for Erlang, Elixir
brew install autoconf
brew install fop
brew install wxwidgets

# youtube downloader
brew install yt-dlp

brew install autojump

# Starship 是一个定制的跨 Shell 终端提示符
brew install starship

## exa: A modern replacement for ‘ls’.
brew install ghq fzf exa
git config --global ghq.root '~/src'
exa -l -g --icons

apps=(
    caffeine
    gas-mask
    google-chrome
    appcleaner
    vlc
    ## Mac 平台最好的免费播放器
    IINA
    CleanShot
    wechatwork
    libreoffice
)

cecho "Install My Favorate Apps with brew install --cask xxx" $yellow
for item in ${apps[@]}; do
	cecho "> ${item}" $magenta
done
cecho "Enter: y or n To install or not install apps" $yellow
select yn in "Yes" "No"; do
	case $yn in
		Yes )
		    cecho "Ok! installing apps, please wait ... " $yellow
		    brew install --cask --appdir="/Applications" ${apps[@]}
		    break;;
		No ) break;;
	esac
done

cecho "Cleaning ..." $yellow
brew cleanup
cecho "Done!!!" $yellow
