;;; init-org.el --- Set up Org Mode
;;; Commentary:

;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;; org basic settings
;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
(use-package org-evil :ensure t)

(setf org-todo-keyword-faces '(("TODO" . (:foreground "white" :background "#95A5A6"   :weight bold))
                               ("HAND" . (:foreground "white" :background "#2E8B57"  :weight bold))
                               ("DONE" . (:foreground "white" :background "#3498DB" :weight bold))))
(use-package org-bullets
             :ensure t
             :config
             (progn
               (setq org-bullets-bullet-list '("☯" "✿" "✚" "◉" "❀"))
               ;;(setq org-bullets-bullet-list '("☰" "☷" "☯" "☭"))
               (add-hook 'org-mode-hook (lambda () (org-bullets-mode 1)))))

;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;; code: cd .emacs.d/elpa/org-20161102 && rm *.elc || 执行 x/recompile-elpa
;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
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

(setq org-startup-indented t)
(setq org-plantuml-jar-path "~/.emacs.d/vendor/plantuml.jar")
(setq org-ditaa-jar-path "~/.emacs.d/vendor/ditaa0_9.jar")
;; Let's have pretty source code blocks
(setq org-edit-src-content-indentation 0
      org-src-tab-acts-natively t
      org-src-fontify-natively t
      org-confirm-babel-evaluate nil
      org-support-shift-select 'always)

(setq org-image-actual-width '(400))

(add-hook 'org-babel-after-execute-hook 'org-display-inline-images 'append)

;; 参考org 依赖安装：https://orgmode.org/worg/org-dependencies.html
;; http://nickgeorge.net/programming/latex_setup/
;; pip install pygments
;; sudo tlmgr install minted

;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;; export html with highlight code
;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
(use-package htmlize
             :ensure t
             :defer t
             :commands (htmlize-buffer
                         htmlize-file
                         htmlize-many-files
                         htmlize-many-files-dired
                         htmlize-region))
;; drag the pitcture
(use-package org-download :ensure t)

;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;; sudo tlmgr update --self --all
;; sudo tlmgr install ctex environ trimspaces zhnumber cjk

; #+LATEX_HEADER: \documentclass{article}
; #+LATEX_HEADER: \usepackage{xeCJK}
; #+LATEX_HEADER: \usepackage{minted}

;; or use this title
;#+LATEX_HEADER: \documentclass{article}
;#+LATEX_HEADER: \usepackage{ctex}
;#+LATEX_HEADER: \usepackage{minted}

;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

;; -----------------------------------------------------------------------------
;; setting font for mac system
;; -----------------------------------------------------------------------------
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
