# 文件說明

- .aliases: 命令別名
- .exports: 环境变量
- .aliases: cmd别名
- .config: ssh 配置文件
- jumper.expect 一个跳板机相关脚本
- apt.sh: ubuntu 工具安裝腳本
- brew.sh: macos 工具安裝腳本
- .macos:   a config script for macos refer: https://github.com/mathiasbynens/dotfiles/blob/main/.macos

# 初始化

同步 .files 到 home 目录, 安装常用库，工具,软件(自动适配 linux，macos)

```
git clone https://github.com/robertzhouxh/dotfiles 
cd dotfiles
# -------------------------------------------------------------------------------
# 更新到最新 commit 可以使用  # git submodule update --init --remote
# 修改 .gitmodules 后 可以执行 # git submodule sync 
# 更新到 .gitmodules 中的 commit
# -------------------------------------------------------------------------------
git submodule update --init
set -- -f; source bootsrap.sh
```
# macos 部署
## 安裝 emacs
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

## vim/emacs 部署

```
rm -rf ~/.emacs*
./vim.sh
./emacs.sh
```
启动 Emacs

## 安装鼠须管输入法+雾凇词库

```
brew install --cask squirrel
mkdir -p  ~/Library/Rime
rm -rf ~/Library/Rime/*

git clone https://github.com/iDvel/rime-ice --depth=1
cp -r ./rime-ice/*  ~/Library/Rime/

# redeploy siquirrel

```

## 安裝 Emacs 需要的 librime

```
curl -L -O https://github.com/rime/librime/releases/download/1.9.0/rime-a608767-macOS.tar.bz2
tar jxvf rime-a608767-macOS.tar.bz2 -C ~/.emacs.d/librime

# 如果MacOS Gatekeeper阻止第三方软件运行，可以暂时关闭它：
# 
# sudo spctl --master-disable
# # later: sudo spctl --master-enable

# 使用 toggle-input-method 来激活，默认快捷键为 C-\

```

## Mac 付费软件推荐

```
brew install Proxifier （记得 DNS 选择 Resolve hostname through proxy)
brew install CleanShot （截图软件，桃宝宝买licence）
```
# ubuntu 部署
## 换清华源
```
cp /etc/apt/sources.list /etc/apt/sources.bak
vi /etc/apt/sources.list

deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy main restricted universe multiverse
deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy main restricted universe multiverse

deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-security main restricted universe multiverse
deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-security main restricted universe multiverse

deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-updates main restricted universe multiverse
deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-updates main restricted universe multiverse

deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-backports main restricted universe multiverse
deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-backports main restricted universe multiverse

## Not recommended
# deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-proposed main restricted universe multiverse
# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-proposed main restricted universe multiverse
```

