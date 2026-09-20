#!/usr/bin/env bash
# build-librime.sh —— 从源码编译安装带 lua 插件的 librime（Ubuntu 22.04 专用）
#
# 解决的问题：jammy 源里的 librime 是 1.7.3，跑不动雾凇拼音(rime-ice)的
# lua_translator / lua_filter——报 `LuaTranslation::Next: attempt to call a nil
# value`，候选词整个为空，打不出中文。雾凇要求 librime ≥ 1.8.5。本脚本从源码编
# 最新 librime，并把 hchunhui/librime-lua 以 merged-plugin 方式打进 librime.so，
# 装到 /usr/local（jammy 的 ld.so.conf 里 /usr/local/lib 排在 /usr/lib 之前，
# 新库会盖过 apt 的 1.7.3，不用 purge apt 包，也不破坏 fcitx5-rime 的依赖）。
#
# 用法：
#   ./build-librime.sh            # 装依赖、装 CMake、克隆、编译、安装
#   ./build-librime.sh --dry-run  # 只打印会做什么，不碰系统
#   ./build-librime.sh --force    # 已克隆/已编过也强制重来
#
# 环境变量：
#   RIME_SRC_DIR   librime 源码目录，默认 $HOME/src/librime
#   RIME_JOBS      并行编译线程数，默认 nproc（内存小就改成 2）
#   CMAKE_VERSION  CMake 版本，默认 3.30.5
#
# 脚本只做「编译安装 librime」这一件确定的事。装完之后的 fcitx5 重启、重新部署
# rime、重编 emacs-rime 模块、把雾凇拷进 ~/.config/fcitx/rime/ 这些要碰会话/GUI
# 的步骤，结尾会打印成清单，不替你执行。
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DRY_RUN=0
FORCE=0
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run|-n) DRY_RUN=1 ;;
    --force)       FORCE=1 ;;
    -h|--help)
      sed -n '2,/^[^#]/p' "$0" | sed '$d' | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *) echo "未知参数：$1" >&2; exit 2 ;;
  esac
  shift
done

# 空字符串只换行不打前缀，否则纯为留白的那几处会印出孤零零一个「==>」
say()  { [ -z "${1:-}" ] && { printf '\n'; return 0; }; printf '\033[1;32m==>\033[0m %s\n' "$1"; }
warn() { printf '\033[1;33m警告：\033[0m %s\n' "$1"; }
die()  { printf '\033[1;31m错误：\033[0m %s\n' "$*" >&2; exit 1; }
# dry-run 下只打印，不真的执行
run()  { if [ "$DRY_RUN" = 1 ]; then say "[dry-run] $*"; else "$@"; fi; }

# ---- 0. 前置检查 ----
[ "$(uname -s)" = "Linux" ] || die "这个脚本只用于 Linux。"
command -v apt-get >/dev/null 2>&1 || die "找不到 apt-get，只支持 Debian / Ubuntu。"

# 只在 22.04（jammy）才需要：23.04 起源里就是 1.8.5+。别的版本提示一句但继续（无害）。
# shellcheck disable=SC1091
. /etc/os-release 2>/dev/null || true
if [ "${VERSION_CODENAME:-}" = "jammy" ] || [ "${VERSION_ID:-}" = "22.04" ]; then
  say "Ubuntu 22.04（jammy），源里的 librime 1.7.3 需要替换。"
else
  warn "这不是 jammy（${VERSION_ID:-未知}）。源里可能已经有 1.8.5+，先确认再决定要不要跑。"
fi

if [ "$(id -u)" = "0" ]; then
  SUDO=""
elif [ "$DRY_RUN" = 1 ]; then
  # dry-run 只打印，不真碰系统，也就没必要验证 sudo——没终端时 sudo -v 会直接失败
  SUDO="sudo"
else
  command -v sudo >/dev/null 2>&1 || die "需要 sudo 或 root 权限，但两者都没有。"
  say "需要管理员权限，下面可能要求输入密码。"
  sudo -v || die "sudo 验证失败。"
  SUDO="sudo"
fi

RIME_SRC_DIR="${RIME_SRC_DIR:-$HOME/src/librime}"
RIME_JOBS="${RIME_JOBS:-$(nproc 2>/dev/null || echo 4)}"
CMAKE_VERSION="${CMAKE_VERSION:-3.30.5}"
case "$(uname -m)" in
  x86_64)  CMAKE_ARCH="x86_64" ;;
  aarch64) CMAKE_ARCH="aarch64" ;;
  *) die "不认识的架构 $(uname -m)，请手动指定 CMAKE_ARCH。" ;;
