;;; init-evil.el -- My evil mode configuration.
;;; Commentary:
;;; Code:
(defun air--config-evil-leader ()
  "Configure evil leader mode."
  (evil-leader/set-leader ",")
  (evil-leader/set-key
    "."  'avy-goto-char-2
    ","  'other-window
    ":"  'eval-expression
    "aa" 'align-regexp
    "a=" 'my-align-single-equals
    "b"   'projectile-switch-to-buffer
    "B"  'magit-blame-toggle
    "c"  'comment-dwim
    "d"  'kill-this-buffer
    "D"  'delete-window
    "E"  'sudo-edit-current-file
    "g"  'magit-status
    "hb" 'fontify-and-browse    ;; HTML-ize the buffer and browse the result
    "hs" 'helm-projectile-ag
    "hp" 'helm-projectile
    "hd" 'helm-dash-at-point
    "hf" 'helm-find-files'
    "hm" 'helm-mini'
    "j"  'json-reformat-region'
    "k"  'get-erl-man'
    "l"  'whitespace-mode       ;; Show invisible characters
    "L"  (lambda () (interactive) (get-lua-man))
    "m"  'eshell-here
    "M"  'eshell-x
    "nn" 'air-narrow-dwim       ;; Narrow to region and enter normal mode
    "nw" 'widen
    "o"  'delete-other-windows  ;; C-w o
    "O"  'other-frame
    "p"  'helm-show-kill-ring
    "P"  'projectile-find-file-other-window
    "s"  'ag-project            ;; Ag search from project's root
    ;"rs" 'cider-start-http-server
    ;"rs" 'cider-jack-in
    ;"rr" 'cider-refresh
    ;"re" 'cider-macroexpand-1
    ;"ru" 'cider-user-ns
    ;"rn" 'cider-repl-set-ns
    ;"rx" 'cider-eval-last-sexp
    ;"R"  (lambda () (interactive) (font-lock-fontify-buffer) (redraw-display))
    "S"  'delete-trailing-whitespace
    "t"  'gtags-reindex
    "T"  'gtags-find-tag
    "w"  'save-buffer
    "x"  'helm-M-x
    "y"  'yank-to-x-clipboard
    ))

(use-package evil
  :ensure t
  :init
  ;; TODO: robertzhouxh !!!  (setq evil-want-C-u-scroll t) needs to happen before evil is loaded.
  (setq evil-want-C-u-scroll t)
  (evil-define-key 'normal global-map (kbd "C-]")     'gtags-find-tag-from-here)
  (evil-define-key 'normal global-map (kbd "C-t")     'gtags-pop-stack)
  (evil-add-hjkl-bindings occur-mode-map 'emacs
                          (kbd "/")       'evil-search-forward
                          (kbd "n")       'evil-search-next
                          (kbd "N")       'evil-search-previous
                          (kbd "C-d")     'evil-scroll-down
                          (kbd "C-u")     'evil-scroll-up
                          (kbd "C-w C-w") 'other-window)
  :commands (evil-mode evil-define-key)
  ;; While I'm still getting used to Evil, I'll eschew certain
  ;; advanced features, and fall-back on my Emacs.  Setting to `nil'
  ;; falls back to Emacs defaults.
  :bind
  (:map evil-normal-state-map
        ("C-a" . nil)
        ("C-e" . nil)
        ("C-d" . nil)
        ("C-k" . nil)
        ("C-n" . nil)
        ("C-p" . nil)
        ("C-t" . nil)
        ("C-]" . nil)
        ("M-." . nil)
        ("M-," . nil))
  :config
  (progn
    (define-key evil-motion-state-map "/" 'swiper)
    (setq evil-disable-insert-state-bindings t)
    (evil-mode 1)
    ;; Let's not bother with Evil in *every* mode...
    (dolist (mode '(ag-mode
		    flycheck-error-list-mode
		    git-rebase-mode))
      (add-to-list 'evil-emacs-state-modes mode))
    ;; Start in insert mode for small buffers
    (dolist (mode '(text-mode))
      (add-to-list 'evil-insert-state-modes mode)))
  (use-package evil-leader
    :ensure t
    :config
    (global-evil-leader-mode)
    (air--config-evil-leader))

  (use-package evil-surround
    :ensure t
    :init
    (progn
      (global-evil-surround-mode 1)
      ;; `s' for surround instead of `substitute'
      (evil-define-key 'visual evil-surround-mode-map "s" 'evil-surround-region)
      (evil-define-key 'visual evil-surround-mode-map "S" 'evil-substitute)))
  (air--apply-evil-other-package-configs))

(provide 'init-evil)
