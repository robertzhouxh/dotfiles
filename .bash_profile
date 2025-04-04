#!/usr/bin/env bash
# ==================== 基础环境变量 ====================
export EDITOR='vim'
export LANG='en_US.UTF-8'
export LC_ALL='en_US.UTF-8'
export GPG_TTY=$(tty)

# ==================== macOS 专用配置 ====================
if [[ "$(uname -s)" == "Darwin" ]]; then
    # 先确保 /opt/homebrew/bin 在 PATH 中（Apple Silicon 默认路径）
    if [ -d "/opt/homebrew/bin" ]; then
        export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
    elif [ -d "/usr/local/bin" ]; then  # Intel Mac 默认路径
        export PATH="/usr/local/bin:/usr/local/sbin:$PATH"
    fi

    # 确保 brew 可用后获取前缀
    if command -v brew &>/dev/null; then
        export BREW_PREFIX=$(brew --prefix)

        # Homebrew 相关路径
        export PATH="${BREW_PREFIX}/bin:${BREW_PREFIX}/sbin:$PATH"

        # JDK 配置
        if [[ -d "$(brew --prefix openjdk)" ]]; then
            export JAVA_HOME="$(brew --prefix openjdk)"
            export PATH="$JAVA_HOME/bin:$PATH"
        fi

        # OpenSSL 相关编译标志
        export LDFLAGS="-L${BREW_PREFIX}/opt/openssl@3/lib"
        export CPPFLAGS="-I${BREW_PREFIX}/opt/openssl@3/include"
    fi
fi

# ==================== 加载 ~/.env（存放 API Key 等敏感信息）====================
if [ -f ~/.env ]; then
    source ~/.env
fi

# ==================== 加载 ~/.bashrc ====================
if [ -f ~/.bashrc ]; then
    source ~/.bashrc
fi

# 登录提示
echo "System initialized for $(whoami) at $(date)"
