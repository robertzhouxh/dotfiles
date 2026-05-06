#!/usr/bin/env zsh

[[ -o interactive ]] || return
[[ -f "$HOME/.env" ]] && source "$HOME/.env"
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
