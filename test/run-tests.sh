#!/usr/bin/env bash
# 门禁测试运行器：确定性、本地、免费、无网络、无 sudo、<2 秒、永不 flaky。
#
# 覆盖范围：
#   - 所有 shell 文件的语法
#   - 「无硬编码家目录」回归（/Users/zxh 那类写死路径）
#   - .alias / .envv 在 mac 与 linux 两个平台下的真实行为（靠 DOTFILES_OS 注入）
#   - .zprofile 的 brew 探测不刷错误
#   - deploy.sh 的完整行为：dry-run 无副作用、复制、链接、幂等、备份
#   - vim.sh 的完整行为：链接、幂等、自指符号链接自愈（curl / vim 换成桩）
#   - emacs.sh 的版本闸门（假 emacs 喂各种版本号）
#   - 各脚本 --help 的完整性与不泄漏代码
#   - README 引用的脚本确实存在
#
# 用法：test/run-tests.sh
set -uo pipefail   # 刻意不用 -e：单个用例失败要收集起来继续跑，最后统一报告

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
cd "$REPO"

PASS=0
FAIL=0
FAILED_NAMES=()

ok()  { PASS=$((PASS + 1)); printf '  \033[32m✓\033[0m %s\n' "$1"; }
bad() {
  FAIL=$((FAIL + 1)); FAILED_NAMES+=("$1")
  printf '  \033[31m✗\033[0m %s\n' "$1"
  [ $# -gt 1 ] && printf '      %s\n' "$2"
  return 0
}
group() { printf '\n\033[1m%s\033[0m\n' "$1"; }

# assert_ok <名称> <命令...>           命令必须返回 0
assert_ok()   { local n="$1"; shift; if "$@" >/dev/null 2>&1; then ok "$n"; else bad "$n" "$* 返回非 0"; fi; }
# assert_fail <名称> <命令...>         命令必须返回非 0
assert_fail() { local n="$1"; shift; if "$@" >/dev/null 2>&1; then bad "$n" "$* 本应失败却成功了"; else ok "$n"; fi; }
# assert_contains <名称> <大海捞针> <针>
assert_contains() {
  local n="$1" hay="$2" needle="$3"
  if [[ "$hay" == *"$needle"* ]]; then ok "$n"; else bad "$n" "输出里没有「${needle}」，实际是：${hay:0:200}"; fi
}
# assert_not_contains <名称> <大海捞针> <针>
assert_not_contains() {
  local n="$1" hay="$2" needle="$3"
  if [[ "$hay" != *"$needle"* ]]; then ok "$n"; else bad "$n" "输出里不该有「${needle}」"; fi
}

# ---------------------------------------------------------------------------
group "语法"

SHELL_FILES=$(
  { git ls-files '*.sh' '.alias' '.bashrc' '.bash_profile' '.envv' '.zshrc' '.zprofile' 2>/dev/null \
      || printf '%s\n' .alias .bashrc .bash_profile .envv .zshrc .zprofile \
           bootstrap.sh ubuntu.sh deploy.sh vim.sh emacs.sh brew.sh; } | sort -u
)

for f in $SHELL_FILES; do
  [ -f "$f" ] || continue
  assert_ok "bash -n $f" bash -n "$f"
done

if command -v zsh >/dev/null 2>&1; then
  for f in .zshrc .zprofile; do
    assert_ok "zsh -n $f" zsh -n "$f"
  done
else
  printf '  \033[33m-\033[0m 跳过 zsh 语法检查（本机没有 zsh）\n'
fi

for f in bootstrap.sh ubuntu.sh deploy.sh vim.sh emacs.sh; do
  assert_ok "$f 有可执行位" test -x "$f"
done

# ---------------------------------------------------------------------------
group "回归：不得写死家目录"

# 针自己不能以字面量出现在这个文件里，否则测试会命中自己。拼出来。
MAC_HOME=$(printf '/%s/' Users)

HITS=""
for f in $(git ls-files 2>/dev/null); do
  case "$f" in test/*) continue ;; esac
  [ -f "$f" ] || continue
  if grep -qF "$MAC_HOME" "$f" 2>/dev/null; then HITS="$HITS$f "; fi
done

if [ -z "$HITS" ]; then
  ok "被跟踪文件里没有写死的 macOS 家目录"
else
  bad "被跟踪文件里没有写死的 macOS 家目录" "命中：$HITS"
fi

# libncurses5-dev 是 22.04 的过渡包，新脚本不能再带（被删掉的 apt.sh 带过它）。
# 只看包清单，不看注释——注释里正当地提到了这个名字。
PKG_LISTS="$(sed -n '/^CORE_PKGS=(/,/^)/p;/^OPTIONAL_PKGS=(/,/^)/p' ubuntu.sh | sed 's/#.*//')"
assert_not_contains "包清单里没有已废弃的 libncurses5-dev" "$PKG_LISTS" "libncurses5-dev"
assert_contains "包清单里用的是 libncurses-dev" "$PKG_LISTS" "libncurses-dev"

# openssh-server 是 apt.sh 被删掉时唯一没接过来的包，是刻意补回来的：
# 从别处 SSH 进这台机器要用，TRAMP-RPC 也要求远端能 SSH 访问。
assert_contains "包清单里有 openssh-server（承接 apt.sh）" "$PKG_LISTS" "openssh-server"

# `"…$var中文"` 是这一族脚本的真实坑：UTF-8 locale 下 bash 把紧跟变量的多字节字符
# 也算进变量名，于是 `$DEST，` 会去找名叫 `DEST，` 的变量，在 set -u 下直接崩。
if command -v perl >/dev/null 2>&1; then
  NONASCII_VAR_HITS=$(perl -ne 'print "$ARGV:$.\n" if /\$[A-Za-z_][A-Za-z0-9_]*[^\x00-\x7F]/' \
    bootstrap.sh ubuntu.sh deploy.sh .alias .envv .bashrc .zshrc .zprofile 2>/dev/null)
  if [ -z "$NONASCII_VAR_HITS" ]; then
    ok "变量引用后面没有紧跟多字节字符（需写 \${var}）"
  else
    bad "变量引用后面没有紧跟多字节字符（需写 \${var}）" "$NONASCII_VAR_HITS"
  fi
else
  printf '  \033[33m-\033[0m 跳过多字节变量名检查（本机没有 perl）\n'
fi

# ---------------------------------------------------------------------------
group ".alias 平台行为"

alias_of() { # <平台> <alias 名> -> 展开结果，未定义则返回非 0
  local os="$1" name="$2"
  DOTFILES_OS="$os" bash -c "source '$REPO/.alias' >/dev/null 2>&1; alias '$name'" 2>/dev/null
}

if alias_of linux ip >/dev/null 2>&1; then
  bad "Linux 下不得定义 ip（会遮蔽系统命令）" "alias ip = $(alias_of linux ip)"
else
  ok "Linux 下 ip 未被遮蔽，系统 ip 命令可用"
fi
assert_ok "mac 下 ip 指向公网 IP 查询" bash -c \
  "DOTFILES_OS=mac bash -c \"source '$REPO/.alias'; alias ip\" | grep -q myip.opendns.com"

assert_contains "Linux 下 open → xdg-open" "$(alias_of linux open)" "xdg-open"
if alias_of mac open >/dev/null 2>&1; then
  bad "macOS 下不该重定义 open" "alias open = $(alias_of mac open)"
else
  ok "macOS 下 open 保持系统原样"
fi

assert_contains "两个平台都有 myip" "$(alias_of linux myip)$(alias_of mac myip)" "myip.opendns.com"

# flush / flushdns / localip / myip 两个平台都有各自的实现，不在此列
MAC_ONLY_ALIASES=(macinfo afk darkmode wifi-on wifi-off show-hidden hide-hidden open-wifi ifactive)
for a in "${MAC_ONLY_ALIASES[@]}"; do
  assert_fail "Linux 下不定义 macOS 独占 alias：$a" bash -c \
    "DOTFILES_OS=linux bash -c \"source '$REPO/.alias'; alias '$a'\""
  assert_ok "mac 下定义：$a" bash -c \
    "DOTFILES_OS=mac bash -c \"source '$REPO/.alias'; alias '$a'\""
done

assert_contains "Linux 下有 localip 的内核对等物" "$(alias_of linux localip)" "hostname -I"
assert_contains "Linux 下 flushdns 走 systemd-resolved" "$(alias_of linux flushdns)" "resolvectl"
assert_contains "Linux 下 flush 走 systemd-resolved" "$(alias_of linux flush)" "resolvectl"
assert_contains "mac 下 flush 走 dscacheutil" "$(alias_of mac flush)" "dscacheutil"

# 跨平台别名在两个平台都必须在
for a in myip c cxl cxy vpn; do
  assert_ok "两个平台都有 alias $a" bash -c \
    "DOTFILES_OS=linux bash -c \"source '$REPO/.alias'; alias '$a'\" && DOTFILES_OS=mac bash -c \"source '$REPO/.alias'; alias '$a'\""
done

# ---------------------------------------------------------------------------
group ".envv 环境行为"

# 干净 PATH：只留系统目录，确保找不到 emacsclient。
# ${extra:+$extra:} 的冒号不能省，否则前缀会和 /usr/bin 粘成一个不存在的路径。
envv_value() { # <变量名> [额外 PATH 前缀]
  local var="$1" extra="${2:-}"
  env -i PATH="${extra:+$extra:}/usr/bin:/bin" HOME="$HOME" bash -c \
    "source '$REPO/.envv' >/dev/null 2>&1; printf '%s' \"\${$var:-}\""
}

EDITOR_FALLBACK="$(envv_value EDITOR)"
assert_not_contains "没装 emacsclient 时 EDITOR 不指向 emacsclient" "${EDITOR_FALLBACK}" "emacsclient"
assert_ok "EDITOR 回退到 vim 或 vi" bash -c \
  "case '${EDITOR_FALLBACK}' in vim|vi) exit 0;; *) exit 1;; esac"

# 造一个假的 emacsclient，EDITOR 应该切过去
FAKE_BIN="$(mktemp -d)"
printf '#!/bin/sh\nexit 0\n' > "$FAKE_BIN/emacsclient"
chmod +x "$FAKE_BIN/emacsclient"
EDITOR_WITH="$(envv_value EDITOR "$FAKE_BIN")"
assert_contains "有 emacsclient 时 EDITOR 用它" "${EDITOR_WITH}" "emacsclient -t"
rm -rf "$FAKE_BIN"

LOCALE_VALUE="$(envv_value LC_ALL)"
assert_ok "LC_ALL 落在一个 UTF-8 locale 上" bash -c \
  "case '${LOCALE_VALUE}' in *UTF-8|*utf8|*UTF8) exit 0;; *) exit 1;; esac"

assert_contains ".envv 定义了 DOTFILES_OS" "$(envv_value DOTFILES_OS)" "$(uname -s | sed 's/Darwin/mac/;s/Linux/linux/')"

# --- asdf：PATH 闸门与 GOROOT ---
# 沙箱家目录里造出 asdf 的数据目录再 source，验证「挂不挂 shims」的判据。
envv_path_in() { # <家目录> -> 该 HOME 下 source .envv 后的 PATH
  env -i PATH=/usr/bin:/bin HOME="$1" bash -c \
    "source '$REPO/.envv' >/dev/null 2>&1; printf '%s' \"\$PATH\""
}
envv_var_in() { # <家目录> <变量名> -> 值
  env -i PATH=/usr/bin:/bin HOME="$1" bash -c \
    "source '$REPO/.envv' >/dev/null 2>&1; printf '%s' \"\${$2:-}\""
}

ASDF_SANDBOX="$(mktemp -d)"
mkdir -p "$ASDF_SANDBOX/.asdf/shims"

# 回归：闸门曾经是 `command -v asdf`，于是「二进制还没进 PATH」的机器上整段被跳过，
# 所有 asdf 装的工具跟着一起消失。该不该动 PATH，只取决于 shims 目录在不在。
assert_contains "shims 目录在就挂进 PATH（不在乎 asdf 命令此刻在不在 PATH 上）" \
  "$(envv_path_in "$ASDF_SANDBOX")" "$ASDF_SANDBOX/.asdf/shims"
assert_contains "ASDF_DATA_DIR 默认导出成 \$HOME/.asdf" \
  "$(envv_var_in "$ASDF_SANDBOX" ASDF_DATA_DIR)" "$ASDF_SANDBOX/.asdf"

# 指到别处时整个块都得跟着走，不能一半认变量一半认写死的 ~/.asdf
mkdir -p "$ASDF_SANDBOX/custom/shims"
CUSTOM_PATH="$(env -i PATH=/usr/bin:/bin HOME="$ASDF_SANDBOX" ASDF_DATA_DIR="$ASDF_SANDBOX/custom" \
  bash -c "source '$REPO/.envv' >/dev/null 2>&1; printf '%s' \"\$PATH\"")"
