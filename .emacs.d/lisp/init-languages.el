;;; init-languages.el --- Set up programming languages
;;; Commentary:

;; Basic programming languages

;;; Code:

;; --------------------------------------------------------------------
;; generate the tag files
;; --------------------------------------------------------------------
;; scheme-1
;; (add-to-list 'helm-sources-using-default-as-input 'helm-source-man-pages)
;; global、gtags、gtags-cscope三个命令。global是查询，gtags是生成索引文件，gtags-cscope是与cscope一样的界面
;; 查询使用的命令是global和gtags-cscope。前者是命令行界面，后者是与cscope兼容的ncurses界面
;; helm-ggtags
;(if
;    (executable-find "global")
;    (progn
;      (use-package bpr :ensure t)
;      (use-package helm-gtags
;        :diminish helm-gtags-mode
;        :init
;        (add-hook 'dired-mode-hook 'helm-gtags-mode)
;        (add-hook 'eshell-mode-hook 'helm-gtags-mode)
;        (add-hook 'c-mode-hook 'helm-gtags-mode)
;        (add-hook 'c++-mode-hook 'helm-gtags-mode)
;        (add-hook 'asm-mode-hook 'helm-gtags-mode)
;        (add-hook 'go-mode-hook (lambda () (helm-gtags-mode)))
;        (add-hook 'python-mode-hook (lambda () (helm-gtags-mode)))
;        (add-hook 'ruby-mode-hook (lambda () (helm-gtags-mode)))
;        (add-hook 'lua-mode-hook (lambda () (helm-gtags-mode)))
;        (add-hook 'js-mode-hook (lambda () (helm-gtags-mode)))
;        (add-hook 'erlang-mode-hook (lambda () (helm-gtags-mode)))
;        :config
;        ;(custom-set-variables
;        ; '(helm-gtags-prefix-key "C-t")
;        ; '(helm-gtags-suggested-key-mapping t))
;        (setq
;         helm-gtags-ignore-case t
;         helm-gtags-auto-update t
;         helm-gtags-use-input-at-cursor t
;         helm-gtags-pulse-at-cursor t
;         helm-gtags-prefix-key "\C-cg"
;         helm-gtags-suggested-key-mapping t
;         )
;         (define-key helm-gtags-mode-map (kbd "C-]") 'helm-gtags-dwim)
;         (define-key helm-gtags-mode-map (kbd "C-t") 'helm-gtags-pop-stack)
;        ))
;  (message "%s: GNU GLOBAL not found in exec-path. helm-gtags will not be used." 'please check))

;; scheme-2
;; /usr/local/Cellar/global/6.5.5/share/gtags/gtags.el
;; gtags --gtagslabel=pygments --debug
;; or use ensure t

;; scheme-2
;; /usr/local/Cellar/global/6.5.5/share/gtags/gtags.el
;; gtags --gtagslabel=pygments --debug
;; (use-package gtags :ensure t)
(require 'gtags)
(use-package bpr :ensure t)

;; Bind some useful keys in the gtags select buffer that evil overrides.
(add-hook 'gtags-select-mode-hook
          (lambda ()
            (evil-define-key 'normal gtags-select-mode-map (kbd "RET") 'gtags-select-tag)
            (evil-define-key 'normal gtags-select-mode-map (kbd "q") 'kill-buffer-and-window)))

(defun gtags-reindex ()
  "Kick off gtags reindexing."
  (interactive)
  (let* ((root-path (expand-file-name (vc-git-root (buffer-file-name))))
         (gtags-filename (expand-file-name "GTAGS" root-path)))
    (if (file-exists-p gtags-filename)
      (gtags-index-update root-path)
      (gtags-index-initial root-path))))

(defun gtags-index-initial (path)
  "Generate initial GTAGS files for PATH."
  (let ((bpr-process-directory path))
    (bpr-spawn "gtags")))

(defun gtags-index-update (path)
  "Update GTAGS in PATH."
  (let ((bpr-process-directory path))
    (bpr-spawn "global -uv")))

;-------------------------------------------------------
(use-package dumb-jump
             :ensure nil
             :bind (("M-g o" . dumb-jump-go-other-window)
                    ("M-g j" . dumb-jump-go)
                    ("M-g ." . dumb-jump-back)
                    ("M-g i" . dumb-jump-go-prompt)
                    ("M-g x" . dumb-jump-go-prefer-external)
                    ("M-g z" . dumb-jump-go-prefer-external-other-window))
             :config (setq dumb-jump-selector 'helm) ;; (setq dumb-jump-selector 'ivy)
             )

;;--------------------------------------------------------------
;; sh-mode
;;--------------------------------------------------------------
(use-package sh-script
             :defer t
             :config (setq sh-basic-offset 4))

(use-package eldoc
             :diminish eldoc-mode
             :init  (setq eldoc-idle-delay 0.1))

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

;;---------------------------------------------------------------
;; Erlang
;;---------------------------------------------------------------
(let* ((emacs-version "3.1")
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

(eval-after-load "erlang" '(define-key erlang-mode-map (kbd "C-c b") 'erlang-insert-binary))

(add-to-list 'auto-mode-alist '("rebar.config" . erlang-mode)) ;; rebar
(add-to-list 'auto-mode-alist '("rebar.config.script" . erlang-mode)) ;; rebar
(add-to-list 'auto-mode-alist '("app.config" . erlang-mode)) ;; embedded node/riak
(add-to-list 'auto-mode-alist '("\\.src$" . erlang-mode)) ;; User customizations file
(add-to-list 'auto-mode-alist '("\\.erlang$" . erlang-mode)) ;; User customizations file
(add-to-list 'auto-mode-alist '("\\.erl$" . erlang-mode)) ;; User customizations file
(add-to-list 'auto-mode-alist '("\\.hrl" . erlang-mode)) ;; User customizations file

;;;----------------------------------------------------------------------------
;;; lua
;;;----------------------------------------------------------------------------
(use-package lua-mode
             :ensure t
             :defer t
             :mode "\\.lua\\'"
             :init
             (add-hook 'lua-mode-hook
                       (lambda ()
                         (setq lua-indent-level 4)
                         (auto-complete-mode)
                         (hs-minor-mode)
                         (turn-on-font-lock)
                         )
                       )
             )

;; get lua man page
(defun get-lua-man ()
  (interactive)
  (let* ((man-path "/usr/local/Cellar/lua/5.2.4_4/share/man")
         (man-args (format "-M %s %s" man-path (current-word))))
    (man man-args)))

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
;;----------------------------------------------------------------------------
(use-package company-go
             :ensure t
             :defer t
             :init
             (with-eval-after-load 'company
                                   (add-to-list 'company-backends 'company-go)))

(use-package go-eldoc
             :ensure t
             :defer
             :init
             (add-hook 'go-mode-hook 'go-eldoc-setup))

(use-package go-mode
 :config
 (bind-keys :map go-mode-map
  ("C-," . godef-jump)
  ("C-;" . pop-tag-mark)
  )
 (add-hook 'go-mode-hook '(lambda () (setq tab-width 2)))
 (setq gofmt-command "goimports")
 (add-hook 'before-save-hook 'gofmt-before-save))

;;----------------------------------------------------------------------------
;; es6
;;----------------------------------------------------------------------------
(add-to-list 'auto-mode-alist '("\\.js\\'" . js2-mode))
(add-to-list 'auto-mode-alist '("\\.js[x]?\\'" . web-mode))
(use-package js2-mode
             :config (setq js2-basic-offset 2))

;; force web-mode’s content type as jsx for .js and .jsx files
(use-package web-mode :ensure t)

(defun my-web-mode-hook ()
  "Hooks for Web mode. Adjust indents"
  (setq web-mode-enable-current-column-highlight t)
  (setq web-mode-markup-indent-offset 2)
  (setq web-mode-css-indent-offset 2)
  (setq web-mode-code-indent-offset 2))

(add-hook 'web-mode-hook  'my-web-mode-hook)

(setq web-mode-content-types-alist
  '(("jsx" . "\\.js[x]?\\'")))

(defadvice web-mode-highlight-part (around tweak-jsx activate)
  (if (equal web-mode-content-type "jsx")
    (let ((web-mode-enable-part-face nil))
      ad-do-it)
    ad-do-it))

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
(use-package markdown-mode
             :defer t
             :config
             (progn
               (add-to-list 'auto-mode-alist '("\\.text\\'" . markdown-mode))
               (add-to-list 'auto-mode-alist '("\\.markdown\\'" . markdown-mode))
               (add-to-list 'auto-mode-alist '("\\.md\\'" . markdown-mode)))
             (add-hook 'markdown-mode-hook
                       (lambda ()
                         (set-fill-column 80)
                         (turn-on-auto-fill)
                         (flyspell-mode)
                         (visual-line-mode t)
                         (writegood-mode t)
                         (flyspell-mode t)))
             (setq markdown-command "pandoc --smart -f markdown -t html")
             ;(setq markdown-css-paths `(,(expand-file-name "markdown.css" vendor-dir)))
             )
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
(setq auto-insert-query t)
(add-hook 'find-file-hooks 'auto-insert)
;(setq auto-insert-directory "~/.emacs.d/vendor/auto-insert/")
(setq auto-insert-alist
      (append
       '(
         (("\\\\.el\\\\'" . "Emacs Lisp header")
          "Short description: "
          ";;; " (file-name-nondirectory (buffer-file-name)) " --- " str "
;; Copyright (C) " (substring (current-time-string) -4) " by robert zhou " "
;; Author: robert zhou"
'(end-of-line 1) " <" (user-login-name) ?@ "robertzhouxh@gmail.com>
(defconst "
(substring (file-name-nondirectory (buffer-file-name)) 0 -3)
"-version \\"$Id: "
(file-name-nondirectory (buffer-file-name))
",v 1.1 "
'(require 'time-stamp)
(concat (time-stamp-yyyy/mm/dd) " " (time-stamp-hh:mm:ss))
" matsu Exp matsu $\\")" "
;; Keywords: "
 '(require 'finder)
 ;;'(setq v1 (apply 'vector (mapcar 'car finder-known-keywords)))
 '(setq v1 (mapcar (lambda (x) (list (symbol-name (car x))))
                   finder-known-keywords)
        v2 (mapconcat (lambda (x) (format "%10.0s:  %s" (car x) (cdr x)))
           finder-known-keywords
           "\\n"))
 ((let ((minibuffer-help-form v2))
    (completing-read "Keyword, C-h: " v1 nil t))
    str ", ") & -2 "
;;
;; This program is free software; you can redistribute it and/or modify
(中略)
;;; Commentary:
;; " _ "
;;; Code:
;;; " (file-name-nondirectory (buffer-file-name)) " ends here"))
       auto-insert-alist))

(setq auto-insert-alist
      (append '(
                (("\\.go$" . "golang header")
                 nil
                 "//---------------------------------------------------------------------\n"
                 "// @Copyright (c) 2016-2017 MOLMC Enterprise, Inc. (http://intoyun.com)\n"
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
                 "%%% @Copyright (c) 2016-2017 MOLMC Enterprise, Inc. (http://intoyun.com)\n"
                 "%%% @Author: robertzhouxh <robertzhouxh@gmail.com>\n"
                 "%%% @Date   Created: " (format-time-string "%Y-%m-%d %H:%M:%S")"\n"
                 "%%%-------------------------------------------------------------------\n"
                 _
                 ))
              auto-insert-alist))

(setq auto-insert-alist
      (append '(
                (("\\.org$" . "org header")
                 nil
                 "#+HTML_HEAD: <link rel=\"stylesheet\" href=\"http://dakrone.github.io/org.css\" type=\"text/css\" />"
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
