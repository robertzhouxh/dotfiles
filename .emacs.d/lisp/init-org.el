;;; init-org.el --- Set up Org Mode
;;; Commentary:

;; org basic settings
(use-package org-evil)

;; https://justinbarclay.me/posts/literate_programming_against_rest_apis/
(use-package org
  :ensure org-plus-contrib
  :bind
  (("C-c a" . org-agenda)
   ("C-c c" . org-capture)
   ("C-c C-v C-c" . jb/org-clear-results))
  :init
  (progn
    (global-unset-key "\C-c\C-v\C-c")
    (defun jb/org-narrow-to-parent ()
      "Narrow buffer to the current subtree."
      (interactive)
      (widen)
      (org-up-element)
      (save-excursion
        (save-match-data
          (org-with-limited-levels
           (narrow-to-region
            (progn
              (org-back-to-heading t) (point))
            (progn (org-end-of-subtree t t)
                   (when (and (org-at-heading-p) (not (eobp))) (backward-char 1))
                   (point)))))))
    (defun jb/org-clear-results ()
      (interactive)
      (org-babel-remove-result-one-or-many 't))
    (defun run-org-block ()
      (interactive)
      (save-excursion
        (goto-char
         (org-babel-find-named-block
          (completing-read "Code Block: " (org-babel-src-block-names))))
        (org-babel-execute-src-block-maybe)))
    (setq global-company-modes '(not org-mode)))
  :config
  (progn
    (setq truncate-lines nil
          org-startup-truncated nil
          word-wrap t)
    (setq org-agenda-files (list (concat org-directory "/personal/calendar.org")
                                 (concat org-directory "/work/calendar.org")
                                 (concat org-directory "/personal/tasks.org")
                                 (concat org-directory "/work/tasks.org")))
    (require 'ob-erlang)
    (org-babel-do-load-languages 'org-babel-load-languages
                                 '((dot . t)
				   (erlang . t)
				   (emacs-lisp . t)
                                   (js . t)
                                   (sql . t)
				   (awk . t)
				   (plantuml . t)
				   (ditaa . t)
				   (restclient . t)
				   (shell . t)))
    (setq org-todo-keywords
	  '((sequence "TODO(t)" "INPROGRESS(i)" "|" "DONE(d)")
	    ("WAITING(w@/!)" "HOLD(h@/!)" "|" "CANCELLED(c@/!)" "PHONE" "MEETING"))

          org-todo-keyword-faces
          '(("TODO" :foreground "red" :weight bold)
            ("INPROGRESS" :foreground "blue" :weight bold)
            ("DONE" :foreground "forest green" :weight bold)
            ("WAITING" :foreground "orange" :weight bold)
            ("BLOCKED" :foreground "magenta" :weight bold)
            ("CANCELLED" :foreground "forest green" :weight bold)))
    (setq org-default-notes-file (concat org-directory "/notes.org")
          org-export-html-postamble nil
          org-hide-leading-stars t
          org-startup-folded 'overview
          org-startup-indented t)))

(use-package org-bullets
             :config
             (progn
               (setq org-bullets-bullet-list '("☯" "✿" "✚" "◉" "❀"))
               ;;(setq org-bullets-bullet-list '("☰" "☷" "☯" "☭"))
               (add-hook 'org-mode-hook (lambda () (org-bullets-mode 1)))))


;; ---------------------------------------------------------------------------
;; restclient config
;; code: cd .emacs.d/elpa/org-20161102 && rm *.elc || 执行 x/recompile-elpa

(use-package restclient :ensure t :mode ("\\.http\\'" . restclient-mode))
(use-package ob-restclient :ensure t :after org restclient)

;; generated-curl-command is used to communicate state across several function calls
(setq generated-curl-command nil)

(defvar org-babel-default-header-args:restclient-curl `((:results . "raw")) "Default arguments for evaluating a restclient block.")

;; Lambda function reified to a named function, stolen from restclient
(defun gen-restclient-curl-command (method url headers entity)
  (let ((header-args
         (apply 'append
                (mapcar (lambda (header)
                          (list "-H" (format "%s: %s" (car header) (cdr header))))
                        headers))))
    (setq generated-curl-command
          (concat
           "#+BEGIN_SRC sh\n"
           "curl "
           (mapconcat 'shell-quote-argument
                      (append '("-i")
                              header-args
                              (list (concat "-X" method))
                              (list url)
                              (when (> (string-width entity) 0)
                                (list "-d" entity)))
                      " ")
           "\n#+END_SRC"))))

(defun org-babel-execute:restclient-curl (body params)
  "Execute a block of Restclient code to generate a curl command with org-babel.
This function is called by `org-babel-execute-src-block'"
  (message "executing Restclient source code block")
  (with-temp-buffer
    (let ((results-buffer (current-buffer))
          (restclient-same-buffer-response t)
          (restclient-same-buffer-response-name (buffer-name))
          (display-buffer-alist
           (cons
            '("\\*temp\\*" display-buffer-no-window (allow-no-window . t))
            display-buffer-alist)))

      (insert (buffer-name))
      (with-temp-buffer
        (dolist (p params)
          (let ((key (car p))
                (value (cdr p)))
            (when (eql key :var)
              (insert (format ":%s = %s\n" (car value) (cdr value))))))
        (insert body)
        (goto-char (point-min))
        (delete-trailing-whitespace)
        (goto-char (point-min))
        (restclient-http-parse-current-and-do 'gen-restclient-curl-command))
      generated-curl-command)))

;; Make it easy to interactively generate curl commands
(defun jb/gen-curl-command ()
  (interactive)
  (let ((info (org-babel-get-src-block-info)))
    (if (equalp "restclient" (car info))
        (org-babel-execute-src-block t (cons "restclient-curl"
                                             (cdr info)))
        (message "I'm sorry, I can only generate curl commands for a restclient block."))))


;; -----------------------------------------------------------------------------------------
; brew tap d12frosted/emacs-plus
; brew install emacs-plus --with-imagemagick@6 --without-spacemacs-icon
;; plantuml-mode
;; brew install imagemagick

;; plantuml-mode
(use-package plantuml-mode
  :ensure t
  :config
  (add-to-list 'auto-mode-alist '("\\.plantuml\\'" . plantuml-mode))
  (setq plantuml-default-exec-mode 'jar)
  (setq plantuml-jar-path "/usr/local/Cellar/plantuml/1.2020.15/libexec/plantuml.jar")
  )

(setq org-plantuml-jar-path "/usr/local/Cellar/plantuml/1.2020.15/libexec/plantuml.jar")
(setq plantuml-default-exec-mode 'jar)

;; Download and hook up plantuml.jar
;(let ((plantuml-directory (concat  config-load-path "vendor/"))
;      (plantuml-link "https://superb-dca2.dl.sourceforge.net/project/plantuml/plantuml.jar"))
;  (let ((plantuml-target (concat plantuml-directory "plantuml.jar")))
;    (if (not (f-exists? plantuml-target))
;        (progn (message "Downloading plantuml.jar")
;               (shell-command
;                (mapconcat 'identity (list "wget" plantuml-link "-O" plantuml-target) " "))
;               (kill-buffer "*Shell Command Output*")))
;    (setq org-plantuml-jar-path plantuml-target)))

;; Let's have pretty source code blocks
(setq org-edit-src-content-indentation 0
      org-src-tab-acts-natively t
      org-src-fontify-natively t
      org-confirm-babel-evaluate nil
      org-support-shift-select 'always)

;; export html with highlight code
(use-package htmlize
             :defer t
             :commands (htmlize-buffer
                         htmlize-file
                         htmlize-many-files
                         htmlize-many-files-dired
                         htmlize-region))

;; capture the picture for macos
(defun my-org-screenshot (basename)
  "Take a screenshot into a time stamped unique-named file in the
same directory as the org-buffer and insert a link to this file."
  (interactive "sScreenshot name: ")
  (if (equal basename "")
      (setq basename (format-time-string "%Y%m%d_%H%M%S")))
  (setq filename
        (concat (file-name-directory (buffer-file-name))
                "imgs/"
                (file-name-base (buffer-file-name))
                "_"
                basename
                ".png"))
  (call-process "screencapture" nil nil nil "-s" filename)
  (insert "#+CAPTION:")
  (insert basename)
  (insert "\n")
  (insert (concat "[[" filename "]]"))
  (org-display-inline-images))

;(setq org-image-actual-width '(400))
;(add-hook 'org-babel-after-execute-hook 'org-display-inline-images 'append)
(setq org-image-actual-width nil)
; eg:
; #+NAME: fig:moodleviz
; #+CAPTION: Screenshot from Moodleviz.
; #+ATTR_ORG: :width 600
; #+ATTR_LATEX: :width 5in
; [[file:figures/moodleviz-laps.png]]

;; org -> html
(setq org-html-doctype "html5")
(setq org-html-xml-declaration nil)
(setq org-html-postamble nil)
;; more beatyfull
(setq org-html-head "<link rel='stylesheet' href='http://cdn.bootcss.com/bootstrap/3.3.0/css/bootstrap.min.css'>\n<link rel='stylesheet' href='http://cdn.bootcss.com/bootstrap/3.3.0/css/bootstrap-theme.min.css'>\n<script src='http://cdn.bootcss.com/jquery/1.11.1/jquery.min.js'>\n</script><script src='http://cdn.bootcss.com/bootstrap/3.3.0/js/bootstrap.min.js'></script>")

;;(use-package org-download :ensure t)

(add-hook 'org-babel-after-execute-hook 'org-display-inline-images 'append)
(setq org-image-actual-width '(400))
(setq org-startup-with-inline-images t)

(add-hook 'org-mode-hook
	  (lambda()
	    (setq truncate-lines nil)))

;; --------------------------------------------------------------
;; org -> latex -> pdf
;; --------------------------------------------------------------
;; latex supporting deps
;; https://orgmode.org/worg/org-dependencies.html

;; brew cask install basictex --verbose # verbose flag so I can see what is happening.
;; which pdflatex
;; export PATH=$PATH:/Library/TeX/texbin

;; pip install pygments
;; sudo tlmgr install minted

;; sudo tlmgr update --self --all
;; sudo tlmgr install ctex environ trimspaces zhnumber cjk

; #+LATEX_HEADER: \documentclass{article}
; #+LATEX_HEADER: \usepackage{xeCJK}
; #+LATEX_HEADER: \usepackage{minted}

;; or use this title
;#+LATEX_HEADER: \documentclass{article}
;#+LATEX_HEADER: \usepackage{ctex}
;#+LATEX_HEADER: \usepackage{minted}
;; --------------------------------------------------------------

;; setting font for mac system
;; Setting English Font
(defun s-font()
  (interactive)
  ;; font config for org table showing.
  (set-face-attribute
   'default nil :font "Monaco 12")
;; Chinese Font 配制中文字体
  (dolist (charset '(kana han symbol cjk-misc bopomofo))
    (set-fontset-font (frame-parameter nil 'font)
                    charset
                    (font-spec :family "Microsoft YaHei" :size 14))))
;; tune rescale so that Chinese character width = 2 * English character width
;; (setq face-font-rescale-alist '(("Monaco" . 1.0) ("Microsoft YaHei" . 1.23)))
(add-to-list 'after-make-frame-functions
             (lambda (new-frame)
               (select-frame new-frame)
               (if window-system
                   (s-font))))
(if window-system
    (s-font))

;; set latex
(require 'ox-latex)
(setq org-latex-compiler "xelatex")

;; use minted to hightlight the source code
(add-to-list 'org-latex-packages-alist '("" "minted"))
(setq org-latex-listings 'minted)
(add-to-list 'org-latex-minted-langs '(csharp "csharp"))
(add-to-list 'org-latex-minted-langs '(bash "bash"))
(add-to-list 'org-latex-minted-langs '(golang "golang"))

(setq org-latex-minted-options
      '(("frame" "lines")
        ("framesep=2mm")
        ("linenos=true")
        ("baselinestretch=1.2")
        ("fontsize=\\footnotesize")
        ("breaklines")
        ))

(setq org-latex-pdf-process
      '("xelatex -8bit -shell-escape -interaction nonstopmode -output-directory %o %f"))

(provide 'init-org)
