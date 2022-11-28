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


### For MacOS

- brew tap railwaycat/emacsmacport
- brew install --cask emacs-mac

或者 

- brew tap daviderestivo/emacs-head
- brew install emacs-head@29 --with-cocoa --with-native-comp --with-native-full-aot --with-imagemagick --with-xwidgets


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

## Files

- .aliases: short name for frequence cmd
- .exports: all the envirenment varibles
- .macos:   a config script for macos refer: https://github.com/mathiasbynens/dotfiles/blob/main/.macos
- .exports: 所有环境变量
- .aliases: cmd别名
- .config: ssh 配置文件
- jumper.expect 一个跳板机相关脚本
- apt.sh: ubuntu scripts
- brew.sh: macos scripts

## Mac squirrel 中文
	
```bash

1. brew install --cask squirrel

   cp -rf ./squirrel/* ~/Library/Rime/

   # redeploy siquirrel

2. cd ~/.emacs.d/
  
  curl -L -O https://github.com/rime/librime/releases/download/1.7.3/rime-1.7.3-osx.zip
  unzip rime-1.7.3-osx.zip -d ~/.emacs.d/librime
  rm -rf rime-1.7.3-osx.zip
  
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


## Emacs 启动与配置

启动 emacs 等待插件自动安装完毕!!!

1. 编程语言跳转 lsp-server
  pip3 install epc orjson six

  选择对应语言的安装包 -- https://github.com/manateelazycat/lsp-bridge#supported-language-servers
```
  - Rust: brew install rust-analyzer && rustup component add rust-src rustfmt clippy rls rust-analysis
  - Golang: go install golang.org/x/tools/gopls@latest
  - Erlang: git clone https://github.com/erlang-ls/erlang_ls && cd erlang_ls && make && PREFIX=/usr/local/bin make install
  - Yaml: npm install -g yaml-language-server


2. 适配章节 .emacs.d/config.org 中 ( Custom Var) 中的变量

```

  (setq erlang-path-prefix "/usr/local/lib/erlang")
  (setq erlang-lib-tools-version "3.5.2")
  (setq erlang-ls "/Users/glodon/githubs/erlang_ls/_build/default/bin/erlang_ls")
  (setq plantuml-path "/usr/local/Cellar/plantuml/1.2022.1/libexec/plantuml.jar")
  (setq centaur-proxy "127.0.0.1:8123")          ; HTTP/HTTPS proxy
  (setq centaur-socks-proxy "127.0.0.1:1080")    ; SOCKS proxy
  (setq centaur-server t)                        ; Enable `server-mode' or not: t or nil

```

重新启动 emacs

## Elisp 

参考: https://github.com/susam/emacs4cl#use-slime
```
brew install sbcl

## Debug

```
  ;; Environment
  (use-package exec-path-from-shell
    :ensure t
    :if (or sys/mac-x-p sys/linux-x-p)
    :config
    (setq exec-path-from-shell-variables '("PATH" "GOPATH"))
    (setq exec-path-from-shell-arguments '("-l"))
    (exec-path-from-shell-initialize))

光标直接放到最后一个list  [ (exec-path-from-shell-initialize) ]括号上执行 c-x c-e

如 (featurep 'cocoa)  c-x c-e 在minibuffer中输出 t

```
## To be continued...
