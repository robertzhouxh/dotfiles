#!/usr/bin/env zsh

# Homebrew 初始化。
# 必须逐路径探测：直接 eval 不存在的路径会让每次开终端都报 "no such file or directory"。
# 顺序按机器常见程度排列，命中即止。
for _brew in \
  /opt/homebrew/bin/brew \
  /usr/local/bin/brew \
  /home/linuxbrew/.linuxbrew/bin/brew \
  "$HOME/.linuxbrew/bin/brew"
do
  if [ -x "$_brew" ]; then
    eval "$("$_brew" shellenv)"
    break
  fi
done

unset _brew
