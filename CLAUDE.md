# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 仓库概述

个人 dotfiles，管理 macOS/Ubuntu 双平台的 Shell、编辑器、Git、终端等配置。主要编辑器是 Emacs，配置用 Org-mode 文学编程（Literate Programming）。

## 同步到 Home 目录

```
rsync -av --include='.*' --exclude='.git' --exclude='.DS_Store' --exclude='*' ./ ~/
```

## 平台初始化

- **macOS**: `./brew.sh` — 安装 Homebrew 及所有 CLI/GUI 工具
- **Ubuntu**: `./apt.sh` — 安装 apt 包及基础开发库
- **Emacs**: `./emacs.sh` — 创建 `~/.emacs.d` 符号链接
- **Vim**: `./vim.sh` — 安装 vim-plug 并创建符号链接

## 配置架构

### Shell 环境分层（加载顺序）

1. `.zshrc` / `.bashrc` — 交互式 shell 入口，跨平台兼容（zsh/bash 语法取交集）
2. `.envv` — 环境变量（PATH、编辑器、语言运行时、XDG、API Keys 加载）
3. `.alias` — 别名（ls 增强、网络工具、macOS 快捷操作、vibe coding）

API Keys 统一放在 `~/.config/secrets/env`（权限 600），由 `.envv` 中这行加载：`[ -r "$HOME/.config/secrets/env" ] && . "$HOME/.config/secrets/env"`

### Emacs 配置 (`~/.emacs.d/`)

- **入口**: `early-init.el` → `init.el`
- **配置模块**: `lisp/init-*.el`（16 个模块文件，按功能拆分）
- **包管理**: 内置 `package.el` + `use-package`（Emacs 29.1+ 内置），`:ensure t` 自动安装 MELPA 包，`:vc` 安装 Git 源包
- **包缓存**: `var/packages/elpa/`

**加载顺序**: `init-path` → `init-elpa` → `init-env` → `init-kbd` → `init-editor` → `init-ui` → `init-completion` → `init-dired` → `init-project` → `init-vcs` → `init-org` → `init-langs` → `init-evil` → `init-tools` → `init-rime` → `init-platform`

**模块职责**:

| 文件 | 职责 |
|---|---|
| `early-init.el` | GC 调优、frame 预配置 |
| `init.el` | 入口，按顺序 require |
| `lisp/init-path.el` | 路径常量、平台检测 |
| `lisp/init-elpa.el` | package-archives (MELPA)、bootstap |
| `lisp/init-env.el` | exec-path-from-shell |
| `lisp/init-kbd.el` | general.el + which-key + SPC leader |
| `lisp/init-editor.el` | 编辑行为、工具函数、avy/vundo/ws-butler |
| `lisp/init-ui.el` | 主题(lazycat)、字体、sort-tab、awesome-tray |
| `lisp/init-completion.el` | yasnippet + lsp-bridge |
| `lisp/init-dired.el` | Dired |
| `lisp/init-project.el` | projectile + ivy/counsel/swiper |
| `lisp/init-vcs.el` | VC 内置 Git 前端 |
| `lisp/init-org.el` | Org-Mode + LaTeX 导出 |
| `lisp/init-langs.el` | Tree-sitter、Go/Rust/C++/Python/TS/LaTeX 等 |
| `lisp/init-evil.el` | Evil + evil-surround/org/textobj-line + undo-fu |
| `lisp/init-tools.el` | eat 终端、claude-code、tramp、sudo-edit |
| `lisp/init-rime.el` | Rime 中文输入法 |
| `lisp/init-platform.el` | macOS/Linux 平台差异 |

修改 Emacs 配置时，编辑对应的 `lisp/init-*.el` 文件，重启或 `SPC f i` 重新加载 `init.el`。

### Vim 配置

- 插件管理: vim-plug
- 主要插件: nerdtree、vim-solarized
- Leader key: `,`

### 其他配置

- `starship.toml` → `~/.config/starship.toml` — Shell 提示符主题
- `.gitconfig` — Git 别名和配置，分支命名 `main`，默认推送 `simple`，URL 简写 `gh:`/`gist:`
- `cvr-max.yaml` / `cvr-min.yaml` — Clash Verge Rev 代理配置（完整版/精简版）
- `squirrel/` — Mac 鼠须管输入法配置
- `rime/` — Rime 输入法词库和配置文件

### 版本管理工具链

- 使用 `asdf` 管理语言运行时版本
- Go: `GOPROXY='https://goproxy.cn,direct'`
- `ghq` 管理 Git 仓库克隆路径，root 设为 `~/src`
