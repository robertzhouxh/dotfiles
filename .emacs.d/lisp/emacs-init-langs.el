;;; emacs-init-langs.el --- 编程语言配置 -*- lexical-binding: t; -*-

(require 'emacs-init-path)

;; ---- 通用 ----
(use-package yaml-mode :mode ("\\.ya?ml\\'" . yaml-mode))
(use-package json-mode :mode ("\\.json\\'" . json-mode))
(use-package protobuf-mode :mode ("\\.proto\\'" . protobuf-mode))
(use-package dockerfile-mode :commands dockerfile-mode)

(use-package auto-save
  :vc (:url "https://github.com/manateelazycat/auto-save" :rev :newest)
  :hook (after-init . auto-save-enable)
  :custom
  (auto-save-silent t)
  (auto-save-disable-predicates
   '((lambda () (string-prefix-p "*" (buffer-name)))
     (lambda () (string-match-p "\\.gpg$" (buffer-file-name))))))

;; ---- Tree-sitter ----
(use-package treesit-fold
  :vc (:url "https://github.com/emacs-tree-sitter/treesit-fold" :rev :newest)
  :hook (prog-mode . treesit-fold-mode))

(use-package treesit-auto
  :demand t
  :custom (treesit-font-lock-level 4)
  :config
  (setq treesit-auto-install 'prompt)
  (global-treesit-auto-mode))

(defun treesit-show-parser ()
  "显示当前位置的 tree-sitter 语法解析器。"
  (interactive)
  (if (treesit-available-p)
      (message "%s" (or (treesit-language-at (point)) "无解析器"))
    (message "Tree-sitter 不可用")))

(use-package kirigami
  :ensure t
  :init
  (kirigami-global-mode 1)
  :config
  (with-eval-after-load 'evil
    (evil-define-key 'normal 'global (kbd "<tab>") #'kirigami-toggle-fold)
    (evil-define-key 'normal 'global (kbd "<S-tab>") #'kirigami-close-folds)))

(setq major-mode-remap-alist
      '((c-mode . c-ts-mode)
        (c++-mode . c++-ts-mode)
        (python-mode . python-ts-mode)
        (js-mode . js-ts-mode)
        (typescript-mode . typescript-ts-mode)
        (rust-mode . rust-ts-mode)
        (java-mode . java-ts-mode)
        (go-mode . go-ts-mode)
        (sh-mode . bash-ts-mode)
        (css-mode . css-ts-mode)
        (json-mode . json-ts-mode)))

;;(use-package markdown-ts-mode
;;  :if (>= emacs-major-version 31)
;;  :ensure nil
;;  :mode ("\\.md\\'" "\\.mdx\\'" "\\.markdown\\'")
;;  :init (load-library "markdown-ts-mode"))
(use-package markdown-mode
  :mode ("\\.md\\'" . markdown-mode)
  :commands markdown-mode
  :config
  (defun my/align-all-markdown-tables ()
    "对齐当前 buffer 中的所有 Markdown 表格。"
    (interactive)
    (save-excursion
      (goto-char (point-min))
      ;; 搜索每个以 | 开头的行，并检查是否在表格内
      (while (re-search-forward "^|" nil t)
        (when (markdown-table-at-point-p)
          (markdown-table-align)          ; 对齐当前表格
          (goto-char (markdown-table-end)))))) ; 跳到该表格末尾
  :bind (:map markdown-mode-map
              ("C-c C-t" . my/align-all-markdown-tables))) ; 绑定到 C-c C-t

;; ---- 高亮关键字 ----
(use-package symbol-overlay
  :commands symbol-overlay-put
  :bind
  (("C-c i" . symbol-overlay-put)
   ("C-c q" . symbol-overlay-remove-all)))

;; ---- Go ----
(use-package go-mode
  :defer t
  :hook ((go-mode . (lambda () (setq tab-width 4)))
         (before-save . gofmt-before-save))
  :config
  (defun go-run-buffer ()
    "运行当前 Go 文件。"
    (interactive)
    (let ((file (buffer-file-name)))
      (if file
          (progn
            (save-buffer)
            (compile (concat "go run " file)))
        (message "当前 buffer 没有关联的文件，无法运行")))))

;; ---- Rust ----
(use-package rust-mode
  :defer t
  :hook (rust-mode . lsp)
  :config
  (setq rust-format-on-save t)
  (defun my/rust-setup ()
    (setq-local lsp-completion-enable nil)
    (setq-local compile-command "cargo build")))

;; ---- C/C++ ----
(use-package cc-mode
  :ensure nil
  :defer t
  :bind (:map c-mode-base-map ("C-c c" . compile))
  :hook (c-mode-common . (lambda () (c-set-style "stroustrup")))
  :config
  (use-package modern-cpp-font-lock
    :hook (c++-mode . modern-c++-font-lock-mode)))

;; ---- Python ----
(require 'python)

;; ---- TypeScript ----
(use-package typescript-mode :mode "\\.ts\\'" :commands typescript-mode)

;; ---- LaTeX ----
(use-package auctex
  :defer t
  :custom
  (TeX-auto-save t)
  (TeX-parse-self t)
  (TeX-master nil)
  (TeX-engine 'xetex)
  (TeX-source-correlate-method 'synctex)
  (TeX-source-correlate-start-server t)
  (TeX-after-compilation-finished-functions #'TeX-revert-document-buffer)
  :hook
  (LaTeX-mode . my-latex-setup)
  (LaTeX-mode . display-line-numbers-mode)
  :config
  (defun my-latex-setup ()
    (reftex-mode 1)
    (setq reftex-plug-into-AUCTeX t)))

(provide 'emacs-init-langs)
;;; init-langs.el ends here
