# dotfiles

个人 macOS / Ubuntu 开发环境配置。

## 快速开始

### 全新 Ubuntu（连 git 都没有）

```bash
curl -fsSL https://raw.githubusercontent.com/robertzhouxh/dotfiles/main/bootstrap.sh | bash
cd ~/dotfiles && ./ubuntu.sh
```

`bootstrap.sh` 只用系统自带的 apt / curl 把「能 clone 仓库」这一步打通；`ubuntu.sh` 接着装开发工具、生成 locale、部署 dotfiles、把登录 shell 切到 zsh。两者都可反复执行。

想先看看会动什么，两个脚本都支持 `--dry-run`：

```bash
curl -fsSL https://raw.githubusercontent.com/robertzhouxh/dotfiles/main/bootstrap.sh | bash -s -- --dry-run
./ubuntu.sh --dry-run
```

### 已有仓库的机器

```bash
./deploy.sh              # 部署 dotfiles（覆盖前自动备份）
./deploy.sh --link       # 改用符号链接，之后 git pull 即生效
./deploy.sh --dry-run    # 先看看会动哪些文件
```

macOS 上接着跑 `./brew.sh`，然后 `./vim.sh` 和 `./emacs.sh` 部署 vim / Emacs。

> `.vim` 和 `.emacs.d` 不走 `deploy.sh`——它们建符号链接而不是复制，见 `vim.sh` / `emacs.sh`。

### 门禁测试

```bash
test/run-tests.sh        # 87 个用例，约 1.1 秒，无网络无 sudo
```

覆盖：所有 shell 文件的语法、`.alias` / `.envv` 在 mac 与 linux 两个平台下的真实行为、`.zprofile` 的 brew 探测、`deploy.sh` 的复制/链接/幂等/备份、`bootstrap.sh` 的管道执行。平台分支靠注入 `DOTFILES_OS` 来验证，所以两个平台都能在本机跑。

`test/install-hooks.sh` 会把 pre-commit hook 装上，之后每次 commit 自动跑。

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

### TRAMP-RPC：高速远程文件访问

