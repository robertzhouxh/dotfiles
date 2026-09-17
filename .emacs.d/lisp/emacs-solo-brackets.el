;;; emacs-solo-brackets.el --- 跳到最近的括号 -*- lexical-binding: t; -*-

;; 来源：Xah Lee, "Emacs: Move Cursor to Bracket"
;;   http://xahlee.info/emacs/emacs/emacs_navigating_keys_for_brackets.html
;; Package-Requires: ((emacs "30.1"))
;;
;; 提供两个命令：向后跳到最近的左括号、向前跳到最近的右括号。与 `forward-sexp'
;; 不同，它们不认识语法结构，只做纯文本搜索，因此在语法树残缺（正在输入的
;; 半截表达式）、非 Lisp 语言、甚至纯文本里都一样可用。
;;
;; 括号表覆盖 ASCII 与全角、CJK、数学、Dingbats 等大量 Unicode 括号。
;;
;; 键位绑定在 `emacs-init-keys.el'（C-7 / C-8）。
;; 门禁测试在同名 test/emacs-solo-brackets-test.el。

;;; Code:

(defvar xah-brackets '( "“”" "()" "[]" "{}" "<>" "＜＞" "（）" "［］" "｛｝" "⦅⦆" "〚〛" "⦃⦄" "‹›" "«»" "「」" "〈〉" "《》" "【】" "〔〕" "⦗⦘" "『』" "〖〗" "〘〙" "｢｣" "⟦⟧" "⟨⟩" "⟪⟫" "⟮⟯" "⟬⟭" "⌈⌉" "⌊⌋" "⦇⦈" "⦉⦊" "❛❜" "❝❞" "❨❩" "❪❫" "❴❵" "❬❭" "❮❯" "❰❱" "❲❳" "〈〉" "⦑⦒" "⧼⧽" "﹙﹚" "﹛﹜" "﹝﹞" "⁽⁾" "₍₎" "⦋⦌" "⦍⦎" "⦏⦐" "⁅⁆" "⸢⸣" "⸤⸥" "⟅⟆" "⦓⦔" "⦕⦖" "⸦⸧" "⸨⸩" "｟｠")
  "A list of strings, each element is a string of 2 chars, the left bracket
and a matching right bracket.
Used by
`xah-backward-left-bracket'.
`xah-forward-right-bracket'.
`xah-goto-matching-bracket'.
URL `http://xahlee.info/emacs/emacs/emacs_navigating_keys_for_brackets.html'
")

(defconst xah-left-brackets
  (regexp-opt (mapcar (lambda (x) (substring x 0 1)) xah-brackets))
  "Regex string of left bracket chars. Generated from `xah-brackets'.
URL `http://xahlee.info/emacs/emacs/emacs_navigating_keys_for_brackets.html'
")

(defconst xah-right-brackets
  (regexp-opt (mapcar (lambda (x) (substring x 1 2)) xah-brackets))
  "Regex string of right bracket chars. Generated from `xah-brackets'.
URL `http://xahlee.info/emacs/emacs/emacs_navigating_keys_for_brackets.html'
")

(defun xah-backward-left-bracket ()
  "Move cursor to the previous occurrence of left bracket.
The list of brackets to jump to is defined by `xah-left-brackets'.

URL `http://xahlee.info/emacs/emacs/emacs_navigating_keys_for_brackets.html'
Created: 2015-10-01
Version: 2026-07-09"
  (interactive)
  (re-search-backward xah-left-brackets nil t))

(defun xah-forward-right-bracket ()
  "Move cursor to the next occurrence of right bracket.
The list of brackets to jump to is defined by `xah-right-brackets'.

URL `http://xahlee.info/emacs/emacs/emacs_navigating_keys_for_brackets.html'
Created: 2015-10-01
Version: 2026-07-09"
  (interactive)
  (re-search-forward xah-right-brackets nil t))

(provide 'emacs-solo-brackets)
;;; emacs-solo-brackets.el ends here