## 网络代理最土实践-机场 + v2rayA + SwitchyOmega + proxy-ns/polipo/Proxifier
### 安装 v2rayA 
```
// 添加公钥
wget -qO - https://apt.v2raya.org/key/public-key.asc | sudo tee /etc/apt/keyrings/v2raya.asc

// 添加源
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


### 离线安装 chrome + Proxy-SwitchyOmega
```
wget -c https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo dpkg -i google-chrome-stable_current_amd64.deb
```

离线安装Proxy-SwitchyOmega
- 下载： https://github.com/FelisCatus/SwitchyOmega/releases/download/v2.5.20/SwitchyOmega_Chromium.crx
- 将扩展名改为 .zip, 解压缩到某个目录
- 打开 chrome 扩展程序，打开开发者模式，加载已经解压缩的文件目录就安装好了

### 离线安装 polipo(http->socks5)

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


### 源码安装 Polipo(http->socks5)

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

## 网络代理最佳实践-机场 + v2raya + GFWList(来自emacs 大神 lazycat)

机场 + v2raya + GFWList 全局透明代理， (不再需要 SwitchyOmega 和 proxy-ns/polipo/Proxifier)

- 购买机场， 安装 v2raya, 浏览器打开 http://127.0.0.1:2017 登录以后进行配置：
- 订阅机场: 拷贝机场订阅 URL, 点击导入按钮导入
- 选择服务器： 选择 S.JISUSUB.CC 标签， 选择一个合适的服务器， 然后选择左上角启动按钮
- 更新 GFWList： 点击页面右上角设置按钮， 在设置对话框右上角点击更新按钮更新 GFWLIST， 然后再按照下面的步骤对设置页面进行配置
- 透明代理/系统代理： 启用 GFWList 模式
- 透明代理/系统代理实现方式： redirect
- 规则端口的分流模式： GFWList 模式
- 防止 DNS 污染： DNS-over-HTTPS
- 特殊模式： supervisor
- TCPFastOpen: 关闭
- 多路复用： 关闭
- 自动更新 GFWList: 每个 1 小时自动更新
- 自动更新订阅: 每个 1 小时自动更新
- 解析订阅地址/更新时优先使用： 不进行分流

故障解决

failed to start v2ray-core: LocateServerRaw: ID or Sub exceed range
- 删除 “/etc/v2raya” 目录下所有文件， 
- 然后重启 v2raya sudo systemctl restart v2raya 后， 重新导入机场地址即可.


## 安装星火应用商店
https://spark-app.store/

```
wget https://gitee.com/deepin-community-store/spark-store/releases/download/4.2.7.3/spark-store_4.2.7.3_amd64.deb

// 不可以！不可以！不可以！直接调用dpkg是不处理依赖的！使用
[❌] sudo dpkg -i spark-store_4.2.7.3_amd64.deb 
[✅] sudo apt install ./spark-store_4.2.7.3_amd64.deb 
```
- 安装微信
- 安装字体
## 安装字体
``` 
apt-cache search wqy-microhei
apt install fonts-wqy-microhei

// 查看已经安装的字体
$ sudo fc-list :lang=zh

apt-cache search fonts | grep noto

// 看看是否安装
dpkg -l *fonts-noto*

// 如果没有安装则
sudo apt-get install fonts-noto-cjk
sudo apt-get install fonts-noto-mono
sudo apt-get install fonts-noto-color-emoji

// 下载苍耳今楷字体： http://tsanger.cn/product/47 
// 注意：用字体管理界面看一下字体名称，再配置到 emacs 配置文件中
wget http://tsanger.cn/download/%E4%BB%93%E8%80%B3%E4%BB%8A%E6%A5%B705-W03.ttf
mv 仓耳今楷05-W03.ttf ~/.fonts/TsangerJinKai05.ttf

// 下载 Noto_Sans/Serif_SC 字体： https://fonts.google.com/
// 下载鸿蒙字体： https://developer.harmonyos.com/cn/docs/design/des-guides/font-0000001157868583

unzip fontsxxx.zip
mkdir ~/.fonts
cp -rf HarmonyOS_ ~/.fonts
cp -rf Noto_* ~/.fonts

fc-cache -f

// 管理字体
sudo apt install font-manager

```
## 中文输入法

检查系统中文环境
在 Ubuntu 设置中打开「区域与语言」—— 「管理已安装的语言」，然后会自动检查已安装语言是否完整。若不完整，根据提示安装即可。

```
sudo apt install fcitx5 \
    fcitx5-chinese-addons \
    fcitx5-frontend-gtk4 fcitx5-frontend-gtk3 fcitx5-frontend-gtk2 \
    fcitx5-frontend-qt5

// 安装 RIME 输入法
sudo apt install fcitx5-rime

// 安装 librime
emacs-rime 会用到这个lib
 
