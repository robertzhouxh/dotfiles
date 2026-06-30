;;; init-platform.el --- 平台差异配置 -*- lexical-binding: t; -*-

(require 'init-path)

;; ---- macOS ----
(when my-sys-mac-p
  (use-package reveal-in-osx-finder
    :commands (reveal-in-osx-finder))

  ;; 系统剪贴板集成
  (defun copy-from-osx ()
    (shell-command-to-string "pbpaste"))

  (defun paste-to-osx (text &optional push)
    (let ((process-connection-type nil))
      (let ((proc (start-process "pbcopy" "*Messages*" "pbcopy")))
        (process-send-string proc text)
        (process-send-eof proc))))

  (setq interprogram-cut-function   'paste-to-osx
        interprogram-paste-function 'copy-from-osx)

  ;; 废纸篓
  (setq delete-by-moving-to-trash t
        trash-directory "~/.Trash/emacs")

  (defun system-move-file-to-trash (file)
    (call-process (executable-find "trash") nil 0 nil file))

  (message "Welcome to macOS, have a nice day!"))

;; ---- Linux ----
(when my-sys-linux-p
  (defun yank-to-x-clipboard ()
    "将当前选中区域复制到 X 剪贴板。"
    (interactive)
    (if (region-active-p)
        (progn
          (shell-command-on-region (region-beginning) (region-end) "xsel -i -b")
          (message "Yanked region to clipboard!")
          (deactivate-mark))
      (message "No region active; can't yank to clipboard!"))))

(provide 'init-platform)
;;; init-platform.el ends here
