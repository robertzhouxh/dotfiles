# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="/Users/xier/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
ZSH_THEME="robbyrussell"

DISABLE_AUTO_UPDATE="true"


source $ZSH/oh-my-zsh.sh

# Load the shell dotfiles, and then some:
# * ~/.path can be used to extend `$PATH`.
# * ~/.extra can be used for other settings you don’t want to commit.
for file in ~/.{path,exports,aliases,functions,extra}; do
	[ -r "$file" ] && [ -f "$file" ] && source "$file";
done;
unset file;

# for fzf does not loaded been in .zshrc
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# for source liquidprompt && z awesome tools
[[ `uname -s` == "Linux" ]] && [[ $- = *i* ]] && . ~/.liquidprompt/liquidprompt
[[ `uname -s` == "Linux" ]] && . ~/z/z.sh
[[ `uname -s` == "Darwin" ]] && . /usr/local/share/liquidprompt
[[ `uname -s` == "Darwin" ]] && . `brew --prefix`/etc/profile.d/z.sh

