;;; emacs-init-ui.el --- UI 视觉配置 -*- lexical-binding: t; -*-

(require 'emacs-init-path)

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

(use-package git-gutter
  :ensure t
  :hook ((prog-mode text-mode conf-mode) . git-gutter-mode)
  :custom
  ;; 实时刷新（默认仅保存时刷新）
  (git-gutter:update-interval 0.1)

  ;; Terminal 下显示符号
  (git-gutter:modified-sign "┃")
  (git-gutter:added-sign    "┃")
  (git-gutter:deleted-sign  "▔")

  ;; 不弹出提示
  (git-gutter:ask-p nil)

  ;; 更安静
  (git-gutter:hide-gutter nil)

  :config
  ;; GUI 使用 Fringe，美观很多
  (when (display-graphic-p)
    (use-package git-gutter-fringe
      :ensure t
      :config
      (define-fringe-bitmap 'git-gutter-fr:added
        [224] nil nil '(center repeated))
      (define-fringe-bitmap 'git-gutter-fr:modified
        [224] nil nil '(center repeated))
      (define-fringe-bitmap 'git-gutter-fr:deleted
        [128 192 224 240] nil nil 'bottom)))

  ;; 更协调的颜色
  (custom-set-faces
   '(git-gutter:modified ((t (:inherit warning))))
   '(git-gutter:added    ((t (:inherit success))))
   '(git-gutter:deleted  ((t (:inherit error))))))

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

(provide 'emacs-init-ui)
;;; init-ui.el ends here
