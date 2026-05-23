#!/usr/bin/env bash
set -euo pipefail

echo "== /dev/snd/by-path =="
ls -l /dev/snd/by-path || true
echo

echo "== cards =="
cat /proc/asound/cards || true
echo

echo "== USB HIFI AUDIO cards =="
for c in /proc/asound/card*/id; do
  [[ -e "$c" ]] || continue
  card="${c%/id}"
  card="${card##*/card}"
  id="$(tr -d '[:space:]' < "$c")"
  long="$(cat "/proc/asound/card${card}/usbid" 2>/dev/null || true)"
  echo "card $card id=$id usbid=$long"
done

