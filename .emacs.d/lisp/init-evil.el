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
    "b"  'ido-switch-buffer
    "B"  'magit-blame-toggle
    "c"  'comment-dwim
    "d"  'kill-this-buffer
    "D"  'delete-window
    "E"  'sudo-edit-current-file
    "f"  'ido-find-file
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
    "m"  'eshell-here
    "M"  'eshell-x
    "nn" 'air-narrow-dwim       ;; Narrow to region and enter normal mode
    "nw" 'widen
    "o"  'delete-other-windows  ;; C-w o
    "O"  'other-frame
    "p"  'helm-show-kill-ring
    "P"  'projectile-find-file-other-window
    "s"  'ag-project            ;; Ag search from project's root
    "S"  'ag
    ;"rs" 'cider-start-http-server
    ;"rs" 'cider-jack-in
    ;"rr" 'cider-refresh
    ;"re" 'cider-macroexpand-1
    ;"ru" 'cider-user-ns
    ;"rn" 'cider-repl-set-ns
    ;"rx" 'cider-eval-last-sexp
    ;"R"  (lambda () (interactive) (font-lock-fontify-buffer) (redraw-display))
    "/"  'delete-trailing-whitespace
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
             (setq evil-search-module 'evil-search)
             (setq evil-shift-round nil)
             (setq evil-disable-insert-state-bindings t)
             :commands (evil-mode evil-define-key)
             :config
             (evil-mode 1)
             (progn
               (define-key evil-motion-state-map "/" 'swiper)
               (define-key evil-insert-state-map (kbd "j") 'bw-evil-escape-if-next-char-is-j)
               ;; esc should always quit: http://stackoverflow.com/a/10166400/61435
               (define-key evil-normal-state-map [escape] 'keyboard-quit)
               (define-key evil-visual-state-map [escape] 'keyboard-quit)
               (define-key minibuffer-local-map [escape] 'abort-recursive-edit)
               (define-key minibuffer-local-ns-map [escape] 'abort-recursive-edit)
               (define-key minibuffer-local-completion-map [escape] 'abort-recursive-edit)
               (define-key minibuffer-local-must-match-map [escape] 'abort-recursive-edit)
               (define-key minibuffer-local-isearch-map [escape] 'abort-recursive-edit)

               ;; modes to map to different default states
               (dolist (mode-map '((comint-mode . emacs)
                                   (term-mode . emacs)
                                   (eshell-mode . emacs)
                                   (help-mode . emacs)
                                   (fundamental-mode . emacs))))

               (use-package evil-leader
                            :ensure t
                            :config
                            (global-evil-leader-mode)
                            (air--config-evil-leader))
               (use-package evil-visualstar
                            :ensure t
                            :bind (:map evil-visual-state-map
                                        ("*" . evil-visualstar/begin-search-forward)
                                        ("#" . evil-visualstar/begin-search-backward)))
               (use-package evil-surround
                            :ensure t
                            :init
                            (progn
                              (global-evil-surround-mode 1)
                              ;; `s' for surround instead of `substitute'
                              (evil-define-key 'visual evil-surround-mode-map "s" 'evil-surround-region)
                              (evil-define-key 'visual evil-surround-mode-map "S" 'evil-substitute)))
               (air--apply-evil-other-package-configs)))

(provide 'init-evil)
