#!/usr/bin/env bash
# vim.sh —— 部署 .vimrc 与 .vim，并装好插件
#
# .vimrc 和 .vim 建符号链接，不走 deploy.sh 的复制：插件装在仓库的 .vim/plugged 下
# 跟着仓库走，git pull 之后配置立即生效。
#
# 这里为什么单独盯住 autoload/plug.vim：~/.vim 是指向本仓库 .vim 的符号链接，
# 于是 ~/.vim/autoload/plug.vim 和仓库里的 .vim/autoload/plug.vim 是同一个文件。
# 早先的版本对这两条路径做了 ln，第二次运行就把真实的 plug.vim 换成了一个指向
# 自己的符号链接，curl 写不进去（Too many levels of symbolic links），vim 启动即报
# E117: Unknown function: plug#begin。现在只认仓库里那一个路径，下载走「先写临时文件、
# 再 mv」，永远碰不到自己的链接；万一哪次留下了这种自指环，脚本会先把它清掉。
#
# 用法：
#   ./vim.sh                 链接配置 → 装 vim-plug → PlugInstall
#   ./vim.sh --dry-run       只打印会做什么；一个字不落地，也不联网
#   ./vim.sh --no-plugins    只链接配置，不碰 vim-plug 和插件（离线时用）
#   ./vim.sh --update-plug   强制重新下载 plug.vim（默认只在缺失或损坏时下载）
#
# 环境变量：
#   VIM   指定 vim 二进制，默认从 PATH 找。
#   HOME  要部署到哪个家目录，默认当前的。
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VIMDIR="$HERE/.vim"
PLUG_URL="https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"

DRY_RUN=0
DO_PLUGINS=1
FORCE_PLUG=0
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run|-n)  DRY_RUN=1 ;;
    --no-plugins)  DO_PLUGINS=0 ;;
    --update-plug) FORCE_PLUG=1 ;;
    # 打印到第一行非注释为止，不写死行号：写死的范围会随文件改动悄悄截断或越界。
    -h|--help)     sed -n '2,/^[^#]/p' "$0" | sed '$d' | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "未知参数：$1" >&2; exit 2 ;;
  esac
  shift
done

# 空字符串只换行不打前缀，否则纯为了留白的那几处会印出孤零零一个「==>」
say()  { [ -z "${1:-}" ] && { printf '\n'; return 0; }; printf '\033[1;32m==>\033[0m %s\n' "$1"; }
warn() { printf '\033[1;33m警告：\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m错误：\033[0m %s\n' "$*" >&2; exit 1; }
run()  { if [ "$DRY_RUN" = 1 ]; then say "[dry-run] $*"; else "$@"; fi; }

# ---- 1. 找到 vim ----
# 旧版这里有一行从 spf13 抄来的提权检查，白弹一次密码。这个脚本一个需要 root 的
# 动作都没有，删掉。
VIM_BIN="${VIM:-vim}"

if ! command -v "$VIM_BIN" >/dev/null 2>&1; then
  cat >&2 <<EOF
$(printf '\033[1;31m错误：\033[0m') 找不到 vim（找的是「${VIM_BIN}」）。

装一个：macOS 上 brew install macvim，Ubuntu 上 apt install vim
（ubuntu.sh 的可选包清单里有它）。两个平台的说明都在 README 里。

已经装在非 PATH 位置的话：

    VIM=/opt/macvim/bin/vim ./vim.sh
EOF
  exit 1
fi

[ -f "$HERE/.vimrc" ] || die "仓库里找不到 $HERE/.vimrc，这个脚本得在仓库目录里跑。"

# ---- 2. 备份旧配置 ----
TODAY="$(date +%Y%m%d)"