assert_contains "ASDF_DATA_DIR 指到别处时挂的是那儿" "$CUSTOM_PATH" "$ASDF_SANDBOX/custom/shims"
assert_not_contains "…且不会再去挂默认的 ~/.asdf/shims" "$CUSTOM_PATH" "$ASDF_SANDBOX/.asdf/shims"

# 没装 asdf（shims 目录不存在）时不许往 PATH 里塞不存在的路径
assert_not_contains "shims 目录不存在时不塞进 PATH" \
  "$(envv_path_in "$(mktemp -d)")" ".asdf/shims"

# 回归：GOROOT 曾经写成 GOROOT="$(asdf where golang)"，asdf 里没有 golang 插件时
# 就把外部导出的 GOROOT 抹成空串，Go 接着报 "cannot find GOROOT"。
GO_SANDBOX="$(mktemp -d)"
mkdir -p "$GO_SANDBOX/bin"
printf '#!/bin/sh\nexit 0\n' > "$GO_SANDBOX/bin/go"
printf '#!/bin/sh\nexit 1\n' > "$GO_SANDBOX/bin/asdf"       # `where golang` 什么都不输出
chmod +x "$GO_SANDBOX/bin/go" "$GO_SANDBOX/bin/asdf"
GOROOT_HOME_OUT="$(env -i PATH="$GO_SANDBOX/bin:/usr/bin:/bin" HOME="$GO_SANDBOX" GOROOT=/opt/keep-go \
  bash -c "source '$REPO/.envv' >/dev/null 2>&1; printf '%s' \"\${GOROOT:-}\"")"
assert_contains "asdf 里没有 golang 时不把已有的 GOROOT 抹掉" "$GOROOT_HOME_OUT" "/opt/keep-go"

# asdf 装了 golang 时反过来要指到它那儿
printf '#!/bin/sh\n[ "$1" = where ] && { printf "%%s\\n" /opt/asdf-go; exit 0; }\nexit 1\n' > "$GO_SANDBOX/bin/asdf"
chmod +x "$GO_SANDBOX/bin/asdf"
GOROOT_ASDF_OUT="$(env -i PATH="$GO_SANDBOX/bin:/usr/bin:/bin" HOME="$GO_SANDBOX" \
  bash -c "source '$REPO/.envv' >/dev/null 2>&1; printf '%s' \"\${GOROOT:-}\"")"
assert_contains "asdf 装了 golang 时 GOROOT 指到它那儿" "$GOROOT_ASDF_OUT" "/opt/asdf-go"
rm -rf "$ASDF_SANDBOX" "$GO_SANDBOX"

# conda init 会把 conda 的 bin 插到最前面，.zshrc 末尾那句要把 shims 顶回去；
# 它得跟着 ASDF_DATA_DIR 走，不能写死 ~/.asdf。
assert_contains ".zshrc 重新挂 shims 时跟着 ASDF_DATA_DIR" \
  "$(cat .zshrc)" '${ASDF_DATA_DIR:-$HOME/.asdf}'
assert_not_contains ".zshrc 不写死 ~/.asdf/shims" "$(cat .zshrc)" '"$HOME/.asdf/shims:$PATH"'

# ---------------------------------------------------------------------------
group ".zprofile 平台行为"

if command -v zsh >/dev/null 2>&1; then
  ZP_ERR="$(env -i PATH=/usr/bin:/bin HOME="$HOME" zsh -c "source '$REPO/.zprofile'" 2>&1 >/dev/null)"
  if [ -z "$ZP_ERR" ]; then
    ok "source .zprofile 不产生任何 stderr 输出"
  else
    bad "source .zprofile 不产生任何 stderr 输出" "$ZP_ERR"
  fi

  # brew 的路径必须来自探测循环里的变量，不能写死在 eval 里
  assert_not_contains "brew shellenv 不 eval 写死路径" \
    "$(cat .zprofile)" 'eval "$(/opt/homebrew/bin/brew shellenv)"'
  assert_contains "brew 通过探测循环定位" "$(cat .zprofile)" 'for _brew in'
else
  printf '  \033[33m-\033[0m 跳过 .zprofile 行为检查（本机没有 zsh）\n'
fi

# ---------------------------------------------------------------------------
group "deploy.sh 行为"

SANDBOX="$(mktemp -d)"
cleanup() { rm -rf "$SANDBOX"; }
trap cleanup EXIT

DEPLOY_TARGETS=(.alias .bash_profile .bashrc .envv .gitconfig .gitignore .vimrc .zprofile .zshrc .config/starship.toml)

# dry-run 必须在空的 HOME 里一个文件都不留
DRY_HOME="$SANDBOX/dry"
mkdir -p "$DRY_HOME"
HOME="$DRY_HOME" ./deploy.sh --dry-run >/dev/null 2>&1
LEFT="$(find "$DRY_HOME" -mindepth 1 | wc -l | tr -d ' ')"
if [ "$LEFT" = "0" ]; then
  ok "dry-run 不落地任何文件"
else
  bad "dry-run 不落地任何文件" "$LEFT 个残留"
fi

# 复制部署
CP_HOME="$SANDBOX/copy"
mkdir -p "$CP_HOME"
HOME="$CP_HOME" ./deploy.sh >/dev/null 2>&1
MISSING=""
for t in "${DEPLOY_TARGETS[@]}"; do
  [ -f "$CP_HOME/$t" ] || MISSING="$MISSING$t "
done
if [ -z "$MISSING" ]; then
  ok "复制部署落地全部 ${#DEPLOY_TARGETS[@]} 个文件"
else
  bad "复制部署落地全部 ${#DEPLOY_TARGETS[@]} 个文件" "缺失：$MISSING"
fi
assert_ok "复制的内容与仓库一致（starship.toml）" \
  cmp -s starship.toml "$CP_HOME/.config/starship.toml"

# 幂等：再跑一次不该产生新的备份目录
HOME="$CP_HOME" ./deploy.sh >/dev/null 2>&1
BACKUPS="$(find "$CP_HOME/.dotfiles-backup" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')"
if [ "$BACKUPS" = "0" ]; then
  ok "重复部署不产生备份（内容相同则跳过）"
else
  bad "重复部署不产生备份（内容相同则跳过）" "出现了 $BACKUPS 个备份目录"
fi

# 备份：内容不同的既有文件必须先存下来
BK_HOME="$SANDBOX/backup"
mkdir -p "$BK_HOME"
printf 'OLD CONTENT\n' > "$BK_HOME/.alias"
HOME="$BK_HOME" ./deploy.sh >/dev/null 2>&1
BK_FILE="$(find "$BK_HOME/.dotfiles-backup" -name '.alias' 2>/dev/null | head -1)"
if [ -n "$BK_FILE" ] && grep -q 'OLD CONTENT' "$BK_FILE"; then
  ok "覆盖前备份原有文件"
else
  bad "覆盖前备份原有文件" "没找到备份，或备份内容不对"
fi
assert_ok "部署后 .alias 已替换为仓库版本" cmp -s .alias "$BK_HOME/.alias"

# 符号链接部署
LK_HOME="$SANDBOX/link"
mkdir -p "$LK_HOME"
HOME="$LK_HOME" ./deploy.sh --link >/dev/null 2>&1
assert_ok ".alias 是符号链接" test -L "$LK_HOME/.alias"
assert_ok ".alias 指向仓库" test "$(readlink "$LK_HOME/.alias")" = "$REPO/.alias"

# 清单里的每一项都必须真的存在，防止改文件名时漏改
BAD_ENTRIES=""
while read -r rel; do
  [ -z "$rel" ] && continue
  [ -e "$REPO/$rel" ] || BAD_ENTRIES="$BAD_ENTRIES$rel "
