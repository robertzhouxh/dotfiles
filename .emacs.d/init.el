;;; init.el --- Emacs 配置入口 -*- lexical-binding: t; -*-

(add-to-list 'load-path (expand-file-name "lisp" user-emacs-directory))

;; 路径常量必须最先加载（my-cache-dir 等后面要用）
(require 'emacs-init-path)

;; custom-file 尽早设置，避免 Customize 写入 init.el
(setq custom-file (expand-file-name "custom.el" my-cache-dir))
(when (file-exists-p custom-file)
  (load custom-file nil 'nomessage))

;; 可选功能开关（在加载对应模块前声明）
(defcustom emacs-solo-enable-highlight-keywords t
  "Enable `emacs-solo-highlight-keywords'."
  :type 'boolean :group 'emacs-solo)

(defcustom emacs-solo-enable-rainbown-delimiters t
  "Enable rainbow-delimiters."
  :type 'boolean :group 'emacs-solo)

(defcustom emacs-solo-ai-scratch-path nil
  "If non-nil, AI commands run from this directory."
  :type '(choice (const :tag "Disabled" nil)
                 (directory :tag "AI Scratch Directory"))
  :group 'emacs-solo)

;; ── 基础层 ──────────────────────────────────────────────────────────────────
(require 'emacs-init-elpa)
(require 'emacs-solo-exec-path-from-shell)
(require 'emacs-solo-clipboard)

;; ── 编辑器核心 ───────────────────────────────────────────────────────────────
(require 'emacs-init-keys)
(require 'emacs-init-settings)
(require 'emacs-init-ui)
(require 'emacs-init-font)

;; ── 功能模块 ─────────────────────────────────────────────────────────────────
(require 'emacs-init-completion)
(require 'emacs-init-dired)
(require 'emacs-init-project)
;;(require 'emacs-init-vcs)
(require 'emacs-solo-gh)
(require 'emacs-init-org)
(require 'emacs-init-langs)
(require 'emacs-solo-highlight-keywords)
(require 'emacs-init-evil)

;; ── 其他工具 ─────────────────────────────────────────────────────────────────
(require 'emacs-solo-ai)
(require 'emacs-init-rime)
(require 'emacs-init-platform)
(require 'emacs-solo-sudo-edit)
(require 'emacs-solo-temp-sharing)

;; 所有模块加载完后再收紧警告级别，避免第三方包加载期间的 warning 被升级为 error
(setq warning-minimum-level :error)

(server-start)

(provide 'init)
;;; init.el ends here
