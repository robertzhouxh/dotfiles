;;; package --- Summary
;;; Commentary:
;;; Code:

;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;;	setup the load path
;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
(defvar vendor-dir (expand-file-name "vendor" user-emacs-directory))
(defvar lisp-dir (expand-file-name "lisp" user-emacs-directory))
(add-to-list 'load-path lisp-dir)
(add-to-list 'load-path vendor-dir)
(let ((default-directory "/usr/local/share/emacs/site-lisp/"))
  (normal-top-level-add-subdirs-to-load-path))

;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;;	Setup pkg repo and install use-package
;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
(require 'package)
(setq package-enable-at-startup nil)
;;(setq package-archives '(("gnu"   . "http://elpa.emacs-china.org/gnu/")
;;                         ("melpa" . "http://elpa.emacs-china.org/melpa/")
;;                         ("marmalade" . "http://marmalade-repo.org/packages/")))

(unless (assoc-default "melpa" package-archives)
  (add-to-list 'package-archives '("melpa" . "http://mirrors.tuna.tsinghua.edu.cn/elpa/melpa/") t))
(unless (assoc-default "org" package-archives)
  (add-to-list 'package-archives '("org" . "https://orgmode.org/elpa/") t))
(unless (assoc-default "marmalade" package-archives)
  (add-to-list 'package-archives '("gnu" . "http://mirrors.tuna.tsinghua.edu.cn/elpa/gnu/")))
(setq package-pinned-packages '((gtags . "marmalade")))
(package-initialize)

;; config changes made through the customize UI will be stored here
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(load custom-file 'noerror)

;;; auto install use-package
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(eval-when-compile
  (require 'use-package))
(setq use-package-verbose t)
(setq use-package-always-ensure t)

;; proxy?
;(setq url-proxy-services `(("http" . "127.0.0.1:8123")
;                           ("https" . "127.0.0.1:8123")))
;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;;	load my own configurations
;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
(require 'init-bootstrap)
(require 'init-utils)
(require 'init-plantform)
(require 'init-pkgs)
(require 'init-evil)
(require 'init-org)
(require 'init-languages)
(require 'init-maps)

(provide 'init)
