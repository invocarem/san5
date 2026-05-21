#!/usr/bin/env bash
# Click in DOSBox after mouse capture (autolock): focus, capture click, then target click.
# Usage: click-dosbox.sh [target_x target_y]   (default ≈ 確認 button on 800x600 client)
set -euo pipefail

export DISPLAY="${DISPLAY:-:99}"

TARGET_X="${1:-400}"
TARGET_Y="${2:-320}"
# Center of 800x600 client — click here first to enable mouse capture (autolock=true)
CAPTURE_X="${CAPTURE_X:-400}"
CAPTURE_Y="${CAPTURE_Y:-300}"

find_dosbox_client() {
  local w width height
  for w in $(xdotool search --class dosbox 2>/dev/null); do
    eval "$(xdotool getwindowgeometry --shell "$w")"
    if [[ "$WIDTH" == "800" && "$HEIGHT" == "600" ]]; then
      echo "$w"
      return 0
    fi
  done
  xdotool search --name "DOSBox" 2>/dev/null | tail -1
}

CLIENT=$(find_dosbox_client)
[[ -n "$CLIENT" ]] || { echo "error: no DOSBox window on $DISPLAY" >&2; exit 1; }

xdotool windowactivate --sync "$CLIENT" 2>/dev/null || true
sleep 0.15

# Step 1: click inside window to turn ON mouse capture (do not send Ctrl+F10 — that unlocks)
xdotool mousemove --window "$CLIENT" "$CAPTURE_X" "$CAPTURE_Y"
sleep 0.05
xdotool click --window "$CLIENT" --clearmodifiers 1
sleep 0.25

# Step 2: move DOS mouse to target and click (e.g. 確認)
xdotool mousemove --window "$CLIENT" "$TARGET_X" "$TARGET_Y"
sleep 0.05
xdotool click --window "$CLIENT" --clearmodifiers 1

echo "capture-click at ${CAPTURE_X},${CAPTURE_Y} then click at ${TARGET_X},${TARGET_Y} (client=$CLIENT)"
