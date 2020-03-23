;;; init-plantform.el
;;; ;;; Commentary:
;;; ;;; Code:

(when (x/system-is-mac)
  (setq mac-command-modifier 'meta
        mac-option-modifier 'none)

  (set-face-attribute 'default nil :height 160)
  ;;coding font for english and chinese
  ;(set-face-attribute 'default nil
  ;                    :family "Source Code Pro for Powerline"
  ;                    :height 140
  ;                    :weight 'medium
  ;                    :width 'medium)

  ;(if (display-graphic-p)
  ;  (dolist (charset '(kana han symbol cjk-misc bopomofo))
  ;    (set-fontset-font (frame-parameter nil 'font)
  ;                      charset (font-spec :family "Microsoft Yahei"
  ;                                         :size 14)))
  ;  )

  ;; Better copy and paste support for mac os x
  (defun copy-from-osx ()
    (shell-command-to-string "pbpaste"))
  (defun paste-to-osx (text &optional push)
    (let ((process-connection-type nil))
      (let ((proc (start-process "pbcopy" "*Messages*" "pbcopy")))
        (process-send-string proc text)
        (process-send-eof proc))))
  (setq interprogram-cut-function 'paste-to-osx)
  (setq interprogram-paste-function 'copy-from-osx)

  ;; Better for dired
  (if (executable-find "gls")
    (progn
      (setq insert-directory-program "gls")
      (setq dired-listing-switches "-lFaGh1v --group-directories-first"))
    (setq dired-listing-switches "-ahlF"))

  ;; Trash for safe
  (defun move-file-to-trash (file)
    "Use `trash' to move FILE to the system trash.
    When using Homebrew, install it using \"brew install trash\"."
    (call-process (executable-find "trash")
                  nil 0 nil
                  file))
    (setq trash-directory "~/.Trash/emacs")
    (setq delete-by-moving-to-trash t)
    (defun system-move-file-to-trash (file)
      "Use \"trash\" to move FILE to the system trash.
      When using Homebrew, install it using \"brew install trash\"."
      (call-process (executable-find "trash")
                    nil 0 nil
                    file))
      (message "Wellcome To Mac OS X, Have A Nice Day!!!"))

(when (x/system-is-linux)
  (defun yank-to-x-clipboard ()
    (interactive)
    (if (region-active-p)
      (progn
        (shell-command-on-region (region-beginning) (region-end) "xsel -i -b")
        (message "Yanked region to clipboard!")
        (deactivate-mark))
      (message "No region active; can't yank to clipboard!"))))

(provide 'init-plantform)
