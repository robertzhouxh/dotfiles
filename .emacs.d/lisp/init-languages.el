;;; init-languages.el
;;; Commentary:

;; Remote SSH
;; C-x C-f /remotehost:filename RET (or /method:user@remotehost:filename)
;; type C-x C-f /ssh:root@ssb.willschenk.com:/etc/host= it connects over ssh to the remote server and edits that file. 
;; dired mode also works, so if you want to move around just C-x C-f and select the directory, then you can navigate around as you normally would.
;; C-x C-f /sudo::/etc/hosts
;; Another fun trick is to edit a file inside of a docker container. Is this what docker is used for? No,
;; but it’s sometimes useful if you are debugging a docker file or whatever and need a tigher feedback loop.
(use-package tramp
  :config
  (setq tramp-default-method "ssh"
	tramp-auto-save-directory (expand-file-name "~/.emacs.d/auto-save-list")))

;; Open files in Docker containers like so: /docker:drunk_bardeen:/etc/passwd
(push
 (cons
  "docker"
  '((tramp-login-program "docker")
    (tramp-login-args (("exec" "-it") ("%h") ("/bin/bash")))
    (tramp-remote-shell "/bin/sh")
    (tramp-remote-shell-args ("-i") ("-c"))))
 tramp-methods)

(defadvice tramp-completion-handle-file-name-all-completions
  (around dotemacs-completion-docker activate)
  "(tramp-completion-handle-file-name-all-completions \"\" \"/docker:\" returns
    a list of active Docker container names, followed by colons."
  (if (equal (ad-get-arg 1) "/docker:")
      (let* ((dockernames-raw (shell-command-to-string "docker ps | awk '$NF != \"NAMES\" { print $NF \":\" }'"))
             (dockernames (cl-remove-if-not
                           #'(lambda (dockerline) (string-match ":$" dockerline))
                           (split-string dockernames-raw "\n"))))
        (setq ad-return-value dockernames))
    ad-do-it))

; To try this out, we can spin up a quick server like this
; docker run --rm -p 6379:6379 --name redis_container redis
; And then look at files inside of it using
; C-x C-f /docker:redis_container:/

; Inside a docker container on a remote host
; We can also chain things together! Lets say that we have a docker container named ssb-pub running on a remote host ssb.willschenk.com, we can connect to it using:
; C-x C-f /ssh:root@ssb.willschenk.com|docker:ssb-pub:/

;;---------------------------------------------------------
;; Golang
;; export GO111MODULE=on
;; go get golang.org/x/tools/gopls@latest
;; go get golang.org/x/tools/cmd/goimports
;;---------------------------------------------------------

(defun lsp-go-install-save-hooks()
  (add-hook 'before-save-hook #'lsp-format-buffer t t)
  (add-hook 'before-save-hook #'lsp-organize-imports t t))

(use-package go-mode
  :mode (("\\.go\\'" . go-mode))
  :init
  (add-hook 'go-mode-hook #'lsp-go-install-save-hooks))
;
;;; Language Server
;(use-package lsp-mode
;  :hook
;  (go-mode . lsp-deferred)
;  :commands (lsp lsp-deferred))
;(use-package lsp-ui :commands lsp-ui-mode)

