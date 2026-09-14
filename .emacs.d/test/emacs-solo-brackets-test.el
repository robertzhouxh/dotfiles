;;; emacs-solo-brackets-test.el --- emacs-solo-brackets 门禁测试 -*- lexical-binding: t; -*-

;; 门禁测试：确定性、本地、免费、<2 秒、永不 flaky。
;; 运行：test/run-tests.sh   （或 emacs -Q --batch -L lisp -L test -l 本文件 -f ert-run-tests-batch-and-exit）
;;
;; 覆盖三类断言：
;;   1. 数据不变量 —— 括号表结构正确（每条 2 字符、无重复、左右集合不相交）。
;;   2. 正则精确性 —— `xah-left/right-brackets' 匹配且仅匹配目标字符，
;;      既不漏匹配也不多匹配（多匹配会静默跳到错误的字符上）。
;;   3. 命令行为   —— 落点、边界失败时不移动 point、多字节、以及键位接线是否还在。

;;; Code:

(require 'ert)
(require 'cl-lib)
(require 'emacs-solo-brackets)

(defconst esb-test--root
  ;; test/ 的上一级 = .emacs.d/
  (file-name-directory
   (directory-file-name
    (file-name-directory (or load-file-name buffer-file-name))))
  "Path to the `.emacs.d' directory, used by the wiring tests.")

(defconst esb-test--left-chars
  (mapcar (lambda (p) (substring p 0 1)) xah-brackets))

(defconst esb-test--right-chars
  (mapcar (lambda (p) (substring p 1 2)) xah-brackets))

;;; ── 1. 数据不变量 ───────────────────────────────────────────────────────────

(ert-deftest esb-data-every-pair-is-two-chars ()
  "Every entry in `xah-brackets' must be a 2-char string."
  (dolist (pair xah-brackets)
    (should (stringp pair))
    (should (= 2 (length pair)))))

(ert-deftest esb-data-no-duplicate-pairs ()
  "No duplicate pairs; duplicates would make the regexps redundant."
  (should (= (length xah-brackets)
             (length (delete-dups (copy-sequence xah-brackets))))))

