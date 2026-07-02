;;; init-vcs.el --- 版本控制配置 -*- lexical-binding: t; -*-

(use-package vc
  :ensure nil
  :defer t
  :custom
  (vc-handled-backends '(Git))
  :config

  ;; ============================================================
  ;; vc-dir Magit 风格工作流
  ;;   s     → stage 当前文件
  ;;   S     → stage 所有文件
  ;;   A     → amend 提交
  ;;   c c   → 提交
  ;;   h/j/k/l → 导航（同 Dired）
  ;; ============================================================

  ;; vc-dir 相关配置延迟到 vc-dir 加载后执行，
  ;; 避免 vc-dir-mode-map 在 vc 的 :config 中尚未定义。
  (with-eval-after-load 'vc-dir
    ;; vc-dir 设为 emacs 状态（同 Dired），mode-map 按键直接生效
    (when (featurep 'evil)
      (evil-set-initial-state 'vc-dir-mode 'emacs)
      (add-hook 'vc-dir-mode-hook #'evil-emacs-state))

    ;; ---- 命令实现 ----
    (defun vc-dir-stage-all ()
      "Stage (mark) all modified, added, and removed files."
      (interactive)
      (vc-dir-unmark-all-files 1)
      (dolist (state '(edited added removed))
        (vc-dir-mark-state-files state))
      (message "All changes staged"))

    (defun vc-dir-amend-commit ()
      "Amend the last commit, including currently staged changes."
      (interactive)
      (let ((files (vc-dir-marked-files)))
        (if files
            (vc-modify-change-comment nil)
          (user-error "No staged files; stage files with s or S first"))))

    ;; ---- 导航 (h/j/k/l 同 Dired) ----
    (define-key vc-dir-mode-map (kbd "h") #'vc-dir-previous-line)
    (define-key vc-dir-mode-map (kbd "j") #'vc-dir-next-line)
    (define-key vc-dir-mode-map (kbd "k") #'vc-dir-previous-line)
    (define-key vc-dir-mode-map (kbd "l") #'vc-dir-find-file)

    ;; ---- Stage (s = 单个文件, S = 全部) ----
    (define-key vc-dir-mode-map (kbd "s")  #'vc-dir-mark)
    (define-key vc-dir-mode-map (kbd "S")  #'vc-dir-stage-all)

    ;; ---- Amend ----
    (define-key vc-dir-mode-map (kbd "A")  #'vc-dir-amend-commit)

    ;; ---- Commit prefix (c c = commit, c a = amend) ----
    (defvar vc-dir-commit-prefix-map
      (let ((map (make-sparse-keymap)))
        (define-key map (kbd "c") #'vc-next-action)
        (define-key map (kbd "a") #'vc-dir-amend-commit)
        map)
      "Commit-related keymap under `c` prefix in vc-dir.")
    (define-key vc-dir-mode-map (kbd "c") vc-dir-commit-prefix-map)

    (defun vc-dir-current-should-skip-p ()
      "判断当前行是否需要跳过。"
      (when vc-ewoc
        (let* ((node (ewoc-locate vc-ewoc))
               (data (ewoc-data node)))
          (when data
            (or (vc-dir-fileinfo->directory data)
                (eq (vc-dir-fileinfo->state data) 'up-to-date))))))

    (defun vc-dir-move-and-diff (move-fn wrap-pos)
      "移动到下一个文件并显示 diff。"
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
      (save-selected-window
        (vc-diff)))

    (defun vc-dir-next-and-diff ()
      "移动到下一个修改文件并 diff。"
      (interactive)
      (vc-dir-move-and-diff #'vc-dir-next-line (point-min)))

    (defun vc-dir-prev-and-diff ()
      "移动到上一个修改文件并 diff。"
      (interactive)
      (vc-dir-move-and-diff #'vc-dir-previous-line (point-max)))

    (defun vc-dir-quick-commit-all ()
      "标记所有修改的文件并提交。"
      (interactive)
      (vc-dir-unmark-all-files 1)
      (dolist (state '(edited added removed))
        (vc-dir-mark-state-files state))
      (let ((files (vc-dir-marked-files)))
        (if files
            (vc-next-action nil)
          (message "No files to commit")))))

  ;; vc-change-log 显示在当前窗口
  (add-to-list 'display-buffer-alist
               '("\\*vc-change-log\\*\\|\\*VC-log\\*"
                 (display-buffer-same-window)))
  ;; 其他 vc buffer 显示在右侧
  (add-to-list 'display-buffer-alist
               '("\\*vc-\\|\\*VC-\\|\\*cvs\\|COMMIT_EDITMSG"
                 (display-buffer-in-side-window)
                 (side . right)
                 (window-width . 0.5)
                 (slot . 0))))

(provide 'init-vcs)
;;; init-vcs.el ends here
