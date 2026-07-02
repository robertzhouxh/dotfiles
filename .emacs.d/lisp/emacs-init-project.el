;;; emacs-init-project.el --- 项目管理配置 -*- lexical-binding: t; -*-

(use-package projectile
  :diminish
  :commands (projectile-switch-project projectile-discover-projects-in-search-path)
  :config
  (projectile-mode +1)
  (setq projectile-project-search-path '("~/src/" "~githubs")
        projectile-require-project-root nil
        projectile-completion-system 'ivy
        projectile-mode-line-function '(lambda () " Projectile")))

(use-package ivy
  :diminish
  :init
  (use-package amx :defer t)
  (use-package counsel :diminish :config (counsel-mode 1))
  (use-package swiper :defer t)
  (ivy-mode 1)
  :bind
  (("C-s" . swiper-isearch)
   ("M-y" . counsel-yank-pop)
   (:map ivy-minibuffer-map ("M-RET" . ivy-immediate-done))
   (:map counsel-find-file-map ("C-~" . counsel-goto-local-home)))
  :custom
  (ivy-use-virtual-buffers t)
  (ivy-height 10)
  (ivy-on-del-error-function nil)
  (ivy-magic-slash-non-match-action 'ivy-magic-slash-non-match-create)
  (ivy-count-format "【%d/%d】")
  (ivy-wrap t)
  :config
  (defun counsel-goto-local-home ()
    "跳转到本地 HOME 目录。"
    (interactive)
    (ivy--cd "~/")))

(use-package color-rg
  :vc (:url "https://github.com/manateelazycat/color-rg" :rev :newest)
  :if (executable-find "rg")
  :bind ("C-M-s" . color-rg-search-input))

(use-package find-file-in-project
  :if (executable-find "find")
  :init
  (when (executable-find "fd")
    (setq ffip-use-rust-fd t)))

(provide 'emacs-init-project)
;;; init-project.el ends here
