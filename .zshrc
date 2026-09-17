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
# 不写死安装路径：macOS 与 Linux 的家目录不同，且 conda 可能装在若干常见位置。
# 全部探测失败则静默跳过，保证裸机上一条错误都不刷。
for _conda_root in \
  "$HOME/miniconda3" \
  "$HOME/anaconda3" \
  "$HOME/miniforge3" \
  /opt/miniconda3 \
  /opt/anaconda3 \
  /opt/homebrew/Caskroom/miniconda/base \
  /usr/local/Caskroom/miniconda/base
do
  [ -x "$_conda_root/bin/conda" ] || continue
  __conda_setup="$("$_conda_root/bin/conda" 'shell.zsh' 'hook' 2> /dev/null)"
  if [ $? -eq 0 ]; then
    eval "$__conda_setup"
  elif [ -f "$_conda_root/etc/profile.d/conda.sh" ]; then
    . "$_conda_root/etc/profile.d/conda.sh"
  else
    export PATH="$_conda_root/bin:$PATH"
  fi
  unset __conda_setup
  break
done

unset _conda_root

# Ensure asdf shims take priority over conda
[ -d "$HOME/.asdf/shims" ] && export PATH="$HOME/.asdf/shims:$PATH"
