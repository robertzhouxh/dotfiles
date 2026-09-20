;;; emacs-solo-lazycat-theme.el --- lazycat-theme 上游 bug 的启动时幂等补丁 -*- lexical-binding: t; -*-

;; Package-Requires: ((emacs "30.1"))

;; lazycat-theme（:vc :rev :newest）有两个上游没修的 bug，且每次启动 `git pull`
;; 都会把本地手改的文件还原，所以这里用「启动时幂等补丁」：只在文件缺修补时写盘，
;; 更新后下一轮自动再补。
;;
;;   1. dark/light 子文件缺 lexical-binding cookie，加载时弹
;;      `Warning (files): Missing 'lexical-binding' cookie'。
;;   2. 主文件的 custom-button 一族 face 用了 `:box '(:line-width 1 :style none)'，
;;      Emacs 31 不再接受 `:style none'（合法值只有 released-button /
;;      pressed-button / flat-button / nil），defface 展开时报 "Invalid face box"
;;      让 GUI 起不来。

;;; Code:

(defun emacs-solo-lazycat-theme-ensure-cookie ()
  "Ensure lazycat-theme's dark/light files carry a lexical-binding cookie."
  (let ((lib (locate-library "lazycat-theme")))
    (when lib
      (let ((dir (file-name-directory lib)))
        (dolist (f '("lazycat-dark-theme.el" "lazycat-light-theme.el"))
          (let ((file (expand-file-name f dir)))
            (when (file-readable-p file)
              (with-temp-buffer
                (insert-file-contents file)
                (goto-char (point-min))
                (end-of-line)
                (let ((first-line (buffer-substring-no-properties (point-min) (point))))
                  (when (and (string-prefix-p ";;; " first-line)
                             (string-match-p "\\.el --- " first-line)
                             (not (string-match-p "lexical-binding" first-line)))
                    (insert " -*- lexical-binding: t; -*-")
                    (write-region (point-min) (point-max) file nil 'quiet)))))))))))

;; `:style none' 的补丁必须在 :init（:vc 之后、require 之前）里跑：主文件的
;; `defvar lazycat-themes-base-faces' 在 require 时读进内存，`:config' 里再改盘
;; 已经来不及了。
(defun emacs-solo-lazycat-theme-ensure-box-style ()
  "Strip the invalid `:style none' from lazycat-theme's `:box' face specs."
  (let ((lib (locate-library "lazycat-theme")))
    (when lib
      (let ((file (expand-file-name "lazycat-theme.el" (file-name-directory lib))))
        (when (file-writable-p file)
          (with-temp-buffer
            (insert-file-contents file)
            (let ((changed nil))
              (goto-char (point-min))
              (while (re-search-forward " :style none" nil t)
                (replace-match "")
                (setq changed t))
              (when changed
                (write-region (point-min) (point-max) file nil 'quiet)))))))))

(provide 'emacs-solo-lazycat-theme)
;;; emacs-solo-lazycat-theme.el ends here
