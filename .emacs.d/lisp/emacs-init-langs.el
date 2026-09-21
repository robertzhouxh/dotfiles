;;; emacs-init-langs.el --- 编程语言配置 -*- lexical-binding: t; -*-

(require 'emacs-init-path)

;; ---- 通用 ----
(use-package yaml-mode :mode ("\\.ya?ml\\'" . yaml-mode))
(use-package json-mode :mode ("\\.json\\'" . json-mode))
(use-package protobuf-mode :mode ("\\.proto\\'" . protobuf-mode))
(use-package dockerfile-mode :commands dockerfile-mode)

;; 保留旧配置，方便在体验 super-save 后快速恢复。
;; (use-package auto-save
;;   :vc (:url "https://github.com/manateelazycat/auto-save" :rev :newest)
;;   :hook (after-init . auto-save-enable)
;;   :custom
;;   (auto-save-silent t)
;;   (auto-save-disable-predicates
;;    '((lambda () (string-prefix-p "*" (buffer-name)))
;;      (lambda () (string-match-p "\\.gpg$" (buffer-file-name))))))

(use-package super-save
  :ensure t
  :config
  (setq super-save-auto-save-when-idle t
        super-save-silent t
        auto-save-default nil)
  (super-save-mode +1))

;; ---- Tree-sitter ----
(use-package treesit-fold
  :vc (:url "https://github.com/emacs-tree-sitter/treesit-fold" :rev :newest)
  :hook (prog-mode . treesit-fold-mode))

(use-package treesit-auto
  :demand t
  :custom
  (treesit-font-lock-level 4)
  ;; Emacs 31.1 会处理内置 grammar 的来源；缺失时仍由用户确认下载。
  (treesit-auto-install 'prompt)
  :config
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

;; ---- Markdown ----
;; 代码块按语言高亮 + 语言标签别名表也在里面，单独成模块是为了能挂门禁测试
;; （这个文件依赖一堆包，`-Q --batch' 里加载不起来）。
(require 'emacs-solo-markdown)

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