done < <(sed -n '/^FILES=(/,/^)/p' deploy.sh | grep -oE '"[^"]+"' | tr -d '"' | cut -d: -f1)
if [ -z "$BAD_ENTRIES" ]; then
  ok "deploy.sh 的 FILES 清单全部指向仓库内真实文件"
else
  bad "deploy.sh 的 FILES 清单全部指向仓库内真实文件" "不存在：$BAD_ENTRIES"
fi

# ---------------------------------------------------------------------------
group "ubuntu.sh 装 starship"

# jammy 源里没有 starship，塞进 apt 清单只会被可用性探测跳过，还让人以为装上了。
# 它走官方安装脚本这条路（上游只发 tar.gz，没有 .deb / .rpm）。
assert_not_contains "apt 清单里没有 starship（源里没有这个包）" "$PKG_LISTS" "starship"
assert_contains "starship 走官方安装脚本" "$(cat ubuntu.sh)" "starship.rs/install.sh"

# 安装逻辑单独抽成了函数，这里从 ubuntu.sh 里原样抠出来在进程内跑：ubuntu.sh 开头
# 有 uname 闸门，在 macOS 上跑两行就 die，整段逻辑端到端根本测不到。
STARSHIP_SRC="$(sed -n '/^install_starship()/,/^}/p' ubuntu.sh)"
if [ -z "$STARSHIP_SRC" ]; then
  bad "能从 ubuntu.sh 里取到 install_starship" "没匹配到函数定义，它被改名或改写了？"
else
  ok "能从 ubuntu.sh 里取到 install_starship"

  # 桩：curl 不联网，只把「安装脚本」写到 -o 指定的路径；那个脚本按 FAKE_INSTALLER_EXIT
  # 决定成败，成功时往 STUB_BIN 里放一个 starship（模拟装到 /usr/local/bin）。
  # FAKE_CURL_EXIT 非 0 则连下载都失败，覆盖「拉不到 GitHub」那条路。
  SHIPBIN="$SANDBOX/shipbin"
  SHIPLOG="$SANDBOX/ship-curl.log"
  mkdir -p "$SHIPBIN"
  cat > "$SHIPBIN/curl" <<'STUB'
#!/bin/sh
echo "CURL $*" >> "$STUB_LOG"
[ "${FAKE_CURL_EXIT:-0}" = "0" ] || exit 22
out=""
prev=""
for a in "$@"; do
  [ "$prev" = "-o" ] && out="$a"
  prev="$a"
done
[ -n "$out" ] || exit 2
cat > "$out" <<'INSTALLER'
#!/bin/sh
[ "${FAKE_INSTALLER_EXIT:-0}" = "0" ] || exit 1
printf '#!/bin/sh\necho "starship 1.26.0"\n' > "$STUB_BIN/starship"
chmod +x "$STUB_BIN/starship"
INSTALLER
exit 0
STUB
  chmod +x "$SHIPBIN/curl"

  # 把 PATH 收窄到「桩 + 系统目录」：本机若是 brew 装过 starship，不能被它蒙混过关。
  # URL 指向不可路由的地址，桩万一失效也联不上网。第 4 个参数是「装到哪儿」，
  # 用来演「脚本成功但没落在 PATH 里」。
  SHIP_OUT="$SANDBOX/ship-out"
  ship_run() { # <DRY_RUN> <FAKE_INSTALLER_EXIT> [FAKE_CURL_EXIT] [BIN_DIR] -> 退出码
    env -i PATH="$SHIPBIN:/usr/bin:/bin" HOME="$SANDBOX" \
      STUB_LOG="$SHIPLOG" STUB_BIN="${4:-$SHIPBIN}" SUDO="" \
      STARSHIP_INSTALL_URL="http://127.0.0.1:1/install.sh" \
      DRY_RUN="$1" FAKE_INSTALLER_EXIT="$2" FAKE_CURL_EXIT="${3:-0}" \
      /bin/bash -c 'say() { printf "==> %s\n" "$1"; }; warn() { printf "警告：%s\n" "$1"; }
'"$STARSHIP_SRC"'
install_starship' >"$SHIP_OUT" 2>&1
  }
  # grep -c 无匹配时自己就打印 0 并返回 1，写成 `|| printf 0` 会印出两个 0
  ship_calls() { local n; n="$(grep -c '^CURL ' "$SHIPLOG" 2>/dev/null)"; printf '%s\n' "${n:-0}"; }
  ship_reset() { rm -f "$SHIPBIN/starship"; : > "$SHIPLOG"; }

  # 已经装过：跳过，且一个字节都不下载
  printf '#!/bin/sh\necho "starship 1.26.0"\n' > "$SHIPBIN/starship"
  chmod +x "$SHIPBIN/starship"
  : > "$SHIPLOG"
  ship_run 0 0; rc=$?
  if [ "$rc" = 0 ] && [ "$(ship_calls)" = "0" ] && grep -q "已装" "$SHIP_OUT"; then
    ok "starship 已装时跳过，且不联网"
  else
    bad "starship 已装时跳过，且不联网" "退出码 $rc，curl 跑了 $(ship_calls) 次：$(head -c 200 "$SHIP_OUT")"
  fi

  # --dry-run：也不许联网
  ship_reset
  ship_run 1 0; rc=$?
  if [ "$rc" = 0 ] && [ "$(ship_calls)" = "0" ] && grep -q "dry-run" "$SHIP_OUT"; then
    ok "starship --dry-run 只打印不联网"
  else
    bad "starship --dry-run 只打印不联网" "退出码 $rc，curl 跑了 $(ship_calls) 次：$(head -c 200 "$SHIP_OUT")"
  fi

  # 正常安装：下载一次、执行一次，starship 落到 PATH 里
  ship_reset
  ship_run 0 0; rc=$?
  if [ "$rc" = 0 ] && [ "$(ship_calls)" = "1" ] && [ -x "$SHIPBIN/starship" ]; then
    ok "starship 没装时下载并安装"
  else
    bad "starship 没装时下载并安装" "退出码 $rc，curl $(ship_calls) 次，starship 存在？$([ -x "$SHIPBIN/starship" ] && echo 是 || echo 否)"
  fi

  # 拉不到（curl 失败）与装不上（脚本非 0）都要返回非 0，交给调用方去 warn
  ship_reset
  ship_run 0 0 22; rc=$?
  if [ "$rc" != 0 ]; then
    ok "下载失败时返回非 0（调用方好去警告）"
  else
    bad "下载失败时返回非 0（调用方好去警告）" "却返回了 0"
  fi

  ship_reset
  ship_run 0 1; rc=$?
  if [ "$rc" != 0 ]; then
    ok "安装脚本失败时返回非 0"
  else
    bad "安装脚本失败时返回非 0" "却返回了 0"
  fi

  # 脚本跑成功了、PATH 里却没有 starship（装去了别处）：一样算没装上
  ship_reset
  mkdir -p "$SANDBOX/elsewhere"
  ship_run 0 0 0 "$SANDBOX/elsewhere"; rc=$?
  if [ "$rc" != 0 ]; then
    ok "脚本成功但 PATH 里没有 starship 时仍算失败"
  else
    bad "脚本成功但 PATH 里没有 starship 时仍算失败" "却返回了 0"
  fi
fi

# ---------------------------------------------------------------------------
group "ubuntu.sh 装 ls 增强（exa / eza）"

# exa / eza 和 starship 不是一类东西：starship 在 apt 里根本没有，才要官方脚本兜底；
# 这两个都在 universe 里，直接进包清单就够（核对过 dists/jammy 与 dists/noble 的
# Packages 索引：jammy 只有 exa 0.10.1，noble 只有 eza 0.18.2）。门禁挡的是把它们
# 挪进核心清单——核心包装不上会 die，而每个发行版必然缺其中一个。
assert_contains "apt 清单里有 exa（jammy 的 universe）" "$PKG_LISTS" "exa"
assert_contains "apt 清单里有 eza（noble 的 universe）" "$PKG_LISTS" "eza"
CORE_LIST="$(sed -n '/^CORE_PKGS=(/,/^)/p' ubuntu.sh | sed 's/#.*//')"
assert_not_contains "exa 留在可选清单里，不在核心清单" "$CORE_LIST" "exa"
assert_not_contains "eza 留在可选清单里，不在核心清单" "$CORE_LIST" "eza"

# 这次改动的起点是一句过期的事实断言：README 和 ubuntu.sh 都写着「jammy 源里没有 exa」，
# 而 22.04 从发布起 universe 里就有它。文档里的断言不会自己变旧了报警，所以让这类
# 说法一旦写下就得有人去核索引——命中即失败，改完再放行。
STALE_EXA="$(grep -lE 'exa 不在|里没有 exa' README.md ubuntu.sh 2>/dev/null | tr '\n' ' ')"
if [ -z "$STALE_EXA" ]; then
  ok "没有残留「jammy 没有 exa」的旧断言"
else
  bad "没有残留「jammy 没有 exa」的旧断言" "命中：$STALE_EXA（先核 dists/jammy/universe 的索引再写）"
fi

# ---- ls 增强：按行为测，不抠源码 ----
#
# 桩 exa / 桩 eza 只回答一个问题：--git 能不能用（STUB_GIT=1 表示能用）。真机上的
# 差异正好就是这个，三种都在容器里实测过：
#   jammy 的 exa（apt 装的）     exa --git -d . -> rc=3   ← 整个命令失败，不是少一列
#   brew 的 exa                  --git -> rc=0
#   noble 的 eza（apt 装的）      eza --git -d . -> rc=0
# 所以别名体只断言字符串，不真的执行——执行要真二进制，断言只要桩。
LSBIN="$SANDBOX/lsbin"
mkdir -p "$LSBIN"

stub_ls_tool() { # <exa|eza>
  cat > "$LSBIN/$1" <<'STUB'
#!/bin/sh
case "$*" in
  *--git*) [ "${STUB_GIT:-0}" = "1" ] || exit 3 ;;
esac
exit 0
STUB
  chmod +x "$LSBIN/$1"
}

