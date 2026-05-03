#!/usr/bin/env bash

# 仅限交互式 shell 执行（避免影响 scp、rsync 等非交互任务）
[[ $- == *i* ]] || return

# 0. 加载 asdf（如果已安装）
[ -f "$HOME/.asdf/asdf.sh" ] && . "$HOME/.asdf/asdf.sh"
[ -f "$HOME/.asdf/completions/asdf.bash" ] && . "$HOME/.asdf/completions/asdf.bash"

# 1. starship 提示符（如果已安装）
if command -v starship &>/dev/null; then
    eval "$(starship init bash)"
fi

# 2. 加载用户环境变量和别名（文件存在即加载，允许空文件）
[ -f "$HOME/.env" ] && source "$HOME/.env"
[ -f "$HOME/.alias" ] && source "$HOME/.alias"

# 3. exa 别名（如需使用，取消注释以下行并安装 exa）
# if command -v exa &>/dev/null; then
#     alias l='exa --icons --git'
#     alias ll='exa --icons --git -l'
#     alias la='exa --icons --git -la'
# fi

# 4. 跨平台加载 autojump
_autojump_paths=(
    "$(brew --prefix 2>/dev/null)/etc/profile.d/autojump.sh"   # macOS (Homebrew)
    "/usr/share/autojump/autojump.sh"                         # Ubuntu/Debian (apt)
    "/etc/profile.d/autojump.sh"                              # 通用系统路径
    "$HOME/.autojump/etc/profile.d/autojump.sh"              # 用户源码安装
)

for _path in "${_autojump_paths[@]}"; do
    if [ -f "$_path" ]; then
        source "$_path"
        break
    fi
done
unset _path _autojump_paths
