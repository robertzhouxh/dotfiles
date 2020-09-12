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
(use-package which-key
  :diminish which-key-mode
  :config
  (progn
    ;; for emacs 26+
    (which-key-setup-side-window-right)
    (which-key-mode 1)))

;; File explorer sidebar
(use-package treemacs
	     :bind
	     (("C-c t" . treemacs)
	      ("s-a" . treemacs)))

;; Cycle through buffers’ history
(use-package buffer-flip
  :bind
  (("H-f" . buffer-flip)
   :map buffer-flip-map
   ("H-f" . buffer-flip-forward)
   ("H-F" . buffer-flip-backward)
   ("C-g" . buffer-flip-abort)))

;;; Improved in buffer search
(use-package ctrlf :config (ctrlf-mode 1))
(use-package avy
  :bind
  (("H-." . avy-goto-char-timer)
   ("H-," . avy-goto-line)))

(use-package multiple-cursors
  :bind
  (("C-c n" . mc/mark-next-like-this)
   ("C-c p" . mc/mark-previous-like-this)))

(use-package paredit
  :diminish paredit-mode
  :init
  (add-hook 'erlang-mode-hook 'paredit-mode)
  ;(add-hook 'go-mode-hook 'paredit-mode)
  (add-hook 'emacs-lisp-mode-hook 'paredit-mode))

(use-package flycheck
  :config
  (global-flycheck-mode 1))

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

;; Emacs framework for incremental completions and narrowing selections
(use-package helm-descbinds
  :init (helm-descbinds-mode))
(use-package helm
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
    (define-key helm-map (kbd "C-n") 'helm-next-line)
    (define-key helm-map (kbd "C-p") 'helm-previous-line))
  :bind  (("C-i" . helm-swoop)
	  ("C-x C-f" . helm-find-files)
	  ("C-x b" . helm-buffers-list)
	  ("M-y" . helm-show-kill-ring)
	  ("M-x" . helm-M-x)))

;; highlight symbol and search
(use-package avy :config (setq avy-background t))
(use-package helm-swoop)
;; substitue the default  C-s(isearch-forward)
(use-package swiper :bind (("C-s" . swiper)))
(use-package ag
  :defer t
  :config
  (progn
    (setq ag-highlight-search t)
    (bind-key "n" 'compilation-next-error ag-mode-map)
    (bind-key "p" 'compilation-previous-error ag-mode-map)
    (bind-key "N" 'compilation-next-file ag-mode-map)
    (bind-key "P" 'compilation-previous-file ag-mode-map)))
(use-package helm-ag
  :defer t
  :init
  (setq helm-ag-base-command "ag --nocolor --nogroup --ignore-case"
	helm-ag-command-option "--all-text"
	helm-ag-insert-at-point 'symbol))

;;;; magit
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

(use-package git-commit :hook (git-commit-mode . my-american-dict))
(use-package git-messenger
  :bind ("C-x G" . git-messenger:popup-message)
  :config
  (setq git-messenger:show-detail t
	git-messenger:use-magit-popup t))

(use-package git-gutter
  :diminish git-gutter+-mode
  :defer t
  :init
  (global-git-gutter-mode t)
  :config
  (progn
    (setq git-gutter:window-width 2)
    (setq git-gutter:modified-sign "==")
    (setq git-gutter:added-sign "++")
    (setq git-gutter:deleted-sign "--")
    (set-face-foreground 'git-gutter:added "#daefa3")
    (set-face-foreground 'git-gutter:deleted "#FA8072")
    (set-face-foreground 'git-gutter:modified "#b18cce")
    ))

;;  以项目为单位的一些实用功能, Projectile 可以与 Helm 集成
(use-package projectile
  :config
  (projectile-global-mode))
(use-package helm-projectile)

;; Remote SSH
(use-package tramp
  :config
  (setq tramp-default-method "ssh"
	tramp-auto-save-directory (expand-file-name "~/.emacs.d/auto-save-list")))

(use-package dumb-jump
  :diminish dumb-jump-mode
  :config
  (setq dumb-jump-selector 'helm)
  (setq dumb-jump-prefer-searcher 'ag))

;; UI
(setq my-font-list '("monaco" "menlo" "Source Code Pro"))

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

(load-theme 'wombat t)
(set-cursor-color "#00ff00")

(provide 'init-pkgs)
