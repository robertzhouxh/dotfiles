;;; package --- Summary
;;; Commentary:
;;; Code:

;; setup the load path
(defvar vendor-dir (expand-file-name "vendor" user-emacs-directory))
(defvar lisp-dir (expand-file-name "lisp" user-emacs-directory))
(add-to-list 'load-path lisp-dir)
(add-to-list 'load-path vendor-dir)
(let ((default-directory "/usr/local/share/emacs/site-lisp/"))
  (normal-top-level-add-subdirs-to-load-path))

;; Setup pkg repo and install use-package
(require 'package)
(setq package-enable-at-startup nil)
(setq package-archives '(("gnu"   . "http://elpa.emacs-china.org/gnu/")
                         ("melpa" . "http://elpa.emacs-china.org/melpa/")
                         ("marmalade" . "http://marmalade-repo.org/packages/")))

(package-initialize)
(setq use-package-always-ensure nil)

;;; auto install use-package
(unless (require 'use-package nil t)
  (if (not (yes-or-no-p (concat "Refresh packages, install use-package and"
                                " other packages used by init file? ")))
      (error "you need to install use-package first")
    (package-refresh-contents)
    (package-install 'use-package)
    (require 'use-package)
    (setq use-package-always-ensure t)))

;; Use separate custom file
(setq custom-file "~/.emacs.d/custom.el")
(if (file-exists-p custom-file)
    (load custom-file))

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
