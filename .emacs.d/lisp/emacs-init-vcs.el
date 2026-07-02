;;; emacs-init-vcs.el --- 版本控制配置 -*- lexical-binding: t; -*-

(use-package vc
  :ensure nil
  :defer t
  :config

  ;; ── 基础设置 ────────────────────────────────────────────────────────────────

  (setopt
   vc-auto-revert-mode               t      ; Emacs 31
   vc-allow-rewriting-published-history t   ; Emacs 31
   vc-dir-auto-hide-up-to-date       t      ; Emacs 31
   vc-git-diff-switches    '("--patch-with-stat" "--histogram")
   vc-git-log-switches     '("--stat")
   vc-git-log-edit-summary-target-len 50
   vc-git-log-edit-summary-max-len    70
   vc-git-print-log-follow t
   vc-git-revision-complete-only-branches nil
   vc-git-show-stash       0
   vc-annotate-display-mode 'scale
   add-log-keep-changes-together t
   vc-make-backup-files    nil)

  (with-eval-after-load 'vc-annotate
    (setopt vc-annotate-color-map
            '((20  . "#c3e88d") (40  . "#89ddff") (60  . "#82aaff")
              (80  . "#676e95") (100 . "#c792ea") (120 . "#f78c6c")
              (140 . "#79a8ff") (160 . "#f5e0dc") (180 . "#a6e3a1")
              (200 . "#94e2d5") (220 . "#89dceb") (240 . "#74c7ec")
              (260 . "#82aaff") (280 . "#b4befe") (300 . "#b5b0ff")
              (320 . "#8c9eff") (340 . "#6a81ff") (360 . "#5c6bd7"))))

  (require 'log-edit)
  (setopt log-edit-confirm              'changed
          log-edit-keep-buffer          nil
          log-edit-require-final-newline t
          log-edit-setup-add-author     nil)
  (remove-hook 'log-edit-hook #'log-edit-show-files)

  ;; ── 核心：统一刷新 ──────────────────────────────────────────────────────────
  ;;
  ;; vc-dir-refresh-files 是 Emacs 29+ 公开 API，走 Git dir-status-files
  ;; 异步路径，和 g 键效果一致但只更新指定文件。
  ;; 必须先 vc-file-clearprops 清缓存，否则 backend 可能直接读缓存返回旧值。

  (defun emacs-solo/vc-refresh-after-git-op (files)
    "清除 FILES 的 VC 缓存，然后 revert 所有包含这些文件的 vc-dir buffer。"
    (mapc #'vc-file-clearprops files)
    (dolist (buf (buffer-list))
      (when (buffer-live-p buf)
        (with-current-buffer buf
          (when (and (derived-mode-p 'vc-dir-mode)
                     (cl-some (lambda (f)
                                (file-in-directory-p f default-directory))
                              files))
            (revert-buffer t t))))))

  ;; ── Stage / Unstage ─────────────────────────────────────────────────────────

  (defun emacs-solo/vc-git-command (verb fn)
    "对当前 fileset 执行 Git 操作 FN，完成后刷新 vc-dir。VERB 用于 minibuffer 提示。"
    (let* ((fileset (vc-deduce-fileset t))
           (backend (car fileset))
           (files   (nth 1 fileset)))
      (if (eq backend 'Git)
          (progn
            (funcall fn files)
            (emacs-solo/vc-refresh-after-git-op files)
            (message "%s %d file(s)." verb (length files)))
        (message "Not in a VC Git buffer."))))

  (defun emacs-solo/vc-git-add (&optional _r _f _c)
    "Stage 当前文件或已标记文件 (git add)。"
    (interactive "P")
    (emacs-solo/vc-git-command "Staged" #'vc-git-register))

  (defun emacs-solo/vc-git-reset (&optional _r _f _c)
    "Unstage 当前文件或已标记文件 (git reset)。"
    (interactive "P")
    (emacs-solo/vc-git-command
     "Unstaged"
     (lambda (files) (vc-git-command nil 0 files "reset" "-q" "--"))))

  ;; ── Git 输出缓冲区 ──────────────────────────────────────────────────────────

  (defun emacs-solo/vc-git-visualize-status ()
    "在专用 buffer 中显示 git status -v。"
    (interactive)
    (let ((buf  (get-buffer-create "*Git Status*"))
          (root (or (vc-root-dir) default-directory)))
      (with-current-buffer buf
        (let ((inhibit-read-only t)
              (default-directory root))
          (erase-buffer)
          (call-process "git" nil buf nil "status" "-v"))
        (setq buffer-read-only t))
      (pop-to-buffer buf)))

  (defun emacs-solo/vc-git-reflog ()
    "在专用 buffer 中显示 git reflog（含 ANSI 颜色）。"
    (interactive)
    (let ((buf  (get-buffer-create "*vc-git-reflog*"))
          (root (vc-root-dir)))
      (with-current-buffer buf
        (let ((inhibit-read-only t)
              (default-directory (or root default-directory)))
          (erase-buffer)
          (vc-git-command buf nil nil
                          "reflog" "--color=always"
                          "--pretty=format:%C(yellow)%h%Creset %C(auto)%d%Creset \
%Cgreen%gd%Creset %s %Cblue(%cr)%Creset")
          (goto-char (point-min))
          (ansi-color-apply-on-region (point-min) (point-max)))
        (setq buffer-read-only t
              mode-name         "Git-Reflog"
              major-mode        'special-mode)
        (let ((map (make-sparse-keymap)))
          (define-key map (kbd "/") #'isearch-forward)
          (define-key map (kbd "p") #'previous-line)
          (define-key map (kbd "n") #'next-line)
          (define-key map (kbd "q") #'kill-buffer-and-window)
          (use-local-map map)))
      (pop-to-buffer buf)))

  ;; ── Rebase ──────────────────────────────────────────────────────────────────

  (defun emacs-solo/vc-git-compile (git-cmd)
    "在 repo 根目录执行 git GIT-CMD，输出显示在 compilation buffer。"
    (let ((default-directory (or (vc-root-dir) default-directory)))
      (compilation-start (concat "git " git-cmd) 'compilation-mode
                         (lambda (_) "*vc-git*"))))

  (defun emacs-solo/vc-rebase (rev)
    "Rebase 当前分支到 REV。"
    (interactive (list (vc-read-revision "Rebase onto: ")))
    (emacs-solo/vc-git-compile (format "rebase %s" rev)))

  (defvar-keymap emacs-solo/vc-rebase-map
    :doc "Rebase 及 reflog 快捷键。"
    "R" #'emacs-solo/vc-rebase
    "c" (lambda () (interactive) (emacs-solo/vc-git-compile "rebase --continue"))
    "a" (lambda () (interactive) (emacs-solo/vc-git-compile "rebase --abort"))
    "s" (lambda () (interactive) (emacs-solo/vc-git-compile "rebase --skip"))
    "l" #'emacs-solo/vc-git-reflog)

  ;; ── Pull ────────────────────────────────────────────────────────────────────

  (defun emacs-solo/vc-pull-merge-current-branch ()
    "Pull origin/<当前分支>，输出显示在专用 buffer。"
    (interactive)
    (let* ((branch (string-trim
                    (vc-git--run-command-string nil "rev-parse" "--abbrev-ref" "HEAD")))
           (cmd    (format "git pull origin %s" branch))
           (buf    (get-buffer-create "*Git Pull Output*")))
      (if (string-empty-p branch)
          (message "Could not determine current branch.")
        (with-current-buffer buf
          (erase-buffer)
          (insert (format "$ %s\n\n" cmd))
          (call-process-shell-command cmd nil buf t))
        (display-buffer buf))))

  ;; ── Browse remote ───────────────────────────────────────────────────────────

  (defun emacs-solo/vc-browse-remote (&optional current-line)
    "在浏览器中打开远程仓库主页；CURRENT-LINE 非 nil 时定位到当前文件及行号。"
    (interactive "P")
    (let* ((remote (string-trim
                    (vc-git--run-command-string nil "config" "--get" "remote.origin.url")))
           (branch (string-trim
                    (vc-git--run-command-string nil "rev-parse" "--abbrev-ref" "HEAD")))
           (file   (when (buffer-file-name)
                     (file-relative-name (buffer-file-name) (vc-root-dir))))
           (line   (line-number-at-pos)))
      (if (string-match
           "\\(?:git@\\|https://\\)\\([^:/]+\\)[:/]\\(.+?\\)\\(?:\\.git\\)?$" remote)
          (let ((host (match-string 1 remote))
                (path (match-string 2 remote)))
            (when (string-prefix-p "git@" host)
              (setq host (replace-regexp-in-string "^git@" "" host)))
            (browse-url
             (if (and current-line file)
                 (format "https://%s/%s/blob/%s/%s#L%d" host path branch file line)
               (format "https://%s/%s" host path))))
        (message "Could not determine repository URL."))))

  ;; ── Diff hunk ───────────────────────────────────────────────────────────────

  (defun emacs-solo/vc-diff-on-current-hunk ()
    "打开 vc-diff，并跳转到当前行所在的 hunk。"
    (interactive)
    (let ((target-line (line-number-at-pos)))
      (vc-diff)
      (with-current-buffer "*vc-diff*"
        (goto-char (point-min))
        (let (found)
          (while (and (not found)
                      (re-search-forward
                       "^@@ -[0-9]+,?[0-9]* \\+\\([0-9]+\\),?\\([0-9]*\\) @@" nil t))
            (let* ((start (string-to-number (match-string 1)))
                   (cnt   (let ((s (match-string 2)))
                            (if (string-empty-p s) 1 (string-to-number s)))))
              (when (and (>= target-line start) (<= target-line (+ start cnt)))
                (setq found t)
                (goto-char (match-beginning 0)))))
          (unless found (goto-char (point-min)))))))

  ;; ── Switch to modified file ─────────────────────────────────────────────────

  (defun emacs-solo/switch-git-status-buffer ()
    "补全跳转到当前 Git 仓库中已修改或未跟踪的文件。"
    (interactive)
    (require 'vc-git)
    (let ((root (vc-git-root default-directory)))
      (unless root (user-error "Not inside a Git repository"))
      (let* ((root       (expand-file-name root))
             (candidates
              (delq nil
                    (mapcar
                     (lambda (line)
                       (when (>= (length line) 3)
                         (let ((status (substring line 0 2))
                               (path   (substring line 3)))
                           (cond
                            ((string-prefix-p "R" status)
                             (when-let ((new (cadr (split-string path " -> " t))))
                               (cons (format "R  %s" new) new)))
                            ((string-match-p "[M?]" status)
                             (cons (format "%s %s" status path) path))))))
                     (split-string
                      (vc-git--run-command-string nil "status" "--porcelain=v1")
                      "\n" t)))))
        (if (null candidates)
            (message "No modified or untracked files.")
          (when-let* ((sel  (completing-read "Git modified: "
                                             (mapcar #'car candidates) nil t))
                      (file (cdr (assoc sel candidates))))
            (find-file (expand-file-name file root)))))))

  ;; ── 键绑定 ──────────────────────────────────────────────────────────────────

  (with-eval-after-load 'vc-dir
    (define-key vc-dir-mode-map (kbd "S") #'emacs-solo/vc-git-add)
    (define-key vc-dir-mode-map (kbd "U") #'emacs-solo/vc-git-reset)
    (define-key vc-dir-mode-map (kbd "V") #'emacs-solo/vc-git-visualize-status)
    (define-key vc-dir-mode-map (kbd "R") emacs-solo/vc-rebase-map)
    (define-key vc-dir-mode-map (kbd "g")
                (lambda () (interactive) (vc-dir-refresh) (vc-dir-hide-up-to-date))))

  (define-key vc-prefix-map (kbd "S") #'emacs-solo/vc-git-add)
  (define-key vc-prefix-map (kbd "U") #'emacs-solo/vc-git-reset)
  (define-key vc-prefix-map (kbd "V") #'emacs-solo/vc-git-visualize-status)
  (define-key vc-prefix-map (kbd "R") emacs-solo/vc-rebase-map)
  (define-key vc-prefix-map (kbd "B") #'emacs-solo/vc-browse-remote)
  (define-key vc-prefix-map (kbd "o")
              (lambda () (interactive) (emacs-solo/vc-browse-remote 1)))
  (define-key vc-prefix-map (kbd "=") #'emacs-solo/vc-diff-on-current-hunk)

  (global-set-key (kbd "C-x C-g") #'emacs-solo/switch-git-status-buffer))

(provide 'emacs-init-vcs)
;;; emacs-init-vcs.el ends here
