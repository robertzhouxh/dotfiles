;;; init-dired.el --- Dired 极简配置  -*- lexical-binding: t; -*-

;; 自定义变量（这些可以放在外面，不依赖 Dired 加载）
(setq dired-dwim-target t
      dired-recursive-copies 'always
      dired-recursive-deletes 'top
      dired-listing-switches "-alh"
      delete-by-moving-to-trash t)

(put 'dired-find-alternate-file 'disabled nil)

;; 定义辅助函数
(defun my/dired-open ()
  "打开文件或目录：目录复用 buffer，文件新开 buffer。"
  (interactive)
  (let ((file (dired-get-filename)))
    (if (file-directory-p file)
        (dired-find-alternate-file)
      (dired-find-file))))

(defun my/dired-up ()
  "返回上级目录，复用当前 buffer。"
  (interactive)
  (find-alternate-file ".."))

;; ========== 关键：在 Dired 加载后执行绑定 ==========
(with-eval-after-load 'dired
  ;; 绑定按键到 dired-mode-map
  (define-key dired-mode-map (kbd "h") #'my/dired-up)
  (define-key dired-mode-map (kbd "l") #'my/dired-open)
  (define-key dired-mode-map (kbd "j") #'dired-next-line)
  (define-key dired-mode-map (kbd "k") #'dired-previous-line)
  (define-key dired-mode-map (kbd "m") #'dired-mark)
  (define-key dired-mode-map (kbd "u") #'dired-unmark)
  (define-key dired-mode-map (kbd "r") #'dired-do-rename)
  (define-key dired-mode-map (kbd "c") #'dired-do-copy)
  (define-key dired-mode-map (kbd "d") #'dired-do-delete)
  (define-key dired-mode-map (kbd "g") #'revert-buffer)
  (define-key dired-mode-map (kbd "?") #'dired-summary)
  ;; 恢复 Enter 键（防止被覆盖）
  (define-key dired-mode-map (kbd "RET") #'dired-find-file)

  ;; 如果使用了 Evil，让 Dired 永远处于 Emacs 状态
  (when (featurep 'evil)
    (evil-set-initial-state 'dired-mode 'emacs)
    ;; 可选：进入 Dired 时强制切换到 emacs 状态
    (add-hook 'dired-mode-hook #'evil-emacs-state)))

(provide 'emacs-init-dired)

