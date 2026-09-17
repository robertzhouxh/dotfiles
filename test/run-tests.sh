#!/usr/bin/env bash
# 门禁测试运行器：确定性、本地、免费、无网络、无 sudo、<2 秒、永不 flaky。
#
# 覆盖范围：
#   - 所有 shell 文件的语法
#   - 「无硬编码家目录」回归（/Users/zxh 那类写死路径）
#   - .alias / .envv 在 mac 与 linux 两个平台下的真实行为（靠 DOTFILES_OS 注入）
#   - .zprofile 的 brew 探测不刷错误
#   - deploy.sh 的完整行为：dry-run 无副作用、复制、链接、幂等、备份
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
           bootstrap.sh ubuntu.sh deploy.sh vim.sh emacs.sh brew.sh apt.sh; } | sort -u
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

# apt.sh 里那条 libncurses5-dev 是 22.04 的过渡包，新脚本不能再带。
# 只看包清单，不看注释——注释里正当地提到了这个名字。
PKG_LISTS="$(sed -n '/^CORE_PKGS=(/,/^)/p;/^OPTIONAL_PKGS=(/,/^)/p' ubuntu.sh | sed 's/#.*//')"
assert_not_contains "包清单里没有已废弃的 libncurses5-dev" "$PKG_LISTS" "libncurses5-dev"
assert_contains "包清单里用的是 libncurses-dev" "$PKG_LISTS" "libncurses-dev"

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
group "README 与脚本的一致性"

for s in bootstrap.sh ubuntu.sh deploy.sh vim.sh emacs.sh brew.sh; do
  assert_contains "README 提到 $s" "$(cat README.md)" "$s"
done

assert_contains "ubuntu.sh 会调用 deploy.sh" "$(cat ubuntu.sh)" "deploy.sh"
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
