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
#brew install screen
#brew install gmp

# Install font tools.
#brew tap bramstein/webfonttools
#brew install sfnt2woff
#brew install sfnt2woff-zopfli
#brew install woff2

brew tap homebrew/cask-fonts
# brew tap laishulu/cask-fonts
brew install --cask font-source-code-pro
brew install --cask font-hack

# Install some CTF tools; see https://github.com/ctfs/write-ups.
#brew install aircrack-ng
#brew install bfg
#brew install binutils
#brew install binwalk
#brew install cifer
#brew install dex2jar
#brew install dns2tcp
#brew install fcrackzip
#brew install foremost
#brew install hashpump
#brew install hydra
#brew install john
#brew install knock
#brew install netpbm
#brew install nmap
#brew install pngcheck
#brew install socat
#brew install sqlmap
#brew install tcpflow
#brew install tcpreplay
#brew install tcptrace
#brew install xpdf
#brew install xz

# Install other useful binaries.
#brew install ack
#brew install exiv2
brew install git
brew install git-lfs
#brew install gs
#brew install imagemagick --with-webp
brew install imagemagick 
brew install lua
#brew install lynx
#brew install p7zip
#brew install pigz
#brew install pv
#brew install rename
#brew install rlwrap
brew install ssh-copy-id
brew install tree
#brew install vbindiff
#brew install zopfli


# ----------------------custom----------------------
brew install graphicsmagick
brew install trash
#brew install https://raw.githubusercontent.com/kadwanev/bigboybrew/master/Library/Formula/sshpass.rb
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

# for Erlang, Elixir
brew install autoconf
brew install fop
#brew install --build-from-source wxmac
brew install wxwidgets 

# A Terminal Client for MySQL with AutoCompletion and Syntax Highlighting.
brew install mycli

# youtube downloader
brew install yt-dlp

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

cecho "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<" $yellow
cecho "Done!!!" $yellow
cecho "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<" $yellow
