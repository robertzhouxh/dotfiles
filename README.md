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
