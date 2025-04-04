#!/usr/bin/env zsh

## git config --global ghq.root '~/src'
eval "$(starship init zsh)"

if [ "$TERM_PROGRAM" != "vscode" ] && [ "$PWD" = "$HOME" ]; then
  cd ~/src
fi

if [[ $(command -v exa) ]]; then;
 exa --icons --git
fi

if [ -f ~/.env ]; then
    source ~/.env
fi

