;;; emacs-solo-lazycat-theme-test.el --- emacs-solo-lazycat-theme 门禁测试 -*- lexical-binding: t; -*-

;; 门禁测试：确定性、本地、免费、<2 秒、永不 flaky。
;; 运行：.emacs.d/test/run-tests.sh
;;
;; 覆盖两个启动时幂等补丁：
;;   1. `emacs-solo-lazycat-theme-ensure-box-style' —— 去掉 Emacs 31 不再接受的
;;      `:box' 里的 `:style none'。
;;   2. `emacs-solo-lazycat-theme-ensure-cookie' —— 补 dark/light 子文件首行缺的
;;      lexical-binding cookie。

;;; Code:

(require 'ert)
(require 'emacs-solo-lazycat-theme)

(defun eslt-test--with-fake-theme (files fn)
  "Run FN (a function taking DIR) with FILES written into a temp package dir.

FILES is an alist of (NAME . CONTENT).  The temp dir is pushed onto
`load-path' so `locate-library' resolves within it."
  (let ((dir (make-temp-file "eslt-" t)))
    (unwind-protect
        (let ((load-path (cons dir load-path)))
          (dolist (f files)
            (write-region (cdr f) nil (expand-file-name (car f) dir)))
          (funcall fn dir))
      (delete-directory dir t))))

(defun eslt-test--slurp (file)
  "Return FILE's content as a string."
  (with-temp-buffer
    (insert-file-contents file)
    (buffer-string)))

(defun eslt-test--count (needle haystack)
  "Count non-overlapping occurrences of NEEDLE in HAYSTACK."
  (let ((n 0) (start 0))
    (while (string-match (regexp-quote needle) haystack start)
      (setq n (1+ n) start (match-end 0)))
    n))

(defconst eslt-test--box-file
  (concat
   ";;; lazycat-theme.el --- a fake theme for tests\n"
   "(custom-button                  :box '(:line-width 1))\n"
   "(custom-button-unraised         :box '(:line-width 1 :style none))\n"
   "(custom-button-pressed-unraised :box '(:line-width 1 :style none))\n"
   "(custom-button-pressed          :box '(:line-width 1 :style none))\n"
   "(custom-button-mouse            :box '(:line-width 1 :style none))\n")
  "Fake lazycat-theme.el mirroring the four upstream `:style none' faces.")

(defconst eslt-test--main-file
  ";;; lazycat-theme.el --- fake main file\n"
  "Fake lazycat-theme.el used only as a `locate-library' anchor.")

(defconst eslt-test--dark-file-no-cookie
  ";;; lazycat-dark-theme.el --- Lazycat dark theme\n\n(deftheme lazycat-dark)\n"
  "Fake dark theme file missing the lexical-binding cookie.")

(defconst eslt-test--dark-file-with-cookie
  ";;; lazycat-dark-theme.el --- Lazycat dark theme -*- lexical-binding: t; -*-\n\n(deftheme lazycat-dark)\n"
  "Fake dark theme file that already carries the cookie.")

;;; ── :style none 补丁 ─────────────────────────────────────────────────────────

(ert-deftest eslt-box-style-strips-style-none ()
  (eslt-test--with-fake-theme
      `(("lazycat-theme.el" . ,eslt-test--box-file))
    (lambda (dir)
      (emacs-solo-lazycat-theme-ensure-box-style)
      (let ((out (eslt-test--slurp (expand-file-name "lazycat-theme.el" dir))))
        (should-not (string-match-p ":style none" out))
        ;; 4 patched + 1 already-valid line all collapse to :box '(:line-width 1)
        (should (= 5 (eslt-test--count ":box '(:line-width 1)" out)))
        ;; removal leaves no dangling space between the width and the closing paren
        (should-not (string-match-p ":line-width 1 +)" out))))))

(ert-deftest eslt-box-style-is-idempotent ()
  (eslt-test--with-fake-theme
      `(("lazycat-theme.el" . ,eslt-test--box-file))
    (lambda (dir)
      (emacs-solo-lazycat-theme-ensure-box-style)
      (let ((first (eslt-test--slurp (expand-file-name "lazycat-theme.el" dir))))
        (emacs-solo-lazycat-theme-ensure-box-style)
        (should (equal first (eslt-test--slurp
                              (expand-file-name "lazycat-theme.el" dir))))))))

(ert-deftest eslt-box-style-valid-file-untouched ()
  (let ((content "(custom-button :box '(:line-width 1))\n"))
    (eslt-test--with-fake-theme
        `(("lazycat-theme.el" . ,content))
      (lambda (dir)
        (emacs-solo-lazycat-theme-ensure-box-style)
        (should (equal content (eslt-test--slurp
                                (expand-file-name "lazycat-theme.el" dir))))))))

(ert-deftest eslt-box-style-missing-file-is-no-op ()
  (let ((dir (make-temp-file "eslt-empty-" t)))
    (unwind-protect
        (let ((load-path (cons dir load-path)))
          (emacs-solo-lazycat-theme-ensure-box-style)
          (should t))
      (delete-directory dir t))))

;;; ── cookie 补丁 ──────────────────────────────────────────────────────────────

(ert-deftest eslt-cookie-adds-when-missing ()
  (eslt-test--with-fake-theme
      `(("lazycat-theme.el" . ,eslt-test--main-file)
        ("lazycat-dark-theme.el" . ,eslt-test--dark-file-no-cookie)
        ("lazycat-light-theme.el" . ,eslt-test--dark-file-no-cookie))
    (lambda (dir)
      (emacs-solo-lazycat-theme-ensure-cookie)
      (dolist (f '("lazycat-dark-theme.el" "lazycat-light-theme.el"))
        (let ((first-line (car (split-string
                                (eslt-test--slurp (expand-file-name f dir))
                                "\n"))))
          (should (string-match-p "-\\*- lexical-binding" first-line)))))))

(ert-deftest eslt-cookie-is-idempotent ()
  (eslt-test--with-fake-theme
      `(("lazycat-theme.el" . ,eslt-test--main-file)
        ("lazycat-dark-theme.el" . ,eslt-test--dark-file-no-cookie))
    (lambda (dir)
      (emacs-solo-lazycat-theme-ensure-cookie)
      (let ((first (eslt-test--slurp (expand-file-name "lazycat-dark-theme.el" dir))))
        (emacs-solo-lazycat-theme-ensure-cookie)
        (should (equal first (eslt-test--slurp
                              (expand-file-name "lazycat-dark-theme.el" dir))))))))

(ert-deftest eslt-cookie-preserves-existing ()
  (let ((content eslt-test--dark-file-with-cookie))
    (eslt-test--with-fake-theme
        `(("lazycat-theme.el" . ,eslt-test--main-file)
          ("lazycat-dark-theme.el" . ,content))
      (lambda (dir)
        (emacs-solo-lazycat-theme-ensure-cookie)
        (should (equal content (eslt-test--slurp
                                (expand-file-name "lazycat-dark-theme.el" dir))))))))

(ert-deftest eslt-cookie-skips-non-header-first-line ()
  (let ((content "(deftheme lazycat-dark)\n"))
    (eslt-test--with-fake-theme
        `(("lazycat-theme.el" . ,eslt-test--main-file)
          ("lazycat-dark-theme.el" . ,content))
      (lambda (dir)
        (emacs-solo-lazycat-theme-ensure-cookie)
        (should (equal content (eslt-test--slurp
                                (expand-file-name "lazycat-dark-theme.el" dir))))))))

(provide 'emacs-solo-lazycat-theme-test)
;;; emacs-solo-lazycat-theme-test.el ends here
