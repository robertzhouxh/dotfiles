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
   '("d6b369a3f09f34cdbaed93eeefcc6a0e05e135d187252e01b0031559b1671e97"
     default))
 '(highlight-parentheses-colors '("DarkOrange" "DeepSkyBlue" "DarkRed") nil nil "Customized with use-package highlight-parentheses"))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
