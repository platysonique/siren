#!/usr/bin/env bash
# Create github.com/platysonique/siren and push main. Requires: gh auth login
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

GH="${GH:-gh}"
if ! command -v "$GH" >/dev/null; then
  echo "Install gh: sudo apt install gh   OR use /tmp/gh from publish flow"
  exit 1
fi

"$GH" auth status >/dev/null

git remote remove origin 2>/dev/null || true
"$GH" repo create siren --public \
  --description "Dual USB HIFI 8ch judge recording — Waveform on Linux (blood + siren)" \
  --source=. --remote=origin --push

echo
echo "Done: https://github.com/platysonique/siren"
