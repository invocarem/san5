#!/usr/bin/env bash
# Press Enter on the focused DOSBox window (works when mouse click does not).
set -euo pipefail
export DISPLAY="${DISPLAY:-:99}"

mapfile -t WINS < <(xdotool search --class dosbox 2>/dev/null || true)
[[ ${#WINS[@]} -gt 0 ]] || { echo "error: no DOSBox window" >&2; exit 1; }
WIN="${WINS[-1]}"

xdotool windowactivate --sync "$WIN"
xdotool key --window "$WIN" --clearmodifiers Return
