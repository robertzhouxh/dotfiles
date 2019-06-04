;;; init-evil.el -- My evil mode configuration.
;;; Commentary:
;;; Code:
(defun x/config-evil-leader ()
  "Configure evil leader mode."
  (evil-leader/set-leader ",")
  (evil-leader/set-key
    "#"  'server-edit
    ","  'other-window
    "."  'mode-line-other-buffer
    ":"  'eval-expression

    "a"  'align-regexp
    "c"  'comment-dwim
    "d"  'kill-this-buffer

    "es" 'ivy-erlang-complete-find-spec
    "ef" 'ivy-erlang-complete-find-file
    "eh" 'ivy-erlang-complete-show-doc-at-point
    "ep" 'ivy-erlang-complete-set-project-root
    "ea" 'ivy-erlang-complete-autosetup-project-root
    "ek" 'get-erl-man

    "Es" 'x/eshell-here
    "Ex" 'x/eshell-x

    "f"  'other-frame

    "g"  'magit-status
    "G"  'magit-dispatch-popup

    "hb" 'ido-switch-buffer
    "hf" 'helm-find-files
    "hs" 'helm-projectile-ag
    "hp" 'helm-projectile
    "hd" 'helm-dash-at-point
    "hm" 'helm-mini
    "hk" 'helm-show-kill-ring

    "oi" 'org-clock-in
    "oo" 'org-clock-out
    "oc" 'org-clock-cancel
    "os" 'org-schedule
    "od" 'org-deadline
    "or" 'org-clock-report

    "O"  'delete-other-windows
    "P"  'projectile-find-file-other-window
    ;"rs" 'cider-start-http-server
    ;"rs" 'cider-jack-in
    ;"rr" 'cider-refresh
    ;"re" 'cider-macroexpand-1
    ;"ru" 'cider-user-ns
    ;"rn" 'cider-repl-set-ns
    ;"rx" 'cider-eval-last-sexp
    "r"  'x/open-init-file
    "R" 'x/reload-init-file
    "s" 'x/save-all
    "S" 'delete-trailing-whitespace
    "t" 'gtags-reindex
    "x" 'helm-M-x
    "w" 'whitespace-mode          ;; Show invisible characters
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
                            (x/config-evil-leader))
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
               ))

(provide 'init-evil)
