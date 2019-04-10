;;; init-plantform.el
;;; ;;; Commentary:
;;; ;;; Code:

(when (system-is-mac)
  ;; refer to: http://azaleasays.com/2013/07/05/setting-up-mac-os-x-and-iterm2-for-emacs/
  ;; Switch the Cmd and Meta keys
  ;; On  I use ⌘ as meta and prefer ⌥ to do nothing 
  (setq mac-command-modifier 'meta
        mac-option-modifier 'none)

  ;; font size
  (set-fontset-font t 'unicode "Apple Color Emoji" nil 'prepend)
  (set-face-attribute 'default nil :height 140)

  (if (executable-find "gls")
    (progn
      (setq insert-directory-program "gls")
      (setq dired-listing-switches "-lFaGh1v --group-directories-first"))
    (setq dired-listing-switches "-ahlF"))

  (defun copy-from-osx ()
    "Handle copy/paste intelligently on osx."
    (let ((pbpaste (purecopy "/usr/bin/pbpaste")))
      (if (and (eq system-type 'darwin)
               (file-exists-p pbpaste))
        (let ((tramp-mode nil)
              (default-directory "~"))
          (shell-command-to-string pbpaste)))))

  (defun paste-to-osx (text &optional push)
    (let ((process-connection-type nil))
      (let ((proc (start-process "pbcopy" "*Messages*" "/usr/bin/pbcopy")))
        (process-send-string proc text)
        (process-send-eof proc))))

  (setq interprogram-cut-function 'paste-to-osx
        interprogram-paste-function 'copy-from-osx)

  ;; Trash.
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
                    file)))

(when (system-is-linux)
  (defun yank-to-x-clipboard ()
    (interactive)
    (if (region-active-p)
      (progn
        (shell-command-on-region (region-beginning) (region-end) "xsel -i -b")
        (message "Yanked region to clipboard!")
        (deactivate-mark))
      (message "No region active; can't yank to clipboard!"))))

(provide 'init-plantform)
