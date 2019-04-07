;;; init-utils.el --- Utilities borrowed from Steve Purcell
;;; Commentary:
;;; Code:

(defun untabify-buffer ()
  (interactive)
  (untabify (point-min) (point-max)))

(defun indent-buffer ()
  (interactive)
  (indent-region (point-min) (point-max)))

(defun cleanup-buffer ()
  "Perform a bunch of operations on the whitespace content of a buffer."
  (interactive)
  (indent-buffer)
  (untabify-buffer)
  (delete-trailing-whitespace))

(defun sudo-edit-current-file ()
  (interactive)
  (let ((my-file-name) ; fill this with the file to open
        (position))    ; if the file is already open save position
    (if (equal major-mode 'dired-mode) ; test if we are in dired-mode
      (progn
        (setq my-file-name (dired-get-file-for-visit))
        (find-alternate-file (prepare-tramp-sudo-string my-file-name)))
      (setq my-file-name (buffer-file-name); hopefully anything else is an already opened file
            position (point))
      (find-alternate-file (prepare-tramp-sudo-string my-file-name))
      (goto-char position))))

(defun create-new-empty-buffer ()
  "Open a new empty buffer."
  (interactive)
  (let ((buf (generate-new-buffer "untitled")))
    (switch-to-buffer buf)
    (funcall (and initial-major-mode))
    (setq buffer-offer-save t)))

(defun put-todays-date ()
  (interactive)
  (insert (shell-command-to-string "todays-date")))

(defun delete-this-buffer-and-file ()
  "Removes file connected to current buffer and kills buffer."
  (interactive)
  (let ((filename (buffer-file-name))
        (buffer (current-buffer))
        (name (buffer-name)))
    (if (not (and filename (file-exists-p filename)))
      (error "Buffer '%s' is not visiting a file!" name)
      (when (yes-or-no-p "Are you sure you want to remove this file? ")
        (delete-file filename)
        (kill-buffer buffer)
        (message "File '%s' successfully removed" filename)))))

(defun delete-this-file ()
  "Delete the current file, and kill the buffer."
  (interactive)
  (or (buffer-file-name) (error "No file is currently being edited"))
  (when (yes-or-no-p (format "Really delete '%s'?"
                             (file-name-nondirectory buffer-file-name)))
    (delete-file (buffer-file-name))
    (kill-this-buffer)))

(defun rename-this-file-and-buffer (new-name)
  "Renames both current buffer and file it's visiting to NEW-NAME."
  (interactive "sNew name: ")
  (let ((name (buffer-name))
        (filename (buffer-file-name)))
    (unless filename
      (error "Buffer '%s' is not visiting a file!" name))
    (if (get-buffer new-name)
      (message "A buffer named '%s' already exists!" new-name)
      (progn
        (when (file-exists-p filename)
          (rename-file filename new-name 1))
        (rename-buffer new-name)
        (set-visited-file-name new-name)))))

(defun browse-current-file ()
  "Open the current file as a URL using `browse-url'."
  (interactive)
  (let ((file-name (buffer-file-name)))
    (if (tramp-tramp-file-p file-name)
      (error "Cannot open tramp file")
      (browse-url (concat "file://" file-name)))))

(defun switch-to-previous-buffer ()
  "Switch to previously open buffer.
  Repeated invocations toggle between the two most recently open buffers."
  (interactive)
  (switch-to-buffer (other-buffer (current-buffer) 1)))

(defun my-align-single-equals ()
  "Align on the first single equal sign."
  (interactive)
  (align-regexp
    (region-beginning) (region-end)
    "\\(\\s-*\\)=" 1 1 nil))


;;----------------------------------------------------------------------------
;; awesome trick cool
;;----------------------------------------------------------------------------
(defun load-local (filename)
  ;; (let ((file (s-concat (f-expand filename user-emacs-directory) ".el")))
  (let ((file (s-concat (f-expand filename robertzhouxh/config-dir) ".el")))
    (if (f-exists? file)
      (load-file file))))

(defun my/insert-lod ()
  "Well. This is disappointing."
  (interactive)
  (insert "ಠ_ಠ"))

(defun system-is-mac ()
  (interactive)
  (string-equal system-type "darwin"))

(defun system-is-linux ()
  (interactive)
  (string-equal system-type "gnu/linux"))

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

(defmacro after (mode &rest body)
  "`eval-after-load' `MODE', wrapping `BODY' in `progn'."
  (declare (indent defun))
  (let ((s (if (symbolp mode)
             (symbol-name mode)
             mode)))
    `(eval-after-load ,(symbol-name mode)
                      (quote (progn ,@body)))))

(defun scan-code-tags ()
  "Scan code tags: @TODO: , @FIXME:, @BUG:, @NOTE:."
  (interactive)
  (split-window-horizontally)
  (occur "@FIXME:\\|@TODO:\\|@BUG:\\|@NOTE:"))

(defun python/scan-functions ()
  (interactive)
  (split-window-horizontally)
  (occur "def"))

;; Usage: M-x reload-init-file
;;
(defun reload-init-file ()
  "Reload init.el file."
  (interactive)
  (load user-init-file)
  (message "Reloaded init.el OK."))

;; Usage: M-x open-init-file
;;
(defun open-init-file ()
  (interactive)
  (find-file user-init-file))

(defun dired-touch ()
  "Creates empty file at current directory."
  (interactive)
  (append-to-file "" nil (read-string "New file: "))
  (if (equal major-mode 'dired-mode)
    (revert-buffer)))

;; Edit File as Root   utils edit
(defun open-as-root (filename)
  (interactive)
  (find-file (concat "/sudo:root@localhost:"  filename)))

(defun open-buffer-as-root ()
  (interactive)
  (let
    (
     ;; Get the current buffer file name
     (filename (buffer-file-name (current-buffer)))
     ;; Get the current file name
     (bufname  (buffer-name (current-buffer)))
     )
    (progn
      (kill-buffer bufname)         ;; Kill current buffer
      (open-as-root filename))))    ;; Open File as root


;This comamnd can be bound to a keybiding with the code bellow that bidns the key combination SUPER (Windows Key) + 8.
(defun shell-launch ()
  "Launch a process without creating a buffer. It is useful to launch apps from Emacs."
  (interactive)
  (let* ((cmd-raw  (read-shell-command "Launch command: "))
         (cmd-args (split-string-and-unquote cmd-raw))
         (cmd      (car cmd-args))       ;; program that will run
         (args     (cdr cmd-args)))     ;; command arguments
    (apply #'start-process `(,cmd
                              nil
                              ,cmd ,@args
                              ))))

;;Read a command in launch in terminal
;; This command uses xfce4-terminal but it can be changed to any other terminal emulator.
(defun run-terminal ()
  "Launch application in a terminal emulator."
  (interactive)
  (start-process
    "iTerm"
    nil
    ;; Change this for your terminal.
    "iTerm" "-e" (read-shell-command "Shell: ")))

;;Launch specific commands
(defun shell-command-in-terminal (command)
  (start-process
    "iTerm"
    nil
    ;; Change this for your terminal.
    "iTerm" "-e" command))

(defun sh/scratch ()
  (interactive)
  (let ( (buf (get-buffer-create "*sh-scratch*")))
    ;; Executes functions that would change the current buffer at
    ;; buffer buf
    (with-current-buffer buf
                         ;;; Set the new buffer to scratch mode
                         (sh-mode)
                         ;;; Pop to scratch buffer
                         (pop-to-buffer buf))))

(defun select-current-word ()
  "Select the word under cursor.
  “word” here is considered any alphanumeric sequence with “_” or “-”."
  (interactive)
  (let (pt)
    (skip-chars-backward "-_A-Za-z0-9")
    (setq pt (point))
    (skip-chars-forward "-_A-Za-z0-9")
    (set-mark pt)))

;;----------------------------------------------------------------------------
;; manage window
;;----------------------------------------------------------------------------
(defun x-split-window-right ()
  "Split window with another buffer."
  (interactive)
  (select-window (split-window-right))
  (switch-to-buffer (other-buffer)))

(defun x-split-window-below ()
  "Split window with another buffer."
  (interactive)
  (select-window (split-window-below))
  (switch-to-buffer (other-buffer)))

(defun revert-all-buffers ()
  (interactive)
  (dolist (buf (buffer-list))
    (with-current-buffer buf
                         (when (buffer-file-name)
                           (revert-buffer t t t)))))

(defun vsplit-last-buffer ()
  (interactive)
  (split-window-vertically)
  (other-window 1 nil)
  (switch-to-next-buffer)
  )
(defun hsplit-last-buffer ()
  (interactive)
  (split-window-horizontally)
  (other-window 1 nil)
  (switch-to-next-buffer)
  )

;; spawn shell
(defun eshell-here ()
  "Opens up a new shell in the directory associated with the
current buffer's file. The eshell is renamed to match that
directory to make multiple eshell windows easier."
  (interactive)
  (let* ((parent (if (buffer-file-name)
                     (file-name-directory (buffer-file-name))
                   default-directory))
         (height (/ (window-total-height) 3))
         (name   (car (last (split-string parent "/" t)))))
    (split-window-vertically (- height))
    (other-window 1)
    (eshell "new")
    (rename-buffer (concat "*eshell: " name "*"))

    (insert (concat "ls"))
    (eshell-send-input)))

;; exit shell
(defun eshell-x ()
  (interactive)
  (insert "exit")
  (eshell-send-input)
  (delete-window))

;; Automatically save on loss of focus.
(defun save-all ()
  "Save all file-visiting buffers without prompting."
  (interactive)
  (save-some-buffers t) ;; Do not prompt for confirmation.
  )

(defun jc/switch-to-previous-buffer ()
  "Switch to previously open buffer.
  Repeated invocations toggle between the two most recently open buffers."
  (interactive)
  (switch-to-buffer (other-buffer (current-buffer) 1)))

(provide 'init-utils)
;;; init-utils.el ends here
