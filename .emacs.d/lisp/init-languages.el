;;; init-languages.el --- Set up programming languages
;;; Commentary:

;;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;; helm-dash-install-docset ===> GO, Erlang, Mongodb, Redis,...
;;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
(use-package helm-dash
  :config
  (progn
    (setq helm-dash-browser-func 'eww)
    (setq helm-dash-docsets-path (expand-file-name "~/.emacs.d/docsets"))
    (helm-dash-activate-docset "Go")
    (helm-dash-activate-docset "Erlang")
    (helm-dash-activate-docset "Python 3")
    (helm-dash-activate-docset "Emacs Lisp")
    ))

;;--------------------------------------------------------------
;; cc-mode
;;--------------------------------------------------------------
(use-package cc-mode
  :config
  (progn
    (add-hook 'c-mode-hook (lambda () (c-set-style "bsd")))
    (add-hook 'java-mode-hook (lambda () (c-set-style "bsd")))
    (setq tab-width 4)
    (setq c-basic-offset 4)))

;;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;; Erlang Programming << sed ---> gsed >>
;;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;; ===> https://stackoverflow.com/questions/30003570/how-to-use-gnu-sed-on-mac-os-x#34815955
;; wget https://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb
;; sudo dpkg -i erlang-solutions_1.0_all.deb
;; sudo apt-get update
;; sudo apt-get install erlang

;; Install Erlang Docs And Man Pages
;;    wget http://erlang.org/download/otp_doc_man_21.3.tar.gz
;;    $ manpath
;;    /usr/local/share/man:/usr/share/man:/usr/X11/man:/usr/local/git/share/man
;;    Copy man pages to man path:
;;    $ tar xfz xxx.tar.gz
;;    $ ls man
;;    man1 man3 man4 man6 man7
;;    $ sudo cp -r man/* /usr/local/share/man/
;;    Test:
;;    $ man erl
;;    Updated: Erlang's man pages may not need to download, since there is already a copy at /usr/local/lib/erlang/man. Just copy them into manpath.

(setq auto-mode-alist
      (reverse
       (append auto-mode-alist
	       '(("\\.rel$"         . erlang-mode)
		 ("\\.app\\.src$"     . erlang-mode)
		 ("\\.hrl$"         . erlang-mode)
		 ("\\.erl$"         . erlang-mode)
		 ("\\.yrl$"         . erlang-mode)
		 ("\\.conf$"        . erlang-mode)
		 ("\\.schema"       . erlang-mode)
		 ("rebar\\.config$" . erlang-mode)
		 ("relx\\.config$"  . erlang-mode)
		 ("sys\\.config$"   . erlang-mode)))))

;; "/usr/local/lib/erlang/lib/tools-" for mac
(let* ((emacs-version "3.3.1")
       (tools-path
	(concat "/usr/local/lib/erlang/lib/tools-" emacs-version "/emacs")))
  (when (file-exists-p tools-path)
    (setq load-path (cons tools-path load-path))
    (setq erlang-root-dir "/usr/local/lib/erlang")
    (setq exec-path (cons "/usr/local/lib/erlang/bin" exec-path))
    (require 'erlang-start)
    (defvar inferior-erlang-prompt-timeout t)))

;; get erlang man page
(defun get-erl-man ()
  (interactive)
  ;;(let* ((man-path "/usr/local/opt/erlang/lib/erlang/man")
  (let* ((man-path "/usr/local/lib/erlang/man")
	 (man-args (format "-M %s %s" man-path (current-word))))
    (man man-args)))

(defun erlang-insert-binary ()
  "Inserts a binary string into an Erlang buffer and places the
  point between the quotes."
  (interactive)
  (insert "<<\"\">>")
  (backward-char 3)
  )

;; https://github.com/s-kostyaev/ivy-erlang-complete
(use-package ivy-erlang-complete
  :ensure t
  :custom
  (ivy-erlang-complete-erlang-root '/usr/local/Cellar/erlang/22.3.2/lib/erlang)
  :config
  :bind
  (
   ("C-c e s" . 'ivy-erlang-complete-find-spec)
   ("C-c e f" . 'ivy-erlang-complete-find-file)
   ("C-c e h" . 'ivy-erlang-complete-show-doc-at-point)
   ("C-c e p" . 'ivy-erlang-complete-set-project-root)
   ("C-c e a" . 'ivy-erlang-complete-autosetup-project-root)
   )
  :init
  (add-hook 'erlang-mode-hook #'ivy-erlang-complete-init)
  (add-hook 'after-save-hook #'ivy-erlang-complete-reparse)
  (add-hook 'erlang-mode-hook #'company-erlang-init)
  )

;;----------------------------------------------------------------------------
;; lisp: C-x C-e 执行光标下lisp
;; 或者 l执行整个buffer ==> ,e
;;----------------------------------------------------------------------------
(use-package slime
  :defer t
  :config
  (progn
    (use-package ac-slime :ensure t)
    (setq inferior-lisp-program "sbcl")
    (slime-setup)
    (add-hook 'slime-mode-hook 'set-up-slime-ac)
    (add-hook 'slime-repl-mode-hook 'set-up-slime-ac)
    (add-hook 'slime-mode-hook
	      (lambda ()
		(unless (slime-connected-p)
		  (save-excursion (slime)))))
    (slime-setup '(slime-fancy slime-asdf))
    (slime-setup '(slime-repl slime-fancy slime-banner))
    (setq slime-protocol-version 'ignore
	  slime-net-coding-system 'utf-8-unix
	  ;;slime-complete-symbol*-fancy t
	  slime-complete-symbol-function 'slime-fuzzy-complete-symbol))
  :ensure t)

(use-package color-identifiers-mode
  :ensure t
  :init
  (add-hook 'emacs-lisp-mode-hook 'color-identifiers-mode)
  :diminish color-identifiers-mode)

;;----------------------------------------------------------------------------
;; Golang
;; go get github.com/rogpeppe/godef
;; go get -u github.com/golang/lint/golint
;; go get -u github.com/nsf/gocode
;; c-x c-s 保存
;; c-x c-e 下载
;;----------------------------------------------------------------------------
;;(use-package go-mode
;;             :ensure t
;;             :bind (:map go-mode-map
;;                         ("M-l" . godef-jump)
;;                         ("M-h" . pop-tag-mark))
;;             :config
;;             (add-hook 'go-mode-hook '(lambda () (setq tab-width 2)))
;;             (setq gofmt-command "goimports")
;;             (add-hook 'before-save-hook 'gofmt-before-save))
;;
;;(use-package company-go
;;             :ensure t
;;             :after go-mode
;;             :config
;;             (setq company-go-gocode-command "/Users/xier/go-workspace/bin/gocode")
;;             (add-hook 'go-mode-hook 'company-mode)
;;             (add-hook 'go-mode-hook (lambda ()
;;                                       (set (make-local-variable 'company-backends) '(company-go))
;;                                       (company-mode)))
;;             (setq company-tooltip-align-annotations t))

;;; Code:
(use-package go-mode
  :ensure t
  :mode (("\\.go\\'" . go-mode))
  :hook ((before-save . gofmt-before-save))
  :config
  (setq gofmt-command "goimports")
  (use-package company-go
    :ensure t
    :config
    (add-hook 'go-mode-hook (lambda()
			      (add-to-list (make-local-variable 'company-backends)
					   '(company-go company-files company-yasnippet company-capf))))
    )
  (use-package go-eldoc
    :ensure t
    :hook (go-mode . go-eldoc-setup)
    )
  (use-package go-guru
    :ensure t
    :hook (go-mode . go-guru-hl-identifier-mode)
    )
  ;; (use-package go-rename
  ;;   :ensure t)
  )

;;
;; for guru setup scope
;;
(defun my/go-guru-set-current-package-as-main ()
  "GoGuru requires the scope to be set to a go package which
     contains a main, this function will make the current package the
     active go guru scope, assuming it contains a main"
  (interactive)
  (let* ((filename (buffer-file-name))
	 (gopath-src-path (concat (file-name-as-directory (go-guess-gopath)) "src"))
	 (relative-package-path (directory-file-name (file-name-directory (file-relative-name filename gopath-src-path)))))
    (setq go-guru-scope relative-package-path)))

;;----------------------------------------------------------------------------
;; clojure
;; M-x cider-jack-in 打开一个repl 的session，你编写的Clojure代码之后会在这里运行。

;; C-c C-k 编译Clojure代码，如果编译出错 C-c C-f来定位错误的地方然后修正。
;; C-c C-, 可以用来运行测试文件，结果会输出到打开的repl session。

;; C-c M-n 用来切换repl session的namespace， 如果你正在编写一个clojure文件，可以
;; 使用这个快捷键来一边开发，一边测试。

;; C-c C-o 可以用来清初repl session的无用信息。
;; C-c C-d 可以用来查看函数的doc。

;; M-. 可以查看函数的源代码。
;; M-, 用来查看第三方库
;;----------------------------------------------------------------------------
(use-package clj-refactor :ensure t)
(use-package clojure-mode
  :ensure t
  :config
  (add-hook 'clojure-mode-hook #'paredit-mode)
  (add-hook 'clojure-mode-hook #'subword-mode)
  (add-hook 'clojure-mode-hook #'rainbow-delimiters-mode))

(use-package cider
  :config
  (setq nrepl-popup-stacktraces nil)
  (add-hook 'cider-mode-hook 'eldoc-mode)
  (add-hook 'cider-mode-hook #'rainbow-delimiters-mode)
  ;; Replace return key with newline-and-indent when in cider mode.
  (add-hook 'cider-mode-hook '(lambda () (local-set-key (kbd "RET") 'newline-and-indent)))
  (add-hook 'cider-mode-hook #'company-mode)
  (add-hook 'cider-repl-mode-hook 'subword-mode)
  (add-hook 'cider-repl-mode-hook 'paredit-mode)
  (add-hook 'cider-repl-mode-hook #'company-mode)
  (add-hook 'cider-repl-mode-hook #'rainbow-delimiters-mode)
  :custom
  ;; nice pretty printing
  (cider-repl-use-pretty-printing t)
  ;; nicer font lock in REPL
  (cider-repl-use-clojure-font-lock t)
  ;; result prefix for the REPL
  (cider-repl-result-prefix "; => ")
  ;; never ending REPL history
  (cider-repl-wrap-history t)
  ;; looong history
  (cider-repl-history-size 5000)
  ;; persistent history
  (cider-repl-history-file "~/.emacs.d/cider-history")
  ;; error buffer not popping up
  (cider-show-error-buffer nil)
  ;; go right to the REPL buffer when it's finished connecting
  (cider-repl-pop-to-buffer-on-connect t))

(use-package clojure-mode-extra-font-locking
  :ensure t
  :config
  ;; syntax hilighting for midje
  (add-hook 'clojure-mode-hook
	    (lambda ()
	      (setq inferior-lisp-program "lein repl")
	      (font-lock-add-keywords
	       nil
	       '(("(\\(facts?\\)"
		  (1 font-lock-keyword-face))
		 ("(\\(background?\\)"
		  (1 font-lock-keyword-face))))
	      (define-clojure-indent (fact 1))
	      (define-clojure-indent (facts 1)))))

					; key bindings
					; these help me out with the way I usually develop web apps
(defun cider-start-http-server ()
  (interactive)
  (cider-load-current-buffer)
  (let ((ns (cider-current-ns)))
    (cider-repl-set-ns ns)
    (cider-interactive-eval (format "(println '(def server (%s/start))) (println 'server)" ns))
    (cider-interactive-eval (format "(def server (%s/start)) (println server)" ns))))

(defun cider-refresh ()
  (interactive)
  (cider-interactive-eval (format "(user/reset)")))

(defun cider-user-ns ()
  (interactive)
  (cider-repl-set-ns "user"))

(eval-after-load 'cider
  '(progn
     (define-key clojure-mode-map (kbd "C-c C-v") 'cider-start-http-server)
     (define-key clojure-mode-map (kbd "C-M-r") 'cider-refresh)
     (define-key clojure-mode-map (kbd "C-c u") 'cider-user-ns)
     (define-key cider-mode-map (kbd "C-c u") 'cider-user-ns)))

(require 'clj-refactor)
(defun cljr-mode-hook ()
  (clj-refactor-mode 1)
  (yas-minor-mode 1) ; for adding require/use/import statements
  ;; This choice of keybinding leaves cider-macroexpand-2 unbound
  (cljr-add-keybindings-with-prefix "C-c C-m")
  (define-key clojure-mode-map (kbd "C-c M-RET") 'cider-macroexpand-1))
(add-hook 'clojure-mode-hook #'cljr-mode-hook)

(defun my/set-cljs-repl-figwheel ()
  (setq cider-cljs-lein-repl "(do (use 'figwheel-sidecar.repl-api) (start-figwheel!) (cljs-repl))"))

(defun my/cider-figwheel-repl ()
  (interactive)
  (save-some-buffers)
  (with-current-buffer (cider-current-repl-buffer)
    (goto-char (point-max))
    (insert "(require 'figwheel-sidecar.repl-api)
	     (figwheel-sidecar.repl-api/start-figwheel!)
	     (figwheel-sidecar.repl-api/cljs-repl)")
    (cider-repl-return)))

(global-set-key (kbd "C-c C-f") #'my/cider-figwheel-repl)

(defun my/set-cljs-repl-rhino ()
  (setq cider-cljs-lein-repl "rhino"))

(defun my/start-cider-repl-with-profile (profile)
  (interactive "sEnter profile name: ")
  (letrec ((lein-params (concat "with-profile +" profile " repl :headless")))
    (message "lein-params set to: %s" lein-params)
    (set-variable 'cider-lein-parameters lein-params)
    (cider-jack-in)
    (set-variable 'cider-lein-parameters "repl :headless")))

(require 'clojure-mode)
(define-clojure-indent
  (defroutes 'defun)
  (GET 2)
  (POST 2)
  (PUT 2)
  (DELETE 2)
  (HEAD 2)
  (ANY 2)
  (OPTIONS 2)
  (PATCH 2)
  (rfn 2)
  (let-routes 1)
  (context 2))

;;----------------------------------------------------------------------------
;; other programming languages
;;----------------------------------------------------------------------------
(use-package sh-script
  :defer t
  :config (setq sh-basic-offset 4))
(use-package web-mode
  :ensure t
  :mode (("\\.phtml\\'" . web-mode)
	 ("\\.erb\\'" . web-mode)
	 ("\\.mustache\\'" . web-mode)
	 ("\\.djhtml\\'" . web-mode)
	 ("\\.tmpl\\'" . web-mode)
	 ("\\.html\\'" . web-mode))
  :config
  (setq web-mode-markup-indent-offset 4)
  (setq web-mode-enable-current-column-highlight t)
  (setq web-mode-enable-current-element-highlight t))
(use-package lua-mode
  :ensure t
  :mode (("\\.lua\\'" . lua-mode))
  :config
  (add-hook 'lua-mode-hook #'company-mode))
(use-package markdown-mode
  :ensure t
  :mode ("\\.md\\'" . markdown-mode))
(use-package dockerfile-mode
  :ensure t
  :mode "\\Dockerfile\\'")
(use-package yaml-mode
  :defer t
  :mode ("\\.yml$" . yaml-mode))
(use-package ansible
  :defer t
  :init (add-hook 'yaml-mode-hook '(lambda () (ansible 1))))

;;----------------------------------------------------------------------------
;; auto insert
;;----------------------------------------------------------------------------
;; https://github.com/alexott/emacs-configs/blob/master/rc/emacs-rc-auto-insert.el
(load "autoinsert")
(auto-insert-mode)
(setq auto-insert t)
;;(setq auto-insert-query t)
(add-hook 'find-file-hooks 'auto-insert)

(setq auto-insert-alist
      (append '(
		(("\\.go$" . "golang header")
		 nil
		 "//---------------------------------------------------------------------\n"
		 "// @Copyright (c) 2016-2017 Rosinno Enterprise, Inc. (http://rosinno.com)\n"
		 "// @Author: robertzhouxh <robertzhouxh@gmail.com>\n"
		 "// @Date   Created: " (format-time-string "%Y-%m-%d %H:%M:%S")"\n"
		 "//----------------------------------------------------------------------\n"
		 _
		 ))
	      auto-insert-alist))

(setq auto-insert-alist
      (append '(
		(("\\.py$" . "python template")
		 nil
		 "#!/usr/bin/env python\n"
		 "\n"
		 "import sys, os, math\n"
		 "# import numpy as np\n"
		 "# import scipy as sp\n"
		 "# import ROOT\n"
		 "# import pyfits as pf\n"
		 "\n"
		 _
		 )) auto-insert-alist))
(setq auto-insert-alist
      (append '(
		(("\\.sh$" . "shell script template")
		 nil
		 "#!/bin/bash\n"
		 "\n"
		 _
		 )) auto-insert-alist))

(setq auto-insert-alist
      (append '(
		(("\\.erl$" . "erlang header")
		 nil
		 "%%%-------------------------------------------------------------------\n"
		 "%%% @Copyright (c) 2019-2020 rosinno Enterprise, Inc. (http://rosinno.com)\n"
		 "%%% @Author: robertzhouxh <zhouxuehao@rosinno.com>\n"
		 "%%% @Date   Created: " (format-time-string "%Y-%m-%d %H:%M:%S")"\n"
		 "%%%-------------------------------------------------------------------\n"
		 _
		 ))
	      auto-insert-alist))

(setq auto-insert-alist
      (append '(
		(("\\.h\\'" . "C/C++ header")
		 nil
		 '(c++-mode)
		 '(setq my:skeleton-author (identity user-full-name))
		 '(setq my:skeleton-mail-address (identity user-mail-address))
		 '(setq my:skeleton-namespace (read-string "Namespace: " ""))
		 '(setq my:skeleton-description (read-string "Short Description: " ""))
		 '(setq my:skeleton-inherit (read-string "Inherits from (space separate for multiple inheritance): " ""))
		 '(setq my:skeleton-inherit-list (split-string my:skeleton-inherit " " t))
		 '(setq my:skeleton-inheritance (cond ((null my:skeleton-inherit-list)
						       "")
						      (t
						       (setq my:skeleton-inheritance-concat "")
						       (dolist (element my:skeleton-inherit-list)
							 (setq my:skeleton-inheritance-concat
							       (concat my:skeleton-inheritance-concat
								       "public " element ", ")))
						       (setq my:skeleton-inheritance-concat
							     (concat " : "
								     my:skeleton-inheritance-concat))
						       (eval (replace-regexp-in-string ", \\'" "" my:skeleton-inheritance-concat)))))
		 '(setq my:skeleton-include (cond ((null my:skeleton-inherit-list)
						   "")
						  (t
						   (setq my:skeleton-include "\n")
						   (dolist (element my:skeleton-inherit-list)
						     (setq my:skeleton-include
							   (concat my:skeleton-include
								   "#include \"" element ".h\"\n")))
						   (eval my:skeleton-include))))
		 '(setq my:skeleton-namespace-list (split-string my:skeleton-namespace "::"))
		 '(setq my:skeleton-file-name (file-name-nondirectory (buffer-file-name)))
		 '(setq my:skeleton-class-name (file-name-sans-extension my:skeleton-file-name))
		 '(setq my:skeleton-namespace-class
			(cond ((string= my:skeleton-namespace "")
			       my:skeleton-class-name)
			      (t
			       (concat my:skeleton-namespace "::" my:skeleton-class-name)
			       )))
		 '(setq my:skeleton-namespace-decl
			(cond ((string= my:skeleton-namespace "")
			       ""
			       )
			      (t
			       (setq my:skeleton-namespace-decl-pre "")
			       (setq my:skeleton-namespace-decl-post "")
			       (setq my:skeleton-namespace-decl-indent "")
			       (dolist (namespace-element my:skeleton-namespace-list)
				 (setq my:skeleton-namespace-decl-pre
				       (concat my:skeleton-namespace-decl-pre
					       my:skeleton-namespace-decl-indent
					       "namespace " namespace-element " {\n"))
				 (setq my:skeleton-namespace-decl-post
				       (concat "\n"
					       my:skeleton-namespace-decl-indent
					       "}"
					       my:skeleton-namespace-decl-post))
				 (setq my:skeleton-namespace-decl-indent
				       (concat my:skeleton-namespace-decl-indent "   "))
				 )
			       (eval (concat my:skeleton-namespace-decl-pre
					     my:skeleton-namespace-decl-indent
					     "class " my:skeleton-class-name ";"
					     my:skeleton-namespace-decl-post))
			       )))
		 '(random t)
		 '(setq my:skeleton-include-guard
			(upcase
			 (format "INCLUDE_GUARD_UUID_%04x%04x_%04x_4%03x_%04x_%06x%06x"
				 (random (expt 16 4))
				 (random (expt 16 4))
				 (random (expt 16 4))
				 (random (expt 16 3))
				 (+ (random (expt 2 14)) (expt 2 5))
				 (random (expt 16 6))
				 (random (expt 16 6)))))
		 "/**" n
		 "* @file   " my:skeleton-file-name > n
		 "* @brief  " my:skeleton-description > n
		 "*" > n
		 "* @date   Created       : " (format-time-string "%Y-%m-%d %H:%M:%S") > n
		 "*         Last Modified :" > n
		 "* @author " my:skeleton-author " <" my:skeleton-mail-address ">" > n
		 "*" > n
		 "*    (C) " (format-time-string "%Y") " " my:skeleton-author > n
		 "*/" > n
		 n
		 "#ifndef " my:skeleton-include-guard n
		 "#define " my:skeleton-include-guard n
		 my:skeleton-include n
		 my:skeleton-namespace-decl n
		 n
		 "class " my:skeleton-namespace-class my:skeleton-inheritance " {" n
		 "public:" > n
		 my:skeleton-class-name "();" n
		 "virtual ~" my:skeleton-class-name "();" n
		 n
		 my:skeleton-class-name "(const " my:skeleton-class-name "& rhs);" n
		 my:skeleton-class-name "& operator=(const " my:skeleton-class-name "& rhs);" n
		 n
		 "protected:" > n
		 n
		 "private:" > n
		 n
		 "ClassDef(" my:skeleton-class-name ",1) // " my:skeleton-description n
		 "};" > n
		 n
		 "#endif // " my:skeleton-include-guard n
		 '(delete-trailing-whitespace)
		 )
		)
	      auto-insert-alist))

(provide 'init-languages)
	;;; init-languages.el ends here
