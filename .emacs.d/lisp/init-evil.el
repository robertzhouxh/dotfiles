;;; init-evil.el -- My evil mode configuration.
;;; Commentary:
;;; Code:

;; customize my keybinds
(defun x/config-evil-leader ()
  "Configure evil leader mode."
  (evil-leader/set-leader ",")
  (evil-leader/set-key
    "#"  'server-edit
    ","  'other-window
    "."  'mode-line-other-buffer
    ":"  'eval-expression

    "a"  'align-regexp

    "bb" 'ivy-switch-buffer
    "br" 'counsel-recentf
    "dv" 'counsel-describe-variable
    "df" 'counsel-describe-function
    "/"  'counsel-rg

    "c"  'comment-dwim

    "d"  'kill-this-buffer
    "D"  'kill-this-window

    "es" 'ivy-erlang-complete-find-spec
    "ef" 'ivy-erlang-complete-find-file
    "eh" 'ivy-erlang-complete-show-doc-at-point
    "ep" 'ivy-erlang-complete-set-project-root
    "ea" 'ivy-erlang-complete-autosetup-project-root
    "ek" 'get-erl-man

    "Es" 'x/eshell-here
    "Ex" 'x/eshell-x

    "f"  'other-frame
    "F"  'other-window

    "g"  'magit-status
    "G"  'magit-dispatch-popup

    "o"  'delete-other-windows
    "O"  'delete-other-buffers

    "p/" 'counsel-projectile-rg
    "pf" 'counsel-projectile-find-file
    "pp" 'counsel-projectile-switch-project
    "pb" 'counsel-projectile-switch-to-buffer

    "r"  'x/open-init-file
    "R" 'x/reload-init-file

    "s" 'x/save-all
    "S" 'delete-trailing-whitespace

    "w" 'whitespace-mode
    ))

(use-package evil
             :init
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
                            :config
                            (global-evil-leader-mode)
                            (x/config-evil-leader))
               (use-package evil-visualstar
                            :bind (:map evil-visual-state-map
                                        ("*" . evil-visualstar/begin-search-forward)
                                        ("#" . evil-visualstar/begin-search-backward)))
               ))

(provide 'init-evil)
