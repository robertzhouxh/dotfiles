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
   '("9f2a181c19c10162f6135a007443d5e7e5524070f7aedd5d4c442cc80e7d3ebe" "7b303763746ab4ab92fd18d911073aadb1393d36263ba1f04f5e0641e94f6d54" "3fec737266204a5422e5acc776ea55e1a2fcd3a8104fd8c70ee0a300e56ece3c" "dbade2e946597b9cda3e61978b5fcc14fa3afa2d3c4391d477bdaeff8f5638c5" "801a567c87755fe65d0484cb2bded31a4c5bb24fd1fe0ed11e6c02254017acb2" default))
 '(package-selected-packages
   '(yasnippet-snippets youdao-dictionary yasnippet yaml-mode which-key visual-fill-column undo-fu toc-org tao-theme rust-mode rime restclient rainbow-delimiters protobuf-mode plantuml-mode org-modern org-download org-auto-tangle nginx-mode modern-cpp-font-lock markdown-mode lua-mode live-py-mode keyfreq json-reformat json-mode highlight-parentheses go-mode flycheck exec-path-from-shell evil-leader engrave-faces dumb-jump dockerfile-mode diff-hl dash-at-point counsel-projectile comment-dwim-2 buffer-flip avy all-the-icons ag))
 '(tramp-verbose 0))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
