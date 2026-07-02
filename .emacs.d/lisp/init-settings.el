;;; init-editor.el --- 编辑行为配置 -*- lexical-binding: t; -*-

(require 'init-path)

;; ---- 编码 ----
(when (not (eq system-type 'windows-nt))
  (set-selection-coding-system 'utf-8)
  (prefer-coding-system 'utf-8)
  (set-language-environment "UTF-8")
  (set-default-coding-systems 'utf-8)
  (set-terminal-coding-system 'utf-8)
  (set-keyboard-coding-system 'utf-8)
  (setq locale-coding-system 'utf-8))

(when my-graphic-p
  (setq x-select-request-type '(UTF8_STRING COMPOUND_TEXT TEXT STRING)))

;; ---- UI 精简 ----
(use-package emacs
  :init
  (when my-graphic-p
    (when (fboundp 'tool-bar-mode) (tool-bar-mode -1))
    (when (fboundp 'menu-bar-mode) (menu-bar-mode -1))
    (when (fboundp 'scroll-bar-mode) (scroll-bar-mode -1))
    (when (fboundp 'tooltip-mode) (tooltip-mode -1))))

;; ---- 编辑行为 ----
(setq create-lockfiles nil
      make-backup-files nil
      backup-inhibited t
      read-answer-short t            ; y/n 替代 yes/no
      echo-keystrokes 0.1
      kill-ring-max 1024
      mark-ring-max 1024
      enable-recursive-minibuffers t
      history-delete-duplicates t
      confirm-kill-emacs 'y-or-n-p
      confirm-kill-processes nil
      ring-bell-function 'ignore
      mouse-yank-at-point t
      x-select-enable-clipboard t
      inhibit-startup-message t
      initial-scratch-message (concat "浩哥，enjoy coding *^____^* emacs startup in " (emacs-init-time)))

;; Treesitter
(setq treesit-font-lock-level 4
      treesit-auto-install-grammar 'always  ; EMACS-31
      treesit-enabled-modes t)              ; EMACS-31

(setq-default cursor-type 'bar
              comment-style 'indent
              require-final-newline nil
              history-length 500
              indent-tabs-mode nil
              tab-always-indent t
              tab-width 2
              frame-title-format '(" %f" (:eval (if (buffer-modified-p) " ✍️"))))

;; 滚动
(setq scroll-step 1
      scroll-margin 3
      scroll-conservatively 101
      mouse-wheel-scroll-amount '(1 ((shift) . 1))
      mouse-wheel-progressive-speed nil
      hscroll-step 1
      hscroll-margin 1)

;; 大文件优化
(when (fboundp 'global-so-long-mode) (global-so-long-mode))
(setq-default bidi-display-reordering nil
              bidi-paragraph-direction 'left-to-right)
(setq bidi-inhibit-bpa t)

;; 行号
(setq display-line-numbers-grow-only t)
(dolist (hook '(prog-mode-hook text-mode-hook conf-mode-hook))
  (add-hook hook #'display-line-numbers-mode))

;; 括号匹配
(show-paren-mode 1)

;; 自动刷新
(setq-default auto-revert-mode 1)

;; 补全风格
(setq completion-styles '(basic substring))

;; 使用空格缩进
(defun my/use-spaces-setup ()
  (setq indent-tabs-mode nil)
  (setq tab-width 4))
(add-hook 'prog-mode-hook 'my/use-spaces-setup)

;; ---- 实用函数 ----
(defun my/all-available-fonts ()
  "列出所有可用字体。"
  (interactive)
  (let ((font-list (sort (x-list-fonts "*") #'string<))
        (font-buffer (generate-new-buffer "*Font List*")))
    (with-current-buffer font-buffer
      (dolist (font font-list)
        (let* ((font-family (nth 2 (split-string font "-"))))
          (insert (format "%s\n" (propertize font 'face `(:family ,font-family :height 140))))))
      (goto-char (point-min))
      (setq buffer-read-only t))
    (pop-to-buffer font-buffer)))

(defun format-function-parameters ()
  "将函数参数列表格式化为多行。"
  (interactive)
  (beginning-of-line)
  (search-forward "(" (line-end-position))
  (newline-and-indent)
  (while (search-forward "," (line-end-position) t)
    (newline-and-indent))
  (end-of-line)
  (c-hungry-delete-forward)
  (insert " ")
  (search-backward ")")
  (newline-and-indent))

(defun delete-trailing-M ()
  "删除 buffer 中的 ^M 字符。"
  (interactive)
  (save-excursion
    (goto-char 0)
    (while (search-forward "\r" nil :noerror)
      (replace-match ""))))

(defun save-buffer-as-utf8 (coding-system)
  "以 CODING-SYSTEM 解码后重新以 UTF-8 保存。"
  (interactive "zCoding system for visited file (default nil):")
  (revert-buffer-with-coding-system coding-system)
  (set-buffer-file-coding-system 'utf-8)
  (save-buffer))

(defun save-buffer-gbk-as-utf8 ()
  "以 GBK 解码并以 UTF-8 保存。"
  (interactive)
  (save-buffer-as-utf8 'gbk))

(defun +rename-current-file (newname)
  "重命名当前文件为 NEWNAME。"
  (interactive
   (progn
     (unless buffer-file-name
       (user-error "No file is visiting"))
     (let ((name (read-file-name "Rename to: " nil buffer-file-name 'confirm)))
       (when (equal (file-truename name) (file-truename buffer-file-name))
         (user-error "Can't rename file to itself"))
       (list name))))
  (when (equal newname (file-name-as-directory newname))
    (setq newname (concat newname (file-name-nondirectory buffer-file-name))))
  (rename-file buffer-file-name newname)
  (set-visited-file-name newname)
  (rename-buffer newname))

(defun +delete-current-file (file)
  "删除当前文件 FILE。"
  (interactive
   (list (or buffer-file-name (user-error "No file is visiting"))))
  (when (y-or-n-p (format "Really delete '%s'? " file))
    (kill-this-buffer)
    (delete-file file)))

(defun +copy-current-filename (file)
  "复制当前文件 FILE 的完整路径到剪贴板。"
  (interactive
   (list (or buffer-file-name (user-error "No file is visiting"))))
  (kill-new file)
  (message "Copying '%s' to clipboard" file))

(defun +copy-current-buffer-name ()
  "复制当前 buffer 名到剪贴板。"
  (interactive)
  (kill-new (buffer-name))
  (message "Copying '%s' to clipboard" (buffer-name)))

(defun my/rpc-dired ()
  "使用 rpc: 方法打开远程目录。"
  (interactive)
  (let ((default-directory "/rpc:"))
    (call-interactively 'dired)))

;; ---- 插件 ----

(use-package ws-butler
  :diminish
  :hook (prog-mode . ws-butler-mode)
  :init
  (setq ws-butler-keep-whitespace-before-point t))

(use-package avy
  :bind (("C-c j" . avy-goto-char)
         ("C-c l" . avy-goto-line)))

(use-package vundo
  :commands (vundo)
  :bind (("C-x u" . vundo))
  :config
  (setq vundo-compact-display t)
  (define-key vundo-mode-map (kbd "l") #'vundo-forward)
  (define-key vundo-mode-map (kbd "h") #'vundo-backward)
  (define-key vundo-mode-map (kbd "j") #'vundo-next)
  (define-key vundo-mode-map (kbd "k") #'vundo-previous)
  (define-key vundo-mode-map (kbd "a") #'vundo-stem-root)
  (define-key vundo-mode-map (kbd "e") #'vundo-stem-end)
  (define-key vundo-mode-map (kbd "q") #'vundo-quit)
  (define-key vundo-mode-map (kbd "C-g") #'vundo-quit)
  (define-key vundo-mode-map (kbd "RET") #'vundo-confirm))

(use-package comment-dwim-2
  :commands (comment-dwim-2))

(use-package ediff
  :commands (ediff ediff-buffers ediff-files ediff-regions-wordwise ediff-directories)
  :config
  (setq ediff-keep-variants nil
        ediff-split-window-function 'split-window-horizontally
        ediff-window-setup-function #'ediff-setup-windows-plain))

(use-package discover-my-major)

(provide 'init-settings)
;;; init-editor.el ends here