```
### 配置输入法以及环境变量

使用 im-config 工具可以配置首选输入法，在任意命令行输入： im-config
根据弹出窗口的提示，将首选输入法设置为 Fcitx 5 即可。
-  ~/.bash_profile，这样只对当前用户生效，而不影响其他用户。
- 系统级的 /etc/profile。

```
export XMODIFIERS=@im=fcitx
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
```

- 或者在 /etc/environment 這個檔案加入以下三行
```
 GTK_IM_MODULE=fcitx
 QT_IM_MODULE=fcitx
 XMODIFIERS=@im=fcitx
 ```


### 下載東風破（plum）
git clone https://github.com/rime/plum.git && cd plum
用東風破下載行列輸入法【來源】
東風破的預設是 ibus-rime，所以要特別指定是 fcitx5-rime
rime_frontend=fcitx5-rime bash rime-install array emoji

### 开机自启动
在 Tweaks（sudo apt install gnome-tweaks）中将 Fcitx 5 添加到「开机启动程序」列表中即可。
### Fcitx 配置
Fcitx 5 提供了一个基于 Qt 的强大易用的 GUI 配置工具，可以对输入法功能进行配置。有多种启动该配置工具的方法：
- 在应用程序列表中打开「Fcitx 配置」
- 在 Fcitx 托盘上右键打开「设置」
- 命令行命令 fcitx5-configtool

注意:「输入法」标签页下，应将「键盘 - 英语」放在首位，拼音（或其他中文输入法）， Rime  放在后面的位置。

### 安装雾凇拼音( 词库 )
使用下面的命令拷贝雾凇拼音的所有 rime 配置到 fcitx 的 rime 配置目录下

```
git clone https://github.com/iDvel/rime-ice --depth=1


