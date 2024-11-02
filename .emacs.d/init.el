(require 'org)
(require 'cl-lib)
(setq byte-compile-warnings '(cl-functions))
(org-babel-load-file (expand-file-name "config.org" user-emacs-directory))
(put 'dired-find-alternate-file 'disabled nil)
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-safe-themes
   '("7b303763746ab4ab92fd18d911073aadb1393d36263ba1f04f5e0641e94f6d54" "0f4e8712faa97372f505cac514d11f7fa0891e1dfc8bdf03208247b31fa29a01" "67f6b0de6f60890db4c799b50c0670545c4234f179f03e757db5d95e99bac332" "9f2a181c19c10162f6135a007443d5e7e5524070f7aedd5d4c442cc80e7d3ebe" default))
 '(tramp-verbose 0))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
