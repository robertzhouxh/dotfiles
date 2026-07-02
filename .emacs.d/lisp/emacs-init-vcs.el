;;; init-vcs.el --- 版本控制配置 -*- lexical-binding: t; -*-
;;; │ VC
(use-package vc
  :ensure nil
  :defer t
  :config
  (setopt
   vc-auto-revert-mode t                    ; EMACS-31
   vc-allow-rewriting-published-history t   ; EMACS-31
   vc-git-diff-switches '("--patch-with-stat" "--histogram")  ;; add stats to `git diff'
   vc-git-log-switches '("--stat")                            ;; add stats to `git log'
   vc-git-log-edit-summary-target-len 50
   vc-git-log-edit-summary-max-len 70
   vc-git-print-log-follow t
   vc-git-revision-complete-only-branches nil
   vc-git-show-stash 0                                        ;; do not polute vc-dir with stash lines
   vc-annotate-display-mode 'scale
   add-log-keep-changes-together t
   vc-dir-auto-hide-up-to-date   t          ; EMACS-31
   vc-make-backup-files nil)                                  ;; do not backup version controlled files

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

  ;; This one is for editing commit messages
  (require 'log-edit)
  (setopt log-edit-confirm 'changed
          log-edit-keep-buffer nil
          log-edit-require-final-newline t
          log-edit-setup-add-author nil)

  ;; Removes the bottom window with modified files list
  (remove-hook 'log-edit-hook #'log-edit-show-files)

  (with-eval-after-load 'vc-dir
    ;; In vc-git and vc-dir for git buffers, make (C-x v) a run git add, u run git
    ;; reset, and r run git reset and checkout from head.
    (defun emacs-solo/vc-git-command (verb fn)
      "Execute a Git command with VERB as action and FN as operations."
      (let* ((fileset (vc-deduce-fileset t)) ;; Deduce fileset
             (backend (car fileset))
             (files (nth 1 fileset)))
        (if (eq backend 'Git)
            (progn
              (funcall fn files)
              (message ">>> emacs-solo: %s %d file(s)." verb (length files)))
          (message ">>> emacs-solo: Not in a VC Git buffer."))))

    (defun emacs-solo/vc-git-add (&optional _revision _vc-fileset _comment)
      (interactive "P")
      (emacs-solo/vc-git-command "Staged" 'vc-git-register))

    (defun emacs-solo/vc-git-reset (&optional _revision _vc-fileset _comment)
      (interactive "P")
      (emacs-solo/vc-git-command "Unstaged"
                                 (lambda (files) (vc-git-command nil 0 files "reset" "-q" "--")))))


  (defun emacs-solo/vc-git-visualize-status ()
    "Show the Git status of files in the `vc-log` buffer."
    (interactive)
    (let* ((fileset (vc-deduce-fileset t))
           (backend (car fileset)))
      (if (eq backend 'Git)
          (let ((output-buffer "*Git Status*"))
            (with-current-buffer (get-buffer-create output-buffer)
              (read-only-mode -1)
              (erase-buffer)
              ;; Capture the raw output including colors using 'git status --color=auto'
              (call-process "git" nil output-buffer nil "status" "-v")
              (pop-to-buffer output-buffer)))
        (message ">>> emacs-solo: Not in a VC Git buffer."))))


  (defun emacs-solo/vc-git-reflog ()
    "Show git reflog in a new buffer with ANSI colors and custom keybindings."
    (interactive)
    (let* ((root (vc-root-dir)) ;; Capture VC root before creating buffer
           (buffer (get-buffer-create "*vc-git-reflog*")))
      (with-current-buffer buffer
        (setq-local vc-git-reflog-root root) ;; Store VC root as a buffer-local variable
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
    "Pull the from origin for the current branch and display output in a buffer."
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
If CURRENT-LINE is non-nil, point to the current branch, file, and line.
Otherwise, open the repository's main page."
    (interactive "P")
    (let* ((remote-url (string-trim (vc-git--run-command-string nil "config" "--get" "remote.origin.url")))
           (branch (string-trim (vc-git--run-command-string nil "rev-parse" "--abbrev-ref" "HEAD")))
           (file (string-trim (file-relative-name (buffer-file-name) (vc-root-dir))))
           (line (line-number-at-pos)))
      (message ">>> emacs-solo: Opening remote on browser %s" remote-url)
      (if (and remote-url (string-match "\\(?:git@\\|https://\\)\\([^:/]+\\)[:/]\\(.+?\\)\\(?:\\.git\\)?$" remote-url))
          (let ((host (match-string 1 remote-url))
                (path (match-string 2 remote-url)))
            ;; Convert SSH URLs to HTTPS (e.g., git@github.com:user/repo.git -> https://github.com/user/repo)
            (when (string-prefix-p "git@" host)
              (setq host (replace-regexp-in-string "^git@" "" host)))
            ;; Construct the appropriate URL based on CURRENT-LINE
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
      (vc-diff) ; Generate the diff buffer
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
                (goto-char (match-beginning 0))))) ; Jump to the beginning of the hunk
          (unless found-hunk
            (message ">>> emacs-solo: Current line %d is not within any hunk range." current-line)
            (goto-char (point-min)))))))


  (defun emacs-solo/switch-git-status-buffer ()
    "Switch to a buffer visiting a modified or renamed file in the current Git repo.
The completion candidates include the Git status of each file."
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
                         ;; Renamed files
                         ((string-prefix-p "R" status)
                          (let* ((paths (split-string path-info " -> " t))
                                 (new-path (cadr paths)))
                            (when new-path
                              (push (cons (format "R %s" new-path) new-path) files))))
                         ;; Modified or untracked
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


  ;; For *vc-dir* buffer:
  (with-eval-after-load 'vc-dir
    (define-key vc-dir-mode-map (kbd "S") #'emacs-solo/vc-git-add)
    (define-key vc-dir-mode-map (kbd "U") #'emacs-solo/vc-git-reset)
    (define-key vc-dir-mode-map (kbd "V") #'emacs-solo/vc-git-visualize-status)
    (define-key vc-dir-mode-map (kbd "R") emacs-solo/vc-rebase-map)
    ;; Bind g to hide up to date files after refreshing in vc-dir

    ;; NOTE: this won't be needed once EMACS-31 gets released: vc-dir-hide-up-to-date-on-revert does that
    (define-key vc-dir-mode-map (kbd "g")
                (lambda () (interactive) (vc-dir-refresh) (vc-dir-hide-up-to-date))))


  ;; For C-x v ... bindings:
  (define-key vc-prefix-map (kbd "S") #'emacs-solo/vc-git-add)
  (define-key vc-prefix-map (kbd "U") #'emacs-solo/vc-git-reset)
  (define-key vc-prefix-map (kbd "V") #'emacs-solo/vc-git-visualize-status)
  (define-key vc-prefix-map (kbd "R") emacs-solo/vc-rebase-map)
  (define-key vc-prefix-map (kbd "B") #'emacs-solo/vc-browse-remote)
  (define-key vc-prefix-map (kbd "o") #'(lambda () (interactive) (emacs-solo/vc-browse-remote 1)))
  (define-key vc-prefix-map (kbd "=") #'emacs-solo/vc-diff-on-current-hunk)

  ;; Switch-buffer between modified files
  (global-set-key (kbd "C-x C-g") 'emacs-solo/switch-git-status-buffer))

(provide 'emacs-init-vcs)
;;; init-vcs.el ends here
