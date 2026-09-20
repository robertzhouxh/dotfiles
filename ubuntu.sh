#!/usr/bin/env bash
# ubuntu.sh —— 在 Ubuntu（22.04 及以后）上把本仓库跑起来
#
# 做七件事：装开发工具 → 装 starship、rtk、asdf → 生成 locale → 部署 dotfiles → 切登录 shell 到 zsh。
# 可反复执行，已经满足的步骤会跳过。
#
# 用法：
#   ./ubuntu.sh                   # 复制方式部署 dotfiles
#   ./ubuntu.sh --link            # 符号链接方式部署，之后 git pull 即生效
#   ./ubuntu.sh --no-chsh         # 不改登录 shell
#   ./ubuntu.sh --dry-run         # 只打印会做什么
#
# 刻意不装 Emacs：apt 里的是 27.1，而本仓库配置要 30.1+（见 README
# 「Ubuntu 上的 Emacs」）。装一个确定跑不起来的版本只会误导人，
# 所以 Emacs 由你自己装，装好后跑 ./emacs.sh —— 它会先验证版本再链接。
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DO_CHSH=1
DRY_RUN=0
DEPLOY_ARGS=()

while [ $# -gt 0 ]; do
  case "$1" in
    --no-chsh)    DO_CHSH=0 ;;
    --link)       DEPLOY_ARGS+=(--link) ;;
    --copy)       DEPLOY_ARGS+=(--copy) ;;
    --dry-run|-n) DRY_RUN=1; DEPLOY_ARGS+=(--dry-run) ;;
    # 打印到第一行非注释为止，不写死行号：写死的范围会随文件改动越界，
    # 把 set -euo pipefail 和下面的变量赋值漏进帮助信息里。
    -h|--help)
      sed -n '2,/^[^#]/p' "$0" | sed '$d' | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *) echo "未知参数：$1" >&2; exit 2 ;;
  esac
  shift
done

# 空字符串只换行不打前缀，否则纯为了留白的那几处会印出孤零零一个「==>」
say()  { [ -z "${1:-}" ] && { printf '\n'; return 0; }; printf '\033[1;32m==>\033[0m %s\n' "$1"; }
warn() { printf '\033[1;33m警告：\033[0m %s\n' "$1"; }
die()  { printf '\033[1;31m错误：\033[0m %s\n' "$*" >&2; exit 1; }
# dry-run 下只打印，不真的执行
run()  { if [ "$DRY_RUN" = 1 ]; then say "[dry-run] $*"; else "$@"; fi; }

# ---- 0. 前置检查 ----
[ "$(uname -s)" = "Linux" ] || die "这个脚本只用于 Linux。macOS 用 README 里的 brew.sh。"
command -v apt-get >/dev/null 2>&1 || die "找不到 apt-get，只支持 Debian / Ubuntu。"

if [ "$(id -u)" = "0" ]; then
  SUDO=""
else
  command -v sudo >/dev/null 2>&1 || die "需要 sudo 或 root 权限，但两者都没有。"
  say "需要管理员权限，下面可能要求输入密码。"
  sudo -v || die "sudo 验证失败。"
  SUDO="sudo"
  while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
fi

# ---- 1. 软件包 ----
# 核心包：任何一个装不上都算失败，直接停。
CORE_PKGS=(
  ca-certificates curl wget git rsync gnupg
  zsh
  software-properties-common
  build-essential pkg-config cmake autoconf automake texinfo
  # Emacs / 常见源码构建的依赖。用 libncurses-dev，不是已废弃的 libncurses5-dev。
  libncurses-dev libssl-dev libreadline-dev libsqlite3-dev libxml2-dev
  zlib1g-dev libpcre3-dev libgnutls28-dev libssh-dev libjansson-dev
  language-pack-en
)