ls_aliases_with() { # <STUB_GIT> <放进 PATH 的命令…> —— 空 PATH 起底，只留传进来的桩
  local git="$1"; shift
  rm -f "$LSBIN"/*
  local c; for c in "$@"; do stub_ls_tool "$c"; done
  env -i PATH="$LSBIN" HOME="$HOME" DOTFILES_OS=linux STUB_GIT="$git" "${BASH:-/bin/bash}" -c \
    "source '$REPO/.alias' >/dev/null 2>&1 || printf 'source失败 '; \
     for a in e ea ee et eta l ls la ll lt lta; do alias \"\$a\" 2>/dev/null || printf '未定义 '; done; printf '\n'"
}

# 这条是这次最要紧的回归：apt 装的 exa 用不了 --git，别名里就不能带它。
# 带了不是「不显示 git 状态」，而是 ls / la / ll 一律 rc=3 报错——比没有增强糟得多，
# 因为 exa 确实是 apt 正常装上的，用户会以为只是换了个 ls。
JAMMY_LS="$(ls_aliases_with 0 exa)"
assert_contains     "exa 的 --git 不可用时仍走 exa" "$JAMMY_LS" "exa --icons"
assert_not_contains "exa 的 --git 不可用时别名里不带 --git（带了整个命令 rc=3）" "$JAMMY_LS" "--git"
assert_contains     "exa 的 --git 不可用时 --icons 还在" "$JAMMY_LS" "--icons"

BREW_LS="$(ls_aliases_with 1 exa)"
assert_contains "exa 的 --git 可用时别名里带 --git（brew 那版）" "$BREW_LS" "--icons --git"

EZA_LS="$(ls_aliases_with 1 eza)"
assert_contains "装了 eza 时走 eza" "$EZA_LS" "eza --icons --git"

BOTH_LS="$(ls_aliases_with 1 exa eza)"
assert_contains     "两个都在时优先 eza（24.04 之后只剩它）" "$BOTH_LS" "eza --icons --git"
assert_not_contains "两个都在时不落到 exa" "$BOTH_LS" "exa"

assert_contains "一个都没装时 ls 不被接管，且不定义半个别名" "$(ls_aliases_with 0)" "未定义"

# 别名用的参数必须是 exa 0.10.1 与 eza 0.18.2 都认识的（两个版本的容器里逐个跑过）。
# exa 上游已归档、eza 里这些选项也早已稳定，表不会再长，写死是安全的。
# 它挡的是「只在本机那版上试过就以为行」：比如 exa 的参数里塞一个 eza 才有的选项，
# 或者反过来，只有在对应发行版上才会炸。
LS_LONG_OK="--icons --git --all --header --long --tree --level --ignore-glob --color"
LS_SHORT_OK="-a -h -l -T -L -I"

# ` | ` 之后是别的命令（eta 结尾的 `less -r` 不是这两个工具的选项）。
LS_FLAGS="$(ls_aliases_with 1 eza | sed 's/ | .*//' | tr -d "'\"" \
  | tr ' ' '\n' | grep -E '^-' | sed 's/=.*//' | sort -u)"

# 抠不到参数就别放行：模式失效时下面那个循环会一个都不检查，静默变绿灯。
if [ -z "$LS_FLAGS" ]; then
  bad "能从别名展开里抠出 ls 增强用的参数" "一个都没抠到，别名定义被改写了吗？"
else
  LS_UNKNOWN=""
  for _tok in $LS_FLAGS; do
    case "$_tok" in
      --*)
        case " $LS_LONG_OK " in *" $_tok "*) ;; *) LS_UNKNOWN="$LS_UNKNOWN $_tok" ;; esac ;;
      -*)
        # -aahl 这种捆在一起的短选项要拆开逐个认
        _rest="${_tok#-}"
        while [ -n "$_rest" ]; do
          _c="-${_rest:0:1}"; _rest="${_rest:1}"
          case " $LS_SHORT_OK " in *" $_c "*) ;; *) LS_UNKNOWN="$LS_UNKNOWN $_c" ;; esac
        done ;;
    esac
  done
  if [ -z "$LS_UNKNOWN" ]; then
    ok "ls 增强用的参数 exa 0.10.1 与 eza 0.18.2 都认识"
  else
    bad "ls 增强用的参数 exa 0.10.1 与 eza 0.18.2 都认识" "两边都对不上：$LS_UNKNOWN"
  fi
fi

# ---------------------------------------------------------------------------
group "登录 shell 用 zsh"

# 这一族的共同点：脚本跑在用户机器上、要动系统状态（chsh 还会弹密码），所以两条
# 都得验——「该改的时候改了」和「不该动的时候别动」。抠出真代码、把 chsh / dscl /
# getent 换成桩在进程里跑，比对着源码 grep 强。
SHELLBIN="$SANDBOX/shellbin"
mkdir -p "$SHELLBIN"
FAKE_SHELL_FILE="$SANDBOX/current-shell"
CHSH_LOG="$SANDBOX/chsh.log"

# 假 dscl：只回答登录 shell 是什么
cat > "$SHELLBIN/dscl" <<'STUB'
#!/bin/sh
printf 'UserShell: %s\n' "$(cat "$FAKE_SHELL_FILE")"
STUB

