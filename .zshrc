## starship(mac)
## curl -sS https://starship.rs/install.sh | sh
## echo 'eval "$(starship init zsh)"' >> ~/.zshrc
## mkdir -p ~/.config && touch ~/.config/starship.toml
## sudo vim ~/.config/starship.toml

## brew install ghq exa
## exa: A modern replacement for ‘ls’.
## git config --global ghq.root '~/src'

## 字体使用 JetBrains Mono Nerd
## brew tap homebrew/cask-fonts
## brew install --cask font-jetbrains-mono-nerd-font
## fc-cache -f -v

## git config --global ghq.root '~/src'

eval "$(starship init zsh)"
if [ "$TERM_PROGRAM" != "vscode" ] && [ "$PWD" = "$HOME" ]; then
  cd ~/src
fi
if [[ $(command -v exa) ]]; then;
 exa --icons --git
fi

# aliases
alias g=git

# hook
## cd+ls
chpwd() {
    if [[ $(pwd) != $HOME ]]; then;
        ls
    fi
}

if [[ $(command -v exa) ]]; then
  alias e='exa --icons --git'
  alias l=e
  alias ls=e
  alias ea='exa -a --icons --git'
  alias la=ea
  alias ee='exa -aahl --icons --git'
  alias ll=ee
  alias et='exa -T -L 3 -a -I "node_modules|.git|.cache" --icons'
  alias lt=et
  alias eta='exa -T -a -I "node_modules|.git|.cache" --color=always --icons | less -r'
  alias lta=eta
  alias l='clear && ls'
fi

# func
function ghq-fzf_change_directory() {
  local src=$(ghq list | fzf --preview "exa -l -g -a --icons $(ghq root)/{} | tail -n+4 | awk '{print \$6\"/\"\$8\" \"\$9 \" \" \$10}'")
  if [ -n "$src" ]; then
    BUFFER="cd $(ghq root)/$src"
    zle accept-line
  fi
  zle -R -c
}

zle -N ghq-fzf_change_directory
bindkey '^f' ghq-fzf_change_directory
