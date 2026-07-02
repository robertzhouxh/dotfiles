;;; emacs-init-org.el --- Org-Mode 配置 -*- lexical-binding: t; -*-

(require 'emacs-init-path)

(use-package org-download
  :commands (org-download-enable org-download-screenshot org-download-clipboard)
  :hook (dired-mode . org-download-enable)
  :init
  (setq-default org-download-image-dir "./static/images/")
  (setq org-download-method 'directory
        org-download-display-inline-images 'posframe
        org-download-image-attr-list '("#+ATTR_HTML: :width 800 :align left"))
  (setq org-download-annotate-function (lambda (link) (previous-line 1) "")))

(use-package org
  :ensure nil
  :defer 0.2
  :bind (("C-c l" . org-store-link)
         ("C-c c" . org-capture)
         (:map org-mode-map ("C-c ;" . nil)))
  :config
  (require 'org-tempo)
  (setq org-startup-folded 'overview)

  ;; Ellipsis
  (setq org-ellipsis " ▼ ")
  (set-face-attribute 'org-ellipsis nil :inherit 'default :box nil)

  (setq org-pretty-entities t
        org-highlight-latex-and-related '(latex)
        org-export-with-latex 'verbatim
        org-export-with-broken-links 'mark
        org-export-with-sub-superscripts nil
        org-export-default-language "zh-CN"
        org-export-coding-system 'utf-8
        org-use-sub-superscripts nil
        org-link-file-path-type 'relative
        org-html-validation-link nil
        org-mouse-1-follows-link nil
        org-hide-emphasis-markers t
        org-hide-block-startup t
        org-hidden-keywords '(title)
        org-hide-leading-stars t
        org-cycle-separator-lines 2
        org-cycle-level-faces t
        org-n-level-faces 4
        org-list-indent-offset 2
        org-src-preserve-indentation t
        org-edit-src-content-indentation 0
        org-log-into-drawer t
        org-log-done 'note
        org-startup-with-inline-images nil
        org-cycle-inline-images-display nil
        org-startup-numerated nil
        org-startup-indented t
        org-image-actual-width '(600)
        org-clock-sound t
        org-archive-default-command nil
        org-tags-column 0
        org-auto-align-tags nil
        org-catch-invisible-edits 'show-and-error
        org-special-ctrl-a/e t
        org-insert-heading-respect-content t
        org-fold-catch-invisible-edits t
        org-id-link-to-org-use-id t
        org-confirm-babel-evaluate nil
        org-todo-keywords
        '((sequence "TODO(t!)" "DOING(d@)" "|" "DONE(D)")
          (sequence "WAITING(w@/!)" "NEXT(n!/!)" "SOMEDAY(S)" "|" "CANCELLED(c@/!)")))

  ;; 代码块
  (setq org-plantuml-jar-path my-plantuml-jar-path)
  (setq org-src-fontify-natively t
        org-src-tab-acts-natively t)
  (org-babel-do-load-languages
   'org-babel-load-languages
   '((shell . t)
     (plantuml . t)
     (makefile . t)
     (python . t)
     (C . t))))

;; ---- Org 截图 ----
(defun my-org-screenshot ()
  "截图并插入 Org 链接。"
  (interactive)
  (org-display-inline-images)
  (setq filename
        (concat
         (make-temp-name
          (concat (file-name-nondirectory (buffer-file-name))
                  "assets/"
                  (format-time-string "%Y%m%d_%H%M%S_")) ) ".png"))
  (unless (file-exists-p (file-name-directory filename))
    (make-directory (file-name-directory filename)))
  (if (eq system-type 'darwin)
      (call-process "screencapture" nil nil nil "-i" filename))
  (if (eq system-type 'gnu/linux)
      (call-process "import" nil nil nil filename))
  (if (file-exists-p filename)
      (insert (concat "[[file:" filename "]]"))))

;; ---- Org-LaTeX ----
(use-package engrave-faces
  :after ox-latex
  :config
  (require 'engrave-faces-latex)
  (setq org-latex-src-block-backend 'engraved)
  (add-to-list 'org-latex-engraved-options '("numbers" . "left")))

(defun my/export-pdf (backend)
  (setq org-export-headline-levels 2))

(add-hook 'org-export-before-processing-functions #'my/export-pdf)

(use-package ox-gfm :defer t)

(with-eval-after-load 'ox
  (require 'ox-latex)
  (setq org-latex-image-default-width "0.7\\linewidth"
        org-latex-tables-booktabs t
        org-latex-remove-logfiles t
        org-latex-pdf-process
        '("latexmk -xelatex -shell-escape -f %f"
          "rm -fr %b.out %b.tex %b.brf %b.bbl"))

  (add-to-list 'org-latex-classes
               '("ctexart"
                 "\\documentclass[lang=cn,11pt,a4paper,table]{ctexart}
                      [NO-DEFAULT-PACKAGES]
                      [PACKAGES]
                      [EXTRA]"
                 ("\\section{%s}" . "\\section*{%s}")
                 ("\\subsection{%s}" . "\\subsection*{%s}")
                 ("\\subsubsection{%s}" . "\\subsubsection*{%s}")
                 ("\\paragraph{%s}" . "\\paragraph*{%s}")
                 ("\\subparagraph{%s}" . "\\subparagraph*{%s}"))))

(with-eval-after-load 'ox-latex
  (setq org-latex-packages-alist '(("" "mhchem" t) ("" "ctex" t)))
  (add-to-list 'org-preview-latex-process-alist
               '(xelatex-ch
                 :programs ("xelatex" "dvisvgm")
                 :description "xdv > svg"
                 :message "You need to install xelatex & dvisvgm"
                 :image-input-type "xdv"
                 :image-output-type "svg"
                 :image-size-adjust (1.3 . 1.2)
                 :latex-compiler
                 ("xelatex -no-pdf -interaction nonstopmode -output-directory %o %f")
                 :image-converter
                 ("dvisvgm %f --no-fonts --exact-bbox --scale=%S --output=%O"))))

(provide 'emacs-init-org)
;;; init-org.el ends here
