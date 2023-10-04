# 文件說明

- .aliases: 命令別名
- .exports: 环境变量
- .aliases: cmd别名
- .config: ssh 配置文件
- jumper.expect 一个跳板机相关脚本
- apt.sh: ubuntu 工具安裝腳本
- brew.sh: macos 工具安裝腳本
- .macos:   a config script for macos refer: https://github.com/mathiasbynens/dotfiles/blob/main/.macos

# 安装 http->socks5 协议转换代理 
    
```
	wget https://www.irif.fr/~jch/software/files/polipo/polipo-1.1.1.tar.gz
	tar zxvf polipo-1.1.1.tar.gz
	cd polipo-1.1
	make all
	nohup ./polipo -c ~/.polipo &
```
注意：

+ Docker for Mac 代理不要配成127.0.0.1:8123,
+ 原因 docker 命令是运行在 docker machine (Mac上的虚拟机)中，127.0.0.1会走其代理
+ 一定要配置成宿主机 Ip
+  定义命令别名随时在terminal 切换是否使用 polipo 代理

```
  alias hproxy='export http_proxy=http://10.1.105.135:8123;export HTTPS_PROXY=$http_proxy;export HTTP_PROXY=$http_proxy;export https_proxy=$http_proxy'
  alias proxy='export ALL_PROXY=socks5://10.1.105.135:1080'

  alias nohproxy='unset http_proxy;unset HTTPS_PROXY;unset HTTP_PROXY;unset https_proxy'
  alias noproxy='unset ALL_PROXY'

  apt-get -o Acquire::http::proxy="http://10.1.105.135:8123" update

```

# 初始化

同步 .files 到 home 目录, 安装常用库，工具,软件(自动适配 linux，macos)

```
git clone https://github.com/robertzhouxh/dotfiles 
cd dotfiles

set -- -f; source bootsrap.sh
```
# 安裝 emacs （linux, macos）
## 源码安装
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

## Mac 上建议安装 emacs-plus

```
brew tap d12frosted/emacs-plus
brew install emacs-plus --with-native-comp --with-xwidgets
ln -s /opt/homebrew/opt/emacs-plus@30/Emacs.app /Applications
```

# 同步 Emacs Submodules

```
# -------------------------------------------------------------------------------
# 更新到最新 commit 可以使用  # git submodule update --init --remote
# 修改 .gitmodules 后 可以执行 # git submodule sync 
# 更新到 .gitmodules 中的 commit
# -------------------------------------------------------------------------------
git submodule update --init
```

# vim/emacs 部署

```
./vim.sh
rm -rf ~/.emacs*
./emacs.sh
```

# 部署 macos squirrel

```
brew install --cask squirrel
mkdir -p  ~/Library/Rime
rm -rf ~/Library/Rime/*
git clone https://github.com/iDvel/rime-ice --depth=1
cp -r ./rime-ice/*  ~/Library/Rime/

# redeploy siquirrel

```

# 部署 emacs squireel

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

# 多語言支持
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

4. node
```
asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git
asdf list all nodejs
asdf install nodejs latest:16
asdf install nodejs 19.6.0

# eaf-file-manager 需要高版本的node
asdf global node 19.6.0
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

# Mac 付费软件
+ brew install Proxifier （记得 DNS 选择 Resolve hostname through proxy)
+ brew install CleanShot （截图软件，桃宝宝买licence）


# ubuntu 安装- v2rayA

```
// 添加公钥
wget -qO - https://apt.v2raya.org/key/public-key.asc | sudo tee /etc/apt/keyrings/v2raya.asc

// 添加源泉
echo "deb [signed-by=/etc/apt/keyrings/v2raya.asc] https://apt.v2raya.org/ v2raya main" | sudo tee /etc/apt/sources.list.d/v2raya.list
sudo apt update

// 安装
sudo apt install v2raya v2ray

// 启动 v2rayA 
sudo systemctl start v2raya.service

// 设置 v2rayA 自动启动
sudo systemctl enable v2raya.service



```

- 订阅机场: 浏览器打开 http://127.0.0.1:2017, 点击导入按钮， 拷贝机场订阅 URL， 点击确定
- 选择服务器： 选择 S.JISUSUB.CC 标签， 选择一个合适的服务器， 然后选择左上角 启动 按钮
- 局域网支持： 选择右上角设置按钮， 打开 开启 IP 转发 和 开启端口分享 两个按钮， 让后续的 proxy-ns 可以对接机场
- 设置端口号： 在设置对话框左下角点击 地址和端口 按钮， 设置 socks5 端口（带分流规则） 为 1080, 并重启 v2raya 服务 sudo systemctl restart v2raya.service
- 开机自动启动： 在命令行输入 sudo systemctl enable v2raya.service， 让 v2raya 开机自动启动


配置浏览器插件 SwitchyOmega
用 Chrome 开发者模式安装 SwitchyOmega ， 并添加代理配置：

- 代理协议: Socks5
- 代理服务器: 127.0.0.1
- 代理端口: 1080


离线安装 chrome
```
wget -c https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo dpkg -i google-chrome-stable_current_amd64.deb
```

离线安装Proxy-SwitchyOmega
- 下载： https://github.com/FelisCatus/SwitchyOmega/releases/download/v2.5.20/SwitchyOmega_Chromium.crx
- 将扩展名改为 .zip, 解压缩到某个目录
- 打开 chrome 扩展程序，打开开发者模式，加载已经解压缩的文件目录就安装好了

离线安装  polipo
```
wget http://archive.ubuntu.com/ubuntu/pool/universe/p/polipo/polipo_1.1.1-8_amd64.deb
sudo dpkg -i polipo_1.1.1-8_amd64.deb

