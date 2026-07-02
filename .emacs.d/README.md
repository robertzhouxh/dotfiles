# Emacs 配置

## 第三方包补丁

### lazycat-theme — Emacs 31 `:style none` 兼容性修复

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
