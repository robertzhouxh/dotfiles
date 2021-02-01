## Quick Start

### Install usefull applications eg: userApp,utils,libs for developer

   ```bash
   git clone https://github.com/robertzhouxh/dotfiles /path/to/dotfiles
   cd dotfiles
   set -- -f; source bootsrap.sh
   ```

### Automatically depoly vim/emacs

    ```bash

    # vim configuration file: .vimrc
    ./vim.sh

    # emacs configuration file: .emacs.d/...
    ./emacs.sh
    ```
### Emacs

use emacs org mode to describe the emacs configurations: ==.emacs.d/config.org==

Emacs: Failed to verify signature xxx

1. set package-check-signature to nil, e.g. M-: (setq package-check-signature nil) RET
2. download the package gnu-elpa-keyring-update and run the function with the same name, e.g. M-x package-install RET gnu-elpa-keyring-update RET.
3. reset package-check-signature to the default value allow-unsigned，e.g. M-: (setq package-check-signature t) RET

## other explainations

- z: jump to the target dir directly eg: $ z xxxdir
- .aliases: short name for frequence cmd
- .exports: all the envirenment varibles


## mac 中文设置

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

## C4-mode 架构图渲染

```
cd `pwd` && ggrep -rl "' !include C4" ./ | gxargs -i echo {} | gxargs gsed -i "s|' !include C4|!include /Users/glodon/.emacs.d/vendor/C4-PlantUML/C4|g"
cd `pwd` && ggrep -rl "!include https" ./ | gxargs -i echo {} | gxargs gsed -i "s|!include https|'!include https|g"

```

## to be continued...
