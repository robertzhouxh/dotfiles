;;; init-tools.el --- 工具插件配置 -*- lexical-binding: t; -*-

;; ---- 终端 ----
(use-package inheritenv
  :vc (:url "https://github.com/purcell/inheritenv" :rev :newest))

(use-package eat
  :vc (:url "https://codeberg.org/akib/emacs-eat" :rev :newest)
  :commands eat)

;; ---- Claude Code ----
(use-package claude-code
  :vc (:url "https://github.com/stevemolitor/claude-code.el" :rev :newest)
  :config
  (setq claude-code-terminal-backend 'eat
        claude-code-term-name "xterm-256color"
        claude-code-program-switches '("--verbose")
        claude-code-enable-notifications t
        claude-code-notification-function 'claude-code--default-notification)

  ;; DeepSeek-V4 pro
  (progn
    (setenv "ANTHROPIC_BASE_URL" "https://api.deepseek.com/anthropic")
    (setenv "ANTHROPIC_AUTH_TOKEN" (getenv "DEEPSEEK_API_KEY"))
    (setenv "ANTHROPIC_MODEL" "deepseek-v4-pro[1m]")
    (setq claude-code-program "/usr/local/bin/claude")))

;; ---- Emacs 自带 tramp ----
(use-package tramp
  :ensure nil
  :defer t
  :custom
  (tramp-default-method "ssh"))

(provide 'emacs-init-ai)
;;; init-tools.el ends here
