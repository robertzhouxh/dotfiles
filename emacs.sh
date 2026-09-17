#!/usr/bin/env bash
# emacs.sh —— 部署 .emacs.d
#
# 先验证 Emacs 版本，再动手链接。
#
# 为什么非要验证：本仓库的配置要 30.1+。`.emacs.d/lisp/` 下的 emacs-solo-*.el
# 都写了 `Package-Requires: ((emacs "30.1"))`，而 Ubuntu 22.04 的 apt 里只有 27.1。
# 不查版本就链接，用户得到的是一屏加载错误，而不是一句「你的 Emacs 太旧」。
#
# 用法：
#   ./emacs.sh               验证版本 → 备份旧配置 → 链接 .emacs.d
#   ./emacs.sh --dry-run     只打印会做什么，一个字都不落地
#   ./emacs.sh --force       版本不达标也硬上（配置大概率跑不起来，但由你决定）
#
# 环境变量：
#   EMACS   指定 emacs 二进制，默认从 PATH 找。
#           与 .emacs.d/test/run-tests.sh 用同一个变量名，方便指到别的版本上试。
#   HOME    要部署到哪个家目录，默认当前的。
set -euo pipefail

# 配置声明的最低版本。改这里之前先改 .emacs.d/lisp/emacs-solo-*.el 的 Package-Requires。
MIN_VERSION="30.1"

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$HERE/.emacs.d"

DRY_RUN=0
FORCE=0
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run|-n) DRY_RUN=1 ;;
    --force|-f)   FORCE=1 ;;
    # 打印到第一行非注释为止，不写死行号：写死的范围会随文件改动悄悄截断
    # 或越界（--help 里漏出 set -euo pipefail 就是这么来的）。
    -h|--help)    sed -n '2,/^[^#]/p' "$0" | sed '$d' | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "未知参数：$1" >&2; exit 2 ;;
  esac
  shift
done

# 空字符串只换行不打前缀，否则纯为了留白的那几处会印出孤零零一个「==>」
say()  { [ -z "${1:-}" ] && { printf '\n'; return 0; }; printf '\033[1;32m==>\033[0m %s\n' "$1"; }
warn() { printf '\033[1;33m警告：\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m错误：\033[0m %s\n' "$*" >&2; exit 1; }
run()  { if [ "$DRY_RUN" = 1 ]; then say "[dry-run] $*"; else "$@"; fi; }

# version_ge <a> <b>：a >= b 时返回 0。
# 按点号切成整数逐段比，段数不同时短的一侧补 0（30.1 与 30.1.0 等价）。
# 不能拿字符串比：那会得出 "9.9" > "30.1"。
version_ge() {
  local IFS='.'
  # shellcheck disable=SC2206  # 就是要按 IFS 切成数组
  local -a a=($1) b=($2)
  local i x y
  for ((i = 0; i < ${#a[@]} || i < ${#b[@]}; i++)); do
    x="${a[i]:-0}"; y="${b[i]:-0}"
    [ "$x" -gt "$y" ] && return 0
    [ "$x" -lt "$y" ] && return 1
  done
  return 0
}

# ---- 1. 找到 Emacs ----
EMACS_BIN="${EMACS:-emacs}"

if ! command -v "$EMACS_BIN" >/dev/null 2>&1; then
  cat >&2 <<EOF
$(printf '\033[1;31m错误：\033[0m') 找不到 emacs（找的是「${EMACS_BIN}」）。

这个脚本不会替你装 Emacs——apt 里只有 27.1，装上也跑不了本仓库的配置。
装 30+ 的两条路见 README「Ubuntu 上的 Emacs」一节：

    grep -A 12 'Ubuntu 上的 Emacs' '$HERE/README.md'

装好后重新运行本脚本。已经装在非 PATH 位置的话：

    EMACS=/opt/emacs-30/bin/emacs ./emacs.sh
EOF
  exit 1
fi

# ---- 2. 版本检查 ----
# -Q 保证不加载任何用户 init：此刻 ~/.emacs.d 可能正指向一份坏配置，
# 不能让它有机会干扰我们读版本。
RAW="$("$EMACS_BIN" -Q --version </dev/null 2>/dev/null | head -n 1 || true)"
VER="$(printf '%s\n' "$RAW" | sed -n 's/^GNU Emacs \([0-9][0-9.]*\).*$/\1/p')"

if [ -z "$VER" ]; then
  # 解析不出来就放行。宁可放过一个可能能用的 Emacs，也不要因为读不懂版本号
  # 而挡住一个显然能用的。真正的判据是启动后能不能跑起来，那是用户的事。
  warn "无法从「${RAW}」里解析出版本号，跳过版本检查。"
elif version_ge "$VER" "$MIN_VERSION"; then
  say "Emacs ${VER}（需要 ${MIN_VERSION}+），检查通过。"
elif [ "$FORCE" = 1 ]; then
  warn "Emacs ${VER} 低于要求的 ${MIN_VERSION}，按 --force 继续。配置大概率报错。"
else
  cat >&2 <<EOF
$(printf '\033[1;31m错误：\033[0m') Emacs ${VER} 太旧，本仓库配置需要 ${MIN_VERSION}+。

  .emacs.d/lisp/ 下的 emacs-solo-*.el 声明了 Package-Requires: ((emacs "30.1"))，
  配置本身也用了 29+ 才有的 API。这个组合跑不起来。

  Ubuntu 22.04 的 apt 里只有 27.1，装了也一样。
  怎么装 30+ 见 README「Ubuntu 上的 Emacs」：

      grep -A 12 'Ubuntu 上的 Emacs' '$HERE/README.md'

  确实想拿旧版试试：./emacs.sh --force
EOF
  exit 1
fi

# ---- 3. 备份旧配置 ----
[ -d "$SRC" ] || die "仓库里找不到 ${SRC}，这个脚本得在仓库目录里跑。"

TODAY="$(date +%Y%m%d)"
for i in "$HOME/.emacs" "$HOME/.emacs.d"; do
  # 已经是指向别处的符号链接不用备份，下面 -sfn 会直接换掉它。
  # -e 对坏掉的符号链接是假，所以先判 -L 才能覆盖到这种情况。
  if [ -L "$i" ]; then
    say "已有的符号链接 $(basename "$i") 将被替换。"
  elif [ -d "$i" ] || [ -f "$i" ]; then
    dst="$i.$TODAY"
    # 同一天跑第二次时，后缀撞车会让 mv 把目录塞进目录里，加个时分秒岔开
    [ -e "$dst" ] && dst="$i.$TODAY.$(date +%H%M%S)"
    say "备份 $(basename "$i") → $(basename "$dst")"
    run mv "$i" "$dst"
  fi
done

# ---- 4. 链接 ----
# -n 是必须的：目标已经是「指向目录的符号链接」时，不加 -n 的 ln 会顺着它
# 建到目标目录里面去，得到一个 ~/.emacs.d/xxx/.emacs.d 的套娃。
say "链接 ${SRC} → $HOME/.emacs.d"
run ln -sfn "$SRC" "$HOME/.emacs.d"

say ""
say "完成。启动 Emacs 后首次会从 MELPA 拉包，耐心等或先配好镜像源。"
