# 初始化

同步 .files 到 home 目录

```
rsync -av --include='.*' --exclude='.git' --exclude='.DS_Store' --exclude='*' ./ ~/
```

# MacOS 
## 工具软件
```
./brew.sh
```
## 付费软件

```
brew install Proxifier （记得 DNS 选择 Resolve hostname through proxy)
brew install CleanShot （截图软件，桃宝宝买licence）
```

## 安裝 emacs
- 参考: https://github.com/d12frosted/homebrew-emacs-plus
- 参考: https://github.com/jimeh/build-emacs-for-macos
## vim/emacs 部署

```
rm -rf ~/.emacs*
./vim.sh
./emacs.sh
```
启动 Emacs

## 安装鼠须管输入法+雾凇词库

```
git clone --depth=1 https://github.com/Mark24Code/rime-auto-deploy.git --branch latest
cd rime-auto-deploy
./installer.rb
```

## 安裝 Emacs 需要的 librime

```
curl -L -O https://github.com/rime/librime/releases/download/1.9.0/rime-a608767-macOS.tar.bz2
tar jxvf rime-a608767-macOS.tar.bz2 -C ~/.emacs.d/librime

# 如果MacOS Gatekeeper阻止第三方软件运行，可以暂时关闭它：
# 
# sudo spctl --master-disable
# # later: sudo spctl --master-enable

# 使用 toggle-input-method 来激活，默认快捷键为 C-\

```

# UbuntuOS
## 中文输入法
检查系统中文环境

在 Ubuntu 设置中打开「区域与语言」—— 「管理已安装的语言」，然后会自动检查已安装语言是否完整。若不完整，根据提示安装即可。

```
sudo apt install fcitx5 \
    fcitx5-chinese-addons \
    fcitx5-frontend-gtk4 fcitx5-frontend-gtk3 fcitx5-frontend-gtk2 \
    fcitx5-frontend-qt5

// 安装 RIME 输入法
sudo apt install fcitx5-rime

// 安装 librime
emacs-rime 会用到这个lib
 
```


## Emacs 配置

### 第三方包补丁:lazycat-theme — Emacs 31 `:style none` 兼容性修复

**问题**: Emacs 31 中 face `:box` 属性不再接受 `:style none`（有效值为 `released-button`、`pressed-button`、`flat-button` 或 nil），导致 GUI 启动报错：

```
Eager macro-expansion failure: (error "Invalid face box" :line-width 1 :style none)
```

**修复位置**: `var/packages/elpa/lazycat-theme/lazycat-theme.el` L418–422

**Patch**:

```diff
-    (custom-button                  :foreground blue   :background bg     :box '(:line-width 1 :style none))
-    (custom-button-unraised         :foreground violet :background bg     :box '(:line-width 1 :style none))
-    (custom-button-pressed-unraised :foreground bg     :background violet :box '(:line-width 1 :style none))
-    (custom-button-pressed          :foreground bg     :background blue   :box '(:line-width 1 :style none))
-    (custom-button-mouse            :foreground bg     :background blue   :box '(:line-width 1 :style none))
+    (custom-button                  :foreground blue   :background bg     :box '(:line-width 1))
+    (custom-button-unraised         :foreground violet :background bg     :box '(:line-width 1))
+    (custom-button-pressed-unraised :foreground bg     :background violet :box '(:line-width 1))
+    (custom-button-pressed          :foreground bg     :background blue   :box '(:line-width 1))
+    (custom-button-mouse            :foreground bg     :background blue   :box '(:line-width 1))
```

> 移除 `:style none` 等价于默认无样式，视觉效果不变。
# Emacs AI / LLM 工具

当前配置了三层 AI 交互方式，从轻到重：

| 工具 | 入口 | 后端 | 适用场景 |
|------|------|------|----------|
| gptel | `M-return` | DeepSeek (OpenAI 兼容) | 快速问答、查文档、临时请求 |
| Claude Chat | `C-c C-0` | DeepSeek V4 (Anthropic 兼容) | 项目级对话、文件编辑、会话恢复 |
| agent-shell | `C-c C-a` | Claude Code (ACP 协议) | 完整终端 agent 体验 |

配置文件：`emacs-init-ai.el`（claude-code + gptel + agent-shell + eat + tramp）。

## 键位速查

| 快捷键 | 功能 |
|--------|------|
| `M-return` | 弹出/收起 gptel drawer |
| `C-c C-a` | 启动 agent-shell (Claude Code) |
| `C-c C-0` | Claude Code 原生聊天 (stream-json) |
| `C-c C-8` | Claude Code TUI (订阅配额) |
| `C-c C-9` | OpenCode agent |

---

## gptel — 轻量级 LLM 交互

gptel 的核心设计不是聊天 UI，而是「Emacs 里任意文本都能发给模型，回复可以重定向到任意 buffer」。

