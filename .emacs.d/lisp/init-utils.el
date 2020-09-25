;;; init-utils.el --- Utilities borrowed from Steve Purcell
;;; Commentary:
;;; Code:

(defun x/recompile-elpa ()
  "Recompile packages in elpa directory. Useful if you switch Emacs versions."
  (interactive)
  (byte-recompile-directory package-user-dir nil t))

(defun x/save-all ()
  "Save all file-visiting buffers without prompting."
  (interactive)
  (save-some-buffers t))

(defun x/close-all-buffers ()
  (interactive)
  (mapc 'kill-buffer (buffer-list)))

(defun x/open-init-file ()
  (interactive)
  (find-file user-init-file))

(defun x/reload-init-file ()
  "Reload init.el file."
  (interactive)
  (load user-init-file)
  (message "Reloaded init.el OK."))

(defun x/system-is-mac ()
  (interactive)
  (string-equal system-type "darwin"))

(defun x/system-is-linux ()
  (interactive)
  (string-equal system-type "gnu/linux"))

(defun system-is-mac ()
  (eq system-type 'darwin))

(defun hold-line-scroll-up ()
  "Scroll the page with the cursor in the same line"
  (interactive)
  ;; move the cursor also
  (let ((tmp (current-column)))
    (scroll-up 1)
    (line-move-to-column tmp)
    (forward-line 1)))

(defun hold-line-scroll-down ()
  "Scroll the page with the cursor in the same line"
  (interactive)
  ;; move the cursor also
  (let ((tmp (current-column)))
    (scroll-down 1)
    (line-move-to-column tmp)
    (forward-line -1)))

(defun scan-code-tags ()
  "Scan code tags: @TODO: , @FIXME:, @BUG:, @NOTE:."
  (interactive)
  (split-window-horizontally)
  (occur "@FIXME:\\|@TODO:\\|@BUG:\\|@NOTE:"))

(defun dired-touch ()
  "Creates empty file at current directory."
  (interactive)
  (append-to-file "" nil (read-string "New file: "))
  (if (equal major-mode 'dired-mode)
    (revert-buffer)))

(defun select-current-word ()
  "Select the word under cursor.
  “word” here is considered any alphanumeric sequence with “_” or “-”."
  (interactive)
  (let (pt)
    (skip-chars-backward "-_A-Za-z0-9")
    (setq pt (point))
    (skip-chars-forward "-_A-Za-z0-9")
    (set-mark pt)))

;; manage window
(defun revert-all-buffers ()
  (interactive)
  (dolist (buf (buffer-list))
    (with-current-buffer buf
                         (when (buffer-file-name)
                           (revert-buffer t t t)))))

(defun x/drop-project-cache ()
  "invalidate projectile cache if it is currently active"
  (when (and (featurep 'projectile)
             (projectile-project-p))
    (call-interactively #'projectile-invalidate-cache)))

;; Insert Src Block
(use-package ido-completing-read+)
(defun pkg-insert-src-block (src-code-type)
  "Insert a `SRC-CODE-TYPE' type source code block in org-mode."
  (interactive
    (let ((src-code-types
            '("emacs-lisp" "python" "C" "sh" "java" "js" "clojure" "C++" "css"
              "calc" "asymptote" "dot" "gnuplot" "ledger" "lilypond" "mscgen"
              "octave" "oz" "plantuml" "R" "sass" "screen" "sql" "awk" "ditaa"
              "haskell" "latex" "lisp" "matlab" "ocaml" "org" "perl" "ruby"
              "scheme" "sqlite" "html")))
      (list (ido-completing-read+ "Source code type: " src-code-types))))
  (progn
    (newline-and-indent)
    (insert (format "#+BEGIN_SRC %s\n" src-code-type))
    (newline-and-indent)
    (insert "#+END_SRC\n")
    (previous-line 2)
    (org-edit-src-code)))


;;; Some Cool Funtions

(defun generate-scratch-buffer ()
  "Create and switch to a temporary scratch buffer with a random
     name."
  (interactive)
  (switch-to-buffer (make-temp-name "scratch-")))

(defun sudo ()
  "Use TRAMP to `sudo' the current buffer"
  (interactive)
  (when buffer-file-name
    (find-alternate-file
     (concat "/sudo:root@localhost:"
             buffer-file-name))))

(defun replace-token (token)
  "Replace JSON web token for requests"
  (interactive "sEnter the new token: ")
  (save-excursion
    (goto-char (point-min))
    (while (re-search-forward "Bearer .*\"" nil t)
      (replace-match (concat "Bearer " token "\"")))))

;; source: http://steve.yegge.googlepages.com/my-dot-emacs-file
(defun rename-file-and-buffer (new-name)
  "Renames both current buffer and file it's visiting to NEW-NAME."
  (interactive "sNew name: ")
  (let ((name (buffer-name))
        (filename (buffer-file-name)))
    (if (not filename)
        (message "Buffer '%s' is not visiting a file!" name)
      (if (get-buffer new-name)
          (message "A buffer named '%s' already exists!" new-name)
        (progn
          (rename-file filename new-name 1)
          (rename-buffer new-name)
          (set-visited-file-name new-name)
          (set-buffer-modified-p nil))))))

(defun rename-local-var (name)
  (interactive "sEnter new name: ")
  (let ((var (word-at-point)))
    (mark-defun)
    (replace-string var name nil (region-beginning) (region-end))))

(defun increment-number-at-point ()
  (interactive)
  (skip-chars-backward "0-9")
  (or (looking-at "[0-9]+")
      (error "No number at point"))
  (replace-match (number-to-string (1+ (string-to-number (match-string 0))))))

(defun decrement-number-at-point ()
  (interactive)
  (skip-chars-backward "0-9")
  (or (looking-at "[0-9]+")
      (error "No number at point"))
  (replace-match (number-to-string (- (string-to-number (match-string 0)) 1))))

(defun email-selection ()
  (interactive)
  (copy-region-as-kill (region-beginning) (region-end))
  (let ((tmp-file (concat "/tmp/" (buffer-name (current-buffer))))
        (recipient (read-string "Enter a recipient: "))
        (subject (read-string "Enter a subject: ")))
    (find-file tmp-file)
    (yank)
    (save-buffer)
    (kill-buffer (current-buffer))
    (shell-command (concat "mutt -s \"" subject "\" " recipient " < " tmp-file))
    (shell-command (concat "rm -f " tmp-file)))
  (message "Sent!"))

(defun move-file ()
  "Write this file to a new location, and delete the old one."
  (interactive)
  (let ((old-location (buffer-file-name)))
    (call-interactively #'write-file)
    (when old-location
      (delete-file old-location))))

(defun format-function-parameters ()
  "Turn the list of function parameters into multiline."
  (interactive)
  (beginning-of-line)
  (search-forward "(" (line-end-position))
  (newline-and-indent)
  (while (search-forward "," (line-end-position) t)
    (newline-and-indent))
  (end-of-line)
  (c-hungry-delete-forward)
  (insert " ")
  (search-backward ")")
  (newline-and-indent))

(defun eshell-here ()
  "Opens up a new shell in the directory associated with the
    current buffer's file. The eshell is renamed to match that
    directory to make multiple eshell windows easier."
  (interactive)
  (let* ((height (/ (window-total-height) 3)))
    (split-window-vertically (- height))
    (other-window 1)
    (eshell "new")
    (insert (concat "ls"))
    (eshell-send-input)))

(bind-key "C-!" 'eshell-here)

(add-hook 'git-commit-setup-hook
    '(lambda ()
        (let ((has-ticket-title (string-match "^[A-Z]+-[0-9]+"
                                    (magit-get-current-branch)))
              (words (s-split-words (magit-get-current-branch))))
          (if has-ticket-title
              (insert (format "[%s-%s] " (car words) (car (cdr words))))))))

(defun what-the-commit ()
  (interactive)
  (insert
   (with-current-buffer
       (url-retrieve-synchronously "http://whatthecommit.com")
     (re-search-backward "<p>\\([^<]+\\)\n<\/p>")
     (match-string 1))))

(defun insta-kill-buffer ()
  (interactive)
  (kill-buffer))
(global-set-key (kbd "C-z") 'insta-kill-buffer)

(defun toggle-presentation ()
  "Toggle presentation features, like font increase."
  (interactive)
  (let ((regular-fontsize 140)
        (presentation-fontsize 240))
    (if (equal (face-attribute 'default :height) regular-fontsize)
        (set-face-attribute 'default nil :height presentation-fontsize)
      (set-face-attribute 'default nil :height regular-fontsize))))

;;Quick custom function to integrate with the moq tool to generate quick mocks
(defun moq ()
  (interactive)
  (let ((interface (word-at-point))
        (test-file (concat (downcase (word-at-point)) "_test.go")))
    (shell-command
     (concat "moq -out " test-file " . " interface))
    (find-file test-file)))

;;-------------------------- Esehll -----------------------------
(use-package eshell
  :init
  (setq eshell-scroll-to-bottom-on-input 'all
        eshell-error-if-no-glob t
        eshell-hist-ignoredups t
        eshell-save-history-on-exit t
        eshell-prefer-lisp-functions nil
        eshell-destroy-buffer-when-process-dies t))

;; Fancy prompt
(setq eshell-prompt-function
      (lambda ()
        (concat
         (propertize "┌─[" 'face `(:foreground "green"))
         (propertize (user-login-name) 'face `(:foreground "red"))
         (propertize "@" 'face `(:foreground "green"))
         (propertize (system-name) 'face `(:foreground "lightblue"))
         (propertize "]──[" 'face `(:foreground "green"))
         (propertize (format-time-string "%H:%M" (current-time)) 'face `(:foreground "yellow"))
         (propertize "]──[" 'face `(:foreground "green"))
         (propertize (concat (eshell/pwd)) 'face `(:foreground "white"))
         (propertize "]\n" 'face `(:foreground "green"))
         (propertize "└─>" 'face `(:foreground "green"))
         (propertize (if (= (user-uid) 0) " # " " $ ") 'face `(:foreground "green"))
         )))

;; Define visual commands and subcommands
(setq eshell-visual-commands '("htop" "vi" "screen" "top" "less"
                               "more" "lynx" "ncftp" "pine" "tin" "trn" "elm"
                               "vim"))

(setq eshell-visual-subcommands '("git" "log" "diff" "show" "ssh"))

;; Pager setup
(setenv "PAGER" "cat")

(use-package eshell-autojump)

(defalias 'ff 'find-file)
(defalias 'd 'dired)

(defun eshell/clear ()
  (let ((inhibit-read-only t))
    (erase-buffer)))

;; Git
(defun eshell/gst (&rest args)
    (magit-status (pop args) nil)
    (eshell/echo))   ;; The echo command suppresses output

;; Bargs and Sargs
(defun eshell/-buffer-as-args (buffer separator command)
  "Takes the contents of BUFFER, and splits it on SEPARATOR, and
runs the COMMAND with the contents as arguments. Use an argument
`%' to substitute the contents at a particular point, otherwise,
they are appended."
  (let* ((lines (with-current-buffer buffer
                  (split-string
                   (buffer-substring-no-properties (point-min) (point-max))
                   separator)))
         (subcmd (if (-contains? command "%")
                     (-flatten (-replace "%" lines command))
                   (-concat command lines)))
         (cmd-str  (string-join subcmd " ")))
    (message cmd-str)
    (eshell-command-result cmd-str)))

(defun eshell/bargs (buffer &rest command)
  "Passes the lines from BUFFER as arguments to COMMAND."
  (eshell/-buffer-as-args buffer "\n" command))

(defun eshell/sargs (buffer &rest command)
  "Passes the words from BUFFER as arguments to COMMAND."
  (eshell/-buffer-as-args buffer nil command))

(defun eshell/close ()
  (delete-window))

(add-hook 'eshell-mode-hook
          (lambda ()
            (define-key eshell-mode-map (kbd "C-M-a") 'eshell-previous-prompt)
            (define-key eshell-mode-map (kbd "C-M-e") 'eshell-next-prompt)))

(defun eshell-pop--kill-and-delete-window ()
  (unless (one-window-p)
    (delete-window)))

(add-hook 'eshell-exit-hook 'eshell-pop--kill-and-delete-window)

(provide 'init-utils)
