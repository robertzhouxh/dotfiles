;;; package --- Summary
;;; Commentary:
;;; Code:

;; === SETUP ===
(require 'package) ;; You might already have this line

(defvar vendor-dir (expand-file-name "vendor" user-emacs-directory))
(defvar backup-dir "~/.emacs.d/backups/")

(add-to-list 'package-archives '("org" . "http://orgmode.org/elpa/") t)
(add-to-list 'load-path (expand-file-name "lisp" user-emacs-directory))
(add-to-list 'load-path vendor-dir)
(add-to-list 'exec-path "/usr/local/bin")
(add-to-list 'exec-path "/usr/bin")

(let ((files (directory-files-and-attributes "~/.emacs.d/lisp" t)))
  (dolist (file files)
    (let ((filename (car file))
          (dir (nth 1 file)))
      (when (and dir
                 (not (string-suffix-p "." filename)))
        (add-to-list 'load-path (car file))))))

(let ((default-directory "/usr/local/share/emacs/site-lisp/"))
  (normal-top-level-add-subdirs-to-load-path))

;;; Standard package repositories
(setq package-archives '(("gnu"   . "http://elpa.emacs-china.org/gnu/")
                         ("melpa" . "http://elpa.emacs-china.org/melpa/")))

;;; Pin some packages to specific repositories.
;(setq package-pinned-packages '((gtags . "marmalade")))

(package-initialize) ;; You might already have this line

;(setq url-proxy-services `(("http" . "127.0.0.1:8123")
;                           ("https" . "127.0.0.1:8123")))

;;; auto install use-package
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

;; (setq use-package-always-ensure t)
(setq package-enable-at-startup nil)

(eval-when-compile
  (require 'use-package))

;;; My own configurations, which are bundled in my dotfiles.
(require 'init-bootstrap)
(require 'init-utils)
(require 'init-plantform)
(require 'init-pkgs)
(require 'init-evil)
;;(require 'init-evil-eshell)
(require 'init-org)
(require 'init-languages)
(require 'init-maps)

(provide 'init)
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(cider-repl-history-file "~/.emacs.d/cider-history")
 '(cider-repl-history-size 5000)
 '(cider-repl-pop-to-buffer-on-connect t)
 '(cider-repl-result-prefix "; => ")
 '(cider-repl-use-clojure-font-lock t)
 '(cider-repl-use-pretty-printing t)
 '(cider-repl-wrap-history t)
 '(cider-show-error-buffer nil)
 '(custom-safe-themes
   (quote
    ("f153e8ed90e4d79cf2c61560da2b3091d2f3b94da42aaddc707012be4608cf52" "291588d57d863d0394a0d207647d9f24d1a8083bb0c9e8808280b46996f3eb83" "b9cbfb43711effa2e0a7fbc99d5e7522d8d8c1c151a3194a4b176ec17c9a8215" "30f7c9e85d7fad93cf4b5a97c319f612754374f134f8202d1c74b0c58404b8df" "98cc377af705c0f2133bb6d340bf0becd08944a588804ee655809da5d8140de6" "12ae26f3493216be1bc0bbd28732671e8672bc3c631f1cea042a1040b136058a" "a4c9e536d86666d4494ef7f43c84807162d9bd29b0dfd39bdf2c3d845dcc7b2e" "3629b62a41f2e5f84006ff14a2247e679745896b5eaa1d5bcfbc904a3441b0cd" "8aebf25556399b58091e533e455dd50a6a9cba958cc4ebb0aab175863c25b9a4" default)))
 '(package-selected-packages
   (quote
    (highlight-indentation dockerfile-mode docker geiser racket-mode ansible markdown-mode web-mode js2-mode go-eldoc company-go paredit color-identifiers-mode ac-slime slime lua-mode bpr yasnippet yaml-mode wsd-mode which-key use-package uimage rainbow-mode rainbow-delimiters ox-ioslide org-page org-evil org-bullets multiple-cursors magit json-reformat hippie-exp-ext highlight-symbol helm-projectile helm-descbinds helm-ag git-gutter flycheck exec-path-from-shell evil-surround evil-leader evil-indent-textobject dired-k diminish company comment-dwim-2 ag)))
 '(pos-tip-background-color "#36473A")
 '(pos-tip-foreground-color "#FFFFC8"))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
