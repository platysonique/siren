#!/usr/bin/env bash
set -euo pipefail

for card in /proc/asound/card*; do
  [[ -d "$card" ]] || continue
  id="$(cat "$card/id" 2>/dev/null || true)"
  case "$id" in
    AUDIO*|*HIFI*|*hifi*) ;;
    *) continue ;;
  esac
  echo "== ${card##*/} id=$id =="
  find "$card" -path '*pcm*p/sub*/status' -print -exec sh -c 'echo "--- $1"; cat "$1"' _ {} \; || true
done

