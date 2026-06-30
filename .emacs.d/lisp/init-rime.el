;;; init-rime.el --- Rime 中文输入配置 -*- lexical-binding: t; -*-

(require 'init-path)

(use-package rime
  :custom
  (default-input-method "rime")
  (rime-posframe-style 'vertical)
  (rime-show-candidate 'posframe)
  (rime-user-data-dir my-rime-user-data-dir)
  (rime-librime-root (expand-file-name "librime/dist" user-emacs-directory))
  :hook
  (emacs-startup . (lambda () (setq default-input-method "rime")))
  :bind
  (:map rime-active-mode-map
        ("M-j" . 'rime-inline-ascii)
        :map rime-mode-map
        ("M-j" . 'rime-force-enable)
        ("C-." . 'rime-send-keybinding)
        ("C-+" . 'rime-send-keybinding)
        ("C-," . 'rime-send-keybinding))
  :config
  (setq mode-line-mule-info '((:eval (rime-lighter))))
  (add-to-list 'rime-translate-keybindings "C-h")
  (add-to-list 'rime-translate-keybindings "C-d")
  (add-to-list 'rime-translate-keybindings "C-k")
  (add-to-list 'rime-translate-keybindings "C-a")
  (add-to-list 'rime-translate-keybindings "C-e")
  (setq rime-inline-ascii-trigger 'shift-r)

  (setq rime-disable-predicates
        '(rime-predicate-punctuation-line-begin-p
          rime-predicate-punctuation-after-space-cc-p
          rime-predicate-space-after-cc-p
          rime-predicate-punctuation-after-ascii-p))

  (setq rime-posframe-properties
        (list :background-color "#333333"
              :foreground-color "#dcdccc"
              :internal-border-width 2)))

(provide 'init-rime)
;;; init-rime.el ends here