# 可选包：装了更好，装不上只提示，不影响整体。
# 全部核对过 jammy 的实际索引；btop / ripgrep / fzf / fd-find / autojump 在 universe。
OPTIONAL_PKGS=(
  # 命令行日常
  vim ripgrep fzf tree htop jq unzip zip xdg-utils net-tools
  fd-find
  # .alias 里那族 ls 增强。exa 与 eza 二选一，各发行版有哪个装哪个：22.04 的
  # universe 只有 exa（0.10.1），24.04 起只剩 eza（0.18.2），两个都在可选里，
  # 探测时自然只会命中其中一个。
  #
  # 注意别把 --git 当默认能力：Ubuntu 打包的 exa 是关掉 git feature 编的，传
  # --git 会让命令直接以 rc=3 失败，不是少显示一列。.alias 因此改成运行时探测，
  # 这里只管把包装上。
  exa
  eza
  # dig 等 DNS 工具。不用 dnsutils——那是 bind9-dnsutils 的过渡包。
  bind9-dnsutils
  # .zshrc:16-24 / .bashrc:16-24 会去 source autojump 的 profile.d，这是真正接上的那个
  autojump
  btop
  # 从别处 SSH 进这台机器要用（TRAMP-RPC 也要求远端能 SSH 访问）。
  # 被删掉的 apt.sh 一直在装它，这里是接着装。装在桌面机上会自起监听，
  # 不想要就别装——它列在可选里，跳过不会影响别的。
  openssh-server
  # 注：starship 与 rtk 都不在源里，它们不走 apt，见下面第 2、3 步。
  # jammy 的 zoxide 是 0.4.3，且没有任何 dotfile 会 init 它，装了也是一把闲置的二进制，故不装。
  # 解 Sarasa Mono SC 的 .7z 用（见「字体」那一步）。更纱黑体 GitHub release 只发
  # .7z，jammy 源里也没有 fonts-sarasa-gothic（24.04 才进），所以要自己下、自己解。
  p7zip-full
)

say "更新软件包索引……"
run $SUDO apt-get update

# universe 里才有 autojump / btop / ripgrep / fzf / fd-find，先确保它开着
if ! apt-cache show autojump >/dev/null 2>&1 && command -v add-apt-repository >/dev/null 2>&1; then
  say "启用 universe 软件源……"
  run $SUDO add-apt-repository -y universe
  run $SUDO apt-get update
fi

