;;; init-ui.el --- UI 视觉配置 -*- lexical-binding: t; -*-

(require 'init-path)

;; ---- 高亮与括号 ----
(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

(use-package highlight-parentheses
  :diminish
  :hook ((prog-mode . highlight-parentheses-mode)
         (org-mode . highlight-parentheses-mode))
  :custom
  (highlight-parentheses-colors '("green" "yellow" "purple" "orange" "red")))

(use-package paren
  :hook (prog-mode . show-paren-mode)
  :custom
  (show-paren-delay 0.1)
  (show-paren-when-point-inside-paren t)
  (show-paren-when-point-in-periphery t)
  (show-paren-style 'parenthesis)
  :config
  (set-face-attribute 'show-paren-match nil :weight 'extra-bold))

(use-package elec-pair
  :hook (prog-mode . electric-pair-mode)
  :custom
  (electric-pair-preserve-balance t)
  (electric-pair-delete-adjacent-pairs t)
  (electric-pair-skip-self 'electric-pair-default-skip-self)
  (electric-pair-open-newline-between-pairs t)
  :config
  (setq electric-pair-pairs '((?\" . ?\") (?\{ . ?\}))))

;; ---- 图标 ----
(use-package all-the-icons
  :if my-graphic-p
  :commands all-the-icons-install-fonts)

;; ---- 标签栏 ----
(use-package sort-tab
  :if my-graphic-p
  :vc (:url "https://github.com/manateelazycat/sort-tab" :rev :newest)
  :commands (sort-tab-mode sort-tab-next sort-tab-previous)
  :init
  (run-with-idle-timer 1 nil #'sort-tab-mode)
  :config
  (setq sort-tab-name-max-length 20
        sort-tab-hide-tab-function nil
        sort-tab-cycle-navigation t))

;; ---- 主题 ----
(use-package lazycat-theme
  :vc (:url "https://github.com/manateelazycat/lazycat-theme" :rev :newest)
  :config
  (lazycat-theme-load-dark))

;; ---- Mode-line ----
(use-package awesome-tray
  :vc (:url "https://github.com/manateelazycat/awesome-tray" :rev :newest)
  :hook (after-init . awesome-tray-mode)
  :custom
  (awesome-tray-active-modules '("location" "pdf-view-page" "belong" "file-path" "mode-name" "last-command" "battery" "date"))
  (awesome-tray-info-padding-right 1))

;; ---- 字体 ----
(defun my/available-font (font-list)
  "从 FONT-LIST 中获取第一个可用字体。"
  (catch 'font
    (dolist (font font-list)
      (when (member font (font-family-list))
        (throw 'font font)))))

(setq my/ef (my/available-font '("Sarasa Mono SC"
                                  "JetBrainsMono Nerd Font"
                                  "JetBrainsMono"
                                  "Monaco"
                                  "Iosevka Comfy"
                                  "Cascadia Code")))

(setq my/cf (my/available-font '("Sarasa Mono SC"
                                  "等距更纱黑体 SC"
                                  "LXGW WenKai Mono"
                                  "Microsoft YaHei Mono")))

(defun my/load-font-setup ()
  "设置中英文字体。"
  (when my-graphic-p
    (let ((english-font (or my/ef "Monaco"))
          (chinese-font (or my/cf "PingFang SC"))
          (font-size 180))
      (set-face-attribute 'default nil :family english-font :height font-size)
      (dolist (charset '(kana han symbol cjk-misc bopomofo))
        (set-fontset-font (frame-parameter nil 'font) charset
                          (font-spec :family chinese-font :height font-size))))))

(add-hook 'after-init-hook 'my/load-font-setup)

;; ---- macOS Emoji 字体 ----
(when my-sys-mac-p
  (set-fontset-font t 'emoji '("Apple Color Emoji" . "iso10646-1") nil 'prepend))

(provide 'init-ui)
;;; init-ui.el ends here
