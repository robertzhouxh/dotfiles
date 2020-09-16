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



;; some cool funtions

(defalias 'pr #'point-to-register)
(defun my-switch-to-register ()
  "Switch to buffer given by a register named by last character
of the key binding used to execute this command."
  (interactive)
  (let* ((v (this-command-keys-vector))
         (c (aref v (1- (length v))))
         (r (get-register c)))
    (if (and (markerp r) (marker-buffer r))
        (switch-to-buffer (marker-buffer r))
      (jump-to-register c))))

(setq my-switch-to-register-map (make-sparse-keymap))

(dolist (character (number-sequence ?a ?z))
  (define-key my-switch-to-register-map
    (char-to-string character) #'my-switch-to-register))

(global-set-key (kbd "H-r") my-switch-to-register-map)


(setq my-browsers
      '(("Firefox" . browse-url-firefox)
        ("Chromium" . browse-url-chromium)
        ("EWW" . eww-browse-url)))

(defun my-browse-url (&rest args)
  "Select the prefered browser from a menu before opening the URL."
  (interactive)
  (let ((browser (ivy-read "WWW browser: " my-browsers :require-match t)))
    (apply (cdr (assoc browser my-browsers)) args)))

(setq browse-url-browser-function #'my-browse-url)

(defun my-eww-scale-adjust ()
  "Slightly bigger font but text shorter than text."
  (interactive)
  (text-scale-adjust 0)
  (text-scale-adjust 1)
  (eww-toggle-fonts)
  (split-window-right)
  (eww-toggle-fonts)
  (other-window 1)
  (sleep-for 1)
  (delete-window))

(defalias 'pr #'point-to-register)
(defun my-switch-to-register ()
  "Switch to buffer given by a register named by last character
of the key binding used to execute this command."
  (interactive)
  (let* ((v (this-command-keys-vector))
         (c (aref v (1- (length v))))
         (r (get-register c)))
    (if (and (markerp r) (marker-buffer r))
        (switch-to-buffer (marker-buffer r))
      (jump-to-register c))))

(setq my-switch-to-register-map (make-sparse-keymap))

(dolist (character (number-sequence ?a ?z))
  (define-key my-switch-to-register-map
    (char-to-string character) #'my-switch-to-register))

(global-set-key (kbd "H-r") my-switch-to-register-map)


(setq my-browsers
      '(("Firefox" . browse-url-firefox)
        ("Chromium" . browse-url-chromium)
        ("EWW" . eww-browse-url)))

(defun my-browse-url (&rest args)
  "Select the prefered browser from a menu before opening the URL."
  (interactive)
  (let ((browser (ivy-read "WWW browser: " my-browsers :require-match t)))
    (apply (cdr (assoc browser my-browsers)) args)))

(setq browse-url-browser-function #'my-browse-url)

(defun my-eww-scale-adjust ()
  "Slightly bigger font but text shorter than text."
  (interactive)
  (text-scale-adjust 0)
  (text-scale-adjust 1)
  (eww-toggle-fonts)
  (split-window-right)
  (eww-toggle-fonts)
  (other-window 1)
  (sleep-for 1)
  (delete-window))
(defalias 'pr #'point-to-register)
(defun my-switch-to-register ()
  "Switch to buffer given by a register named by last character
of the key binding used to execute this command."
  (interactive)
  (let* ((v (this-command-keys-vector))
         (c (aref v (1- (length v))))
         (r (get-register c)))
    (if (and (markerp r) (marker-buffer r))
        (switch-to-buffer (marker-buffer r))
      (jump-to-register c))))

(setq my-switch-to-register-map (make-sparse-keymap))

(dolist (character (number-sequence ?a ?z))
  (define-key my-switch-to-register-map
    (char-to-string character) #'my-switch-to-register))

(global-set-key (kbd "H-r") my-switch-to-register-map)


(setq my-browsers
      '(("Firefox" . browse-url-firefox)
        ("Chromium" . browse-url-chromium)
        ("EWW" . eww-browse-url)))

(defun my-browse-url (&rest args)
  "Select the prefered browser from a menu before opening the URL."
  (interactive)
  (let ((browser (ivy-read "WWW browser: " my-browsers :require-match t)))
    (apply (cdr (assoc browser my-browsers)) args)))

(setq browse-url-browser-function #'my-browse-url)

(defun my-eww-scale-adjust ()
  "Slightly bigger font but text shorter than text."
  (interactive)
  (text-scale-adjust 0)
  (text-scale-adjust 1)
  (eww-toggle-fonts)
  (split-window-right)
  (eww-toggle-fonts)
  (other-window 1)
  (sleep-for 1)
  (delete-window))
(defalias 'pr #'point-to-register)
(defun my-switch-to-register ()
  "Switch to buffer given by a register named by last character
of the key binding used to execute this command."
  (interactive)
  (let* ((v (this-command-keys-vector))
         (c (aref v (1- (length v))))
         (r (get-register c)))
    (if (and (markerp r) (marker-buffer r))
        (switch-to-buffer (marker-buffer r))
      (jump-to-register c))))

(setq my-switch-to-register-map (make-sparse-keymap))

(dolist (character (number-sequence ?a ?z))
  (define-key my-switch-to-register-map
    (char-to-string character) #'my-switch-to-register))

(global-set-key (kbd "H-r") my-switch-to-register-map)


(setq my-browsers
      '(("Firefox" . browse-url-firefox)
        ("Chromium" . browse-url-chromium)
        ("EWW" . eww-browse-url)))

(defun my-browse-url (&rest args)
  "Select the prefered browser from a menu before opening the URL."
  (interactive)
  (let ((browser (ivy-read "WWW browser: " my-browsers :require-match t)))
    (apply (cdr (assoc browser my-browsers)) args)))

(setq browse-url-browser-function #'my-browse-url)

(defun my-eww-scale-adjust ()
  "Slightly bigger font but text shorter than text."
  (interactive)
  (text-scale-adjust 0)
  (text-scale-adjust 1)
  (eww-toggle-fonts)
  (split-window-right)
  (eww-toggle-fonts)
  (other-window 1)
  (sleep-for 1)
  (delete-window))
(defalias 'pr #'point-to-register)
(defun my-switch-to-register ()
  "Switch to buffer given by a register named by last character
of the key binding used to execute this command."
  (interactive)
  (let* ((v (this-command-keys-vector))
         (c (aref v (1- (length v))))
         (r (get-register c)))
    (if (and (markerp r) (marker-buffer r))
        (switch-to-buffer (marker-buffer r))
      (jump-to-register c))))

(setq my-switch-to-register-map (make-sparse-keymap))

(dolist (character (number-sequence ?a ?z))
  (define-key my-switch-to-register-map
    (char-to-string character) #'my-switch-to-register))

(global-set-key (kbd "H-r") my-switch-to-register-map)


(setq my-browsers
      '(("Firefox" . browse-url-firefox)
        ("Chromium" . browse-url-chromium)
        ("EWW" . eww-browse-url)))

(defun my-browse-url (&rest args)
  "Select the prefered browser from a menu before opening the URL."
  (interactive)
  (let ((browser (ivy-read "WWW browser: " my-browsers :require-match t)))
    (apply (cdr (assoc browser my-browsers)) args)))

(setq browse-url-browser-function #'my-browse-url)

(defun my-eww-scale-adjust ()
  "Slightly bigger font but text shorter than text."
  (interactive)
  (text-scale-adjust 0)
  (text-scale-adjust 1)
  (eww-toggle-fonts)
  (split-window-right)
  (eww-toggle-fonts)
  (other-window 1)
  (sleep-for 1)
  (delete-window))


(provide 'init-utils)
