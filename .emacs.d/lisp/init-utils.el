;;; init-utils.el --- Utilities borrowed from Steve Purcell
;;; Commentary:
;;; Code:

;;----------------------------------------------------------------------------
;; awesome trick cool
;;----------------------------------------------------------------------------
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

;;----------------------------------------------------------------------------
;; manage window
;;----------------------------------------------------------------------------
;(defun x-split-window-right ()
;  "Split window with another buffer."
;  (interactive)
;  (select-window (split-window-right))
;  (switch-to-buffer (other-buffer)))
;
;(defun x-split-window-below ()
;  "Split window with another buffer."
;  (interactive)
;  (select-window (split-window-below))
;  (switch-to-buffer (other-buffer)))

(defun revert-all-buffers ()
  (interactive)
  (dolist (buf (buffer-list))
    (with-current-buffer buf
                         (when (buffer-file-name)
                           (revert-buffer t t t)))))

;(defun vsplit-last-buffer ()
;  (interactive)
;  (split-window-vertically)
;  (other-window 1 nil)
;  (switch-to-next-buffer)
;  )
;(defun hsplit-last-buffer ()
;  (interactive)
;  (split-window-horizontally)
;  (other-window 1 nil)
;  (switch-to-next-buffer)
;  )

;; spawn shell
(defun x/eshell-here ()
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
(defun x/eshell-x ()
  (interactive)
  (insert "exit")
  (eshell-send-input)
  (delete-window))

(defun x/drop-project-cache ()
  "invalidate projectile cache if it is currently active"
  (when (and (featurep 'projectile)
             (projectile-project-p))
    (call-interactively #'projectile-invalidate-cache)))

;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;; 	Insert Src Block
;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
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

(provide 'init-utils)
