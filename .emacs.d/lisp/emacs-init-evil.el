;;; init-evil.el --- Evil 模式配置 -*- lexical-binding: t; -*-

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
             (messages-buffer-mode . normal)))
  (evil-set-initial-state (car p) (cdr p)))

(provide 'emacs-init-evil)
;;; init-evil.el ends here
