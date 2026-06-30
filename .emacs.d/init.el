;;; init.el --- Emacs 配置入口 -*- lexical-binding: t; -*-

;; 将 lisp/ 目录加入 load-path
(add-to-list 'load-path (expand-file-name "lisp" user-emacs-directory))

;; 基础：路径常量 → 包引导 → 环境
(require 'init-path)
(require 'init-elpa)
(require 'init-env)

;; custom-file 尽早设置（在加载模块之前）
(setq custom-file (expand-file-name "custom.el" my-cache-dir))
(unless (file-directory-p my-cache-dir)
  (make-directory my-cache-dir t))
(when (file-exists-p custom-file)
  (load custom-file nil 'nomessage))

;; 编辑器核心
(require 'init-kbd)
(require 'init-editor)
(require 'init-ui)

;; 功能模块
(require 'init-completion)
(require 'init-dired)
(require 'init-project)
(require 'init-vcs)
(require 'init-org)
(require 'init-langs)
(require 'init-evil)
(require 'init-tools)
(require 'init-rime)
(require 'init-platform)

;; 关闭第三方包的 lexical-binding 警告
(setq warning-minimum-level :error)

;; 启动 emacs server
(server-start)

(provide 'init)
;;; init.el ends here
