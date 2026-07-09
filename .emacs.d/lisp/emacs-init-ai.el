;;; emacs-init-tools.el --- 工具插件配置 -*- lexical-binding: t; -*-

;; ---- 终端 ----
(use-package inheritenv
  :vc (:url "https://github.com/purcell/inheritenv" :rev :newest))

(use-package eat
  :vc (:url "https://codeberg.org/akib/emacs-eat" :rev :newest)
  :commands eat)

;; ---- Claude Code ----
;; (use-package claude-code
;;   :vc (:url "https://github.com/stevemolitor/claude-code.el" :rev :newest)
;;   :config
;;   (setq claude-code-terminal-backend 'eat
;;         claude-code-term-name "xterm-256color"
;;         claude-code-program "/usr/local/bin/claude"
;;         claude-code-program-switches '("--verbose")
;;         claude-code-enable-notifications t
;;         claude-code-notification-function 'claude-code--default-notification))

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
  :init
  ;; DeepSeek-V4 pro — 设在 :init 保证 claude-agent-acp 子进程启动前生效
  (setenv "ANTHROPIC_BASE_URL" "https://api.deepseek.com/anthropic")
  (setenv "ANTHROPIC_AUTH_TOKEN" (getenv "DEEPSEEK_API_KEY"))
  (setenv "ANTHROPIC_MODEL" "deepseek-v4-pro[1m]")
  :custom
  (agent-shell-preferred-agent-config 'claude-code)
  (agent-shell-anthropic-authentication
   (agent-shell-anthropic-make-authentication
    :api-key (string-trim
              (shell-command-to-string
               "$SHELL --login -c 'echo $DEEPSEEK_API_KEY'"))))
  (agent-shell-anthropic-claude-acp-command
   '("claude-agent-acp" "--dangerously-skip-permissions"))
  (agent-shell-tool-use-expand-by-default t)
  ;; 收紧行间距：Sarasa Mono SC 是 CJK 字体，行高偏大，
  ;; buffer 内默认 face 缩小 5% 让行间距更紧凑，不影响可读性
  :hook (agent-shell-mode . (lambda ()
                              (face-remap-add-relative 'default :height 0.95)))
  :config
  ;; vibe-coding: 自动批准 read/write，execute 仍需确认
  (setq agent-shell-permission-responder-function
        (lambda (permission)
          (when-let* ((kind (map-elt (map-elt permission :tool-call) :kind))
                      ((member kind '("read" "write" "edit")))
                      (choice (seq-find
                               (lambda (option)
                                 (equal (map-elt option :kind) "allow_once"))
                               (map-elt permission :options))))
            (funcall (map-elt permission :respond)
                     (map-elt choice :option-id))
            t)))
  :bind (("C-c C-a" . agent-shell-anthropic-start-claude-code)
         ("C-c C-1" . agent-shell-anthropic-start-claude-code)
         (:map agent-shell-mode-map
          ("C-<tab>" . nil))))

;; 释放 markdown-mode 中 C-c C-a 前缀（deprecated keys，规范键是 C-c C-l 等）
;; 否则 markdown buffer 中 C-c C-a 被拦截，无法启动 agent-shell
(with-eval-after-load 'markdown-mode
  (define-key markdown-mode-map (kbd "C-c C-a") nil))

;; ---- Drawer 窗口工具 ----
(defun create-drawer-window (buffer-name &optional focus height mode)
  "Create a bottom drawer window displaying BUFFER-NAME.
If FOCUS is non-nil, move point into the drawer.
HEIGHT is the window height (negative = lines from bottom, default -10).
MODE is a major mode function to activate in the buffer."
  (split-window-vertically (if height height -10))
  (other-window 1)
  (let ((buf (switch-to-buffer buffer-name)))
    (if (not focus) (other-window -1))
    (with-current-buffer buf
      (if mode (funcall mode)))
    buf))

;; ---- gptel（LLM 聊天抽屉）----
;;
;; M-RET 弹出/关闭底部 drawer，DeepSeek 后端，Emacs 原生体验。
;; 系统依赖：无需额外安装，API key 从 shell 环境变量读取。
(use-package gptel
  :ensure t
  :vc (:url "https://github.com/karthink/gptel" :rev :newest)
  :bind (:map gptel-mode-map
          ("C-<return>" . gptel-send))
  :config
  (setq gptel-backend (gptel-make-openai "DeepSeek"
                        :host "api.deepseek.com"
                        :key (string-trim
                              (shell-command-to-string
                               "$SHELL --login -c 'echo $DEEPSEEK_API_KEY'"))
                        :stream t
                        :models `((,(intern "deepseek-v4-pro[1m]")
                                   . (:description "DeepSeek V4 Pro")))))
  (setq gptel-model (intern "deepseek-v4-pro[1m]"))

  (defun skye/toggle-gptel-drawer ()
    "Toggle the gptel chat drawer at the bottom of the frame.
When opening and a region is active, include it as context."
    (interactive)
    (let* ((region-text (when (use-region-p)
                          (buffer-substring-no-properties
                           (region-beginning) (region-end))))
           (buf (gptel "*gptel*" nil region-text))
           (win (get-buffer-window buf)))
      (if win
          ;; Already visible — close it. If it's the selected window,
          ;; delete-window is enough; otherwise just delete that window.
          (if (eq win (selected-window))
              (unless (one-window-p)
                (delete-window))
            (delete-window win))
        ;; Not visible — open as bottom drawer.
        (create-drawer-window (buffer-name buf) t -20))))

  (global-set-key (kbd "<M-return>") #'skye/toggle-gptel-drawer))

;; ---- Emacs 自带 tramp ----
(use-package tramp
  :ensure nil
  :defer t
  :custom
  (tramp-default-method "ssh"))

(provide 'emacs-init-ai)
;;; init-tools.el ends here
