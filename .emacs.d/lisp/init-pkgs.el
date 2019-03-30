;;; init-packages.el
;;; Commentary:
;;; Code:

;; Utilities
(use-package diminish
             :ensure t)
(use-package exec-path-from-shell
             :ensure t
             :config
             (exec-path-from-shell-initialize)
             (exec-path-from-shell-copy-env "GOPATH"))
(use-package which-key
             :ensure t
             :diminish which-key-mode
             :defer 10
             :config
             (progn
               ;; for emacs 26+
               (which-key-setup-side-window-right)
               (which-key-mode 1)))
(use-package helm-descbinds
             :ensure t
             :init (helm-descbinds-mode))
(use-package json-reformat
             :ensure t
             :defer t
             :bind (("C-x i" . json-reformat-region)))
(use-package rainbow-mode
             :ensure t
             :defer t
             :commands rainbow-mode)
(use-package rainbow-delimiters
             :defer t
             :ensure t
             :init
             (add-hook 'prog-mode-hook 'rainbow-delimiters-mode))
(use-package comment-dwim-2 :ensure t)
;(use-package multiple-cursors
;             :ensure t
;             :init
;             (progn
;               ;; these need to be defined here - if they're lazily loaded with
;               ;; :bind they don't work.
;               (global-set-key (kbd "C-c .") 'mc/mark-next-like-this)
;               (global-set-key (kbd "C->") 'mc/mark-next-like-this)
;               (global-set-key (kbd "C-c ,") 'mc/mark-previous-like-this)
;               (global-set-key (kbd "C-<") 'mc/mark-previous-like-this)
;               (global-set-key (kbd "C-c C-l") 'c/mark-all-like-this)))
(use-package helm
             :ensure t
             :diminish helm-mode
             :defer t
             :bind
             ("C-x C-f" . helm-find-files)
             ("C-x b" . helm-mini)
             :commands helm-mode
             :init (progn
                     ;; for os-x add the line
                     (setq helm-man-format-switches "%s")
                     (require 'helm-config)
                     (setq helm-split-window-default-side 'other)
                     (setq helm-split-window-in-side-p t))
             :config (progn
                       (setq
                         helm-move-to-line-cycle-in-source nil
                         ;helm-split-window-default-side 'left
                         ;helm-always-two-windows t
                         helm-candidate-number-limit 200
                         helm-M-x-requires-pattern 0
                         helm-google-suggest-use-curl-p t
                         )
                       (helm-autoresize-mode 1)
                       (define-key helm-map (kbd "C-b") 'helm-keyboard-quit)
                       (define-key helm-map (kbd "C-p") 'helm-keyboard-quit)
                       (define-key helm-map (kbd "C-j") 'helm-next-line)
                       (define-key helm-map (kbd "C-k") 'helm-previous-line)
                       ))
(use-package highlight-symbol
             :defer t
             :ensure t
             :config
             (setq-default highlight-symbol-idle-delay 1.5))

(use-package hl-todo                    ; Highlight TODO and similar keywords
             :ensure nil
             :hook ((prog-mode . hl-todo-mode)
                    (yaml-mode . hl-todo-mode)))

(use-package flycheck
             :ensure t
             :defer t
             :config
             (global-flycheck-mode)
             ;; disable jshint since we prefer eslint checking
             (setq-default flycheck-disabled-checkers
                           (append flycheck-disabled-checkers
                                   '(javascript-jshint)))

             (setq flycheck-checkers '(javascript-eslint))
             ;; use eslint with web-mode for jsx files
             (flycheck-add-mode 'javascript-eslint 'web-mode)
             (flycheck-add-mode 'javascript-eslint 'js2-mode)
             (flycheck-add-mode 'javascript-eslint 'js-mode)
             ;; To verify just do C-h v flycheck-eslintrc
             (setq flycheck-eslintrc "~/.eslintrc"))

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

(use-package yasnippet
             :ensure t
             :defer t
             ;:diminish yas-minor-mode
             :init
             (yas-global-mode)
             :config
             (progn
               (add-to-list 'yas-snippet-dirs (concat user-emacs-directory "snippets"))
               ;; refer https://github.com/AndreaCrotti/yasnippet-snippets
               ))

;(use-package hippie-expand
(use-package hippie-exp-ext
             :ensure t
             :defer t
             :init
             (setq hippie-expand-try-functions-list
                   '(try-complete-file-name-partially
                      try-complete-file-name
                      try-expand-dabbrev
                      try-expand-dabbrev-all-buffers
                      try-expand-dabbrev-from-kill))
             :bind
             ("M-/" . hippie-expand))

(use-package magit
             :ensure t
             :defer t
             :bind (("M-g s" . magit-status)
                    ("M-g l" . magit-log)
                    ("M-g f" . magit-pull)
                    ("M-g p" . magit-push)
                    ("M-g x" . magit-reset-hard))
             :init
             (setq magit-popup-show-common-commands nil)
             (setq magit-log-arguments '("--graph"
                                         "--decorate"
                                         "--color"))
             :config
             (progn
               (defadvice magit-status (around magit-fullscreen activate)
                          (window-configuration-to-register :magit-fullscreen)
                          ad-do-it
                          (delete-other-windows))

               (defun magit-quit-session ()
                 "Restores the previous window configuration and kills the magit buffer"
                 (interactive)
                 (kill-buffer)
                 (jump-to-register :magit-fullscreen))

               (define-key magit-status-mode-map (kbd "q") 'magit-quit-session))

             ;; removes 1.4.0 warning in arguably cleaner way
             (remove-hook 'after-init-hook 'magit-maybe-show-setup-instructions)
             (defadvice magit-blame-mode (after switch-to-emacs-state activate)
                        (if magit-blame-mode
                          (evil-emacs-state 1)
                          (evil-normal-state 1))))

(use-package git-gutter
             :ensure t
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

(use-package projectile
             :defer t
             :ensure t
             :diminish projectile-mode
             :config
             (projectile-global-mode)
             (setq projectile-enable-caching t))

(use-package helm-projectile
             :defer t
             :commands (helm-projectile helm-projectile-switch-project)
             :ensure t)

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
             (define-key company-active-map (kbd "C-n") 'company-select-next)
             (define-key company-active-map (kbd "C-p") 'company-select-previous))

(use-package paredit
             :ensure t
             :diminish paredit-mode
             :init
             (add-hook 'erlang-mode-hook 'paredit-mode)
             (add-hook 'go-mode-hook 'paredit-mode)
             (add-hook 'emacs-lisp-mode-hook 'paredit-mode))

;; reffer to http://jwintz.me/blog/2014/02/16/helm-dash-makes-you-efficient/
;(use-package helm-dash
;             :ensure t
;             :defines (helm-dash-docsets)
;             :functions (esk-helm-dash-install
;                          helm-dash-web
;                          helm-dash-go
;                          helm-dash-installed-docsets)
;             :commands (helm-dash-at-point esk-helm-dash-install)
;             :preface
;             (progn
;               (defvar esk-dash-docsets
;                 ;'("Bash" "C" "C++" "Go" "Redis" "Ansible" "UnderscoreJS" "JavaScript" "React"))
;                 '("Bash" "Go" "Clojure"))
;
;               (defun esk-helm-dash-install (docset-name)
;                 (message (format "Installing helm-dash docset '%s'" docset-name))
;                 (unless (file-exists-p (concat (concat helm-dash-docsets-path docset-name) ".docset"))
;                   (helm-dash-install-docset docset-name)))
;
;               (defun esk-dash-limit (docsets-names)
;                 (set (make-local-variable 'helm-dash-docsets) docsets-names))
;
;               (defun helm-dash-bash () (esk-dash-limit '("Bash")))
;               (defun helm-dash-go () (esk-dash-limit '("Go" "Redis")))
;               (defun helm-dash-clojure () (esk-dash-limit '("Clojure")))
;               (defun helm-dash-yaml () (esk-dash-limit '("Ansible")))
;               (defun helm-dash-c () (esk-dash-limit '("c")))
;               (defun helm-dash-web () (esk-dash-limit '("UnderscoreJS" "JavaScript" "React")))
;
;               :init
;               (progn
;                 (setq helm-dash-docsets-path "~/.emacs.d/docsets/")
;                 (after sh-script (add-hook 'sh-mode-hook 'helm-dash-bash))
;                 (after go-mode (add-hook 'go-mode-hook 'helm-dash-go))
;                 (after clojure-mode (add-hook 'clojure-mode-hook 'helm-dash-clojure))
;                 ;(after yaml-mode (add-hook 'yaml-mode-hook 'helm-dash-yaml))
;                 ;(after c-mode (add-hook 'c-mode-hook 'helm-dash-c))
;                 ;(after web-mode (add-hook 'web-mode-hook 'helm-dash-web))
;                 )
;               :config
;               (progn
;                 (defun eww-split (url)
;                   (interactive)
;                   (select-window (split-window-right))
;                   (eww url))
;                 (setq helm-dash-browser-func 'eww-split)
;                 ;(setq helm-dash-browser-func 'eww)
;                 (add-hook 'prog-mode-hook
;                           (lambda ()
;                             (interactive)
;                             (setq helm-current-buffer (current-buffer))))
;                 (dolist (docset esk-dash-docsets)
;                   (esk-helm-dash-install docset))
;                 )))
;; UI
;(use-package moe-theme                     ; Theme
;  :ensure t
;  :config
;  (load-theme 'moe-dark t))

(use-package darktooth-theme               ; Theme
  :ensure t
  ;:disabled t
  :config
  (load-theme 'darktooth t))
;(use-package solarized-theme
;             :ensure t
;             :disabled t
;             :init
;             (load-theme 'solarized-light 'no-confirm))
;
;(use-package monokai-theme
;             :ensure t
;             :disabled t
;             :init (load-theme 'monokai 'no-confirm))
;(load-theme 'wombat t)

(provide 'init-pkgs)
