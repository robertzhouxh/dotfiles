;;; emacs-init-completion.el --- LSP 与补全配置 -*- lexical-binding: t; -*-

;; YASnippet
(use-package yasnippet
  :commands yas-minor-mode
  :config
  (setq yas-snippet-dirs '("~/.emacs.d/snippets"))
  (yas-reload-all))

;; 关闭内置 eldoc（lsp-bridge 自行处理）
(global-eldoc-mode -1)

;; LSP Bridge
(use-package lsp-bridge
  :vc (:url "https://github.com/manateelazycat/lsp-bridge"
       :rev :newest)
  :custom
  (lsp-bridge-enable-hover-diagnostic t)
  (lsp-bridge-popup-documentation-delay 0.5)
  (lsp-bridge-enable-signature-help t)
  (lsp-bridge-enable-list-diagnostic t)
  (lsp-bridge-enable-inlay-hint t)
  (lsp-bridge-enable-auto-format-code nil)
  (lsp-bridge-python-command (expand-file-name "~/miniconda3/bin/python3"))
  (lsp-bridge-python-lsp-server "pyright")
  (lsp-bridge-markdown-lsp-server "marksman")
  :init
  (global-lsp-bridge-mode))

(provide 'emacs-init-completion)
;;; init-completion.el ends here
