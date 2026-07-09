;;; emacs-init-tools.el --- 工具插件配置 -*- lexical-binding: t; -*-

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

;; ---- agent-shell（终端 Agent 集成）----
;;
;; 把 Claude Code / Codex 等终端 agent 包装成 Emacs major mode。
;; 每个会话按「模型名 @ 目录名」命名 buffer，多项目切换即切 buffer。
;;
;; 系统依赖（需手动安装）：
;;   brew install claude-code
;;   npm install -g @zed-industries/claude-agent-acp
;;
;; 首次使用：M-x agent-shell，选择 Claude Code，即可开始。
(use-package agent-shell
  :ensure nil
  :vc (:url "https://github.com/xenodium/agent-shell" :rev :newest)
  :custom
  (agent-shell-anthropic-authentication
   (agent-shell-anthropic-make-authentication
    :api-key (string-trim
              (shell-command-to-string
               "$SHELL --login -c 'echo $DEEPSEEK_API_KEY'"))))
  (agent-shell-anthropic-claude-acp-command
   '("claude-agent-acp" "--dangerously-skip-permissions"))
  :bind (("C-c C-a" . agent-shell-anthropic-start-claude-code)
         ("C-c C-1" . agent-shell-anthropic-start-claude-code)
         (:map agent-shell-mode-map
          ("C-<tab>" . nil))))

;; 释放 markdown-mode 中 C-c C-a 前缀（deprecated keys，规范键是 C-c C-l 等）
;; 否则 markdown buffer 中 C-c C-a 被拦截，无法启动 agent-shell
(with-eval-after-load 'markdown-mode
  (define-key markdown-mode-map (kbd "C-c C-a") nil))

;; ---- Emacs 自带 tramp ----
(use-package tramp
  :ensure nil
  :defer t
  :custom
  (tramp-default-method "ssh"))

(provide 'emacs-init-ai)
;;; init-tools.el ends here
