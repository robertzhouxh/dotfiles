;;; init-bootstrap.el -- My bootstrap configuration.
;;; Commentary:
;;; Code:

;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;;	setup coding system and window property
;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
(prefer-coding-system 'utf-8)
(setenv "LANG" "en_US.UTF-8")
(setenv	"LC_ALL" "en_US.UTF-8")
(setenv	"LC_CTYPE" "en_US.UTF-8")

;; setup titlebar appearance
(add-to-list 'default-frame-alist '(ns-transparent-titlebar . t))
(add-to-list 'default-frame-alist '(ns-appearance . dark))

;; useful mode settings
(display-time-mode 1)
(column-number-mode 1)
(show-paren-mode nil)
(display-battery-mode 1)
(tool-bar-mode -1)
(menu-bar-mode -1)
(toggle-scroll-bar -1)
(global-auto-revert-mode t)
(global-hl-line-mode nil)

(fset 'yes-or-no-p 'y-or-n-p)
(toggle-frame-fullscreen)

;; file edit settings
(setq
  user-mail-address "robertzhouxh@gmail.com"
  user-full-name "zxh"
  tab-width 4
  default-fill-column 80
  default-directory "~/"
  inhibit-splash-screen t
  initial-scratch-message nil
  sentence-end-double-space nil
  ring-bell-function 'ignore
  create-lockfiles nil
  make-backup-files nil
  indent-tabs-mode nil
  make-backup-files nil
  select-enable-clipboard t
  auto-save-default t)

(setq-default auto-save-timeout 15) ; 15秒无动作,自动保存
(setq-default auto-save-interval 100) ; 100个字符间隔, 自动保存

;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;;	setup history of edited file
;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
(savehist-mode 1)
(setq savehist-file "~/.emacs.d/.savehist")
(setq history-length t)
(setq history-delete-duplicates t)
(setq savehist-save-minibuffer-history 1)
(setq savehist-additional-variables
      '(kill-ring
        search-ring
regexp-search-ring))

;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;;; essential libs
;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
(use-package s        :ensure t :defer t)
(use-package cl       :ensure t :defer t)
(use-package ht       :ensure t :defer t)
(use-package git      :ensure t :defer t)
(use-package dash     :ensure t :defer t)
(use-package mustache :ensure t :defer t)
(use-package popup    :ensure t :defer t)

(provide 'init-bootstrap)