**启动方式：**
- `M-return` — 弹出/收起底部 drawer 窗口
- `M-x gptel` — 手动创建新会话

**在 gptel buffer 内：**
- `C-c RET` — 发送输入给模型
- `C-c C-k` — 取消当前请求
- `C-u M-x gptel` — 选择不同后端或模型

**在其他 buffer 中使用（核心能力）：**
1. 选中一段文本（代码、报错、文档）
2. `M-x gptel-send` — 把选区作为 prompt 发给模型
3. 回复可插入当前 buffer、新 buffer、或 gptel 聊天 buffer

**常用 recipe：**
- 代码审查：选中函数 → `M-x gptel-send` → "review this code"
- 解释报错：选中 error log → `M-x gptel-send` → "what does this error mean"
- 翻译/改写：选中文字 → `M-x gptel-send` → "translate to Chinese"

**可用模型：**
- `deepseek-chat` — DeepSeek V3，快速便宜（默认）
- `deepseek-reasoner` — DeepSeek R1，深度推理

---

## agent-shell — 终端 Agent 集成

把 Claude Code / Codex / Gemini CLI 等 12 种终端 agent 包装成 Emacs major mode。每个会话独立 buffer，按「模型名 @ 目录名」命名。

**系统依赖（需手动安装一次）：**

```bash
brew install claude-code
npm install -g @zed-industries/claude-agent-acp
```

**启动方式：**
- `C-c C-a` — 一键在当前项目目录启动 Claude Code agent
- `M-x agent-shell` — 手动选择 provider

**在 agent-shell buffer 内：**
- `RET` — 发送输入
- `C-return` — 插入换行
- `C-c C-c` — 中断当前操作

**多项目管理：** 按目录命名 buffer，`~/dev/dotfiles` 启动 Claude Code 得到 `Claude Code Agent @ dotfiles`。`M-x switch-to-buffer` 即可切换，支持并发会话。

**与其他入口对比：**

| 入口 | 命令 | 方式 | 特点 |
|------|------|------|------|
| agent-shell | `C-c C-a` | ACP 协议 + 终端 buffer | 完整终端体验，buffer 管理 |
| Claude Chat | `C-c C-0` | stream-json + 原生渲染 | diff 高亮、会话恢复、图片粘贴 |
| TUI Chat | `C-c C-8` | ansi-term 终端 | 传统 TUI，订阅配额 |
| opencode | `C-c C-9` | ansi-term 终端 | 多任务类型 agent |

---

## Claude Code 原生聊天 (`emacs-solo-ai`)

`emacs-solo-ai` 集成 Claude Code、Ollama、Gemini、OpenCode 四种 AI 后端。

**SDK 模式 (`C-c C-0`)：** `claude --print --input-format stream-json`，走 Agent SDK 配额，渲染工具调用 diff，支持会话恢复。

**TUI 模式 (`C-c C-8`)：** 普通 `claude` 终端交互，走 Claude Code 订阅配额。

**SDK 模式快捷键：**

| 快捷键 | 功能 |
|--------|------|
| `RET` | 发送输入 |
| `C-RET` | 插入换行 |
| `C-c C-c` | 中断 Claude 进程 |
| `C-c C-i` | 粘贴剪贴板中的 PNG 图片 |
| `C-c C-k` | 终止进程（保留聊天记录） |
| `C-c C-l` | 清除聊天记录 |
| `C-c C-r` | 恢复之前的会话 |
| `C-c C-m` | 切换模型 |

**斜杠命令（在输入框中输入）：**

| 命令 | 功能 |
|------|------|
| `/clear` | 开始新会话 |
| `/model NAME` | 切换模型（如 `/model opus`） |
| `/resume` | 恢复历史会话 |

**用法特点：**
- 选中文本后按 `C-c C-0`，会提示输入问题，将选中内容作为上下文发送
- 支持从剪贴板粘贴 PNG 图片（`C-c C-i`）
- 工具调用（Edit/Write/Bash）以内联 diff 形式渲染

## Ollama / Gemini / OpenCode

- **Ollama** (`emacs-solo/ollama-run-model`)：自动列出本地模型，在 `ansi-term` 中运行
- **Gemini** (`emacs-solo/gemini-chat`)：Google Gemini CLI，按项目命名 buffer
- **OpenCode** (`emacs-solo/opencode-chat`)：支持任务类型选择（general、explore、code-reviewer 等）

## 自定义变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `emacs-solo-claude-executable` | `"claude"` | Claude 可执行文件路径 |
| `emacs-solo-claude-permission-mode` | `"acceptEdits"` | 权限模式 |
| `emacs-solo-claude-confirm-before-edit` | `t` | 编辑前是否要求确认 |
| `emacs-solo-claude-model-choices` | 见源码 | 可选模型列表 |
| `emacs-solo-claude-diff-max-lines` | `200` | 内联 diff 最大显示行数 |

## FAQ

