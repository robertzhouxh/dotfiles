;;; emacs-solo-markdown.el --- Markdown 代码块按语言高亮 -*- lexical-binding: t; -*-

;; Package-Requires: ((emacs "30.1"))

;; markdown-mode 默认**不**对代码块做语言级 font-lock：`markdown-fontify-code-blocks-natively'
;; 默认 nil，`markdown-fontify-code-blocks-generic' 于是走 else 分支，整块套一层
;; `markdown-pre-face' —— ```python 里的 def / return / 字符串 / 数字一个都不亮。
;; 打开之后 markdown-mode 会把块内容丢进语言主模式的临时 buffer 过一遍
;; `font-lock-ensure'，再把 face 拷回原 buffer。
;;
;; 块里用的是不是 Tree-sitter 主模式，由两件事共同决定，缺一不可：
;;
;;   1. `markdown-get-lang-mode' 按语言标签找模式：先查 `markdown-code-lang-modes'，
;;      再试 `<lang>-ts-mode'，最后落到 `<lang>-mode'。
;;   2. `markdown--lang-mode-predicate' 只认「在 `major-mode-remap-alist' 或
;;      `auto-mode-alist' 里登记过」的 `-ts-mode'（防某个 ts-mode 抢走用户的 auto-mode）。
;;
;; emacs-init-langs.el 的 `major-mode-remap-alist' 正好登记了下面别名表用到的全部
;; ts-mode，所以第 2 条成立。指到没登记的 ts-mode 反而比不指还糟：谓词判掉之后
;; 兜底的常规模式也轮不上，直接解析成 nil，块里一点颜色都没有。
;; 这条跨文件契约由测试 `esm-alias-ts-modes-are-remapped' 钉住。
;;
;; `markdown-fontify-code-blocks-natively' 在文件顶层 setq、不塞进
;; `with-eval-after-load'：`defcustom' 在变量已有全局值时不覆盖它
;; （`custom-declare-variable' 只在 `default-boundp' 为 nil 时才 set-default），
;; 所以 markdown-mode 先加载还是后加载结果一样；反过来，没装 markdown-mode 的环境里
;; 这个开关也照样可断言——门禁测试正是靠这一点在包缺席时仍能跑。
;;
;; `markdown-code-lang-modes' 只能 `with-eval-after-load' 合并：整表 setq 会把
;; markdown-mode 自带的默认项（C、C++、sqlite、ocaml、ditaa…）一起丢掉。
;;
;; 门禁测试：.emacs.d/test/emacs-solo-markdown-test.el

;;; Code:

(require 'use-package)

;; ---- 编译期声明 ----
;; 这些符号都归 markdown-mode 所有，而这个文件不 `require' 它（加载点在下面的
;; `use-package'），所以字节编译时编译器看不见它们，会逐条报 free variable /
;; unknown function。声明一下即可，都不赋值，运行时行为不受影响。
(defvar markdown-fontify-code-blocks-natively)
(defvar markdown-code-lang-modes)
(defvar markdown-mode-map)
(declare-function markdown-table-at-point-p "markdown-mode")
(declare-function markdown-table-end "markdown-mode")
(declare-function markdown-table-align "markdown-mode")

;; ---- 打开原生代码块高亮 ----
(setq markdown-fontify-code-blocks-natively t)

(defconst emacs-solo-markdown-code-lang-modes
  ;; (语言标签 主模式 该主模式要的 grammar)
  '(("bash"       bash-ts-mode       bash)
    ("sh"         bash-ts-mode       bash)
    ("shell"      bash-ts-mode       bash)
    ("js"         js-ts-mode         javascript)
    ("javascript" js-ts-mode         javascript)
    ("ts"         typescript-ts-mode typescript)
    ("golang"     go-ts-mode         go)
    ("cpp"        c++-ts-mode        cpp)
    ("c++"        c++-ts-mode        cpp)
    ("C++"        c++-ts-mode        cpp))
  "补进 `markdown-code-lang-modes' 的「语言标签 → 主模式」别名表。

每条都在修一处默认行为：`bash' / `sh' / `shell' 自带默认项指 `sh-mode'，压过
ts-mode 分支；`javascript' 落到已废弃的 `javascript-mode'；`ts' / `golang' /
`cpp' 要么解析成 nil，要么落到常规模式。其余标签走 `<lang>-ts-mode' 启发式就能命中
（python、go、rust、java、css、json…），不必列。

第三列是给 `emacs-solo-markdown--merge-lang-modes' 用的 grammar 名。别名直接指
`-ts-mode' 会绕过 markdown-mode 自己的 `treesit-language-available-p' 检查：
grammar 没装时它照样把主模式当候选，但 `<lang>-ts-mode' 一初始化就
`treesit-parser-create' 报错——代码块不是没颜色，是整个 fontify 炸掉。
grammar 由 `treesit-auto' 按文件类型装，而 .md 里的代码块不触发它，所以这道闸
只能自己把。（仓库不跟踪 .emacs.d/tree-sitter/，新机器上确实可能没有。）")

(defun emacs-solo-markdown--merge-lang-modes ()
  "把 `emacs-solo-markdown-code-lang-modes' 按同键覆盖并进 `markdown-code-lang-modes'。

grammar 没装的那条跳过、不并：让 markdown-mode 自己的兜底逻辑接着管这个标签，
结果与打这张表之前一模一样（`bash' 回落到 `sh-mode'，`ts' / `golang' 解析成 nil）。"
  (dolist (entry emacs-solo-markdown-code-lang-modes)
    (let ((tag (nth 0 entry))
          (mode (nth 1 entry))
          (grammar (nth 2 entry)))
      (when (treesit-language-available-p grammar)
        (setf (alist-get tag markdown-code-lang-modes nil nil #'equal) mode)))))

(with-eval-after-load 'markdown-mode
  (emacs-solo-markdown--merge-lang-modes))

;; ---- markdown-mode 本体 ----
;; 留着 elpa 的 markdown-mode，不换 Emacs 31 内置的 markdown-ts-mode：本配置已经有
;; 一批东西挂在 markdown-mode 上（`markdown-mode-hook' 的行内图片、
;; `my/align-all-markdown-tables' 用的 `markdown-table-at-point-p' / `markdown-table-align'、
;; `markdown-mode-map' 上的 C-c C-t、lsp-bridge 的 marksman）。换 ts 版要一条条重接，
;; 而代码块高亮两边都做得到（markdown-ts-mode 的默认就开）。
(use-package markdown-mode
  :mode ("\\.md\\'" . markdown-mode)
  :commands markdown-mode
  :hook (markdown-mode . markdown-toggle-inline-images)
  :config
  (defun my/align-all-markdown-tables ()
    "对齐当前 buffer 中的所有 Markdown 表格。"
    (interactive)
    (save-excursion
      (goto-char (point-min))
      ;; 搜索每个以 | 开头的行，并检查是否在表格内
      (while (re-search-forward "^|" nil t)
        (when (markdown-table-at-point-p)
          (markdown-table-align)          ; 对齐当前表格
          (goto-char (markdown-table-end)))))) ; 跳到该表格末尾
  :bind (:map markdown-mode-map
              ("C-c C-t" . my/align-all-markdown-tables))) ; 绑定到 C-c C-t

(provide 'emacs-solo-markdown)
;;; emacs-solo-markdown.el ends here
