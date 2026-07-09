# dotfiles

个人 macOS / Ubuntu 开发环境配置。

## 快速开始

```bash
# 同步配置文件到 $HOME（仅同步 dotfiles，跳过 .git .DS_Store）
rsync -av --include='.*' --exclude='.git' --exclude='.DS_Store' --exclude='*' ./ ~/

# 安装 macOS 工具链
./brew.sh

# 部署 vim 和 Emacs
./vim.sh
./emacs.sh
```

---

## macOS

### 工具软件

```bash
./brew.sh
```

### 付费软件

```bash
brew install Proxifier    # 记得在 Proxifier 中设置 DNS → Resolve hostname through proxy
brew install CleanShot    # 截图工具，购买 license: https://cleanshot.com
```

### 安装 Emacs

- [homebrew-emacs-plus](https://github.com/d12frosted/homebrew-emacs-plus)
- [build-emacs-for-macos](https://github.com/jimeh/build-emacs-for-macos)
- [手动编译安装](https://codeberg.org/mclear-tools/build-emacs-macos)

> 安装后执行 `./emacs.sh` 完成部署，启动 Emacs 即可。

---

## Ubuntu

### 中文输入法

```bash
# 1. 系统设置 → 区域与语言 → 管理已安装的语言，按提示补全语言包
# 2. 安装 fcitx5 + RIME
sudo apt install fcitx5 \
    fcitx5-chinese-addons \
    fcitx5-frontend-gtk4 fcitx5-frontend-gtk3 fcitx5-frontend-gtk2 \
    fcitx5-frontend-qt5 \
    fcitx5-rime
# 3. 注销重新登录后生效
```

---

## Emacs 输入法

### 鼠须管 + 雾凇词库（macOS）

```bash
git clone --depth=1 https://github.com/Mark24Code/rime-auto-deploy.git --branch latest
cd rime-auto-deploy
./installer.rb
```

### librime（Emacs 内嵌输入法依赖）

```bash
curl -L -O https://github.com/rime/librime/releases/download/1.9.0/rime-a608767-macOS.tar.bz2
tar jxvf rime-a608767-macOS.tar.bz2 -C ~/.emacs.d/librime

# 如果 Gatekeeper 阻止加载，临时关闭：
#   sudo spctl --master-disable
# 安装后恢复：
#   sudo spctl --master-enable
```

Emacs 中按 `C-\` 激活输入法。

---

## Emacs AI / LLM 工具

当前配置了三层 AI 交互：

| 工具        | 快捷键     | 后端                          | 场景                           |
|-------------|------------|-------------------------------|--------------------------------|
| Claude Chat | `C-c C-0`  | DeepSeek V4（Anthropic 兼容） | 项目级对话、文件编辑、会话恢复 |
| agent-shell | `C-c C-a`  | Claude Code（ACP 协议）       | 完整终端 agent、多项目并发     |
| gptel       | `M-RET`    | DeepSeek V4（OpenAI 兼容）    | 底部抽屉式 LLM 聊天            |

配置文件：`.emacs.d/lisp/emacs-init-ai.el`

### agent-shell — 终端 Agent

把 Claude Code、Codex、Gemini CLI 等终端 agent 包装成 Emacs buffer。每个会话按 `模型名 @ 目录名` 命名，多项目间 `M-x switch-to-buffer` 切换。

**前提：** 手动安装一次系统依赖：

```bash
brew install claude-code
npm install -g @zed-industries/claude-agent-acp
```

| 操作                   | 方式                      |
|------------------------|---------------------------|
| 启动 Claude Code agent | `C-c C-a` / `C-c C-1`    |
| 手动选择 provider      | `M-x agent-shell`         |
| 发送输入               | `RET`                     |
| 插入换行               | `C-return`                |
| 中断                   | `C-c C-c`                 |

### Claude Chat 原生模式（`emacs-solo-ai`）

`C-c C-0` 启动 SDK 模式（stream-json 协议，diff 高亮、会话恢复、图片粘贴）。
`C-c C-8` 启动 TUI 模式（传统终端交互，走订阅配额）。
`C-c C-9` 启动 opencode agent（多任务类型）。

SDK 模式快捷键：

| 键        | 功能     | 键        | 功能          |
|-----------|----------|-----------|---------------|
| `RET`     | 发送     | `C-c C-i` | 粘贴 PNG 图片 |
| `C-RET`   | 换行     | `C-c C-l` | 清除聊天记录  |
| `C-c C-c` | 中断进程 | `C-c C-r` | 恢复历史会话  |
| `C-c C-k` | 终止进程 | `C-c C-m` | 切换模型      |

斜杠命令（在输入框直接输入）：

| 命令          | 功能         |
|---------------|--------------|
| `/clear`      | 开始新会话   |
| `/model NAME` | 切换模型     |
| `/resume`     | 恢复历史会话 |

### 键位速查

| 快捷键    | 功能               |
|-----------|--------------------|
| `C-c C-a` | agent-shell（首选）|
| `C-c C-1` | agent-shell（备选）|
| `C-c C-0` | Claude Chat（SDK） |
| `C-c C-8` | Claude TUI         |
| `C-c C-9` | OpenCode           |
| `M-RET`   | gptel 抽屉         |

### Evil 模式与 AI 工具协作（vibe-coding 校准）

所有 AI 终端模式（agent-shell、eat、term、Claude Chat、gptel）启动时自动进入 **emacs state**，不与 Evil 快捷键冲突。

vibe-coding 工作流：

```
C-c C-a 启动 agent-shell → 自动进入 emacs state
  → 打字、RET 发送、n/p 导航 agent 输出，一切正常
  → 想用 j/k 滚动输出时，按 Escape 进入 normal state
  → 想继续打字时，按 C-z 回到 emacs state
```

| 键        | 状态   | 行为                                              |
|-----------|--------|---------------------------------------------------|
| `n`       | emacs  | agent-shell-next-item（在 prompt 处则插入 n）     |
| `p`       | emacs  | agent-shell-previous-item（在 prompt 处则插入 p） |
| `j` / `k` | normal | 逐行滚动 agent 输出                               |
| `C-z`     | normal | 回到 emacs state,必要的时候 Enter                 |
| `Escape`  | emacs  | 进入 normal state（用于 j/k 滚动阅读）            |

配置位置：`.emacs.d/lisp/emacs-init-evil.el:27-60`

### FAQ

**`C-c C-a` 没启动 agent-shell（进入了 markdown / org 命令）？**
`C-c C-a` 在 markdown-mode 和 org-mode 中有内置绑定（markdown 的废弃 prefix keys、org-attach）。
markdown 的冲突已修复（移除了废弃的 `C-c C-a *` 前缀）。org-mode 中 `C-c C-a` 仍为 `org-attach`，请使用 `C-c C-1` 启动 agent-shell。

**agent-shell 报 "claude-agent-acp not found"？**
`npm install -g @zed-industries/claude-agent-acp`，确认 `which claude-agent-acp` 有输出。

**agent-shell 和 Claude Chat 怎么选？**
Claude Chat 是 Emacs 原生实现（diff 高亮、会话恢复），agent-shell 是终端包装（体验等同于直接跑 `claude` 命令）。
- 日常开发用 Claude Chat
- 需要完整终端交互时用 agent-shell。

### gptel — 底部抽屉式 LLM 聊天

`M-RET` 弹出/关闭 `*gptel*` 抽屉，DeepSeek V4 后端（OpenAI 兼容协议）。适合随手问问题、快速代码片段生成、翻译等轻量对话。

快捷键（gptel buffer 内）：

| 键        | 功能     |
|-----------|----------|
| `C-c RET` | 发送输入 |
| `M-RET`   | 关闭抽屉 |

Evil 协作：gptel buffer 默认 emacs state，`Escape` 切 normal 用 j/k 滚动，`C-z` 回 emacs state，与 agent-shell 行为一致。

---

## 已知问题

### lazycat-theme — Emacs 31 `:style none` 不兼容

Emacs 31 中 face `:box` 不再接受 `:style none`（有效值：`released-button`、`pressed-button`、`flat-button`、nil），导致 GUI 启动报错：

```
Eager macro-expansion failure: (error "Invalid face box" :line-width 1 :style none)
```

**修复：** 编辑 `var/packages/elpa/lazycat-theme/lazycat-theme.el` L418-422，移除 `:style none`：

```diff
-    (custom-button :box '(:line-width 1 :style none))
+    (custom-button :box '(:line-width 1))
```

> 对 `custom-button-unraised`、`custom-button-pressed-unraised`、`custom-button-pressed`、`custom-button-mouse` 做同样修改。视觉效果不变。

---

## CLAUDE.md

本仓库的 `CLAUDE.md` 是 AI 编码代理的工作契约文件，在会话开始时自动加载到模型上下文。

Claude Code 自动读取项目根目录的 `CLAUDE.md`（全局版本在 `~/.claude/CLAUDE.md`）。其他工具的兼容方式：

```bash
ln -s CLAUDE.md AGENTS.md      # Codex CLI、Cursor 等
ln -s CLAUDE.md GEMINI.md      # Gemini CLI
```

本仓库的 `CLAUDE.md` 已针对个人 dotfiles 项目定制。复制到其他项目时需替换项目特定的路径和工具链引用。
