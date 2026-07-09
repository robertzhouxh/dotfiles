;;; emacs-init-elpa.el --- 包管理器引导 -*- lexical-binding: t; -*-

(require 'package)

(setq package-user-dir (expand-file-name "elpa" my-packages-dir))

;; 包归档源
(setq package-archives
      '(("gnu" . "https://elpa.gnu.org/packages/")
        ("melpa" . "https://melpa.org/packages/")))

;; 初始化 package.el
(package-initialize)

;; 首次运行时刷新包列表
(unless package-archive-contents
  (package-refresh-contents))

;; MELPA 每天重建，缓存超过 24 小时自动刷新，避免 stale URL 报错
(let ((stamp (expand-file-name "archive-contents-timestamp" package-user-dir)))
  (when (or (not (file-exists-p stamp))
            (> (- (float-time) (float-time (file-attribute-modification-time
                                            (file-attributes stamp))))
               (* 24 60 60)))
    (package-refresh-contents)
    (write-region "" nil stamp nil 'quiet)))

;; 如果 use-package 尚未安装，从 ELPA 安装
(unless (package-installed-p 'use-package)
  (package-install 'use-package))

(eval-when-compile
  (require 'use-package))

;; 确保 diminish 已安装（被多个模块的 :diminish 使用）
(unless (package-installed-p 'diminish)
  (package-install 'diminish))
(require 'diminish)

;; 启用 :ensure 支持
(setq use-package-always-ensure t)

;; 统计和 imenu 支持
(setq use-package-enable-imenu-support t)

(provide 'emacs-init-elpa)
;;; init-elpa.el ends here
