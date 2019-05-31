;;; init-pkgs.el
;;; Commentary:
;;; Code:

;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;; Basic plugins
;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
(use-package exec-path-from-shell
  :ensure t
  :if (x/system-is-mac)
  :config
  (exec-path-from-shell-initialize)
  (exec-path-from-shell-copy-env "GOROOT")
  (exec-path-from-shell-copy-env "GOPATH")
  ;;(exec-path-from-shell-copy-env "LC_ALL")
  ;;(exec-path-from-shell-copy-env "LANG")
  ;;(exec-path-from-shell-copy-env "LC_TYPE")
  )
(use-package diminish :ensure t)
(use-package json-reformat :ensure t :defer t)
(use-package comment-dwim-2 :ensure t)
(use-package which-key
  :ensure t
  :diminish which-key-mode
  :defer 10
  :config
  (progn
    ;; for emacs 26+
    (which-key-setup-side-window-right)
    (which-key-mode 1)))

(use-package paredit
  :ensure t
  :diminish paredit-mode
  :init
  (add-hook 'erlang-mode-hook 'paredit-mode)
  (add-hook 'go-mode-hook 'paredit-mode)
  (add-hook 'emacs-lisp-mode-hook 'paredit-mode))

(use-package flycheck
  :ensure t
  :defer 5
  :config
  (global-flycheck-mode 1))

