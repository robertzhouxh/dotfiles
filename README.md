# dotfiles

个人 macOS / Ubuntu 开发环境配置。

## 快速开始

### 全新 Ubuntu（连 git 都没有）

```bash
curl -fsSL https://raw.githubusercontent.com/robertzhouxh/dotfiles/main/bootstrap.sh | bash
cd ~/dotfiles && ./ubuntu.sh
```

`bootstrap.sh` 只用系统自带的 apt / curl 把「能 clone 仓库」这一步打通；`ubuntu.sh` 接着装开发工具、生成 locale、部署 dotfiles、把登录 shell 切到 zsh。两者都可反复执行。

这一轮**不装 Emacs**：apt 里只有 27.1，配置要 30.1+。按下面的「[Ubuntu 上的 Emacs](#ubuntu-上的-emacs)」自己装，装好再跑 `./emacs.sh`。

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

### vim 配置

```bash
./vim.sh                  # 链接 .vimrc / .vim → 装 vim-plug → PlugInstall
./vim.sh --dry-run        # 只打印会做什么，不落地也不联网
./vim.sh --no-plugins     # 只链接配置，不碰插件（离线时用）
./vim.sh --update-plug    # 强制重新下载 plug.vim
```

`~/.vimrc` 和 `~/.vim` 都链到仓库；插件装在 `~/.vim/plugged`，也就是仓库的 `.vim/plugged`（`.vim` 整个目录都在 `.gitignore` 里，插件不进版本控制）。`~/.vim` 原本若是真实目录，会先备份成 `~/.vim.YYYYMMDD`。想指到别的 vim 二进制上用 `VIM=/path/to/vim ./vim.sh`。

> `~/.vim` 是符号链接，`~/.vim/autoload/plug.vim` 和仓库里那个是**同一个文件**。`vim.sh` 只认仓库内那一条路径，会清掉已经坏掉的（自指成环，vim 报 `E117: Unknown function: plug#begin`）再重新下载。

## macOS

### 工具软件

```bash
./brew.sh
```

`brew.sh` 会把登录 shell 切成 `/bin/zsh`（macOS 自 Catalina 起自带，本来就在 `/etc/shells` 里）。整套配置都是照 zsh 写的：登录 shell 是 bash 时新开的终端读 `.bashrc`，`.zshrc` / `.zprofile` / starship 的 zsh 分支全都不生效。已经是 zsh 就跳过，不会反复弹密码。

改完要**重开终端**才生效。

### 截图-付费软件

```bash
brew install CleanShot    # 截图工具，购买 license: https://cleanshot.com
```

### 安装 Emacs

- [homebrew-emacs-plus](https://github.com/d12frosted/homebrew-emacs-plus)
- [build-emacs-for-macos](https://codeberg.org/mclear-tools/build-emacs-macos)

> 装完执行 `./emacs.sh` 完成部署，启动 Emacs 即可。
>
> `emacs.sh` 先验证版本——本仓库配置要 **30.1+**（`.emacs.d/lisp/` 下的 `emacs-solo-*.el` 都声明 `Package-Requires: ((emacs "30.1"))`）。版本不够直接拒绝并说明，不会先把 `~/.emacs.d` 链好再让你面对一屏加载错误。确实想拿旧版试加 `--force`；想指到别的二进制上用 `EMACS=/path/to/emacs ./emacs.sh`。

### TRAMP-RPC：高速远程文件访问

已配置 [TRAMP-RPC](https://github.com/ArthurHeymans/emacs-tramp-rpc)。常规 SSH TRAMP（`/ssh:`）仍是默认方式；需要更快的目录、文件和 Git 操作时走 `rpc` 方法：

```text
/rpc:user@host:/path/to/file
```

按 `C-x C-f` 输入 `/rpc:alice@example.com:/srv/app/README.md` 开远程文件；`C-x d` 输入 `/rpc:alice@example.com:/srv/app/` 开远程目录。Evil normal、visual 或 motion state 下按 `SPC r`，会提示 `user@host` 和远端目录并直接打开对应的 RPC Dired。

首次连某台远程主机时，TRAMP-RPC 惰性部署服务端二进制到远端 `~/.cache/emacs/tramp-rpc/`；远端要能 SSH 上去，且是受支持的 Linux 或 macOS 架构。出问题用 `M-x tramp-rpc-deploy-diagnose` 出诊断、`M-x tramp-rpc-deploy-status` 看本地缓存与部署状态、`M-x tramp-rpc-deploy-clear-cache` 清掉缓存重来。

---

## Ubuntu

### ubuntu.sh 装了什么

- **核心**：git / curl / wget / rsync / gnupg / zsh / 编译工具链（build-essential、cmake、autoconf、automake、texinfo）以及 Emacs 的构建依赖（libncurses-dev、libgnutls28-dev、libxml2-dev、libjansson-dev 等）
- **可选**：vim、ripgrep、fzf、tree、htop、btop、openssh-server、jq、unzip、zip、xdg-utils、net-tools、bind9-dnsutils、autojump、fd-find、exa 或 eza、p7zip-full（解更纱黑体的 .7z）
- **starship**：apt 源里没有，走官方安装脚本装到 `/usr/local/bin`（配置 `starship.toml` 由 `deploy.sh` 放到 `~/.config/`）
- **rtk**：同样不在 apt 里，走官方安装脚本装到 `~/.local/bin`（`.envv` 会把这个目录加进 PATH），不用 sudo、不碰系统目录。它是省 token 的命令代理，用法见下面「RTK」
- **asdf**：apt 源里同样没有，从上游 release 下 linux 二进制装到 `~/.local/bin`，不用 sudo。macOS 侧由 `brew.sh` 装。用法见下面「asdf」
- **字体**：Sarasa Mono SC（等距更纱黑体），从 GitHub release 下 `.7z` 解到 `~/.local/share/fonts`，不用 sudo。CJK 严格 2:1，markdown 表格中文才能跟 ASCII 对齐

可选包装不上只提示不中断。上面 apt 装的每一项都核对过 jammy 的真实索引；btop / ripgrep / fzf / fd-find / autojump 在 universe 里，`ubuntu.sh` 会先确保该组件已启用。

非 apt 的四项（starship / rtk / asdf / 字体）都是装过就跳过、拉不到 GitHub 只警告不中断。starship 上游只发 tar.gz，没有 `.deb` / `.rpm`，所以走官方脚本；`.zshrc` / `.bashrc` 里那段 init 本来就是 `command -v` 通过才生效，没装就退回默认样式。

`rtk` 的「已装」判据是 `rtk --version` 打得出 `rtk <版本号>`，不是「有个叫 rtk 的可执行文件」——这个名字被 crates.io 上的 Rust Type Kit 共用，只认名字会把那个异物当成已装，然后永远跳过真正要装的这个。

`asdf` 的安装有两处讲究。**版本钉在 `ubuntu.sh` 的 `ASDF_VERSION`**，不查 GitHub 的 latest：脚本要离线可跑、每次跑结果一致（换版本：`ASDF_VERSION=x.y.z ./ubuntu.sh`）。**先解到临时目录、验过版本对得上再落盘**：落点上的 asdf 版本对不上（哪怕只差个 `-rc1` 后缀）就当没装对、换掉它；装在别处（brew、发行版包、用户自己 clone 的）则原样不动，免得两份互相遮蔽。PATH 侧由 `.envv` 接，闸门是 **shims 目录在不在**，不是 `command -v asdf`——后者在二进制还没进 PATH 的机器上会让整段静默失效。

`ls` 增强用 `exa` 或 `eza`（`eza` 是 `exa` 的活跃分支，exa 上游 2021 年后归档）：22.04 的 universe 里只有 `exa` 0.10.1，24.04 起只剩 `eza`，两个都列在可选包里，各发行版自然只命中一个，`.alias` 两个都认、优先 `eza`。装不上只是没有增强，`ls` 还是 `ls`。

**`--git` 在 Ubuntu 的 `exa` 上不能用。** 那个包是关掉 git feature 编的，传了不是「少显示一列」而是整个命令以 `rc=3` 失败（`Options --git ... because 'git' feature was disabled in this build`）。`.alias` 因此运行时探测一次再决定加不加，别照着「上游默认开着」写死。`eza` 和 brew 的 `exa` 都支持。

`--icons` 要终端字体带 Nerd Font 图标，否则图标位置显示成方块，换个字体或去掉 `--icons` 即可。跳转用 `autojump`（`.zshrc` 会 source 它的 profile.d），没装 `zoxide`（jammy 里是 0.4.3，且没有 dotfile 会 init 它）。

### Ubuntu 上的 Emacs

**apt 里的 Emacs 是 27.1，跑不了本仓库的配置。** `.emacs.d/lisp/` 下的 `emacs-solo-*.el` 包头都写着 `Package-Requires: ((emacs "30.1"))`。只能自己编译 30：

```bash
sudo apt install -y libgtk-3-dev libgif-dev libxpm-dev libjpeg-dev libtiff-dev
git clone --depth=1 --branch emacs-30 https://git.savannah.gnu.org/git/emacs.git ~/src/emacs
cd ~/src/emacs && ./autogen.sh && ./configure --with-native-compilation --with-tree-sitter && make -j"$(nproc)"
```

装好后再跑 `./emacs.sh`（同一个 ≥ 30.1 闸门）。首次启动会从 MELPA 全量拉包，国内建议先挂代理，或把 `.emacs.d/lisp/emacs-init-elpa.el` 里的 `package-archives` 换成能连上的镜像源。

其余依赖：

- **字体**：配置优先找「Sarasa Mono SC」（等距更纱黑体）——它是等宽字体里 CJK 严格 2:1 的那个，markdown 表格的中文才能跟 ASCII 对齐。`ubuntu.sh` 会下 GitHub release 装到 `~/.local/share/fonts`（jammy 源里没有 `fonts-sarasa-gothic`，24.04 才进 Debian/Ubuntu）。
- **librime**：Emacs 内嵌 rime 的动态模块要链 librime。Linux 上 `sudo apt install librime-dev` 即可——头文件落到 `/usr/include/`，rime 包 `make lib` 的默认分支（`-lrime`）直接链上，不用设 `rime-librime-root`；只有 macOS 才下载二进制包（见下方「For MACOS」一节）。
- **Rime 配置**：`rime/` 目录在 `.gitignore` 里，不在版本控制中。两套 Rime 用户目录是分开的，别混：
  - 系统级 fcitx5-rime：`~/.local/share/fcitx5/rime/`（fcitx5 默认用户目录）。
  - Emacs 内嵌 rime：`~/.config/fcitx/rime/`（见 `.emacs.d/lisp/emacs-init-path.el` 里的 `my-rime-user-data-dir`）。
  两处都需要手动把雾凇(rime-ice) 配置放过去。

### 中文输入法

`ubuntu.sh` 会装 fcitx5 + Rime（`fcitx5-rime` / `fcitx5-config-qt` 都在里面）并配好环境变量与自启。GNOME Wayland 默认框架是 ibus，不显式把 `GTK_IM_MODULE` / `QT_IM_MODULE` / `XMODIFIERS` 指向 fcitx，fcitx5 起不来也接不进应用。装完注销重登，还剩一步 GUI 脚本替不了：

```bash
# 1. 注销重新登录
# 2. fcitx5-configtool → 输入法 → + → 添加「中州韻 Rime」，去掉多余项
# 3. Ctrl+Space 切中英文
```

Rime 配置用雾凇(rime-ice)，放在 `~/.local/share/fcitx5/rime/`（不在本仓库里）；Emacs 内嵌 rime 走 `~/.config/fcitx/rime/`，两套分开。

---

## Emacs 输入法设置

### 鼠须管 + 雾凇词库 For MACOS & Ubuntu

```bash
git clone --depth=1 https://github.com/Mark24Code/rime-auto-deploy.git --branch latest
cd rime-auto-deploy
./installer.rb
```

### librime（Emacs 内嵌输入法依赖）For MACOS

```bash
curl -L -O https://github.com/rime/librime/releases/download/1.17.0/rime-33e7814-macOS-universal.tar.bz2
tar jxvf rime-33e7814-macOS-universal.tar.bz2 -C ~/.emacs.d/librime

# 如果 Gatekeeper 阻止加载，临时关闭：
#   sudo spctl --master-disable
# 安装后恢复：
#   sudo spctl --master-enable
```

Emacs 中按 `C-\` 激活输入法。

---

## Emacs AI / LLM 工具

三层 AI 交互。agent-shell 与 gptel 配在 `.emacs.d/lisp/emacs-init-ai.el`，Claude Chat 配在 `.emacs.d/lisp/emacs-solo-ai.el`：

| 工具        | 快捷键    | 后端                          | 场景                           |
|-------------|-----------|-------------------------------|--------------------------------|
| Claude Chat | `C-c C-0` | DeepSeek V4（Anthropic 兼容） | 项目级对话、文件编辑、会话恢复 |
| agent-shell | `SPC a a` | Claude Code CLI + DeepSeek V4 | 完整终端 agent、多项目并发     |
| gptel       | `SPC a g` | DeepSeek V4（OpenAI 兼容）    | 底部抽屉式 LLM 聊天            |

### agent-shell：终端 Agent

把 Claude Code、Codex、Gemini CLI 等终端 agent 包装成 Emacs buffer。每个会话按 `Claude Agent @ 项目名` 命名（agent 名 + 项目名，不是模型名），多项目间 `M-x switch-to-buffer` 切换。

前提是手动装一次系统依赖：

```bash
brew install claude-code
npm install -g @zed-industries/claude-agent-acp
```

`claude-agent-acp` 子进程继承 `.emacs.d/lisp/emacs-init-ai.el` 里设的 `ANTHROPIC_BASE_URL` / `ANTHROPIC_MODEL`，所以这里的 Claude Code 实际跑在 DeepSeek 的 Anthropic 兼容端点上。

| 操作                   | 方式                      |
|------------------------|---------------------------|
| 启动 Claude Code agent | `SPC a a` / `SPC a 1`    |
| 手动选择 provider      | `M-x agent-shell`         |
| 发送输入               | `RET`                     |
| 插入换行               | `S-return`                |
| 中断                   | `C-c C-c`                 |

### Claude Chat 原生模式（`emacs-solo-ai`）

`C-c C-0` SDK 模式（stream-json 协议，diff 高亮、会话恢复、图片粘贴）；`C-c C-8` TUI 模式（传统终端交互，走订阅配额）；`C-c C-9` opencode agent（多任务类型）。

SDK 模式快捷键：

| 键        | 功能     | 键        | 功能          |
|-----------|----------|-----------|---------------|
| `RET`     | 发送     | `C-c C-i` | 粘贴 PNG 图片 |
| `C-RET`   | 换行     | `C-c C-l` | 清除聊天记录  |
| `C-c C-c` | 中断进程 | `C-c C-r` | 恢复历史会话  |
| `C-c C-k` | 终止进程 | `C-c C-m` | 切换模型      |

输入框里可直接敲斜杠命令：`/clear` 开始新会话、`/model NAME` 切换模型、`/resume` 恢复历史会话。

### Evil 模式与 AI 工具协作（vibe-coding 校准）

所有 AI 终端模式（agent-shell、eat、term、Claude Chat、gptel）启动时自动进入 **emacs state**，不与 Evil 快捷键冲突。流程是：`SPC a a` 起 agent-shell 后正常打字、`RET` 发送、`n/p` 导航输出；想用 `j/k` 滚动输出就快速 `jj` 进 normal state；想继续打字按 `C-z` 回 emacs state。

> `Escape` 在这里不是出口：Evil 只把它绑在 insert / replace / normal / visual 状态上，emacs state 下它是 Meta 前缀。要回 normal 用 `jj` 或 `C-z`（Evil 的 toggle 键）。eat / term 例外——Escape 直接送给终端里的程序。

| 键        | 状态   | 行为                                              |
|-----------|--------|---------------------------------------------------|
| `n`       | emacs  | agent-shell-next-item（在 prompt 处则插入 n）     |
| `p`       | emacs  | agent-shell-previous-item（在 prompt 处则插入 p） |
| `j` / `k` | normal | 逐行滚动 agent 输出                               |
| `C-z`     | 双向   | normal → emacs state（必要时 Enter）；emacs → normal |
| `j j`     | emacs  | 快速进入 normal state                             |
| `C-w h/l` | 全部   | 切换左/右窗口                                     |
| `C-w w`   | 全部   | 循环切换窗口                                       |
| `C-w o`   | 全部   | 仅保留当前窗口                                     |

配置位置：`.emacs.d/lisp/emacs-init-evil.el`（`skye/evil-emacs-state-jj` 与 emacs-state 钩子）

### FAQ

**怎么启动 agent-shell？** Evil normal、visual 或 motion state 下按 `SPC a a`；`SPC a 1` 是同一命令的备用键位。

**报 "claude-agent-acp not found"？** 跑 `npm install -g @zed-industries/claude-agent-acp`，确认 `which claude-agent-acp` 有输出。

**agent-shell 和 Claude Chat 怎么选？** Claude Chat 是 Emacs 原生实现（diff 高亮、会话恢复），日常开发用它；agent-shell 是终端包装，体验等同于直接跑 `claude`，需要完整终端交互时用它。

### gptel：底部抽屉式 LLM 聊天

两个可独立切换的抽屉：`M-RET` / `SPC a g` 是解释代码的 `*gptel-explain*`，`SPC a r` 是改写用的 `*gptel-rewrite*`，两者都要先选中内容，后端 DeepSeek V4（OpenAI 兼容协议）。抽屉里输入要求后按 `C-RET` 发送；`SPC a s` 发送、`SPC a d` 销毁抽屉（Evil normal、visual、motion state 下可用，`M-RET` 全状态可用）。`SPC a d` 会先中止进行中的请求，再关窗删掉匹配当前上下文的 buffer，下次按 `M-RET` 或 `SPC a g` 是全新会话。

---

## Emacs 31+ 已知问题

### lazycat-theme：Emacs 31 `:style none` 不兼容

Emacs 31 中 face `:box` 不再接受 `:style none`（有效值：`released-button`、`pressed-button`、`flat-button`、nil），`lazycat-theme` 主文件的 `custom-button` 一族 face 用了 `:box '(:line-width 1 :style none)`，导致 GUI 启动报错：

```
Eager macro-expansion failure: (error "Invalid face box" :line-width 1 :style none)
```

**修复（自动）：** `.emacs.d/lisp/emacs-solo-lazycat-theme.el` 里的 `emacs-solo-lazycat-theme-ensure-box-style` 在 `:init`（`require` 前）幂等去掉 `:style none`，`:vc :rev :newest` 每次启动 `git pull` 还原文件后会自动再补。涉及 `custom-button`、`custom-button-unraised`、`custom-button-pressed-unraised`、`custom-button-pressed`、`custom-button-mouse`，视觉效果不变。

补丁必须在 `:init` 跑、不能在 `:config` 跑：主文件的 `lazycat-themes-base-faces` 在 `require` 时读进内存，`:config` 里再改盘就晚了。

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

与 `forward-sexp` 的区别：这两个命令不认识语法结构，只做纯文本搜索，所以语法树残缺（正在输入的半截表达式）、非 Lisp 语言、纯文本里都能用。括号表共 62 组，其中 ASCII 4 组（`()` `[]` `{}` `<>`）、Unicode 58 组（全角、CJK、数学、Dingbats 等）。

**注意事项**

- `C-7` / `C-8` 与 `C-w` / `C-x` 是**不同的事件**（`(kbd "C-7")` 求值为 `[67108919]`），不遮蔽 `kill-region` 和 `C-x` 前缀。差分测试确认过：加上这两个绑定后，`C-w`、`C-x`、`C-9`、`C-0`、`M-.`、`M-m`、`M-7`、`M-8` 的解析结果一个字节没变。
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

确定性、本地、免费、永不 flaky。

```bash
test/run-tests.sh              # shell 侧，200+ 个用例，墙钟约 11 秒（无网络无 sudo）
.emacs.d/test/run-tests.sh     # Emacs 侧，20+ 个用例，约 10ms，不启动完整 Emacs
```

shell 侧那 11 秒几乎都花在反复起子进程上，CPU 时间只有 3 秒左右——不是断言慢。数字都写「N+」而不是确切值：确切值会随测试增删过期，以输出末尾的「结果：N 通过，M 失败」为准。

`test/install-hooks.sh` 装上 pre-commit hook，之后每次 commit 自动跑 shell 侧。shell 侧会用 `emacs.sh --dry-run` 当版本判据、顺带跑一遍 Emacs 侧；版本不够或没装 Emacs 就跳过并说明原因，不会让门禁红掉。

Emacs 侧覆盖 `emacs-solo-brackets`：括号表结构不变量、正则精确性、命令落点与边界行为、模块与键位接线。其中的「正则精确性」值得一说：`regexp-opt` 对单字符输入会走 `regexp-opt-charset`，而它**允许输出字符范围**——一旦输出成跨过非括号字符的范围（如 `[(-{]`），命令就会静默跳到普通文本上。当前这张表恰好没触发，但测试按 Unicode 区块划窗口、逐码位双向验证（既不漏匹配也不多匹配），而不是只断言「括号能匹配上」。

另覆盖 `emacs-solo-lazycat-theme` 的两个启动时幂等补丁：去掉 `:style none`、补 lexical-binding cookie，各验证「改了该改的 / 不误改别的 / 跑两次不变」。

---

## CLAUDE

Claude Code 只认 `CLAUDE.md` 这个文件名，而本仓库根目录没有这个文件，所以下面两份**都不会被自动加载**。中文版实际是通过全局的 `~/.claude/CLAUDE.md` 生效的：那份内容与 `CLAUDE_CN.md` 相同，但是独立副本而非软链，改一边得手动同步另一边。

两份内容一一对应：`CLAUDE_EN.md` 是英文版（改名前就叫 `CLAUDE.md`），`CLAUDE_CN.md` 是中文版。都针对个人 dotfiles 项目定制，复制到别的项目要替换掉项目特定路径和工具链引用。

要让某个工具读到这里的一份：

```bash
ln -s CLAUDE_CN.md CLAUDE.md      # Claude Code
ln -s CLAUDE_CN.md AGENTS.md      # Codex CLI、Cursor 等
ln -s CLAUDE_CN.md GEMINI.md      # Gemini CLI
```

## CODEX

先备份相关配置，再按下面的内容更新 Codex。三段字面量（toml 与 markdown）可以直接照抄。

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

## asdf

语言运行时版本管理器：Node / Erlang / Elixir / Go 这类「同一台机器上要多个版本」的东西由它装，brew 和 apt 只管装 `asdf` 自己。上游是 [asdf-vm/asdf](https://github.com/asdf-vm/asdf)，官方入门 [Getting Started](https://asdf-vm.com/guide/getting-started.html)。

```
# macOS：brew.sh 已经装了
brew install asdf

# Ubuntu：ubuntu.sh 已经装好，落在 ~/.local/bin（.envv 会把这个目录加进 PATH）。
# 手动补装就是下官方 release 的 linux 二进制解出单个 asdf，见 ubuntu.sh 的 install_asdf

asdf --version   # 0.16 起是 Go 重写的单体二进制，「git clone ~/.asdf 就能用」那套已经不作数

# 数据目录默认 ~/.asdf，要挪就设 ASDF_DATA_DIR（.envv 认它；shims 由 .envv 挂进 PATH）
# 装一个运行时：加插件 → 装版本 → 定版本。-u 写全局，不加写当前目录的 .tool-versions
asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git
asdf install nodejs latest
asdf set -u nodejs 22.11.0

asdf list nodejs
asdf current
```

`latest` 只是运行时解析用的关键字，落到 `.tool-versions` 里的是解析出的确切版本。`asdf install` 干的是真编译或真下载：Node 有官方预编译包，Erlang / Elixir 要从源码编，第一次会跑很久。装完 shims 自动就位，新开的终端直接 `node -v` 即可。

用 asdf 装 Go 的话 `.envv` 会顺手把 `GOROOT` 指到那个版本目录（`asdf where golang` 取得到才设，取不到保持原样）。

## RTK

把 `git status` 之类命令的输出压掉 60-90% 再交给 agent 读，给 Claude Code 省 token。上游是 [rtk-ai/rtk](https://github.com/rtk-ai/rtk)。

```
# macOS
brew install rtk

# Ubuntu：ubuntu.sh 已经装好，落在 ~/.local/bin（.envv 会把它加进 PATH）。
# 手动补装同一个官方脚本：
curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh

rtk --version   # Should show "rtk X.Y.Z"（本机核对时是 0.46.0）
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

---

## 不参与自动部署的两批配置

`deploy.sh` 的清单里没有这两批，得手动取用：

- **`cvr-max.yaml` / `cvr-min.yaml`**：Clash Verge Rev 的配置。`max` 是带注释的完整版，`min` 只留通路（7890 + fake-ip DNS + 两条策略组）。节点凭据都是占位符（`密码`、`服务端UID`、`你的密钥`），导入前换成自己的。改完可以无头校验语法：`/Applications/Clash Verge.app/Contents/MacOS/verge-mihomo -t -f cvr-max.yaml`——占位符会让检查提前截断，先填假值再跑。
- **`squirrel/`**：鼠须管的 RIME 用户配置。`luna_pinyin.custom.yaml` 默认开繁→简转换，并把词典换成 `luna_pinyin.extended`；后者把 `luna_pinyin` 与 `moegirl`（萌娘百科词库）拼成一张表；剩下两个管外观与翻页。拷进 RIME 用户目录（macOS `~/Library/Rime/`、Linux `~/.config/fcitx/rime/`）后重新部署生效。

> 「鼠须管 + 雾凇词库」那套走的是上面的 rime-auto-deploy，与 `squirrel/` 是两套方案。
