;;; init.el --- Emacs 配置入口 -*- lexical-binding: t; -*-

;; 将 lisp/ 目录加入 load-path
(add-to-list 'load-path (expand-file-name "lisp" user-emacs-directory))

(defcustom emacs-solo-enable-transparency nil
  "Enable `emacs-solo-transparency'."
  :type 'boolean
  :group 'emacs-solo)

(defcustom emacs-solo-enable-highlight-keywords t
  "Enable `emacs-solo-enable-highlight-keywords'."
  :type 'boolean
  :group 'emacs-solo)

(defcustom emacs-solo-enable-rainbown-delimiters t
  "Enable `emacs-solo-enable-rainbown-delimiters'."
  :type 'boolean
  :group 'emacs-solo)

(defcustom emacs-solo-enable-buffer-gutter t
  "Enable `emacs-solo-enable-gutter'."
  :type 'boolean
  :group 'emacs-solo)

(defcustom emacs-solo-enable-dired-gutter t
  "Enable `emacs-solo-dired-gutter'."
  :type 'boolean
  :group 'emacs-solo)

(defcustom emacs-solo-enable-preferred-font t
  "Enable `emacs-solo-enable-preferred-font'."
  :type 'boolean
  :group 'emacs-solo)

(defcustom emacs-solo-preferred-font-name "JetBrainsMono Nerd Font"
  "The name of the font to be used.
Examples: `Maple Mono NF' or `JetBrainsMono Nerd Font'."
  :type 'string
  :group 'emacs-solo)

(defcustom emacs-solo-preferred-font-sizes '(130 105)
  "List of default font sizes (first for macOS, second for GNU/Linux)."
  :type '(repeat integer)
  :group 'emacs-solo)

(defcustom emacs-solo-ai-scratch-path nil
  "If non-nil, AI commands run from this directory.
This allows using a specific environment or scratch context."
  :type '(choice (const :tag "Disabled" nil)
                 (directory :tag "AI Scratch Directory"))
  :group 'emacs-solo)

;; 基础：路径常量 → 包引导 → 环境
(require 'emacs-init-path)
(require 'emacs-init-elpa)
;;(require 'emacs-init-env)
(require 'emacs-solo-exec-path-from-shell)
(require 'emacs-solo-clipboard)

;; custom-file 尽早设置（在加载模块之前）
(setq custom-file (expand-file-name "custom.el" my-cache-dir))
(unless (file-directory-p my-cache-dir)
  (make-directory my-cache-dir t))
(when (file-exists-p custom-file)
  (load custom-file nil 'nomessage))

;; 编辑器核心
(require 'emacs-init-keys)
(require 'emacs-init-settings)
(require 'emacs-init-ui)
(require 'emacs-solo-transparency)

;; 功能模块
(require 'emacs-init-completion)
(require 'emacs-init-dired)
(require 'emacs-solo-dired-gutter)
(require 'emacs-init-project)
(require 'emacs-solo-project-select)
(require 'emacs-init-vcs)
(require 'emacs-solo-gutter)
(require 'emacs-solo-gh)
(require 'emacs-init-org)
(require 'emacs-init-langs)
(require 'emacs-solo-highlight-keywords)
(require 'emacs-init-evil)
(require 'emacs-init-ai)
(require 'emacs-solo-ai)
(require 'emacs-init-rime)
(require 'emacs-init-platform)
(require 'emacs-solo-sudo-edit)
(require 'emacs-solo-temp-sharing)

;; 关闭第三方包的 lexical-binding 警告
(setq warning-minimum-level :error)

;; 启动 emacs server
(server-start)

(provide 'init)
;;; init.el ends here