# 假 chsh：记下被怎么调的；CHSH_WORKS=0 表示「退出码 0 但压根没改」——
# 真有机器是这样（PAM / 目录服务会把改动吃掉），那正是要能看出来的情况。
cat > "$SHELLBIN/chsh" <<'STUB'
#!/bin/sh
printf '%s\n' "$*" >> "$CHSH_LOG"
[ "${CHSH_WORKS:-1}" = "1" ] || exit 0
while [ $# -gt 0 ]; do
  if [ "$1" = "-s" ]; then printf '%s' "$2" > "$FAKE_SHELL_FILE"; break; fi
  shift
done
exit 0
STUB

# 假 getent：getent passwd <user> 的第七个字段是登录 shell
cat > "$SHELLBIN/getent" <<'STUB'
#!/bin/sh
printf 'user:x:1000:1000::/home/user:%s\n' "$(cat "$FAKE_SHELL_FILE")"
STUB
chmod +x "$SHELLBIN"/*

# ---- macOS：brew.sh ----
BREW_SHELL_SRC="$(sed -n '/^CURRENT_SHELL="\$(dscl/,/^fi$/p' brew.sh)"
if [ -z "$BREW_SHELL_SRC" ]; then
  bad "能从 brew.sh 里取到切换登录 shell 的那段" "没匹配到，它被改名或挪走了？"
else
  ok "能从 brew.sh 里取到切换登录 shell 的那段"

  brew_shell_run() { # <当前 shell> -> 打印脚本的输出；chsh 的调用记在 CHSH_LOG
    printf '%s' "$1" > "$FAKE_SHELL_FILE"
    : > "$CHSH_LOG"
    env -i PATH="$SHELLBIN:/usr/bin:/bin" HOME="$HOME" \
        FAKE_SHELL_FILE="$FAKE_SHELL_FILE" CHSH_LOG="$CHSH_LOG" \
        "${BASH:-/bin/bash}" -c "cecho() { printf '%s\n' \"\$1\"; }; $BREW_SHELL_SRC" 2>&1
  }

  OUT="$(brew_shell_run /bin/bash)"
  assert_contains ".login shell 是 bash 时会切到 /bin/zsh" "$OUT" "/bin/zsh"
  if [ "$(cat "$FAKE_SHELL_FILE")" = "/bin/zsh" ]; then
    ok "切完之后登录 shell 真的是 /bin/zsh"
  else
    bad "切完之后登录 shell 真的是 /bin/zsh" "实际是 $(cat "$FAKE_SHELL_FILE")"
  fi
  assert_contains "确实调用了 chsh -s /bin/zsh" "$(cat "$CHSH_LOG")" "-s /bin/zsh"

  # 已经是 zsh 就不该再动：chsh 会要密码，可反复执行的脚本每次弹出一下没法用
  OUT="$(brew_shell_run /bin/zsh)"
  assert_contains "已经是 /bin/zsh 时提示跳过" "$OUT" "已经是"
  if [ -s "$CHSH_LOG" ]; then
    bad "已经是 /bin/zsh 时不调用 chsh（每次运行都弹密码没法用）" "却调了：$(cat "$CHSH_LOG")"
  else
    ok "已经是 /bin/zsh 时不调用 chsh（每次运行都弹密码没法用）"
  fi
fi

# ---- Linux：ubuntu.sh 第 6 段 ----
# 段号不写死：同一棵工作区里谁都可能往 ubuntu.sh 插步骤，插一次后面全顺移，写死的
# 号会在别人提交时突然失配。按标题认段——这跟 README 那条「不拿行号指位置」同理。
UBUNTU_SHELL_SRC="$(sed -n '/^# ---- [0-9][0-9]*\. 登录 shell ----/,/^# ---- [0-9][0-9]*\. /p' ubuntu.sh | sed '$d')"
if [ -z "$UBUNTU_SHELL_SRC" ]; then
  bad "能从 ubuntu.sh 里取到「登录 shell」那一段" "没匹配到，段号或标题改了吗？"
elif ! command -v zsh >/dev/null 2>&1; then
  printf '  \033[33m-\033[0m 跳过 ubuntu.sh 的登录 shell 测试（本机没有 zsh）\n'
else
  ok "能从 ubuntu.sh 里取到「登录 shell」那一段"

  ubuntu_shell_run() { # <当前 shell> <CHSH_WORKS> <DO_CHSH> -> 打印输出
    printf '%s' "$1" > "$FAKE_SHELL_FILE"
    : > "$CHSH_LOG"
    env -i PATH="$SHELLBIN:/usr/bin:/bin" HOME="$HOME" \
        FAKE_SHELL_FILE="$FAKE_SHELL_FILE" CHSH_LOG="$CHSH_LOG" \
        CHSH_WORKS="$2" DO_CHSH="$3" DRY_RUN=0 "${BASH:-/bin/bash}" -c \
        "say() { printf 'SAY %s\n' \"\$1\"; }; warn() { printf 'WARN %s\n' \"\$1\"; }; \
         run() { \"\$@\"; }; $UBUNTU_SHELL_SRC" 2>&1
  }

  OUT="$(ubuntu_shell_run /bin/bash 1 1)"
  assert_contains "ubuntu.sh 把登录 shell 切到 zsh" "$OUT" "SAY 已切到"
  assert_contains "切完读回来确认，确认到的是 zsh" "$(cat "$FAKE_SHELL_FILE")" "zsh"

  # chsh 退出码 0 却没改成功：必须报警，不能让用户下次登录才发现 .zshrc 没生效
  OUT="$(ubuntu_shell_run /bin/bash 0 1)"
  assert_contains "chsh 没生效时报出来（退出码 0 也会骗人）" "$OUT" "WARN"
  assert_contains "没生效时给出 sudo chsh 的补救办法" "$OUT" "sudo chsh"

  OUT="$(ubuntu_shell_run /bin/zsh 1 1)"
  assert_contains "已经是 zsh 时提示跳过" "$OUT" "已经是 zsh"
  if [ -s "$CHSH_LOG" ]; then
    bad "已经是 zsh 时不调用 chsh" "却调了：$(cat "$CHSH_LOG")"
  else
    ok "已经是 zsh 时不调用 chsh"
  fi

  OUT="$(ubuntu_shell_run /bin/bash 1 0)"
  assert_not_contains "--no-chsh 时不碰登录 shell" "$OUT" "SAY 已切到"
fi

# ---------------------------------------------------------------------------
group "ubuntu.sh 装 asdf"

# asdf 不在 jammy 源里。上游 0.16 起是 Go 写的单体二进制，仓库里已经没有 bin/，
# 老教程里「git clone 下来就能用」那套不再成立（clone 到的只有源码，要自己编），
# 所以走官方 release 资产，落点跟 rtk 一样是 ~/.local/bin（.envv 会挂进 PATH）。
assert_not_contains "apt 清单里没有 asdf（源里没有这个包）" "$PKG_LISTS" "asdf"
assert_contains "asdf 走官方 release 资产" "$(cat ubuntu.sh)" "asdf-vm/asdf/releases/download"
assert_contains "brew.sh 装 asdf" "$(cat brew.sh)" "brew install asdf"

ASDF_SRC="$(sed -n '/^install_asdf()/,/^}/p' ubuntu.sh)"
ASDF_DEFAULTS="$(grep -E '^ASDF_VERSION=|^ASDF_RELEASE_BASE=' ubuntu.sh)"
# 版本号不在这里另抄一份：从 ubuntu.sh 自己钉的那行取，省得它升级了这边还在验旧值
ASDF_PIN="$(printf '%s\n' "$ASDF_DEFAULTS" | sed -n 's/^ASDF_VERSION="\${ASDF_VERSION:-\([^}"]*\)}"$/\1/p')"
if [ -z "$ASDF_SRC" ] || [ -z "$ASDF_PIN" ]; then
  bad "能从 ubuntu.sh 里取到 install_asdf 与它钉的 ASDF_VERSION" \
    "没匹配到函数定义或版本默认值，被改名或改写了？"
else
  ok "能从 ubuntu.sh 里取到 install_asdf 与它钉的 ASDF_VERSION（$ASDF_PIN）"

  # 装进执行者自己的家目录；套了 sudo 就落到 /root/.local/bin 去了
  assert_not_contains "install_asdf 不套 sudo（装进执行者自己的家目录）" "$ASDF_SRC" "SUDO"

  ASDFTOOLS="$SANDBOX/asdftools"   # PATH 上的桩目录
  ASDFHOME="$SANDBOX/asdfhome"
  ASDFLOG="$SANDBOX/asdf-curl.log"
  ASDF_OUT="$SANDBOX/asdf-out"
  mkdir -p "$ASDFTOOLS" "$ASDFHOME"

  # 假 uname：架构映射是被测逻辑的一部分，得能在 mac 上验 linux 那几种
  cat > "$ASDFTOOLS/uname" <<'STUB'
#!/bin/sh
[ "${1:-}" = "-m" ] || exec /usr/bin/uname "$@"
printf '%s\n' "${FAKE_UNAME_M:-x86_64}"
STUB

  # 假 curl：不联网，真打一个 tar.gz 出来。被测代码要真解它、真跑包里的 asdf，
  # 所以包名、成员名、权限位错一个都会在这里露馅，不是拿字符串比对糊过去。
  # 版本号在打包时展开，于是装出来的 asdf 在任何环境里都报得出自己的版本。
  #
  # 报出版本的那行必须跟真二进制一模一样，含 v 前缀。这行是照 v0.20.0 的 darwin 构建
  # 逐字抄的（`asdf version v0.20.0 (revision 150aaf0)`）；桩子少个 v，被测代码少剥个 v，
  # 两边一起错就谁也发现不了——真机上却会因为版本永远对不上而每次都重装。
  cat > "$ASDFTOOLS/curl" <<'STUB'
#!/bin/sh
echo "CURL $*" >> "$STUB_LOG"
[ "${FAKE_CURL_EXIT:-0}" = "0" ] || exit 22
out=""
prev=""
for a in "$@"; do
  [ "$prev" = "-o" ] && out="$a"
  prev="$a"
done
[ -n "$out" ] || exit 2
stage="$(mktemp -d)"
cat > "$stage/asdf" <<INNER
#!/bin/sh
echo "asdf version v${FAKE_ASDF_VERSION} (revision unknown)"
INNER
chmod +x "$stage/asdf"
tar -czf "$out" -C "$stage" asdf
rm -rf "$stage"
exit 0
STUB
  chmod +x "$ASDFTOOLS/uname" "$ASDFTOOLS/curl"

  asdf_run() { # <DRY_RUN> <FAKE_UNAME_M> [FAKE_CURL_EXIT] [FAKE_ASDF_VERSION] -> 退出码
    # 不传 ASDF_BIN，让函数落到默认的 $HOME/.local/bin：默认路径本身也是被测对象
    env -i PATH="$ASDFTOOLS:/usr/bin:/bin" HOME="$ASDFHOME" \
      STUB_LOG="$ASDFLOG" \
      ASDF_RELEASE_BASE="http://127.0.0.1:1/dl" \
      DRY_RUN="$1" FAKE_UNAME_M="$2" FAKE_CURL_EXIT="${3:-0}" \
      FAKE_ASDF_VERSION="${4:-$ASDF_PIN}" \
      /bin/bash -c 'say() { printf "==> %s\n" "$1"; }; warn() { printf "警告：%s\n" "$1"; }
'"$ASDF_DEFAULTS"'
'"$ASDF_SRC"'
install_asdf' >"$ASDF_OUT" 2>&1
  }
  # grep -c 无匹配时自己就打印 0 并返回 1，写成 `|| printf 0` 会印出两个 0
  asdf_calls() { local n; n="$(grep -c '^CURL ' "$ASDFLOG" 2>/dev/null)"; printf '%s\n' "${n:-0}"; }
  asdf_reset() { rm -rf "$ASDFHOME/.local" "$ASDFTOOLS/asdf"; : > "$ASDFLOG"; }
  asdf_fake() { # <放哪儿> <版本号>：造一个会报版本号的假 asdf（v 前缀照真二进制）
    printf '#!/bin/sh\necho "asdf version v%s (revision unknown)"\n' "$2" > "${1:-$ASDFTOOLS}/asdf"
    chmod +x "${1:-$ASDFTOOLS}/asdf"
  }

  # 没装：下载一次、装到默认的 ~/.local/bin，并且真的能跑起来
  asdf_reset
  asdf_run 0 x86_64; rc=$?
  if [ "$rc" = 0 ] && [ "$(asdf_calls)" = "1" ] && [ -x "$ASDFHOME/.local/bin/asdf" ] &&
     "$ASDFHOME/.local/bin/asdf" --version | grep -q "asdf version v$ASDF_PIN "; then
    ok "asdf 没装时下载并安装到默认的 ~/.local/bin"
  else
    bad "asdf 没装时下载并安装到默认的 ~/.local/bin" \
      "退出码 $rc，curl $(asdf_calls) 次，落点存在？$([ -x "$ASDFHOME/.local/bin/asdf" ] && echo 是 || echo 否)：$(head -c 200 "$ASDF_OUT")"
  fi

  # 幂等：落点上已经有对版本的 asdf（新机器上它还没进 PATH），跳过且一个字节都不下
  asdf_reset
  mkdir -p "$ASDFHOME/.local/bin"
  asdf_fake "$ASDFHOME/.local/bin" "$ASDF_PIN"
  asdf_run 0 x86_64; rc=$?
  if [ "$rc" = 0 ] && [ "$(asdf_calls)" = "0" ] && grep -q "已装" "$ASDF_OUT"; then
    ok "落点上已有同版本的 asdf 时跳过，且不联网"
  else
    bad "落点上已有同版本的 asdf 时跳过，且不联网" \
      "退出码 $rc，curl 跑了 $(asdf_calls) 次：$(head -c 200 "$ASDF_OUT")"
  fi

  # 版本得整段比，不能是子串：$ASDF_PIN-rc1 里含有 $ASDF_PIN，
  # 用 `case $have in *$ASDF_VERSION*)` 那种子串判定会把预发布版当成目标版，升级永不发生。
  asdf_reset
  mkdir -p "$ASDFHOME/.local/bin"
  asdf_fake "$ASDFHOME/.local/bin" "${ASDF_PIN}-rc1"
  asdf_run 0 x86_64; rc=$?
  if [ "$rc" = 0 ] && [ "$(asdf_calls)" = "1" ] &&
     "$ASDFHOME/.local/bin/asdf" --version | grep -q "asdf version v$ASDF_PIN "; then
    ok "只差个后缀（${ASDF_PIN}-rc1）也算没装对，照样换成 $ASDF_PIN"
  else
    bad "只差个后缀也算没装对，照样换成 $ASDF_PIN" \
      "退出码 $rc，curl $(asdf_calls) 次：$(head -c 200 "$ASDF_OUT")"
  fi

  # 装在别处（brew、发行版包、或用户自己 clone 的）：不动它，免得两份 asdf 互相遮蔽
  asdf_reset
  asdf_fake "$ASDFTOOLS" "$ASDF_PIN"
  asdf_run 0 x86_64; rc=$?
  if [ "$rc" = 0 ] && [ "$(asdf_calls)" = "0" ] && [ ! -e "$ASDFHOME/.local/bin/asdf" ]; then
    ok "asdf 已在 PATH 上时跳过，且不往 ~/.local/bin 里塞第二份"
  else
    bad "asdf 已在 PATH 上时跳过，且不往 ~/.local/bin 里塞第二份" \
      "退出码 $rc，curl $(asdf_calls) 次：$(head -c 200 "$ASDF_OUT")"
  fi

  # --dry-run：也不许联网
  asdf_reset
  asdf_run 1 x86_64; rc=$?
  if [ "$rc" = 0 ] && [ "$(asdf_calls)" = "0" ] && grep -q "dry-run" "$ASDF_OUT"; then
    ok "asdf --dry-run 只打印不联网"
  else
    bad "asdf --dry-run 只打印不联网" \
      "退出码 $rc，curl 跑了 $(asdf_calls) 次：$(head -c 200 "$ASDF_OUT")"
  fi

  # 资产名里的架构：拼错了这里就红。三种都用 uname -m 的真实取值试。
  asdf_reset
  asdf_run 0 x86_64 >/dev/null
  assert_contains "x86_64 取 linux-amd64 的包" "$(cat "$ASDFLOG")" "asdf-v${ASDF_PIN}-linux-amd64.tar.gz"
  asdf_reset
  asdf_run 0 aarch64 >/dev/null
  assert_contains "aarch64 取 linux-arm64 的包" "$(cat "$ASDFLOG")" "asdf-v${ASDF_PIN}-linux-arm64.tar.gz"
  asdf_reset
  asdf_run 0 i686 >/dev/null
  assert_contains "i686 取 linux-386 的包" "$(cat "$ASDFLOG")" "asdf-v${ASDF_PIN}-linux-386.tar.gz"

  # 上游没有的架构：说清楚是哪个架构，不联网，也不留半成品
  asdf_reset
  asdf_run 0 riscv64; rc=$?
  if [ "$rc" != 0 ] && [ "$(asdf_calls)" = "0" ] && grep -q "riscv64" "$ASDF_OUT"; then
    ok "上游没有的架构（riscv64）直接跳过，且不联网"
  else
    bad "上游没有的架构（riscv64）直接跳过，且不联网" \
      "退出码 $rc，curl $(asdf_calls) 次：$(head -c 200 "$ASDF_OUT")"
  fi

  # 拉不到：非 0 交给调用方 warn，且不许在落点上留半成品
  asdf_reset
  asdf_run 0 x86_64 22; rc=$?
  if [ "$rc" != 0 ] && [ ! -e "$ASDFHOME/.local/bin/asdf" ]; then
    ok "下载失败时返回非 0，且不留下 asdf"
  else
    bad "下载失败时返回非 0，且不留下 asdf" \
      "退出码 $rc，落点存在？$([ -e "$ASDFHOME/.local/bin/asdf" ] && echo 是 || echo 否)"
  fi

  # 包能解开、但里面的 asdf 版本不对：一样不能落地。原地那份旧版还得原封不动——
  # 先解到临时目录、验过再 cp 的意义就在这里：宁可保持旧的，也不留个跑不起来的。
  asdf_reset
  mkdir -p "$ASDFHOME/.local/bin"
  asdf_fake "$ASDFHOME/.local/bin" "0.19.0"
  asdf_run 0 x86_64 0 "0.19.0"; rc=$?
  if [ "$rc" != 0 ] && "$ASDFHOME/.local/bin/asdf" --version | grep -q "asdf version v0.19.0 "; then
    ok "下回来的包版本不对就不装，原地那份旧的照旧"
  else
    bad "下回来的包版本不对就不装，原地那份旧的照旧" \
      "退出码 $rc，现在报的是：$("$ASDFHOME/.local/bin/asdf" --version 2>&1 | head -n 1)"
  fi
fi
# ---------------------------------------------------------------------------
group "vim.sh 行为"

# vim.sh 往 $HERE/.vim 里写东西（插件就装在那儿）。直接对真仓库跑会污染工作区，
# 所以把脚本和 .vimrc 复制成一个临时「仓库」——HERE 由 BASH_SOURCE 推出，自然落在那儿。
VIMREPO="$SANDBOX/vimrepo"
mkdir -p "$VIMREPO"
cp vim.sh .vimrc "$VIMREPO/"

# curl 和 vim 都不许真跑：curl 会联网，vim 会抢终端。
VIMBIN="$SANDBOX/vimbin"
mkdir -p "$VIMBIN"
cat > "$VIMBIN/curl" <<'STUB'
#!/bin/sh
echo "CURL $*" >> "$STUB_LOG"
prev=""
for a in "$@"; do
  [ "$prev" = "-o" ] && printf 'FAKE VIM-PLUG\n' > "$a"
  prev="$a"
done
exit 0
STUB
cat > "$VIMBIN/vim" <<'STUB'
#!/bin/sh
echo "VIM $*" >> "$STUB_LOG"
exit 0
STUB
chmod +x "$VIMBIN/curl" "$VIMBIN/vim"

STUB_LOG="$SANDBOX/vim-stub.log"
: > "$STUB_LOG"

# run_vim_sh <家目录> [参数...]  ->  vim.sh 的退出码
run_vim_sh() {
  local home="$1"; shift
  mkdir -p "$home"
  STUB_LOG="$STUB_LOG" VIM=vim PATH="$VIMBIN:$PATH" HOME="$home" \
    bash "$VIMREPO/vim.sh" "$@" >"$SANDBOX/vim-out" 2>&1
}
stub_calls() { grep -c "^$1 " "$STUB_LOG" 2>/dev/null || true; }

# 一个需要 root 的动作都没有，就不该弹密码。针是整词，因为下面还要提这件事。
assert_not_contains "vim.sh 不索要提权（它用不到）" "$(cat vim.sh)" "sudo"

# --dry-run：一个字不落地，也不联网、不跑 vim
DRY_HOME="$SANDBOX/vim-dry"
rm -rf "$DRY_HOME" "$VIMREPO/.vim"; : > "$STUB_LOG"
mkdir -p "$DRY_HOME"
run_vim_sh "$DRY_HOME" --dry-run
if [ "$(find "$DRY_HOME" -mindepth 1 2>/dev/null | wc -l | tr -d ' ')" = "0" ] && [ ! -e "$VIMREPO/.vim" ]; then
  ok "vim.sh --dry-run 不落地任何文件"
else
  bad "vim.sh --dry-run 不落地任何文件" \
    "残留：$(find "$DRY_HOME" "$VIMREPO/.vim" -mindepth 1 2>/dev/null | tr '\n' ' ')"
fi
if [ "$(stub_calls CURL)" = "0" ] && [ "$(stub_calls VIM)" = "0" ]; then
  ok "vim.sh --dry-run 不联网也不跑 vim"
else
  bad "vim.sh --dry-run 不联网也不跑 vim" "curl $(stub_calls CURL) 次，vim $(stub_calls VIM) 次"
fi

# 首次运行
FIRST_HOME="$SANDBOX/vim-first"
rm -rf "$FIRST_HOME" "$VIMREPO/.vim"; : > "$STUB_LOG"
run_vim_sh "$FIRST_HOME"
FIRST_RC=$?
if [ "$FIRST_RC" -eq 0 ] && [ -L "$FIRST_HOME/.vimrc" ] &&
   [ "$(readlink "$FIRST_HOME/.vimrc")" = "$VIMREPO/.vimrc" ]; then
  ok ".vimrc 链接到仓库"
else
  bad ".vimrc 链接到仓库" "退出码 $FIRST_RC，readlink=$(readlink "$FIRST_HOME/.vimrc" 2>/dev/null)"
fi
if [ -L "$FIRST_HOME/.vim" ] && [ "$(readlink "$FIRST_HOME/.vim")" = "$VIMREPO/.vim" ]; then
  ok ".vim 链接到仓库"
else
  bad ".vim 链接到仓库" "readlink=$(readlink "$FIRST_HOME/.vim" 2>/dev/null)"
fi
if [ -f "$VIMREPO/.vim/autoload/plug.vim" ] && [ ! -L "$VIMREPO/.vim/autoload/plug.vim" ]; then
  ok "plug.vim 落成真文件（不是符号链接）"
else
  bad "plug.vim 落成真文件（不是符号链接）" "$(ls -la "$VIMREPO/.vim/autoload/" 2>&1)"
fi
assert_ok "首次运行会调用 PlugInstall" test "$(stub_calls VIM)" = "1"

# 回归：连跑两次，plug.vim 必须还是那个真文件。
# 旧版正是在这里翻车——~/.vim/autoload/plug.vim 和仓库 .vim/autoload/plug.vim
# 因为 ~/.vim 是指向仓库的符号链接而是同一个文件，对这两条路径做 ln 就等于让文件
# 指向自己，第二次运行后 vim 报 E117: Unknown function: plug#begin。
: > "$STUB_LOG"
run_vim_sh "$FIRST_HOME"
if [ -f "$VIMREPO/.vim/autoload/plug.vim" ] && [ ! -L "$VIMREPO/.vim/autoload/plug.vim" ]; then
  ok "第二次运行后 plug.vim 仍是真文件（没变成自指环）"
else
  bad "第二次运行后 plug.vim 仍是真文件（没变成自指环）" "$(ls -la "$VIMREPO/.vim/autoload/" 2>&1)"
fi
assert_ok "plug.vim 已就位时不重新下载" test "$(stub_calls CURL)" = "0"
assert_ok "重复运行不备份自己建的符号链接" \
  test "$(find "$FIRST_HOME" -maxdepth 1 -name '.vim*20*' | wc -l | tr -d ' ')" = "0"

# 被旧版坑过、已经留下自指环的机器，跑一次就该好
rm -f "$VIMREPO/.vim/autoload/plug.vim"
ln -s "$VIMREPO/.vim/autoload/plug.vim" "$VIMREPO/.vim/autoload/plug.vim"
: > "$STUB_LOG"
run_vim_sh "$FIRST_HOME"
if [ -f "$VIMREPO/.vim/autoload/plug.vim" ] && [ ! -L "$VIMREPO/.vim/autoload/plug.vim" ] &&
   [ "$(stub_calls CURL)" = "1" ]; then
  ok "自指的 plug.vim 会被清掉并重新下载"
else
  bad "自指的 plug.vim 会被清掉并重新下载" "$(ls -la "$VIMREPO/.vim/autoload/" 2>&1)"
fi

: > "$STUB_LOG"
run_vim_sh "$FIRST_HOME" --update-plug
assert_ok "--update-plug 强制重新下载" test "$(stub_calls CURL)" = "1"

# 既有真实目录必须先备份再覆盖，否则用户配置就这么没了
BK_HOME="$SANDBOX/vim-bk"
rm -rf "$BK_HOME"
mkdir -p "$BK_HOME/.vim"
printf 'OLD\n' > "$BK_HOME/.vim/marker"
run_vim_sh "$BK_HOME" --no-plugins
BK_DIR="$(find "$BK_HOME" -maxdepth 1 -name '.vim.20*' | head -1)"
if [ -n "$BK_DIR" ] && [ -f "$BK_DIR/marker" ] && [ -L "$BK_HOME/.vim" ]; then
  ok "既有 .vim 目录先备份再链接"
else
  bad "既有 .vim 目录先备份再链接" "备份目录：${BK_DIR:-无}"
fi

# 目标已经是指向别处的符号链接时，ln 不加 -n 会顺着它建到目录里面去
NEST_HOME="$SANDBOX/vim-nest"
rm -rf "$NEST_HOME"
mkdir -p "$NEST_HOME/elsewhere"
ln -s "$NEST_HOME/elsewhere" "$NEST_HOME/.vim"
run_vim_sh "$NEST_HOME" --no-plugins
NESTED="$(ls -A "$NEST_HOME/elsewhere" 2>/dev/null | wc -l | tr -d ' ')"
if [ "$NESTED" = "0" ] && [ "$(readlink "$NEST_HOME/.vim")" = "$VIMREPO/.vim" ]; then
  ok "替换旧符号链接不产生套娃"
else
  bad "替换旧符号链接不产生套娃" "elsewhere 里多了 $NESTED 项"
fi

# deploy.sh 复制过来的 .vimrc 内容与仓库一致，不值得为它堆一个备份
SAME_HOME="$SANDBOX/vim-same"
rm -rf "$SAME_HOME"
mkdir -p "$SAME_HOME"
cp .vimrc "$SAME_HOME/.vimrc"
run_vim_sh "$SAME_HOME" --no-plugins
if [ -L "$SAME_HOME/.vimrc" ] &&
   [ "$(find "$SAME_HOME" -maxdepth 1 -name '.vimrc.20*' | wc -l | tr -d ' ')" = "0" ]; then
  ok "内容相同的 .vimrc 不备份，直接换成符号链接"
else
  bad "内容相同的 .vimrc 不备份，直接换成符号链接" "$(ls -A "$SAME_HOME" | tr '\n' ' ')"
fi

NP_HOME="$SANDBOX/vim-np"
rm -rf "$NP_HOME" "$VIMREPO/.vim"; : > "$STUB_LOG"
run_vim_sh "$NP_HOME" --no-plugins
if [ -L "$NP_HOME/.vim" ] && [ "$(stub_calls CURL)" = "0" ] && [ "$(stub_calls VIM)" = "0" ]; then
  ok "--no-plugins 只链接配置，不下载也不跑 vim"
else
  bad "--no-plugins 只链接配置，不下载也不跑 vim" \
    "curl $(stub_calls CURL) 次，vim $(stub_calls VIM) 次"
fi

# 找不到 vim：必须说清楚并指向 README，而不是抛一句 command not found
NONE_HOME="$SANDBOX/vim-none"
rm -rf "$NONE_HOME"; mkdir -p "$NONE_HOME"
VIM=definitely-not-a-vim-binary PATH="$VIMBIN:$PATH" HOME="$NONE_HOME" \
  bash "$VIMREPO/vim.sh" >"$SANDBOX/vim-out" 2>&1
RC=$?
if [ "$RC" -ne 0 ] && [ ! -L "$NONE_HOME/.vimrc" ] && [ ! -L "$NONE_HOME/.vim" ]; then
  ok "找不到 vim 时失败且不建链接"
else
  bad "找不到 vim 时失败且不建链接" "退出码 $RC"
fi
assert_contains "提示里指明了 README" "$(cat "$SANDBOX/vim-out")" "README"

# ---------------------------------------------------------------------------
group "emacs.sh 版本闸门"

# 假 emacs：只回应 --version。真 emacs 装不上，但版本闸门的逻辑必须能测。
fake_emacs() { # <版本号> -> 打印可执行文件路径
  local d="$SANDBOX/emacs-$1"
  mkdir -p "$d"
  printf '#!/bin/sh\necho "GNU Emacs %s"\n' "$1" > "$d/emacs"
  chmod +x "$d/emacs"
  printf '%s' "$d/emacs"
}

# run_emacs_sh <家目录> <EMACS 路径或空> [参数...] -> 返回 emacs.sh 的退出码
run_emacs_sh() {
  local home="$1" em="$2"; shift 2
  mkdir -p "$home"
  if [ -n "$em" ]; then
    EMACS="$em" HOME="$home" bash "$REPO/emacs.sh" "$@" >"$SANDBOX/emacs-out" 2>&1
  else
    # 空 PATH，保证找不到真 emacs
    env -i PATH=/usr/bin:/bin HOME="$home" bash "$REPO/emacs.sh" "$@" >"$SANDBOX/emacs-out" 2>&1
  fi
}

EMACS_LINKED() { [ -L "$1/.emacs.d" ]; }

# 版本比较是纯函数，直接从 emacs.sh 里抠出来在进程内测：比每次 fork 一个 bash
# 快两个数量级，而且能铺开比端到端用例多得多的边界。抠的是真函数不是副本，
# 所以这里通过就等于脚本里那段通过。
EVAL_SRC="$(sed -n '/^version_ge()/,/^}/p' emacs.sh)"
if [ -z "$EVAL_SRC" ]; then
  bad "能从 emacs.sh 里取到 version_ge" "没匹配到函数定义，它被改名或改写了？"
else
  eval "$EVAL_SRC"
  # 字符串比较会得出 "9.9" > "30.1"；短的一侧补 0，所以 30.1 == 30.1.0；
  # 30.0.92 是 30.0 的预发布版，按版本序确实低于 30.1。
  VERSION_CASES="
30.1 30.1 pass
31.1 30.1 pass
30.2 30.1 pass
31 30.1 pass
30.1.0 30.1 pass
30.1.1 30.1 pass
30.10 30.1 pass
30.1 30.0.9 pass
30.0 30.1 fail
30.0.92 30.1 fail
30.0.99 30.1 fail
29.4 30.1 fail
27.1 30.1 fail
9.9 30.1 fail
3.1 30.1 fail
30.0 30.0.1 fail
"
  VER_BAD=""
  while read -r ver min want; do
    [ -z "$ver" ] && continue
    if version_ge "$ver" "$min"; then got=pass; else got=fail; fi
    [ "$got" = "$want" ] || VER_BAD="$VER_BAD\n    $ver vs $min：期望 $want，实得 $got"
  done <<EOF
$VERSION_CASES
EOF
  if [ -z "$VER_BAD" ]; then
    ok "version_ge 的 16 组版本比较全部正确"
  else
    bad "version_ge 的 16 组版本比较全部正确" "$(printf '%b' "$VER_BAD")"
  fi
fi

# 端到端只留够证明接线是对的：拦一个（版本不够且绝不能先建链接）、放一个。
run_emacs_sh "$SANDBOX/em-old" "$(fake_emacs 27.1)"
if [ $? -eq 0 ]; then
  bad "Emacs 27.1 被拒绝" "退出码是 0"
elif EMACS_LINKED "$SANDBOX/em-old"; then
  bad "Emacs 27.1 被拒绝后不得留下链接" "已建出 $SANDBOX/em-old/.emacs.d"
else
  ok "Emacs 27.1 被拒绝且未建链接"
fi

run_emacs_sh "$SANDBOX/em-new" "$(fake_emacs 31.1)"
if [ $? -eq 0 ] && EMACS_LINKED "$SANDBOX/em-new"; then
  ok "Emacs 31.1 放行并建出链接"
else
  bad "Emacs 31.1 放行并建出链接" "$(cat "$SANDBOX/emacs-out")"
fi

# 找不到 emacs：必须说清楚，并指向 README，而不是抛一句 command not found
run_emacs_sh "$SANDBOX/em-none" ""
RC=$?
if [ "$RC" -ne 0 ] && ! EMACS_LINKED "$SANDBOX/em-none"; then
  ok "找不到 emacs 时失败且不建链接"
else
  bad "找不到 emacs 时失败且不建链接" "退出码 $RC"
fi
assert_contains "提示里指明了 README 的 Emacs 章节" "$(cat "$SANDBOX/emacs-out")" "README"

# --force：用户明确要求时，旧版本也要放行
run_emacs_sh "$SANDBOX/em-force" "$(fake_emacs 27.1)" --force
if [ $? -eq 0 ] && EMACS_LINKED "$SANDBOX/em-force"; then
  ok "--force 覆盖版本闸门"
else
  bad "--force 覆盖版本闸门" "$(cat "$SANDBOX/emacs-out")"
fi

# dry-run：一个字都不许落地
run_emacs_sh "$SANDBOX/em-dry" "$(fake_emacs 31.1)" --dry-run
if EMACS_LINKED "$SANDBOX/em-dry"; then
  bad "emacs.sh --dry-run 不建链接" "却建出了链接"
else
  ok "emacs.sh --dry-run 不建链接"
fi

# 既有真实目录必须先备份再覆盖，否则用户配置就这么没了
mkdir -p "$SANDBOX/em-bk/.emacs.d"
printf 'OLD\n' > "$SANDBOX/em-bk/.emacs.d/marker"
run_emacs_sh "$SANDBOX/em-bk" "$(fake_emacs 31.1)"
BK="$(find "$SANDBOX/em-bk" -maxdepth 1 -name '.emacs.d.20*' | head -1)"
if [ -n "$BK" ] && [ -f "$BK/marker" ] && EMACS_LINKED "$SANDBOX/em-bk"; then
  ok "既有 .emacs.d 先备份再链接"
else
  bad "既有 .emacs.d 先备份再链接" "备份目录：${BK:-无}"
fi

# 目标已经是指向别处的符号链接时，ln 不加 -n 会顺着它建到目录里面去
mkdir -p "$SANDBOX/em-nest/elsewhere"
ln -s "$SANDBOX/em-nest/elsewhere" "$SANDBOX/em-nest/.emacs.d"
run_emacs_sh "$SANDBOX/em-nest" "$(fake_emacs 31.1)"
NESTED="$(ls -A "$SANDBOX/em-nest/elsewhere" 2>/dev/null | wc -l | tr -d ' ')"
if [ "$NESTED" = "0" ] && [ "$(readlink "$SANDBOX/em-nest/.emacs.d")" = "$REPO/.emacs.d" ]; then
  ok "替换旧符号链接不产生套娃"
else
  bad "替换旧符号链接不产生套娃" "elsewhere 里多了 $NESTED 项"
fi

# emacs.sh 从不调用 sudo，就不该弹密码
assert_not_contains "emacs.sh 不索要 sudo（它用不到）" "$(cat emacs.sh)" "sudo -v"

# ---------------------------------------------------------------------------
group "Emacs 配置门禁"

# 用 emacs.sh 自己的判定来决定跑不跑 ERT：口径只有一个，不在测试里另抄一份
# 版本比较逻辑（抄一份就会有第二份会过期的真相）。
if bash emacs.sh --dry-run >"$SANDBOX/emacs-check" 2>&1; then
  assert_ok ".emacs.d 的 ERT 套件" .emacs.d/test/run-tests.sh
else
  printf '  \033[33m-\033[0m 跳过 .emacs.d 的 ERT 套件：%s\n' \
    "$(grep -m1 -E 'Emacs|emacs' "$SANDBOX/emacs-check" | head -c 120)"
fi

# ---------------------------------------------------------------------------
group "--help 不得漏出代码"

# 头部最后一行注释的内容。拿它当针，就能发现「写死行号写短了、把末尾截掉」——
# bootstrap.sh 曾经这样漏掉整段 DOTFILES_DIR 说明，ubuntu.sh 曾经把
# set -euo pipefail 和 HERE= 赋值漏进帮助信息里。
# 这里自己从头文件直接取，与被测脚本怎么实现无关，所以脚本改坏了它也照样测得出来。
last_header_line() {
  sed -n '2,/^[^#]/p' "$1" | sed '$d' | sed 's/^# \{0,1\}//' | grep -v '^[[:space:]]*$' | tail -1
}

for f in bootstrap.sh ubuntu.sh deploy.sh vim.sh emacs.sh; do
  HELP="$(bash "$f" --help 2>&1 || true)"
  assert_not_contains "$f --help 只打印注释" "$HELP" "set -euo pipefail"
  assert_not_contains "$f --help 不打印赋值语句" "$HELP" 'HERE="$(cd'
  LAST="$(last_header_line "$f")"
  assert_contains "$f --help 没被截断（含末行）" "$HELP" "$LAST"
done

# --help 是脚本门面，未知参数必须报错退出，不能当成没看见
for f in bootstrap.sh ubuntu.sh deploy.sh vim.sh emacs.sh; do
  assert_fail "$f 对未知参数报错" bash "$f" --definitely-not-a-flag
done

# 纯为留白而调用的 say ""，不该打出孤零零一个「==> 」。
# 三个脚本各抄了一份 say()，抄漏守卫就会漏出来——先查源码里的守卫，
# 再用真实输出验证一次（emacs.sh 在 macOS 上也能跑 dry-run，可以真跑）。
for f in ubuntu.sh vim.sh emacs.sh bootstrap.sh; do
  assert_contains "$f 的 say() 有空白行守卫" "$(grep -m1 '^say()' "$f")" '[ -z "${1:-}" ]'
done

# 注意别用 assert_not_contains：$( ) 会把尾换行吃掉，针退化成「==> 」，
# 于是每一行都命中。要数的是「整行只有提示符」的行数。
EMACS_DRY="$(bash emacs.sh --dry-run 2>&1 | sed 's/\x1b\[[0-9;]*m//g' || true)"
NAKED="$(printf '%s\n' "$EMACS_DRY" | grep -cE '^==>[[:space:]]*$' || true)"
if [ "${NAKED:-1}" = "0" ]; then
  ok "emacs.sh --dry-run 不留孤零零的 ==="
else
  bad "emacs.sh --dry-run 不留孤零零的 ==>" "有 $NAKED 行只有提示符，没有内容"
fi

# ---------------------------------------------------------------------------
group "README 与脚本的一致性"

for s in bootstrap.sh ubuntu.sh deploy.sh vim.sh emacs.sh brew.sh; do
  assert_contains "README 提到 $s" "$(cat README.md)" "$s"
done

# README 里反引号包住的仓库内路径必须真的存在。三类不算仓库路径，显式放过：
#   CLAUDE.md  —— 讲的是「软链成这个名字」，仓库里叫 CLAUDE_CN.md / CLAUDE_EN.md
#   default.toml / plug.vim / var/packages/… —— 都在 $HOME 下，不在本仓库
README_SKIP='CLAUDE\.md|default\.toml|plug\.vim|var/packages/'
README_MISSING=""
for p in $(grep -oE '`[.A-Za-z0-9_/-]+\.(el|sh|md|toml|vim|org|txt)`' README.md | tr -d '`' | sort -u); do
  printf '%s\n' "$p" | grep -qE "^($README_SKIP)" && continue
  [ -e "$p" ] || README_MISSING="$README_MISSING $p"
done
if [ -z "$README_MISSING" ]; then
  ok "README 引用的仓库内路径都存在"
else
  bad "README 引用的仓库内路径都存在" "指空气了：$README_MISSING"
fi

# 行号会漂：emacs-solo-clipboard.el 的 Package-Requires 原本在第 6 行，文件头改动之后
# 变成第 5 行，README 却还指着 6——而「文件存在、行号也在范围内」根本拦不住这种漂移。
# 所以干脆禁掉这个写法，要指位置就指符号名（函数名、变量名、注释里的键名）。
README_LINEREF="$(grep -oE '`[.A-Za-z0-9_/-]+\.(el|sh|md|toml|vim|org|txt):[0-9]+' README.md | tr -d '`' | sort -u)"
if [ -z "$README_LINEREF" ]; then
  ok "README 不拿行号指位置（行号会漂）"
else
  bad "README 不拿行号指位置（行号会漂）" "改用符号名：$(printf '%s ' $README_LINEREF)"
fi

# README 说「emacs-solo-*.el 都声明 Emacs 30.1」——那就得真的都声明。加了新文件却
# 忘了写包头，等于悄悄把 emacs.sh 那个版本闸门的依据抽掉了。
NO_REQ=""
for f in .emacs.d/lisp/emacs-solo-*.el; do
  grep -q 'Package-Requires:.*emacs "30.1"' "$f" || NO_REQ="$NO_REQ ${f##*/}"
