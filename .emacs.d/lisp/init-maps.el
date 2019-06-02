;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;; Plugin Keybinding Mapping
;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
(use-package key-chord
             :ensure t
             :config
             (progn
               (key-chord-define-global "jb" 'ibuffer)
               (key-chord-define-global "j0" 'delete-window)
               (key-chord-define-global "j1" 'delete-other-windows)
               (key-chord-define-global "jz" 'magit-dispatch-popup)
               (key-chord-define-global "kb" 'gh/kill-current-buffer)
               (key-chord-mode 1)))

(use-package hydra :ensure t)
;; 如果用过 magit , 对 magit-status 下按 c 等出现的可选菜单应该有印象, hydra 正是把这个能力扩展了. hydra 也在快速进化变强,
(global-set-key
  (kbd "C-M-w")
  (defhydra hydra-window ()
            "window"
            ("h" windmove-left)
            ("j" windmove-down)
            ("k" windmove-up)
            ("l" windmove-right)
            ("v" (lambda ()
                   (interactive)
                   (split-window-right)
                   (windmove-right))
             "vert")
            ("x" (lambda ()
                   (interactive)
                   (split-window-below)
                   (windmove-down))
             "horz")
            ("o" delete-other-windows "1" :color blue)
            ("i" ace-maximize-window "a1" :color blue)
            ("q" nil "cancel")))

(global-set-key
  (kbd "C-M-o")
  (defhydra hydra-vi
            (:pre
              (set-cursor-color "#e52b50")
              :post
              (set-cursor-color "#ffffff")
              :color amaranth)
            "vi"
            ("l" forward-char)
            ("h" backward-char)
            ("j" next-line)
            ("k" previous-line)
            ("m" set-mark-command "mark")
            ("a" move-beginning-of-line "beg")
            ("e" move-end-of-line "end")
            ("d" delete-region "del" :color blue)
            ("y" kill-ring-save "yank" :color blue)
            ("q" nil "quit")))



(global-set-key
  (kbd "C-M-i")
  (defhydra hydra-vi
            (:pre
              (set-cursor-color "#e52b50")
              :post
              (set-cursor-color "#ffffff")
              :color amaranth)
              "
              [_i_]ut       Jump to [_n_]ext        Search [_s_]iterally
              [_t_]oggle            [_p_]revious     ...or [_q_]uery Replace
              [_e_]cho              [_d_]efinition   ...or [_r_]ename
              [_s_]ave
              "
              ("i" symbol-overlay-put)
              ("n" symbol-overlay-jump-next)
              ("p" symbol-overlay-jump-prev)
              ("w" symbol-overlay-save-symbol)
              ("t" symbol-overlay-toggle-in-scope)
              ("e" symbol-overlay-echo-mark)
              ("d" symbol-overlay-jump-to-definition)
              ("s" symbol-overlay-isearch-literally)
              ("q" symbol-overlay-query-replace)
              ("r" symbol-overlay-rename)
              ("q" nil "quit")))

;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;; 覆盖全局 mapping
;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
(global-set-key (kbd "C-]") 'gtags-find-tag-from-here)
(global-set-key (kbd "C-t") 'gtags-pop-stack)
(global-set-key (kbd "M-]") 'dumb-jump-go)
(global-set-key (kbd "M-t") 'dumb-jump-back)
(global-set-key (kbd "M-p") 'hold-line-scroll-up )
(global-set-key (kbd "M-n") 'hold-line-scroll-down )
(global-set-key (kbd "M-@") 'pkg-mark-word)
(global-set-key (kbd "M-y") 'async-shell-command)
(global-set-key (kbd "C-x 2") 'vsplit-last-buffer)
(global-set-key (kbd "C-x 3") 'hsplit-last-buffer)
(global-set-key [M-left]  'shrink-window-horizontally)
(global-set-key [M-right] 'enlarge-window-horizontally)
(global-set-key [M-up]    'shrink-window)
(global-set-key [M-down]  'enlarge-window)

;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;; 覆盖全局 mapping
;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
(eval-after-load "evil-maps"
                 (dolist (map '(evil-normal-state-map
                                evil-motion-state-map
                                evil-insert-state-map
                                evil-emacs-state-map))
                   (define-key (eval map) "\M-." nil)
                   (define-key (eval map) "\M-," nil)
                   (define-key (eval map) "\C-t" nil)
                   (define-key (eval map) "\C-]" nil)))

(eval-after-load "erlang"
  '(progn
     (define-key erlang-mode-map (kbd "C-c b") 'erlang-insert-binary)
     (define-key erlang-mode-map (kbd "M-.") 'ivy-erlang-complete-find-definition)
     (define-key erlang-mode-map (kbd "M-,") 'xref-pop-marker-stack)
     (define-key erlang-mode-map (kbd "M-?") 'ivy-erlang-complete-find-references)
     ))

;; stolen from: https://github.com/bbatsov/prelude/blob/master/modules/prelude-go.el

(with-eval-after-load 'go-mode
  (defun prelude-go-mode-defaults ()
    ;; Add to default go-mode key bindings
    (let ((map go-mode-map))
      (define-key map (kbd "M-.") 'godef-jump)
      (define-key map (kbd "M-,") 'pop-tag-mark)
      (define-key map (kbd "C-h f") 'godoc-at-point))

    ;; Prefer goimports to gofmt if installed
    (let ((goimports (executable-find "goimports")))
      (when goimports
        (setq gofmt-command goimports)))

    ;; gofmt on save
    (add-hook 'before-save-hook 'gofmt-before-save nil t)

    ;; stop whitespace being highlighted
    ;;(whitespace-toggle-options '(tabs))

    ;; Company mode settings
    (set (make-local-variable 'company-backends) '(company-go))

    ;; CamelCase aware editing operations
    (subword-mode +1))

  (setq prelude-go-mode-hook 'prelude-go-mode-defaults)
  (add-hook 'go-mode-hook (lambda ()
			    (run-hooks 'prelude-go-mode-hook))))

  (provide 'init-maps)
  ;;; init-maps.el ends here
