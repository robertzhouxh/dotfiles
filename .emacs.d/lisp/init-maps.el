;;; init-maps.el -- Provide global key maps

;;; Commentary:
;;; Provide global maps that aren't specific to any mode or package.

;; C-x C-+ or C-x-+ 字体放大
;; C-x C--  字体缩小

;; Automatically save all file-visiting buffers when Emacs loses focus.
(add-hook 'focus-out-hook 'save-all)

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

(global-set-key (kbd "C-]") 'helm-gtags-find-tag)
(global-set-key (kbd "C-t") 'helm-gtags-pop-stack)


;;(global-set-key (kbd "C-t") 'x/hydra-window)

;; 如果用过 magit , 对 magit-status 下按 c 等出现的可选菜单应该有印象, hydra 正是把这个能力扩展了. hydra 也在快速进化变强,
(global-set-key
  (kbd "C-M-w")
  (defhydra hydra-window ()
            "window"
            ("h" windmove-left)
            ("j" windmove-down)
            ("k" windmove-up)
            ("l" windmove-right)
            ("v" (lambda ()
                   (interactive)
                   (split-window-right)
                   (windmove-right))
             "vert")
            ("x" (lambda ()
                   (interactive)
                   (split-window-below)
                   (windmove-down))
             "horz")
            ("o" delete-other-windows "1" :color blue)
            ("i" ace-maximize-window "a1" :color blue)
            ("q" nil "cancel")))

(global-set-key
  (kbd "C-M-o")
  (defhydra hydra-vi
            (:pre
              (set-cursor-color "#e52b50")
              :post
              (set-cursor-color "#ffffff")
              :color amaranth)
            "vi"
            ("l" forward-char)
            ("h" backward-char)
            ("j" next-line)
            ("k" previous-line)
            ("m" set-mark-command "mark")
            ("a" move-beginning-of-line "beg")
            ("e" move-end-of-line "end")
            ("d" delete-region "del" :color blue)
            ("y" kill-ring-save "yank" :color blue)
            ("q" nil "quit")))

(provide 'init-maps)
;;; init-maps.el ends here
