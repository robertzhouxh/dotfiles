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

assert_contains "ubuntu.sh 会调用 deploy.sh" "$(cat ubuntu.sh)" "deploy.sh"

# ubuntu.sh 不装 Emacs：apt 里是 27.1，配置要 30.1+，装上就是个跑不起来的组合。
# 留个 --with-emacs 开关等于留个坑，用户按提示开了它只会得到一屏报错。
assert_not_contains "ubuntu.sh 没有 --with-emacs 开关" "$(cat ubuntu.sh)" "--with-emacs"
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
