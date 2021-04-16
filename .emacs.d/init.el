;; set garbage collection threshold high for initialization
(setq gc-cons-threshold (* 100 1000 1000))
(setq byte-compile-warnings '(not cl-functions obsolete))
(set 'ad-redefinition-action 'accept)
(org-babel-load-file (expand-file-name "config.org" user-emacs-directory))
(put 'dired-find-alternate-file 'disabled nil)
