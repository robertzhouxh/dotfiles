#!/usr/bin/env bash
# 把门禁测试接到 pre-commit。每台新机器上跑一次即可。
#
# 刻意不用 `git config core.hooksPath`：那会连带接管 .git/hooks 下的其他钩子，
# 而且这个仓库本身是 dotfiles，不动全局 git 配置更稳。
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"

GIT_DIR="$(git -C "$REPO" rev-parse --git-dir 2>/dev/null)" \
  || { echo "错误：$REPO 不是 git 仓库。" >&2; exit 1; }
case "$GIT_DIR" in
  /*) ;;
  *) GIT_DIR="$REPO/$GIT_DIR" ;;
esac

HOOK="$GIT_DIR/hooks/pre-commit"
mkdir -p "$(dirname "$HOOK")"

if [ -e "$HOOK" ] && ! grep -q 'run-tests.sh' "$HOOK" 2>/dev/null; then
  echo "警告：已存在 pre-commit（内容不是本仓库装的），备份为 pre-commit.bak"
  cp "$HOOK" "$HOOK.bak"
fi

cat > "$HOOK" <<'HOOK_BODY'
#!/usr/bin/env bash
# 由 test/install-hooks.sh 安装。跳过测试请先修好底层问题，不要用 --no-verify。
set -e
REPO="$(git rev-parse --show-toplevel)"
exec "$REPO/test/run-tests.sh"
HOOK_BODY

chmod +x "$HOOK"
echo "已安装：$HOOK"
echo "验证：cd $REPO && test/run-tests.sh"