**Q: gptel drawer 弹不出来？**
A: 确认 `DEEPSEEK_API_KEY` 环境变量已设置（`echo $DEEPSEEK_API_KEY` 有输出）。终端 Emacs 需确保 shell 环境变量已同步。

**Q: agent-shell 启动报错 "claude-agent-acp not found"？**
A: 运行 `npm install -g @zed-industries/claude-agent-acp`，确保 `claude-agent-acp` 在 PATH 中。

**Q: agent-shell 和 Claude Chat 有什么区别？**
A: Claude Chat (`C-c C-0`) 是 emacs-solo 的原生实现，用 stream-json 协议，有 diff 高亮、会话恢复等原生功能。agent-shell 把终端 Claude Code 包装进 Emacs buffer，体验更接近直接跑 `claude` 命令。选哪个看习惯。

**Q: gptel 能用其他模型吗？**
A: 可以。gptel 支持 OpenAI、Anthropic、Gemini、Ollama 等。在 `emacs-init-ai.el` 中参考 DeepSeek 示例添加新后端即可。

# CLAUDE.md — AI 编码代理的工作契约

[CLAUDE.md](./CLAUDE.md) 是本仓库的 AI 编码代理指令文件，灵感来自 [jbarbier/CLAUDE.md](https://github.com/jbarbier/CLAUDE.md)。

## 为什么需要它

没有指令的 AI 代理默认输出的是"它见过的一切的平均值"——平庸、提前停手、跳过测试、编造库、对不该问的事情请求许可。`CLAUDE.md` 在会话开始时加载到模型上下文中，充当一份长期契约，覆盖这些默认行为。

> 就像雇一个没有 brief 的承包商 vs 雇一个墙上贴着单页 spec 的承包商。

## 安装（3分钟）

### Claude Code

Claude Code 自动从项目根目录读取 `CLAUDE.md`（全局版本在 `~/.claude/CLAUDE.md`）：

```
# 在项目目录中
curl -O https://raw.githubusercontent.com/<your-fork>/CLAUDE.md/main/CLAUDE.md
# 或者直接手动复制文件
```

搞定。在该目录下启动 `claude`，规则即刻生效。

### 其他工具（Codex CLI、Cursor、Gemini CLI 等）

大多数其他代理读取 `AGENTS.md` 而非 `CLAUDE.md`。`AGENTS.md` 是新兴的跨工具标准（Codex CLI、Cursor、Gemini CLI、Jules 等均支持），内容完全相同，仅文件名不同。

不要维护两份逐渐偏离的副本——保持单一数据源，其余通过符号链接指向它：

```
# CLAUDE.md 是真实文件，其余全部指向它
ln -s CLAUDE.md AGENTS.md      # Codex CLI、Cursor 等 AGENTS.md 标准工具
ln -s CLAUDE.md GEMINI.md      # Gemini CLI
```

现在 Claude 读 `CLAUDE.md`，Codex 读 `AGENTS.md`，Gemini 读 `GEMINI.md`，三者是同一份字节。编辑一次，所有代理同步更新。

| 工具 | 读取的文件 | 接线方式 |
|------|-----------|----------|
| Claude Code | `CLAUDE.md` | 直接使用 |
| OpenAI Codex CLI | `AGENTS.md` | `ln -s CLAUDE.md AGENTS.md` |
| Cursor | `AGENTS.md`（或 `.cursor/rules/`） | `ln -s CLAUDE.md AGENTS.md` |
| Gemini CLI | `GEMINI.md` | `ln -s CLAUDE.md GEMINI.md` |
| GitHub Copilot | `.github/copilot-instructions.md` | 复制内容进去 |
| 其他工具 | 通常是 `AGENTS.md` | `ln -s CLAUDE.md AGENTS.md` |

> 如果你的工具不跟随符号链接，直接复制文件并重命名即可。规则不关心文件叫什么名字。

## 个性化

### 替换名字

文件中会引用作者名字（如 "impress Julien"、"ask Julien"），代理将其视为对话对象。用 `sed` 一键替换：

```
# macOS
sed -i '' 's/Julien/YOUR_NAME/g' CLAUDE.md

# Linux
sed -i 's/Julien/YOUR_NAME/g' CLAUDE.md
```

### 其他调整

- **`food_vision/classifier.py:47`** — 只是展示代码指向格式的示例，保留即可
- **LLM 访问规则**（"通过本地 Claude Code 路由，绝不使用外部 API"）——如果你直接调用 Anthropic 或 OpenAI API，删除或反转该段
- **gstack / skills 引用**——假定安装了 Garry Tan 的 `gstack`；如果没装，"检查技能"规则仍然有效，只是能找到的技能更少

本仓库的 `CLAUDE.md` 已针对个人 dotfiles 项目定制。复制到其他项目时，应替换项目特定的路径、工具链和偏好设置。

# 关于版本控制