;; refer https://github.com/AndreaCrotti/yasnippet-snippets
(use-package yasnippet
  :ensure t
  :defer t
  :init
  (yas-global-mode)
  :config
  (progn
    (add-to-list 'yas-snippet-dirs (concat user-emacs-directory "snippets"))))

(use-package company
  :ensure t
  :diminish 'company-mode
  :defer t
  :init
  (global-company-mode)
  :config
  (setq company-idle-delay 0.2)
  (setq company-selection-wrap-around t)
  (define-key company-active-map [tab] 'company-complete)
  (define-key company-active-map (kbd "C-j") 'company-select-next)
  (define-key company-active-map (kbd "C-k") 'company-select-previous))

;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;; Emacs framework for incremental completions and narrowing selections
;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
(use-package helm-descbinds
  :ensure t
  :init (helm-descbinds-mode))
(use-package helm
  :ensure t
  :diminish helm-mode
  :init
  (progn
    (setq helm-candidate-number-limit 100)
    (setq helm-idle-delay 0.0 ; update fast sources immediately (doesn't).
	  helm-input-idle-delay 0.01  ; this actually updates things
					; reeeelatively quickly.
	  helm-yas-display-key-on-candidate t
	  helm-quick-update t
	  helm-M-x-requires-pattern nil
	  helm-ff-skip-boring-files t)
    (helm-mode))
  :config
  (progn
    (define-key helm-map (kbd "C-j") 'helm-next-line)
    (define-key helm-map (kbd "C-k") 'helm-previous-line))
  :bind  (("C-i" . helm-swoop)
	  ("C-x C-f" . helm-find-files)
	  ("C-x b" . helm-buffers-list)
	  ("M-y" . helm-show-kill-ring)
	  ("M-x" . helm-M-x)))

;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;; highlight symbol and search
;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;; 增量搜索匹配行, 类似于helm-occur，但会即时显示匹配的部分
(use-package avy :ensure t :config (setq avy-background t))
(use-package helm-swoop :ensure t)
;; substitue the default  C-s(isearch-forward)
(use-package swiper :ensure t :bind (("C-s" . swiper)))
(use-package symbol-overlay
  :ensure t
;  :bind (:map symbol-overlay-mode-map
;	      ("M-h" . symbol-overlay-put)
;	      ("M-n" . symbol-overlay-jump-next)
;	      ("M-p" . symbol-overlay-jump-prev))
  :hook ((conf-mode . symbol-overlay-mode)
	 (html-mode . symbol-overlay-mode)
	 (prog-mode . symbol-overlay-mode)
	 (org-mode . symbol-overlay-mode)
	 (yaml-mode . symbol-overlay-mode)))
(use-package ag
  :ensure t
  :defer t
  :config
  (progn
    (setq ag-highlight-search t)
    (bind-key "n" 'compilation-next-error ag-mode-map)
    (bind-key "p" 'compilation-previous-error ag-mode-map)
    (bind-key "N" 'compilation-next-file ag-mode-map)
    (bind-key "P" 'compilation-previous-file ag-mode-map)))
(use-package helm-ag
  :ensure t
  :defer t
  :init
  (setq helm-ag-base-command "ag --nocolor --nogroup --ignore-case"
	helm-ag-command-option "--all-text"
	helm-ag-insert-at-point 'symbol))

;(use-package golden-ratio
;  :ensure t
;  :diminish golden-ratio-mode
;  :init
;  (golden-ratio-mode 1))

;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;; version control
;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

(use-package magit
  :ensure t
  :defer t
  :config
  (progn
    (setq magit-branch-prefer-remote-upstream '("master"))
    (setq magit-branch-adjust-remote-upstream-alist '(("origin/master" "master")))
    (setq magit-branch-arguments nil)))

;(use-package git-gutter
;  :ensure t
;  :diminish git-gutter+-mode
;  :defer t
;  :init
;  (global-git-gutter-mode t)
;  :config
;  (progn
;    (setq git-gutter:window-width 2)
;    (setq git-gutter:modified-sign "==")
;    (setq git-gutter:added-sign "++")
;    (setq git-gutter:deleted-sign "--")
;    (set-face-foreground 'git-gutter:added "#daefa3")
;    (set-face-foreground 'git-gutter:deleted "#FA8072")
;    (set-face-foreground 'git-gutter:modified "#b18cce")
;    ))

;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;;  以项目为单位的一些实用功能, Projectile 可以与 Helm 集成
;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
(use-package projectile
  :ensure t
  :config
  (projectile-global-mode))
(use-package helm-projectile :ensure t :defer t)

;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;; Eshell + Remote SSH
;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
(use-package eshell
  :ensure t
  :config
  (require 'f)
  (setq eshell-visual-commands
	'("less" "tmux" "htop" "top" "bash" "zsh" "fish"))
  (setq eshell-visual-subcommands
	'(("git" "log" "l" "diff" "show")))
  ;; Prompt with a bit of help from http://www.emacswiki.org/emacs/EshellPrompt
  (defmacro with-face (str &rest properties)
    `(propertize ,str 'face (list ,@properties)))

  (defun eshell/abbr-pwd ()
    (let ((home (getenv "HOME"))
	  (path (eshell/pwd)))
      (cond
       ((string-equal home path) "~")
       ((f-ancestor-of? home path) (concat "~/" (f-relative path home)))
       (path))))

  (defun eshell/my-prompt ()
    (let ((header-bg "#161616"))
      (concat
       (with-face user-login-name :foreground "#d75faf")
       " "
       (with-face (eshell/abbr-pwd) :foreground "#008700")
       (if (= (user-uid) 0)
	   (with-face "#" :foreground "red")
	 (with-face "$" :foreground "#2345ba"))
       " ")))
  (setq eshell-prompt-function 'eshell/my-prompt)
  (setq eshell-highlight-prompt nil)
  (setq eshell-prompt-regexp "^[^#$\n]+[#$] ")
  (setq eshell-cmpl-cycle-completions nil))

(use-package tramp
  :ensure t
  :defer t
  :config
  (setq tramp-default-method "ssh"
	tramp-auto-save-directory (expand-file-name "~/.emacs.d/auto-save-list")))

;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;; Find defination
;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
(require 'gtags)
(use-package bpr :ensure t)
;; Bind some useful keys in the gtags select buffer that evil overrides.
(add-hook 'gtags-select-mode-hook
	  (lambda ()
	    (evil-define-key 'normal gtags-select-mode-map (kbd "RET") 'gtags-select-tag)
	    (evil-define-key 'normal gtags-select-mode-map (kbd "q") 'kill-buffer-and-window)))

(defun gtags-reindex ()
  "Kick off gtags reindexing."
  (interactive)
  (let* ((root-path (expand-file-name (vc-git-root (buffer-file-name))))
	 (gtags-filename (expand-file-name "GTAGS" root-path)))
    (if (file-exists-p gtags-filename)
	(gtags-index-update root-path)
      (gtags-index-initial root-path))))

(defun gtags-index-initial (path)
  "Generate initial GTAGS files for PATH."
  (let ((bpr-process-directory path))
    (bpr-spawn "gtags")))

(defun gtags-index-update (path)
  "Update GTAGS in PATH."
  (let ((bpr-process-directory path))
    (bpr-spawn "global -uv")))

(use-package dumb-jump
  :ensure t
  :diminish dumb-jump-mode
  :config
  (setq dumb-jump-selector 'helm)
  (setq dumb-jump-prefer-searcher 'ag))

;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;; UI Schemes + Modeline
;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
(use-package all-the-icons :ensure t)
(use-package kaolin-themes
  :ensure t
  :config
  (load-theme 'kaolin-dark t)
  (kaolin-treemacs-theme))
(use-package doom-themes
  :ensure t
  :defer t)
(use-package doom-modeline
  :ensure t
  :defer t
  :config
  (setq doom-modeline-icon nil)
  (setq doom-modeline-height 22)
  (setq doom-modeline-vcs-max-length 12)
  (setq auto-revert-check-vc-info t)
  (setq doom-modeline-github nil)
  (doom-modeline-def-modeline
    'gs
    ;; Left mode line segments
    '(bar window-number "  " matches buffer-info buffer-position selection-info)
    ;; Right mode line segments
    '(major-mode buffer-encoding vcs checker))
  (doom-modeline-set-modeline 'gs t)
  :hook (after-init . doom-modeline-init))

(use-package birds-of-paradise-plus-theme :ensure t :defer t)
(use-package plain-theme :ensure t :defer t)
(use-package spacemacs-theme :ensure t :defer t)
(use-package tao-theme :ensure t :defer t)
(use-package dracula-theme :ensure t :defer t)
(use-package plan9-theme :ensure t :defer t)

;;(load-theme 'doom-molokai t)
;;(load-theme 'doom-vibrant t)
(load-theme 'wombat t)

(provide 'init-pkgs)
