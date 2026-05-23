#!/usr/bin/env bash
set -euo pipefail

ENV_FILE="${HOME}/.config/bloodsiren/hub-ports.env"
[[ -f "$ENV_FILE" ]] && source "$ENV_FILE"
HUB_PORT_BLOOD="${HUB_PORT_BLOOD:-}"
HUB_PORT_SIREN="${HUB_PORT_SIREN:-}"

check_port() {
  local port="$1"
  local label="$2"
  local tracks="$3"

  for path in /dev/snd/by-path/*"usb-0:${port}"*:1.1; do
    [[ -e "$path" ]] || continue
    local card_num card_id
    card_num=$(basename "$(readlink -f "$path")" | sed 's/controlC//')
    card_id=$(cat "/sys/class/sound/card${card_num}/id")
    echo "PRESENT  hub port ${port}  card ${card_num} (${card_id})  -> tracks ${tracks}  [${label}]"
    return 0
  done

  echo "EMPTY    hub port ${port}  -> tracks ${tracks}  [${label}]"
}

HIFI_USB_COUNT=0
while IFS= read -r _; do
  HIFI_USB_COUNT=$((HIFI_USB_COUNT + 1))
done < <(lsusb -d 152a:893a 2>/dev/null || true)

echo "USB HIFI AUDIO unit map"
echo "======================="
echo "Thesycon HIFI on USB bus: ${HIFI_USB_COUNT} (need 2 for 8 inputs)"
if [[ "$HIFI_USB_COUNT" -lt 2 ]]; then
  echo "  -> Only blood (tracks 1-4) until a second 152a:893a unit enumerates."
fi
echo
echo "Config: ${ENV_FILE}"
echo "  HUB_PORT_BLOOD=${HUB_PORT_BLOOD}  (tracks 1-4, playback)"
if [[ -n "$HUB_PORT_SIREN" ]]; then
  echo "  HUB_PORT_SIREN=${HUB_PORT_SIREN}  (tracks 5-8)"
else
  echo "  HUB_PORT_SIREN=(empty)  (tracks 5-8 when second unit plugged)"
fi
echo
[[ -n "$HUB_PORT_BLOOD" ]] && check_port "$HUB_PORT_BLOOD" "blood" "1-4" || echo "UNSET    hub port (blood)  -> run detect-hub-ports.sh"
[[ -n "$HUB_PORT_SIREN" ]] && check_port "$HUB_PORT_SIREN" "siren" "5-8" || echo "SKIPPED  siren port empty — 4 inputs only"
echo
other_usb=$(lsusb 2>/dev/null | grep -iE 'audio|sound' | grep -vi '152a:893a' || true)
if [[ -n "$other_usb" ]]; then
  echo "Other USB audio (not blood/siren — ignored by this setup):"
  while IFS= read -r line; do
    [[ -n "$line" ]] && echo "  $line"
  done <<< "$other_usb"
  echo
fi
echo "Wrong ports or still 4 inputs with both HIFI plugged? Run: scripts/detect-hub-ports.sh"