# 索引有没有就绪。--dry-run 不会真的跑 apt-get update，此时索引必然是空的，
# 拿空索引去探测会把每个包都判成「找不到」，那是误导，得区分开。
#
# 不能拿 `apt-cache show 某个包` 来探：它对已安装的包会回落到 dpkg 状态，
# 索引全空也能答「有」。直接看索引文件本身。
INDEX_READY=1
ls /var/lib/apt/lists/*_Packages* >/dev/null 2>&1 || INDEX_READY=0

if [ "$INDEX_READY" = 0 ]; then
  if [ "$DRY_RUN" = 1 ]; then
    warn "dry-run 没有执行 apt-get update，本地索引为空，跳过可用性检查。"
    warn "真正跑一次时才是在真实索引上判定。"
  else
    die "apt-get update 之后索引依然为空，检查 /etc/apt/sources.list 与网络。"
  fi
fi

# 先探测可用性，不要一股脑 install 再让 apt 报一串 E: Unable to locate package
UNAVAILABLE=()
if [ "$INDEX_READY" = 1 ]; then
  for pkg in "${CORE_PKGS[@]}"; do
    apt-cache show "$pkg" >/dev/null 2>&1 || UNAVAILABLE+=("$pkg")
  done
fi
if [ ${#UNAVAILABLE[@]} -gt 0 ]; then
  die "以下核心包在当前 apt 源里找不到：${UNAVAILABLE[*]}
请检查 /etc/apt/sources.list，确认对应组件（main/universe）已启用。"
fi

say "安装核心工具（${#CORE_PKGS[@]} 个）……"
run $SUDO apt-get install -y "${CORE_PKGS[@]}"

INSTALLABLE=()
SKIPPED=()
for pkg in "${OPTIONAL_PKGS[@]}"; do
  if [ "$INDEX_READY" != 1 ] || apt-cache show "$pkg" >/dev/null 2>&1; then
    INSTALLABLE+=("$pkg")
  else
    SKIPPED+=("$pkg")
  fi
done

say "安装可选工具（${#INSTALLABLE[@]} 个）……"
if [ ${#INSTALLABLE[@]} -gt 0 ]; then
  run $SUDO apt-get install -y "${INSTALLABLE[@]}"
fi
if [ ${#SKIPPED[@]} -gt 0 ]; then
  warn "当前源里没有，已跳过：${SKIPPED[*]}"
  warn "以上都是可选包，跳过不影响其余步骤。"
  warn "用到它们的地方自带 command -v 守卫，例如 .alias 里那族 ls 增强：没装就是普通 ls。"
fi

# 这里刻意不装 Emacs。apt 里是 27.1，配置要 30.1+，装上就是个跑不起来的组合；
# 见收尾提示与 README「Ubuntu 上的 Emacs」。

# ---- 2. starship ----
# jammy 源里没有 starship（macOS 侧由 brew.sh 装），走官方安装脚本。上游只发
# tar.gz，没有 .deb / .rpm；脚本自己按 uname 认平台（Linux 挑 musl 静态包，不挑
# glibc），自己 sudo 装到 /usr/local/bin，比我们自己拼 release 资产名稳。
#
# 拉不到只警告不中断：这是个提示符，不该让整台机器的初始化卡在这儿。.zshrc /
# .bashrc 里那段 init 本来就是 command -v 通过才生效，没装就是默认样式。
#
# 单独抽成函数是为了能在测试里抠出来跑：ubuntu.sh 开头有 uname 闸门，在 macOS
# 上跑两行就 die，逻辑埋在主干里就永远测不到。
STARSHIP_INSTALL_URL="${STARSHIP_INSTALL_URL:-https://starship.rs/install.sh}"

install_starship() {
  if command -v starship >/dev/null 2>&1; then
    say "starship 已装（$(starship --version 2>/dev/null | head -n 1)），跳过。"
    return 0
  fi
  if [ "$DRY_RUN" = 1 ]; then
    say "[dry-run] 下载 $STARSHIP_INSTALL_URL 并执行 sh -s -- -y，装到 /usr/local/bin"
    return 0
  fi
  say "安装 starship……"
  local tmp installer_ok=1
  tmp="$(mktemp)"
  if curl -fsSL -o "$tmp" "$STARSHIP_INSTALL_URL" && ${SUDO:-} sh "$tmp" -y; then
    installer_ok=0
  fi
  rm -f "$tmp"
  # 安装脚本自己会报告装到了哪儿，这里复核一遍 PATH：装没装上以实际能用为准。
  if [ "$installer_ok" = 0 ] && command -v starship >/dev/null 2>&1; then
    say "starship 装好了：$(command -v starship)"
    return 0
  fi
  return 1
}

if ! install_starship; then
  warn "starship 没装上（下载或安装失败），已跳过。提示符退回默认样式，其余不受影响。"
  warn "手动补装：curl -fsSL $STARSHIP_INSTALL_URL | sh -s -- -y"
fi

# ---- 3. rtk ----
# rtk（https://github.com/rtk-ai/rtk）是个命令代理：把 git status 之类命令的输出压掉
# 60-90% 再交给 agent 读，给 Claude Code 省 token。apt 里没有，也没有官方 deb 源，所以
# 跟 starship 一样走官方安装脚本——它自己按 uname 挑平台、下 release 里的 tar.gz、核对
# checksums.txt 里的 SHA-256 才安装，比我们手拼 release 资产名稳。
#
# 装到 ~/.local/bin 且刻意不套 sudo，而不是像 starship 那样进 /usr/local/bin：那正是
# .envv 会 _path_prepend 的目录，装给执行者自己就够；用 sudo 跑会把文件落进 root 的家目录。
#
# 拉不到只警告不中断：这是个锦上添花的加速器，缺了不影响 shell、编辑器、git 任何一件事。
#
# 单独抽成函数是为了能在测试里抠出来跑：ubuntu.sh 开头有 uname 闸门，在 macOS 上跑两行就 die。
RTK_INSTALL_URL="${RTK_INSTALL_URL:-https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh}"
# 默认落点跟官方安装脚本一致，也正好是 .envv 会加进 PATH 的那个目录。
RTK_BIN_DIR="${RTK_BIN_DIR:-$HOME/.local/bin}"

install_rtk() {
  local bin="$RTK_BIN_DIR/rtk" cand v found=""

  # 「已装」的判据是 `rtk --version` 打得出 `rtk <版本号>`，不是「有个叫 rtk 的可执行文件」：
  # 这个名字被两个项目共用（rtk-ai/rtk 与 crates.io 上的 Rust Type Kit），只认名字会把后者
  # 误判成已装，然后永远跳过真正要装的那个。
  #
  # 两个位置都看：RTK_BIN_DIR 与 PATH。新机器上 ~/.local/bin 还没进 PATH（.envv 要重新登录
  # 才生效），只看 PATH 会每次都重装一遍。
  for cand in "$bin" "$(command -v rtk 2>/dev/null)"; do
    [ -n "$cand" ] && [ -x "$cand" ] || continue
    # 赋值语句不吃 errexit 的豁免：候选二进制跑不起来时，光秃秃的 v="$(...)" 会让整个脚本
    # 在 set -e 下当场退出。补一个 || v="" 兜住。
    v="$("$cand" --version 2>/dev/null | head -n 1)" || v=""
    case "$v" in
      rtk\ [0-9]*) found="$cand"; break ;;
    esac
  done

  if [ -n "$found" ]; then
    say "rtk 已装（${v}，${found}），跳过。"
    return 0
  fi

  if [ "$DRY_RUN" = 1 ]; then
    say "[dry-run] 下载 $RTK_INSTALL_URL 并执行 sh，装到 $RTK_BIN_DIR"
    return 0
  fi

  say "安装 rtk……"
  local tmp installer_ok=1
  tmp="$(mktemp)"
  # RTK_INSTALL_DIR 指明落点；PATH 里先塞进同一个目录，免得官方脚本装完自查 `command -v rtk`
  # 时误报「装了但不在 PATH」——那只是 .envv 还没生效，不是真没装。
  if curl -fsSL -o "$tmp" "$RTK_INSTALL_URL" &&
     PATH="$RTK_BIN_DIR:$PATH" RTK_INSTALL_DIR="$RTK_BIN_DIR" sh "$tmp"; then
    installer_ok=0
  fi
  rm -f "$tmp"

  # 装没装上以「RTK_BIN_DIR 里的 rtk 能报出版本号」为准，不只看安装脚本的退出码：脚本成功
  # 但把文件落到别处时，新 shell 里敲 rtk 依然是 command not found。
  if [ "$installer_ok" = 0 ]; then
    v="$("$bin" --version 2>/dev/null | head -n 1)" || v=""
    case "$v" in
      rtk\ [0-9]*) say "rtk 装好了：${bin}（${v}）"; return 0 ;;
    esac
  fi
  return 1
}

if ! install_rtk; then
  warn "rtk 没装上（下载或安装失败），已跳过。少个省 token 的代理，其余不受影响。"
  warn "手动补装：curl -fsSL $RTK_INSTALL_URL | sh"
fi

# ---- 4. asdf ----
# asdf（https://asdf-vm.com）是版本管理器：Erlang / Elixir / Node 这些不该由 apt 管版本的
# 东西用它装。apt 源里没有它；上游从 0.16 起是 Go 写的单体二进制，仓库里已经没有 bin/，
# 老教程里「clone 完就能用」的那套不再成立（clone 下来只有源码，要自己 make），所以直接下
# 官方 release 资产（linux-<arch>.tar.gz）。
#
# 装到 ~/.local/bin，跟 rtk 同一个理由：那是 .envv 会 _path_prepend 的目录，不用 sudo，
# 也不往 /usr/local/bin 写用户级的东西。数据目录仍是 ASDF_DATA_DIR（默认 ~/.asdf），
# shims 由 .envv 接进 PATH。
#
# 版本写死，不查 GitHub 的 latest：脚本要离线可跑、每次跑结果一致。换版本：
#   ASDF_VERSION=0.21.0 ./ubuntu.sh      落点换地方：ASDF_BIN=/别的/路径/asdf ./ubuntu.sh
ASDF_VERSION="${ASDF_VERSION:-0.20.0}"
ASDF_RELEASE_BASE="${ASDF_RELEASE_BASE:-https://github.com/asdf-vm/asdf/releases/download}"

# 单独抽成函数是为了能在测试里抠出来跑：ubuntu.sh 开头有 uname 闸门，在 macOS 上跑两行就 die。
install_asdf() {
  local bin="${ASDF_BIN:-$HOME/.local/bin/asdf}" asset url tmpdir rc=0 have got

  # 「装过没有」以这个文件为准，不看 PATH：新机器上 ~/.local/bin 还没进 PATH（.envv 要重新
  # 登录才生效），只看 PATH 会每次都重下一遍。
  #
  # 比的是版本号本身，不是 `case $have in *$ASDF_VERSION*` 那种子串：子串会把 0.20 认成
  # 已经装过 0.20.0，于是升级永远不发生。
  # 版本号从 `asdf version v0.20.0 (revision 150aaf0)` 里抠，末尾那个 `#v` 不能省：上游
  # 打出来的版本号带一个 v 前缀，ASDF_VERSION 不带。不剥前缀就永远比不相等——「装过没有」
  # 的判据会一直认为没装对，每次跑都重下一遍；下面解包后那道校验同理，会把好包判成版本
  # 不对，于是永远装不上。（这行输出是拿 v0.20.0 的真二进制核过的，不是照文档猜的。）
  if [ -x "$bin" ]; then
    have="$("$bin" --version 2>/dev/null | head -n 1)" || have=""
    have="${have#asdf version }"; have="${have%% *}"; have="${have#v}"
    if [ "$have" = "$ASDF_VERSION" ]; then
      say "asdf 已装（${ASDF_VERSION}），跳过。"
      return 0
    fi
    say "asdf 现有版本是 ${have:-跑不起来}，换成 $ASDF_VERSION ……"
  elif command -v asdf >/dev/null 2>&1; then
    # 装在别处（brew、发行版包、或用户自己 clone 的）：不动它，免得装出两份互相遮蔽的 asdf。
    have="$(asdf --version 2>/dev/null | head -n 1)" || have=""
    have="${have#asdf version }"; have="${have%% *}"; have="${have#v}"
    say "asdf 已装（${have:-版本未知}，$(command -v asdf)），跳过。"
    return 0
  fi

  # uname -m 到 release 资产名里的架构
  case "$(uname -m)" in
    x86_64|amd64)        asset=amd64 ;;
    aarch64|arm64)       asset=arm64 ;;
    i386|i486|i586|i686) asset=386 ;;
    *)
      warn "asdf 上游没有 $(uname -m) 的 Linux 二进制，跳过。"
      return 1 ;;
  esac

  url="$ASDF_RELEASE_BASE/v$ASDF_VERSION/asdf-v$ASDF_VERSION-linux-$asset.tar.gz"
  if [ "$DRY_RUN" = 1 ]; then
    say "[dry-run] 下载 ${url}，把包里的 asdf 装到 ${bin}"
    return 0
  fi

  say "安装 asdf ${ASDF_VERSION}（linux-${asset}）……"
  tmpdir="$(mktemp -d)"
  curl -fsSL -o "$tmpdir/asdf.tar.gz" "$url" || rc=1
  # 先解到临时目录、跑通了再落到 PATH 上：宁可不装，也别留一个跑不起来的 asdf 把整个
  # 版本管理器（以及它名下的所有语言）顶掉。tar 包损坏在这里就会报错，不必再叠一层校验。
  if [ "$rc" = 0 ]; then
    tar -xzf "$tmpdir/asdf.tar.gz" -C "$tmpdir" asdf || rc=1
  fi
  if [ "$rc" = 0 ]; then
    chmod 0755 "$tmpdir/asdf" 2>/dev/null || true
    got="$("$tmpdir/asdf" --version 2>/dev/null | head -n 1)" || got=""
    got="${got#asdf version }"; got="${got%% *}"; got="${got#v}"
    if [ "$got" != "$ASDF_VERSION" ]; then
      warn "下回来的 asdf 跑不起来或版本不对（${got:-跑不起来}），没有安装。"
      rc=1
    fi
  fi
  if [ "$rc" = 0 ]; then
    mkdir -p "$(dirname "$bin")"
    cp "$tmpdir/asdf" "$bin" && chmod 0755 "$bin" || rc=1
  fi
  rm -rf "$tmpdir"
  if [ "$rc" != 0 ]; then
    return 1
  fi
  say "asdf 装好了：${bin}（${ASDF_VERSION}）"
  return 0
}

if ! install_asdf; then
  warn "asdf 没装上（下载或校验失败），已跳过。它不影响其余步骤。"
  warn "手动装法见 README 的 asdf 一节；重跑本脚本时会自动重试。"
fi

# ---- 5. 字体 ----
# Emacs 配置（emacs-init-font.el）的 my/ef、my/cf 都优先 Sarasa Mono SC——它是
# 等宽字体里 CJK 严格 2:1 的那个，markdown 表格里的中文才能跟 ASCII 对齐。macOS
# 侧由 brew.sh 装字体，Linux 这边 jammy 源里没有 fonts-sarasa-gothic（24.04 才进
# Debian/Ubuntu），只能下 GitHub release 自己解。
#
# 装到 ~/.local/share/fonts（用户级、不套 sudo），fc-cache 刷新后 fontconfig 即能
# 解析。拉不到只警告不中断：没这字体只是表格错位，不影响 shell / 编辑器 / git。
#
# 单独抽成函数是为了能在测试里抠出来跑（跟 starship / rtk / asdf 同理）。
SARASA_VERSION="${SARASA_VERSION:-1.0.41}"
SARASA_URL="${SARASA_URL:-https://github.com/be5invis/Sarasa-Gothic/releases/download/v${SARASA_VERSION}/SarasaMonoSC-TTF-${SARASA_VERSION}.7z}"

install_sarasa_mono() {
  if command -v fc-list >/dev/null 2>&1 && fc-list 2>/dev/null | grep -qi "Sarasa Mono SC"; then
    say "Sarasa Mono SC 已装，跳过。"
    return 0
  fi
  if [ "$DRY_RUN" = 1 ]; then
    say "[dry-run] 下载 $SARASA_URL 解压到 ~/.local/share/fonts/sarasa-mono-sc 并 fc-cache"
    return 0
  fi
  say "安装 Sarasa Mono SC……"
  local tmp ok=1
  tmp="$(mktemp -d)"
  if command -v 7z >/dev/null 2>&1 \
     && curl -fsSL -o "$tmp/font.7z" "$SARASA_URL" \
     && 7z x -y -o"$tmp" "$tmp/font.7z" >/dev/null \
     && mkdir -p "$HOME/.local/share/fonts/sarasa-mono-sc" \
     && cp "$tmp"/*.ttf "$HOME/.local/share/fonts/sarasa-mono-sc/" \
     && fc-cache -f "$HOME/.local/share/fonts" >/dev/null 2>&1; then
    ok=0
  fi
  rm -rf "$tmp"
  if [ "$ok" = 0 ]; then
    say "Sarasa Mono SC 装好了，重启 Emacs 后 markdown 表格中文对齐。"
    return 0
  fi
  return 1
}

if ! install_sarasa_mono; then
  warn "Sarasa Mono SC 没装上（缺 7z 或下载/解压失败），已跳过。markdown 表格里中文会错位，其余不受影响。"
  warn "手动补装：apt install p7zip-full，再下 $SARASA_URL 解压到 ~/.local/share/fonts 后 fc-cache -f"
fi

# ---- 6. locale ----
# 不做这步，.envv 里写死的 en_US.UTF-8 会让每条命令都刷 setlocale 警告。
if locale -a 2>/dev/null | grep -qiE '^en_US\.utf-?8$'; then
  say "en_US.UTF-8 已存在，跳过。"
else
  say "生成 en_US.UTF-8 locale……"
  run $SUDO locale-gen en_US.UTF-8
  run $SUDO update-locale LANG=en_US.UTF-8
fi

# ---- 7. 部署 dotfiles ----
say "部署 dotfiles……"
if [ "$DRY_RUN" = 1 ]; then
  # shellcheck disable=SC2016  # 这里就是要让 $HERE 在子 shell 里展开，不是当前 shell
  run bash "$HERE/deploy.sh" "${DEPLOY_ARGS[@]+"${DEPLOY_ARGS[@]}"}"
else
  bash "$HERE/deploy.sh" "${DEPLOY_ARGS[@]+"${DEPLOY_ARGS[@]}"}"
fi

# ---- 8. 登录 shell ----
if [ "$DO_CHSH" = 0 ]; then
  warn "按 --no-chsh 要求跳过，登录 shell 未改。"
elif ! command -v zsh >/dev/null 2>&1; then
  warn "zsh 没装上，登录 shell 无法切换，.zshrc 不会生效。"
else
  ZSH_BIN="$(command -v zsh)"
  CURRENT_SHELL="$(getent passwd "$(id -un)" | cut -d: -f7)"
  if [ "$CURRENT_SHELL" = "$ZSH_BIN" ]; then
    say "登录 shell 已经是 zsh，跳过。"
  else
    say "把登录 shell 从 $CURRENT_SHELL 切到 $ZSH_BIN ……"
    run chsh -s "$ZSH_BIN"
    # chsh 可能「成功」却没改：某些机器上 PAM / 目录服务会把改动吃掉，退出码照样是 0。
    # 这个脚本的可反复执行只保证「跑过」，不保证「成了」，所以读回来确认一次。
    if [ "$DRY_RUN" = 0 ]; then
      NOW_SHELL="$(getent passwd "$(id -un)" | cut -d: -f7)"
      if [ "$NOW_SHELL" = "$ZSH_BIN" ]; then
        say "已切到 ${ZSH_BIN}，重新登录后生效。想改回去：chsh -s $CURRENT_SHELL"
      else
        warn "chsh 退出码是 0，但登录 shell 仍是 ${NOW_SHELL}（期望 ${ZSH_BIN}）。"
        warn "试试 sudo chsh -s $ZSH_BIN $(id -un)，或直接改 /etc/passwd 里那一行。"
        warn ".zshrc 要在登录 shell 是 zsh 时才会生效。"
      fi
    fi
  fi
fi

# ---- 9. 收尾 ----
say ""
say "完成。下一步："
printf '  1. exec zsh                    立刻进新 shell（或重新登录）\n'
printf '  2. ./vim.sh                    部署 vim 与插件\n'
printf '  3. ./emacs.sh                  装好 Emacs 30+ 之后跑，它会先验证版本\n'
printf '  4. rtk init -g                 把 rtk 接进 Claude Code（见 README「RTK」）\n'
printf '  5. asdf plugin add nodejs      用 asdf 装语言运行时（见 README「asdf」）\n'
say ""
warn ".vim 和 .emacs.d 不在 deploy.sh 的处理范围内（它们需要符号链接，见 vim.sh / emacs.sh）。"
warn "本脚本不碰 Emacs：apt 里只有 27.1，配置要 30.1+。装法见 README「Ubuntu 上的 Emacs」。"