done
if [ -z "$NO_REQ" ]; then
  ok "emacs-solo-*.el 都声明 Package-Requires Emacs 30.1"
else
  bad "emacs-solo-*.el 都声明 Package-Requires Emacs 30.1" "没声明：$NO_REQ"
fi

assert_contains "ubuntu.sh 会调用 deploy.sh" "$(cat ubuntu.sh)" "deploy.sh"

# ubuntu.sh 不装 Emacs：apt 里是 27.1，配置要 30.1+，装上就是个跑不起来的组合。
# 留个 --with-emacs 开关等于留个坑，用户按提示开了它只会得到一屏报错。
assert_not_contains "ubuntu.sh 没有 --with-emacs 开关" "$(cat ubuntu.sh)" "--with-emacs"

# apt.sh 已被 ubuntu.sh 取代，别再捡回来：它那份包清单在 22.04 上会报错
# （libncurses5-dev 是过渡包），而且它 clone 的 rupa/z 和 liquidprompt
# 没有任何 dotfile 会 source，装了也是闲置的。
assert_ok "apt.sh 已删除（被 ubuntu.sh 取代）" test ! -e apt.sh
assert_contains "ubuntu.sh 指向 emacs.sh" "$(cat ubuntu.sh)" "./emacs.sh"
assert_contains "bootstrap.sh 会提到 ubuntu.sh" "$(cat bootstrap.sh)" "ubuntu.sh"
assert_contains "ubuntu.sh 会生成 en_US.UTF-8" "$(cat ubuntu.sh)" "locale-gen en_US.UTF-8"

