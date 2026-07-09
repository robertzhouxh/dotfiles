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

;; ---- gptel（轻量 LLM 交互）----
;;
;; 在任意 buffer 选中文本发给模型，回复可重定向到任意 buffer。
;; 主力后端：DeepSeek（OpenAI 兼容）。
(use-package gptel
  :init
  (defun my/create-drawer-window (buffer-name &optional focus height mode)
    "Create a bottom drawer window with BUFFER-NAME.
If FOCUS is non-nil, keep focus in the new window.
HEIGHT is passed to `split-window-vertically' (negative = lines from bottom).
When MODE is non-nil, call it as the new buffer's major mode."
    (split-window-vertically (if height height -10))
    (other-window 1)
    (let ((buf (switch-to-buffer buffer-name)))
      (unless focus (other-window -1))
      (when mode
        (with-current-buffer buf (funcall mode)))
      buf))

  (defun my/toggle-gptel-drawer ()
    "Toggle a gptel chat buffer as a bottom drawer window."
    (interactive)
    (let ((buffer (gptel "*gpt*")))
      (if (string-equal (buffer-name buffer) (buffer-name (current-buffer)))
          (delete-window)
        (my/create-drawer-window (buffer-name buffer) t -20))))
  :custom
  (gptel-api-key (string-trim
                  (shell-command-to-string
                   "$SHELL --login -c 'echo $DEEPSEEK_API_KEY'")))
  :config
  ;; DeepSeek 作为主力后端（OpenAI 兼容）
  (gptel-make-openai "DeepSeek"
    :host "api.deepseek.com"
    :endpoint "/chat/completions"
    :key (string-trim
          (shell-command-to-string
           "$SHELL --login -c 'echo $DEEPSEEK_API_KEY'"))
    :models '(deepseek-chat deepseek-reasoner))
  (setq gptel-model 'deepseek-chat
        gptel-backend (gptel-get-backend "DeepSeek"))
  :bind (("M-<return>" . my/toggle-gptel-drawer)
         (:map gptel-mode-map
          ("C-<tab>" . nil))))

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
         (:map agent-shell-mode-map
          ("C-<tab>" . nil))))

;; ---- Emacs 自带 tramp ----
(use-package tramp
  :ensure nil
  :defer t
  :custom
  (tramp-default-method "ssh"))

(provide 'emacs-init-ai)
;;; init-tools.el ends here
