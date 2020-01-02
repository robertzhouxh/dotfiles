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

(provide 'init-org)
