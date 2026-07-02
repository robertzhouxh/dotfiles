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
# Emacs AI 助手 (`emacs-solo-ai`)

`emacs-solo-ai` 集成 Claude Code、Ollama、Gemini、OpenCode 四种 AI 后端到 Emacs 中。

## 全局快捷键

| 快捷键 | 功能 |
|--------|------|
| `C-c C-0` | 启动 Claude Code 原生聊天（SDK stream-json 模式） |
| `C-c C-8` | 启动 Claude TUI（终端交互模式，走订阅配额） |
| `C-c C-9` | 启动 OpenCode 聊天 |

## Claude Code 原生聊天 (`emacs-solo/claude-chat`)

**两种模式：**

- **`C-c C-0`（SDK 模式）**：使用 `claude --print --input-format stream-json`，走 Agent SDK 配额，渲染工具调用 diff，支持会话恢复
- **`C-c C-8`（TUI 模式）**：运行普通 `claude` 终端交互，走 Claude Code 订阅配额

**SDK 模式聊天缓冲区快捷键：**

| 快捷键    | 功能                             |
|-----------|----------------------------------|
| `RET`     | 发送输入                         |
| `C-RET`   | 插入换行                         |
| `C-c C-c` | 中断 Claude 进程（SIGINT）       |
| `C-c C-i` | 粘贴剪贴板中的 PNG 图片          |
| `C-c C-k` | 终止 Claude 进程（保留聊天记录） |
| `C-c C-l` | 清除聊天记录                     |
| `C-c C-r` | 恢复之前的会话                   |
| `C-c C-m` | 切换模型                         |

**斜杠命令（在输入框中输入）：**

| 命令          | 功能                                          |
|---------------|-----------------------------------------------|
| `/clear`      | 开始新会话                                    |
| `/model NAME` | 切换模型（如 `/model opus`、`/model sonnet`） |
| `/resume`     | 恢复历史会话                                  |

**用法特点：**

- 选中文本区域后按 `C-c C-0`，会提示输入问题，将选中内容作为上下文发送
- 支持从剪贴板粘贴 PNG 图片（`C-c C-i`），插入后显示为 `[image:/tmp/...]` 标记
- 工具调用（Edit/Write/Bash）会以内联 diff 形式渲染，方便查看代码变更

## Ollama (`emacs-solo/ollama-run-model`)

运行本地 Ollama 模型。自动列出 `ollama list` 中的模型供选择，可选输入 prompt，选中区域可作为查询上下文，在 `ansi-term` 中运行。

## Gemini (`emacs-solo/gemini-chat`)

启动 Google Gemini CLI 交互会话，在 `ansi-term` 中运行，缓冲区分项目命名。

## OpenCode (`emacs-solo/opencode-chat`)

启动 OpenCode AI 助手，支持任务类型选择（general、explore、code-reviewer 等），选中区域可作为上下文发送。

## 自定义变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `emacs-solo-claude-executable` | `"claude"` | Claude 可执行文件路径 |
| `emacs-solo-claude-permission-mode` | `"acceptEdits"` | 权限模式 |
| `emacs-solo-claude-confirm-before-edit` | `t` | 编辑前是否要求确认 |
| `emacs-solo-claude-model-choices` | 见源码 | 可选模型列表 |
| `emacs-solo-claude-diff-max-lines` | `200` | 内联 diff 最大显示行数 |

# 关于版本控制


