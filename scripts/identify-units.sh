#!/usr/bin/env bash
set -euo pipefail

ENV_FILE="${HOME}/.config/bloodsiren/hub-ports.env"
[[ -f "$ENV_FILE" ]] && source "$ENV_FILE"
HUB_PORT_BLOOD="${HUB_PORT_BLOOD:-2.3}"
HUB_PORT_SIREN="${HUB_PORT_SIREN:-2.2}"

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

echo "USB HIFI AUDIO unit map"
echo "======================="
echo "Config: ${ENV_FILE}"
echo "  HUB_PORT_BLOOD=${HUB_PORT_BLOOD}  (tracks 1-4, playback)"
echo "  HUB_PORT_SIREN=${HUB_PORT_SIREN}  (tracks 5-8)"
echo
check_port "$HUB_PORT_BLOOD" "blood" "1-4"
check_port "$HUB_PORT_SIREN" "siren" "5-8"
echo
echo "Wrong ports? Run: scripts/detect-hub-ports.sh"
