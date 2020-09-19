;;; init-evil.el -- My evil mode configuration.
;;; Commentary:
;;; Code:

;; customize my keybinds
(defun x/config-evil-leader ()
  "Configure evil leader mode."
  (evil-leader/set-leader ",")
  (evil-leader/set-key
    ","  'avy-goto-char-2
    ":"  'eval-expression

    ; C-y => paste the things to minibuffer, then use consel-rg
    "/"  'counsel-rg

    "a"  'align-regexp

    "bb" 'ivy-switch-buffer
    "br" 'counsel-recentf

    "c"  'comment-dwim

    "db" 'kill-this-buffer
    "dw" 'delete-window
    "do" 'delete-other-windows
    "dt" 'delete-trailing-whitespace
    "dv" 'counsel-describe-variable
    "df" 'counsel-describe-function

    "es" 'ivy-erlang-complete-find-spec
    "ef" 'ivy-erlang-complete-find-file
    "eh" 'ivy-erlang-complete-show-doc-at-point
    "ep" 'ivy-erlang-complete-set-project-root
    "ea" 'ivy-erlang-complete-autosetup-project-root
    "ek" 'get-erl-man
    "es" 'eshell-here
    "ec" 'eshell/clear
    "ed" 'eshell/close

    "ff" 'find-file-other-frame
    "fp" 'format-function-parameters

    "g"  'magit-status
    "G"  'magit-dispatch-popup

    "of" 'other-frame
    "ow" 'other-window

    "p/" 'counsel-projectile-rg
    "pf" 'counsel-projectile-find-file
    "pp" 'counsel-projectile-switch-project
    "pb" 'counsel-projectile-switch-to-buffer

    "rb" 'generate-scratch-buffer
    "ri" 'x/open-init-file
    "rv" 'rename-local-var
    "R"  'x/reload-init-file

    "sa" 'x/save-all
    "su" 'sudo

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
