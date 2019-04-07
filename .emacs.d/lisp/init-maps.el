;;; init-maps.el -- Provide global key maps

;;; Commentary:
;;; Provide global maps that aren't specific to any mode or package.

;; C-x C-+ or C-x-+ 字体放大
;; C-x C--  字体缩小

;;; Code:
(global-set-key (kbd "C-x 2") 'vsplit-last-buffer)
(global-set-key (kbd "C-x 3") 'hsplit-last-buffer)

(global-set-key [M-left] 'shrink-window-horizontally)
(global-set-key [M-right] 'enlarge-window-horizontally)
(global-set-key [M-up] 'shrink-window)
(global-set-key [M-down] 'enlarge-window)

(global-set-key (kbd "C-c <left>")  'windmove-left)
(global-set-key (kbd "C-c <right>") 'windmove-right)
(global-set-key (kbd "C-c <up>")    'windmove-up)
(global-set-key (kbd "C-c <down>")  'windmove-down)

(global-set-key (kbd "M-,") 'godef-jump)
(global-set-key (kbd "M-'") 'pop-tag-mark)

(global-set-key (kbd "M-]") 'dumb-jump-go)
(global-set-key (kbd "M-t") 'dumb-jump-back)

(global-set-key (kbd "M-p") 'hold-line-scroll-up )
(global-set-key (kbd "M-n") 'hold-line-scroll-down )

(global-set-key (kbd "M-y")   'async-shell-command)
(global-set-key (kbd "M-g")   'goto-line)
(global-set-key (kbd "C-h")     'backward-delete-char)
(global-set-key (kbd "M-r")     'rename-file)
(global-set-key (kbd "C-x s") 'save-all)
;;(key-chord-define-global "jj" 'evil-normal-state)
;;(key-chord-define-global "jk" 'jc/switch-to-previous-buffer)

;; Automatically save all file-visiting buffers when Emacs loses focus.
(add-hook 'focus-out-hook 'save-all)

(provide 'init-maps)
;;; init-maps.el ends here
