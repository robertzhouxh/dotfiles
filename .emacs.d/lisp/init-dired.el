;;; init-dired.el --- Dired 文件管理配置 -*- lexical-binding: t; -*-

(use-package dired
  :ensure nil
  :custom
  (dired-dwim-target t)
  (dired-recursive-copies 'always)
  (dired-recursive-deletes 'top)
  (dired-listing-switches "-alh")
  (delete-by-moving-to-trash t)
  :config
  ;; 在 Dired 中复用当前 buffer
  (put 'dired-find-alternate-file 'disabled nil)

  ;; 用 a 键在已有 buffer 中打开文件/目录
  (define-key dired-mode-map (kbd "a")
              (lambda ()
                (interactive)
                (let ((file (dired-get-filename)))
                  (if (file-directory-p file)
                      (dired-find-alternate-file)
                    (dired-find-file)))))

  ;; 用 C-a 回到上级目录
  (define-key dired-mode-map (kbd "C-a")
              (lambda ()
                (interactive)
                (find-alternate-file ".."))))

(provide 'init-dired)
;;; init-dired.el ends here
