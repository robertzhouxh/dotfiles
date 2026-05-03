#!/usr/bin/env zsh

# 仅限交互式 shell 执行（避免影响 scp、rsync 等非交互任务）
[[ -o interactive ]] || return

# 0. 加载 asdf（如果已安装）
[ -f "$HOME/.asdf/asdf.sh" ] && source "$HOME/.asdf/asdf.sh"
# 可选：加载 asdf 补全（zsh 补全通常需要额外配置，简单起见只加载核心）
[ -f "$HOME/.asdf/completions/asdf.zsh" ] && source "$HOME/.asdf/completions/asdf.zsh"

# 1. starship 提示符（如果已安装）
if (( $+commands[starship] )); then
    eval "$(starship init zsh)"
fi

# 2. 加载用户环境变量和别名（文件存在即可加载，允许空文件）
[[ -f "$HOME/.env" ]] && source "$HOME/.env"
[[ -f "$HOME/.alias" ]] && source "$HOME/.alias"

# 3. exa 别名（取消注释以启用，不再自动执行）
# if (( $+commands[exa] )); then
#     alias l='exa --icons --git'
#     alias ll='exa --icons --git -l'
#     alias la='exa --icons --git -la'
# fi

# 4. 跨平台加载 autojump（支持 macOS Homebrew 与 Ubuntu/Debian）
_autojump_paths=(
    "$(brew --prefix 2>/dev/null)/etc/profile.d/autojump.sh"   # macOS (Homebrew)
    "/usr/share/autojump/autojump.sh"                          # Ubuntu/Debian (apt)
    "/etc/profile.d/autojump.sh"                               # 通用系统路径
    "$HOME/.autojump/etc/profile.d/autojump.sh"               # 用户源码安装
)

for _path in $_autojump_paths; do
    if [[ -f "$_path" ]]; then
        source "$_path"
        break
    fi
done
unset _path _autojump_paths
