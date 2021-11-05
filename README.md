# Quick Start
### syn submodules and dotfiles

```bash
git clone https://github.com/robertzhouxh/dotfiles /path/to/dotfiles
# 同步 .files 到 home 目录, 安装常用库，工具,软件(自动适配 linux，macos)
set -- -f; source bootsrap.sh
```
## Install emacs

```bash

cd dotfiles

# -------------------------------------------------------------------------------
# 更新到最新 commit 可以使用  # git submodule update --init --remote
# 修改 .gitmodules 后 可以执行 # git submodule sync 
# 更新到 .gitmodules 中的 commit
# -------------------------------------------------------------------------------
git submodule update --init


# -------------------------------------------------------------------------------
# git clone --depth 1 git://git.savannah.gnu.org/emacs.git
# 这里选择选择国内的同步镜像
# -------------------------------------------------------------------------------

git clone --depth 1 https://mirrors.ustc.edu.cn/emacs.git
brew install autoconf automake texinfo gnutls pkg-config libxml2 --debug --verbose
cd ./emacs && ./autogen.sh

export LDFLAGS="-L/usr/local/opt/libxml2/lib"
export CPPFLAGS="-I/usr/local/opt/libxml2/include"
export PKG_CONFIG_PATH="/usr/local/opt/libxml2/lib/pkgconfig"

./configure && make && make install
open -R nextstep/Emacs.app
and dragging Emacs to the Applications folder.

cp  nextstep/Emacs.app/Contents/MacOS/bin/emacsclient /usr/local/bin/
cp  nextstep/Emacs.app/Contents/MacOS/emacs /usr/local/bin/
```


### Automatically depoly vim/emacs

    ```bash

    # 可以添加自己的插件到: .vimrc
    ./vim.sh

    # 可以添加自己的配置到: .emacs.d/config.org
    rm -rf ~/.emacs
	./emacs.sh
    ```

Start emacs gui and wait for emacs pull all the plugins

Note: if you encouter "Failed to verify signature xxx"
1. set package-check-signature to nil, e.g. M-: (setq package-check-signature nil) RET
2. download the package gnu-elpa-keyring-update and run the function with the same name, e.g. M-x package-install RET gnu-elpa-keyring-update RET.
3. reset package-check-signature to the default value allow-unsigned，e.g. M-: (setq package-check-signature t) RET

### 维护 emacs 配置 (~/.emacs.d/config.org)
1. open .emacs.d/config.org with emacs in org-mode (,fe ---> M-X ---> org-mode)
2. modify chapter: Evil-Mode, Kep-Map, ...
3. reload: ,fr
4. 准备golang 的依赖
    ```
    go get -v golang.org/x/tools/gopls@latest

    go get -v -u golang.org/x/tools/cmd/goimports
    go get -v -u github.com/go-delve/delve/cmd/dlv
    go get -v -u github.com/josharian/impl
    go get -v -u github.com/cweill/gotests/...
    go get -v -u github.com/fatih/gomodifytags
    go get -v -u github.com/davidrjenni/reftools/cmd/fillstruct
    ```
5. 修改 plantuml 路径: 

   ```
   (setq plantuml-jar-path "/usr/local/Cellar/plantuml/1.2020.26/libexec/plantuml.jar")~
   (setq org-plantuml-jar-path "/usr/local/Cellar/plantuml/1.2020.26/libexec/plantuml.jar")
   ```

6. 修改 erlang version: 路径: 

   ```
   ls /usr/local/lib/erlang/lib/tools-{version}/
   emacs-version = ${version}
   (add-to-list 'nox-server-programs '(erlang-mode . ("/Users/zxh/githubs/erlang_ls/_build/default/bin/erlang_ls"))))

    ```
7. 修改 代理设置
    ```
    (setq centaur-proxy "127.0.0.1:8123")          ; http_proxy
    (setq centaur-proxy "127.0.0.1:1080")          ; Network proxy
    (setq centaur-server nil)                      ; Enable `server-mode' or not: t or nil

	```

8. 根据需要调整 evil 键映射
    ```
    (defun x/config-evil-leader ()
      "Configure evil leader mode."
      (evil-leader/set-leader ",")
      (evil-leader/set-key
	    ","  'avy-goto-char-2
	    ":"  'eval-expression

	    "/"  'counsel-rg

	    "A"  'align-regexp

	    "bb" 'ivy-switch-buffer
	    "br" 'counsel-recentf
    ```
### 代码跳转

1. nox 方案， M-X ---> nox ---> C-], C-T
2. dumb-jump 方案， M-], M-T

	针对 nox 的 python 代码补全跳转
```
  ;; Nox
  ;; 1. M-x -> eshell 进入 eshell
  ;; 2. ~ $ (nox-print-mspyls-download-url)
  ;;    https://pvsc.blob.core.windows.net/python-language-server-stable/Python-Language-Server-osx-x64.0.5.59.nupkg
  ;; 3. 下载并解压文件到 ~/.emacs.d/nox/mspyls 目录下，保证目录的根位置有 Microsoft.Python.LanguageServer 这个文件
        mkdir -p ~/.emacs.d/nox/mspyls
        unzip Python-Language-Server-osx-x64.0.5.59.nupkg -d ~/.emacs.d/nox/mspyls/
  ;; 4. 给mspyls索引权限: sudo chmod +x -R ~/.emacs.d/nox/mspyls
  ;; 5. 直接打开 python 文件，即可快速进行语法补全

```
## 文件说明

- .aliases: short name for frequence cmd
- .exports: all the envirenment varibles
- .macos:   a config script for macos refer: https://github.com/mathiasbynens/dotfiles/blob/main/.macos
- .exports: 所有环境变量
- .aliases: cmd别名
- .config: ssh 配置文件
- jumper.expect 一个跳板机相关脚本
- apt.sh: ubuntu scripts
- brew.sh: macos scripts

## Mac 中文设置
	
```bash

1. brew install squirrel
   使用开源方案 https://github.com/wongdean/rime-settings
   settings ---> 项目中除了 font 以外的全部文件拖进来
   shift 切换中英文,

2. cd ~/.emacs.d/
  
  curl -L -O https://github.com/rime/librime/releases/download/1.7.1/rime-1.7.1-osx.zip
  unzip rime-1.7.1-osx.zip -d ~/.emacs.d/librime
  rm -rf rime-1.7.1-osx.zip
  
  # 如果MacOS Gatekeeper阻止第三方软件运行，可以暂时关闭它：
  # 
  # sudo spctl --master-disable
  # # later: sudo spctl --master-enable

  ;使用 toggle-input-method 来激活，默认快捷键为 C-\


```
## Proxy(代理设置)

    ```
	1. 命令行代理 vi ~/.polipo 配置 http -〉socks5 (用於不支持sock5代理的應用)
	2. github 代理 vi ~/.gitconfig 适配sock5监听端口
	3. .aliases 文件中的 hproxy 使用步驟1配置的http代理端口使用http代理
	
	youtube-dl --proxy socks5://127.0.0.1:1080 video_url -o /download_dir/%(title)s-%(id)s.%(ext)s
    ```


## Elisp 

参考: https://github.com/susam/emacs4cl#use-slime
```
brew install sbcl
```
## To be continued...
