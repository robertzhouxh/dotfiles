;;; init-kbd.el --- 键位配置 -*- lexical-binding: t; -*-

;; 卸载不需要的默认快捷键
(let ((keys '("C-q" "C-6" "C-z"
              "C-<wheel-down>" "C-<wheel-up>"
              "C-M-<wheel-down>" "C-M-<wheel-up>"
              "s-T" "s-W" "s-z"
              "M-h" "M-." "M-," "M-]"
              "s-c" "s-x" "s-v" "s-k" "s-w"
              "s-," "s-." "s--" "s-+"
              "<mouse-2>")))
  (dolist (key keys)
    (global-unset-key (kbd key))))

(use-package general
  :after evil
  :config
  ;; ============================================================
  ;; Evil normal/visual/motion 状态绑定
  (general-define-key
   :states '(normal visual motion)
   :keymaps 'override
   "/"   'swiper
   "?"   'swiper-backward

   ;; LSP
   "C-]"   'lsp-bridge-find-def
   "C-t"   'lsp-bridge-find-def-return
   "M-]"   'lsp-bridge-find-impl
   "M-."   'lsp-bridge-find-references
   "M-,"   'lsp-bridge-code-action
   "C-9"   'lsp-bridge-popup-documentation
   "C-0"   'lsp-bridge-rename
   "M-s-j" 'lsp-bridge-diagnostic-jump-next
   "M-s-k" 'lsp-bridge-diagnostic-jump-prev
   "M-s-l" 'lsp-bridge-diagnostic-ignore
   "M-s-n" 'lsp-bridge-popup-documentation-scroll-up
   "M-s-p" 'lsp-bridge-popup-documentation-scroll-down)

  ;; ============================================================
  ;; emacs/insert 状态绑定（Dired、term 等 emacs state 的 mode 需要）
  (general-define-key
   :states '(emacs insert)
   :keymaps 'override

   ;; LSP
   "C-]"   'lsp-bridge-find-def
   "C-t"   'lsp-bridge-find-def-return
   "C-9"   'lsp-bridge-popup-documentation
   "C-0"   'lsp-bridge-rename)
  ;; ============================================================
  ;; 全局跨状态绑定（包括 insert 等）
  (general-define-key
   :states '(normal visual insert emacs motion)
   :keymaps 'global

   "C-c p p" 'projectile-switch-project
   "C-c p f" 'projectile-find-file

   "M-j"   'sort-tab-select-prev-tab
   "M-k"   'sort-tab-select-next-tab
   "M-7"   'sort-tab-select-first-tab
   "M-8"   'sort-tab-select-last-tab
   "M-m"   'sort-tab-close-current-tab

   "s-q"   'sort-tab-close-mode-tabs
   "s-Q"   'sort-tab-close-all-tabs

   "M-n"   'hold-line-scroll-down
   "M-p"   'hold-line-scroll-up)

  ;; ============================================================
  ;; SPC 作为 Evil Leader (仅在 normal/visual/motion 生效)
  (general-define-key
   :states '(normal visual motion)
   :prefix "SPC"
   :keymaps 'override

   "==" 'markdown-table-align

   ;; buffers
   "bb" 'switch-to-buffer
   "bd" 'kill-current-buffer
   "bo" 'switch-to-buffer-other-window
   "bn" '+copy-current-buffer-name
   "bv" 'revert-buffer
   "bz" 'bury-buffer
   "bZ" 'unbury-buffer
   "bK" 'kill-other-window-buffer
   "bx" (lambda () (interactive) (switch-to-buffer "*scratch*"))

   ;; code
   "cf" 'format-function-parameters
   "cc" 'comment-dwim
   "ca" 'align-regexp
   "cd" 'delete-trailing-whitespace
   "cl" 'toggle-truncate-lines
   "cm" 'delete-trailing-M
   "c:" 'eval-expression
   "cs" 'my-org-screenshot

   ;; dired
   "d" (lambda () (interactive) (dired (file-name-directory (or (buffer-file-name) default-directory))))

   ;; files
   "ff" 'find-file
   "fo" 'find-file-other-window
   "fO" 'find-file-other-frame
   "fd" '+delete-current-file
   "fn" '+copy-current-filename
   "fr" '+rename-current-file
   "fe" (lambda () (interactive) (find-file (expand-file-name "init.el" user-emacs-directory)))
   "fi" (lambda () (interactive) (load-file (expand-file-name "init.el" user-emacs-directory)))
   "fF" 'my/all-available-fonts

   ;; version control
   "gs" 'magit-status
   "gL" 'magit-log-buffer-file
   "gp" 'magit-blob-previous
   "gn" 'magit-blob-next
   "gv" 'vc-dir
   "gl" 'vc-print-root-log
   "ga" 'vc-register
   "gc" 'vc-next-action
   "gF" 'vc-pull
   "gP" 'vc-push

   ;; help
   "hk" 'describe-key
   "hf" 'describe-function
   "hv" 'describe-variable
   "hm" 'describe-mode
   "hp" 'describe-package
   "h?" 'which-key-show-major-mode

   ;; insert
   "ic" 'insert-changelog-date
   "id" 'insert-standard-date

   ;; jump (avy)
   "jj" 'avy-goto-word-1
   "jl" 'avy-goto-line

   ;; quit
   "qr" 'restart-emacs

   ;; remote dired
   "r" #'my/rpc-dired

   ;; open
   "oo" (lambda () (interactive) (browse-url default-directory))
   "of" (lambda () (interactive)
          (when buffer-file-name (browse-url buffer-file-name)))

   ;; project
   "pp" 'projectile-switch-project
   "pa" 'projectile-add-known-project
   "pr" 'projectile-remove-known-project
   "pf" 'projectile-find-file
   "pg" 'projectile-grep
   "pd" 'projectile-dired

   ;; search
   "ss" 'swiper-isearch
   "sg" 'color-rg-search-input
   "sG" 'rgrep

   ;; toggle
   "tn" 'display-line-numbers-mode

   ;; window
   "wo" 'delete-other-windows
   "ws" 'split-window-below
   "wv" 'split-window-right
   "wd" 'delete-window
   "ww" 'other-window
   "wc" (lambda () (interactive) (delete-window) (delete-other-windows)))

  ;; macOS 修饰键：Cmd = Meta
  (when my-sys-mac-p
    (setq mac-command-modifier 'meta
          mac-option-modifier  'super
          ns-function-modifier 'hyper)))

(use-package which-key
  :diminish
  :hook (after-init . which-key-mode)
  :config
  (which-key-setup-side-window-right))

(provide 'init-keys)
;;; init-kbd.el ends here
