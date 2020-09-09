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

(require 'ox-latex)
(setq org-latex-compiler "xelatex")
(setq org-latex-pdf-process
	'("xelatex -8bit -shell-escape -interaction nonstopmode -output-directory %o %f"))

;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;; org to pdf: https://www.dazhuanlan.com/2020/04/28/5ea7e2f107bf5/?__cf_chl_jschl_tk__=6f188c90740a81954c2e5b9a8af0126fb307da54-1599611250-0-AQ1xpE1-fM1lLvd7fU6OwqbT6nzMD_xb4C7w29Qpai9WCBuTazemqsreaCjpUqIkmyMnMbirmFsuqkD1Z7LzhPMz5OSkKGwv5lVStRZJu1ZvZs4xqC_ycsu3bCn9DTrdLcWnHntDN96EgMyWivRXfDDDKz4b8Xq5RNxqu75BPSrWRYUoLQhgkWyOQp5Xffyt9TaCjdNAWHvGyGDbVr7SpZfD0e-skePdDdbFU-IliebDwXArBnvUraUoXJk9zA5WO-aKPwZzHos_HeXGO1ar8gaoHQ7E48QKBXQCwx9E0gFswBUuMMROTgo64HWpjpKdZg
;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

;; 设置编译器
(require 'ox-latex)
(setq org-latex-compiler "xelatex")
(setq org-latex-pdf-process
	'("xelatex -8bit -shell-escape -interaction nonstopmode -output-directory %o %f"))

;; 源代码语法高亮
(add-to-list 'org-latex-packages-alist '("" "minted"))
(setq org-latex-listings 'minted)
(add-to-list 'org-latex-minted-langs '(csharp "csharp"))
(setq org-latex-minted-options
      '(
	("linenos=true")
;;	("mathescape=true")
;;        ("numbersep=5pt")
;;        ("gobble=2")
	("frame=lines")
;;        ("framesep=2mm")
	))

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
;;(setq face-font-rescale-alist '(("Monaco" . 1.0) ("Microsoft YaHei" . 1.23)))
(add-to-list 'after-make-frame-functions
	     (lambda (new-frame)
	       (select-frame new-frame)
	       (if window-system
		   (s-font))))
(if window-system
    (s-font))
;; 导出的快捷键是 C-x C-e l o 。 如果在导出的过程中，出现一些package不存在的提示，可以用如下命令安装：
;;sudo tlmgr install <package name>

(provide 'init-org)
