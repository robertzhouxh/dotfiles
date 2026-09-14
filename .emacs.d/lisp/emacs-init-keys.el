;;; emacs-init-keys.el --- 键位配置 -*- lexical-binding: t; -*-

;; M-n / M-p 的滚动命令（原本定义在 config.org，重构时漏迁，需与下方绑定同文件存在）
(defun hold-line-scroll-up ()
  "Scroll the page with the cursor in the same line"
  (interactive)
  ;; move the cursor also
  (let ((tmp (current-column)))
    (scroll-up 1)
    (line-move-to-column tmp)
    (forward-line 1)))

(defun hold-line-scroll-down ()
  "Scroll the page with the cursor in the same line"
  (interactive)
  ;; move the cursor also
  (let ((tmp (current-column)))
    (scroll-down 1)
    (line-move-to-column tmp)
    (forward-line -1)))

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
   "C-0"   'lsp-bridge-rename

   ;; word 移动（自定义边界，不覆盖 Evil normal/visual 的 w/b/e）
   "M-f"           'my-forward-word
   "M-b"           'my-backward-word
   "C-<right>"     'my-forward-word
   "C-<left>"      'my-backward-word
   "C-<delete>"    'my-delete-word-forward
   "C-<backspace>" 'my-delete-word-backward)
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

   "s-g"   'vc-dir

   "M-n"   'hold-line-scroll-down
   "M-p"   'hold-line-scroll-up
   "M-RET" 'skye/gptel-dwim

   ;; 括号跳转（定义见 emacs-solo-brackets.el）
   ;; 与 C-9（lsp-bridge popup）/ C-0（rename）连成一片。
   ;; C-7/C-8 与 C-w/C-x 是不同的事件（(kbd "C-7") => [67108919]），
   ;; 不会遮蔽 kill-region / C-x 前缀。
   ;; 但 tty（emacs -nw）下 C-7/C-8 无法与 C-w/C-x 区分：终端发的是同一个
   ;; 字节 0x17/0x18，Emacs 读成 C-w/C-x，local-function-key-map 里也没有
   ;; 0x17->C-7 的转换。所以这两个键只在 GUI 生效；终端里用 M-x 调用。
   "C-7"   'xah-backward-left-bracket
   "C-8"   'xah-forward-right-bracket)

  (with-eval-after-load 'agent-shell
    (define-key agent-shell-mode-map (kbd "C-<tab>") nil))

  ;; ============================================================
  ;; SPC 作为 Evil Leader (仅在 normal/visual/motion 生效)
  (general-define-key
   :states '(normal visual motion)
   :prefix "SPC"
   :keymaps 'override

   ;"==" 'markdown-table-align
   "==" 'my/align-all-markdown-tables

   ;; AI
   "aa" 'agent-shell-anthropic-start-claude-code
   "a1" 'agent-shell-anthropic-start-claude-code
   "ag" 'skye/toggle-gptel-explain-drawer
   "ar" 'skye/toggle-gptel-rewrite-drawer
   "as" 'gptel-send
   "ad" 'skye/destroy-gptel-drawer

   ;; buffers
   "bb" 'switch-to-buffer
   "bg" 'emacs-solo/switch-git-status-buffer
   "bd" 'kill-current-buffer
   "bk" 'kill-current-buffer
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
   "l" (lambda () (interactive) (dired (file-name-directory (or (buffer-file-name) default-directory))))

   ;; files
   "fa" #'find-file-at-point
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
   "wr" 'window-layout-rotate-clockwise
   "wc" (lambda () (interactive) (delete-window) (delete-other-windows)))

  ;; macOS 修饰键：Cmd = Meta
  (when my-sys-mac-p
    (setq mac-command-modifier 'meta
          mac-option-modifier  'super
          ns-function-modifier 'hyper)))

(provide 'emacs-init-keys)
;;; init-keys.el ends here
