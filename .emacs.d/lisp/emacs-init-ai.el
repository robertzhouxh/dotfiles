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
  :commands (agent-shell agent-shell-anthropic-start-claude-code)
  :init
  ;; DeepSeek-V4 pro — 设在 :init 保证 claude-agent-acp 子进程启动前生效
  (setenv "ANTHROPIC_BASE_URL" "https://api.deepseek.com/anthropic")
  (setenv "ANTHROPIC_AUTH_TOKEN"
          (string-trim
           (shell-command-to-string
            "sh -c '. ~/.config/secrets/env && echo $DEEPSEEK_API_KEY'")))
  (setenv "ANTHROPIC_MODEL" "deepseek-v4-pro[1m]")
  :custom
  (agent-shell-preferred-agent-config 'claude-code)
  (agent-shell-anthropic-authentication
   (agent-shell-anthropic-make-authentication
    :api-key (string-trim
              (shell-command-to-string
               "sh -c '. ~/.config/secrets/env && echo $DEEPSEEK_API_KEY'"))))
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
            t))))

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
;; M-RET：有选区时切换独立的解释抽屉。
;; DeepSeek 后端，Emacs 原生体验。
;; 系统依赖：无需额外安装，API key 从 shell 环境变量读取。
(use-package gptel
  :ensure t
  :vc (:url "https://github.com/karthink/gptel" :rev :newest)
  :demand t
  :config
  (setq gptel-backend (gptel-make-openai "DeepSeek"
                        :host "api.deepseek.com"
                        :key (string-trim
                              (shell-command-to-string
                               "sh -c '. ~/.config/secrets/env && echo $DEEPSEEK_API_KEY'"))
                        :stream t
                        :models `((,(intern "deepseek-v4-pro")
                                   . (:description "DeepSeek V4 Pro")))))
  (setq gptel-model (intern "deepseek-v4-pro[1m]"))

  (defconst skye/gptel-rewrite-drawer-name "*gptel-rewrite*")
  (defconst skye/gptel-explain-drawer-name "*gptel-explain*")

  (defconst skye/gptel-drawer-names
    (list skye/gptel-rewrite-drawer-name
          skye/gptel-explain-drawer-name))

  (defun skye/gptel-selected-context ()
    "Return the active region, or signal that a region is required."
    (unless (use-region-p)
      (user-error "Select text before opening this gptel drawer"))
    (buffer-substring-no-properties (region-beginning) (region-end)))

  (defun skye/gptel-drawer-spec ()
    "Return the explanation drawer and the active region context."
    (list skye/gptel-explain-drawer-name (skye/gptel-selected-context)))

  (defun skye/gptel-current-drawer-name ()
    "Return the current gptel drawer, or select one from the active context."
    (when (member (buffer-name) skye/gptel-drawer-names)
      (buffer-name)))

  (defun skye/show-gptel-drawer (buf)
    "Show BUF as a bottom drawer, or select its existing window."
    (if-let* ((win (get-buffer-window buf)))
        (select-window win)
      (create-drawer-window (buffer-name buf) t -20)))

  (defun skye/hide-gptel-drawer (buf)
    "Hide BUF's drawer without deleting the chat buffer."
    (when-let* ((win (get-buffer-window buf)))
      (if (one-window-p nil (window-frame win))
          (quit-window nil win)
        (delete-window win))))

  (defun skye/toggle-gptel-drawer-named (drawer-name &optional region-text prompt)
    "Toggle DRAWER-NAME, optionally providing REGION-TEXT and a PROMPT."
    (let* ((new-buffer (not (get-buffer drawer-name)))
           (buf (gptel drawer-name nil region-text))
           (win (get-buffer-window buf)))
      (when (and new-buffer prompt)
        (with-current-buffer buf
          (goto-char (point-max))
          (insert prompt)))
      (if win
          (skye/hide-gptel-drawer buf)
        (skye/show-gptel-drawer buf))))

  (defun skye/toggle-gptel-drawer ()
    "Hide the current drawer, or show an existing drawer, or create an explanation drawer."
    (interactive)
    (cond
     ((member (buffer-name) skye/gptel-drawer-names)
      (skye/hide-gptel-drawer (current-buffer)))
     ((when-let* ((buf (or (get-buffer skye/gptel-explain-drawer-name)
                           (get-buffer skye/gptel-rewrite-drawer-name))))
        (skye/show-gptel-drawer buf)))
     (t
      (pcase-let* ((`(,drawer-name ,region-text) (skye/gptel-drawer-spec)))
        (skye/toggle-gptel-drawer-named
         drawer-name region-text "请解释这段代码：\n")))))

  (defun skye/toggle-gptel-rewrite-drawer ()
    "Toggle the region-backed gptel rewrite drawer."
    (interactive)
    (skye/toggle-gptel-drawer-named
     skye/gptel-rewrite-drawer-name (skye/gptel-selected-context)))

  (defun skye/toggle-gptel-explain-drawer ()
    "Toggle the region-backed gptel code explanation drawer."
    (interactive)
    (skye/toggle-gptel-drawer-named
     skye/gptel-explain-drawer-name (skye/gptel-selected-context)
     "请解释这段代码：\n"))

  (defun skye/gptel-dwim ()
    "Toggle the regular or region-backed gptel explanation drawer."
    (interactive)
    (skye/toggle-gptel-drawer))

  (defun skye/destroy-gptel-drawer ()
    "Abort the current gptel request and destroy its matching drawer."
    (interactive)
    (if-let ((buf (get-buffer (skye/gptel-current-drawer-name))))
        (let ((win (get-buffer-window buf t)))
          (gptel-abort buf)
          (when (kill-buffer buf)
            (when (and (window-live-p win)
                       (not (one-window-p nil (window-frame win))))
              (delete-window win))
            (message "Destroyed gptel drawer: %s" (buffer-name buf))))
      (message "No matching gptel drawer to destroy")))

  (define-key gptel-mode-map (kbd "C-RET") #'gptel-send)
  (define-key gptel-mode-map (kbd "C-<return>") #'gptel-send))

(use-package tramp
  :ensure nil
  :custom
  (tramp-default-method "ssh"))

(provide 'emacs-init-ai)
;;; init-tools.el ends here
