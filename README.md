## 同时支持 MacOSX 和 ubuntu 系统的 dotfiles ( vim, emacs, shadowsocks, polipo, utils, applications... )

* 自动化安装系统基础工具以及应用程序
* 命令行 shadowsocks 部署以及 polipo 命令行代理
* 精简版的版的 vim 配置
* 最适合编写 Golang，Erlang， Clojure 的 emacs 配置

## 快速安装

   ```bash
   git clone https://github.com/robertzhouxh/dotfiles /path/to/dotfiles
   cd dotfiles
   set -- -f; source bootsrap.sh

   ./vim.sh

   #  ( 建议使用 GUI 的 emacs )
   ./emacs.sh
   ```
## vim 配置参考 .vimrc 文件
## emacs 配置文件参考 .emacs.d 目录

### 自定义emacs配置

    ```
        init.el                          配置入口文件
        vendor                           自定义的加载目录
        lisp                             主要配置文件目录
            init-bootstrap.el            启动配置选项
            init-evil.el                 evil 相关配置
            init-languages.el            语言相关的配置
            init-maps.el                 keybindings
            init-org.el                  org 相关配置
            init-pkgs.el                 基础插件配置
            init-plantform.el            跨平台相关配置
            init-utils.el                工具小函数

    ```
### evil 模式配置文件的keybinds( a-b-c...z)

    (evil-leader/set-key
      "#"  'server-edit
      ","  'other-window
      "."  'mode-line-other-buffer
      ":"  'eval-expression

      "a"  'align-regexp
      "c"  'comment-dwim
      "d"  'kill-this-buffer

      "es" 'ivy-erlang-complete-find-spec
      "ef" 'ivy-erlang-complete-find-file
      "eh" 'ivy-erlang-complete-show-doc-at-point
      "ep" 'ivy-erlang-complete-set-project-root
      "ea" 'ivy-erlang-complete-autosetup-project-root
      "ek" 'get-erl-man

      "Es" 'x/eshell-here
      "Ex" 'x/eshell-x

      "f"  'other-frame

      "g"  'magit-status
      "G"  'magit-dispatch-popup

      "hb" 'ido-switch-buffer
      "hf" 'helm-find-files
      "hs" 'helm-projectile-ag
      "hp" 'helm-projectile
      "hd" 'helm-dash-at-point
      "hm" 'helm-mini
      "hk" 'helm-show-kill-ring

      "oi" 'org-clock-in
      "oo" 'org-clock-out
      "oo" 'org-clock-out
      "os" 'org-schedule
      "od" 'org-deadline
      "or" 'org-clock-report

      "O"  'delete-other-windows
      "P"  'projectile-find-file-other-window
      ;"rs" 'cider-start-http-server
      ;"rs" 'cider-jack-in
      ;"rr" 'cider-refresh
      ;"re" 'cider-macroexpand-1
      ;"ru" 'cider-user-ns
      ;"rn" 'cider-repl-set-ns
      ;"rx" 'cider-eval-last-sexp
      "r"  'x/open-init-file
      "R" 'x/reload-init-file
      "s" 'x/save-all
      "S" 'delete-trailing-whitespace
      "t" 'gtags-reindex
      "x" 'helm-M-x
      "w" 'whitespace-mode          ;; Show invisible characters
      ))

###  global mapping ( init-maps.el)

* 插件 key-chord ++ hydra 灵活的定制组合
* 全局绑定

    ;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    ;; 全局 mapping
    ;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    (global-set-key (kbd "C-]") 'gtags-find-tag-from-here)
    (global-set-key (kbd "C-t") 'gtags-pop-stack)
    (global-set-key (kbd "M-]") 'dumb-jump-go)
    (global-set-key (kbd "M-t") 'dumb-jump-back)
    (global-set-key (kbd "M-p") 'hold-line-scroll-up )
    (global-set-key (kbd "M-n") 'hold-line-scroll-down )
    (global-set-key (kbd "M-@") 'pkg-mark-word)
    (global-set-key (kbd "M-y") 'async-shell-command)
    (global-set-key (kbd "C-x |") 'vsplit-last-buffer)
    (global-set-key (kbd "C-x -") 'hsplit-last-buffer)
    (global-set-key [M-left]  'shrink-window-horizontally)
    (global-set-key [M-right] 'enlarge-window-horizontally)
    (global-set-key [M-up]    'shrink-window)
    (global-set-key [M-down]  'enlarge-window)

* 局部绑定

    ;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    ;; 覆盖全局 mapping
    ;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    (eval-after-load "evil-maps"
                     (dolist (map '(evil-normal-state-map
                                    evil-motion-state-map
                                    evil-insert-state-map
                                    evil-emacs-state-map))
                       (define-key (eval map) "\M-." nil)
                       (define-key (eval map) "\M-," nil)
                       (define-key (eval map) "\C-t" nil)
                       (define-key (eval map) "\C-]" nil)))

    (eval-after-load "erlang"
      '(progn
         (define-key erlang-mode-map (kbd "C-c b") 'erlang-insert-binary)
         (define-key erlang-mode-map (kbd "M-.") 'ivy-erlang-complete-find-definition)
         (define-key erlang-mode-map (kbd "M-,") 'xref-pop-marker-stack)
         (define-key erlang-mode-map (kbd "M-?") 'ivy-erlang-complete-find-references)
         ))

    (with-eval-after-load 'go-mode
      (defun prelude-go-mode-defaults ()
        ;; Add to default go-mode key bindings
        (let ((map go-mode-map))
          (define-key map (kbd "M-.") 'godef-jump)
          (define-key map (kbd "M-,") 'pop-tag-mark)
          (define-key map (kbd "C-h f") 'godoc-at-point))

### emacs 关于跳转

* 常规的gtags: ,t  然后可以用 C-] && C-t 模糊跳转
* 对于任何编程语言: 可以使用 dumb-jump插件, 直接可以用 M-] && M-t 模糊跳转
* 针对golang, erlang 语言: M-,&& M-t 精准跳转

