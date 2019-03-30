;;; evil-eshell.el --- Add Evil bindings to Eshell
;;; Code:

(require 'evil)
(require 'eshell)

(defun evil-eshell-next-prompt ()
  (when (get-text-property (point) 'read-only)
    ;; If at end of prompt, `eshell-next-prompt' will not move, so go backward.
    (beginning-of-line)
    (eshell-next-prompt 1)))

(defun evil-eshell-setup ()
  (dolist (hook '(evil-replace-state-entry-hook evil-insert-state-entry-hook))
    (add-hook hook 'evil-eshell-next-prompt nil t)))

(add-hook 'eshell-mode-hook 'evil-eshell-setup)

(defun evil-eshell-interrupt-process ()
  (interactive)
  (eshell-interrupt-process)
  (evil-insert 1))

;;; `eshell-mode-map' is reset when Eshell is initialized in `eshell-mode'. We
;;; need to add bindings to `eshell-first-time-mode-hook'.
(defun evil-eshell-set-keys-function ()
  (evil-define-key 'normal eshell-mode-map
    ;; motion
    "[" 'eshell-previous-prompt
    "]" 'eshell-next-prompt
    (kbd "C-k") 'eshell-previous-prompt
    (kbd "C-j") 'eshell-next-prompt
    "0" 'eshell-bol
    "^" 'eshell-bol
    (kbd "M-h") 'eshell-backward-argument
    (kbd "M-l") 'eshell-forward-argument

    (kbd "<return>") 'eshell-send-input
    (kbd "C-c C-c") 'evil-eshell-interrupt-process)
  (evil-define-key 'insert eshell-mode-map
    ;; motion
    (kbd "M-h") 'eshell-backward-argument
    (kbd "M-l") 'eshell-forward-argument)
  (evil-define-key 'visual eshell-mode-map
    ;; motion
    ;; TODO: This does not work with `evil-visual-line'.
    "[" 'eshell-previous-prompt
    "]" 'eshell-next-prompt
    (kbd "C-k") 'eshell-previous-prompt
    (kbd "C-j") 'eshell-next-prompt
    "0" 'eshell-bol
    "^" 'eshell-bol))

;; TODO: Compare this setup procedure with evil-ediff.
;;;###autoload
(defun evil-eshell-set-keys ()
  (add-hook 'eshell-first-time-mode-hook 'evil-eshell-set-keys-function))

(provide 'init-evil-eshell)
;;; evil-eshell.el ends here