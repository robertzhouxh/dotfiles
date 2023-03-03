(require 'org)
(require 'cl-lib)
(setq gc-cons-threshold (* 200 1024 1024))
(run-with-idle-timer 5 t #'garbage-collect)
(org-babel-load-file (expand-file-name "config.org" user-emacs-directory))
(put 'dired-find-alternate-file 'disabled nil)
