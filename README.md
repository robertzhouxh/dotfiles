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
# 更新到最新 commit 可以使用  # git submodule update --init --recursive --remote
# 修改 .gitmodules 后 可以执行 # git submodule sync 
# 更新到 .gitmodules 中的 commit
# -------------------------------------------------------------------------------
git submodule update --init


# -------------------------------------------------------------------------------
# git clone --depth 1 git://git.savannah.gnu.org/emacs.git
# 选择国内的同步镜像
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

### 维护 emacs 配置
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
5. erlang 依赖  erlang_ls 并适配路径

### 代码跳转

1. nox 方案， M-X ---> nox ---> C-], C-T
2. dumb-jump 方案， M-], M-T

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

brew cask install squirrel


#可以直接使用 cd ~/Library && git clone https://github.com/Zheaoli/RimeConfig.git Rime/
#或者自己按照如下配制

vi ~/Library/Rime/luna_pinyin.custom.yaml

# luna_pinyin.custom.yaml

patch:
  switches:                   # 注意縮進
    - name: ascii_mode
      reset: 0                # reset 0 的作用是當從其他輸入方案切換到本方案時，
      states: [ 中文, 西文 ]  # 重設爲指定的狀態，而不保留在前一個方案中設定的狀態。
    - name: full_shape        # 選擇輸入方案後通常需要立即輸入中文，故重設 ascii_mode = 0；
      states: [ 半角, 全角 ]  # 而全／半角則可沿用之前方案中的用法。
    - name: simplification
      reset: 1                # 增加這一行：默認啓用「繁→簡」轉換。
      states: [ 漢字, 汉字 ]


vi ~/Library/Rime/squirrel.custom.yaml

# squirrel.custom.yaml

patch:
  style/color_scheme: clean_white        # 选择配色方案
  style/horizontal: true                 # 候选窗横向显示
  style/inline_preedit: false            # 关闭内嵌编码，这样就可以显示首行的拼音
  style/font_point: 28                   # 字号

# 重新加载配置
修改配置，需要重新加载配置文件，新的配置才能生效。可以在输入法托盘图标右键点击 重新部署，或者用快捷键 Ctrl + alt + ~


cd ~/.emacs.d/
 wget https://github.com/rime/librime/releases/download/1.6.1/rime-1.6.1-osx.zip
unzip rime-1.6.1-osx.zip -d ~/.emacs.d/librime

```
## Proxy(代理设置)
	
    ```
	1. 命令行代理 vi ~/.polipo 适配转发端口
	2. github 代理 vi ~/.gitconfig 适配sock5监听端口
    ```


## To be continued...
