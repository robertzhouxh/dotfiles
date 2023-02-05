# Quick Start
### syn submodules and dotfiles

查找域名对应的ip

https://www.ipaddress.com/site/raw.githubusercontent.com
https://www.ipaddress.com/site/github.com

sudo vi /etc/hosts 
x.x.x.x raw.githubusercontent.com
x.x.x.x github.com

建议手动安装 brew, asdf, polipo, sock5 proxy

```bash
git clone https://github.com/robertzhouxh/dotfiles /path/to/dotfiles
# 同步 .files 到 home 目录, 安装常用库，工具,软件(自动适配 linux，macos)
set -- -f; source bootsrap.sh
```
## Install emacs

```
cd dotfiles
# -------------------------------------------------------------------------------
# 更新到最新 commit 可以使用  # git submodule update --init --remote
# 修改 .gitmodules 后 可以执行 # git submodule sync 
# 更新到 .gitmodules 中的 commit
# -------------------------------------------------------------------------------
git submodule update --init
```


### For General

```
# 这里选择选择国内的同步镜像
# git clone --depth 1 git://git.savannah.gnu.org/emacs.git

git clone --depth 1 https://mirrors.ustc.edu.cn/emacs.git
brew install autoconf automake texinfo gnutls pkg-config libxml2 --debug --verbose
cd ./emacs && ./autogen.sh

export LDFLAGS="-L/usr/local/opt/libxml2/lib"
export CPPFLAGS="-I/usr/local/opt/libxml2/include"
export PKG_CONFIG_PATH="/usr/local/opt/libxml2/lib/pkgconfig"

./configure && make && make install
open -R nextstep/Emacs.app
# dragging Emacs to the Applications folder.

cp  nextstep/Emacs.app/Contents/MacOS/bin/emacsclient /usr/local/bin/
cp  nextstep/Emacs.app/Contents/MacOS/emacs /usr/local/bin/
```


### For MacOS(m1,m2)


```
 brew tap railwaycat/emacsmacport
 # brew install emacs-mac --with-modules
 # brew install emacs-mac  --with-no-title-bars --with-imagemagick --with-dbus --with-modules
 brew install emacs-mac  --with-imagemagick --with-dbus --with-modules
 open -R /opt/homebrew/opt/emacs-mac/Emacs.app
 # dragging Emacs to the Applications folder.

 # emacs-rime 输入法，需要文件 emacs-module.h, M2/M1 mac，路径是 /opt/homebrew/Cellar/emacs-mac/emacs-28.2-mac-9.1/include
```

关于切换 openssl 版本

```
brew install openssl@3
brew install openssl@1.1
brew unlink openssl@3
brew link openssl@1.1
# 按照提示 export 对应的环境变量

```

### Automatically depoly vim/emacs

```
# 添加自己的插件到: .vimrc
./vim.sh

# 添加自己的配置到: .emacs.d/config.org
rm -rf ~/.emacs*
./emacs.sh

# Start emacs gui and wait for emacs pull all the plugins
# 
# Note: if you encouter "Failed to verify signature xxx"
# 1. set package-check-signature to nil, e.g. M-: (setq package-check-signature nil) RET
# 2. download the package gnu-elpa-keyring-update and run the function with the same name, e.g. M-x package-install RET gnu-elpa-keyring-update RET.
# 3. reset package-check-signature to the default value allow-unsigned，e.g. M-: (setq package-check-signature t) RET

```


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
	
1. 部署 macos squirrel

```
brew install --cask squirrel
mkdir -p  ~/Library/Rime
cp -rf ./squirrel/* ~/Library/Rime/

# redeploy siquirrel
```

2. 部署 emacs squireel
  
```
curl -L -O https://github.com/rime/librime/releases/download/1.7.3/rime-1.7.3-osx.zip
unzip rime-1.7.3-osx.zip -d ~/.emacs.d/librime
rm -rf rime-1.7.3-osx.zip

# 如果MacOS Gatekeeper阻止第三方软件运行，可以暂时关闭它：
# 
# sudo spctl --master-disable
# # later: sudo spctl --master-enable

# 使用 toggle-input-method 来激活，默认快捷键为 C-\

```

