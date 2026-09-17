#!/usr/bin/env bash
# deploy.sh —— 把仓库里的 dotfiles 部署到 $HOME
#
# 为什么不用 `rsync --include='.*' --exclude='*'`：那条规则依赖 rsync 的模式匹配语义，
# 而 macOS 的 openrsync 与 GNU rsync 结果不同（前者会连 .emacs.d/ 里的隐藏子文件一起捞），
# 且它只匹配第一层，starship.toml 永远同步不过去。这里改成显式清单，行为到处一致。
#
# 用法：
#   ./deploy.sh              # 覆盖部署（原文件先备份）
#   ./deploy.sh --link       # 建符号链接代替复制，之后 git pull 即生效
#   ./deploy.sh --dry-run    # 只打印会做什么
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODE=copy
DRY_RUN=0

while [ $# -gt 0 ]; do
  case "$1" in
    --link)    MODE=link ;;
    --copy)    MODE=copy ;;
    --dry-run|-n) DRY_RUN=1 ;;
    # 打印到第一行非注释为止，不写死行号：写死的范围会随文件改动越界。
    -h|--help)
      sed -n '2,/^[^#]/p' "$0" | sed '$d' | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *) echo "未知参数：$1" >&2; exit 2 ;;
  esac
  shift
done

# 仓库文件 → $HOME 下的目标路径。
# 用 `源:目标` 表示目标与源不同名；没有冒号时目标就是源本身。
FILES=(
  ".alias"
  ".bash_profile"
  ".bashrc"
  ".envv"
  ".gitconfig"
  ".gitignore"
  ".vimrc"
  ".zprofile"
  ".zshrc"
  "starship.toml:.config/starship.toml"
)

BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
BACKED_UP=0
BACKUP_DIR_CREATED=0

say()  { printf '%s\n' "$*"; }
run()  { if [ "$DRY_RUN" = 1 ]; then say "  [dry-run] $*"; else "$@"; fi; }

# 用到才建。顶层文件（.alias 之类）的 dirname 是 "."，走不到「顺带把父目录建出来」那条路，
# 所以备份目录必须自己保证存在，否则第一个备份就会因为目标目录不存在而失败。
ensure_backup_dir() {
  [ "$BACKUP_DIR_CREATED" = 1 ] && return 0
  run mkdir -p "$BACKUP_DIR"
  BACKUP_DIR_CREATED=1
}

say "仓库：$HERE"
say "模式：$MODE$([ "$DRY_RUN" = 1 ] && echo "（dry-run）")"
say ""

for entry in "${FILES[@]}"; do
  src_rel="${entry%%:*}"
  dst_rel="${entry#*:}"
  src="$HERE/$src_rel"
  dst="$HOME/$dst_rel"

  if [ ! -e "$src" ]; then
    say "跳过 ${src_rel}（仓库里没有）"
    continue
  fi

  # 内容已经一致就不动它，顺带让脚本可以反复跑
  if [ "$MODE" = copy ] && [ -f "$dst" ] && cmp -s "$src" "$dst"; then
    say "已是最新 $dst_rel"
    continue
  fi
  if [ "$MODE" = link ] && [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    say "已是最新 ${dst_rel}（符号链接）"
    continue
  fi

  # 顶层文件（.alias 之类）的 dirname 是 "."，不必也不该去 mkdir
  dst_dir="$(dirname "$dst_rel")"
  [ "$dst_dir" != "." ] && run mkdir -p "$HOME/$dst_dir"

  # 备份：仅当目标存在、且不是指向本仓库的符号链接（那是我们自己的产物，无需备份）
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
      :
    else
      ensure_backup_dir
      [ "$dst_dir" != "." ] && run mkdir -p "$BACKUP_DIR/$dst_dir"
      run cp -a "$dst" "$BACKUP_DIR/$dst_rel"
      BACKED_UP=1
      say "备份 $dst_rel → $BACKUP_DIR/$dst_rel"
    fi
  fi

  if [ "$MODE" = link ]; then
    run rm -f "$dst"
    run ln -s "$src" "$dst"
    say "链接 $dst_rel → $src"
  else
    run cp "$src" "$dst"
    say "部署 $dst_rel"
  fi
done

say ""
if [ "$BACKED_UP" = 1 ]; then
  if [ "$DRY_RUN" = 1 ]; then
    say "原文件将备份到：$BACKUP_DIR"
  else
    say "原文件已备份到：$BACKUP_DIR"
  fi
else
  say "没有文件需要备份。"
fi
say ""
say "注意：.vim / .emacs.d 不在这里处理，用 ./vim.sh 和 ./emacs.sh（它们建符号链接，不是复制）。"
