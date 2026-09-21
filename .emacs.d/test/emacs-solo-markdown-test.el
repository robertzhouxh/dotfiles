;;; emacs-solo-markdown-test.el --- emacs-solo-markdown 门禁测试 -*- lexical-binding: t; -*-

;; 门禁测试：确定性、本地、免费、<2 秒、永不 flaky。
;; 运行：.emacs.d/test/run-tests.sh
;;
;; 反例来源：.md 里的 ```python 代码块没有任何语法高亮。根因是
;; `markdown-fontify-code-blocks-natively' 默认 nil，而配置从没打开过它——
;; markdown-mode 于是整块套一层 `markdown-pre-face'，语言语法一个不认。
;;
;; 这个开关关着时不会有任何报错，块照常显示、只是整块一个颜色，所以「文件能正常
;; 打开」这类断言抓不到它。这里正面断言**块里的关键字拿到了 `font-lock-keyword-face'**，
;; 并配一条反向断言（把开关摁回 nil 时同一段代码拿不到），证明这条测试真的对开关敏感，
;; 而不是恰好在别处被满足了。

;;; Code:

(require 'ert)
(require 'cl-lib)
(require 'emacs-solo-markdown)

;; markdown-mode 才定义这两个，而门禁跑在 `-Q' 下、上面那个 require 不负责加载它。
;; 纯声明，给字节编译器看的。
(defvar markdown-code-lang-modes)
(declare-function markdown-get-lang-mode "markdown-mode" (lang))

(defconst esm-test--file
  (or load-file-name buffer-file-name)
  "本测试文件路径。")

(defconst esm-test--repo-root
  (expand-file-name "../../" (file-name-directory esm-test--file))
  "仓库根目录。测试文件在 <repo>/.emacs.d/test/ 下，上两级即根。")

(defun esm-test--load-markdown-mode ()
  "把 markdown-mode 装进 `load-path' 并 require，成功返回非 nil。

markdown-mode 是 elpa 包，落在被 gitignore 掉的 .emacs.d/var 下，新机器上未必有；
`-Q' 又不加载用户 init，所以这里按通配自己找。装不上就返回 nil，由调用方 skip。"
  (or (require 'markdown-mode nil t)
      (let ((dirs (file-expand-wildcards
                   (expand-file-name ".emacs.d/var/packages/elpa/markdown-mode-*"
                                     esm-test--repo-root))))
        (when dirs
          ;; 目录名带版本号，取排序最后一个即最新那份
          (let ((dir (car (last (sort (copy-sequence dirs) #'string<)))))
            (let ((load-path (cons dir load-path)))
              (require 'markdown-mode nil t)))))))

(defun esm-test--config-remap-alist ()
  "从 emacs-init-langs.el 里读出 `major-mode-remap-alist' 的真实取值。

测试跑在 `-Q' 下，加载不了那个文件（它依赖一堆 elpa 包）。但这里不是另抄一份
假表——那等于用自己的假设给配置背书；而是 `read' 原文里那个 `(setq ...)' 表单，
拿到的就是配置真正会装上去的那张表。"
  (let ((file (expand-file-name ".emacs.d/lisp/emacs-init-langs.el" esm-test--repo-root)))
    (with-temp-buffer
      (insert-file-contents file)
      (goto-char (point-min))
      (search-forward "(setq major-mode-remap-alist")
      (goto-char (match-beginning 0))
      (let ((value (car (last (read (current-buffer))))))
        ;; 配置里写的是 (setq ... '((a . b) ...))，read 出来是 (quote ALIST)
        (if (and (consp value) (eq (car value) 'quote)) (cadr value) value)))))

(defun esm-test--lang-modes-without-aliases ()
  "返回剔除本模块别名条目后的 `markdown-code-lang-modes'。

`emacs-solo-markdown' 加载时 `with-eval-after-load' 已经并过一次了，所以直接拿
当前值跑另一遍合并，看到的是上一遍的结果——「该跳过」的分支永远测不到。每次
合并前都得先回到没并过的状态。

深拷贝再删：`alist-get' 的 setf 对已存在的键是就地 setcdr，不拷贝会改到
markdown-mode 的全局默认表。"
  (let ((tbl (copy-tree markdown-code-lang-modes)))
    (dolist (entry emacs-solo-markdown-code-lang-modes)
      (setq tbl (assoc-delete-all (nth 0 entry) tbl #'equal)))
    tbl))

(defun esm-test--faces-at (needle)
  "在当前 buffer 里前向搜 NEEDLE，返回该处 face 的列表。

`face' 属性可能是单个符号也可能是列表，统一成列表再断言。"
  (goto-char (point-min))
  (unless (search-forward needle nil t)
    (error "测试素材里找不到 %S" needle))
  (let ((face (get-text-property (match-beginning 0) 'face)))
    (cond ((null face) nil)
          ((listp face) face)
          (t (list face)))))

(defun esm-test--fontify-python-block (natively)
  "用 markdown-mode fontify 一段 ```python，NATIVELY 绑到原生高亮开关上。
返回块里 `def ' / `return ' / `42' 三处的 face 列表，顺序同上。"
  (with-temp-buffer
    (insert "```python\ndef foo(x):\n    return 42\n```\n")
    ;; `delay-mode-hooks'：markdown-mode-hook 上的 `markdown-toggle-inline-images'
    ;; 在 batch 里直接报 `Cannot show images'（没有图形显示）。这里要的是
    ;; font-lock 结果，不是 hook 副作用，跳过 hook 不削弱断言。
    (delay-mode-hooks (markdown-mode))
    (setq-local markdown-fontify-code-blocks-natively natively)
    (font-lock-ensure)
    (mapcar #'esm-test--faces-at '("def " "return " "42"))))

;;; 开关本身

(ert-deftest esm-native-fontification-is-on ()
  "原生代码块高亮必须开着——这是那个 bug 的直接回归点。

不依赖 markdown-mode：模块在顶层就 setq，没装包时这个变量也已绑定。"
  (should markdown-fontify-code-blocks-natively))

(ert-deftest esm-alias-table-is-well-formed ()
  "别名表三列都得立得住：标签是字符串、模式真实存在、grammar 是符号。

写错一个模式名（或指着已废弃的 `javascript-mode' 之类）不会报错，只会让那个标签
静默解析成 nil，块里一点颜色都没有。"
  (dolist (entry emacs-solo-markdown-code-lang-modes)
    (should (= 3 (length entry)))
    (should (stringp (nth 0 entry)))
    (should (fboundp (nth 1 entry)))
    (should (symbolp (nth 2 entry)))))

(ert-deftest esm-alias-ts-modes-are-remapped ()
  "别名表用到的每个 -ts-mode 都必须在配置的 `major-mode-remap-alist' 里登记过。

`markdown--lang-mode-predicate' 只认登记过的 ts-mode：没登记就判掉，连兜底的常规
模式也轮不上，直接 nil。所以「模块指了某个 ts-mode」和「配置登记了它」是一条跨
文件的隐性契约，这条断言把它钉死。"
  (let ((remap (esm-test--config-remap-alist)))
    (should remap)
    (let ((registered (mapcar #'cdr remap)))
      (dolist (entry emacs-solo-markdown-code-lang-modes)
        (should (memq (nth 1 entry) registered))))))

(ert-deftest esm-alias-table-skips-missing-grammars ()
  "grammar 没装时别把 `-ts-mode' 并进 `markdown-code-lang-modes'。

别名直指 ts-mode 会绕过 markdown-mode 自己的 grammar 检查，`treesit-parser-create'
一报错整个 fontify 就炸——比不指还糟。反过来，grammar 齐了就必须真的并进去，
否则这张表形同虚设。

本机 grammar 是齐的，只测真环境的话「跳过」那一支永远跑不到，等于没测。所以真环境
测一遍之后，再把 `treesit-language-available-p' 桩成全 nil / 全 t 各跑一遍——
两个方向都钉住。桩之前先断言这个谓词对不存在的 grammar 确实返回 nil，否则桩的是
一个真实代码里不存在的分支。"
  (skip-unless (esm-test--load-markdown-mode))
  ;; 谓词的 nil 分支真实存在（桩的不是假想行为）
  (should-not (treesit-language-available-p 'esm-test-no-such-grammar))
  ;; 真环境：装了的 grammar 必须已经并进去
  (dolist (entry emacs-solo-markdown-code-lang-modes)
    (when (treesit-language-available-p (nth 2 entry))
      (should (eq (cdr (assoc (nth 0 entry) markdown-code-lang-modes))
                  (nth 1 entry)))))
  ;; 桩成全部缺失：一条都不许并进去
  (let ((markdown-code-lang-modes (esm-test--lang-modes-without-aliases)))
    (cl-letf (((symbol-function 'treesit-language-available-p)
               (lambda (&rest _) nil)))
      (emacs-solo-markdown--merge-lang-modes))
    (dolist (entry emacs-solo-markdown-code-lang-modes)
      (should-not (eq (cdr (assoc (nth 0 entry) markdown-code-lang-modes))
                      (nth 1 entry)))))
  ;; 桩成全部齐备：每条都必须并进去，键是标签、值是主模式
  (let ((markdown-code-lang-modes (esm-test--lang-modes-without-aliases)))
    (cl-letf (((symbol-function 'treesit-language-available-p)
               (lambda (&rest _) t)))
      (emacs-solo-markdown--merge-lang-modes))
    (dolist (entry emacs-solo-markdown-code-lang-modes)
      (should (eq (cdr (assoc (nth 0 entry) markdown-code-lang-modes))
                  (nth 1 entry))))))

;;; 端到端

(ert-deftest esm-python-block-gets-syntax-highlighting ()
  "```python 块里的关键字真的拿到了 `font-lock-keyword-face'。

反向断言是这条测试的骨架：把开关摁回 nil（也就是改这个 bug 之前的行为）时同一段
代码必须拿不到——否则「拿到了」可能来自别处的 face，测试就在给错误背书。"
  (skip-unless (esm-test--load-markdown-mode))
  (let* ((major-mode-remap-alist (esm-test--config-remap-alist))
         (off (esm-test--fontify-python-block nil))
         (on (esm-test--fontify-python-block t)))
    ;; 关着：只有 markdown 自己的 pre face，没有语言语法
    (should-not (memq 'font-lock-keyword-face (nth 0 off)))
    (should-not (memq 'font-lock-keyword-face (nth 1 off)))
    ;; 开着：def / return 是关键字
    (should (memq 'font-lock-keyword-face (nth 0 on)))
    (should (memq 'font-lock-keyword-face (nth 1 on)))
    ;; markdown 那层底色不能因此丢掉
    (should (memq 'markdown-code-face (nth 0 on)))))

(ert-deftest esm-alias-tags-resolve-to-ts-modes ()
  "别名表里的标签在真实 remap 表下解析成对应的 ts-mode。

`ts' / `golang' 改这个 bug 之前解析成 nil（块里完全没颜色），`bash' 被默认项压成
`sh-mode'——都在这条断言里。grammar 没装的那条不表态：模块本来就把它让回
markdown-mode 的兜底逻辑了。"
  (skip-unless (esm-test--load-markdown-mode))
  (skip-unless (treesit-language-available-p 'python))
  (let ((major-mode-remap-alist (esm-test--config-remap-alist)))
    ;; python 不在别名表里，走启发式，顺带证明 remap 表真的接上了
    (should (eq (markdown-get-lang-mode "python") 'python-ts-mode))
    (dolist (entry emacs-solo-markdown-code-lang-modes)
      (when (treesit-language-available-p (nth 2 entry))
        (should (eq (markdown-get-lang-mode (nth 0 entry)) (nth 1 entry)))))))

(provide 'emacs-solo-markdown-test)
;;; emacs-solo-markdown-test.el ends here
