;;; emacs-init-vcs.el --- 版本控制配置 (Emacs 31) -*- lexical-binding: t; -*-

(use-package vc
  :ensure nil
  :defer t
  :config

  ;; ── Emacs 31 新特性 ────────────────────────────────────────────────────────────
  ;;
  ;; vc-auto-revert-mode: 自动 revert VC 管理文件的外部变更
  ;; vc-allow-rewriting-published-history: 允许/询问重写已发布历史
  ;; vc-dir-auto-hide-up-to-date: 自动隐藏 vc-dir 中 up-to-date 文件
  ;; vc-pull-and-push: 内置 pull+push 命令
  ;; project-vc-*-cache-timeout: VC-aware project backend 缓存

  (setopt
   vc-auto-revert-mode               t       ; Emacs 31: 自动 revert
   vc-allow-rewriting-published-history t     ; Emacs 31: 允许重写历史
   vc-dir-auto-hide-up-to-date       t       ; Emacs 31: 自动隐藏已同步文件
   vc-git-diff-switches    '("--patch-with-stat" "--histogram")
   vc-git-log-switches     '("--stat")
   vc-git-log-edit-summary-target-len 50
   vc-git-log-edit-summary-max-len    70
   vc-git-print-log-follow t                 ; log 跟随重命名
   vc-git-revision-complete-only-branches nil ; 补全时显示 tag
   vc-git-show-stash       0                 ; 在 vc-dir 中显示 stash 数量 (0=不显示)
   vc-annotate-display-mode 'scale           ; 按最旧提交缩放颜色
   vc-make-backup-files    nil)

  ;; vc-auto-revert-mode 是全局 minor mode，直接开启
  (when (fboundp 'vc-auto-revert-mode)
    (vc-auto-revert-mode 1))

  ;; VC-aware project backend 缓存 (Emacs 31)
  (with-eval-after-load 'project
    (when (boundp 'project-vc-cache-timeout)
      (setopt project-vc-cache-timeout 60))
    (when (boundp 'project-vc-non-essential-cache-timeout)
      (setopt project-vc-non-essential-cache-timeout 300)))

  ;; ── annotate 配色 ──────────────────────────────────────────────────────────────

  (with-eval-after-load 'vc-annotate
    (setopt vc-annotate-color-map
            '((20  . "#c3e88d") (40  . "#89ddff") (60  . "#82aaff")
              (80  . "#676e95") (100 . "#c792ea") (120 . "#f78c6c")
              (140 . "#79a8ff") (160 . "#f5e0dc") (180 . "#a6e3a1")
              (200 . "#94e2d5") (220 . "#89dceb") (240 . "#74c7ec")
              (260 . "#82aaff") (280 . "#b4befe") (300 . "#b5b0ff")
              (320 . "#8c9eff") (340 . "#6a81ff") (360 . "#5c6bd7"))))

  ;; ── log-edit (提交信息编辑) ────────────────────────────────────────────────────

  (require 'log-edit)
  (setopt log-edit-confirm              'changed
          log-edit-keep-buffer          nil
          log-edit-require-final-newline t
          log-edit-setup-add-author     nil)
  (remove-hook 'log-edit-hook #'log-edit-show-files)

  ;; ── 核心：刷新 vc-dir ─────────────────────────────────────────────────────────
  ;;
  ;; vc-dir-refresh-files 是 Emacs 29+ 公开 API，走 Git dir-status-files
  ;; 异步路径，只更新指定文件，比 revert-buffer 更高效精准。
  ;; 必须先 vc-file-clearprops 清缓存，否则 backend 可能直接读缓存返回旧值。

  (defun emacs-solo/vc-refresh-after-git-op (files)
    "清除 FILES 的 VC 缓存，然后刷新所有关联 vc-dir buffer 中的这些文件。"
    (mapc #'vc-file-clearprops files)
    (dolist (buf (buffer-list))
      (when (buffer-live-p buf)
        (with-current-buffer buf
          (when (derived-mode-p 'vc-dir-mode)
            (let ((relevant (cl-remove-if-not
                             (lambda (f) (file-in-directory-p f default-directory))
                             files)))
              (when relevant
                (vc-dir-refresh-files relevant))))))))

  ;; ── Stage / Unstage ───────────────────────────────────────────────────────────

  (defun emacs-solo/vc-git-command (verb fn)
    "对当前 fileset 执行 Git 操作 FN，完成后刷新 vc-dir。
VERB 用于 minibuffer 提示（如 \"Staged\"、\"Unstaged\"）。
FN 接收 files 列表作为唯一参数。"
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

  ;; ── Git 输出缓冲区 ────────────────────────────────────────────────────────────

  (defun emacs-solo/vc-git-visualize-status ()
    "在专用 buffer 中显示 git status -v（含未暂存 diff）。"
    (interactive)
    (let ((buf  (get-buffer-create "*Git Status*"))
          (root (or (vc-root-dir) default-directory)))
      (with-current-buffer buf
        (let ((inhibit-read-only t)
              (default-directory root))
          (erase-buffer)
          (call-process "git" nil buf nil "status" "-v"))
        (setq buffer-read-only t)
        (special-mode))
      (pop-to-buffer buf)))

  (defun emacs-solo/vc-git-reflog ()
    "在专用 buffer 中显示 git reflog（含 ANSI 颜色）。
格式：短 hash + 分支/标签 + reflog 名称 + 提交信息 + 相对时间。"
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

  ;; ── Rebase ────────────────────────────────────────────────────────────────────

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

  ;; ── Pull / Push ───────────────────────────────────────────────────────────────

  (defun emacs-solo/vc-pull-merge-current-branch ()
    "Pull origin/<当前分支>，输出显示在专用 buffer。"
    (interactive)
    (let ((branch (vc-git-working-branch))
          (root   (vc-root-dir)))
      (if (or (null branch) (string-empty-p branch))
          (message "Could not determine current branch.")
        (let* ((cmd (format "git pull origin %s" branch))
               (buf (get-buffer-create "*Git Pull Output*"))
               (default-directory (or root default-directory)))
          (with-current-buffer buf
            (let ((inhibit-read-only t))
              (erase-buffer)
              (insert (format "$ %s\n\n" cmd))
              (call-process-shell-command cmd nil buf t))
            (special-mode))
          (display-buffer buf)))))

  (defun emacs-solo/vc-push-current-branch ()
    "Push 当前分支到 origin。使用 `vc-pull-and-push'（Emacs 31 内置）的 push 部分。"
    (interactive)
    (let ((default-directory (or (vc-root-dir) default-directory)))
      (vc-git-push nil)))

  ;; ── Browse remote ─────────────────────────────────────────────────────────────

  (defun emacs-solo/vc-browse-remote (&optional current-line)
    "在浏览器中打开远程仓库主页。
不带前缀参数：打开仓库首页。
带前缀参数 CURRENT-LINE：定位到当前文件及行号。"
    (interactive "P")
    (let* ((repo-url (vc-git-repository-url
                      (or (vc-root-dir) default-directory)))
           (branch  (vc-git-working-branch))
           (file    (when (buffer-file-name)
                      (file-relative-name (buffer-file-name)
                                          (vc-root-dir))))
           (line    (line-number-at-pos)))
      (if (null repo-url)
          (message "Could not determine repository URL.")
        ;; vc-git-repository-url 已经返回 https 格式
        (browse-url
         (if (and current-line file branch)
             (format "%s/blob/%s/%s#L%d" repo-url branch file line)
           repo-url)))))

  ;; ── Diff hunk ─────────────────────────────────────────────────────────────────

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

  ;; ── Switch to modified file ───────────────────────────────────────────────────

  (defun emacs-solo/switch-git-status-buffer ()
    "补全跳转到当前 Git 仓库中已修改或未跟踪的文件。
使用 `vc-git--run-command-string' 解析 git status --porcelain=v1，
这是获取仓库文件状态最直接的方式（无等价公开 API）。"
    (interactive)
    (require 'vc-git)
    (let ((root (vc-git-root default-directory)))
      (unless root (user-error "Not inside a Git repository"))
      (let* ((root (expand-file-name root))
             (candidates
              (delq nil
                    (mapcar
                     (lambda (line)
                       (when (>= (length line) 3)
                         (let ((status (substring line 0 2))
                               (path   (substring line 3)))
                           (cond
                            ((string-prefix-p "R" status)
                             (when-let* ((new (cadr (split-string path " -> " t))))
                               (cons (format "R  %s" new) new)))
                            ((string-match-p "[M?]" status)
                             (cons (format "%s %s" status path) path))))))
                     (split-string
                      (vc-git--run-command-string nil "status" "--porcelain=v1")
                      "\n" t)))))
        (if (null candidates)
            (message "No modified or untracked files.")
          (when-let* ((sel  (completing-read "Git modified: "
                                             (mapc #'car candidates) nil t))
                      (file (cdr (assoc sel candidates))))
            (find-file (expand-file-name file root)))))))

  ;; ── 键绑定 ────────────────────────────────────────────────────────────────────

  ;; vc-dir-mode 中的快捷键
  (with-eval-after-load 'vc-dir
    (define-key vc-dir-mode-map (kbd "S") #'emacs-solo/vc-git-add)
    (define-key vc-dir-mode-map (kbd "U") #'emacs-solo/vc-git-reset)
    (define-key vc-dir-mode-map (kbd "V") #'emacs-solo/vc-git-visualize-status)
    (define-key vc-dir-mode-map (kbd "R") emacs-solo/vc-rebase-map)
    (define-key vc-dir-mode-map (kbd "P") #'vc-pull-and-push)  ; Emacs 31
    (define-key vc-dir-mode-map (kbd "g")
                (lambda () (interactive) (vc-dir-refresh) (vc-dir-hide-up-to-date))))

  ;; 全局 vc-prefix-map (C-x v) 快捷键
  (define-key vc-prefix-map (kbd "S") #'emacs-solo/vc-git-add)
  (define-key vc-prefix-map (kbd "U") #'emacs-solo/vc-git-reset)
  (define-key vc-prefix-map (kbd "V") #'emacs-solo/vc-git-visualize-status)
  (define-key vc-prefix-map (kbd "R") emacs-solo/vc-rebase-map)
  (define-key vc-prefix-map (kbd "B") #'emacs-solo/vc-browse-remote)
  (define-key vc-prefix-map (kbd "o")
              (lambda () (interactive) (emacs-solo/vc-browse-remote 1)))
  (define-key vc-prefix-map (kbd "=") #'emacs-solo/vc-diff-on-current-hunk)

  ;; 全局快捷键
  (global-set-key (kbd "C-x C-g") #'emacs-solo/switch-git-status-buffer))

(provide 'emacs-init-vcs)
;;; emacs-init-vcs.el ends here
