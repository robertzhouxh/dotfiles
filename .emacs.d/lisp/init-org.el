;;; init-org.el --- Set up Org Mode
;;; Commentary:

;; org basic settings
(use-package org-evil)
(setq org-todo-keywords
      '((sequence "TODO(t)" "INPROGRESS(i)" "WAITING(w)" "REVIEW(r)" "|" "DONE(d)" "CANCELED(c)")))
(setq org-todo-keyword-faces
      '(("TODO" . org-warning)
        ("INPROGRESS" . "yellow")
        ("WAITING" . "purple")
        ("REVIEW" . "orange")
        ("DONE" . "green")
        ("CANCELED" .  "red")))
(use-package org-bullets
             :config
             (progn
               (setq org-bullets-bullet-list '("☯" "✿" "✚" "◉" "❀"))
               ;;(setq org-bullets-bullet-list '("☰" "☷" "☯" "☭"))
               (add-hook 'org-mode-hook (lambda () (org-bullets-mode 1)))))

;; code: cd .emacs.d/elpa/org-20161102 && rm *.elc || 执行 x/recompile-elpa
(require 'ob)
(require 'ob-shell)
(org-babel-do-load-languages
 'org-babel-load-languages
 '(
   (emacs-lisp . t)
   (org . t)
   (shell . t)
   (C . t)
   (python . t)
   (awk . t)
   (plantuml . t)
   (ditaa . t)
   ))

(require 'color)
(if (display-graphic-p)
    (set-face-attribute 'org-block nil :background
                        (color-darken-name
                         (face-attribute 'default :background) 3)))

(setq org-startup-indented t)

;; TODO
(use-package plantuml-mode)
;;(setq org-plantuml-jar-path "~/.emacs.d/vendor/plantuml.jar")
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

(setq org-image-actual-width '(400))

(add-hook 'org-babel-after-execute-hook 'org-display-inline-images 'append)

;; export html with highlight code
(use-package htmlize
             :defer t
             :commands (htmlize-buffer
                         htmlize-file
                         htmlize-many-files
                         htmlize-many-files-dired
                         htmlize-region))

;; drag the pitcture to the cursor's positon
(use-package org-download)

(setq org-startup-with-inline-images t)

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
