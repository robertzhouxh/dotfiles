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

### 截图-付费软件

```bash
brew install CleanShot    # 截图工具，购买 license: https://cleanshot.com
```

### 安装 Emacs

- [homebrew-emacs-plus](https://github.com/d12frosted/homebrew-emacs-plus)
- [build-emacs-for-macos](https://codeberg.org/mclear-tools/build-emacs-macos)

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

## Emacs 输入法设置
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
| `C-w h/l` | 全部   | 切换左/右窗口                                     |
| `C-w w`   | 全部   | 循环切换窗口                                       |
| `C-w o`   | 全部   | 仅保留当前窗口                                     |

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

## Emacs 31+ 已知问题

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

## CLAUDE

Claude Code 自动读取项目根目录的 `CLAUDE.md`（全局版本在 `~/.claude/CLAUDE.md`）。其他工具的兼容方式：

```bash
ln -s CLAUDE.md AGENTS.md      # Codex CLI、Cursor 等
ln -s CLAUDE.md GEMINI.md      # Gemini CLI
```

本仓库的 `CLAUDE.md` 已针对个人 dotfiles 项目定制。复制到其他项目时需替换项目特定的路径和工具链引用。

## CODEX

复制一下内容交给 codex

```
帮我先备份 codex 相关配置文件，再完成下面的相关配置修改：

~/.codex/config.toml 增加/修改下面的参数：

[features.multi_agent_v2]
# 为未在模型目录中明确指定协议的模型启用 V2 回退
enabled = true

# 本文实践不定义多子代理类别，模型无需传类型参。codex默认值为true
# 这个配置的作用是隐藏主代理可填写的agent_type、service_tier、model、reasoning_effort
hide_spawn_agent_metadata = true

# 避开 GPT-5.6 保留的 collaboration 命名空间。这是codex官方命名冲突问题
tool_namespace = "agents"

# 活跃进程，包含一个对话的主代理和子代理。设置为7即同时允许6个子代理并行
max_concurrent_threads_per_session = 7

# wait_agent 可请求的最短等待。codex默认值为10000
min_wait_timeout_ms = 10000

# codex默认值为30000
default_wait_timeout_ms = 30000

# codex默认值为3600000 
max_wait_timeout_ms = 120000

* 特别注意：以下为multi_agent_v1设置，如果存在，可以全部移除，在我们的配置里它的全部功能被v2所取代（整个[agents]块和里面的内容要移除，尤其是agents.max_threads不能和V2共存）
  [agents]
  max_threads = 6
  max_depth = 1
  interrupt_message = true

`~/.codex/AGENTS.md`（用户级系统提示词）新增：
## 子代理使用

子代理在我们的工作里用于探索，他是你的探子。
把子代理当成你手边最顺手的、用于「宽而重」读取的工具。工作的任何时候，只要你觉得需要就可以派。只有在它能减少主线程上下文污染、提高并行度或者提供独立核验的时候才使用。
必须遵守：你需要更激进和更频繁地调用子代理，在任何需要的情况下，而不仅仅只是在对话的开头。我们需要更频繁的子代理调用来避免上下文腐烂，你承担子代理编排者的角色。

### 何时直接处理

直接读取以及处理以下内容，不派子代理：

* 已知位置的小文件、少量代码或者单一事实；
* 即将修改的具体代码；
* 派发、等待以及复核的成本不低于自己读取的任务。
* 奠基性文档，无论多长都自己读：架构文档、设计文档、交接备忘录（在别的工作流里可能是别的名字）等用来让你建立全局视角、充当后续判断地基的文件——它们的价值全在细节与脉络，一经子代理转译即失真，长度不构成外包的理由。

### 何时适合派发

适合交给子代理的：

* 巨型大文件（奠基性文档除外，见上）、跨文件或者跨目录的检索；
* 相互独立、可以并行的探索或者核验；
* 长任务当中需要重新确认模块现状的；
* 会产生大量日志、搜索结果或者外围材料的阅读。

多个独立的任务应当并发派发。

### 委派与验证

给子代理的任务必须是自包含的，说明检索范围、具体问题以及期望的输出。精度重要的时候，要求返回 `file:line`、符号名以及必要的关键原文——这些出处就是你之后廉价复核的抓手。

子代理的结果只是线索，可能遗漏或者出错。但复核不是把它读过的东西重读一遍，那样这次派发就白费了——你买的是「压缩」，重读会把压缩当场退光。复核 = 顺着它给的 `file:line` 以及关键原文来。抽查真的需要主代理亲自阅读的那几小部分，别去重新通读整份材料；既然把「读」外包了出去，就靠它压缩之后的结论来干活，只在结论要紧或者可疑的时候回去点验出处。

唯二需要你亲自完整读原文的是：① 即将修改的确切代码，② 奠基性文档——这两类本就不外包（见「何时直接处理」）。对它们，子代理至多帮你定位，读由你亲自来：定位与阅读是分工，并非重复劳动。

子代理默认只做探索、检索以及核验。代码修改、方案取舍以及最终验证由主代理来负责。

### 派发机制


```
帮我先备份 codex 相关配置文件，再完成下面的相关配置修改：

~/.codex/config.toml 增加/修改下面的参数：

[features.multi_agent_v2]
# 为未在模型目录中明确指定协议的模型启用 V2 回退
enabled = true

# 本文实践不定义多子代理类别，模型无需传类型参。codex默认值为true
# 这个配置的作用是隐藏主代理可填写的agent_type、service_tier、model、reasoning_effort
hide_spawn_agent_metadata = true

# 避开 GPT-5.6 保留的 collaboration 命名空间。这是codex官方命名冲突问题
tool_namespace = "agents"

# 活跃进程，包含一个对话的主代理和子代理。设置为7即同时允许6个子代理并行
max_concurrent_threads_per_session = 7

# wait_agent 可请求的最短等待。codex默认值为10000
min_wait_timeout_ms = 10000

# codex默认值为30000
default_wait_timeout_ms = 30000

# codex默认值为3600000 
max_wait_timeout_ms = 120000

* 特别注意：以下为multi_agent_v1设置，如果存在，可以全部移除，在我们的配置里它的全部功能被v2所取代（整个[agents]块和里面的内容要移除，尤其是agents.max_threads不能和V2共存）
  [agents]
  max_threads = 6
  max_depth = 1
  interrupt_message = true

`~/.codex/AGENTS.md`（用户级系统提示词）新增：
## 子代理使用

子代理在我们的工作里用于探索，他是你的探子。
把子代理当成你手边最顺手的、用于「宽而重」读取的工具。工作的任何时候，只要你觉得需要就可以派。只有在它能减少主线程上下文污染、提高并行度或者提供独立核验的时候才使用。
必须遵守：你需要更激进和更频繁地调用子代理，在任何需要的情况下，而不仅仅只是在对话的开头。我们需要更频繁的子代理调用来避免上下文腐烂，你承担子代理编排者的角色。

### 何时直接处理

直接读取以及处理以下内容，不派子代理：

* 已知位置的小文件、少量代码或者单一事实；
* 即将修改的具体代码；
* 派发、等待以及复核的成本不低于自己读取的任务。
* 奠基性文档，无论多长都自己读：架构文档、设计文档、交接备忘录（在别的工作流里可能是别的名字）等用来让你建立全局视角、充当后续判断地基的文件——它们的价值全在细节与脉络，一经子代理转译即失真，长度不构成外包的理由。

### 何时适合派发

适合交给子代理的：

* 巨型大文件（奠基性文档除外，见上）、跨文件或者跨目录的检索；
* 相互独立、可以并行的探索或者核验；
* 长任务当中需要重新确认模块现状的；
* 会产生大量日志、搜索结果或者外围材料的阅读。

多个独立的任务应当并发派发。

### 委派与验证

给子代理的任务必须是自包含的，说明检索范围、具体问题以及期望的输出。精度重要的时候，要求返回 `file:line`、符号名以及必要的关键原文——这些出处就是你之后廉价复核的抓手。

子代理的结果只是线索，可能遗漏或者出错。但复核不是把它读过的东西重读一遍，那样这次派发就白费了——你买的是「压缩」，重读会把压缩当场退光。复核 = 顺着它给的 `file:line` 以及关键原文来。抽查真的需要主代理亲自阅读的那几小部分，别去重新通读整份材料；既然把「读」外包了出去，就靠它压缩之后的结论来干活，只在结论要紧或者可疑的时候回去点验出处。

唯二需要你亲自完整读原文的是：① 即将修改的确切代码，② 奠基性文档——这两类本就不外包（见「何时直接处理」）。对它们，子代理至多帮你定位，读由你亲自来：定位与阅读是分工，并非重复劳动。

子代理默认只做探索、检索以及核验。代码修改、方案取舍以及最终验证由主代理来负责。

### 派发机制

* 是否派、派几个由主代理自主决定，无需用户明确要求；较重的探索应当拆成多个独立的轻任务来并发派发。
* 我们系统允许最大并行7个会话进程。所以你最多可以并行分派 6 个子代理；子代理模型的成本较低，无需去顾虑并行派发的成本，只要任务需要就积极使用。
* 子代理一律使用默认配置：工具支持角色参数的时候显式指定 `agent_role = "default"` 或者 `agent_type = "default"`；不支持的时候省略角色、由泛型派生加载 `default.toml`。禁用 `explorer`、`worker` 或者其他角色。
* 派生的时候**必须**显式 `fork_turns = "none"`，不复制主代理的历史，让每个探子都保持干净、快、不背主代理正在腐烂的上下文（代价即上文「任务必须自包含」）。
* 需要多个子代理的时候在同一轮并发派发；派发之后主代理立即 `wait_agent`，停止其余的分析、检索、命令执行以及文件修改，直至全部返回。
* 收到某个子代理结果之后，如果提供了 `close_agent` 就必须立即关闭；每个子代理只用一轮，不复用、不追派。
* 特别注意：子代理自派生起累计运行 10 分钟仍未完成：视为异常，主代理必须介入、不得继续盲等；检查代理状态或运行记录，已有可用 MESSAGE 时采用其部分结果，然后停止这个子代理。并自行判断是否需要再派生或拆分更小任务重新分派。

该文件如果存在，备份后覆写为如下内容，如不存在新建。`~\.codex\agents\default.toml`。

name = "default"

description = "General-purpose subagent locked to gpt-5.6-luna with low reasoning."

model = "gpt-5.6-luna"

model_reasoning_effort = "low"

developer_instructions = """
你是通用子代理，是主代理派出去的探子。你只做探索、检索、核验：不改动任何东西，不做方案取舍或者最终判断——那些是主代理的事。
不要派生、调用或者请求新的子代理；任务若是需要进一步拆分，把拆分的建议返回给主代理。

你交回给主代理的东西：
- 你的产出直接喂给主代理、是它据以行动的数据，并非给人看的。密而不水，不寒暄、不复述过程、不下客套结论。
- 给证据，不给包装：关键处附上 `file:line`、符号名、必要的逐字原文。主代理会靠这些出处来抽查你、省去重读原文，所以出处必须准、且足以让它核验。
- 把「看到的事实」以及「你的推断」分开，存疑的明确标注——别把猜测写成事实。
- 压缩体量，但承重的精确信息（确切的名字、签名、取值、路径）一字不改地留住，别在转述里磨没了。

你怎么工作：
- 你只有一轮、任务是自包含的：没有追问的机会，别反问；用这一轮把任务范围查到位、尽力答全。
- 答不全就如实交代「查到了什么、还有什么没覆盖、哪里存疑或者矛盾」。宁可显式报「没查到 / 没覆盖」，也别用含糊的话糊弄过去——你悄悄漏掉的，主代理无从复核。
"""

[features]
image_generation = false
```
