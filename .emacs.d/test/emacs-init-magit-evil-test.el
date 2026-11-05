;;; emacs-init-magit-evil-test.el --- Magit quit bindings -*- lexical-binding: t; -*-

;; Requires the installed Evil and Magit packages on `load-path'.
(require 'ert)
(require 'use-package)
(require 'magit)
(require 'emacs-init-evil)

(ert-deftest magit-evil-q-preserves-native-quit ()
  "Keep each Magit view's quit command when switching Evil states."
  (dolist (entry '((magit-status-mode . magit-mode-bury-buffer)
                   (magit-diff-mode . magit-mode-bury-buffer)
                   (magit-revision-mode . magit-mode-bury-buffer)
                   (magit-refs-mode . magit-mode-bury-buffer)
                   (magit-log-mode . magit-log-bury-buffer)
                   (magit-reflog-mode . magit-log-bury-buffer)
                   (magit-cherry-mode . magit-log-bury-buffer)
                   (magit-log-select-mode . magit-log-select-quit)))
    (with-temp-buffer
      (funcall (car entry))
      (evil-local-mode 1)
      (dolist (state '(emacs normal motion visual))
        (evil-change-state state)
        (should (eq (key-binding (kbd "q")) (cdr entry)))))))

(ert-deftest magit-evil-log-q-buries-window ()
  "Execute q in a displayed log buffer after entering normal state."
  (let ((buffer (generate-new-buffer " *magit-quit-test*")))
    (unwind-protect
        (save-window-excursion
          (switch-to-buffer buffer)
          (magit-log-mode)
          (evil-local-mode 1)
          (evil-normal-state)
          (should (eq (key-binding (kbd "q")) #'magit-log-bury-buffer))
          (call-interactively (key-binding (kbd "q")))
          (should-not (get-buffer-window buffer)))
      (when (buffer-live-p buffer)
        (kill-buffer buffer)))))

;;; emacs-init-magit-evil-test.el ends here
