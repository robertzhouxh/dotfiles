#!/usr/bin/env bash

## git config --global ghq.root '~/src'

eval "$(starship init bash)"

if [ -s "$HOME/.asdf/asdf.sh" ]; then
  . "$HOME/.asdf/asdf.sh"
  . "$HOME/.asdf/completions/asdf.bash"
fi

if [ -s "$HOME/.env" ]; then
  . "$HOME/.env"
fi

## 如果 exa 存在，就显示一下 exa 输出（注意这里只会执行一次）
if command -v exa >/dev/null 2>&1; then
  exa --icons --git
fi

# 加载 autojump（Homebrew 安装路径）
autojump_file="$(brew --prefix 2>/dev/null)/etc/profile.d/autojump.sh"
if [[ -s "$autojump_file" ]]; then
  source "$autojump_file"
fi
