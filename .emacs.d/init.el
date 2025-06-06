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
   '("0f4e8712faa97372f505cac514d11f7fa0891e1dfc8bdf03208247b31fa29a01"
     default))
 '(highlight-parentheses-colors '("DarkOrange" "DeepSkyBlue" "DarkRed") nil nil "Customized with use-package highlight-parentheses"))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(vundo-highlight ((t (:foreground "#FFFF00"))))
 '(vundo-node ((t (:foreground "#808080"))))
 '(vundo-stem ((t (:foreground "#808080")))))
