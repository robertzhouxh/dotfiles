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
 '(package-selected-packages
   '(use-package-ensure-system-package youdao-dictionary yasnippet-snippets yaml-mode which-key valign undo-fu toc-org rust-mode rime restclient rainbow-delimiters protobuf-mode plantuml-mode ox-odt org-modern org-auto-tangle nginx-mode modern-cpp-font-lock markdown-mode magit lua-mode live-py-mode json-reformat json-mode highlight-parentheses go-mode flycheck f exec-path-from-shell evil-leader engrave-faces dumb-jump dockerfile-mode disable-mouse diff-hl dash-at-point counsel-projectile comment-dwim-2 buffer-flip avy auctex all-the-icons ag))
 '(tramp-verbose 0))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