(ert-deftest esb-data-left-and-right-sets-are-disjoint ()
  "No char may be both a left and a right bracket.
If one were, `xah-forward-right-bracket' and `xah-backward-left-bracket'
would jump to the same char and the forward/backward pair would be
asymmetric."
  (should-not (seq-intersection esb-test--left-chars esb-test--right-chars
                                #'string=)))

(ert-deftest esb-data-left-chars-are-unique ()
  (should (= (length esb-test--left-chars)
             (length (delete-dups (copy-sequence esb-test--left-chars))))))

(ert-deftest esb-data-right-chars-are-unique ()
  (should (= (length esb-test--right-chars)
             (length (delete-dups (copy-sequence esb-test--right-chars))))))

(ert-deftest esb-data-left-bracket-precedes-its-partner-by-codepoint ()
  "Every pair's left bracket must have a lower codepoint than its right.
This is the only invariant here whose expectation comes from Unicode
rather than from `xah-brackets' itself, which makes it the one test that
catches a pair that is *reversed in the table* (e.g. \"<>\" written as
\"><\").  Every other assertion derives its expectation from the table
and will happily agree with the mistake.

Verified to hold for all 62 pairs.  If a future addition is a genuine
exception, list it explicitly here rather than deleting the check."
  (dolist (pair xah-brackets)
    (should (< (aref pair 0) (aref pair 1)))))

(ert-deftest esb-data-ascii-brackets-on-the-expected-side ()
  "Pin the ASCII brackets to the side a person would expect.
These are the ones actually typed by hand, so a reversal is
user-visible even though it breaks no structural invariant."
  (let ((ascii (lambda (chars)
                 (sort (seq-filter (lambda (c) (< (aref c 0) 128)) chars)
                       (lambda (a b) (< (aref a 0) (aref b 0)))))))
    (should (equal '("(" "<" "[" "{") (funcall ascii esb-test--left-chars)))
    (should (equal '(")" ">" "]" "}") (funcall ascii esb-test--right-chars)))))

;;; ── 2. 正则精确性 ───────────────────────────────────────────────────────────
;; `regexp-opt' hands single-char inputs to `regexp-opt-charset', which is
;; allowed to emit character *ranges* (e.g. `[<-{]').  A range spanning chars
;; that are not brackets would silently make the commands land on ordinary
;; text.  We therefore verify exact membership, not just "the brackets match".

(defun esb-test--assert-exact-match (regexp char-set lo hi)
  "Assert REGEXP matches exactly CHAR-SET over codepoints LO..HI.
Reports both directions of failure separately so a regression is diagnosable."
  (let (over-matched under-matched)
    (cl-loop for cp from lo to hi
             for s = (string cp)
             for in-set = (and (member s char-set) t)
             for matches = (and (string-match-p (concat "\\`" regexp "\\'") s) t)
             do (cond ((and matches (not in-set)) (push s over-matched))
                      ((and in-set (not matches)) (push s under-matched))))
    (should (null (nreverse over-matched)))
    (should (null (nreverse under-matched)))))

;; Ranges chosen to cover every block the bracket table draws from, plus the
;; ASCII block where a bogus range would do the most damage.
(defconst esb-test--codepoint-windows
  '((#x0000 #x007F)   ; ASCII: the over-match danger zone
    (#x2000 #x206F)   ; General Punctuation
    (#x2070 #x209F)   ; Super/subscripts
    (#x2300 #x23FF)   ; Miscellaneous Technical
    (#x2700 #x27BF)   ; Dingbats
    (#x2980 #x29FF)   ; Misc Math Symbols-B
    (#x2E00 #x2E7F)   ; Supplemental Punctuation
    (#x3000 #x303F)   ; CJK Symbols and Punctuation
    (#xFE00 #xFE6F)   ; Small Form Variants
    (#xFF00 #xFFEF))  ; Halfwidth and Fullwidth Forms
  "Codepoint windows scanned by the exactness tests.")

(ert-deftest esb-regexp-left-matches-exactly ()
  (dolist (w esb-test--codepoint-windows)
    (esb-test--assert-exact-match xah-left-brackets esb-test--left-chars
                                  (nth 0 w) (nth 1 w))))

(ert-deftest esb-regexp-right-matches-exactly ()
  (dolist (w esb-test--codepoint-windows)
    (esb-test--assert-exact-match xah-right-brackets esb-test--right-chars
                                  (nth 0 w) (nth 1 w))))

(ert-deftest esb-regexp-does-not-match-plain-double-quote ()
  "`\"\"' is the 3rd char of the `“”\"' entry and must NOT be searched for.
Treating a straight quote as a bracket would make the commands jump to
every string literal in a source file."
  (should-not (string-match-p (concat "\\`" xah-right-brackets "\\'") "\""))
  (should-not (string-match-p (concat "\\`" xah-left-brackets "\\'") "\"")))

;;; ── 3. 命令行为 ─────────────────────────────────────────────────────────────

(defun esb-test--with-text (text fn)
  "Call FN in a temp buffer containing TEXT, point at `point-min'."
  (with-temp-buffer
    (insert text)
    (goto-char (point-min))
    (funcall fn)))

(ert-deftest esb-forward-lands-after-the-right-bracket ()
  (esb-test--with-text "aa(bb[cc]dd)ee"
    (lambda ()
      (xah-forward-right-bracket)
      ;; first right bracket is `]' at index 8 (1-based 9); point goes after it
      (should (= ?\] (char-before)))
      (xah-forward-right-bracket)
      (should (= ?\) (char-before))))))

(ert-deftest esb-backward-lands-on-the-left-bracket ()
  (with-temp-buffer
    (insert "aa(bb[cc]dd)ee")
    (goto-char (point-max))
    (xah-backward-left-bracket)
    (should (= ?\[ (char-after)))
    (xah-backward-left-bracket)
    (should (= ?\( (char-after)))))

(ert-deftest esb-forward-returns-nil-and-stays-put-at-end ()
  (esb-test--with-text "a)"
    (lambda ()
      (xah-forward-right-bracket)
      (let ((pt (point)))
        (should-not (xah-forward-right-bracket))
        (should (= pt (point)))))))

(ert-deftest esb-backward-returns-nil-and-stays-put-at-start ()
  (with-temp-buffer
    (insert "a(b")
    (goto-char (point-max))
    (xah-backward-left-bracket)
    (let ((pt (point)))
      (should-not (xah-backward-left-bracket))
      (should (= pt (point))))))

(ert-deftest esb-forward-returns-nil-when-no-brackets-at-all ()
  (esb-test--with-text "no brackets here"
    (lambda ()
      (let ((pt (point)))
        (should-not (xah-forward-right-bracket))
        (should (= pt (point)))))))

(ert-deftest esb-commands-are-interactive ()
  "Both commands must be reachable via M-x."
  (should (commandp 'xah-backward-left-bracket))
  (should (commandp 'xah-forward-right-bracket)))

(ert-deftest esb-works-on-multibyte-brackets ()
  (esb-test--with-text "x「y」z"
    (lambda ()
      (xah-forward-right-bracket)
      (should (= ?」 (char-before)))
      (let ((after (point)))
        (goto-char (point-max))
        (xah-backward-left-bracket)
        (should (= ?「 (char-after)))
        (should (< (point) after))))))

(ert-deftest esb-finds-every-pair-in-the-table ()
  "For each entry, the forward command finds its right half and the
backward command finds its left half.  Catches a bracket that is listed in
`xah-brackets' but missing from the generated regexps."
  (dolist (pair xah-brackets)
    (let ((left (substring pair 0 1))
          (right (substring pair 1 2)))
      (with-temp-buffer
        (insert "a" left "x" right "b")
        (goto-char (point-min))
        (should (xah-forward-right-bracket))
        (should (equal right (char-to-string (char-before))))
        (goto-char (point-max))
        (should (xah-backward-left-bracket))
        (should (equal left (char-to-string (char-after))))))))

(ert-deftest esb-forward-treats-closing-bracket-as-text ()
  "A left bracket is not a stop for the forward command, and vice versa.
This is what makes C-7/C-8 a forward/backward pair rather than a toggle."
  (esb-test--with-text "([)]"
    (lambda ()
      (xah-forward-right-bracket)
      (should (= ?\) (char-before)))   ; skipped `[', stopped at `)'
      (xah-forward-right-bracket)
      (should (= ?\] (char-before))))))

;;; ── 4. 接线（防止模块/键位被误删） ──────────────────────────────────────────
;; 这些测试读取真实的 Lisp 形式，而不是 grep 源码行：grep 会把注释里出现的
;; `"C-7"' 误认成绑定（本项目就踩过这个坑），`read' 会剥掉注释，只留下真代码。

(defun esb-test--read-forms (file)
  "Read every top-level form in FILE."
  (with-temp-buffer
    (insert-file-contents file)
    (goto-char (point-min))
    (let (forms)
      (condition-case nil
          (while t (push (read (current-buffer)) forms))
        (end-of-file nil))
      (nreverse forms))))

(defun esb-test--normalize-command (x)
  "Return the command symbol denoted by X, unwrapping quote/function."
  (cond ((symbolp x) x)
        ((and (consp x) (memq (car x) '(quote function)) (symbolp (cadr x)))
         (cadr x))
        (t nil)))

(defun esb-test--scan-args (lst)
  "Return (KEY . COMMAND) for each adjacent key/command pair in LST.
Bindings are flat argument lists -- (general-define-key :states ... \"C-7\"
\\='cmd ...) -- so the pair is adjacent elements, not a sublist."
  (let (out)
    (while (and (consp lst) (consp (cdr lst)))
      (let ((cmd (and (stringp (car lst))
                      (esb-test--normalize-command (cadr lst)))))
        (when cmd (push (cons (car lst) cmd) out)))
      (setq lst (cdr lst)))
    out))

(defun esb-test--all-bindings (form)
  "Collect every adjacent key/command argument pair anywhere inside FORM."
  (let ((stack (list form)) out)
    (while stack
      (let ((f (pop stack)))
        (when (consp f)
          (setq out (append (esb-test--scan-args f) out))
          (let ((rest f))
            (while (consp rest)
              (push (car rest) stack)
              (setq rest (cdr rest)))))))
    out))

(defconst esb-test--key-bindings
  (let (out)
    (dolist (form (esb-test--read-forms
                   (expand-file-name "lisp/emacs-init-keys.el" esb-test--root)))
      (setq out (append out (esb-test--all-bindings form))))
    out)
  "All (KEY . COMMAND) bindings parsed out of `emacs-init-keys.el'.")

(ert-deftest esb-wiring-reader-found-some-bindings ()
  "Guard against the parser silently returning nothing, which would make
`esb-wiring-keys-are-bound' vacuously useless."
  (should (> (length esb-test--key-bindings) 20)))

(ert-deftest esb-wiring-keys-are-bound ()
  (should (eq 'xah-backward-left-bracket
              (cdr (assoc "C-7" esb-test--key-bindings))))
  (should (eq 'xah-forward-right-bracket
              (cdr (assoc "C-8" esb-test--key-bindings)))))

(ert-deftest esb-wiring-keys-are-not-double-bound ()
  "Each key must map to exactly one command."
  (dolist (key '("C-7" "C-8"))
    (should (= 1 (length (seq-filter (lambda (b) (equal key (car b)))
                                     esb-test--key-bindings))))))

(ert-deftest esb-wiring-module-is-required-by-init ()
  (let ((file (expand-file-name "init.el" esb-test--root)))
    (with-temp-buffer
      (insert-file-contents file)
      (goto-char (point-min))
      (should (search-forward "(require 'emacs-solo-brackets)" nil t)))))

(provide 'emacs-solo-brackets-test)
;;; emacs-solo-brackets-test.el ends here
