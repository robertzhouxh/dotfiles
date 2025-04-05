(setq user-full-name "zxh")
(setq user-mail-address "robertzhouxh@gmail.com")
(setq erlang-path-prefix (file-truename "~/.asdf/installs/erlang/24.3.4"))
(setq erlang-lib-tools-version "3.5.2")
(defvar zxh-emacs-root-dir (file-truename "~/.emacs.d"))
(defvar zxh-emacs-vendor-dir (concat zxh-emacs-root-dir "/vendor"))

(defconst *sys/win32* (eq system-type 'windows-nt) "Are we running on a WinTel system?")
(defconst *sys/linux* (eq system-type 'gnu/linux) "Are we running on a GNU/Linux system?")
(defconst *sys/mac* (eq system-type 'darwin) "Are we running on a Mac system?")

(defconst python-p
  (or (executable-find "python3")
      (and (executable-find "python")
           (> (length (shell-command-to-string "python --version | grep 'Python 3'")) 0)))
  "Do we have python3?")

(defconst pip-p
  (or (executable-find "pip3")
      (and (executable-find "pip")
           (> (length (shell-command-to-string "pip --version | grep 'python 3'")) 0)))
  "Do we have pip3?")

(defconst clangd-p
  (or (executable-find "clangd")  ;; usually
      (executable-find "/usr/local/opt/llvm/bin/clangd"))  ;; macOS
  "Do we have clangd?")


(when *sys/linux*
  (setq plantuml-path "/opt/plantuml/plantuml.jar")
  (defvar zxh-emacs-module-header-root "/usr/local/include")
  (defvar zxh-emacs-rime-user-data-dir (concat (getenv "HOME") "/.config/fcitx/rime/")))

(when *sys/mac*
  (setq plantuml-path "/opt/homebrew/Cellar/plantuml/1.2024.3/libexec/plantuml.jar")
  (defvar zxh-emacs-module-header-root "/Applications/Emacs.app/Contents/Resources/include/")
  (defvar zxh-emacs-rime-user-data-dir (concat (getenv "HOME") "/Library/Rime")))

(setenv "EMACS_MODULE_HEADER_ROOT" zxh-emacs-module-header-root)

;; StraightBootstrap
(defvar bootstrap-version)
(let ((bootstrap-file
       (expand-file-name "straight/repos/straight.el/bootstrap.el" user-emacs-directory))
      (bootstrap-version 7))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/radian-software/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))
(setq straight-use-package-by-default t)
(setq package-check-signature nil)

;; StraightUsePackage
(straight-use-package 'use-package)

(eval-and-compile
  (setq use-package-verbose t
        use-package-expand-minimally t
        use-package-compute-statistics t
        use-package-enable-imenu-support t))

(eval-when-compile
  (require 'use-package)
  (require 'bind-key))

(use-package diminish)

(defun add-subdirs-to-load-path (search-dir)
  (interactive)
  (let* ((dir (file-name-as-directory search-dir)))
    (dolist (subdir
             ;; 过滤出不必要的目录，提升Emacs启动速度
             (cl-remove-if
              #'(lambda (subdir)
                  (or
                   ;; 不是目录的文件都移除
                   (not (file-directory-p (concat dir subdir)))
                   ;; 父目录、 语言相关和版本控制目录都移除
                   (member subdir '("." ".."
                                    "dist" "node_modules" "__pycache__"
                                    "RCS" "CVS" "rcs" "cvs" ".git" ".github"))))
              (directory-files dir)))
      (let ((subdir-path (concat dir (file-name-as-directory subdir))))
        ;; 目录下有 .el .so .dll 文件的路径才添加到 `load-path' 中，提升Emacs启动速度
        (when (cl-some #'(lambda (subdir-file)
                           (and (file-regular-p (concat subdir-path subdir-file))
                                ;; .so .dll 文件指非Elisp语言编写的Emacs动态库
                                (member (file-name-extension subdir-file) '("el" "so" "dll"))))
                       (directory-files subdir-path))

          ;; 注意：`add-to-list' 函数的第三个参数必须为 t ，表示加到列表末尾
          ;; 这样Emacs会从父目录到子目录的顺序搜索Elisp插件，顺序反过来会导致Emacs无法正常启动
          (add-to-list 'load-path subdir-path t))

        ;; 继续递归搜索子目录
        (add-subdirs-to-load-path subdir-path)))))

(add-subdirs-to-load-path zxh-emacs-vendor-dir)

(tool-bar-mode -1)                               ;禁用工具栏
(menu-bar-mode -1)                               ;禁用菜单栏
(scroll-bar-mode -1)                             ;禁用滚动条
(tooltip-mode -1)                                ;禁用tooltips
(auto-compression-mode 1)                        ;打开压缩文件时自动解压缩
(global-hl-line-mode 1)                          ;高亮当前行
(show-paren-mode t)                              ;显示括号匹配
(global-subword-mode 1)                          ;Word移动支持 FooBar 的格式
(electric-pair-mode -1)                          ;关闭内置补全,使用smartparens

(setq echo-keystrokes 0.1)                       ;加快快捷键提示的速度
(setq kill-ring-max 1024)                        ;用一个很大的 kill ring. 这样防止我不小心删掉重要的东西
(setq mark-ring-max 1024)                        ;设置的mark ring容量
(setq eval-expression-print-length nil)          ;设置执行表达式的长度没有限制
(setq eval-expression-print-level nil)           ;设置执行表达式的深度没有限制
(setq isearch-allow-scroll t)                    ;isearch搜索时是可以滚动屏幕的
(setq enable-recursive-minibuffers t)            ;minibuffer 递归调用命令
(setq history-delete-duplicates t)               ;删除minibuffer的重复历史
(setq minibuffer-message-timeout 1)              ;显示消息超时的时间
(setq show-paren-style 'parentheses)             ;括号匹配显示但不是烦人的跳到另一个括号。
(setq blink-matching-paren nil)                  ;当插入右括号时不显示匹配的左括号
(setq message-log-max t)                         ;设置message记录全部消息, 而不用截去
(setq x-stretch-cursor t)                        ;光标在 TAB 字符上会显示为一个大方块
(setq print-escape-newlines t)                   ;显示字符窗中的换行符为 \n
(setq tramp-default-method "ssh")                ;设置传送文件默认的方法
(setq x-alt-keysym 'meta)                        ;Map Alt key to Meta
(setq confirm-kill-emacs 'y-or-n-p)              ;Yes-y, No-n
(setq confirm-kill-processes nil)                ;Automatically kill all active processes when closing Emacs
(setq ad-redefinition-action 'accept)            ;ad-handle-definition warnings are generated when functions are redefined with `defadvice',
(setq ring-bell-function 'ignore)                ;Do not noise
(setq use-dialog-box nil)                        ;never pop dialog
(setq inhibit-startup-screen t)                  ;inhibit start screen
(setq initial-scratch-message "")                ;关闭启动空白buffer, 这个buffer会干扰session恢复
(setq default-major-mode 'text-mode)             ;设置默认地主模式为TEXT模式
(setq mouse-yank-at-point t)                     ;粘贴于光标处,而不是鼠标指针处
(setq x-select-enable-clipboard t)               ;支持emacs和外部程序的粘贴
(setq frame-resize-pixelwise t)                  ;设置缩放的模式,避免Mac平台最大化窗口以后右边和下边有空隙

(setq-default cursor-type 'bar)                  ;设置光标样式。
(setq x-stretch-cursor t)                        ;光标和字符宽度一致（如 TAB)
(setq-default comment-style 'indent)             ;设定自动缩进的注释风格
(setq-default require-final-newline nil)         ;不自动添加换行符到末尾, 有些情况会出现错误
(setq-default auto-revert-mode 1)                ;自动更新buffer
(setq-default void-text-area-pointer nil)        ;禁止显示鼠标指针
(setq-default create-lockfiles nil)              ;Do not create lock files
(setq-default history-length 500)                ;Set history-length longer
(setq ediff-window-setup-function (quote ediff-setup-windows-plain)) ;比较窗口设置在同一个frame里
(setq byte-compile-warnings
      (quote (
              ;; 显示的警告
              free-vars                 ;不在当前范围的引用变量
              unresolved                ;不知道的函数
              callargs                  ;函数调用的参数和定义的不匹配
              obsolete                  ;荒废的变量和函数
              noruntime                 ;函数没有定义在运行时期
              interactive-only          ;正常不被调用的命令
              make-local ;调用 `make-variable-buffer-local' 可能会不正确的
              mapcar     ;`mapcar' 调用
              ;;
              ;; 抑制的警告
              (not redefine)        ;重新定义的函数 (比如参数数量改变)
              (not cl-functions)    ;`CL' 包中的运行时调用的函数
              )))

;; Better Compilation
(setq-default compilation-always-kill t)      ; kill compilation process before starting another
(setq-default compilation-ask-about-save nil) ; save all buffers on `compile'
(setq-default compilation-scroll-output t)

;; 滚动行为优化
(progn
  ;; 垂直滚动
  (setq scroll-step 1
        scroll-margin 3
        scroll-conservatively 101
        scroll-up-aggressively 0.01
        scroll-down-aggressively 0.01
        mouse-wheel-scroll-amount '(1 ((shift) . 1))
        mouse-wheel-progressive-speed nil)
  ;; 水平滚动
  (setq hscroll-step 1
        hscroll-margin 1))

;; 进一步优化GC触发阈值
(setq gc-cons-threshold most-positive-fixnum)
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold (* 10 1000 1000)) ;提高到10MB，平衡性能和内存使用
            (run-with-idle-timer 2 t #'garbage-collect))) ;减少到2秒的空闲时间

;; 在minibuffer活动时禁用GC
(add-hook 'minibuffer-setup-hook (lambda () (setq gc-cons-threshold most-positive-fixnum)))
(add-hook 'minibuffer-exit-hook (lambda () (setq gc-cons-threshold (* 2 1000 1000))))

;; 本地编译优化
(when (and (fboundp 'native-comp-available-p)
           (native-comp-available-p))
  (setq native-comp-async-report-warnings-errors nil
        native-comp-deferred-compilation t
        native-comp-async-jobs-number (max 1 (floor (/ (num-processors) 2)))))


;; 将长行处理相关的设置组合在一起
(progn
  ;; 长行处理
  (when (fboundp 'global-so-long-mode) (global-so-long-mode))
  (setq-default bidi-display-reordering nil
                bidi-paragraph-direction 'left-to-right)
  (setq bidi-inhibit-bpa t))


;; IO性能优化
(progn
  (setq process-adaptive-read-buffering nil)
  (setq read-process-output-max (* 2 1024 1024)) ;增加到2MB以提高LSP性能
  (setq auto-window-vscroll nil)
  (setq fast-but-imprecise-scrolling nil))

;; **全局优化行号显示**
(setq display-line-numbers-grow-only t) ;; 避免滚动时行号重绘卡顿
;; (setq display-line-numbers-type 'relative) ;; 使用相对行号（可选）

;; **所有编程模式启用行号**
(add-hook 'prog-mode-hook 'display-line-numbers-mode)

;; **额外启用行号的模式**
(add-hook 'text-mode-hook 'display-line-numbers-mode)
(add-hook 'conf-mode-hook 'display-line-numbers-mode)

;; **不想显示行号的模式**
(dolist (hook '(org-mode-hook shell-mode-hook eshell-mode-hook term-mode-hook vterm-mode-hook))
  (add-hook hook (lambda () (display-line-numbers-mode -1))))

;; 全局设置使用空格而非制表符
;;(setq-default indent-tabs-mode nil)    ;; 不使用制表符进行缩进
;;(setq-default tab-width 4)             ;; 默认 Tab 显示为 4 个空格宽度

;; 通用空格缩进函数
(defun my/use-spaces-setup ()
  "设置使用空格进行缩进。"
  (setq indent-tabs-mode nil)
  (setq tab-width 4))

;; 为所有编程模式设置空格缩进
(add-hook 'prog-mode-hook 'my/use-spaces-setup)

;; 设置 org-mode 的 tab-width 为 8
(add-hook 'org-mode-hook
          (lambda ()
            (setq-local tab-width 8)
            (setq-local indent-tabs-mode t)))  ; 使用制表符

;; Go 语言缩进设置
(add-hook 'go-mode-hook
          (lambda ()
            (setq indent-tabs-mode nil)
            (setq tab-width 4)
            (when (boundp 'go-tab-width)
              (setq go-tab-width 4))))

;; Erlang 语言缩进设置
(add-hook 'erlang-mode-hook
          (lambda ()
            (setq indent-tabs-mode nil)
            (setq tab-width 4)
            (when (boundp 'erlang-indent-level)
              (setq erlang-indent-level 4))
            (when (boundp 'erlang-tab-always-indent)
              (setq erlang-tab-always-indent t))))

;; Java 语言缩进设置
(add-hook 'java-mode-hook
          (lambda ()
            (setq indent-tabs-mode nil)
            (setq tab-width 4)
            (setq c-basic-offset 4)
            (c-set-offset 'arglist-intro '+)
            (c-set-offset 'arglist-cont 0)
            (c-set-offset 'arglist-close 0)
            (c-set-offset 'statement-cont 0)))

;; Rust 语言缩进设置
(add-hook 'rust-mode-hook
	      (lambda ()
	        (setq-local indent-tabs-mode nil
			            tab-width 4
			            rust-indent-offset 4)))

;; 支持 tree-sitter 模式
(with-eval-after-load 'treesit
  (dolist (mode-hook '((go-ts-mode-hook . go-ts-mode-indent-offset)
                       (erlang-ts-mode-hook . erlang-ts-indent-offset)
                       (java-ts-mode-hook . java-ts-mode-indent-offset)
                       (rust-ts-mode-hook . rust-ts-mode-indent-offset)))
    (let ((hook (car mode-hook))
          (offset-var (cdr mode-hook)))
      (add-hook hook
                (lambda ()
                  (setq-local  indent-tabs-mode nil)
                  (setq-local  tab-width 4))))))

(unless *sys/win32*
  (set-selection-coding-system 'utf-8)
  (prefer-coding-system 'utf-8)
  (set-language-environment "UTF-8")
  (set-default-coding-systems 'utf-8)
  (set-terminal-coding-system 'utf-8)
  (set-keyboard-coding-system 'utf-8)
  (setq locale-coding-system 'utf-8))
;; Treat clipboard input as UTF-8 string first; compound text next, etc.
(when (display-graphic-p)
  (setq x-select-request-type '(UTF8_STRING COMPOUND_TEXT TEXT STRING)))

(defun bjm/kill-this-buffer () (interactive) (kill-buffer (current-buffer)))

;; from lazycat emacs config
(defun org-export-docx ()
  (interactive)
  (let ((docx-file (concat (file-name-sans-extension (buffer-file-name)) ".docx"))
        (template-file (concat (file-name-as-directory zxh-emacs-root-dir)
                               "template.docx")))
    (message (format "pandoc %s -o %s --reference-doc=%s" (buffer-file-name) docx-file template-file))
    (shell-command (format "pandoc %s -o %s --reference-doc=%s"
                           (buffer-file-name)
                           docx-file
                           template-file
                           ))
    (message "Convert finish: %s" docx-file)))


(defun format-function-parameters ()
  "Turn the list of function parameters into multiline."
  (interactive)
  (beginning-of-line)
  (search-forward "(" (line-end-position))
  (newline-and-indent)
  (while (search-forward "," (line-end-position) t)
    (newline-and-indent))
  (end-of-line)
  (c-hungry-delete-forward)
  (insert " ")
  (search-backward ")")
  (newline-and-indent))

(defun my-org-screenshot ()
  "Take a screenshot into a time stamped unique-named file in the
  same directory as the org-buffer and insert a link to this file."
  (interactive)
  (org-display-inline-images)
  (setq filename
        (concat
         (make-temp-name
          (concat (file-name-nondirectory (buffer-file-name))
                  "assets/"
                  (format-time-string "%Y%m%d_%H%M%S_")) ) ".png"))
  (unless (file-exists-p (file-name-directory filename))
    (make-directory (file-name-directory filename)))
                                        ; take screenshot
  (if (eq system-type 'darwin)
      (call-process "screencapture" nil nil nil "-i" filename))
  (if (eq system-type 'gnu/linux)
      (call-process "import" nil nil nil filename))
                                        ; insert into file if correctly taken
  (if (file-exists-p filename)
      (insert (concat "[[file:" filename "]]"))))

(defun delete-trailing-M ()
  "Delete `^M' characters in the buffer.
                Same as `replace-string C-q C-m RET RET'."
  (interactive)
  (save-excursion
    (goto-char 0)
    (while (search-forward "\r" nil :noerror)
      (replace-match ""))))

(defun save-buffer-as-utf8 (coding-system)
  "Revert a buffer with `CODING-SYSTEM' and save as UTF-8."
  (interactive "zCoding system for visited file (default nil):")
  (revert-buffer-with-coding-system coding-system)
  (set-buffer-file-coding-system 'utf-8)
  (save-buffer))

(defun save-buffer-gbk-as-utf8 ()
  "Revert a buffer with GBK and save as UTF-8."
  (interactive)
  (save-buffer-as-utf8 'gbk))

(defun hold-line-scroll-up ()
  "Scroll the page with the cursor in the same line"
  (interactive)
  ;; move the cursor also
  (let ((tmp (current-column)))
    (scroll-up 1)
    (line-move-to-column tmp)
    (forward-line 1)))

(defun hold-line-scroll-down ()
  "Scroll the page with the cursor in the same line"
  (interactive)
  ;; move the cursor also
  (let ((tmp (current-column)))
    (scroll-down 1)
    (line-move-to-column tmp)
    (forward-line -1)))

(defun +rename-current-file (newname)
  "Rename current visiting file to NEWNAME.
          If NEWNAME is a directory, move file to it."
  (interactive
   (progn
     (unless buffer-file-name
       (user-error "No file is visiting"))
     (let ((name (read-file-name "Rename to: " nil buffer-file-name 'confirm)))
       (when (equal (file-truename name)
                    (file-truename buffer-file-name))
         (user-error "Can't rename file to itself"))
       (list name))))
  ;; NEWNAME is a directory
  (when (equal newname (file-name-as-directory newname))
    (setq newname (concat newname (file-name-nondirectory buffer-file-name))))
  (rename-file buffer-file-name newname)
  (set-visited-file-name newname)
  (rename-buffer newname))

(defun +delete-current-file (file)
  "Delete current visiting FILE."
  (interactive
   (list (or buffer-file-name
             (user-error "No file is visiting"))))
  (when (y-or-n-p (format "Really delete '%s'? " file))
    (kill-this-buffer)
    (delete-file file)))

(defun +copy-current-file (new-path &optional overwrite-p)
  "Copy current buffer's file to `NEW-PATH'.
            If `OVERWRITE-P', overwrite the destination file without
            confirmation."
  (interactive
   (progn
     (unless buffer-file-name
       (user-error "No file is visiting"))
     (list (read-file-name "Copy file to: ")
           current-prefix-arg)))
  (let ((old-path (buffer-file-name))
        (new-path (expand-file-name new-path)))
    (make-directory (file-name-directory new-path) t)
    (copy-file old-path new-path (or overwrite-p 1))))

(defun +copy-current-filename (file)
  "Copy the full path to the current FILE."
  (interactive
   (list (or buffer-file-name
             (user-error "No file is visiting"))))
  (kill-new file)
  (message "Copying '%s' to clipboard" file))

(defun +copy-current-buffer-name ()
  "Copy the name of current buffer."
  (interactive)
  (kill-new (buffer-name))
  (message "Copying '%s' to clipboard" (buffer-name)))


(defvar toggle-one-window-window-configuration nil
  "The window configuration use for `toggle-one-window'.")
(defun toggle-one-window ()
  "Toggle between window layout and one window."
  (interactive)
  (if (equal (length (cl-remove-if #'window-dedicated-p (window-list))) 1)
      (if toggle-one-window-window-configuration
          (progn
            (set-window-configuration toggle-one-window-window-configuration)
            (setq toggle-one-window-window-configuration nil))
        (message "No other windows exist."))
    (setq toggle-one-window-window-configuration (current-window-configuration))
    (delete-other-windows)))

;; ResizeWidthHeight
;; Resizes the window width based on the input
(defun resize-window-dimension (dimension)
  "Resize window by DIMENSION (width or height) with percentage input."
  (lambda (percent)
    (interactive (list (if (> (count-windows) 1)
                           (read-number (format "Set current window %s in [1~9]x10%%: " dimension))
                         (error "You need more than 1 window to execute this function!"))))
    (message "%s" percent)
    (let ((is-width (eq dimension 'width)))
      (window-resize nil
                     (- (truncate (* (/ percent 10.0)
                                     (if is-width (frame-width) (frame-height))))
                        (if is-width (window-total-width) (window-total-height)))
                     is-width))))

(defalias 'resize-window-width (resize-window-dimension 'width)
  "Resizes the window width based on percentage input.")
(defalias 'resize-window-height (resize-window-dimension 'height)
  "Resizes the window height based on percentage input.")

(defun resize-window (width delta)
  "Resize the current window's size.  If WIDTH is non-nil, resize width by some DELTA."
  (if (> (count-windows) 1)
      (window-resize nil delta width)
    (error "You need more than 1 window to execute this function!")))

;; Setup shorcuts for window resize width and height
(defun window-width-increase ()
  (interactive)
  (resize-window t 5))

(defun window-width-decrease ()
  (interactive)
  (resize-window t -5))

(defun window-height-increase ()
  (interactive)
  (resize-window nil 5))

(defun window-height-decrease ()
  (interactive)
  (resize-window nil -5))

(defun edit-configs ()
  "Opens the README.org file."
  (interactive)
  (find-file "~/.emacs.d/config.org"))

;; OrgIncludeAuto
(defun save-and-update-includes ()
  "Update the line numbers of #+INCLUDE:s in current buffer.
  Only looks at INCLUDEs that have either :range-begin or :range-end.
  This function does nothing if not in `org-mode', so you can safely
  add it to `before-save-hook'."
  (interactive)
  (when (derived-mode-p 'org-mode)
    (save-excursion
      (goto-char (point-min))
      (while (search-forward-regexp
              "^\\s-*#\\+INCLUDE: *\"\\([^\"]+\\)\".*:range-\\(begin\\|end\\)"
              nil 'noerror)
        (let* ((file (expand-file-name (match-string-no-properties 1)))
               lines begin end)
          (forward-line 0)
          (when (looking-at "^.*:range-begin *\"\\([^\"]+\\)\"")
            (setq begin (match-string-no-properties 1)))
          (when (looking-at "^.*:range-end *\"\\([^\"]+\\)\"")
            (setq end (match-string-no-properties 1)))
          (setq lines (decide-line-range file begin end))
          (when lines
            (if (looking-at ".*:lines *\"\\([-0-9]+\\)\"")
                (replace-match lines :fixedcase :literal nil 1)
              (goto-char (line-end-position))
              (insert " :lines \"" lines "\""))))))))

(add-hook 'before-save-hook #'save-and-update-includes)

(defun decide-line-range (file begin end)
  "Visit FILE and decide which lines to include.
  BEGIN and END are regexps which define the line range to use."
  (let (l r)
    (save-match-data
      (with-temp-buffer
        (insert-file-contents file)
        (goto-char (point-min))
        (if (null begin)
            (setq l "")
          (search-forward-regexp begin)
          (setq l (line-number-at-pos (match-beginning 0))))
        (if (null end)
            (setq r "")
          (search-forward-regexp end)
          (setq r (1+ (line-number-at-pos (match-end 0)))))
        (format "%s-%s" (+ l 1) (- r 1)))))) ;; Exclude wrapper

;; BetterMiniBuffer
(defun abort-minibuffer-using-mouse ()
  "Abort the minibuffer when using the mouse."
  (when (and (>= (recursion-depth) 1) (active-minibuffer-window))
    (abort-recursive-edit)))

(add-hook 'mouse-leave-buffer-hook 'abort-minibuffer-using-mouse)

;; keep the point out of the minibuffer
(setq-default minibuffer-prompt-properties '(read-only t point-entered minibuffer-avoid-prompt face minibuffer-prompt))

;; DisplayLineOverlay
(defun display-line-overlay+ (pos str &optional face)
  "Display line at POS as STR with FACE.

  FACE defaults to inheriting from default and highlight."
  (let ((ol (save-excursion
              (goto-char pos)
              (make-overlay (line-beginning-position)
                            (line-end-position)))))
    (overlay-put ol 'display str)
    (overlay-put ol 'face
                 (or face '(:background null :inherit highlight)))
    ol))

;; ReadLines
(defun read-lines (file-path)
  "Return a list of lines of a file at FILE-PATH."
  (with-temp-buffer (insert-file-contents file-path)
                    (split-string (buffer-string) "\n" t)))

(defun where-am-i ()
  "An interactive function showing function `buffer-file-name' or `buffer-name'."
  (interactive)
  (message (kill-new (if (buffer-file-name) (buffer-file-name) (buffer-name)))))

(defun watch-other-window-up ()
  "在其他窗口向上滚动一页。"
  (interactive)
  (other-window 1)
  (scroll-up-command)
  (other-window -1))

(defun watch-other-window-down ()
  "在其他窗口向下滚动一页。"
  (interactive)
  (other-window 1)
  (scroll-down-command)
  (other-window -1))

(defun watch-other-window-up-line ()
  "在其他窗口向上滚动一行。"
  (interactive)
  (other-window 1)
  (scroll-up-line)
  (other-window -1))

(defun watch-other-window-down-line ()
  "在其他窗口向下滚动一行。"
  (interactive)
  (other-window 1)
  (scroll-down-line)
  (other-window -1))

(use-package benchmark-init
  :config
  (benchmark-init/activate)
  (add-hook 'after-init-hook 'benchmark-init/deactivate))

(use-package exec-path-from-shell
  :config
  (setq exec-path-from-shell-variables '("PATH" "GOROOT" "GOPATH" "PYTHONPATH" "DEEPSEEK_API_KEY" "OPENROUTER_API_KEY"))
  (exec-path-from-shell-initialize))

(use-package protobuf-mode
  :hook (after-init . protobuf-mode))

(use-package markdown-mode
  :defer 15  ; 延迟 15 秒或按需加载
  :hook (after-init . markdown-mode))

(use-package dockerfile-mode
  :hook (after-init . dockerfile-mode))

(use-package nginx-mode
  :hook (after-init . nginx-mode))

(use-package json-mode
  :hook (after-init . json-mode))

(use-package sh-script
  :hook (after-init . sh-mode))

(use-package lua-mode
  :hook (after-init . lua-mode))

(use-package yaml-mode
  :hook (after-init . yaml-mode))

(use-package plantuml-mode
  :custom (org-plantuml-jar-path (expand-file-name plantuml-path))
  :hook (after-init . plantuml-mode))

(use-package toml-mode
  :hook (after-init . toml-mode))

(use-package restclient
  :hook (after-init . restclient-mode))

(use-package discover-my-major
  :hook (after-init . discover-my-major-mode))

;; `global-auto-revert-mode' is provided by autorevert.el (builtin)
(use-package autorevert
  :diminish
  :hook (after-init . global-auto-revert-mode)
  :init (setq auto-revert-mode-text ""))

(use-package which-key
  :diminish
  :hook (after-init . which-key-mode)
  :config
  (progn
    (which-key-mode)
    (which-key-setup-side-window-right)))


;;; 首次调用 commands 命令加载 
;;(use-package posframe)
(use-package posframe
  :commands (posframe-show posframe-hide posframe-delete-all))

(use-package sudo-edit
  :commands (sudo-edit))

(use-package comment-dwim-2
  :commands (comment-dwim-2))

(use-package ediff
  :commands (ediff-buffers ediff-files ediff-regions-wordwise ediff-directories)
  :config
  (setq ediff-keep-variants nil)
  (setq ediff-split-window-function 'split-window-horizontally)
  ;; 不创建新的 frame 来显示 Control-Panel。
  (setq ediff-window-setup-function #'ediff-setup-windows-plain))

(use-package projectile
  :diminish 
  :init (add-hook 'after-init-hook 'projectile-mode))

(use-package ivy
  :diminish
  :init
  (use-package amx :defer t)
  (use-package counsel :diminish :config (counsel-mode 1))
  (use-package swiper :defer t)
  (ivy-mode 1)
  :bind
  (("C-s" . swiper-isearch)
   ("M-y" . counsel-yank-pop)
   (:map ivy-minibuffer-map
         ("M-RET" . ivy-immediate-done))
   (:map counsel-find-file-map
         ("C-~" . counsel-goto-local-home)))
  :custom
  (ivy-use-virtual-buffers t)
  (ivy-height 10)
  (ivy-on-del-error-function nil)
  (ivy-magic-slash-non-match-action 'ivy-magic-slash-non-match-create)
  (ivy-count-format "【%d/%d】")
  (ivy-wrap t)
  :config
  (defun counsel-goto-local-home ()
    "Go to the $HOME of the local machine."
    (interactive)
    (ivy--cd "~/")))

(use-package color-rg
  :straight (color-rg :type git :host github :repo "manateelazycat/color-rg")
  :if (executable-find "rg")
  :bind ("C-M-s" . color-rg-search-input))

(use-package find-file-in-project
  :if (executable-find "find")
  :init
  (when (executable-find "fd")
    (setq ffip-use-rust-fd t)))

(use-package avy)

(use-package vundo
  :commands (vundo)
  :config
  ;; Take less on-screen space.
  (setq vundo-compact-display t)
  (custom-set-faces
   '(vundo-node ((t (:foreground "#808080"))))
   '(vundo-stem ((t (:foreground "#808080"))))
   '(vundo-highlight ((t (:foreground "#FFFF00")))))
  ;; Use `HJKL` VIM-like motion
  (define-key vundo-mode-map (kbd "l") #'vundo-forward)
  (define-key vundo-mode-map (kbd "h") #'vundo-backward)
  (define-key vundo-mode-map (kbd "j") #'vundo-next)
  (define-key vundo-mode-map (kbd "k") #'vundo-previous)
  (define-key vundo-mode-map (kbd "a") #'vundo-stem-root)
  (define-key vundo-mode-map (kbd "e") #'vundo-stem-end)
  (define-key vundo-mode-map (kbd "q") #'vundo-quit)
  (define-key vundo-mode-map (kbd "C-g") #'vundo-quit)
  (define-key vundo-mode-map (kbd "RET") #'vundo-confirm))

(use-package diff-hl
  :ensure t
  :hook ((dired-mode         . diff-hl-dired-mode-unless-remote)
         (magit-pre-refresh  . diff-hl-magit-pre-refresh)
         (magit-post-refresh . diff-hl-magit-post-refresh))
  :init
  (global-diff-hl-mode t)
  :config
  ;; When Emacs runs in terminal, show the indicators in margin instead.
  (unless (display-graphic-p)
    (diff-hl-margin-mode)))

                ;;;; 自动 revert buffer，确保 modeline 上的分支名正确，但是 CPU Profile 显示 比较影响性能，故暂不开启。
                ;;;; (setq auto-revert-check-vc-info t)
(use-package magit
  :bind (("C-x g" . magit-status))
  :custom
  ;; 在当前窗口显示 `magit-status`，commit diff（magit-diff & magit-revision）在右侧半屏
  (magit-diff-long-lines-threshold nil)
  (magit-show-long-lines-warning nil)
  (magit-display-buffer-function #'my-magit-display-buffer)
  :config
  (defun my-magit-display-buffer (buffer)
    "自定义 Magit buffer 显示策略：
  - `magit-status` 和 `magit-log` 在当前窗口打开；
  - `magit-diff` 和 `magit-revision` 在右侧半屏打开。"
    (let ((mode (buffer-local-value 'major-mode buffer)))
      (if (memq mode '(magit-diff-mode magit-revision-mode))
          (display-buffer
           buffer
           '((display-buffer-in-side-window)
             (side . right)
             (slot . 0)
             (window-width . 0.5)))  ;; 右侧窗口宽度为当前窗口的 50%
        (display-buffer
         buffer
         '((display-buffer-same-window))))))
  ;; 绑定 M-RET 让 Diff 直接在其他窗口打开
  (with-eval-after-load 'magit
    (define-key magit-status-mode-map (kbd "M-RET") #'magit-diff-visit-file-other-window)))

(defun x/config-evil-leader ()
  (evil-leader/set-leader ",")
  (evil-leader/set-key
    ","  'avy-goto-line
    "."  'avy-goto-char-2
    ":"  'eval-expression

    "ai" 'aider-transient-menu
    "ao" 'aidermacs-transient-menu
    "aa" 'align-regexp

    ;; buffer & bookmark
    "bb" 'switch-to-buffer
    "bo" 'switch-to-buffer-other-window
    "bn" '+copy-current-buffer-name
    "bv" 'revert-buffer
    "bz" 'bury-buffer         ;隐藏当前buffer
    "bZ" 'unbury-buffer         ;反隐藏当前buffer

    "bK" 'kill-other-window-buffer ;;;关闭其他窗口的buffer

    ;; code
    "cc" 'comment-dwim
    "cd" 'delete-trailing-whitespace
    "cl" 'toggle-truncate-lines
    "cm" 'delete-trailing-M
    "cf" 'format-function-parameters        ;; 参数列转行

    ;; dired
    "d" '(lambda () (interactive) (eaf-open-in-file-manager (file-name-directory (buffer-file-name))))

    ;; external Apps
    "es" 'my-org-screenshot
    "eo" 'org-export-docx

    ;; file
    "fh" '(lambda () (interactive) (eaf-open-in-file-manager "~/"))
    "fe" '(lambda () (interactive) (find-file (expand-file-name "config.org" user-emacs-directory)))
    "fi" '(lambda () (interactive) (load-file (expand-file-name "init.el" user-emacs-directory)))
    "ff" 'find-file
    "fO" 'find-file-other-frame
    "fo" 'find-file-other-window
    "fd" '+delete-current-file
    "fn" '+copy-current-filename
    "fr" '+rename-current-file
    "fR" 'recentf-open-files

    ;; magit
    "gs" 'magit-status
    "gb" 'magit-branch-checkout
    "gp" 'magit-pull
    "gt" 'magit-blame-toggle
    "gm" 'one-key-menu-git
    "go" 'eaf-open-git
    "gh" 'eaf-git-show-history

    ;; magit-blame
    ;; 可以在 magit-status (C-x g) 里进入 l（log）菜单后，选择 b（blame）来查看文件的 blame 记录
    "mb" 'magit-blame           ;;默认完整模式
    "ma" 'magit-blame-addition  ;;仅显示新增的 commit 影响
    "md" 'magit-blame-delete    ;;仅显示删除的 commit 影响
    "mq" 'magit-blame-quit      ;;仅显示删除的 commit 影响
    "mj" 'discover-my-major

    ;; project
    "pf" 'ffip
    ;;"pf" 'projectile-find-file
    "pb" 'projectile-switch-to-buffer
    "pp" 'projectile-switch-project
    "pk" 'projectile-kill-buffers

    ;; search
    "sI" 'imenu
    "sr" 'counsel-rg
    "sy" 'counsel-yank-pop
    "sb" 'counsel-ibuffer
    "si" 'color-rg-search-input
    "ss" 'color-rg-search-symbol-in-project
    "sp" 'color-rg-search-project

    ;; terminal
    "tn" 'sort-tab-next
    "tp" 'sort-tab-previous
    "T"  'eaf-open-pyqterminal

    ;; window && frame
    "ww" 'other-window
    "wf" 'other-frame

    ;; fold
    "zz" 'treesit-fold-open
    "zZ" 'treesit-fold-open-recursively
    "zc" 'treesit-fold-close
    "zC" 'treesit-fold-close-all
    "za" 'treesit-fold-open-all
    "zt" 'treesit-fold-toggle
    ))

(use-package undo-fu :straight t :ensure t)
(use-package evil
  ;; :bind (("<escape>" . keyboard-escape-quit))
  :init
  ;; allows for using cgn
  ;; (setq evil-search-module 'evil-search)
  (setq evil-want-keybinding nil)
  ;; no vim insert bindings
  (setq evil-undo-system 'undo-fu)
  (setq evil-disable-insert-state-bindings t)
  (setq evil-want-C-u-scroll t)
  (setq evil-esc-delay 0)
  :config
  (evil-mode 1))

(use-package evil-leader
  :init
  (progn
    (global-evil-leader-mode)
    (setq evil-leader/in-all-states 1)
    (x/config-evil-leader)))

;; {{ specify major mode uses Evil (vim) NORMAL state or EMACS original state.
;; You may delete this setup to use Evil NORMAL state always.
(dolist (p '((minibuffer-inactive-mode . emacs)
             (magit-log-edit-mode . emacs)
             (magit-status-mode . emacs)
             (magit-revision . normal)
             (color-rg-mode . emacs)
             (eaf-mode . emacs)
             (comint-mode . emacs)
             (dired-mode . normal)
             (fundamental-mode . normal)
             (grep-mode . emacs)
             (Info-mode . emacs)
             (sdcv-mode . emacs)
             (dashboard-mode . normal)
             (log-edit-mode . emacs)
             (vc-log-edit-mode . emacs)
             (help-mode . emacs)
             (xref--xref-buffer-mode . emacs)
             (compilation-mode . emacs)
             (speedbar-mode . emacs)
             (ivy-occur-mode . emacs)
             (ivy-occur-grep-mode . normal)
             (messages-buffer-mode . normal)
             ))
  (evil-set-initial-state (car p) (cdr p)))

;; 文件操作库
(use-package f :defer t)

;; 多模式编辑支持
(use-package polymode :defer t)

;; Org 表格对齐增强
(use-package valign
  :diminish
  :custom
  (valign-fancy-bar t)
  :hook (org-mode . valign-mode))

;; Org 文档目录自动生成
(use-package toc-org
  :defer t
  :hook (org-mode . toc-org-mode))

;; Org Babel 代码块自动 Tangle
(use-package org-auto-tangle
  :diminish
  :hook (org-mode . org-auto-tangle-mode)
  :custom (org-auto-tangle-default t))

(use-package dslide
  ;; :vc (:url "https://github.com/positron-solutions/dslide.git")
  :straight (dslide :type git :host github :repo "positron-solutions/dslide")
  :after org
  :commands (dslide-deck-start dslide-deck-stop)
  :hook
  ((dslide-start
    .
    (lambda ()
      (org-fold-hide-block-all)
      (setq-default x-stretch-cursor -1)
      (redraw-display)
      (blink-cursor-mode -1)
      (setq cursor-type 'bar)
      ;; (org-display-inline-images)
      ;; (hl-line-mode -1)
      (text-scale-increase 2)
      (read-only-mode 1)))
   (dslide-stop
    .
    (lambda ()
      (blink-cursor-mode +1)
      (setq-default x-stretch-cursor t)
      (setq cursor-type t)
      (text-scale-increase 0)
      ;; (hl-line-mode 1)
      (read-only-mode -1))))
  :init
  (setq dslide-margin-content 0.5)
  (setq dslide-animation-duration 0.5)
  (setq dslide-margin-title-above 0.3)
  (setq dslide-margin-title-below 0.3)
  (setq dslide-header-email nil)
  (setq dslide-header-date nil)
  :config
  (with-eval-after-load 'org
    (define-key org-mode-map (kbd "<f8>") #'dslide-deck-start))
  (with-eval-after-load 'dslide
    (define-key dslide-mode-map (kbd "<f9>") #'dslide-deck-stop)))

(use-package image-slicing
  :straight (image-slicing :type git :host github :repo "ginqi7/image-slicing")
  :hook (org-mode . image-slicing-mode)
  :custom
  (image-slicing-line-height-scale 2)
  (image-slicing-max-width 800))

(use-package org-download
  :commands (org-download-enable org-download-screenshot)
  :hook (dired-mode . org-download-enable)
  :init
  ;; 设置默认的图片保存目录
  (setq-default org-download-image-dir "./static/images/")
  (setq org-download-method 'directory
        org-download-display-inline-images 'posframe
        org-download-image-attr-list '("#+ATTR_HTML: :width 800 :align left"))
  ;; 不添加 #+DOWNLOADED: 注释
  (setq org-download-annotate-function (lambda (link) (previous-line 1) "")))

(use-package ob-go)
(use-package ob-rust)
(use-package org
  :straight (:type built-in)
  :bind (("C-c l" . org-store-link)  ;; 快速存储链接
         ("C-c c" . org-capture)     ;; 进入 Org Capture
         (:map org-mode-map
               (("C-c C-p" . eaf-org-export-to-pdf-and-open) ;; EAF 方式导出 PDF 并打开
                ("C-c ;" . nil))))  ;; 取消 C-c ; 绑定，避免冲突
  :config
  ;; 默认折叠状态：
  ;; 'overview 仅显示最高级标题（最折叠）
  ;; 'content 显示所有标题（折叠正文）
  ;; 'showeverything 不折叠，显示所有内容
  (setq org-startup-folded 'overview)

  ;; 外观设置
  (setq org-ellipsis "..."  ;; 折叠内容的省略号
        org-pretty-entities t  ;; 允许使用 UTF-8 显示 LaTeX 或特殊字符
        org-highlight-latex-and-related '(latex)  ;; 高亮 LaTeX 代码
        org-export-with-latex 'verbatim  ;; 导出时保留 LaTeX 代码，不解析
        org-export-with-broken-links 'mark  ;; 处理无效链接时做标记
        org-export-with-sub-superscripts nil  ;; 关闭 super/sub script 解析，避免数学公式问题
        org-export-default-language "zh-CN"  ;; 默认导出语言设为中文
        org-export-coding-system 'utf-8  ;; 统一编码为 UTF-8
        org-use-sub-superscripts nil  ;; 下标使用 `{}` 形式，避免歧义
        org-link-file-path-type 'relative  ;; 文件链接使用相对路径
        org-html-validation-link nil  ;; 禁用 HTML 导出时的校验链接
        org-mouse-1-follows-link nil  ;; 关闭鼠标点击自动跟随链接

        ;; 隐藏 Org 语法的标记，使文档更清爽
        org-hide-emphasis-markers t
        org-hide-block-startup t
        org-hidden-keywords '(title)
        org-hide-leading-stars t

        ;; 设置标题层级的显示方式
        org-cycle-separator-lines 2  ;; 标题间隔 2 行
        org-cycle-level-faces t  ;; 使用不同颜色区分标题层级
        org-n-level-faces 4  ;; 限制层级颜色数
        org-indent-indentation-per-level 2  ;; 每层级缩进 2 个空格
        org-adapt-indentation t  ;; 让正文内容对齐标题

        ;; 列表项缩进
        org-list-indent-offset 2

        ;; 代码块缩进
        org-src-preserve-indentation t  ;; 保持原始缩进
        org-edit-src-content-indentation 0  ;; 禁止额外缩进

        ;; 任务状态记录
        org-log-into-drawer t  ;; 状态变更日志存入 LOGBOOK
        org-log-done 'note  ;; 任务完成时记录备注

        ;; 关闭图片自动显示，手动点击更好控制大小
        org-startup-with-inline-images nil
        org-cycle-inline-images-display nil

        ;; 关闭编号标题（避免导出时 TOC 缺失）
        org-startup-numerated nil
        org-startup-indented t  ;; 启用缩进模式

        ;; 默认图片显示大小
        org-image-actual-width '(300)

        ;; 计时器到期时播放声音
        org-clock-sound t

        ;; 关闭误触的 archive 命令
        org-archive-default-command nil

        ;; 关闭自动对齐 tag
        org-tags-column 0
        org-auto-align-tags nil

        ;; 防止意外修改隐藏内容
        org-catch-invisible-edits 'show-and-error
        org-fold-catch-invisible-edits t

        ;; 使用 ID 作为内部链接（而不是 CUSTOM_ID）
        org-id-link-to-org-use-id t

        ;; 关闭 C-c C-c 触发代码执行的功能，避免误执行
        ;; (setq org-babel-no-eval-on-ctrl-c-ctrl-c t)

        ;; 代码执行前确认
        ;; (setq org-confirm-babel-evaluate t)

        ;; 任务管理状态
        org-todo-keywords
        '((sequence "TODO(t!)" "DOING(d@)" "|" "DONE(D)")
          (sequence "WAITING(w@/!)" "NEXT(n!/!)" "SOMEDAY(S)" "|" "CANCELLED(c@/!)")))

  ;; 代码块增强
  (setq org-src-fontify-natively t  ;; 代码高亮
        org-src-tab-acts-natively t)  ;; 在 src block 内使用原生 tab 缩进

  ;; 启用 Babel 代码块执行支持的语言
  (org-babel-do-load-languages
   'org-babel-load-languages
   '((shell . t)
     (js . t)
     (plantuml . t)
     (makefile . t)
     (go . t) 
     (rust . t) 
     (emacs-lisp . t) 
     (python . t)
     (C . t) 
     (java . t)
     (awk . t) 
     (css . t))))

;; engrave-faces 比 minted 渲染速度更快。
(use-package engrave-faces
  :after ox-latex
  :config
  (require 'engrave-faces-latex)
  (setq org-latex-src-block-backend 'engraved)
  ;; 代码块左侧添加行号。
  (add-to-list 'org-latex-engraved-options '("numbers" . "left"))
  ;; 代码块主题。
  (setq org-latex-engraved-theme 'ef-light))

(defun my/export-pdf (backend)
  (progn
    ;;(setq org-export-with-toc nil)
    (setq org-export-headline-levels 2))
  )
(add-hook 'org-export-before-processing-functions #'my/export-pdf)

(use-package ox-gfm :defer t) ;; github flavor markdown

(with-eval-after-load 'ox
  (require 'ox-latex)  ;; 确保 LaTeX 导出模块加载

  ;; LaTeX 图片默认宽度
  (setq org-latex-image-default-width "0.7\\linewidth"   ;;;; latex image 的默认宽度, 可以通过 #+ATTR_LATEX :width xx 配置。 
        org-latex-tables-booktabs t                      ;;;; 使用 booktabs style 来显示表格，例如支持隔行颜色, 这样 #+ATTR_LATEX: 中不需要添加 :booktabs t。
        org-latex-remove-logfiles t
        org-latex-pdf-process                            ;;;; 使用支持中文的 xelatex。
        ;;("latexmk -xelatex -quiet -shell-escape -f %f"
        '("latexmk -xelatex -shell-escape -f %f"
          "rm -fr %b.out %b.tex %b.brf %b.bbl"))
  
  ;; 添加 ctexart 作为 LaTeX 类
  (add-to-list 'org-latex-classes
               '("ctexart"
                 "\\documentclass[lang=cn,11pt,a4paper,table]{ctexart}
                      [NO-DEFAULT-PACKAGES]
                      [PACKAGES]
                      [EXTRA]"
                 ("\\section{%s}" . "\\section*{%s}")
                 ("\\subsection{%s}" . "\\subsection*{%s}")
                 ("\\subsubsection{%s}" . "\\subsubsection*{%s}")
                 ("\\paragraph{%s}" . "\\paragraph*{%s}")
                 ("\\subparagraph{%s}" . "\\subparagraph*{%s}"))))

(defun my-latex-template (author title subtitle latex-header-path)
  "生成定制化的 LaTeX 文档模板
  参数说明：
  - AUTHOR: 作者姓名
  - TITLE: 文档标题
  - SUBTITLE: 文档副标题
  - LATEX-HEADER-PATH: LaTeX 头文件路径（例如：~/mystyle.sty）"
  (interactive 
   "s作者: \ns标题: \ns副标题: \nFLaTeX头文件路径: ")  ; 修复1：增加第四个参数输入
  (let ((date (format-time-string "%Y-%m-%d %a"))
	    (template (concat
		           "#+TITLE: %s\n"
		           "#+DATE: %s\n"          ; 修复2：修正为全大写
		           "#+SUBTITLE: %s\n"
		           "#+AUTHOR: %s\n"
		           "#+LANGUAGE: zh-CN\n"
		           "#+OPTIONS: prop:t title:nil num:2 toc:nil ^:nil\n"
		           "#+LATEX_COMPILER: xelatex\n"
		           "#+LATEX_CLASS: ctexart\n"
		           "#+LATEX_HEADER: \\usepackage{%s}\n\n"  ; 修复3：使用动态路径
		           "#+begin_export latex\n"
		           "\\maketitle\n"
		           "\\thispagestyle{empty}\n"
		           "\\clearpage\n\n"
		           "\\begin{abstract}\n"
		           "在此处填写摘要内容。\n"
		           "\\end{abstract}\n\n"
		           "\\tableofcontents\n"
		           "\\clearpage\n"
		           "#+end_export")))
    ;; 插入格式化后的模板内容
    (insert (format template title date subtitle author latex-header-path)))) ; 修复4：添加第五个参数

(defun my-org-table-attr ()
  "tabularx 的特殊 align 参数 X 用来对指定列内容自动换行，表格前需要加如下属性："
  (interactive)
  (insert "#+ATTR_LATEX: :environment tabularx :booktabs t :width \linewidth :align l|X"))

;; (use-package pdf-tools
;;   :straight t
;;   :ensure t
;;   :if (and (display-graphic-p) (not *sys/win32*) (not eaf-env-p))
;;   :mode ("\\.pdf\\'" . pdf-view-mode)  ;; 关联 PDF 文件
;;   :commands (pdf-loader-install)
;;   :custom
;;   (pdf-view-midnight-colors '("#ffffff" . "#000000")) ;; 夜间模式
;;   (TeX-view-program-selection '((output-pdf "PDF Tools"))) ;; AUCTeX 兼容
;;   (TeX-view-program-list '(("PDF Tools" "TeX-pdf-tools-sync-view")))
;;   :hook
;;   (pdf-view-mode . (lambda () (display-line-numbers-mode -1))) ;; 关闭行号
;;   :config
;;   (pdf-tools-install)  ;; 安装 pdf-tools
;;   (pdf-loader-install))  ;; 加载 pdf-tools

;; 根据可用性选择 PDF 查看器：优先使用 EAF PDF，其次 pdf-tools，再不行则使用默认查看器
(cond
 ((require 'eaf-pdf nil 'noerror)
  (setq TeX-view-program-selection '((output-pdf "EAF PDF")))
  (add-to-list 'TeX-view-program-list '("EAF PDF" "eaf-open \"%o\"")))
 ;; ((require 'pdf-tools nil 'noerror)
 ;;  (setq TeX-view-program-selection '((output-pdf "PDF Tools")))
 ;;  (add-to-list 'TeX-view-program-list '("PDF Tools" "TeX-pdf-tools-sync-view")))
 ;; (t
 ;;  (setq TeX-view-program-selection '((output-pdf "Evince"))))
 )

(use-package treesit-fold :straight (treesit-fol :type git :host github :repo "emacs-tree-sitter/treesit-fold") :config)

;; cargo install tree-sitter-cli
;; M-x 执行 M-x treesit-auto-install-all 来安装所有的 treesit modules。
;; 如果要重新安装(升级) grammer, 需要先删除 dylib 文件或 tree-sitter 目录, 重启 emacs 后再执行 M-x treesit-auto-install-all. 
;; (use-package treesit-auto
;;   :demand t
;;   :config
;;   (setq treesit-auto-install 'prompt)
;;   (global-treesit-auto-mode))


;; M-x `treesit-install-language-grammar` to install language grammar.
(use-package treesit-auto
  :ensure t
  :config
  (setq treesit-language-source-alist
        '((bash . ("https://github.com/tree-sitter/tree-sitter-bash"))
          (c . ("https://github.com/tree-sitter/tree-sitter-c"))
          (cpp . ("https://github.com/tree-sitter/tree-sitter-cpp"))
          (css . ("https://github.com/tree-sitter/tree-sitter-css"))
          (cmake . ("https://github.com/uyha/tree-sitter-cmake"))
          ;;(csharp     . ("https://github.com/tree-sitter/tree-sitter-c-sharp.git"))
          (dockerfile . ("https://github.com/camdencheek/tree-sitter-dockerfile"))
          (elisp . ("https://github.com/Wilfred/tree-sitter-elisp"))
          (erlang . ("https://github.com/WhatsApp/tree-sitter-erlang"))
          (elixir "https://github.com/elixir-lang/tree-sitter-elixir" "main" "src" nil nil)
          (go . ("https://github.com/tree-sitter/tree-sitter-go"))
          (gomod      . ("https://github.com/camdencheek/tree-sitter-go-mod.git"))
          (haskell "https://github.com/tree-sitter/tree-sitter-haskell" "master" "src" nil nil)
          (html . ("https://github.com/tree-sitter/tree-sitter-html"))
          (java       . ("https://github.com/tree-sitter/tree-sitter-java.git"))
          (javascript . ("https://github.com/tree-sitter/tree-sitter-javascript"))
          (json . ("https://github.com/tree-sitter/tree-sitter-json"))
          (lua . ("https://github.com/Azganoth/tree-sitter-lua"))
          (make . ("https://github.com/alemuller/tree-sitter-make"))
          (markdown . ("https://github.com/tree-sitter-grammars/tree-sitter-markdown" "split_parser" "tree-sitter-markdown/src"))
          (markdown-inline . ("https://github.com/tree-sitter-grammars/tree-sitter-markdown" "split_parser" "tree-sitter-markdown-inline/src"))
          ;;(ocaml . ("https://github.com/tree-sitter/tree-sitter-ocaml" nil "ocaml/src"))
          (org . ("https://github.com/milisims/tree-sitter-org"))
          (python . ("https://github.com/tree-sitter/tree-sitter-python"))
          ;;(php . ("https://github.com/tree-sitter/tree-sitter-php"))
          (typescript . ("https://github.com/tree-sitter/tree-sitter-typescript" nil "typescript/src"))
          (tsx . ("https://github.com/tree-sitter/tree-sitter-typescript" nil "tsx/src"))
          (ruby . ("https://github.com/tree-sitter/tree-sitter-ruby"))
          (rust . ("https://github.com/tree-sitter/tree-sitter-rust"))
          (sql . ("https://github.com/m-novikov/tree-sitter-sql"))
          (scala "https://github.com/tree-sitter/tree-sitter-scala" "master" "src" nil nil)
          (toml "https://github.com/tree-sitter/tree-sitter-toml" "master" "src" nil nil)
          (vue . ("https://github.com/merico-dev/tree-sitter-vue"))
          (kotlin . ("https://github.com/fwcd/tree-sitter-kotlin"))
          (yaml . ("https://github.com/ikatyang/tree-sitter-yaml"))
          (zig . ("https://github.com/GrayJack/tree-sitter-zig"))
          (clojure . ("https://github.com/sogaiu/tree-sitter-clojure"))
          ;;(nix . ("https://github.com/nix-community/nix-ts-mode"))
          (mojo . ("https://github.com/HerringtonDarkholme/tree-sitter-mojo"))))

  (setq major-mode-remap-alist
        '((c-mode          . c-ts-mode)
          (c++-mode        . c++-ts-mode)
          (cmake-mode      . cmake-ts-mode)
          (conf-toml-mode  . toml-ts-mode)
          (css-mode        . css-ts-mode)
          (js-mode         . js-ts-mode)
          (js-json-mode    . json-ts-mode)
          (python-mode     . python-ts-mode)
          (sh-mode         . bash-ts-mode)
          (typescript-mode . typescript-ts-mode)
          (rust-mode       . rust-ts-mode)
          (java-mode       . java-ts-mode)
          (clojure-mode    . clojure-ts-mode)
          (markdown-mode   . markdown-ts-mode)
          ))

  (dolist (lang (mapcar #'car treesit-language-source-alist))
    (unless (treesit-language-available-p lang)
      (treesit-install-language-grammar lang)))

  (add-hook 'web-mode-hook #'(lambda ()
                               (let ((file-name (buffer-file-name)))
                                 (when file-name
                                   (treesit-parser-create
                                    (pcase (file-name-extension file-name)
                                      ("vue" 'vue)
                                      ("html" 'html)
                                      ("php" 'php))))
                                 )))

  (add-hook 'markdown-ts-mode-hook #'(lambda () (treesit-parser-create 'markdown)))
  (add-hook 'zig-mode-hook #'(lambda () (treesit-parser-create 'zig)))
  (add-hook 'mojo-mode-hook #'(lambda () (treesit-parser-create 'mojo)))
  (add-hook 'emacs-lisp-mode-hook #'(lambda () (treesit-parser-create 'elisp)))
  (add-hook 'ielm-mode-hook #'(lambda () (treesit-parser-create 'elisp)))
  (add-hook 'json-mode-hook #'(lambda () (treesit-parser-create 'json)))
  (add-hook 'go-mode-hook #'(lambda () (treesit-parser-create 'go)))
  (add-hook 'java-mode-hook #'(lambda () (treesit-parser-create 'java)))
  (add-hook 'java-ts-mode-hook #'(lambda () (treesit-parser-create 'java)))
  (add-hook 'clojure-mode-hook #'(lambda () (treesit-parser-create 'clojure)))
  (add-hook 'clojure-ts-mode-hook #'(lambda () (treesit-parser-create 'clojure)))
  (add-hook 'cider-repl-mode-hook #'(lambda () (treesit-parser-create 'clojure)))
  (add-hook 'php-mode-hook #'(lambda () (treesit-parser-create 'php)))
  (add-hook 'php-ts-mode-hook #'(lambda () (treesit-parser-create 'php)))
  (add-hook 'java-ts-mode-hook #'(lambda () (treesit-parser-create 'java)))
  (add-hook 'haskell-mode-hook #'(lambda () (treesit-parser-create 'haskell)))
  (add-hook 'kotlin-mode-hook #'(lambda () (treesit-parser-create 'kotlin)))
  (add-hook 'ruby-mode-hook #'(lambda () (treesit-parser-create 'ruby)))
  )

;; 自动保存
(use-package auto-save
  :straight (auto-save :type git :host github :repo "manateelazycat/auto-save")
  :hook (after-init . auto-save-enable)  ;; 确保 Emacs 启动后才启用 auto-save
  :custom
  (auto-save-silent t) ;; 静默保存，避免干扰
  (auto-save-disable-predicates ;; 设定不自动保存的条件
   '((lambda () (string-prefix-p "*" (buffer-name)))  ;; 排除 * 开头的 buffer，如 *scratch*
     (lambda () (string-match-p "\\.gpg$" (buffer-file-name))) ;; 排除加密文件
     )))

;; 自动清理行尾空格，仅限于修改过的行
(use-package ws-butler
  :diminish
  :straight t
  :hook (prog-mode . ws-butler-mode)
  :init
  (setq ws-butler-keep-whitespace-before-point t)) 


;; Golang
(use-package go-mode
  :hook ((go-mode . (lambda ()
                      (setq tab-width 4) ;; Go 代码缩进
                      (add-hook 'before-save-hook #'gofmt-before-save nil t))))
  :config
  (defun go-run-buffer ()
    "运行当前 Go 文件"
    (interactive)
    (let ((file (buffer-file-name)))
      (if file
          (progn
            (save-buffer) ;; 先保存 buffer
            (compile (concat "go run " file))) ;; 用 compile 代替 shell-command
        (message "当前 buffer 没有关联的文件，无法运行")))))

;; Rust
(use-package rust-mode
  :defer t
  :hook ((rust-mode . lsp)   ;; 仅在 Rust 文件中启动 LSP
         (rust-mode . my/rust-setup)) ;; 仅在 Rust 文件中应用自定义设置
  :config
  (setq rust-format-on-save t) ;; 保存时自动格式化
  
  (defun my/rust-setup ()
    "Rust 相关的自定义设置"
    (setq-local lsp-completion-enable nil) ;; 关闭 LSP 补全（可选）
    (setq-local compile-command "cargo build")))

;; Erlang
(add-hook 'after-init-hook
          (lambda ()
            (let* ((tools-version erlang-lib-tools-version)
                   (path-prefix erlang-path-prefix)
                   (tools-path (concat path-prefix "/lib/tools-" tools-version "/emacs")))
              (when (file-exists-p tools-path)
                (setq erlang-root-dir (concat path-prefix "/erlang"))
                (setq exec-path (cons (concat path-prefix "/bin") exec-path))))))

;; C++
(use-package cc-mode
  :defer t
  :mode ("\\.c\\'" "\\.h\\'" "\\.cpp\\'" "\\.hpp\\'")
  :bind (:map c-mode-base-map
              ("C-c c" . compile))
  :hook (c-mode-common . (lambda () (c-set-style "stroustrup")))
  :config
  (use-package modern-cpp-font-lock
    :hook (c++-mode . modern-c++-font-lock-mode))) ;; 只在 C++ 模式下启用高亮

;; Python
(use-package python
  :defer t
  :mode ("\\.py\\'")
  :custom
  (flycheck-python-pycompile-executable "python3")
  (python-shell-interpreter "python3"))

;; Jupyter Notebook Support
(use-package ein
  :if (executable-find "jupyter")
  :defer t
  :init
  (message "EIN loaded only when needed")
  :bind
  (("C-c e" . ein:worksheet-execute-cell)
   ("C-c C-e" . ein:worksheet-execute-all-cells))
  :custom-face
  (ein:basecell-input-area-face ((t (:extend t :background "#303640"))))
  :custom
  (ein:worksheet-enable-undo t))

;; Latex 
(use-package auctex
  :defer t
  :custom
  (TeX-auto-save t)                        ;; 自动保存 TeX 缓存数据
  (TeX-parse-self t)                       ;; 自动解析 TeX 头部信息
  (TeX-master nil)                         ;; 默认不指定 master 文件
  (TeX-engine 'xetex)                      ;; 默认使用 XeLaTeX，可根据需要更改为 pdflatex 或 lualatex
  (TeX-source-correlate-method 'synctex)     ;; 启用 synctex 反向搜索
  (TeX-source-correlate-start-server t)      ;; 启动反向搜索服务器
  (TeX-after-compilation-finished-functions #'TeX-revert-document-buffer)  ;; 编译完成后自动刷新 PDF buffer
  :hook
  (LaTeX-mode . my-latex-setup)             ;; 自定义 LaTeX 模式初始化
  (LaTeX-mode . display-line-numbers-mode)  ;; 启用行号（仅在需要时）
  :config
  (defun my-latex-setup ()
    "为 AUCTeX 启动 RefTeX 支持。"
    (reftex-mode 1)
    (setq reftex-plug-into-AUCTeX t))
  )

(defvar my/font-base-size 16
  "基础字体大小 (单位: pt)，英文字体直接使用该值，中文字体按缩放系数调整")

(defvar my/cjk-font-scale 1.2
  "中文字体相对于基准字体的缩放系数，建议范围 1.1~1.3")

(defun available-font (font-list)
  "Get the first available font from FONT-LIST."
  (catch 'font
    (dolist (font font-list)
      (if (member font (font-family-list))
          (throw 'font font)))))

(setq my/ef (available-font '("JetBrains Mono" "Monaco" "Iosevka Comfy" "Cascadia Code")))
(setq my/cf (available-font '("LXGW WenKai Mono" "Sarasa Mono SC" "Microsoft YaHei Mono")))
(setq my/en-size (* my/font-base-size 10))  ; 转换为Emacs的height单位
(setq my/zh-size (* my/font-base-size my/cjk-font-scale 10)) ; 中文字体高度

(message "英文字体: %s (%.1fpt)" my/ef (/ my/en-size 10.0))
(message "中文字体: %s (等效%.1fpt)" my/cf (/ my/zh-size 10.0))

(defun my/org-title-font-setup (zh-font en-font)
  "修复 Org 标题中英文字号差异"
  (let* ((base-size my/font-base-size)
         (title-scale '(2.0 1.8 1.6 1.4 1.2 1.1 1.0 0.9)))  ; 确保有 8 级标题的缩放比例
    ;; 设置标题字体
    (dolist (level (number-sequence 1 8))
      (let* ((face (intern (format "org-level-%d" level)))  ; 正确结束变量绑定
             (scale-factor (nth (1- level) title-scale)))   ; 取出对应标题级别的缩放因子

        ;; 中文字体设置
        (set-face-attribute face nil
                            :family zh-font
                            :height (round (* scale-factor base-size 10))  ; 修正高度计算
                            :weight 'semi-bold)

        ;; 确保西文字体存在后再覆盖
        (when (member en-font (font-family-list))
          (set-fontset-font t 'latin (font-spec :family en-font) nil 'prepend))))))


(defun my/setup-font ()
  "智能字体配置，支持动态大小调整"
  (interactive)
  (when my/ef
    (dolist (face '(default fixed-pitch fixed-pitch-serif variable-pitch))
      (set-face-attribute face nil :family my/ef :height my/en-size)))
  (when my/cf
    ;; 设置字符集字体
    (dolist (charset '(kana han hangul cjk-misc bopomofo))
      (set-fontset-font t charset (font-spec :family my/cf :height my/zh-size)))

    ;; 非等宽字体缩放处理
    (unless (string-match-p "Mono" my/cf)
      (setq face-font-rescale-alist `((,my/cf . ,my/cjk-font-scale))))

    ;; 设置Org标题字体
    (when (and my/cf my/ef)
      (my/org-title-font-setup my/cf my/ef))))

;; 初始化加载字体配置
(add-hook 'after-init-hook 'my/setup-font)
(add-hook 'org-mode-hook (lambda () (my/org-title-font-setup my/cf my/ef)))
(add-hook 'org-mode-hook #'valign-mode)

;; 动态调整字体大小
(defun my/reset-font-size ()
  "动态调整字体大小"
  (interactive)
  (let ((new-size (read-number "New base font size (pt): " my/font-base-size)))
    (setq my/font-base-size new-size)
    (my/setup-font)))

(use-package rime
  :defer t
  :custom
  (default-input-method "rime")
  (rime-posframe-style 'vertical)
  (rime-show-candidate 'posframe)
  (rime-user-data-dir zxh-emacs-rime-user-data-dir)
  (rime-librime-root (expand-file-name "librime/dist" user-emacs-directory))
  ;;:hook
  ;;(emacs-startup . (lambda () (setq default-input-method "rime")))
  :bind
  (
   :map rime-active-mode-map
   ;; 在已经激活 Rime 候选菜单时，强制切换到英文直到按回车。
   ("M-j" . 'rime-inline-ascii)
   :map rime-mode-map
   ;; 强制切换到中文模式.
   ("M-j" . 'rime-force-enable)
   ;; 下面这些快捷键需要发送给 rime 来处理, 需要与 default.custom.yaml 文件中的
   ;; key_binder/bindings配置相匹配。
   ("C-." . 'rime-send-keybinding)      ;; 中英文切换
   ("C-+" . 'rime-send-keybinding)      ;; 输入法菜单
   ("C-," . 'rime-send-keybinding)      ;; 中英文标点切换
   ;;("C-," . 'rime-send-keybinding)    ;; 全半角切换
   )
  :config
  ;; 在 modline 高亮输入法图标, 可用来快速分辨分中英文输入状态。
  (setq mode-line-mule-info '((:eval (rime-lighter))))
  ;; 将如下快捷键发送给 rime，同时需要在 rime 的 key_binder/bindings 的部分配置才会生效。
  (add-to-list 'rime-translate-keybindings "C-h") ;; 删除拼音字符
  (add-to-list 'rime-translate-keybindings "C-d")
  (add-to-list 'rime-translate-keybindings "C-k") ;; 删除误上屏的词语
  (add-to-list 'rime-translate-keybindings "C-a") ;; 跳转到第一个拼音字符
  (add-to-list 'rime-translate-keybindings "C-e") ;; 跳转到最后一个拼音字符support
  ;; shift-l, shift-r, control-l, control-r, 只有当使用系统 RIME 输入法时才有效。
  (setq rime-inline-ascii-trigger 'shift-r)

  (setq rime-disable-predicates
        ;; 行首输入符号
        '(rime-predicate-punctuation-line-begin-p
          ;; 中文字符加空格之后输入符号
          rime-predicate-punctuation-after-space-cc-p
          ;; 中文字符加空格之后输入英文
          rime-predicate-space-after-cc-p
          ;; 英文使用半角符号
          rime-predicate-punctuation-after-ascii-p
          ;; 编程模式，只在注释中输入中文
          rime-predicate-prog-in-code-p))

  (setq rime-posframe-properties
        (list :background-color "#333333"
              :foreground-color "#dcdccc"
              :internal-border-width 2)))

(use-package aidermacs
  :defer 2  ; 基础延迟2秒（Emacs空闲时加载）
  :straight (:host github :repo "MatthewZMD/aidermacs" :files ("*.el"))
  :commands (aidermacs-architect-mode  ; 命令触发加载
             aidermacs-transient-menu
             aidermacs-edit-code
             aidermacs-chat)
  :when (executable-find "aider")
  :config
  (setq aidermacs-auto-commits nil)
  ;; When Architect mode is enabled, the aidermacs-default-model setting is ignored
  (setq aidermacs-use-architect-mode t)
  (setenv "AIDER_CHAT_LANGUAGE" "Chinese")

  ;; Openrouter
  (when (getenv "OPENROUTER_API_KEY")
    ;; (setq aidermacs-default-model "openrouter/anthropic/claude-3.5-sonnet")
    (setq aidermacs-architect-model "openrouter/anthropic/claude-3.5-sonnet")
    (setq aidermacs-editor-model "openrouter/anthropic/claude-3.5-sonnet")
    (setenv "OPENROUTER_API_KEY" (getenv "OPENROUTER_API_KEY")))

  ;; DeepSeek
  (when (getenv "DEEPSEEK_API_KEY")
    (setq aidermacs-architect-model "deepseek/deepseek-reasoner")
    ;; (setq aidermacs-editor-model "deepseek/deepseek-chat")
    (setq aidermacs-editor-model "deepseek/deepseek-coder")
    (setenv "DEEPSEEK_API_KEY" (getenv "DEEPSEEK_API_KEY"))
    (setenv "AIDERMACS_API_KEY" (getenv "DEEPSEEK_API_KEY")))
  )

;;----------------------------------------------------------
;; 使用 lsp-bridge 时， 请先关闭其他补全插件，
;; 比如 lsp-mode, eglot, company, corfu 等等， lsp-bridge 提供从补全后端、 补全前端到多后端融合的全套解决方案。
;; rustup component add rust-src
(use-package yasnippet
  :diminish yas-minor-mode
  :init
  (use-package yasnippet-snippets :after yasnippet :defer t)
  :hook ((prog-mode LaTeX-mode org-mode markdown-mode) . yas-minor-mode)
  :bind
  (:map yas-minor-mode-map ("C-c C-n" . yas-expand-from-trigger-key))
  (:map yas-keymap
        (("TAB" . smarter-yas-expand-next-field)
         ([(tab)] . smarter-yas-expand-next-field)))
  :config
  (yas-reload-all)
  (defun smarter-yas-expand-next-field ()
    "Try to `yas-expand' then `yas-next-field' at current cursor position."
    (interactive)
    (let ((old-point (point))
          (old-tick (buffer-chars-modified-tick)))
      (yas-expand)
      (when (and (eq old-point (point))
                 (eq old-tick (buffer-chars-modified-tick)))
        (ignore-errors (yas-next-field))))))


;; 然后选择你要的语言，比如 c, c++, python, rust，等待安装完成。
;; 你可以手动检查 tree-sitter 语法是否正确安装：
;; M-x treesit-inspect-node-at-point
;; commands 延时加载
(use-package lsp-bridge
  :straight (lsp-bridge
             :type git
             :host github
             :repo "manateelazycat/lsp-bridge"
             :files ("*"))
  :commands (global-lsp-bridge-mode lsp-bridge-mode)
  :custom
  (acm-enable-codeium nil)
  (acm-enable-tabnine nil)
  (acm-enable-yas nil)
  (acm-enable-quick-access t)
  (acm-enable-icon t)                         ;; 显示补全图标
  (lsp-bridge-enable-inlay-hint t)            ;; 启用类型提示
  (lsp-bridge-enable-hover-diagnostic t)      ;; 悬停显示错误
  (lsp-bridge-enable-auto-format-code nil)    ;; 关闭自动格式化
  (lsp-bridge-python-command "python3")       ;; 指定 Python 解释器
  (lsp-bridge-python-lsp-server "pyright")    ;; 默认使用 Pyright
  :bind
  (("C-]" . lsp-bridge-find-def)
   ("C-t" . lsp-bridge-find-def-return)
   ("M-]" . lsp-bridge-find-impl)
   ("M-i" . lsp-bridge-popup-documentation)
   ("C-M-." . lsp-bridge-peek)
   :map lsp-bridge-ref-mode-map
   ("n" . lsp-bridge-ref-jump-next-keyword)
   ("p" . lsp-bridge-ref-jump-prev-keyword)
   ("M-n" . lsp-bridge-ref-jump-next-file)
   ("M-p" . lsp-bridge-ref-jump-prev-file)
   ("C-x C-q" . lsp-bridge-ref-switch-to-edit-mode)
   :map lsp-bridge-ref-mode-edit-map
   ("C-x C-q" . lsp-bridge-ref-apply-changed)
   ("C-x C-s" . lsp-bridge-ref-apply-changed)
   ("C-c C-k" . lsp-bridge-ref-quit)
   ("M-n" . lsp-bridge-ref-jump-next-file)
   ("M-p" . lsp-bridge-ref-jump-prev-file)
   :map acm-mode-map
   ("C-n" . acm-select-next)
   ("C-p" . acm-select-prev)
   ("TAB" . acm-complete)
   ("<tab>" . acm-complete)
   ("RET" . acm-complete))  ;; 回车键用于补全
  :hook
  (prog-mode . global-lsp-bridge-mode))  ;; 仅在编程模式下启用 lsp-bridge

(use-package eaf
  :defer 2
  :straight (emacs-application-framework
             :type git
             :host github
             :repo "emacs-eaf/emacs-application-framework"
             :files ("*"))
  :custom
  (eaf-start-python-process-when-require t)
  (browse-url-browser-function #'eaf-open-browser)
  (eaf-browser-enable-adblocker t)
  (eaf-webengine-continue-where-left-off t)
  (eaf-webengine-default-zoom 1.25)
  (eaf-webengine-scroll-step 200)
  (eaf-pdf-show-progress-on-page nil)
  (eaf-pdf-dark-mode "ignore")
  :commands (eaf-open-browser eaf-open-pdf)
  :config
  (dolist (pkg '(eaf-file-manager
                 eaf-browser
                 eaf-pdf-viewer
                 eaf-image-viewer
                 eaf-pyqterminal
                 eaf-mind-elixir
                 eaf-markmap
                 eaf-git
                 eaf-map
                 eaf-jupyter))
    (require pkg nil t)))
;;(with-eval-after-load 'eaf (require pkg nil t))))

;; 设置 EAF PDF 为默认阅读器
(setq browse-url-browser-function
      '((".*\\.pdf\\'" . eaf-open-pdf)
        (".*" . browse-url-default-browser)))

(add-to-list 'auto-mode-alist '("\\.pdf\\'" . eaf-open-pdf))

(use-package highlight-parentheses
  :diminish
  :hook ((prog-mode . highlight-parentheses-mode)
		 (org-mode . highlight-parentheses-mode)) ;; 在代码和 Org 模式启用
  :custom (hl-paren-colors '("DarkOrange" "DeepSkyBlue" "DarkRed")))

(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

;; 显示匹配括号
(use-package paren
  :hook (prog-mode . show-paren-mode)
  :custom
  (show-paren-delay 0.1)
  (show-paren-when-point-inside-paren t)
  (show-paren-when-point-in-periphery t)
  (show-paren-style 'parenthesis) ;; 可选 'expression
  :config
  (set-face-attribute 'show-paren-match nil :weight 'extra-bold))

;; 自动补全括号
(use-package elec-pair
  :hook (prog-mode . electric-pair-mode)
  :custom
  (electric-pair-preserve-balance t)
  (electric-pair-delete-adjacent-pairs t)
  (electric-pair-skip-self 'electric-pair-default-skip-self)
  (electric-pair-open-newline-between-pairs t)
  :config
  (setq electric-pair-pairs
        '((?\" . ?\")
          (?\{ . ?\}))))

;;; commands 延时加载
(use-package all-the-icons
  :when (display-graphic-p)
  :commands all-the-icons-install-fonts)

(use-package dashboard
  :config
  ;; Icon in graphic mode
  (when (display-graphic-p)
    (setq
     dashboard-set-heading-icons t
     dashboard-set-file-icons t))

  (setq
   ;;dashboard-center-content t
   dashboard-banner-logo-title " 浩哥专属 Emacs:-) "
   dashboard-startup-banner (expand-file-name "icon.png" user-emacs-directory)
   dashboard-items '((recents . 5)
                     (bookmarks . 5)
                     (agenda . 5)
                     (projects . 5)))
  (dashboard-setup-startup-hook))

(use-package sort-tab
  :if (display-graphic-p)  ;; 仅在 GUI 模式下启用
  :straight (sort-tab :type git :host github :repo "manateelazycat/sort-tab")
  :commands (sort-tab-mode sort-tab-next sort-tab-previous) ;; 延迟加载
  :init
  ;; 延迟启用，避免阻塞启动
  (run-with-idle-timer 1 nil #'sort-tab-mode)
  :config
  ;; 其他自定义配置
  (setq sort-tab-name-max-length 20      ; 标签最大长度
        sort-tab-hide-tab-function nil   ; 不隐藏标签
        sort-tab-cycle-navigation t))    ; 启用循环导航

(use-package holo-layer
  :if (and (display-graphic-p) (eq system-type 'darwin)) ;; Mac GUI 下启用
  :straight (holo-layer :type git :host github :repo "manateelazycat/holo-layer")
  :init
  ;; 自动检测 Python 解释器路径
  (setq holo-layer-python-command
        (or (executable-find "python3")
            (executable-find "python")
            (expand-file-name "~/.venv/venv/bin/python")))
  ;; 优化动画延迟
  (setq holo-layer-animation-delay 0.05)
  :custom
  ;; 动态启用动画特效
  (holo-layer-enable-cursor-animation (and (>= (display-pixel-width) 2560)
                                           (> (length (frame-list)) 1)))
  ;;(holo-layer-enable-place-info t)  ; 可选启用
  (holo-layer-enable-indent-rainbow t)
  (holo-layer-enable-window-border t)
  (holo-layer-enable-type-animation (>= (display-pixel-width) 2560))
  (holo-layer-type-animation-style "flame")

  :config
  ;; 延迟加载，优化启动性能
  (with-eval-after-load 'holo-layer
    (run-with-idle-timer 1 nil #'holo-layer-enable)))

;; (use-package lazycat-theme
;;   :straight (lazycat-theme :type git :host github :repo "manateelazycat/lazycat-theme")
;;   ;;(lazycat-theme-load-dark)
;;   )
;; (use-package awesome-tray
;;   :straight (awesome-tray :type git :host github :repo "manateelazycat/awesome-tray")
;;   :hook (after-init . awesome-tray-mode)
;;   :custom
;;   (awesome-tray-active-modules '("location" "pdf-view-page" "belong" "file-path"
;;                                  "mode-name" "last-command" "battery" "date"))
;;   (awesome-tray-info-padding-right 1)
;;   :config
;;   (awesome-tray-mode 1))

(use-package ef-themes
  :commands (load-theme)
  :init
  (setq ef-themes-variable-pitch-ui t)
  (setq ef-themes-mixed-fonts t)
  (setq ef-themes-headings
        '((0 . (variable-pitch light 1.9))
          (1 . (variable-pitch light 1.8))
          (2 . (variable-pitch regular 1.7))
          (3 . (variable-pitch regular 1.6))
          (4 . (variable-pitch regular 1.5))
          (5 . (variable-pitch 1.4))
          (6 . (variable-pitch 1.3))
          (7 . (variable-pitch 1.2))
          (8 . (variable-pitch 1.1))
          (t . (variable-pitch 1.1))))
  (setq ef-themes-region '(intense no-extend neutral))
  :config
  ;; 确保不会有其他主题干扰
  (mapc #'disable-theme custom-enabled-themes))

(defun my/get-linux-appearance ()
  "获取 Linux 桌面环境的主题模式（light/dark）。"
  (when (eq system-type 'gnu/linux)
    (let ((theme (shell-command-to-string "gsettings get org.gnome.desktop.interface color-scheme")))
      (cond
       ((string-match "dark" theme) 'dark)
       ((string-match "light" theme) 'light)
       (t 'dark))))) ;; 默认使用 dark 主题

(defun my/load-theme (appearance)
  "根据 APPEARANCE (light/dark) 选择合适的主题。"
  (interactive)
  (pcase appearance
    ('light (load-theme 'ef-light t))
    ('dark (load-theme 'ef-elea-dark t))))

(cond
 ;; macOS 支持
 ((boundp 'ns-system-appearance)

  ;; Emacs 启动后加载正确的主题
  (add-hook 'after-init-hook (lambda () (my/load-theme ns-system-appearance)))

  ;; 监听 macOS 主题变化，自动切换
  (add-hook 'ns-system-appearance-change-functions #'my/load-theme))

 ;; Linux 支持
 (*sys/linux*
  (add-hook 'after-init-hook
            (lambda ()
              (my/load-theme (my/get-linux-appearance))))))

;; 在 Finder 中打开当前文件。
(use-package reveal-in-osx-finder
  :when *sys/mac*
  :commands (reveal-in-osx-finder))

;; macos
(when *sys/mac*

  ;; s- 表示 Super，S- 表示 Shift, H- 表示 Hyper:
  ;; command 作为 Meta 键。
  (setq mac-command-modifier 'meta)

  ;; option 作为 Super 键。
  (setq mac-option-modifier 'super)

  ;; fn 作为 Hyper 键。
  (setq ns-function-modifier 'hyper)

  ;; Copy/Paste
  (defun copy-from-osx ()
    (shell-command-to-string "pbpaste"))

  (defun paste-to-osx (text &optional push)
    (let ((process-connection-type nil))
      (let ((proc (start-process "pbcopy" "*Messages*" "pbcopy")))
        (process-send-string proc text)
        (process-send-eof proc))))

  (setq interprogram-cut-function 'paste-to-osx)
  (setq interprogram-paste-function 'copy-from-osx)

  ;; Move to Trash
  (setq delete-by-moving-to-trash t)
  (setq trash-directory "~/.Trash/emacs")
  (defun system-move-file-to-trash (file)
    "Use \"trash\" to move FILE to the system trash.
              When using Homebrew, install it using \"brew install trash\"."
    (call-process (executable-find "trash")
                  nil 0 nil
                  file))

  ;; Done
  (message "Wellcome To Mac OS X, Have A Nice Day!!!"))


;; linux
(when *sys/linux*
  (defun yank-to-x-clipboard ()
    (interactive)
    (if (region-active-p)
        (progn
          (shell-command-on-region (region-beginning) (region-end) "xsel -i -b")
          (message "Yanked region to clipboard!")
          (deactivate-mark))
      (message "No region active; can't yank to clipboard!"))))

;; Global KeyBindings:  C-h b/k 找到快捷键bind -> ReMap it
;; x-mode KeyBindings   C-h b/k 找到快捷键: M: comand, S: option, C: Control

;; 卸载全局快捷键
(let ((keys '(
              "C-x C-f"
              "C-q"
              "C-6"
              "C-z"
              "C-<wheel-down>"
              "C-<wheel-up>"
              "C-M-<wheel-down>"
              "C-M-<wheel-up>"
              "s-T"
              "s-W"
              "s-z"
              "M-h"
              "M-."
              "M-,"
              "M-]"
              "s-c"
              "s-x"
              "s-v"
              "s-k"
              "s-w"
              "s-,"
              "s-."
              "s--"
              "s-+"
              "<mouse-2>"
              )))
  (dolist (key keys)
    (global-unset-key (kbd key))))

;; 定义窗口管理快捷键
(defun set-control-w-shortcuts ()
  "设置以 C-w 为前缀的窗口管理快捷键。"
  (define-prefix-command 'my-window-map)
  (global-set-key (kbd "C-w") 'my-window-map)
  ;; 窗口大小调整
  (define-key my-window-map (kbd "=")  'window-width-increase)  ; 增加窗口宽度
  (define-key my-window-map (kbd "-")  'window-width-decrease)  ; 减少窗口宽度
  (define-key my-window-map (kbd "9")  'window-height-increase)  ; 增加窗口高度
  (define-key my-window-map (kbd "0")  'window-height-decrease)  ; 减少窗口高度
  ;; 窗口导航
  (define-key my-window-map (kbd "h")  'windmove-left)          ; 左移窗口
  (define-key my-window-map (kbd "j")  'windmove-down)          ; 下移窗口
  (define-key my-window-map (kbd "k")  'windmove-up)            ; 上移窗口
  (define-key my-window-map (kbd "l")  'windmove-right)         ; 右移窗口
  ;; 窗口分割与关闭
  (define-key my-window-map (kbd "v")  'split-window-right)     ; 垂直分割
  (define-key my-window-map (kbd "b")  'split-window-below)     ; 水平分割
  (define-key my-window-map (kbd "d")  'delete-window)          ; 关闭当前窗口
  (define-key my-window-map (kbd "D")  'delete-other-windows)   ; 关闭其他窗口
  (define-key my-window-map (kbd "B")  'kill-buffer-and-window) ; 关闭窗口并杀死缓冲区
  (define-key my-window-map (kbd "o")  'delete-other-windows))  ; 切换到单一窗口

;; 应用窗口管理快捷键
(set-control-w-shortcuts)

;; 在 dired 模式中绑定快捷键
(define-key dired-mode-map (kbd "e") 'wdired-change-to-wdired-mode)

;; 在 evil 模式下卸载和绑定快捷键
(with-eval-after-load 'evil
  ;; 卸载 evil 模式的快捷键
  (dolist (map '(evil-motion-state-map
                 evil-insert-state-map
                 evil-emacs-state-map
                 evil-window-map))
    (define-key (eval map) "\C-]" nil)
    (define-key (eval map) "\C-t" nil)
    (define-key (eval map) "\C-w" nil)
    (define-key (eval map) "\M-]" nil))
  ;; 重新绑定窗口管理快捷键
  (set-control-w-shortcuts)

  ;; 定义智能 q 键行为
  (defun smart-q ()
    "在只读缓冲区中关闭窗口，否则录制宏。"
    (interactive)
    (if buffer-read-only
        (if (= 1 (count-windows))
            (bury-buffer)
          (delete-window))
      (call-interactively 'evil-record-macro)))

  ;; 绑定 smart-q 到 q 键
  (define-key evil-normal-state-map (kbd "q") 'smart-q)
  ;; 卸载其他快捷键
  (define-key evil-motion-state-map (kbd "SPC") nil)
  (define-key evil-motion-state-map (kbd "RET") nil)
  (define-key evil-motion-state-map (kbd "TAB") nil)
  (define-key evil-normal-state-map (kbd "C-t") nil)
  (define-key evil-normal-state-map (kbd "C-]") nil)
  ;; 绑定 swiper 到 / 键
  (define-key evil-normal-state-map (kbd "/")  'swiper)
  (define-key evil-motion-state-map (kbd "C-6") nil))

;; 在 org 模式下卸载快捷键
(with-eval-after-load 'org
  (define-key org-mode-map (kbd "M-h") nil)
  (define-key org-mode-map (kbd "C-,") nil))

;; 全局快捷键绑定
(global-set-key (kbd "C-x k")   'sort-tab-close-current-tab)  ; 关闭当前缓冲区
(global-set-key (kbd "<f5>")    'emacs-session-save)          ; 保存 Emacs 会话
(global-set-key (kbd "C-,")     'goto-last-change)            ; 跳转到最后修改的位置
(global-set-key (kbd "C-4")     'insert-changelog-date)       ; 插入变更日志日期
(global-set-key (kbd "C-5")     'insert-standard-date)        ; 插入标准日期
(global-set-key (kbd "<f6>") #'org-download-screenshot)


;; Projectile 快捷键
(global-set-key (kbd "C-c p f") 'projectile-find-file)        ; 查找文件
(global-set-key (kbd "C-c p b") 'projectile-switch-to-buffer) ; 切换缓冲区
(global-set-key (kbd "C-c p p") 'projectile-switch-project)   ; 切换项目

;; Google 翻译
(global-set-key (kbd "C-c d t") #'google-translate-smooth-translate)

;; Sort-tab 快捷键
(global-set-key (kbd "M-j")     'sort-tab-select-prev-tab)    ; 选择上一个标签页
(global-set-key (kbd "M-k")     'sort-tab-select-next-tab)    ; 选择下一个标签页
(global-set-key (kbd "M-7")     'sort-tab-select-first-tab)   ; 选择第一个标签页
(global-set-key (kbd "M-8")     'sort-tab-select-last-tab)    ; 选择最后一个标签页
(global-set-key (kbd "M-m")     'sort-tab-close-current-tab)  ; 关闭当前标签页
(global-set-key (kbd "s-q")     'sort-tab-close-mode-tabs)    ; 关闭当前模式的标签页
(global-set-key (kbd "s-Q")     'sort-tab-close-all-tabs)     ; 关闭所有标签页

;; Ido 快捷键
(global-set-key (kbd "C-x C-f") 'ido-find-file)               ; 查找文件
(global-set-key (kbd "C-x b")   'ido-switch-buffer)           ; 切换缓冲区
(global-set-key (kbd "C-x i")   'ido-insert-buffer)           ; 插入缓冲区
(global-set-key (kbd "C-x I")   'ido-insert-file)             ; 插入文件

;; 滚动快捷键
(global-set-key (kbd "M-n")     'hold-line-scroll-down)       ; 向下滚动
(global-set-key (kbd "M-p")     'hold-line-scroll-up)         ; 向上滚动

;; 窗口导航快捷键
(global-set-key (kbd "M-]")     'watch-other-window-up)       ; 向上查看其他窗口
(global-set-key (kbd "M-[")     'watch-other-window-down)     ; 向下查看其他窗口
(global-set-key (kbd "M->")     'watch-other-window-up-line)  ; 向上查看其他窗口（行）
(global-set-key (kbd "M-<")     'watch-other-window-down-line); 向下查看其他窗口（行）

;; 搜索和 Git 快捷键
(global-set-key (kbd "C-M-s")   'color-rg-search-input)       ; 彩色搜索
(global-set-key (kbd "C-M-;")   'magit-status)                ; 打开 Magit 状态
(global-set-key (kbd "C-x G")   'git-messenger:popup-message) ; 显示 Git 提交信息

;; LSP Bridge 快捷键
(global-set-key (kbd "C-]")     'lsp-bridge-find-def)         ; 查找定义
(global-set-key (kbd "C-t")     'lsp-bridge-find-def-return)  ; 返回到定义
(global-set-key (kbd "M-]")     'lsp-bridge-find-impl)        ; 查找实现
(global-set-key (kbd "M-.")     'lsp-bridge-find-references)  ; 查找引用
(global-set-key (kbd "M-,")     'lsp-bridge-code-action)      ; 代码操作
(global-set-key (kbd "C-9")     'lsp-bridge-popup-documentation) ; 弹出文档
(global-set-key (kbd "C-0")     'lsp-bridge-rename)           ; 重命名

;; LSP Bridge 诊断快捷键
(global-set-key (kbd "M-s-j")   'lsp-bridge-diagnostic-jump-next) ; 跳转到下一个错误
(global-set-key (kbd "M-s-k")   'lsp-bridge-diagnostic-jump-prev) ; 跳转到上一个错误
(global-set-key (kbd "M-s-l")   'lsp-bridge-diagnostic-ignore)    ; 忽略当前错误
(global-set-key (kbd "M-s-n")   'lsp-bridge-popup-documentation-scroll-up)  ; 向下滚动文档
(global-set-key (kbd "M-s-p")   'lsp-bridge-popup-documentation-scroll-down); 向上滚动文档


;; (global-set-key (kbd "C-c g")   'one-key-menu-git)            ; Git 菜单
;; (global-set-key (kbd "C-c d")   'one-key-menu-directory)      ; 目录菜单