## Proxy(http代理服务器，用来连接上游sock5)

	如果您使用 Trojan 则采用 1080， 如果您使用 ClashX 则采用 7890 作为 socks5 监听端口！
	同时也要适配 .alias, .gitconfig 中的的 1080/7890


    ```
	
    wget https://www.irif.fr/~jch/software/files/polipo/polipo-1.1.1.tar.gz
	tar zxvf polipo-1.1.1.tar.gz
	cd polipo-1.1
	make all
    ./polipo -c ~/.polipo


    # 建议做成 daemon

    sudo cp polipo.plist  /Library/LaunchDaemons/
    sudo chmod 644 /Library/LaunchDaemons/polipo.plist
    plutil /Library/LaunchDaemons/polipo.plist
    sudo launchctl load /Library/LaunchDaemons/polipo.plist
    sudo launchctl start polipo
	launchctl list | grep polipo

	# 删除
    launchctl unload /Library/LaunchDaemons/polipo.plist

	#  1. 命令行代理 vi ~/.polipo 配置 http -〉socks5 (用於不支持sock5代理的應用)
	#  2. github 代理 vi ~/.gitconfig 适配sock5监听端口
	#  3. .aliases 文件中的 hproxy 使用步驟1配置的http代理端口使用http代理
	youtube-dl --proxy socks5://127.0.0.1:7890 video_url -o /download_dir/%(title)s-%(id)s.%(ext)s

    ```

## 编程语言(Erlang/Elixir/Golang/Rust)

采用 asdf 来管理语言多个版本(brew instlla asdf）

1. Erlang/Elixir
```
  asdf plugin add erlang 
  asdf plugin-add rebar 

  export KERL_BUILD_DOCS=yes 
  export KERL_INSTALL_MANPAGES=yes 
  export EGREP=egrep 
  export CC=clang 
  export CPP="clang -E" 
  export CFLAGS="-O2 -g -fno-stack-check -Wno-error=implicit-function-declaration"
  export KERL_CONFIGURE_OPTIONS="--disable-debug --without-javac --without-odbc --without-jinterface --with-ssl=$(brew --prefix openssl)"

  asdf install rebar 3.20.0
  asdf install erlang 24.3.4
  asdf global rebar  3.20.0
  asdf global erlang 24.3.4
  
```

如果遇到错误：  unable to find crypto OpenSSL lib
参考： ttps://github.com/erlang/otp/issues/4821
可以尝试以下方案

1） export KERL_CONFIGURE_OPTIONS="--disable-debug --without-javac --without-odbc --without-jinterface --with-ssl=$(brew --prefix openssl) --disable-parallel-configure"
2） vi ~/.asdf/plugins/erlang/kerl search  we need to      —>  795         Darwin)      改为： Darwin-disabled


2. Golang

```
    asdf plugin-add golang
	asdf list all golang
    asdf install golang 1.19.5
    asdf global golang 1.19.5
```
3. Rust

```
	asdf plugin-add rust
	asdf list all rust
    asdf install rust 1.67.0
    asdf global rust 1.67.0

```
## Emacs 启动与配置

启动 emacs 等待插件自动安装完毕!!!

1. 编程语言跳转 lsp-server

```
  pip3 install epc orjson six
```

  选择对应语言的安装包 -- https://github.com/manateelazycat/lsp-bridge#supported-language-servers
```
  - Rust: brew install rust-analyzer && rustup component add rust-src rustfmt clippy rls rust-analysis
  - Golang: go install golang.org/x/tools/gopls@latest
  - Erlang: 
    asdf plugin-add rebar https://github.com/Stratus3D/asdf-rebar.git
    asdf install erlang 24.3.4
    asdf install rebar 3.20.0
	which rebar3
    git clone https://github.com/erlang-ls/erlang_ls && cd erlang_ls && make && PREFIX=~/ make install
  - Yaml: npm install -g yaml-language-server
```


2. 适配章节 .emacs.d/config.org 中 ( Custom Var) 中的变量


```
  (setq erlang-path-prefix "~/.asdf/installs/erlang/24.3.4")
  (setq erlang-lib-tools-version "3.5.2")
  (setq plantuml-path "/opt/homebrew/Cellar/plantuml/1.2023.1/libexec/plantuml.jar")
  (setq http-proxy "127.0.0.1:8123")     ; HTTP/HTTPS proxy
  (setq socks-proxy "127.0.0.1:7890")    ; SOCKS proxy
  (setq emacs-module-header-root "/opt/homebrew/Cellar/emacs-mac/emacs-28.2-mac-9.1/include")

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
