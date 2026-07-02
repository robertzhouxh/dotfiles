;;; init-platform.el --- 平台差异配置 -*- lexical-binding: t; -*-

(require 'emacs-init-path)

(when my-sys-mac-p
  (setq delete-by-moving-to-trash t
        trash-directory "~/.Trash/emacs")

  (defun system-move-file-to-trash (file)
    (call-process (executable-find "trash") nil 0 nil file)))

;; ---- Linux ----
;;(when my-sys-linux-p
;;  )

(provide 'emacs-init-platform)
;;; init-platform.el ends here