esac
CMAKE_DIR="/opt/cmake-${CMAKE_VERSION}-linux-${CMAKE_ARCH}"
CMAKE_TARBALL="cmake-${CMAKE_VERSION}-linux-${CMAKE_ARCH}.tar.gz"

# 已装 cmake 是否 >= 指定 major.minor；没装或读不到版本算不满足
cmake_version_ge() {
  local maj="$1" min="$2" ver have_maj have_min
  ver="$(cmake --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)"
  [ -n "$ver" ] || return 1
  have_maj="${ver%%.*}"
  have_min="$(printf '%s' "$ver" | cut -d. -f2)"
  [ "$have_maj" -gt "$maj" ] && return 0
  [ "$have_maj" -eq "$maj" ] && [ "$have_min" -ge "$min" ]
}

# ---- 1. 编译依赖 ----
say "安装编译依赖……"
run $SUDO apt-get update
run $SUDO apt-get install -y build-essential git pkg-config ninja-build \
  libboost-all-dev libgoogle-glog-dev libyaml-cpp-dev \
  libleveldb-dev libmarisa-dev libopencc-dev libunwind-dev \
  liblua5.3-dev

# ---- 2. CMake ≥ 3.25 ----
say "检查 CMake……"
if cmake_version_ge 3 25; then
  say "CMake $(cmake --version | head -1 | grep -oE '[0-9.]+') 已满足 ≥ 3.25，跳过。"
else
  say "CMake 太旧（或没装），下载 $CMAKE_VERSION 到 $CMAKE_DIR……"
  run wget -q "https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/${CMAKE_TARBALL}" \
    -O "/tmp/${CMAKE_TARBALL}"
  run $SUDO tar xzf "/tmp/${CMAKE_TARBALL}" -C /opt
  for b in cmake ctest cpack; do
    run $SUDO ln -sf "$CMAKE_DIR/bin/$b" "/usr/local/bin/$b"
  done
  run rm -f "/tmp/${CMAKE_TARBALL}"
fi

# ---- 3. 源码 + lua 插件 ----
say "准备 librime 源码（$RIME_SRC_DIR）……"
if [ -d "$RIME_SRC_DIR/.git" ] && [ "$FORCE" != 1 ]; then
  say "已克隆，跳过。要用 --force 重新拉。"
else
  run mkdir -p "$(dirname "$RIME_SRC_DIR")"
  [ "$FORCE" = 1 ] && run rm -rf "$RIME_SRC_DIR"
  run git clone --recursive https://github.com/rime/librime.git "$RIME_SRC_DIR"
fi
# install-plugins.sh 把 hchunhui/librime-lua 装进 plugins/lua（幂等，已存在则 git pull）
run bash "$RIME_SRC_DIR/install-plugins.sh" hchunhui/librime-lua

# ---- 4. 编译 + 安装 ----
say "编译 librime（merged-plugins 把 lua 打进 .so）……"
run make -C "$RIME_SRC_DIR" merged-plugins -j"$RIME_JOBS"
run make -C "$RIME_SRC_DIR" -j"$RIME_JOBS"
run $SUDO make -C "$RIME_SRC_DIR" install

# ---- 5. 刷新动态链接缓存 ----
run $SUDO ldconfig

# rime_deployer 没有 --version（只会打 invalid arguments.），所以直接看装到
# /usr/local/lib 的库文件名：librime.so.1 是指向 librime.so.1.<版本> 的符号链接。
say "验证安装……"
if [ "$DRY_RUN" = 1 ]; then
  say "[dry-run] 检查 /usr/local/lib/librime.so.1 是否装好"
elif [ -e /usr/local/lib/librime.so.1 ]; then
  say "已装：$(readlink -f /usr/local/lib/librime.so.1)"
  say "ld.so.conf 里 /usr/local/lib 排在 /usr/lib 前，运行时新库会盖过 apt 的 1.7.3。"
else
  warn "没在 /usr/local/lib 找到 librime.so.1，install 可能没成功。"
fi

say ""
say "编译安装完成。剩下这几步要碰会话/GUI，脚本不替你执行："
printf '%s\n' \
  '  1) 重启 fcitx5：             fcitx5 -r' \
  '  2) 重新部署 rime：           rm -rf ~/.local/share/fcitx5/rime/build/*  然后随便打个字触发' \
  '  3) 重编 emacs-rime 模块：    Emacs 里 M-x rime-compile-module，再重启 Emacs' \
  '  4) 给 Emacs 补雾凇：         cp -r ~/.local/share/fcitx5/rime/* ~/.config/fcitx/rime/' \
  '  验证 lua 生效：              fcitx5 里输入 rq 应出当前日期'
