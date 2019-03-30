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
    ;"b"  'helm-mini             ;; Switch to another buffer
    "b"   'projectile-switch-to-buffer
    "B"  'magit-blame-toggle
    "c"  'comment-dwim
    "d"  'kill-this-buffer
    "D"  'delete-window
    ;"D"  'open-current-line-in-codebase-search
    ;"e"  (lambda () (interactive) (get-erl-man))
    "e"  'eval-buffer
    "E"  'sudo-edit-current-file
    "f"  'helm-imenu            ;; Jump to function in buffer
    "g"  'magit-status
    "hb" 'fontify-and-browse    ;; HTML-ize the buffer and browse the result
    "hs" 'helm-projectile-ag
    "hp" 'helm-projectile
    "hd" 'helm-dash-at-point
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
    )

  (defun magit-blame-toggle ()
    "Toggle magit-blame-mode on and off interactively."
    (interactive)
    (if (and (boundp 'magit-blame-mode) magit-blame-mode)
      (magit-blame-quit)
      (call-interactively 'magit-blame))))

(defun air--config-evil ()
  "Configure evil mode."

  ;; Use Emacs state in these additional modes.
  (dolist (mode '(ag-mode
                   flycheck-error-list-mode
                   git-rebase-mode
                   octopress-mode
                   octopress-server-mode
                   octopress-process-mode
                   sunshine-mode
                   term-mode))
    (add-to-list 'evil-emacs-state-modes mode))

  (delete 'term-mode evil-insert-state-modes)

  ;; Use insert state in these additional modes.
  (dolist (mode '(twittering-edit-mode
                   magit-log-edit-mode))
    (add-to-list 'evil-insert-state-modes mode))

  (add-to-list 'evil-buffer-regexps '("\\*Flycheck"))

  (evil-add-hjkl-bindings occur-mode-map 'emacs
                          (kbd "/")       'evil-search-forward
                          (kbd "n")       'evil-search-next
                          (kbd "N")       'evil-search-previous
                          (kbd "C-d")     'evil-scroll-down
                          (kbd "C-u")     'evil-scroll-up
                          (kbd "C-w C-w") 'other-window)

  (when evil-want-C-u-scroll
    (define-key evil-motion-state-map (kbd "C-u") 'evil-scroll-up))

  ;; Global bindings.
  (define-key evil-normal-state-map (kbd "<down>")  'evil-next-visual-line)
  (define-key evil-normal-state-map (kbd "<up>")    'evil-previous-visual-line)
  (define-key evil-normal-state-map (kbd "C-]")     'gtags-find-tag-from-here)
  (define-key evil-normal-state-map (kbd "C-t")     'gtags-pop-stack)

  (define-key evil-normal-state-map (kbd "g/")      'occur-last-search)
  (define-key evil-normal-state-map (kbd "[i")      'show-first-occurrence)
  (define-key evil-normal-state-map (kbd "S-SPC")   'air-pop-to-org-agenda-default)
  (define-key evil-insert-state-map (kbd "C-e")     'end-of-line) ;; I know...

  (define-key evil-normal-state-map (kbd "C-q") 'delete-window)
  (define-key evil-normal-state-map (kbd "C-=") 'evil-window-increase-width)
  (define-key evil-normal-state-map (kbd "C-+") 'evil-window-decrease-width)
  (define-key evil-normal-state-map (kbd "C--") 'evil-window-increase-height)
  (define-key evil-normal-state-map (kbd "C-_") 'evil-window-decrease-height)

  (define-key evil-normal-state-map (kbd "-")   'helm-find-files)
  (define-key evil-normal-state-map (kbd "_")  'split-window-vertically)
  (define-key evil-normal-state-map  (kbd "|")  'split-window-horizontally)

  ;(evil-define-key 'normal global-map (kbd "C-p")   'helm-projectile)
  (evil-define-key 'normal global-map (kbd "C-S-p") 'helm-projectile-switch-project)
  (evil-define-key 'insert global-map (kbd "s-d")   'eval-last-sexp)
  (evil-define-key 'normal global-map (kbd "s-d")   'eval-defun)

  (evil-define-key 'normal global-map "gl" 'air-transpose-word-forward)
  (evil-define-key 'normal global-map "gh" 'air-transpose-word-backward)
  (evil-define-key 'normal global-map (kbd "z d")   'dictionary-lookup-definition)

  (defun minibuffer-keyboard-quit ()
    "Abort recursive edit.
    In Delete Selection mode, if the mark is active, just deactivate it;
    then it takes a second \\[keyboard-quit] to abort the minibuffer."
    (interactive)
    (if (and delete-selection-mode transient-mark-mode mark-active)
      (setq deactivate-mark  t)
      (when (get-buffer "*Completions*") (delete-windows-on "*Completions*"))
      (abort-recursive-edit)))

    ;; Make escape quit everything, whenever possible.
    (define-key evil-normal-state-map [escape] 'keyboard-quit)
    (define-key evil-visual-state-map [escape] 'keyboard-quit)
    (define-key minibuffer-local-map [escape] 'minibuffer-keyboard-quit)
    (define-key minibuffer-local-ns-map [escape] 'minibuffer-keyboard-quit)
    (define-key minibuffer-local-completion-map [escape] 'minibuffer-keyboard-quit)
    (define-key minibuffer-local-must-match-map [escape] 'minibuffer-keyboard-quit)
    (define-key minibuffer-local-isearch-map [escape] 'minibuffer-keyboard-quit)

    ;; My own Ex commands.
    (evil-ex-define-cmd "om" 'octopress-status))

(defun air--apply-evil-other-package-configs ()
  "Apply evil-dependent settings specific to other packages."

  (defun next-conflict-marker ()
    (interactive)
    (evil-next-visual-line)
    (if (not (search-forward-regexp "\\(>>>>\\|====\\|<<<<\\)" (point-max) t))
      (evil-previous-visual-line))
    (move-beginning-of-line nil))

  (defun previous-conflict-marker ()
    (interactive)
    (search-backward-regexp "\\(>>>>\\|====\\|<<<<\\)" (point-min) t)
    (move-beginning-of-line nil))

  ;; PHP
  (evil-define-key 'normal php-mode-map (kbd "]n") 'next-conflict-marker)
  (evil-define-key 'normal php-mode-map (kbd "[n") 'previous-conflict-marker)
  (evil-define-key 'visual php-mode-map (kbd "]n") 'next-conflict-marker)
  (evil-define-key 'visual php-mode-map (kbd "[n") 'previous-conflict-marker)

  ;; Dired
  (evil-define-key 'normal dired-mode-map (kbd "C-e") 'dired-toggle-read-only))

(defmacro define-evil-or-global-key (key def &optional state)
  "Define a key KEY with DEF in an Evil map, or in the global map.
  If the Evil map for STATE is defined (or `normal' if STATE is not
                                           provided) the key will be defined in that map.  Failing that, it will
  be defined globally.
  Note that STATE should be provided as an unquoted symbol.
  This macro provides a way to override Evil mappings in the appropriate
  Evil map in a manner that is compatible with environments where Evil
  is not used."
  (let* ((evil-map-name (if state
                          (concat "evil-" (symbol-name state) "-state-map")
                          "evil-normal-state-map"))
         (map (if (boundp (intern evil-map-name))
                (intern evil-map-name)
                global-map)))
    `(define-key ,map ,key ,def)))

(use-package evil
             :ensure t
             :init
             (setq evil-want-C-u-scroll t)
             :commands (evil-mode evil-define-key)
             :config
             (add-hook 'evil-mode-hook 'air--config-evil)
             (evil-mode 1)

             (use-package evil-leader
                          :ensure t
                          :config
                          (global-evil-leader-mode)
                          (air--config-evil-leader))

             (use-package evil-surround
                          :ensure t
                          :config
                          (global-evil-surround-mode))

             (use-package evil-indent-textobject
                          :ensure t)

             (air--apply-evil-other-package-configs))

(provide 'init-evil)
;;; init-evil.el ends here
