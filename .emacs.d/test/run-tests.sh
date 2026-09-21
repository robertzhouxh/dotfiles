#!/usr/bin/env bash
# 门禁测试运行器：确定性、本地、免费、<2 秒、永不 flaky。
# 用法：.emacs.d/test/run-tests.sh
# 覆盖 emacs 二进制：EMACS=/path/to/emacs test/run-tests.sh
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EMACS="${EMACS:-emacs}"

# -Q: 不加载任何用户 init，保证测试与本地配置状态无关。
exec "$EMACS" -Q --batch \
  -L "$HERE/../lisp" \
  -L "$HERE" \
  -l "$HERE/emacs-solo-brackets-test.el" \
  -l "$HERE/emacs-solo-lazycat-theme-test.el" \
  -l "$HERE/emacs-solo-markdown-test.el" \
  -f ert-run-tests-batch-and-exit
