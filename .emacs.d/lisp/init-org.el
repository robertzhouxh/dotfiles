;;; init-org.el --- Set up Org Mode
;;; Commentary:
(setq auto-mode-alist (cons '("\\.org$" . org-mode) auto-mode-alist))
(setq org-todo-keywords
      '((sequence "TODO(t)" "DOING(i@/!)" "|" "DONE(d!)" "ABORT(a@)")
        (sequence "PROJECT(p)" "STARTED(s)" "WAITING(w)" "MAYBE(m)" "|")
        (sequence "REPORT(r)" "BUG(b)" "KNOWNCLAUSE(k)" "|" "FIXED(f)")
        (sequence "|" "CANCELED(c)" "DEFERRED(e)")))
(setq org-todo-keyword-faces
 '(("TODO" . "red")
   ("DONE" . "green")
   ("BUG" . "red")
   ("FIXED" . "green")
   ("PROJECT" . "yellow")
   ("STARTED" . "yellow")
   ("WAITING" . "purple")
   ("MAYBE" . "purple")
   ("CANCELED" . (:foreground "blue" :weight bold))
   ("DEFERRED" . (:foreground "blue" :weight bold))))

;添加笔记和状态变更信息(包括时间信息)，用"@"表示
;只添加状态变更信息，用"!"表示
;这个通过定义带快速选择键的关键词时，在快速选择键后用"X/Y"来表示，X表示进入该状态时的动作，Y表示离开该状态时的动作。对于一个状态(以"DONE"为例)，以下形式都是合法的:
;DONE(d@)       ; 进入时添加笔记
;DONE(d/!)      ; 离开时添加变更信息
;DONE(d@/!)     ; 进入时添加笔记，离开时添加变更信息
; 记录时间
(setq org-log-done 'time)
; 记录提示信息
(setq org-log-done 'note)
;; 添加note时 可以让org mode单独打开一个buffer用来编写note，然后输入完后按C-c C-c就 可以提交note
(setq org-clock-into-drawer t)

(setq org-agenda-show-log t
      org-agenda-todo-ignore-scheduled t
      org-agenda-todo-ignore-deadlines t)
(setq org-agenda-files (list "~/Dropbox/org/personal.org"
                             "~/Dropbox/org/groupon.org"))

(use-package org-evil :ensure t)
(use-package org-bullets
    :ensure t
    :init
    (setq org-bullets-bullet-list
          '("✡" "✽" "✲" "✱" "✻" "✼" "✽" "✾" "✿" "❀" "❁" "❂" "❃" "❄" "❅" "❆" "❇"))
    (add-hook 'org-mode-hook #'org-bullets-mode))

(add-to-list 'ispell-skip-region-alist '(":\\(PROPERTIES\\|LOGBOOK\\):" . ":END:"))
(add-to-list 'ispell-skip-region-alist '("#\\+BEGIN_SRC" . "#\\+END_SRC"))
(add-to-list 'ispell-skip-region-alist '("#\\+BEGIN_EXAMPLE" . "#\\+END_EXAMPLE"))

;; ==================== table =====================
; C-c |
; |-
; C-c C-c 在不移动光标的情况下对齐表格内容
; TAB     水平后移光标，自动对齐表格，如有需要则自动换行或追加新行
; S-TAB   水平前移光标，自动对齐表格
; RET     垂直下移光标，自动对齐，如果需要则则动换行或追加新行

; M-LEFT /      M-RIGHT 左/右移动当前列
; M-S-LEFT      删除当前列
; M-S-RIGHT     在光标左添加列

; M-UP / M-DOWN 上/下移动当前行
; M-S-UP        删除当前行或行分割线
; M-S-DOWN      在当前行上插入新行

; C-c -         在当前行下插入水平分割线
; C-c RET       在当前行下插入水平分割线，并移动光标到分割线下

; C-c ^         对当前列排序

;; ==================== Code blocks =====================
;; cd .emacs.d/elpa/org-20161102
;; rm *.elc
(setq org-plantuml-jar-path "~/.emacs.d/vendor/plantuml.jar")
(setq org-ditaa-jar-path "~/.emacs.d/vendor/ditaa0_9.jar")
(add-hook 'org-babel-after-execute-hook 'org-display-inline-images 'append)

(require 'ob)
(org-babel-do-load-languages
 'org-babel-load-languages
 '(
   (emacs-lisp . t)
   (org . t)
   ;(sh . t)
   (C . t)
   (python . t)
   (awk . t)
   (plantuml . t)
   (ditaa . t)
   ))

;; Highlight and indent source code blocks
(setq org-src-fontify-natively t)
(setq org-src-tab-acts-natively t)

;; Prevent confirmation
(setq org-confirm-babel-evaluate nil)

;; Export org-mode to Google I/O HTML5 slide.
(use-package uimage :ensure t :defer t)
(use-package htmlize
             :ensure t
             :defer t
             :commands (htmlize-buffer
                         htmlize-file
                         htmlize-many-files
                         htmlize-many-files-dired
                         htmlize-region))

(eval-after-load "org" '(require 'ox-md nil t))

(provide 'init-org)
