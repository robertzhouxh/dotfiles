(setq byte-compile-warnings '(cl-functions))
(setq native-comp-async-report-warnings-errors nil)
(org-babel-load-file (expand-file-name "config.org" user-emacs-directory))
