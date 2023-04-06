# 文件說明

- .aliases: 命令別名
- .exports: 环境变量
- .aliases: cmd别名
- .config: ssh 配置文件
- jumper.expect 一个跳板机相关脚本
- apt.sh: ubuntu 工具安裝腳本
- brew.sh: macos 工具安裝腳本
- .macos:   a config script for macos refer: https://github.com/mathiasbynens/dotfiles/blob/main/.macos

# 准备工作
## 临时 F-Q 

1. 查找域名对应的ip

- https://www.ipaddress.com/site/raw.githubusercontent.com
- https://www.ipaddress.com/site/github.com

2. 修改 /etc/hosts 这样访问 github 页面就暂时不需要 FQ

```
sudo vi /etc/hosts 
x.x.x.x raw.githubusercontent.com
x.x.x.x github.com
```
## 安装网络代理
### 外网服务器安装 trojan server on Debain(9,10.8)

```bash
wget -N --no-check-certificate https://raw.githubusercontent.com/mark-hans/trojan-wiz/master/ins.sh && chmod +x ins.sh && bash ins.sh


  #  安装过程中提示“请选择证书模式”，选择”使用 IP 自签发证书”的模式。

systemctl start trojan-gfw 
systemctl status trojan-gfw 
```

- 通过 systemctl status trojan-gfw  确定服务启动
- 通过 netstat -anlp | grep 443 确定端口在被监听
- 云主机的防火墙开放 443,80,22 TCP 端口

### 本地 PC 机安装
#### 安装 trojan client
    
```
# for linux: 
wget https://github.com/trojan-gfw/trojan/releases/download/v1.16.0/trojan-1.16.0-linux-amd64.tar.xz

# for macos: 
wget  https://github.com/trojan-gfw/trojan/releases/download/v1.16.0/trojan-1.16.0-macos.zip

unzip trojan-1.16.0-macos.zip
cd trojan

scp root@xxx.xxx.xxx.xxx:/home/trojan/ca-cert.pem ./
scp root@xxx.xxx.xxx.xxx:/home/trojan/client.json ./

# 修改从云端 scp 回来的 client.json 

#local_addr: "0.0.0.0"
#local_port: 1080

nohup ./trojan -c client.json &
```

#### 安装 http->socks5 协议转换代理 

```
	wget https://www.irif.fr/~jch/software/files/polipo/polipo-1.1.1.tar.gz
	tar zxvf polipo-1.1.1.tar.gz
	cd polipo-1.1
	make all
	nohup ./polipo -c ~/.polipo &
```

这里还可以使用brew install privoxy

```
vi /path/to/privoxy/config

##代表把所有匹配/的请求(也就是所有请求)，以sock5协议转发到127.0.0.1:1080,最后一个.代表不转发到http代理
forward-socks5 / 127.0.0.1:1080 .
listen-address  0.0.0.0:8118

brew services start/stop privoxy
```

注意：

如果Docker for Mac的代理配成了127.0.0.1:8118/8123,原因docker命令运行在docker machine中的（Mac上的虚拟机），配成127.0.0.1会尝试走那台机器的代理，所以会出错。
因此一定要配置成宿主机IpAddress

#### 其他配置

1. 定义命令别名随时在terminal 切换是否使用 polipo 代理

将以下两行添加到你的 .bashrc 中，启动 terminal 的时候自动加载

```
  alias hproxy='export http_proxy=http://127.0.0.1:8123;export HTTPS_PROXY=$http_proxy;export HTTP_PROXY=$http_proxy;export FTP_PROXY=$http_proxy;export https_proxy=$http_proxy;export ftp_proxy=$http_proxy;'

  alias nohproxy='unset http_proxy;unset HTTPS_PROXY;unset HTTP_PROXY;unset FTP_PROXY;unset https_proxy;unset ftp_proxy'

```


2. 验证curl,wget走 polipo 代理

