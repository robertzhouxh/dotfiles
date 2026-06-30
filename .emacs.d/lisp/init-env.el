;;; init-env.el --- 环境配置 -*- lexical-binding: t; -*-

(require 'init-path)

;; Shell 环境同步（macOS GUI Emacs 必备）
(use-package exec-path-from-shell
  :if my-graphic-p
  :init
  (setq exec-path-from-shell-arguments '("-l"))
  :config
  (dolist (var '("GOROOT" "GOPATH" "GOROOT_BOOTSTRAP"
                  "DEEPSEEK_API_KEY" "OPENROUTER_API_KEY"
                  "SSH_AUTH_SOCK" "SSH_AGENT_PID"))
    (add-to-list 'exec-path-from-shell-variables var))
  (exec-path-from-shell-initialize))

(provide 'init-env)
;;; init-env.el ends here