# 三种情况：指向别处的符号链接直接换掉；内容和仓库一致的（比如 deploy.sh 复制过来的
# .vimrc）也直接换掉，不必每次跑都堆一个备份；剩下的才真是用户数据，先备份。
handle_existing() {
  local p="$1" dst
  if [ -L "$p" ]; then
    say "$(basename "$p") 已是指向 $(readlink "$p") 的符号链接，直接替换。"
  elif [ ! -e "$p" ]; then
    :
  elif [ -f "$p" ] && cmp -s "$p" "$HERE/$(basename "$p")"; then
    say "$(basename "$p") 内容与仓库一致，直接换成符号链接。"
  else
    dst="$p.$TODAY"
    # 同一天跑第二次时后缀撞车，mv 会把目录塞进目录里，加个时分秒岔开
    [ -e "$dst" ] && dst="$p.$TODAY.$(date +%H%M%S)"
    say "备份 $(basename "$p") → $(basename "$dst")"
    run mv "$p" "$dst"
  fi
}

handle_existing "$HOME/.vimrc"
handle_existing "$HOME/.vim"

# ---- 3. 链接 ----
run mkdir -p "$VIMDIR"
say "链接 $HERE/.vimrc → $HOME/.vimrc"
# -n 是必须的：目标已经是「指向目录的符号链接」时，不加 -n 的 ln 会顺着它建到目标
# 目录里面去，得到一个 ~/.vim/xxx/.vim 的套娃。
run ln -sfn "$HERE/.vimrc" "$HOME/.vimrc"
say "链接 $VIMDIR → $HOME/.vim"
run ln -sfn "$VIMDIR" "$HOME/.vim"

# ---- 4. vim-plug 与插件 ----
# 到此为止 ~/.vim 已经指向仓库，下面一律只用 $VIMDIR 这一条路径，
# 绝不再拼 $HOME/.vim/... —— 那正是当初把 plug.vim 写成自指环的原因。
if [ "$DO_PLUGINS" = 1 ]; then
  PLUG="$VIMDIR/autoload/plug.vim"

  # 坏掉的符号链接：-L 为真而 -e 为假（自指环就是 ELOOP，-e 也是假）。清掉它。
  if [ -L "$PLUG" ] && [ ! -e "$PLUG" ]; then
    warn "autoload/plug.vim 是坏掉的符号链接（$(readlink "$PLUG")），先删掉。"
    run rm -f "$PLUG"
  fi

  run mkdir -p "$VIMDIR/autoload" "$VIMDIR/plugged"

  if [ "$FORCE_PLUG" = 1 ] || [ ! -f "$PLUG" ]; then
    say "下载 vim-plug → ${PLUG#"$HERE"/}"
    if [ "$DRY_RUN" = 1 ]; then
      say "[dry-run] curl -fsSL -o $PLUG.tmp $PLUG_URL"
    else
      # 先删后下再 mv：一是下载中途断线不会留下半截的 plug.vim（那会让 vim 每次
      # 启动都报错），二是临时路径上要是有条符号链接，也不至于顺着它写到别处去。
      rm -f "$PLUG.tmp"
      if ! curl -fsSL -o "$PLUG.tmp" "$PLUG_URL"; then
        rm -f "$PLUG.tmp"
        die "下载 vim-plug 失败。网络不通就先 ./vim.sh --no-plugins，
      或者手动把 plug.vim 放到 ${PLUG#"$HERE"/}。"
      fi
      mv -f "$PLUG.tmp" "$PLUG"
    fi
  else
    say "vim-plug 已就位（--update-plug 可强制更新）"
  fi

  say "安装插件（PlugInstall）"
  if [ "$DRY_RUN" = 1 ]; then
    say "[dry-run] $VIM_BIN -u $HOME/.vimrc +PlugInstall! +qall"
  # stdin 关掉、输出吞掉：非终端环境下 vim 会刷一屏「Input is not from a terminal」
  # 和一堆转义序列，把真正有用的信息冲走。
  elif "$VIM_BIN" -u "$HOME/.vimrc" +PlugInstall! +qall </dev/null >/dev/null 2>&1; then
    say "插件就绪。"
  else
    warn "PlugInstall 没有干净退出，插件可能没装全。手动看一眼：vim +PlugInstall"
  fi
fi

say ""
say "完成。插件目录：${VIMDIR#"$HERE"/}/plugged"
