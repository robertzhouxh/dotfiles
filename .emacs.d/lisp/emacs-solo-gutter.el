;;; emacs-solo-gutter.el --- Git diff gutter indicators in buffers  -*- lexical-binding: t; -*-
;;
;; Author: Rahul Martim Juliato
;; URL: https://github.com/LionyxML/emacs-solo
;; Package-Requires: ((emacs "30.1"))
;; Keywords: vc, convenience
;; SPDX-License-Identifier: GPL-3.0-or-later

;;; Commentary:
;;
;; Displays git diff indicators in the left margin of file-visiting
;; buffers.  Shows added, changed, and deleted lines with colored
;; symbols.  Refreshes on save, revert, and focus changes.

;;; Code From: https://github.com/LionyxML/emacs-solo/blob/main/lisp/emacs-solo-gutter.el

;; ── 变量 ────────────────────────────────────────────────────────────────────────

(defvar git-gutter-diff-info nil
  "Alist of (LINE . STATUS) for the current buffer's git diff.
STATUS is one of \"added\", \"changed\", or \"deleted\".")
(make-variable-buffer-local 'git-gutter-diff-info)

(defvar emacs-solo/git-gutter--switch-timer nil
  "Debounce timer for `emacs-solo/git-gutter-on-window-switch'.")

;; ── Hunk 导航 ───────────────────────────────────────────────────────────────────

(defun emacs-solo/goto-next-hunk ()
  "Jump cursor to the closest next hunk."
  (interactive)
  (let* ((current-line (line-number-at-pos))
         (line-numbers (mapcar #'car git-gutter-diff-info))
         (sorted-line-numbers (sort line-numbers '<))
         (next-line-number
          (if (not (member current-line sorted-line-numbers))
              (cl-find-if (lambda (line) (> line current-line)) sorted-line-numbers)
            (let ((last-line nil))
              (cl-loop for line in sorted-line-numbers
                       when (and (> line current-line)
                                 (or (not last-line)
                                     (/= line (1+ last-line))))
                       return line
                       do (setq last-line line))))))
    (when next-line-number
      (goto-char (point-min))
      (forward-line (1- next-line-number)))))

(defun emacs-solo/goto-previous-hunk ()
  "Jump cursor to the closest previous hunk."
  (interactive)
  (let* ((current-line (line-number-at-pos))
         (line-numbers (mapcar #'car git-gutter-diff-info))
         (sorted-line-numbers (sort line-numbers '<))
         (previous-line-number
          (if (not (member current-line sorted-line-numbers))
              (cl-find-if (lambda (line) (< line current-line))
                          (reverse sorted-line-numbers))
            (let ((previous-line nil))
              (dolist (line sorted-line-numbers)
                (when (and (< line current-line)
                           (not (member (1- line) line-numbers)))
                  (setq previous-line line)))
              previous-line))))
    (when previous-line-number
      (goto-char (point-min))
      (forward-line (1- previous-line-number)))))

;; ── Git diff 解析 ───────────────────────────────────────────────────────────────

(defun emacs-solo/git-gutter-process-git-diff ()
  "解析 git diff --unified=0 输出，返回 (LINE . STATUS) 列表。
STATUS 为 \"added\"、\"changed\" 或 \"deleted\"。
使用 rg（优先）或 grep -P 提取 hunk header 中的新行号。"
  (interactive)
  (let* ((result '())
         (file-path (buffer-file-name))
         (grep-cmd (if (executable-find "rg")
                       "rg -Po"
                     "grep -Po"))
         (output (shell-command-to-string
                  (format
                   "git diff HEAD --unified=0 %s | %s '^@@ -[0-9]+(,[0-9]+)? \\+\\K[0-9]+(,[0-9]+)?(?= @@)'"
                   (shell-quote-argument file-path)
                   grep-cmd)))
         (lines (split-string output "\n")))
    (dolist (line lines)
      (cond
       ;; "start,count" 格式 (e.g. "10,3" → 从第10行开始，3行修改)
       ((string-match "\\`\\([0-9]+\\),\\([0-9]+\\)\\'" line)
        (let ((num   (string-to-number (match-string 1 line)))
              (count (string-to-number (match-string 2 line))))
          (if (= count 0)
              (push (cons (1+ num) "deleted") result)
            (dotimes (i count)
              (push (cons (+ num i) "changed") result)))))
       ;; "start" 格式 (e.g. "10" → 第10行新增)
       ((string-match "\\`\\([0-9]+\\)\\'" line)
        (push (cons (string-to-number line) "added") result))))
    (setq git-gutter-diff-info result)
    result))

;; ── Gutter 渲染 ─────────────────────────────────────────────────────────────────

(defun emacs-solo/git-gutter-add-mark (&rest _args)
  "在当前 buffer 的左 margin 添加 Git diff 标记。
'+' 新增行 (success face)
'~' 修改行 (warning face)
'-' 删除行 (error face)"
  (interactive)
  ;; 确保左 margin 有宽度（buffer-local 值供新窗口使用）
  (when (zerop left-margin-width)
    (setq-local left-margin-width 1))
  ;; 更新所有显示当前 buffer 的窗口的 margin（立即生效）
  (dolist (win (get-buffer-window-list nil nil t))
    (when (zerop (or (car (window-margins win)) 0))
      (set-window-margins win 1 (cdr (window-margins win)))))
  (remove-overlays (point-min) (point-max) 'emacs-solo--git-gutter-overlay t)
  (let ((lines-status (or (emacs-solo/git-gutter-process-git-diff) '())))
    (save-excursion
      (dolist (line-status lines-status)
        (let* ((line-num (car line-status))
               (status  (cdr line-status))
               (symbol  "┃")
               (face    (cond
                         ((string= status "added")   'success)
                         ((string= status "changed") 'warning)
                         ((string= status "deleted") 'error))))
          (when (and line-num face)
            (goto-char (point-min))
            (forward-line (1- line-num))
            (let ((ov (make-overlay (line-beginning-position)
                                    (line-beginning-position))))
              (overlay-put ov 'emacs-solo--git-gutter-overlay t)
              (overlay-put ov 'before-string
                           (propertize " "
                                       'display
                                       `((margin left-margin)
                                         ,(propertize symbol 'face face)))))))))))

;; ── Gutter 开关 ─────────────────────────────────────────────────────────────────

(defun emacs-solo/timed-git-gutter-on ()
  "延迟 0.1s 后刷新 gutter（等 VC 状态就绪）。"
  (let ((buf (current-buffer)))
    (run-at-time 0.1 nil
                 (lambda ()
                   (when (buffer-live-p buf)
                     (with-current-buffer buf
                       (emacs-solo/git-gutter-add-mark)))))))

(defun emacs-solo/git-gutter-on ()
  "开启 Git gutter：设置全局 hook 并为当前 buffer 添加标记。"
  (interactive)
  (add-hook 'find-file-hook #'emacs-solo/timed-git-gutter-on)
  (add-hook 'after-save-hook #'emacs-solo/git-gutter-add-mark)
  (add-hook 'after-revert-hook #'emacs-solo/timed-git-gutter-on)
  (add-function :after after-focus-change-function
                #'emacs-solo/git-gutter-refresh-visible)
  (add-hook 'window-selection-change-functions
            #'emacs-solo/git-gutter-on-window-switch)
  (when (and (buffer-file-name)
             (not (string-match-p "\\`\\*" (buffer-name))))
    (emacs-solo/timed-git-gutter-on)))

(defun emacs-solo/git-gutter-off ()
  "关闭 Git gutter：移除所有标记和 hook。"
  (interactive)
  (remove-overlays (point-min) (point-max) 'emacs-solo--git-gutter-overlay t)
  (remove-hook 'find-file-hook #'emacs-solo/timed-git-gutter-on)
  (remove-hook 'after-save-hook #'emacs-solo/git-gutter-add-mark)
  (remove-hook 'after-revert-hook #'emacs-solo/timed-git-gutter-on)
  (remove-function after-focus-change-function
                   #'emacs-solo/git-gutter-refresh-visible)
  (remove-hook 'window-selection-change-functions
               #'emacs-solo/git-gutter-on-window-switch))

;; ── 焦点/窗口切换刷新 ──────────────────────────────────────────────────────────

(defun emacs-solo/git-gutter-refresh-visible ()
  "Emacs 恢复焦点时刷新所有可见 file-visiting buffer 的 gutter。"
  (when (frame-focus-state)
    (dolist (win (window-list))
      (let ((buf (window-buffer win)))
        (when (and (buffer-file-name buf)
                   (not (string-match-p "\\`\\*" (buffer-name buf)))
                   (vc-git-root (buffer-file-name buf)))
          (with-current-buffer buf
            (emacs-solo/timed-git-gutter-on)))))))

(defun emacs-solo/git-gutter-on-window-switch (_frame)
  "切换窗口时刷新 gutter（debounce 200ms）。"
  (when (timerp emacs-solo/git-gutter--switch-timer)
    (cancel-timer emacs-solo/git-gutter--switch-timer))
  (setq emacs-solo/git-gutter--switch-timer
        (run-at-time
         0.2 nil
         (lambda ()
           (setq emacs-solo/git-gutter--switch-timer nil)
           (let ((buf (window-buffer (selected-window))))
             (when (and (buffer-file-name buf)
                        (not (string-match-p "\\`\\*" (buffer-name buf)))
                        (with-current-buffer buf
                          (vc-git-root (buffer-file-name buf))))
               (with-current-buffer buf
                 (emacs-solo/git-gutter-add-mark))))))))

;; ── 键绑定 ─────────────────────────────────────────────────────────────────────

(global-set-key (kbd "M-9") #'emacs-solo/goto-previous-hunk)
(global-set-key (kbd "M-0") #'emacs-solo/goto-next-hunk)
(global-set-key (kbd "C-c g p") #'emacs-solo/goto-previous-hunk)
(global-set-key (kbd "C-c g r") #'emacs-solo/git-gutter-off)
(global-set-key (kbd "C-c g g") #'emacs-solo/git-gutter-on)
(global-set-key (kbd "C-c g n") #'emacs-solo/goto-next-hunk)

;; ── 自动开启 ───────────────────────────────────────────────────────────────────

(when emacs-solo-enable-buffer-gutter
  (add-hook 'after-init-hook #'emacs-solo/git-gutter-on))

(provide 'emacs-solo-gutter)
;;; emacs-solo-gutter.el ends here
