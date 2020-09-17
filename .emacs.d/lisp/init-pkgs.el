;;; init-pkgs.el
;;; Commentary:
;;; Code:

;; Basic plugins
(use-package exec-path-from-shell
  :if (x/system-is-mac)
  :config
  (exec-path-from-shell-initialize)
  (exec-path-from-shell-copy-env "GOROOT")
  (exec-path-from-shell-copy-env "GOPATH")
  )
(use-package diminish)
(use-package json-reformat)
(use-package comment-dwim-2)
(use-package buffer-flip)
(use-package markdown-mode)
(use-package dockerfile-mode)
(use-package json-mode)
(use-package protobuf-mode)
(use-package hydra)
(use-package projectile :config (projectile-global-mode))
(use-package avy :config (setq avy-background t))
(use-package flycheck :config (global-flycheck-mode 1))
(use-package restclient :mode ("\\.restclient\\'" . restclient-mode))
(use-package company-restclient :config (add-to-list 'company-backends 'company-restclient))

(use-package which-key
  :diminish which-key-mode
  :hook (after-init . which-key-mode)
  :config
  (progn
    (which-key-mode)
    (which-key-setup-side-window-right)))

(use-package highlight-indent-guides
  :ensure t
  :diminish
  :hook
  ((prog-mode yaml-mode) . highlight-indent-guides-mode)
  :custom
  (highlight-indent-guides-auto-enabled t)
  (highlight-indent-guides-responsive t)
  (highlight-indent-guides-method 'character)) ; column

(use-package volatile-highlights
  :ensure t
  :diminish
  :hook
  (after-init . volatile-highlights-mode)
  :custom-face
  (vhl/default-face ((nil (:foreground "#FF3333" :background "#FFCDCD")))))

(use-package undo-tree
  :ensure t
  :config
  (progn
    (global-undo-tree-mode)
    (setq undo-tree-visualizer-timestamps t)
    (setq undo-tree-visualizer-diff t)
    ))

(use-package multiple-cursors
  :bind
  (("C-c n" . mc/mark-next-like-this)
   ("C-c p" . mc/mark-previous-like-this)))

(use-package paredit
  :diminish paredit-mode
  :init
  (add-hook 'erlang-mode-hook 'paredit-mode)
  (add-hook 'go-mode-hook 'paredit-mode)
  (add-hook 'emacs-lisp-mode-hook 'paredit-mode))

(use-package yasnippet
  :init
  (yas-global-mode)
  :config
  (progn
    (add-to-list 'yas-snippet-dirs (concat user-emacs-directory "snippets"))))

(use-package company
  :diminish 'company-mode
  :init
  (global-company-mode)
  :config
  (setq company-idle-delay 0.2)
  (setq company-selection-wrap-around t)
  (define-key company-active-map [tab] 'company-complete)
  (define-key company-active-map (kbd "C-p") 'company-select-next)
  (define-key company-active-map (kbd "C-n") 'company-select-previous))

(use-package ag
  :defer t
  :config
  (progn
    (setq ag-highlight-search t)
    (bind-key "n" 'compilation-next-error ag-mode-map)
    (bind-key "p" 'compilation-previous-error ag-mode-map)
    (bind-key "N" 'compilation-next-file ag-mode-map)
    (bind-key "P" 'compilation-previous-file ag-mode-map)))

;; magit
(use-package magit
  :defer t
  :config
  (setq magit-display-buffer-function
      (lambda (buffer)
        (display-buffer
         buffer (if (and (derived-mode-p 'magit-mode)
                         (memq (with-current-buffer buffer major-mode)
                               '(magit-process-mode
                                 ;;magit-revision-mode
                                 magit-diff-mode
                                 magit-stash-mode
                                 magit-status-mode)))
                    nil
                  '(display-buffer-same-window)))))
  ;(setq magit-display-buffer-function 'magit-display-buffer-same-window-except-diff-v1)
  (add-hook 'magit-mode-hook
            (lambda ()
              (define-key magit-mode-map (kbd ",o") 'delete-other-windows)))
  (add-hook 'git-commit-mode-hook 'evil-insert-state))

(use-package git-messenger
  :bind ("C-x G" . git-messenger:popup-message)
  :config
  (setq git-messenger:show-detail t
	git-messenger:use-magit-popup t))

(use-package git-gutter
 :ensure t
  :custom
  (git-gutter:modified-sign "~")
  (git-gutter:added-sign    "+")
  (git-gutter:deleted-sign  "-")
  :custom-face
  (git-gutter:modified ((t (:background "#f1fa8c"))))
  (git-gutter:added    ((t (:background "#50fa7b"))))
  (git-gutter:deleted  ((t (:background "#ff79c6"))))
  :config
  (global-git-gutter-mode +1))


;; helm 全家桶 pk ivy 全家桶
;(use-package helm
;  :diminish helm-mode
;  :init
;  (progn
;    (setq helm-candidate-number-limit 100)
;    (setq helm-idle-delay 0.0 ; update fast sources immediately (doesn't).
;	  helm-input-idle-delay 0.01  ; this actually updates things
;					; reeeelatively quickly.
;	  helm-yas-display-key-on-candidate t
;	  helm-quick-update t
;	  helm-M-x-requires-pattern nil
;	  helm-ff-skip-boring-files t)
;    (helm-mode))
;  :config
;  (progn
;    (define-key helm-map (kbd "C-n") 'helm-next-line)
;    (define-key helm-map (kbd "C-p") 'helm-previous-line))
;  :bind  (("C-i" . helm-swoop)
;	  ("C-x C-f" . helm-find-files)
;	  ("C-x b" . helm-buffers-list)
;	  ("M-y" . helm-show-kill-ring)
;	  ("M-x" . helm-M-x)))
;(use-package helm-descbinds :init (helm-descbinds-mode))
;(use-package helm-swoop)
;(use-package helm-projectile)
;(use-package helm-ag
;  :defer t
;  :init
;  (setq helm-ag-base-command "ag --nocolor --nogroup --ignore-case"
;    	helm-ag-command-option "--all-text"
;	helm-ag-insert-at-point 'symbol))

;; ivy 全家桶 pk helm全家桶
(use-package ivy
  :diminish ivy-mode
  :ensure t
  :preface (eval-when-compile (declare-function ivy-mode nil))
  :init (setq ivy-use-virtual-buffers t)
  :config (ivy-mode t))
(use-package counsel
  :after ivy
  :demand t
  :ensure t
  :bind
  (("C-c C-r" . ivy-resume)
   ("C-x C-b" . ivy-switch-buffer)
   ("C-x C-f" . counsel-find-file)
   ("M-x"     . counsel-M-x)
   :map minibuffer-local-map
   ("C-r"     . counsel-minibuffer-history)
   :map ivy-minibuffer-map
   ("<left>"  . ivy-backward-kill-word)
   ("<right>" . ivy-alt-done)
   ("C-f"     . ivy-partial-or-done)
   ("C-h"     . ivy-backward-kill-word)
   ("C-j"     . ivy-next-line)
   ("C-k"     . ivy-previous-line)
   ("C-l"     . ivy-alt-done)
   ("C-r"     . ivy-previous-line-or-history)
   :map counsel-find-file-map
   ("<left>"  . counsel-up-directory)
   ("C-h"     . counsel-up-directory))
  :init
  (add-to-list 'ivy-ignore-buffers "^#")
  (add-to-list 'ivy-ignore-buffers "^\\*irc\\-")
  (with-eval-after-load 'evil-leader
    (evil-leader/set-key
      "bb" 'ivy-switch-buffer
      "br" 'counsel-recentf
      "dv" 'counsel-describe-variable
      "df" 'counsel-describe-function
      "/"  'counsel-rg)))
(use-package counsel-projectile
  :after (counsel projectile)
  :diminish counsel-projectile-mode
  :ensure t
  :preface (eval-when-compile (declare-function counsel-projectile-mode nil))
  :commands
  (counsel-projectile-rg
   counsel-projectile-find-file
   counsel-projectile-switch-project
   counsel-projectile-switch-to-buffer)
  :init
  (with-eval-after-load 'evil-leader
    (evil-leader/set-key
      "p/" 'counsel-projectile-rg
      "pf" 'counsel-projectile-find-file
      "pp" 'counsel-projectile-switch-project
      "pb" 'counsel-projectile-switch-to-buffer))
  :config (counsel-projectile-mode t))

(use-package ivy-prescient
  :after (ivy prescient)
  :ensure t
  :preface (eval-when-compile (declare-function ivy-prescient-mode nil))
  :config (ivy-prescient-mode t))
(use-package ivy-rich
  :ensure t
  :after (ivy counsel)
  :preface (eval-when-compile (defvar ivy-rich-path-style) (declare-function ivy-rich-mode nil))
  :init (setq ivy-rich-path-style 'abbrev)
  :config (ivy-rich-mode t))
(use-package prescient
  :ensure t
  :preface (eval-when-compile (declare-function prescient-persist-mode nil))
  :config (prescient-persist-mode t))
(use-package swiper
  :after ivy
  :ensure t
  :bind (("\C-s" . swiper)))


;; pk sublime
(use-package minimap
  :ensure t
  :commands
  (minimap-bufname minimap-create minimap-kill)
  :custom
  (minimap-major-modes '(prog-mode))

  (minimap-window-location 'right)
  (minimap-update-delay 0.2)
  (minimap-minimum-width 20)
  :bind ("C-M-m" . zxh/toggle-minimap)
  :preface
  (defun zxh/toggle-minimap ()
    "Toggle minimap for current buffer."
    (interactive)
    (if (null minimap-bufname)
    (minimap-create)
  (minimap-kill)))
  :config
  (custom-set-faces
    '(minimap-active-region-background
       ((((background dark)) (:background "#555555555555"))
	(t (:background "#C847D8FEFFFF"))) :group 'minimap)))

;; Remote SSH
(use-package tramp
  :config
  (setq tramp-default-method "ssh"
	tramp-auto-save-directory (expand-file-name "~/.emacs.d/auto-save-list")))

;; Make numbers in source code more noticeable
(use-package highlight-numbers
  :config (add-hook 'prog-mode-hook 'highlight-numbers-mode))

;; Jump
(use-package dumb-jump
  :diminish dumb-jump-mode
  :config
  ;(setq dumb-jump-selector 'helm)
  (setq dumb-jump-selector 'ivy)
  (setq dumb-jump-prefer-searcher 'ag))

(use-package ace-window
  :after hydra
  :functions hydra-frame-window/body
  :bind ("C-M-o" . hydra-frame-window/body)
  :custom (aw-keys '(?j ?k ?l ?i ?o ?h ?y ?u ?p))
  :custom-face (aw-leading-char-face ((t (:height 4.0 :foreground "#f1fa8c")))))

(use-package key-chord
  :config
  (progn
    (key-chord-define-global "bn" 'buffer-flip-forward)
    (key-chord-define-global "bp" 'buffer-flip-backward)
    (key-chord-define-global "bf" 'buffer-flip)
    (key-chord-define-global "bo" 'buffer-flip-other-window)
    (key-chord-define-global "ba" 'buffer-flip-abort)

    (key-chord-define-global "jb" 'ibuffer)
    (key-chord-define-global "j0" 'delete-window)
    (key-chord-define-global "j1" 'delete-other-windows)
    (key-chord-define-global "jz" 'magit-dispatch-popup)
    (key-chord-define-global "kb" 'gh/kill-current-buffer)
    (key-chord-mode 1)))

;; eshell
(use-package eshell
  :init
  (setq eshell-scroll-to-bottom-on-input 'all
        eshell-error-if-no-glob t
        eshell-hist-ignoredups t
        eshell-save-history-on-exit t
        eshell-prefer-lisp-functions nil
        eshell-destroy-buffer-when-process-dies t))
(setq eshell-prompt-function
      (lambda ()
        (concat
         (propertize "┌─[" 'face `(:foreground "green"))
         (propertize (user-login-name) 'face `(:foreground "red"))
         (propertize "@" 'face `(:foreground "green"))
         (propertize (system-name) 'face `(:foreground "lightblue"))
         (propertize "]──[" 'face `(:foreground "green"))
         (propertize (format-time-string "%H:%M" (current-time)) 'face `(:foreground "yellow"))
         (propertize "]──[" 'face `(:foreground "green"))
         (propertize (concat (eshell/pwd)) 'face `(:foreground "white"))
         (propertize "]\n" 'face `(:foreground "green"))
         (propertize "└─>" 'face `(:foreground "green"))
         (propertize (if (= (user-uid) 0) " # " " $ ") 'face `(:foreground "green"))
         )))



;; Font set

;Download official fonts https://go.googlesource.com/image/+archive/master/font/gofont/ttfs.tar.gz
;tar -xvzf image-master-font-gofont-ttfs.tar.gz
;Click on ttf file to install respective font.
;In Mac, Font Book will open by default.
;Ubuntu has font application too. Click on install.

(setq my-font-list '("Source Code Pro" "monaco" "menlo" "Go Mono"))
(defun my-set-frame-font (font-name size &optional frames)
  "Set font to one of the fonts from `my-font-list'
Argument FRAMES has the same meaning as for `set-frame-font'"
  (interactive
   (list (ivy-read "Font name: " my-font-list)
         (read-number "Font size: ")))
  (set-frame-font
   (format "%s:pixelsize=%d:antialias=true:autohint=true" font-name size)
   nil frames))

(global-set-key (kbd "C-c F") #'my-set-frame-font)

;; UI
(load-theme 'wombat t)
(set-cursor-color "#00ff00")

(provide 'init-pkgs)
