;;; emacs-init-vcs.el --- 版本控制配置 (Emacs 31) -*- lexical-binding: t; -*-

;; ── VC 基础设置 ──────────────────────────────────────────────────────────────

(use-package magit :ensure t :defer t)

(with-eval-after-load 'vc
  (setopt
   vc-handled-backends           '(Git)
   vc-auto-revert-mode           t
   vc-dir-auto-hide-up-to-date   t
   auto-revert-check-vc-info     t
   vc-make-backup-files          nil))

;; ── Stage / Unstage ──────────────────────────────────────────────────────────
;;
;; 注意：VC 状态模型不区分 staged 和 unstaged（都是 `edited`）。
;; 对 tracked modified 文件，S/U 后状态标签不会变（edited → edited），
;; 但 git 操作确实执行了，minibuffer 会有 "Staged/Unstaged N file(s)." 提示。
;; 对 untracked 文件，S 会从 unregistered → added，可见变化。

(defun vc-dir--files-or-current ()
  "返回已标记文件列表；没有标记则返回当前行文件。"
  (or (vc-dir-marked-files)
      (ignore-errors
        (list (vc-dir-current-file)))))

(defun vc-dir-stage ()
  "Stage 当前或已标记文件 (git add)。"
  (interactive)
  (if-let* ((files (vc-dir--files-or-current)))
      (progn (vc-git-register files)
             (dolist (f files) (vc-file-clearprops f))
             (ignore-errors (vc-dir-refresh))
             (message "Staged %d file(s)." (length files)))
    (message "No file at point.")))

(defun vc-dir-unstage ()
  "Unstage 当前或已标记文件 (git reset HEAD)。"
  (interactive)
  (if-let* ((files (vc-dir--files-or-current)))
      (progn (vc-git-command nil 0 files "reset" "-q" "--")
             (dolist (f files) (vc-file-clearprops f))
             (ignore-errors (vc-dir-refresh))
             (message "Unstaged %d file(s)." (length files)))
    (message "No file at point.")))

;; ── 辅助命令 ─────────────────────────────────────────────────────────────────

(defun vc-dir-current-should-skip-p ()
  "当前行是否需要跳过（目录行或 up-to-date 文件）。"
  (when vc-ewoc
    (let* ((node (ewoc-locate vc-ewoc))
           (data (ewoc-data node)))
      (when data
        (or (vc-dir-fileinfo->directory data)
            (eq (vc-dir-fileinfo->state data) 'up-to-date))))))

(defun vc-dir-move-and-diff (move-fn wrap-pos)
  "移动到下一个非跳过文件并显示 diff。"
  (let ((start-node (and vc-ewoc (ewoc-locate vc-ewoc)))
        (wrapped nil))
    (catch 'done
      (while t
        (let ((prev-node (and vc-ewoc (ewoc-locate vc-ewoc))))
          (funcall move-fn 1)
          (let ((cur-node (and vc-ewoc (ewoc-locate vc-ewoc))))
            (when (and (eq cur-node prev-node) (not wrapped))
              (setq wrapped t)
              (goto-char wrap-pos)
              (funcall move-fn 1)
              (setq cur-node (and vc-ewoc (ewoc-locate vc-ewoc))))
            (when (eq cur-node start-node)
              (message "No edited files found")
              (throw 'done nil))
            (unless (vc-dir-current-should-skip-p)
              (throw 'done nil))
            (when (eq cur-node prev-node)
              (message "No edited files found")
              (throw 'done nil)))))))
  (save-selected-window (vc-diff)))

(defun vc-dir-quick-commit ()
  "标记所有已修改文件并进入提交界面。"
  (interactive)
  (vc-dir-unmark-all-files 1)
  (dolist (state '(edited added removed))
    (vc-dir-mark-state-files state))
  (let ((files (vc-dir-marked-files)))
    (if files
        (vc-next-action nil)
      (message "No files to commit."))))

;; ── 键绑定 ──────────────────────────────────────────────────────────────────
;;
;; S - stage (覆盖默认 vc-dir-search，如需搜索用 C-s)
;; U - unstage (覆盖默认 vc-dir-unmark-all-files，取消全部标记用 M-u)
;; c - quick commit（默认无绑定）
;; TAB / S-TAB - 在已修改文件间跳转并 diff（默认无绑定）

(with-eval-after-load 'vc-dir
  (define-key vc-dir-mode-map (kbd "S")        #'vc-dir-stage)
  (define-key vc-dir-mode-map (kbd "U")        #'vc-dir-unstage)
  (define-key vc-dir-mode-map (kbd "c")        #'vc-dir-quick-commit)
  (define-key vc-dir-mode-map (kbd "<tab>")
              (lambda () (interactive) (vc-dir-move-and-diff #'vc-dir-next-line (point-min))))
  (define-key vc-dir-mode-map (kbd "<backtab>")
              (lambda () (interactive) (vc-dir-move-and-diff #'vc-dir-previous-line (point-max))))
  (message "emacs-init-vcs: vc-dir keybindings set (S/U/c/TAB/backtab)"))

(provide 'emacs-init-vcs)
;;; emacs-init-vcs.el ends here
