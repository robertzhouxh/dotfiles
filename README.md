# 初始化

同步 .files 到 home 目录
```
rsync -av --include='.*' --exclude='.git' --exclude='.DS_Store' --exclude='*' ./ ~/
```

# MacOS 
## 工具软件
```
./brew.sh
```
## 付费软件

```
brew install Proxifier （记得 DNS 选择 Resolve hostname through proxy)
brew install CleanShot （截图软件，桃宝宝买licence）
```

## 安裝 emacs
- 参考: https://github.com/d12frosted/homebrew-emacs-plus
- 参考: https://github.com/jimeh/build-emacs-for-macos
## vim/emacs 部署

```
rm -rf ~/.emacs*
./vim.sh
./emacs.sh
```
启动 Emacs

## 安装鼠须管输入法+雾凇词库

```
git clone --depth=1 https://github.com/Mark24Code/rime-auto-deploy.git --branch latest
cd rime-auto-deploy
./installer.rb
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

# UbuntuOS
## disable-while-typing
```
gsettings set org.gnome.desktop.peripherals.touchpad disable-while-typing true
```
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

## 其他 

1. 截图软件： sudo apt install flameshot
2. 恢复到原始桌面配置： $dconf reset -f /org/gnome/
3. 护眼： 打开夜灯模式（settings->display->nightlight）
3. Ctrl 与 Caps 键位交换: Gnome Tweaks -> Choose Keyboard -> Additional Layout Options -> Ctrl Position -> Swap...
4. 按键全局使用 Emacs 模式： Gnome Tweaks -> Keyboard&Mouse -> Emacs Input 打开
5. debian/ubuntu 安装Nvidia显卡驱动后触摸板手势失灵

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

- 也可以参考全局配置选项： https://github.com/JoseExposito/touchegg#global-settings
- 注意：删除 ~/.config/touchegg/.touchegg:1.lock
- 可参考仓库中的 touchegg.conf 文件， 注意，这里的<action type="SEND_KEYS">的手势，是基于你的自定义快捷键（settings->keyboard）

## 坑爹的 NVIDIA 显卡驱动
### 驱动安装
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
  
1. 官网手动下载安装( 重启以后直接黑屏，卡死，进不去系统 )

官网下载对应版本的显卡驱动 ( 会自动识别 ) - https://www.nvidia.com/download/index.aspx

```
chmod +x NVIDIA-Linux-x86_64-535.113.01.run
sudo ./NVIDIA-Linux-x86_64-535.113.01.run
nvidia-settings -q NvidiaDriverVersion
nvidia-smi
```

2. 利用源来安装
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

3. Software & Updates 安装

Software & Updates -> Additional Drivers -> 选择显卡驱动 -> 点右下方 Apply Changes -> 重启

### 重启黑屏解决方案

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

### 安装 NVIDIA Container Toolkit 
https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html#setting-up-nvidia-container-toolkit

```
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
  && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list \
  && \
    sudo apt-get update

sudo apt-get install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```

# 多语言支持
## 用好 asdf
