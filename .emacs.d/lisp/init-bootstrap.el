;;; init-bootstrap.el -- My bootstrap configuration.
;;; Commentary:
;;; Code:
;; Essential settings.

(setq user-full-name "robert zhou")
(setq user-mail-address "robertzhouxh@gmail.com")

(setq
 delete-old-versions -1
 version-control t
 vc-make-backup-files t
 vc-follow-symlinks t
 inhibit-startup-screen t
 ring-bell-function 'ignore
 select-enable-clipboard t
 coding-system-for-read 'utf-8
 coding-system-for-write 'utf-8
 sentence-end-double-space nil
 default-fill-column 80
 initial-scratch-message ""
 save-interprogram-paste-before-kill t
 help-window-select t
 make-backup-files nil
 default-directory "~/"
 large-file-warning-threshold nil
 split-width-threshold 0
 split-height-threshold nil
 create-lockfiles nil
 indent-tabs-mode nil
 tab-width 4
 backup-directory-alist `((".*" . ,temporary-file-directory))
 auto-save-file-name-transforms `((".*" ,temporary-file-directory t))
 gc-cons-threshold (* 64 1000 1000))

(prefer-coding-system 'utf-8)
(add-hook 'after-init-hook #'(lambda () (setq gc-cons-threshold (* 32 1000 1000))))
(add-hook 'focus-out-hook 'garbage-collect)
(run-with-idle-timer 5 t 'garbage-collect)
(menu-bar-mode -1)
(tool-bar-mode -1)
(show-paren-mode 1)
(electric-indent-mode 1)
(global-auto-revert-mode t)
(unless (display-graphic-p)
  (setq-default linum-format "%d "))
(when (boundp 'scroll-bar-mode)
  (scroll-bar-mode -1))
(defalias 'yes-or-no-p 'y-or-n-p)

;;; essential libs
(use-package s        :ensure t :defer t)
(use-package cl       :ensure t :defer t)
(use-package ht       :ensure t :defer t)
(use-package git      :ensure t :defer t)
(use-package dash     :ensure t :defer t)
(use-package mustache :ensure t :defer t)
(use-package popup    :ensure t :defer t)

(provide 'init-bootstrap)
