#!/usr/bin/env bash
# Start 三國志V on virtual display :99 (Xvfb + Openbox + DOSBox).
set -euo pipefail

export DISPLAY="${DISPLAY:-:99}"
SAN5="/home/chenchen/Games/san5"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# One DOSBox only
killall dosbox 2>/dev/null || true
sleep 0.5

pgrep -f "openbox" >/dev/null || DISPLAY=:99 openbox &
sleep 0.5

DISPLAY=:99 dosbox \
  -c "mount c ${SAN5}" \
  -c "mount d ${SAN5} -t cdrom" \
  -c "c:" \
  -c "play" &

echo "waiting for game..."
sleep 8

WIN=$(DISPLAY=:99 xdotool search --class dosbox | tail -1)
DISPLAY=:99 xdotool windowactivate --sync "$WIN"
DISPLAY=:99 xdotool key --window "$WIN" --clearmodifiers Return
sleep 3

# Try mouse click on 確認; fall back to keyboard
if ! "${SCRIPT_DIR}/scripts/click-dosbox.sh" 400 320; then
  echo "click script failed, using Return"
  "${SCRIPT_DIR}/scripts/confirm-dosbox.sh"
fi

DISPLAY=:99 scrot /tmp/san5_after_start.png
echo "screenshot: /tmp/san5_after_start.png"
