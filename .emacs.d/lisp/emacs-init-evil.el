;;; emacs-init-evil.el --- Evil 模式配置 -*- lexical-binding: t; -*-

(use-package evil
  :init
  (setq evil-want-keybinding nil
        evil-undo-system 'undo-fu
        evil-disable-insert-state-bindings t
        evil-want-C-u-scroll t
        evil-esc-delay 0)
  :config
  (evil-mode 1))

(use-package undo-fu)

(use-package evil-textobj-line :after evil)
(use-package evil-surround :after evil :config (global-evil-surround-mode))
(use-package evil-visualstar :after evil :config (global-evil-visualstar-mode))

(use-package evil-org
  :after org
  :hook (org-mode . evil-org-mode)
  :config
  (require 'evil-org-agenda)
  (evil-org-agenda-set-keys)
  (evil-org-set-key-theme '(navigation insert shift todo heading)))

;; 各 mode 的初始 evil 状态
(dolist (p '((minibuffer-inactive-mode . emacs)
             (color-rg-mode . emacs)
             (comint-mode . emacs)
             (vc-dir-git-mode . emacs)
             (vc-dir-mode . emacs)
             (vc-log-edit-mode . emacs)
             (dired-mode . emacs)
             (fundamental-mode . normal)
             (grep-mode . emacs)
             (Info-mode . emacs)
             (sdcv-mode . emacs)
             (log-edit-mode . emacs)
             (help-mode . emacs)
             (xref--xref-buffer-mode . emacs)
             (compilation-mode . emacs)
             (speedbar-mode . emacs)
             (ivy-occur-mode . emacs)
             (ivy-occur-grep-mode . normal)
             (messages-buffer-mode . normal)
             ;; AI / terminal modes — 必须 emacs state，否则快捷键与 Evil 冲突
             (agent-shell-mode . emacs)
             (eat-mode . emacs)
             (term-mode . emacs)
             (emacs-solo-claude-mode . emacs)))
  (evil-set-initial-state (car p) (cdr p)))

;; vibe-coding：agent-shell / AI 终端模式在 emacs state 启动
;; 如果手动切到 normal state（用于 j/k 滚动），按 C-z 即可回到 emacs state
;; eat / term 由底层终端处理 Escape，Evil 不会拦截，无需额外配置
(with-eval-after-load 'evil
  ;; C-z 回到 emacs state（原生的 C-z 被 global-unset-key 移除了，
  ;; 但在 normal state 下 C-z 返回到 emacs state 是刚需）
  (define-key evil-normal-state-map (kbd "C-z") #'evil-emacs-state))

(provide 'emacs-init-evil)
;;; init-evil.el ends here