更新到 Fcitx 目录
cp -r ./rime-ice/* ~/.config/fcitx/rime/
cp -r ./rime-ice/* ~/.local/share/fcitx5/rime

~/.config/fcitx/rime/: 这个目录主要是 Emacs 的 emacs-rime 插件会读取
~/.local/share/fcitx5/rime: 这个目录是 Fcitx 读取的， 用于外部软件使用雾凇输入法
```
### 自定义主题
    
Fcitx 5 默认的外观比较朴素，用户可以根据喜好使用自定义主题。
- 第一种方式为使用经典用户界面，可以在 GitHub 搜索主题，然后在 Fcitx5 configtool —— 「附加组件」 —— 「经典用户界面」中设置即可。
- 第二种方式为使用 Kim面板，一种基于 DBus 接口的用户界面。 此处安装了 Input Method Panel 这个 GNOME 扩展(浏览器打开安装 https://extensions.gnome.org/extension/261/kimpanel/)， 黑色的风格与正在使用的 GNOME 主题 Orchis-dark 非常搭配。
- 安装  Orchis-dark 主题
- 用浏览器（chrome 扩展程序）打开： https://extensions.gnome.org/  接下来 click here to install browser extension, HNOME Shell 集成扩展安装好， 安装 User Themes  扩展， 最后在已经安装的扩展中找到 对应组件，打开开关 User Themes 扩展开关
- Tweaks 配置 Application 和 Shell 的主题


## 安装 Emacs

源码安装
```
git clone --depth 1 https://mirrors.ustc.edu.cn/emacs.git

sudo apt build-dep emacs
sudo apt install libgccjit0 libgccjit-10-dev libjansson4 libjansson-dev \
    gnutls-bin libtree-sitter-dev gcc-10 imagemagick libmagick++-dev \
    libwebp-dev webp libxft-dev libxft2

export CC=/usr/bin/gcc-10
export CXX=/usr/bin/gcc-10

cd emacs-29.1
./autogen.sh
./configure --with-native-compilation=aot --with-imagemagick --with-json \
    --with-tree-sitter --with-xft
make -j$(nproc)

# test
./src/emacs -Q

make install

```


## 安裝 librime

https://github.com/DogLooksGood/emacs-rime/blob/master/INSTALLATION.org

```
sudo apt install librime-dev

## 请注意 librime-dev 的版本，如果在1.5.3以下，则需要自行编译。
sudo apt install git build-essential cmake libboost-all-dev libgoogle-glog-dev libleveldb-dev libmarisa-dev libopencc-dev libyaml-cpp-dev libgtest-dev
git clone https://github.com/rime/librime.git ~/.emacs.d/librime
cd ~/.emacs.d/librime
make
sudo make install
```

## 安装 pyqt6
```
sudo apt install python3-pip
pip3 install pyqt6
```
## 安装 openjdk 

```

apt-cache search openjdk 
sudo apt-get install openjdk-17-jdk
sudo apt-get install openjdk-17-jre
sudo apt install plantuml

or: 手动安装
wget https://github.com/plantuml/plantuml/releases/download/v1.2023.11/plantuml-mit-1.2023.11.jar
sudo tar -xvzf plantuml-mit-1.2023.11.jar -C /usr/local/share/plantuml
sudo ln -s /usr/local/share/plantuml/ /usr/local/bin/plantuml

```

## 安装 plantuml

```

#!/usr/bin/env bash
# Install PlantUML
set -e

PLANTUML_URL="${PLANTUML_URL:-http://sourceforge.net/projects/plantuml/files/plantuml.jar/download}"

if [[ -f "/opt/plantuml/plantuml.jar" && -f "/usr/bin/plantuml" ]]; then
  echo '[plantuml] PlantUML already installed.'
  exit
fi

echo '[plantuml] Installing PlantUML...'
apt-get install -y default-jre graphviz
mkdir -p /opt/plantuml
curl -o /opt/plantuml/plantuml.jar -L "${PLANTUML_URL}"
printf '#!/bin/sh\nexec java -Djava.awt.headless=true -jar /opt/plantuml/plantuml.jar "$@"' > /usr/bin/plantuml
chmod +x /usr/bin/plantuml

```


## 安装 texlive
如果不嫌安装包大，可以按照官网的方式安装：https://tug.org/texlive/doc/texlive-en/texlive-en.html#x1-160003.1.1


```

apt-cache search texlive
// Tex Live: Basic LaTex packages.
sudo apt install texlive-latex-base

// Installs all LaTex CJK packages.（Chinese，Japanese，Korea）
apt-cache search cjk
sudo apt install latex-cjk-all

// 有些.sty文件可能没有安装，如：lastpage.sty. 
// 注意不要加.sty文件后缀
// texlive-latex-extra - TeX Live: LaTeX supplementary packages
apt-cache search lastpage
sudo apt install texlive-latex-extra

// 以上三步，可以满足需求。
// 需要使用到新的包，可以查找相应的安装包安装
// ! LaTeX Error: File `siunitx.sty' not found.
apt-cache  search  siunitx
// texlive-science - TeX Live: Mathematics, natural sciences, computer science packages

// texmaker程序，它是一个图形化界面的Tex书写，编译，生成，预览集合为一体的程序。
sudo apt install texmaker

// XeLaTex
sudo apt install texlive-xetex

// latexmk
sudo apt install latexmk

```

### 如何解决! LaTeX Error: File `physics2.sty' not found.

这里选择手动安装

```
find /usr/share/texlive -name "*.sty"
=> 输出文件列表， latex,luatex,xetex,generic 表示不同的 pdf 编译器
/usr/share/texlive/texmf-dist/tex/xetex/xetexko/xetexko.sty
/usr/share/texlive/texmf-dist/tex/{latex,xelatex,luatex,xetex,generic...}/*

// 这里我使用 xelatex 作为 pdf 编译器
git clone git@github.com:AlphaZTX/physics2.git

sudo mkdir -p /usr/share/texlive/texmf-dist/tex/xelatex/phy
cp -rf ./physics2/tex/* /usr/share/texlive/texmf-dist/tex/xelatex/phy

sudo mktexlsr 

```

## 安装 docker

参考官方安装方法： https://docs.docker.com/engine/install/ubuntu/
```
# Set up the Docker daemon, systemd/cgroupfs

cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "registry-mirrors":["https://bycacelf.mirror.aliyuncs.com"],
  "exec-opts": ["native.cgroupdriver=cgroupfs"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

# Create /etc/systemd/system/docker.service.d
sudo mkdir -p /etc/systemd/system/docker.service.d

# Restart Docker
sudo systemctl daemon-reload
sudo systemctl restart docker

# 彻底卸载 docker
sudo apt-get purge docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras
sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd
```

## 恢复到原始桌面配置： $dconf reset -f /org/gnome/
## Ctrl 与 Caps 键位交换
    
- 打开 Gnome Tweaks,
- 选择 choose Keyboard -> Additional Layout Options -> Ctrl Position -> Swap...
## 坑爹的 NVIDIA 显卡驱动-(附重启黑屏解决办法）
外星人M18 安装 Ubuntu 22.04 以后需要安装显卡驱动， 
- 推荐用第三种安装方式
- 首先需要F2 进入 BIOS 中设置 secure mode 为 false~
- 确定显卡型号 

```
$ ubuntu-drivers devices

== /sys/devices/pci0000:00/0000:00:01.0/0000:01:00.0 ==
modalias : pci:v000010DEd00002206sv00001458sd0000403Fbc03sc00i00
vendor : NVIDIA Corporation
model : GA102 [GeForce RTX 3080]
driver : nvidia-driver-470 - distro non-free recommended
driver : nvidia-driver-470-server - distro non-free
driver : nvidia-driver-495 - distro non-free
driver : nvidia-driver-460-server - distro non-free
driver : xserver-xorg-video-nouveau - distro free builtin

```

注解： 

- the current system has NVIDIA GeForce RTX 3080 graphic card installed
- the recommend driver to install is nvidia-driver-470.
- sudo apt install nvidia-driver-470
  
## 官网手动下载安装( 重启以后直接黑屏，卡死，进不去系统 )

官网下载对应版本的显卡驱动 ( 会自动识别 ) - https://www.nvidia.com/download/index.aspx

```
chmod +x NVIDIA-Linux-x86_64-535.113.01.run
sudo ./NVIDIA-Linux-x86_64-535.113.01.run
nvidia-settings -q NvidiaDriverVersion
nvidia-smi
```

## 利用源来安装
```
# Check the current installed nvidia driver
sudo apt list '*nvidia-driver*'

# Remove the current driver and tools if neccessary
sudo apt-get purge '*nvidia*'
sudo apt autoremove
sudo apt autoclean

# Install the required driver version
 sudo apt install nvidia-driver-470

# Check the installation
nvidia-settings -q NvidiaDriverVersion
nvidia-smi

sudo reboot
```

## Software & Updates 安装
- 搜索 Software & Updates 
- 切换到 Additional Drivers
- 选择合适的显卡驱动，点击右下方的 Apply Changes 按钮。
- 结束后重启计算机。

## 重启黑屏解决方案

- 启动PC ，方向键选择 Advanced options for Ubuntu
- 进入下一个界面，选 recovery mode
- 进入Recovery Menu，选 root 
- 卸载 nvidia 驱动（源安装则： apt remove --purge nvidia*）（官网下载安装： nvidia-uninsatll ）
- cp /etc/default/grub /etc/default/grub.bak  && vim /etc/default/grub

```
GRUB_CMDLINE_LINUX_DEFAULT="quiet"  ---> 注释掉这一行          # GRUB_CMDLINE_LINUX_DEFAULT="quiet"
GRUB_CMDLINE_LINUX=""               ---> ""内改为 text        GRUB_CMDLINE_LINUX="text"
#GRUB_TERMINAL=console              ---> 去掉注释             GRUB_TERMINAL=console
```
- update-grub
- reboot

- 重启正常以后，选择上述第三种 Software & Updates 安装对应版本的驱动
- 再次重启就可以了
- 可以重新进入 recovery mode - root - 恢复 (mv  /etc/default/grub.bak /etc/default/grub) --> update-grub -> reboot 

参考:

- https://zhuanlan.zhihu.com/p/608786007
- https://www.alibabacloud.com/help/en/elastic-gpu-service/latest/uninstall-a-gpu-driver#section-t1c-es8-mb5
- https://www.techsupportall.com/how-to-uninstall-nvidia-driver/#linux

## debian/ubuntu 安装Nvidia显卡驱动后触摸板手势失灵

Nvidia 官方驱动是基于X11环境的，而 debian/ubuntu 的 Gnome 桌面 在 x11 环境下不支持触摸板手势
需要安装以下插件，让其支持触摸板手势

🌀步骤1：安装Touchegg: https://github.com/JoseExposito/touchegg

Ubuntu 系统建议使用ppa进行安装
```
sudo add-apt-repository ppa:touchegg/stable
sudo apt update
sudo apt install touchegg
```
如系统无法以ppa安装，则请下载合适的安装档进行安装
① https://github.com/JoseExposito/touchegg/releases
② sudo apt install ./touchegg_*.deb 进行安装

🌀步骤2： 安装 X11 Gestures: https://extensions.gnome.org/extension/4033/x11-gestures/

如果触摸板手势用着不舒服或者需要很长路径才能触发，按照文档配置以下参数即可
https://github.com/JoseExposito/touchegg#daemon-configuration

🌀步骤3：如果不想安装图形化配置可以直接在操作配置文件

```
mkdir -p ~/.config/touchegg && cp -n /usr/share/touchegg/touchegg.conf ~/.config/touchegg/touchegg.conf
vim ~/.config/touchegg/touchegg.conf
rm ~/.config/touchegg/.touchegg:1.lock
```

- 也可以参考全局配置选项： https://github.com/JoseExposito/touchegg#global-settings
- 注意：删除 ~/.config/touchegg/.touchegg:1.lock
- 可参考仓库中的 touchegg.conf 文件， 注意，这里的<action type="SEND_KEYS">的手势，是基于你的自定义快捷键（settings->keyboard）

1、三指左右滑动可切换工作区
2、三指上滑可以显示概览窗口，即活动窗口，再次上滑可取消概览窗口
3、三指下滑可最小化当前窗口
4、三指内缩可关闭窗口，这是个持续动作，内缩回收可撤回（不止聚焦的窗口可用，只要在屏幕上显示的窗口都可以使用）
5、三指点击表示鼠标中键
6、四指上滑可显示全部菜单，再次上滑可回到概览窗口
7、四指左、右滑动，可将当前窗口移动至左、右工作区
8、四指外阔显示桌面
9、单指，双指保持正常逻辑

### 图形化配置【可选】
🌀步骤1： 安装图形化手势配置管理

Touche是Touchegg的图形化设定软件，建议由Flatpak进行安装：

① 先安裝flatpack

sudo apt install flatpak
flatpak remote-add --if-not-exists flathub  https://flathub.org/repo/flathub.flatpakrepo
sudo reboot

② 安装 Touche: flatpak install flathub com.github.joseexposito.touche 
③ 运行 Touche: flatpak run com.github.joseexposito.touche 

🌀步骤2：在Touche 设定三指&四指手势

Touche的选单提供了8 种系统动作，可依需求自行指定到不同的触控手势：
窗口最大化Maximize or restore a window
♦ 窗口最小化Minimize a window
♦ 平铺窗口Tile a window
♦ 全屏幕窗口Fullscreen a window
♦ 结束窗口Close a window
♦ 切换桌面Switch desktops/workspaces
♦ 显示桌面Show desktop
♦ 执行自定义的快捷键Keyboard shortcut

例如设定手势为：
- 3指向上滑，将APP窗口最大化；
- 3指向下滑，将APP窗口最小化；
- 3指向左/右滑，将APP窗口平铺至左半边或右半边。

# 多語言支持
## Erlang/Elixir on macos

```
  asdf plugin add erlang 
  asdf plugin-add rebar 

  export KERL_BUILD_DOCS=yes 
  export KERL_INSTALL_MANPAGES=yes 
  export EGREP=egrep 
  export CC=clang 
  export CPP="clang -E" 
  export CFLAGS="-O2 -g -fno-stack-check -Wno-error=implicit-function-declaration"
  # export KERL_CONFIGURE_OPTIONS="--disable-debug --without-javac --without-odbc --without-jinterface --with-ssl=$(brew --prefix openssl) -with-wx-config=/opt/homebrew/bin/wx-config"
  export KERL_CONFIGURE_OPTIONS="--disable-debug --without-javac --without-odbc --without-jinterface --with-ssl=$(brew --prefix openssl) --without-wx"


  asdf list all rebar
  asdf install rebar 3.22.1
  asdf install erlang 23.3.4
  asdf install erlang 24.3.4

  asdf list rebar

  asdf global rebar  3.22.1
  asdf global erlang 24.3.4
  
```
如遇错误:  unable to find crypto OpenSSL lib
参考 https://github.com/erlang/otp/issues/4821 尝试以下方案

```
# export KERL_CONFIGURE_OPTIONS="--disable-debug --without-javac --without-odbc --without-jinterface --with-ssl=$(brew --prefix openssl) --disable-parallel-configure"
export KERL_CONFIGURE_OPTIONS="--disable-debug --without-javac --without-odbc --without-jinterface --with-ssl=$(brew --prefix openssl@1.1) --disable-parallel-configure"

asdf install erlang 23.3.4

vi ~/.asdf/plugins/erlang/kerl,  search  "we need to",  Darwin)  改为： Darwin-disabled)

asdf plugin-update --all
asdf install erlang 24.3.4
asdf global erlang 24.3.4

```
## erlang on ubuntu

```
asdf plugin-add erlang https://github.com/asdf-vm/asdf-erlang.git
    
## 不安裝 11-jdk
## sudo apt-get -y install build-essential autoconf m4 libncurses5-dev libwxgtk3.0-gtk3-dev libwxgtk-webview3.0-gtk3-dev libgl1-mesa-dev libglu1-mesa-dev libpng-dev libssh-dev unixodbc-dev xsltproc fop libxml2-utils libncurses-dev openjdk-11-jdk

sudo apt-get -y install build-essential autoconf m4 libncurses5-dev libwxgtk3.0-gtk3-dev libwxgtk-webview3.0-gtk3-dev libgl1-mesa-dev libglu1-mesa-dev libpng-dev libssh-dev unixodbc-dev xsltproc fop libxml2-utils libncurses-dev


## 建议以下方式安装
cd /usr/local/src/
sudo wget https://www.openssl.org/source/openssl-1.1.1m.tar.gz

sudo tar -xf openssl-1.1.1m.tar.gz

cd openssl-1.1.1m
sudo ./config --prefix=/usr/local/ssl --openssldir=/usr/local/ssl shared zlib

sudo make
sudo make test
sudo make install

# install erlang now
export KERL_CONFIGURE_OPTIONS="-with-ssl=/usr/local/ssl"
asdf install erlang 24.3.4

```

## Golang

```
    asdf plugin-add golang
    asdf list all golang
    asdf install golang 1.19.5
    asdf global golang 1.19.5
```
## Rust

```
    asdf plugin-add rust
    asdf list all rust
    asdf install rust 1.67.0
    asdf global rust 1.67.0

```

## node
```
asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git
asdf list all nodejs
asdf install nodejs latest:16
asdf install nodejs 19.6.0

# eaf-file-manager 需要高版本的node
asdf global node 19.6.0
```


# mac or ubuntu 中的 openssl 版本问题
## mac

按照提示 export 对应的环境变量

```
brew install openssl@3
brew install openssl@1.1
brew unlink openssl@3
brew link openssl@1.1

brew --prefix openssl@1.1

```

## ubunut

参考 erlang install 部分
