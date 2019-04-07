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

(use-package swiper
  :ensure t
  :bind (("C-s" . swiper)))

;;jj. It makes evil mode being turned off much more palatable.
(use-package use-package-chords
             :ensure t
             :config
             (key-chord-mode 1))
(use-package google-this :ensure t)
(use-package logview :ensure t)
(use-package hydra :ensure t)
(use-package ace-window
             :functions hydra-frame-window/body
             :bind
             ("C-M-o" . hydra-frame-window/body)
             :custom
             (aw-keys '(?j ?k ?l ?i ?o ?h ?y ?u ?p))
             :custom-face
             (aw-leading-char-face ((t (:height 4.0 :foreground "#f1fa8c")))))
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

;; --------------------------------------------------------------------
;; jump to definations 
;; --------------------------------------------------------------------
;; scheme-1
;; (add-to-list 'helm-sources-using-default-as-input 'helm-source-man-pages)
;; global、gtags、gtags-cscope三个命令。global是查询，gtags是生成索引文件，gtags-cscope是与cscope一样的界面
;; 查询使用的命令是global和gtags-cscope。前者是命令行界面，后者是与cscope兼容的ncurses界面
;; helm-ggtags
;(if
;    (executable-find "global")
;    (progn
;      (use-package bpr :ensure t)
;      (use-package helm-gtags
;        :diminish helm-gtags-mode
;        :init
;        (add-hook 'dired-mode-hook 'helm-gtags-mode)
;        (add-hook 'eshell-mode-hook 'helm-gtags-mode)
;        (add-hook 'c-mode-hook 'helm-gtags-mode)
;        (add-hook 'c++-mode-hook 'helm-gtags-mode)
;        (add-hook 'asm-mode-hook 'helm-gtags-mode)
;        (add-hook 'go-mode-hook (lambda () (helm-gtags-mode)))
;        (add-hook 'python-mode-hook (lambda () (helm-gtags-mode)))
;        (add-hook 'ruby-mode-hook (lambda () (helm-gtags-mode)))
;        (add-hook 'lua-mode-hook (lambda () (helm-gtags-mode)))
;        (add-hook 'js-mode-hook (lambda () (helm-gtags-mode)))
;        (add-hook 'erlang-mode-hook (lambda () (helm-gtags-mode)))
;        :config
;        ;(custom-set-variables
;        ; '(helm-gtags-prefix-key "C-t")
;        ; '(helm-gtags-suggested-key-mapping t))
;        (setq
;         helm-gtags-ignore-case t
;         helm-gtags-auto-update t
;         helm-gtags-use-input-at-cursor t
;         helm-gtags-pulse-at-cursor t
;         helm-gtags-prefix-key "\C-cg"
;         helm-gtags-suggested-key-mapping t
;         )
;         (define-key helm-gtags-mode-map (kbd "C-]") 'helm-gtags-dwim)
;         (define-key helm-gtags-mode-map (kbd "C-t") 'helm-gtags-pop-stack)
;        ))
;  (message "%s: GNU GLOBAL not found in exec-path. helm-gtags will not be used." 'please check))

;; scheme-2
;; /usr/local/Cellar/global/6.5.5/share/gtags/gtags.el
;; gtags --gtagslabel=pygments --debug
;; (use-package gtags :ensure t)
(require 'gtags)
(use-package bpr :ensure t)

;; Bind some useful keys in the gtags select buffer that evil overrides.
(add-hook 'gtags-select-mode-hook
          (lambda ()
            (evil-define-key 'normal gtags-select-mode-map (kbd "RET") 'gtags-select-tag)
            (evil-define-key 'normal gtags-select-mode-map (kbd "q") 'kill-buffer-and-window)))


;;(autoload 'vc-git-root "vc-git")
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
             :bind (
                    ("C-M-o" . dumb-jump-go-other-window)
                    ("C-M-g" . dumb-jump-go)
                    ("C-M-p" . dumb-jump-back)
                    ("C-M-q" . dumb-jump-quick-look))
             :config
             (setq dumb-jump-selector 'helm)
             (setq dumb-jump-prefer-searcher 'ag))

;; ------------------------------
;; UI Schemes
;; ------------------------------
;;(use-package darktooth-theme
;;  :ensure t
;;  :config
;;  (load-theme 'darktooth t))

;(use-package kaolin-themes
;             :ensure t
;             :config
;             (load-theme 'kaolin-dark t)
;             (kaolin-treemacs-theme))

(use-package all-the-icons :ensure t)
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
               '(bar workspace-number window-number "  " matches buffer-info buffer-position selection-info)
               ;; Right mode line segments
               '(major-mode buffer-encoding vcs checker))
             (doom-modeline-set-modeline 'gs t)
             :hook (after-init . doom-modeline-init))

(load-theme 'doom-molokai t)

(provide 'init-pkgs)
