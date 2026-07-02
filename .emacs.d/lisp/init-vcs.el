;;; init-vcs.el --- 版本控制配置 -*- lexical-binding: t; -*-

;;; │ VC ─ 通用配置
(use-package vc
  :ensure nil
  :defer t
  :custom
  (vc-handled-backends '(Git))
  (vc-follow-symlinks t)
  :config
  (setopt
   vc-auto-revert-mode t
   vc-allow-rewriting-published-history t
   vc-git-diff-switches '("--patch-with-stat" "--histogram")
   vc-git-log-switches '("--stat")
   vc-git-log-edit-summary-target-len 50
   vc-git-log-edit-summary-max-len 70
   vc-git-print-log-follow t
   vc-git-revision-complete-only-branches nil
   vc-git-show-stash 0
   vc-annotate-display-mode 'scale
   add-log-keep-changes-together t
   vc-dir-auto-hide-up-to-date t
   vc-make-backup-files nil)

  ;; ---- vc-annotate 配色 ----
  (with-eval-after-load 'vc-annotate
    (setopt vc-annotate-color-map
            '((20 . "#c3e88d")
              (40 . "#89ddff")
              (60 . "#82aaff")
              (80 . "#676e95")
              (100 . "#c792ea")
              (120 . "#f78c6c")
              (140 . "#79a8ff")
              (160 . "#f5e0dc")
              (180 . "#a6e3a1")
              (200 . "#94e2d5")
              (220 . "#89dceb")
              (240 . "#74c7ec")
              (260 . "#82aaff")
              (280 . "#b4befe")
              (300 . "#b5b0ff")
              (320 . "#8c9eff")
              (340 . "#6a81ff")
              (360 . "#5c6bd7"))))

  ;; ---- log-edit 提交消息编辑 ----
  (with-eval-after-load 'log-edit
    (setopt log-edit-confirm 'changed
            log-edit-keep-buffer nil
            log-edit-require-final-newline t
            log-edit-setup-add-author nil)
    (remove-hook 'log-edit-hook #'log-edit-show-files))

  ;; ---- display-buffer 规则 ----
  (add-to-list 'display-buffer-alist
               '("\\*vc-change-log\\*\\|\\*VC-log\\*"
                 (display-buffer-same-window)))
  (add-to-list 'display-buffer-alist
               '("\\*vc-\\|\\*VC-\\|\\*cvs\\|COMMIT_EDITMSG"
                 (display-buffer-in-side-window)
                 (side . right)
                 (window-width . 0.5)
                 (slot . 0)))

  ;; ---- Git 命令工具 ----
  (defun emacs-solo/vc-git-command (verb fn)
    "Execute a Git command with VERB as action and FN as operations."
    (let* ((fileset (vc-deduce-fileset t))
           (backend (car fileset))
           (files (nth 1 fileset)))
      (if (eq backend 'Git)
          (progn
            (funcall fn files)
            (message ">>> emacs-solo: %s %d file(s)." verb (length files)))
        (message ">>> emacs-solo: Not in a VC Git buffer."))))

  (defun emacs-solo/vc-git-add (&optional _revision _vc-fileset _comment)
    "Stage files under point in VC Git buffers."
    (interactive "P")
    (emacs-solo/vc-git-command "Staged" 'vc-git-register))

  (defun emacs-solo/vc-git-reset (&optional _revision _vc-fileset _comment)
    "Unstage files under point in VC Git buffers."
    (interactive "P")
    (emacs-solo/vc-git-command "Unstaged"
                               (lambda (files) (vc-git-command nil 0 files "reset" "-q" "--"))))

  (defun emacs-solo/vc-git-visualize-status ()
    "Show the Git status of files in the `vc-log' buffer."
    (interactive)
    (let* ((fileset (vc-deduce-fileset t))
           (backend (car fileset)))
      (if (eq backend 'Git)
          (let ((output-buffer "*Git Status*"))
            (with-current-buffer (get-buffer-create output-buffer)
              (read-only-mode -1)
              (erase-buffer)
              (call-process "git" nil output-buffer nil "status" "-v")
              (pop-to-buffer output-buffer)))
        (message ">>> emacs-solo: Not in a VC Git buffer."))))

  (defun emacs-solo/vc-git-reflog ()
    "Show git reflog in a new buffer with ANSI colors."
    (interactive)
    (let* ((root (vc-root-dir))
           (buffer (get-buffer-create "*vc-git-reflog*")))
      (with-current-buffer buffer
        (setq-local vc-git-reflog-root root)
        (let ((inhibit-read-only t))
          (erase-buffer)
          (vc-git-command buffer nil nil
                          "reflog"
                          "--color=always"
                          "--pretty=format:%C(yellow)%h%Creset %C(auto)%d%Creset %Cgreen%gd%Creset %s %Cblue(%cr)%Creset")
          (goto-char (point-min))
          (ansi-color-apply-on-region (point-min) (point-max)))
        (let ((map (make-sparse-keymap)))
          (define-key map (kbd "/") #'isearch-forward)
          (define-key map (kbd "p") #'previous-line)
          (define-key map (kbd "n") #'next-line)
          (define-key map (kbd "q") #'kill-buffer-and-window)
          (use-local-map map))
        (setq buffer-read-only t)
        (setq mode-name "Git-Reflog")
        (setq major-mode 'special-mode))
      (pop-to-buffer buffer)))

  ;; ---- Rebase 命令 ----
  (defun emacs-solo/vc-rebase (rev)
    "Rebase current VC branch onto REV."
    (interactive (list (vc-read-revision "Rebase onto: ")))
    (let* ((dir (vc-root-dir))
           (backend (vc-responsible-backend dir)))
      (unless (eq backend 'Git)
        (user-error "Rebase not supported for backend %s" backend))
      (let ((default-directory dir))
        (compilation-start (format "git rebase %s" rev)
                           'compilation-mode
                           (lambda (_) "*vc-rebase*")))))

  (defun emacs-solo/vc-rebase-continue ()
    "Continue current Git rebase."
    (interactive)
    (let ((default-directory (vc-root-dir)))
      (compile "git rebase --continue")))

  (defun emacs-solo/vc-rebase-abort ()
    "Abort current Git rebase."
    (interactive)
    (let ((default-directory (vc-root-dir)))
      (compile "git rebase --abort")))

  (defun emacs-solo/vc-rebase-skip ()
    "Skip current Git rebase commit."
    (interactive)
    (let ((default-directory (vc-root-dir)))
      (compile "git rebase --skip")))

  (defvar-keymap emacs-solo/vc-rebase-map
    :doc "Keymap for VC rebase commands and reflog."
    "R" #'emacs-solo/vc-rebase
    "c" #'emacs-solo/vc-rebase-continue
    "a" #'emacs-solo/vc-rebase-abort
    "s" #'emacs-solo/vc-rebase-skip
    "l" #'emacs-solo/vc-git-reflog)

  (defun emacs-solo/vc-pull-merge-current-branch ()
    "Pull the from origin for the current branch and display output."
    (interactive)
    (let* ((branch (vc-git--symbolic-ref "HEAD"))
           (buffer (get-buffer-create "*Git Pull Output*"))
           (command (format "git pull origin %s" branch)))
      (if branch
          (progn
            (with-current-buffer buffer
              (erase-buffer)
              (insert (format "$ %s\n\n" command))
              (call-process-shell-command command nil buffer t))
            (display-buffer buffer))
        (message ">>> emacs-solo: Could not determine current branch."))))

  (defun emacs-solo/vc-browse-remote (&optional current-line)
    "Open the repository's remote URL in the browser.
If CURRENT-LINE is non-nil, point to the current branch, file, and line."
    (interactive "P")
    (let* ((remote-url (string-trim (vc-git--run-command-string nil "config" "--get" "remote.origin.url")))
           (branch (string-trim (vc-git--run-command-string nil "rev-parse" "--abbrev-ref" "HEAD")))
           (file (string-trim (file-relative-name (buffer-file-name) (vc-root-dir))))
           (line (line-number-at-pos)))
      (message ">>> emacs-solo: Opening remote on browser %s" remote-url)
      (if (and remote-url (string-match "\\(?:git@\\|https://\\)\\([^:/]+\\)[:/]\\(.+?\\)\\(?:\\.git\\)?$" remote-url))
          (let ((host (match-string 1 remote-url))
                (path (match-string 2 remote-url)))
            (when (string-prefix-p "git@" host)
              (setq host (replace-regexp-in-string "^git@" "" host)))
            (browse-url
             (if current-line
                 (format "https://%s/%s/blob/%s/%s#L%d" host path branch file line)
               (format "https://%s/%s" host path))))
        (message ">>> emacs-solo: Could not determine repository URL"))))

  (defun emacs-solo/vc-diff-on-current-hunk ()
    "Open diff jumping to the current hunk."
    (interactive)
    (let ((current-line (line-number-at-pos)))
      (message ">>> emacs-solo: Current line in file %d" current-line)
      (vc-diff)
      (with-current-buffer "*vc-diff*"
        (goto-char (point-min))
        (let ((found-hunk nil))
          (while (and (not found-hunk)
                      (re-search-forward "^@@ -\\([0-9]+\\), *[0-9]+ \\+\\([0-9]+\\), *\\([0-9]+\\) @@" nil t))
            (let* ((start-line (string-to-number (match-string 2)))
                   (line-count (string-to-number (match-string 3)))
                   (end-line (+ start-line line-count)))
              (message ">>> emacs-solo: Found hunk %d to %d" start-line end-line)
              (when (and (>= current-line start-line)
                         (<= current-line end-line))
                (message ">>> emacs-solo: Current line %d is within hunk range %d to %d" current-line start-line end-line)
                (setq found-hunk t)
                (goto-char (match-beginning 0)))))
          (unless found-hunk
            (message ">>> emacs-solo: Current line %d is not within any hunk range." current-line)
            (goto-char (point-min)))))))

  (defun emacs-solo/switch-git-status-buffer ()
    "Switch to a buffer visiting a modified or renamed file in the current Git repo."
    (interactive)
    (require 'vc-git)
    (let ((repo-root (vc-git-root default-directory)))
      (if (not repo-root)
          (message ">>> emacs-solo: Not inside a Git repository.")
        (let* ((expanded-root (expand-file-name repo-root))
               (cmd-output (vc-git--run-command-string nil "status" "--porcelain=v1"))
               (target-files
                (let (files)
                  (dolist (line (split-string cmd-output "\n" t) (nreverse files))
                    (when (>= (length line) 3)
                      (let ((status (substring line 0 2))
                            (path-info (substring line 3)))
                        (cond
                         ((string-prefix-p "R" status)
                          (let* ((paths (split-string path-info " -> " t))
                                 (new-path (cadr paths)))
                            (when new-path
                              (push (cons (format "R %s" new-path) new-path) files))))
                         ((or (string-match "M" status)
                              (string-match "\\?\\?" status))
                          (push (cons (format "%s %s" status path-info) path-info) files)))))))))
          (if (null target-files)
              (message ">>> emacs-solo: No modified or renamed files found.")
            (let* ((candidates target-files)
                   (selection (completing-read "Switch to buffer (Git modified): "
                                               (mapcar #'car candidates) nil t)))
              (when selection
                (let ((file-path (cdr (assoc selection candidates))))
                  (when file-path
                    (find-file (expand-file-name file-path expanded-root)))))))))))

  ;; ---- C-x v 前缀绑定（函数/变量均已定义完毕） ----
  (define-key vc-prefix-map (kbd "S") #'emacs-solo/vc-git-add)
  (define-key vc-prefix-map (kbd "U") #'emacs-solo/vc-git-reset)
  (define-key vc-prefix-map (kbd "V") #'emacs-solo/vc-git-visualize-status)
  (define-key vc-prefix-map (kbd "R") emacs-solo/vc-rebase-map)
  (define-key vc-prefix-map (kbd "B") #'emacs-solo/vc-browse-remote)
  (define-key vc-prefix-map (kbd "o") (lambda () (interactive) (emacs-solo/vc-browse-remote 1)))
  (define-key vc-prefix-map (kbd "=") #'emacs-solo/vc-diff-on-current-hunk)

  ;; ---- 全局快捷键 ----
  (global-set-key (kbd "C-x C-g") 'emacs-solo/switch-git-status-buffer))

;;; │ VC-Dir ─ Magit 风格快捷键
(use-package vc-dir
  :ensure nil
  :after vc
  :hook (vc-dir-mode . evil-emacs-state)
  :init
  (when (featurep 'evil)
    (evil-set-initial-state 'vc-dir-mode 'emacs))
  :config
  ;; ---- 导航 (h/j/k/l 同 Dired) ----
  (define-key vc-dir-mode-map (kbd "h") #'vc-dir-previous-line)
  (define-key vc-dir-mode-map (kbd "j") #'vc-dir-next-line)
  (define-key vc-dir-mode-map (kbd "k") #'vc-dir-previous-line)
  (define-key vc-dir-mode-map (kbd "l") #'vc-dir-find-file)

  ;; ---- Stage ----
  (define-key vc-dir-mode-map (kbd "s") #'vc-dir-mark)
  (define-key vc-dir-mode-map (kbd "S") #'emacs-solo/vc-git-add)
  (define-key vc-dir-mode-map (kbd "U") #'emacs-solo/vc-git-reset)
  (define-key vc-dir-mode-map (kbd "V") #'emacs-solo/vc-git-visualize-status)

  ;; ---- Rebase prefix ----
  (define-key vc-dir-mode-map (kbd "R") emacs-solo/vc-rebase-map)

  ;; ---- Amend ----
  (define-key vc-dir-mode-map (kbd "A") #'vc-dir-amend-commit)

  ;; ---- Refresh + hide up-to-date ----
  (define-key vc-dir-mode-map (kbd "g")
              (lambda () (interactive) (vc-dir-refresh) (vc-dir-hide-up-to-date)))

  ;; ---- Commit prefix (c c = commit, c a = amend) ----
  (defvar vc-dir-commit-prefix-map
    (let ((map (make-sparse-keymap)))
      (define-key map (kbd "c") #'vc-next-action)
      (define-key map (kbd "a") #'vc-dir-amend-commit)
      map)
    "Commit-related keymap under `c` prefix in vc-dir.")
  (define-key vc-dir-mode-map (kbd "c") vc-dir-commit-prefix-map)

  ;; ---- 命令 ----
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

(provide 'init-vcs)
;;; init-vcs.el ends here
