#!/usr/bin/env zsh

[[ -o interactive ]] || return
[[ -f "$HOME/.envv" ]] && source "$HOME/.envv"
[[ -f "$HOME/.alias" ]] && source "$HOME/.alias"

# Starship
if command -v starship >/dev/null 2>&1; then
  if [ -n "$ZSH_VERSION" ]; then
    eval "$(starship init zsh)"
  elif [ -n "$BASH_VERSION" ]; then
    eval "$(starship init bash)"
  fi
fi

for file in \
  /opt/homebrew/etc/profile.d/autojump.sh \
  /usr/local/etc/profile.d/autojump.sh \
  /usr/share/autojump/autojump.sh \
  /etc/profile.d/autojump.sh \
  "$HOME/.autojump/etc/profile.d/autojump.sh"
do
  [[ -f "$file" ]] && source "$file" && break
done

unset file

# Kaku Shell Integration
[[ ":$PATH:" != *":$HOME/.config/kaku/zsh/bin:"* ]] && export PATH="$HOME/.config/kaku/zsh/bin:$PATH"
[[ -f "$HOME/.config/kaku/zsh/kaku.zsh" ]] && source "$HOME/.config/kaku/zsh/kaku.zsh"

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/Users/zxh/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/Users/zxh/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/Users/zxh/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/Users/zxh/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup

# Ensure asdf shims take priority over conda
[ -d "$HOME/.asdf/shims" ] && export PATH="$HOME/.asdf/shims:$PATH"