Emacs 已配置 [TRAMP-RPC](https://github.com/ArthurHeymans/emacs-tramp-rpc)。常规 SSH TRAMP（`/ssh:`）仍是默认方式；需要更快的目录、文件和 Git 操作时，使用 `rpc` 方法：

```text
/rpc:user@host:/path/to/file
```

例如，按 `C-x C-f` 后输入 `/rpc:alice@example.com:/srv/app/README.md` 打开远程文件；按 `C-x d` 后输入 `/rpc:alice@example.com:/srv/app/` 打开远程目录。在 Evil normal、visual 或 motion 状态下，`SPC r` 会提示输入 `user@host` 和远端目录，并直接打开对应的 RPC Dired。

首次连接某个远程主机时，TRAMP-RPC 会将服务端二进制部署到远端的 `~/.cache/emacs/tramp-rpc/`。远端需可通过 SSH 访问，并运行受支持的 Linux 或 macOS 架构。若自动部署无法完成，执行 `M-x tramp-rpc-deploy-install-binary`；用 `M-x tramp-rpc-deploy-status` 查看本地缓存和部署状态。

---

## Ubuntu

### ubuntu.sh 装了什么

- **核心**：git / curl / wget / rsync / gnupg / zsh / 编译工具链（build-essential、cmake、autoconf、automake、texinfo）以及 Emacs 的构建依赖（libncurses-dev、libgnutls28-dev、libxml2-dev、libjansson-dev 等）
- **可选**：vim、ripgrep、fzf、tree、htop、btop、jq、unzip、zip、xdg-utils、net-tools、bind9-dnsutils、autojump、fd-find

可选包装不上只提示不中断。上面每一项都核对过 jammy 的真实索引；btop / ripgrep / fzf / fd-find / autojump 在 universe 里，`ubuntu.sh` 会先确保该组件已启用。

Ubuntu 22.04 的源里**没有 exa，也没有 starship**，`.alias` 和 `.bashrc` 会优雅降级。跳转用 `autojump`（`.zshrc` 会 source 它的 profile.d），没装 `zoxide`（jammy 里是 0.4.3，且没有 dotfile 会 init 它）。

### Ubuntu 上的 Emacs

**apt 里的 Emacs 是 27.1，跑不了本仓库的配置。** `.emacs.d/lisp/emacs-solo-clipboard.el:6` 声明 `Package-Requires: ((emacs "30.1"))`，配置本身也大量依赖 29+ 的 API。要装 Emacs 30 有两条路：

```bash
# 路线一：PPA（省事，版本取决于 PPA 维护者）
sudo add-apt-repository ppa:kelleyk/emacs
sudo apt update && sudo apt install emacs30

# 路线二：自己编译（可控，但耗时）
sudo apt install -y libgtk-3-dev libgif-dev libxpm-dev libjpeg-dev libtiff-dev
git clone --depth=1 --branch emacs-30 https://git.savannah.gnu.org/git/emacs.git ~/src/emacs
cd ~/src/emacs && ./autogen.sh && ./configure --with-native-compilation --with-tree-sitter && make -j"$(nproc)"
```

装好后再跑 `./emacs.sh`。首次启动会从 MELPA 全量拉包，国内建议先挂代理或换镜像源（见 `.emacs.d/lisp/emacs-init-elpa.el`）。

其余依赖：

- **字体**：配置优先找「Sarasa Mono SC」（更纱黑体）。装 `fonts-jetbrains-mono` 和更纱黑体才不会有字体回退的割裂感。
- **librime**：README 里给的是 macOS 二进制包，Linux 上要自己编译，产物放 `~/.emacs.d/librime/dist/`。
- **Rime 配置**：`rime/` 目录在 `.gitignore` 里，不在版本控制中。Linux 的 fcitx5-rime 用户目录是 `~/.config/fcitx/rime/`（见 `.emacs.d/lisp/emacs-init-path.el:26`），需要手动把配置放过去。

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
| agent-shell | `SPC a a`  | Claude Code（ACP 协议）       | 完整终端 agent、多项目并发     |
| gptel       | `SPC a g`  | DeepSeek V4（OpenAI 兼容）    | 底部抽屉式 LLM 聊天            |

配置文件：`.emacs.d/lisp/emacs-init-ai.el`

### agent-shell：终端 Agent

把 Claude Code、Codex、Gemini CLI 等终端 agent 包装成 Emacs buffer。每个会话按 `模型名 @ 目录名` 命名，多项目间 `M-x switch-to-buffer` 切换。

**前提：** 手动安装一次系统依赖：

```bash
brew install claude-code
npm install -g @zed-industries/claude-agent-acp
```

| 操作                   | 方式                      |
|------------------------|---------------------------|
| 启动 Claude Code agent | `SPC a a` / `SPC a 1`    |
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
| `SPC a a` | agent-shell（首选）|
| `SPC a 1` | agent-shell（备选）|
| `C-c C-0` | Claude Chat（SDK） |
| `C-c C-8` | Claude TUI         |
| `C-c C-9` | OpenCode           |
| `M-RET`   | gptel 解释抽屉      |
| `SPC a g` | gptel 解释抽屉      |
| `SPC a r` | gptel 改写抽屉      |
| `SPC a s` | 发送 gptel 输入    |
| `SPC a d` | 销毁 gptel 会话    |

### Evil 模式与 AI 工具协作（vibe-coding 校准）

所有 AI 终端模式（agent-shell、eat、term、Claude Chat、gptel）启动时自动进入 **emacs state**，不与 Evil 快捷键冲突。

vibe-coding 工作流：

```
SPC a a 启动 agent-shell → 自动进入 emacs state
  → 打字、RET 发送、n/p 导航 agent 输出，一切正常
  → 想用 j/k 滚动输出时，按 Escape 或快速按 jj 进入 normal state
  → 想继续打字时，按 C-z 回到 emacs state
```

| 键        | 状态   | 行为                                              |
|-----------|--------|---------------------------------------------------|
| `n`       | emacs  | agent-shell-next-item（在 prompt 处则插入 n）     |
| `p`       | emacs  | agent-shell-previous-item（在 prompt 处则插入 p） |
| `j` / `k` | normal | 逐行滚动 agent 输出                               |
| `C-z`     | normal | 回到 emacs state，必要的时候 Enter                |
| `Escape`  | emacs  | 进入 normal state（用于 j/k 滚动阅读）            |
| `j j`     | emacs  | 快速进入 normal state                             |
| `C-w h/l` | 全部   | 切换左/右窗口                                     |
| `C-w w`   | 全部   | 循环切换窗口                                       |
| `C-w o`   | 全部   | 仅保留当前窗口                                     |

配置位置：`.emacs.d/lisp/emacs-init-evil.el:27-60`

### FAQ

**怎么启动 agent-shell？**
在 Evil normal、visual 或 motion state 中按 `SPC a a`；`SPC a 1` 是同一命令的备用键位。

**agent-shell 报 "claude-agent-acp not found"？**
`npm install -g @zed-industries/claude-agent-acp`，确认 `which claude-agent-acp` 有输出。

**agent-shell 和 Claude Chat 怎么选？**
Claude Chat 是 Emacs 原生实现（diff 高亮、会话恢复），agent-shell 是终端包装（体验等同于直接跑 `claude` 命令）。
- 日常开发用 Claude Chat
- 需要完整终端交互时用 agent-shell。

### gptel：底部抽屉式 LLM 聊天

gptel 提供两种可独立切换的抽屉。`M-RET` 或 `SPC a g` 使用解释代码的 `*gptel-explain*` 并带入选区；`SPC a r` 使用改写用的 `*gptel-rewrite*`。两者都要求先选中内容。后端使用 DeepSeek V4（OpenAI 兼容协议）。

在抽屉中输入要求后按 `C-RET` 或 `C-<return>` 发送。

相关快捷键：

| 作用域                         | 键        | 功能                           |
|--------------------------------|-----------|--------------------------------|
| 全部状态                       | `M-RET`   | 切换解释抽屉（需要选区）       |
| Evil normal、visual、motion state | `SPC a s` | 发送 gptel 输入                |
| Evil normal、visual、motion state | `SPC a d` | 销毁与当前上下文匹配的抽屉     |
| Evil normal、visual、motion state | `SPC a g` | 切换解释抽屉（需要选区）       |
| Evil normal、visual、motion state | `SPC a r` | 切换改写抽屉（需要选区）       |

使用 `SPC a d` 会先中止正在进行的请求，再关闭窗口并删除与当前上下文匹配的 gptel buffer；下次按 `M-RET` 或 `SPC a g` 会创建一个全新的会话。

Evil 协作：gptel buffer 默认 emacs state，`Escape` 切 normal 用 j/k 滚动，`C-z` 回 emacs state，与 agent-shell 行为一致。

---

## Emacs 31+ 已知问题

### lazycat-theme：Emacs 31 `:style none` 不兼容

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

## Emacs 配置参考

来源：[Stealing from the Best Emacs Configs](https://emacsredux.com/blog/2026/04/07/stealing-from-the-best-emacs-configs/)

---

## Emacs 括号跳转（`C-7` / `C-8`）

把光标跳到最近的括号。来源：[Xah Lee: Emacs: Move Cursor to Bracket](http://xahlee.info/emacs/emacs/emacs_navigating_keys_for_brackets.html)

| 键    | 命令                        | 行为                                |
|-------|-----------------------------|-------------------------------------|
| `C-7` | `xah-backward-left-bracket` | 跳到上一个左括号，光标停在括号上     |
| `C-8` | `xah-forward-right-bracket` | 跳到下一个右括号，光标停在括号之后   |

与 `forward-sexp` 的区别：这两个命令不认识语法结构，只做纯文本搜索，所以语法树残缺（正在输入的半截表达式）、非 Lisp 语言、纯文本里都能用。括号表覆盖 ASCII 与 62 组 Unicode 括号（全角、CJK、数学、Dingbats 等）。

**注意事项**

- `C-7` / `C-8` 与 `C-w` / `C-x` 是**不同的事件**（`(kbd "C-7")` 求值为 `[67108919]`），不会遮蔽 `kill-region` 和 `C-x` 前缀。已用差分测试确认：加上这两个绑定后，`C-w`、`C-x`、`C-9`、`C-0`、`M-.`、`M-m`、`M-7`、`M-8` 的解析结果一个字节都没变。
- **只在 GUI 生效。** 终端（`emacs -nw`）里 `C-7` / `C-8` 与 `C-w` / `C-x` 发的是同一个字节（0x17 / 0x18），Emacs 读成后者，`local-function-key-map` 里也没有 `0x17 -> C-7` 的转换，所以这两个绑定在 tty 下按不出来。终端里用 `M-x xah-forward-right-bracket`。
- 代价：Evil normal state 下 `C-7` / `C-8` 原本是 `digit-argument`。`digit-argument` 仍可用 `M-0`…`M-9` 和 `C-u`，没有实际损失。

**位置**

| 内容         | 路径                                                |
|--------------|-----------------------------------------------------|
| 命令与括号表 | `.emacs.d/lisp/emacs-solo-brackets.el`              |
| 键位绑定     | `.emacs.d/lisp/emacs-init-keys.el`（`M-RET` 下方）  |
| 门禁测试     | `.emacs.d/test/emacs-solo-brackets-test.el`         |

---

## 门禁测试

确定性、本地、免费、永不 flaky。无需启动完整 Emacs，直接跑：

```bash
.emacs.d/test/run-tests.sh     # 当前 23 个用例，约 80ms
```

覆盖 `emacs-solo-brackets`：括号表结构不变量、正则精确性、命令落点与边界行为、模块与键位接线。

关于"正则精确性"：`regexp-opt` 对单字符输入会走 `regexp-opt-charset`，而后者**允许输出字符范围**（如 `[(-{]`）。一个跨过非括号字符的范围会让命令静默跳到普通文本上。所以测试逐个码位验证"匹配且仅匹配"目标字符集，而不是只断言"括号能匹配上"。

---

## CLAUDE

Claude Code 自动读取项目根目录的 `CLAUDE.md`（全局版本在 `~/.claude/CLAUDE.md`）。其他工具的兼容方式：

```bash
ln -s CLAUDE.md AGENTS.md      # Codex CLI、Cursor 等
ln -s CLAUDE.md GEMINI.md      # Gemini CLI
```

本仓库的 `CLAUDE.md` 已针对个人 dotfiles 项目定制。复制到其他项目时需替换项目特定的路径和工具链引用。

## CODEX

备份相关配置后，按下面的内容更新 Codex。

### `~/.codex/config.toml`

```toml

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

```

如果存在旧版的 `[agents]` 配置块，请移除整个块。它与 `multi_agent_v2` 不兼容。

### `~/.codex/AGENTS.md`

```markdown
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
```

### `~/.codex/agents/default.toml`

如果该文件存在，备份后覆写；不存在则新建。

```toml
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

## RTK

```
brew install rtk

rtk --version   # Should show "rtk 0.28.2"
rtk gain        # Should show token savings stats

# 1. Install for your AI tool
rtk init -g                     # Claude Code / Copilot (default)
rtk init -g --gemini            # Gemini CLI
rtk init -g --codex             # Codex (OpenAI)
rtk init -g --agent cursor      # Cursor
rtk init -g --agent windsurf    # Windsurf
rtk init --agent cline          # Cline / Roo Code
rtk init --agent kilocode       # Kilo Code
rtk init --agent antigravity    # Google Antigravity
rtk init -g --agent pi          # Pi
rtk init --agent hermes         # Hermes
rtk init -g --agent droid       # Factory Droid

# 2. Restart your AI tool, then test
git status  # Automatically rewritten to rtk git status
```
