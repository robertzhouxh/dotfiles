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

# 登录 shell 用 zsh。这里以前把默认 shell 切成 brew 装的 bash，跟本仓库整套配置
# 是反的：.zshrc / .zprofile / starship 的 zsh 分支都是照 zsh 写的，登录 shell 是
# bash 的话新开的终端读 .bashrc，那套东西一个都不生效。
#
# 用系统的 /bin/zsh（macOS 自 Catalina 起自带，本来就在 /etc/shells 里），不装 brew
# 的 zsh：brew.sh 只装 zsh 插件（zsh-autosuggestions 等），它们挂在任何 5.8+ 的 zsh
# 上都能跑，没必要为此多维护一个 zsh 本体。要换 brew 的 zsh，得先把
# "${BREW_PREFIX}/bin/zsh" 追加进 /etc/shells，chsh 只认那份清单。
#
# 读当前值再决定，不无条件 chsh：chsh 会要密码，幂等运行不该每次都弹。
# dscl 的用户记录名就是那个用户的家目录全路径，$HOME 正好是它。
CURRENT_SHELL="$(dscl . -read "$HOME" UserShell 2>/dev/null | awk '{print $2}')"
if [ "$CURRENT_SHELL" = "/bin/zsh" ]; then
  cecho "登录 shell 已经是 /bin/zsh" $green
else
  cecho "把登录 shell 从 ${CURRENT_SHELL:-未知} 切到 /bin/zsh" $yellow
  chsh -s /bin/zsh
fi

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

# 试试新字体
brew install --cask font-jetbrains-mono-nerd-font
brew install --cask font-jetbrains-mono
brew install --cask font-lxgw-wenkai
# fc-cache -f -v

# 酷酷的终端插件
brew install fastfetch
brew install zsh-autosuggestions zsh-syntax-highlighting zsh-completions

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
brew install btop

## 很酷的网络监控应用
brew install  sniffnet

##  端口killer
brew install --cask productdevbook/tap/portkiller

## 牛逼的命令行下载工具
brew install surge-downloader/tap/surge

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
