;;; init-bootstrap.el -- My bootstrap configuration.
;;; Commentary:
;;; Code:
;; Essential settings.

(setq user-full-name "robert zhou")
(setq user-mail-address "robertzhouxh@gmail.com")

;; start
(setq inhibit-splash-screen t
      initial-scratch-message nil
      inhibit-startup-echo-area-message t
      select-enable-clipboard t
      coding-system-for-read 'utf-8
      coding-system-for-write 'utf-8
      )

;; Use utf8
(set-language-environment "UTF-8")
(set-default-coding-systems 'utf-8)
(set-buffer-file-coding-system 'utf-8)
(set-clipboard-coding-system 'utf-8)
(set-file-name-coding-system 'utf-8)
(set-keyboard-coding-system 'utf-8)
(set-next-selection-coding-system 'utf-8)
(set-selection-coding-system 'utf-8)
(set-terminal-coding-system 'utf-8)
(setq locale-coding-system 'utf-8)
(prefer-coding-system 'utf-8)


(menu-bar-mode -1)
(tool-bar-mode -1)
(show-paren-mode 1)
(electric-indent-mode 1)
(global-auto-revert-mode t)
(unless (display-graphic-p)
  (setq-default linum-format "%d "))
(when (boundp 'scroll-bar-mode)
  (scroll-bar-mode -1))

(setq backup-directory-alist (list (cons "." backup-dir)))
(setq make-backup-files nil)
(setq default-directory "~/")
(setq make-backup-files nil)
(setq auto-save-default nil)
(setq visual-line-fringe-indicators '(left-curly-arrow right-curly-arrow))
(setq vc-follow-symlinks t)
(setq large-file-warning-threshold nil)
(setq split-width-threshold 0)
(setq split-height-threshold nil)
(setq gc-cons-threshold 100000000) ;; This makes my Emacs startup time ~35% faster.

;; No need for ~ files when editing
(setq create-lockfiles nil)

(setq-default left-fringe-width nil)
(eval-after-load "vc" '(setq vc-handled-backends nil))
(defalias 'yes-or-no-p 'y-or-n-p)

;; tabs do not turn spaces into tab
(setq-default indent-tabs-mode nil)
(setq-default tab-width 4)

;; do not use mouse
(define-minor-mode disable-mouse-mode
                   "A minor-mode that disables all mouse keybinds."
                   :global t
                   :lighter " 🐭"
                   :keymap (make-sparse-keymap))

; Set cursor color to white; http://www.tayloredmktg.com/rgb/
;;(set-cursor-color "#ffffff")
(defvar blink-cursor-colors (list  "#92c48f" "#6785c5" "#be369c" "#d9ca65")
  "On each blink the cursor will cycle to the next color in this list.")

(setq blink-cursor-count 0)
(defun blink-cursor-timer-function ()
  "Zarza wrote this cyberpunk variant of timer `blink-cursor-timer'. 
Warning: overwrites original version in `frame.el'.

This one changes the cursor color on each blink. Define colors in `blink-cursor-colors'."
  (when (not (internal-show-cursor-p))
    (when (>= blink-cursor-count (length blink-cursor-colors))
      (setq blink-cursor-count 0))
    (set-cursor-color (nth blink-cursor-count blink-cursor-colors))
    (setq blink-cursor-count (+ 1 blink-cursor-count))
    )
  (internal-show-cursor nil (not (internal-show-cursor-p)))
  )
;;; essential libs
;(use-package s :ensure t  :config (progn (require 's t)))
(use-package s        :ensure t :defer t)
(use-package cl       :ensure t :defer t)
(use-package ht       :ensure t :defer t)
(use-package git      :ensure t :defer t)
(use-package dash     :ensure t :defer t)
(use-package mustache :ensure t :defer t)
(use-package popup    :ensure t :defer t)

(provide 'init-bootstrap)
