;;; init-bootstrap.el -- My bootstrap configuration.
;;; Commentary:
;;; Code:

;; setup coding system and window property
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

;; revert buffers automatically when underlying files are changed externally
(global-auto-revert-mode t)
(global-hl-line-mode -1)

;(global-visual-line-mode 1)
(set-default 'truncate-lines t)

(fset 'yes-or-no-p 'y-or-n-p)

;; file edit settings
(setq
  user-mail-address "robertzhouxh@gmail.com"
  user-full-name "zxh"
  tab-width 4
  default-fill-column 80
  default-directory "~/"
  select-enable-clipboard t
  inhibit-splash-screen t
  initial-scratch-message nil
  sentence-end-double-space nil
  create-lockfiles nil
  indent-tabs-mode nil
  make-backup-files nil
  auto-save-default nil
  create-lockfiles nil)

;; Garbage Collection Tuning
(defmacro k-time (&rest body)
  "Measure and return the time it takes evaluating BODY."
  `(let ((time (current-time)))
     ,@body
     (float-time (time-since time))))

;; When idle for 30sec run the GC no matter what.
(defvar k-gc-timer
  (run-with-idle-timer 30 t
                       (lambda ()
                         (message "Garbage Collector has run for %.06fsec"
                                  (k-time (garbage-collect))))))

;; Set garbage collection threshold to 1GB.
(setq gc-cons-threshold #x40000000)
;; Set garbage collection to 20% of heap
(setq gc-cons-percentage 0.2)


(setq split-width-threshold 1)

;; Don't beep at me
(setq visible-bell t)

;; Turn off the blinking cursor
;;(blink-cursor-mode -1)

;; Don't create backups
(setq make-backup-files nil)
(set-fringe-mode '(6 . 0))

;; nice scrolling
;(setq scroll-margin 0
;      scroll-conservatively 100000
;      scroll-preserve-screen-position 1)

;; more useful frame title, that show either a file or a
;; buffer name (if the buffer isn't visiting a file)
(setq frame-title-format
      '((:eval (if (buffer-file-name)
                   (abbreviate-file-name (buffer-file-name))
		   "%b"))))

;; setup history of edited file
(savehist-mode 1)
(setq savehist-file "~/.emacs.d/.savehist")
(setq history-length t)
(setq history-delete-duplicates t)
(setq savehist-save-minibuffer-history 1)
(setq savehist-additional-variables
      '(kill-ring
	 search-ring
	 regexp-search-ring))

;; fix Tramp mode is much slower than using terminal to ssh
(setq remote-file-name-inhibit-cache nil)
(setq vc-ignore-dir-regexp
         (format "%s\\|%s"
                       vc-ignore-dir-regexp
                       tramp-file-name-regexp))
(setq tramp-verbose 1)

;; essential libs
(use-package s        )
(use-package ht       )
(use-package git      )
(use-package dash     )
(use-package mustache )
(use-package popup    )

(provide 'init-bootstrap)