vi /etc/polipo/config

# This file only needs to list configuration variables that deviate
# from the default values.  See /usr/share/doc/polipo/examples/config.sample
# and "polipo -v" for variables you can tweak and further information.

logSyslog = true
logFile = /var/log/polipo/polipo.log

proxyAddress = "0.0.0.0"

socksParentProxy = "127.0.0.1:1080"
socksProxyType = socks5

chunkHighMark = 50331648
objectHighMark = 16384

serverMaxSlots = 64
serverSlots = 16
serverSlots1 = 32


# 启动
sudo /etc/init.d/polipo restart

```

环境变量的配置了 http_proxy,  https_proxy
关于地址的写法，只写 127.0.0.1:8123 时，遇到过有软件不能识别的情况，改为写完整的地址 http://127.0.0.1:8123/ 就不会有问题了。


安装 Fcitx5 输入法： https://manateelazycat.github.io/2023/09/11/fcitx-best-config/
```
sudo pacman -S fcitx5 fcitx5-gtk fcitx5-qt fcitx5-configtool fcitx5-rime librime

## 然后将下面的内容粘贴到 ~/.pam_environment

GTK_IM_MODULE=fcitx5
XMODIFIERS=@im=fcitx5
QT_IM_MODULE=fcitx5

## 安装 Fcitx5 输入法皮肤

yay -S fcitx5-skin-adwaita-dark
```



安装 Fcitx5 输入法皮肤
```
yay -S fcitx5-skin-adwaita-dark

然后修改配置文件 ~/.config/fcitx5/conf/classicui.conf

# 横向候选列表
Vertical Candidate List=False

# 禁止字体随着 DPI 缩放， 避免界面太大
PerScreenDPI=False

# 字体和大小， 可以用 fc-list 命令来查看使用
Font="Noto Sans Mono 13"

# Gnome3 风格的主题
Theme=adwaita-dark

备注：上面的 Font 可以换成 TsangerJinKai03-6763 15

```

安装雾凇拼音

上面的步骤只是把 Fcitx 的核心和皮肤搞定了， 但是 Fcitx 默认的词库非常难用, 流畅的输入需要安装雾凇输入法。
使用下面的命令拷贝雾凇拼音的所有 rime 配置到 fcitx 的 rime 配置目录下

```
git clone https://github.com/iDvel/rime-ice --depth=1

## 修改默认配置

切换到 rime-ice 目录， 做下面三个操作:

1. grep 目录下所有- { when: paging, accept: comma, send: Page_Up } 和 - { when: has_menu, accept: period, send: Page_Down } 内容， 去掉注释
2. grep 所有 url_2 开头的行的前面都加一个 # 符号注释掉
3. grep page_size, 把 5 换成 9 即可

前两个操作是实现逗号、 句号翻页， 后面一个操作是更改候选词的数量

```

更新到 Fcitx 目录
调整完上面配置后， 进行下面拷贝操作
```

cp -r ./rime-ice/* ~/.config/fcitx/rime/
cp -r ./rime-ice/* ~/.local/share/fcitx5/rime

~/.config/fcitx/rime/: 这个目录主要是 Emacs 的 emacs-rime 插件会读取
~/.local/share/fcitx5/rime: 这个目录是 Fcitx 读取的， 用于外部软件使用雾凇输入法
```


安装 emacs-rime

这一节讲的是怎么让 Emacs 可以使用上雾凇输入法。

首先安装 posframe(https://github.com/tumashu/posframe), posframe 可以让侯选词显示在光标处， 所以建议安装。

然后下载 emacs-rime:

 ```

git clone https://github.com/DogLooksGood/emacs-rime

把 emacs-rime 目录放到 load-path 下， 添加以下配置:

(require 'rime)

;;; Code:
(setq rime-user-data-dir "~/.config/fcitx/rime")

(setq rime-posframe-properties
      (list :background-color "#333333"
            :foreground-color "#dcdccc"
            :font "WenQuanYi Micro Hei Mono-14"
            :internal-border-width 10))

(setq default-input-method "rime"
      rime-show-candidate 'posframe)
```