assert_contains "bootstrap.sh 以「脚本体来自 stdin」为判据" "$(cat bootstrap.sh)" '_src="${BASH_SOURCE[0]:-}"'

# 真跑一遍管道执行，而不是只看源码里有没有那行守卫。
# 守卫若失效，stdin 会被前半段的命令吃掉，执行到中途就断，末尾那句「引导完成」不会出现。
PIPED_OUT="$(cat bootstrap.sh | DOTFILES_DIR=/nonexistent-dir bash -s -- --dry-run 2>&1 || true)"
assert_contains "管道执行能跑到底（末句出现）" "$PIPED_OUT" "引导完成"
assert_contains "管道执行走到了安装步骤" "$PIPED_OUT" "apt-get install -y"
assert_contains "管道执行规划了克隆" "$PIPED_OUT" "git clone"

# 从文件执行时必须等价。stdin 重定向过也一样——
# 早先的守卫用「stdin 不是终端」当判据，会把这种情况误当成管道执行，
# 于是 cat 读到 EOF、写出空脚本、一声不吭跑完。
DIRECT_OUT="$(DOTFILES_DIR=/nonexistent-dir bash bootstrap.sh --dry-run 2>&1 || true)"
assert_contains "直接执行能跑到底" "$DIRECT_OUT" "引导完成"
REDIR_OUT="$(DOTFILES_DIR=/nonexistent-dir bash bootstrap.sh --dry-run </dev/null 2>&1 || true)"
assert_contains "stdin 被重定向时依然能跑到底" "$REDIR_OUT" "引导完成"