(use-package lsp-mode
  :ensure t
  :custom
  ;; debug
  (lsp-print-io nil)
  (lsp-trace nil)
  (lsp-print-performance nil)
  ;; general
  (lsp-auto-guess-root t)
  (lsp-document-sync-method 'incremental) ;; always send incremental document
  (lsp-response-timeout 5)
  (lsp-prefer-flymake 'flymake)
  (lsp-enable-completion-at-point nil)
  :hook
  (go-mode . lsp)
  :bind
  (:map lsp-mode-map
  ("C-c r"   . lsp-rename))
  :config
  ;(require 'lsp-clients)
  (use-package lsp-ui
    :ensure t
    :custom
    ;; lsp-ui-doc
    (lsp-ui-doc-enable t)
    (lsp-ui-doc-header t)
    (lsp-ui-doc-include-signature t)
    (lsp-ui-doc-position 'top) ;; top, bottom, or at-point
    (lsp-ui-doc-max-width 150)
    (lsp-ui-doc-max-height 30)
    (lsp-ui-doc-use-childframe t)
    (lsp-ui-doc-use-webkit t)
    ;; lsp-ui-flycheck
    (lsp-ui-flycheck-enable nil)
    ;; lsp-ui-sideline
    (lsp-ui-sideline-enable nil)
    (lsp-ui-sideline-ignore-duplicate t)
    (lsp-ui-sideline-show-symbol t)
    (lsp-ui-sideline-show-hover t)
    (lsp-ui-sideline-show-diagnostics nil)
    (lsp-ui-sideline-show-code-actions nil)
    ;; lsp-ui-imenu
    (lsp-ui-imenu-enable nil)
    (lsp-ui-imenu-kind-position 'top)
    ;; lsp-ui-peek
    (lsp-ui-peek-enable t)
    (lsp-ui-peek-peek-height 20)
    (lsp-ui-peek-list-width 50)
    (lsp-ui-peek-fontify 'on-demand) ;; never, on-demand, or always
    :preface
    (defun ladicle/toggle-lsp-ui-doc ()
      (interactive)
      (if lsp-ui-doc-mode
        (progn
          (lsp-ui-doc-mode -1)
          (lsp-ui-doc--hide-frame))
         (lsp-ui-doc-mode 1)))
    :bind
    (:map lsp-mode-map
    ("C-c C-r" . lsp-ui-peek-find-references)
    ("C-c C-j" . lsp-ui-peek-find-definitions)
    ("C-c i"   . lsp-ui-peek-find-implementation)
    ("C-c m"   . lsp-ui-imenu)
    ("C-c s"   . lsp-ui-sideline-mode)
    ("C-c d"   . ladicle/toggle-lsp-ui-doc))
    :hook
    (lsp-mode . lsp-ui-mode))

  ;; Lsp completion
  (use-package company-lsp
    :ensure t
    :custom
    (company-lsp-cache-candidates t) ;; always using cache
    (company-lsp-async t)
    (company-lsp-enable-recompletion nil)))

;;---------------------------------------------------------------
;; Erlang Programming << sed ---> gsed >>
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
;;---------------------------------------------------------------

(setq auto-mode-alist
      (reverse
       (append auto-mode-alist
	       '(("\\.rel$"         . erlang-mode)
		 ("\\.app\\.src$"   . erlang-mode)
		 ("\\.hrl$"         . erlang-mode)
		 ("\\.erl$"         . erlang-mode)
		 ("\\.yrl$"         . erlang-mode)
		 ("\\.conf$"        . erlang-mode)
		 ("\\.schema"       . erlang-mode)
		 ("rebar\\.config$" . erlang-mode)
		 ("relx\\.config$"  . erlang-mode)
		 ("sys\\.config$"   . erlang-mode)))))

;; "/usr/local/lib/erlang/lib/tools-" for mac
(let* ((emacs-version "3.4")
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
  :custom
  (ivy-erlang-complete-erlang-root '/usr/local/Cellar/erlang/23.0.3/lib/erlang)
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


;;---------------------------------------------------------
;; cc-mode
;;--------------------------------------------------------
(use-package cc-mode
  :config
  (progn
    (add-hook 'c-mode-hook (lambda () (c-set-style "bsd")))
    (add-hook 'java-mode-hook (lambda () (c-set-style "bsd")))
    (setq tab-width 4)
    (setq c-basic-offset 4)))

(use-package ccls
  :ensure t
  :custom (ccls-executable "/usr/local/bin/ccls")
  :hook ((c-mode c++-mode objc-mode) .
         (lambda () (require 'ccls) (lsp))))


;; other programming languages
(use-package sh-script
  :defer t
  :config (setq sh-basic-offset 4))

(use-package web-mode
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
  :mode (("\\.lua\\'" . lua-mode))
  :config
  (add-hook 'lua-mode-hook #'company-mode))

(use-package yaml-mode
  :config
  (add-hook 'yaml-mode-hook 'flycheck-mode)
  (add-hook 'yaml-mode-hook 'flyspell-mode))
(use-package flycheck-yamllint
  :defer t
  :init
  (progn
    (eval-after-load 'flycheck
      '(add-hook 'flycheck-mode-hook 'flycheck-yamllint-setup))))

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
