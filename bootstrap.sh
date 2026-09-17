#!/usr/bin/env bash
# bootstrap.sh —— 裸 Debian/Ubuntu 引导
#
# 解决的问题：刚装好的 Ubuntu 上连 git 都没有，`git clone` 根本无从谈起。
# 这个脚本只用系统自带的东西（apt / curl）把「能 clone 仓库」这一步打通，然后交给 ubuntu.sh。
#
# 两种用法：
#   1. 已经在目标机上拿到这个文件：
#        ./bootstrap.sh
#   2. 目标机上什么都没有，一行搞定：
#        curl -fsSL https://raw.githubusercontent.com/robertzhouxh/dotfiles/main/bootstrap.sh | bash
#
# 参数：
#   --dry-run    只打印会做什么。也用来在任意平台上验证脚本能跑通管道执行。
#
# 环境变量：
#   DOTFILES_REPO   仓库地址，默认 https://github.com/robertzhouxh/dotfiles.git
#   DOTFILES_DIR    克隆位置，默认 $HOME/dotfiles
set -euo pipefail

# `curl | bash` 时 stdin 就是脚下的脚本本身，sudo 一读密码就把剩下的脚本吃光了。
# 所以检测到 stdin 不是终端，先把脚本落盘再从文件重新执行。
#
# 两个平台差异各自的坑：
#   - mktemp 的模板必须让 XXXXXX 结尾（BSD mktemp 不认识后缀），所以建目录而不是建文件
#   - /dev/tty 这个设备节点存在不代表能打开（无控制终端时 open 会返回 ENXIO），
#     得真去读一下才知道，光用 -e 判断会把脚本送进一个必然失败的重定向
#
# 判据是「脚本体来自 stdin」而不是「stdin 不是终端」：后者在
# `./bootstrap.sh </dev/null`、CI、以及任何 stdin 被重定向的调用下都会误判，
# 那时 cat 会读到 EOF，写出一个空脚本，然后一声不吭地执行完一个空文件。
# BASH_SOURCE[0] 为空或不是可读的普通文件，才说明内容是从 stdin 灌进来的。
_src="${BASH_SOURCE[0]:-}"
if [ -z "$_src" ] || [ ! -f "$_src" ]; then
  _tmpdir="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-bootstrap.XXXXXX")"
  _self="$_tmpdir/bootstrap.sh"
  cat > "$_self"
  chmod +x "$_self"
  if { true </dev/tty; } 2>/dev/null; then
    exec bash "$_self" "$@" </dev/tty
  fi
  exec bash "$_self" "$@"
fi

REPO_URL="${DOTFILES_REPO:-https://github.com/robertzhouxh/dotfiles.git}"
DEST="${DOTFILES_DIR:-$HOME/dotfiles}"
DRY_RUN=0

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run|-n) DRY_RUN=1 ;;
    # 打印到第一行非注释为止，不写死行号：写死的范围会随文件改动截断，
    # 把 DOTFILES_DIR 那行环境变量说明整段漏掉。
    -h|--help) sed -n '2,/^[^#]/p' "$0" | sed '$d' | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "未知参数：$1" >&2; exit 2 ;;
  esac
  shift
done

say()  { [ -z "${1:-}" ] && { printf '\n'; return 0; }; printf '\033[1;32m==>\033[0m %s\n' "$1"; }
warn() { printf '\033[1;33m警告：\033[0m %s\n' "$1"; }
die()  { printf '\033[1;31m错误：\033[0m %s\n' "$1" >&2; exit 1; }
run()  { if [ "$DRY_RUN" = 1 ]; then say "  [dry-run] $*"; else "$@"; fi; }

# ---- 1. 平台与包管理器 ----
# dry-run 下只提醒不拦：它本来就是个「看看会发生什么」的开关，
# 而且门禁测试正是在 macOS 上用它来验证管道执行这条路径。
if [ "$(uname -s)" != "Linux" ]; then
  if [ "$DRY_RUN" = 1 ]; then
    warn "当前不是 Linux，dry-run 只做演示。"
  else
    die "这个脚本只用于 Linux。macOS 请直接看 README 的 macOS 一节。"
  fi
fi

if ! command -v apt-get >/dev/null 2>&1; then
  if [ "$DRY_RUN" = 1 ]; then
    warn "找不到 apt-get，dry-run 只做演示。"
  else
    die "找不到 apt-get。这个脚本只支持 Debian / Ubuntu（Debian 系）。"
  fi
fi

# ---- 2. 拿 sudo ----
SUDO=""
if [ "$DRY_RUN" = 0 ] && [ "$(id -u)" != "0" ]; then
  command -v sudo >/dev/null 2>&1 || die "需要 sudo 或 root 权限，但两者都没有。"
  say "需要管理员权限，下面可能要求输入密码。"
  sudo -v || die "sudo 验证失败。"
  SUDO="sudo"
  # 安装期间保持 sudo 时间戳有效，别装到一半又停下来要密码
  while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
fi

# ---- 3. 装出「能 clone」的最小依赖 ----
say "更新软件包索引……"
# 裸机上索引是空的，不 update 直接 install 会失败
run $SUDO apt-get update

# 没有这些就没法 clone，也没有 TLS 根证书。curl 通常自带，写上是为幂等。
BOOTSTRAP_PKGS=(git curl ca-certificates rsync)

say "安装：${BOOTSTRAP_PKGS[*]}"
run $SUDO apt-get install -y "${BOOTSTRAP_PKGS[@]}"

if [ "$DRY_RUN" = 0 ]; then
  for bin in git curl rsync; do
    command -v "$bin" >/dev/null 2>&1 || die "$bin 安装后仍不可用，请检查 apt 源。"
  done
fi

# ---- 4. 取仓库 ----
if [ "$DRY_RUN" = 1 ]; then
  if [ -d "$DEST/.git" ]; then
    say "  [dry-run] git -C ${DEST} pull --ff-only"
  else
    say "  [dry-run] git clone ${REPO_URL} ${DEST}"
  fi
elif [ -d "$DEST/.git" ]; then
  say "仓库已存在：${DEST}，拉取最新……"
  git -C "$DEST" pull --ff-only
elif [ -e "$DEST" ]; then
  die "$DEST 已存在但不是 git 仓库。换个位置（DOTFILES_DIR=/别的/路径）或者先处理掉它。"
else
  say "克隆到 ${DEST} ……"
  git clone "$REPO_URL" "$DEST"
fi

# ---- 5. 交给 ubuntu.sh ----
say ""
say "引导完成。接下来运行："
printf '\n    cd %s && ./ubuntu.sh\n\n' "$DEST"
say "它会安装开发工具、部署 dotfiles，并把登录 shell 切到 zsh。"