# dry-run 不得真的动系统。不比对输出文本，而是塞一个会留下痕迹的假 apt-get，
# 看它到底有没有被调用——这才是「没动系统」的直接证据。
STUB_DIR="$(mktemp -d)"
cat > "$STUB_DIR/apt-get" <<'STUB'
#!/bin/sh
echo "CALLED $*" >> "$APT_MARKER"
STUB
chmod +x "$STUB_DIR/apt-get"
export APT_MARKER="$SANDBOX/apt-was-called"
PATH="$STUB_DIR:$PATH" DOTFILES_DIR=/nonexistent-dir bash bootstrap.sh --dry-run >/dev/null 2>&1 || true
if [ -f "$APT_MARKER" ]; then
  bad "dry-run 不真的调用 apt-get" "假 apt-get 被调用了：$(cat "$APT_MARKER")"
else
  ok "dry-run 不真的调用 apt-get"
fi
rm -rf "$STUB_DIR"

# ---------------------------------------------------------------------------
printf '\n\033[1m结果：\033[0m %d 通过，%d 失败\n' "$PASS" "$FAIL"

if [ "$FAIL" -gt 0 ]; then
  printf '\n失败的用例：\n'
  for n in "${FAILED_NAMES[@]}"; do printf '  - %s\n' "$n"; done
  exit 1
fi
exit 0