```
  proxy 
  echo $http_proxy
  # 可以看到此环境变量被设置为上述别名的值
  curl -v www.google.com 
  # 可以看到走的是本地的 8123 端口，确定走了 polipo 代理
  # 在不需要使用polipo 的时候直接 noproxy 就可以取消 polipo 代理
```
3. 验证 git走1080代理

```
#修改 ~/.gitconfig

[user]
  name = xx
  email = xx@gmail.com
  
[http "https://github.com"]
  proxy = socks5://127.0.0.1:1080
  postBuffer = 524288000
  sslVerify = false

```

4. google 浏览器安装 Proxy SwitchyOmega 并配置

# 部署 Tools/Apps/Emacs/Vim

同步 .files 到 home 目录, 安装常用库，工具,软件(自动适配 linux，macos)

```
git clone https://github.com/robertzhouxh/dotfiles 
cd dotfiles

set -- -f; source bootsrap.sh
```
## 安裝 emacs （linux, macos）

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

# Emacs/Vim 設置
## 同步 Emacs Submodules

```
# -------------------------------------------------------------------------------
# 更新到最新 commit 可以使用  # git submodule update --init --remote
# 修改 .gitmodules 后 可以执行 # git submodule sync 
# 更新到 .gitmodules 中的 commit
# -------------------------------------------------------------------------------
git submodule update --init
```

## Automatically depoly vim/emacs

```
./vim.sh
rm -rf ~/.emacs*
./emacs.sh

# start emacs and wait for plugins install complete
# 手动安装 all-the-icons
# M-x install-package all-the-icons
# M-x all-the-icons-install-fonts

```


## Emacs squirrel 中文輸入法

部署 macos squirrel

```
brew install --cask squirrel

mkdir -p  ~/Library/Rime

# cp -rf ./squirrel/* ~/Library/Rime/
# redeploy siquirrel

# 或者使用以下两个开源的配置
https://github.com/ssnhd/rime
https://github.com/iDvel/rime-ice

```

部署 emacs squireel

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

# Emacs 多語言支持
## 安裝

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
  export KERL_CONFIGURE_OPTIONS="--disable-debug --without-javac --without-odbc --without-jinterface --with-ssl=$(brew --prefix openssl) -with-wx-config=/opt/homebrew/bin/wx-config"
  #export KERL_CONFIGURE_OPTIONS="--disable-debug --without-javac --without-odbc --without-jinterface --with-ssl=$(brew --prefix openssl) --without-wx"


  asdf install rebar 3.20.0
  asdf install erlang 23.3.4
  asdf install erlang 24.3.4
  asdf global rebar  3.20.0
  asdf global erlang 24.3.4
  
```

如遇错误:  unable to find crypto OpenSSL lib

参考 https://github.com/erlang/otp/issues/4821 尝试以下方案

```
export KERL_CONFIGURE_OPTIONS="--disable-debug --without-javac --without-odbc --without-jinterface --with-ssl=$(brew --prefix openssl) --disable-parallel-configure"

vi ~/.asdf/plugins/erlang/kerl,  search  "we need to",  Darwin)  改为： Darwin-disabled)
```

wx相关错误,ref: https://github.com/asdf-vm/asdf-erlang/issues/203
```
git clone git@github.com:wxWidgets/wxWidgets.git
cd wxWidgets
git submodule update --init src/png
git submodule update --init src/jpeg
./configure --with-cocoa --prefix=/usr/local --enable-webview --enable-compat28 --with-macosx-version-min=11.3
make
sudo make install

export KERL_BUILD_DOCS=yes
export KERL_INSTALL_MANPAGES=yes
export wxUSE_MACOSX_VERSION_MIN=11.3
export EGREP=egrep
export CC=clang
export CPP="clang -E"
export KERL_USE_AUTOCONF=0

