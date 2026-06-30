;;; early-init.el --- 启动早期优化 -*- lexical-binding: t; -*-

;; GC 阈值调优：启动时提高，启动后恢复
(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.6)

(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold (* 16 1024 1024)
                  gc-cons-percentage 0.1)))

;; 禁用 package.el 启动时自动扫描（由 init-elpa 手动管理）
(setq package-enable-at-startup nil)

;; 禁用 UI 元素（在 GUI 初始化之前）
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(menu-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars . nil) default-frame-alist)
(push '(horizontal-scroll-bars . nil) default-frame-alist)
(push '(internal-border-width . 18) default-frame-alist)

;; 不调整 frame 大小以匹配字体
(setq frame-inhibit-implied-resize t)

;; 更快的渲染
(setq-default bidi-display-reordering nil)

;; LSP 性能
(setenv "LSP_USE_PLISTS" "true")

(provide 'early-init)
;;; early-init.el ends here
