#!/bin/bash
set -euo pipefail
if [ $# -lt 2 ]; then
  echo "usage: set-theme.sh <N> <theme|none>   e.g. set-theme.sh 3 sakura" >&2
  node "$HOME/.claude-instances/theme/apply-theme.mjs" 2>&1 | tail -1 >&2 || true
  exit 2
fi
command -v node >/dev/null || { echo "node is required for themes (brew install node)" >&2; exit 1; }
node "$HOME/.claude-instances/theme/apply-theme.mjs" "$HOME/.claude-instances/claude$1" "$2"