export KERL_CONFIGURE_OPTIONS="--disable-debug \
                               --disable-hipe \
                               --disable-sctp \
                               --disable-silent-rules \
                               --enable-darwin-64bit \
                               --enable-dynamic-ssl-lib \
                               --enable-kernel-poll \
                               --enable-shared-zlib \
                               --enable-smp-support \
                               --enable-threads \
                               --enable-wx \
                               --with-ssl=/opt/local \
                               --with-wx-config=/usr/local/bin/wx-config \
                               --without-javac \
                               --without-jinterface \
                               --without-odbc"
```

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
## 语言補全語法跳轉

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
  (setq socks-proxy "127.0.0.1:1080")    ; SOCKS proxy
  (setq emacs-module-header-root "/opt/homebrew/Cellar/emacs-mac/emacs-28.2-mac-9.1/include")

```

3. 重新启动 emacs



```
brew install openssl@3
brew install openssl@1.1
brew unlink openssl@3
brew link openssl@1.1
# 按照提示 export 对应的环境变量

```


# asdf 安裝低版本 Node

```
asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git
asdf list all nodejs
asdf install nodejs latest:16
asdf install nodejs 19.6.0

# eaf-file-manager 需要高版本的node
asdf global node 19.6.0
```

# emacs 听音乐 with eaf-music-player

```
 brew install taglib
 pip install --global-option=build_ext --global-option="-I/opt/homebrew/include" --global-option="-L/opt/homebrew/lib/"  pytaglib
```
# Mac 付费软件 

代理软件: proxifier 
+ brew install Proxifier （记得 DNS 选择 Resolve hostname through proxy)
+ socks5: localhost:1080
+ https:  localhost:8123

截图软件： brew install CleanShot （桃宝宝买licence）
# Mac 安装 Ubuntu 开发环境

终于可以不用再选 vmware、ParallelDesktop 了， 安装Ubuntu 的发行商 Canonical 开发的 Multipass
建议用 gui 的方式安装， 我用 brew 安装以后一直报错

```
brew install multipass
multipass find
## multipass launch -n master -c 2 -m 2G -d 40G focal

## 失败：launch failed: Downloaded image hash does not match
## sudo launchctl unload /Library/LaunchDaemons/com.canonical.multipassd.plist
## stop multipass, sudo rm -rf  /var/root/Library/Caches/multipassd/network-cache, start multipass
##                  sudo rm -rf /var/root/Library/Caches/multipassd/vault
## sudo launchctl load /Library/LaunchDaemons/com.canonical.multipassd.plist


## 使用 qemu-img 命令调整已经创建的实例的磁盘大小: brew install qemu
## stop：multipass stop master
## resize: sudo qemu-img resize "/var/root/Library/Application Support/multipassd/qemu/vault/instances/master/ubuntu-20.04-server-cloudimg-arm64.img" +20G
## start again: multipass start master

multipass shell master
# 设置密码: sudo passwd ubuntu （xxxxxx） 建议直接一个空格当密码
# 设置密码: sudo passwd root   （xxxxxx） 建议直接一个空格当密码

直接使用宿主机代理
alias proxy='export ALL_PROXY=socks5://hostIp:1080'
alias hproxy='export http_proxy=http://hostIp:8123;export HTTPS_PROXY=$http_proxy;export HTTP_PROXY=$http_proxy;;export https_proxy=$http_proxy;'

# 更新apt: apt-get update

...

# 安装 asdf

git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.11.2


```


# elisp 

```elisp
  ;; Environment
  (use-package exec-path-from-shell
  :ensure t
  :if (or sys/mac-x-p sys/linux-x-p)
  :config
  (setq exec-path-from-shell-variables '("PATH" "GOPATH"))
  (setq exec-path-from-shell-arguments '("-l"))
  (exec-path-from-shell-initialize))
  
  ; 光标直接放到最后一个list  [ (exec-path-from-shell-initialize) ]括号上执行 c-x c-e
  ; 如 (featurep 'cocoa)  c-x c-e 在minibuffer中输出 t
```
