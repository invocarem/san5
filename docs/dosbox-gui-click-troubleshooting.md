# DOSBox GUI Button Click Troubleshooting

## The main lesson: X11 cursor ≠ DOSBox mouse

**These are not the same thing.** Confusing them is why automation looked like it “almost worked.”

| | X11 cursor | DOSBox / DOS mouse |
|---|------------|-------------------|
| **What it is** | Linux desktop pointer on display `:99` | Emulated mouse inside DOS (INT 33h) that the game reads |
| **Who moves it** | `xdotool`, VNC, Openbox | DOSBox SDL layer, after X11 events are translated |
| **What you see** | White arrow in VNC/screenshots | Often a different in-game sprite, or hidden until captured |
| **What we controlled** | Yes — `mousemove` places the arrow on **確認** | **No** — the game did not react to our clicks |

`xdotool` moves the **X11 cursor only**. It does **not** directly set the DOS mouse position or send a DOS button press. Openbox helps **window focus**; it does **not** merge the two cursors.

Until the **DOS mouse is captured**, X11 clicks may not reach the game. Putting the X11 arrow on the button **proves nothing** if capture was never enabled.

### Mouse capture (what we should have tried first)

With `autolock=true` (DOSBox default), the **first click inside the client** enables mouse capture (DOS mouse active). **Ctrl+F10 unlocks** — sending it before clicking was wrong in our script.

**Working sequence** (`scripts/click-dosbox.sh`):

1. `windowactivate` on the 800×600 DOSBox client  
2. `mousemove` + `click` at **center** of client (capture click)  
3. `sleep 0.25`  
4. `mousemove` + `click` on **確認** (or other target)

We had tried bare `xdotool click` on the button and `Ctrl+F10` (unlock). We had **not** tried a dedicated capture click first until later. That test advanced past the CD dialog to the game menu.

---

This document records attempts to click **確認** on a headless `:99` setup, what failed, and what might actually work.

## Environment

| Component | Configuration |
|-----------|---------------|
| Virtual display | `Xvfb :99 -screen 0 1024x768x24` |
| Remote view | `x11vnc -display :99 -forever -shared -passwd …` |
| Emulator | DOSBox 0.74-3, window ~800×600 at offset (192, 184) |
| Game | 三國志V 威力加強版 — CD-insert prompt dialog |
| Automation target | `DISPLAY=:99` (not the VNC client) |

Game files live under `/home/chenchen/Games/san5/`. DOSBox was started with **stdin connected to `/dev/null`**, so shell piping into the process is not an option.

## What We Saw On Screen

- Blue patterned background (Koei-style title screen).
- Center dialog (Traditional Chinese): *請將三國志V 威力加強版 光碟片放入光碟機。*
- Single green **確認** button below the text.
- Estimated button center (screen coordinates on `:99`): **(591, 503)** (in window-relative coords for an 800×600 client: about **(399, 319)**).

The dialog appears because the game expects a CD-ROM (威力加強版 disc); clicking Confirm without a mounted CD may dismiss and re-show the same prompt, which can look like “click did nothing.”

## What We Tried

### Worked

| Tool | Purpose |
|------|---------|
| `DISPLAY=:99 scrot /tmp/screen.png` | Capture framebuffer for visual verification |
| `DISPLAY=:99 xwd -root` | Raw root window capture (convert to PNG if ImageMagick available) |
| `DISPLAY=:99 xwininfo -root -tree` | List windows; found DOSBox `0xc00008` |
| `DISPLAY=:99 xdotool search --name DOSBox getwindowgeometry` | Window ID, position, size |
| `DISPLAY=:99 xdotool mousemove 592 504` | **Moved the visible cursor** on `:99` (confirmed in before/after screenshots) |
| Python + Pillow on PNG | Sample pixels / estimate button region (~y 496–511, x ~531–652) |

### Failed or Unreliable

| Action | Result |
|--------|--------|
| `xdotool click 1` at button coordinates | Cursor moved; **dialog unchanged** — game did not act on click |
| `xdotool mousemove --window … click 1` | Same — pointer position updates, no in-game response |
| `xdotool windowactivate` / `windowfocus` | **Aborted**: *windowmanager claims not to support _NET_ACTIVE_WINDOW* |
| `xdotool key --window … Return` | Command hung a long time (session interrupted); no confirmed dialog change |
| Keyboard via `/proc/<pid>/fd/0` | **Not possible** — fd 0 is `/dev/null` |
| `python-xlib` + `XSetInputFocus` | Package not installed; `sudo apt install` blocked (no passwordless sudo) |

## Why the Mouse Is Not “Accessible” With the Current Stack

“Mouse not accessible” means: **we could move the X11 cursor, but not the DOSBox mouse the game uses.** Several layers sit between them:

### 1. No window manager on Xvfb

The setup is **Xvfb + x11vnc only** — no Openbox, XFCE, `twm`, etc.

- Root window has **no** `_NET_SUPPORTED` / `_NET_SUPPORTING_WM_CHECK` (EWMH not present).
- `xdotool windowactivate` / `windowfocus` **fails** because nothing implements `_NET_ACTIVE_WINDOW`.
- Without a focused top-level window, many X clients (including SDL-based DOSBox) **ignore or do not route** mouse button events into the application, even when the cursor is drawn on top of the window.

**Pointer motion ≠ focused input.** `xdotool` uses the XTest extension to move the global cursor; that is visible in screenshots. **Button events** are typically delivered to the **focused** window. With no WM and no successful focus change, presses may go nowhere useful from DOSBox’s point of view.

### 2. DOSBox input path (X11 → SDL → emulated DOS mouse)

DOSBox draws one X11 window and, inside the emulator, exposes a **DOS mouse** (INT 33h) to the game. That chain normally requires:

1. X11 focus on the DOSBox window  
2. SDL receiving `ButtonPress` / `ButtonRelease`  
3. DOSBox updating emulated mouse state  
4. The game polling DOS mouse APIs  

Automation that only moves the X cursor without establishing focus breaks at step 1–2.

### 3. No stdin control of DOSBox

Process inspection showed:

```text
/proc/<dosbox-pid>/fd/0 -> /dev/null
```

So you cannot `echo` keys or commands into DOSBox from the shell. All UI automation must go through **X11** (or DOSBox extras like serial/socket if configured in `dosbox.conf`).

### 4. VNC is for humans, not for injection

`x11vnc` mirrors display `:99`; it does not replace `DISPLAY=:99` automation. Scripts must set `DISPLAY=:99` and use `xdotool` / Xlib on that display. Clicking inside a VNC viewer on another machine is a separate path and was not used here.

### 5. Possible “success” that looks like failure

If Confirm is clicked but **no CD is mounted**, the game may show the same CD prompt again. Always verify with screenshots and, when testing clicks, mount the disc first so the UI can advance.

## Tools Needed (Recommended)

### Minimum for observation

- `scrot` or `xwd` (+ ImageMagick `convert` optional) — screenshots  
- `xwininfo`, `xdotool` — window geometry and input attempts  

### Minimum for reliable GUI automation on `:99`

| Tool | Role |
|------|------|
| **Window manager** (`openbox`, `twm`, or full `xfce4` as in other project scripts) | Implements focus, `_NET_ACTIVE_WINDOW`, sane stacking |
| `xdotool` | After WM: `windowactivate` → `mousemove` → `click` or `key Return` |
| `python3-xlib` (optional) | Programmatic `XSetInputFocus` + XTest if you want focus without a full desktop |

Example bring-up order:

```bash
Xvfb :99 -screen 0 1024x768x24 &
DISPLAY=:99 openbox &          # or twm / xfce4-session
sleep 1
DISPLAY=:99 dosbox … &
# then automate
DISPLAY=:99 xdotool search --name DOSBox windowactivate --sync
DISPLAY=:99 xdotool mousemove --window <id> 399 319 click 1
```

### Alternatives if X11 clicking stays painful

- **Keyboard**: `xdotool key --window <id> Return` or `space` — often maps to default dialog button; still needs focus (WM helps).  
- **DOSBox serial / socket** (if enabled in config): send commands without X11.  
- **Game automation at DOS level**: not applicable to arbitrary GUI dialogs without a harness.  
- **Mount CD before UI** (`mount d … -t cdrom` in DOSBox): avoids blocking on the insert-disc dialog during tests.

## Diagnostic Checklist

Use this order when debugging “click did nothing”:

1. **Screenshot** — `DISPLAY=:99 scrot …` — is the dialog still the same?  
2. **Window tree** — `xwininfo -root -tree` — is DOSBox the only client? Note window ID.  
3. **WM present?** — `xprop -root _NET_SUPPORTED` — if missing, fix focus before blaming coordinates.  
4. **Focus** — `xdotool getwindowfocus` — does it match DOSBox’s ID after `windowactivate`?  
5. **Cursor** — two screenshots; did the pointer move onto the button?  
6. **Click** — screen coords vs `--window` relative coords (window origin + button offset).  
7. **Game state** — is CD mounted? Does Confirm only loop the same message?  
8. **stdin** — `ls -l /proc/<pid>/fd/0` — if `/dev/null`, do not plan shell stdin injection.

## Summary

| Question | Answer |
|----------|--------|
| Can we see the display? | **Yes** — `scrot` / `xwd` on `DISPLAY=:99`. |
| Can we find the button? | **Yes** — screenshots + geometry (~591, 503). |
| Can we move the mouse? | **Yes** — `xdotool mousemove` updates the visible cursor. |
| Can we move the X11 cursor onto the button? | **Yes** |
| Can we click the button **in the game** (DOS mouse)? | **Yes**, after **capture click** inside client + Openbox focus (not X11 cursor alone) |
| Did Openbox fix mouse? | **Partial** — focus required; capture click bridges X11 → DOS mouse |
| Wrong things we tried | `Ctrl+F10` before click (unlocks), `autolock=false`, button-only click without capture |

## References in This Repo / Machine

- DOSBox config: `~/.dosbox/dosbox-0.74-3.conf`  
- Game path: `/home/chenchen/Games/san5/`  
- Related VNC stack (includes XFCE + xdotool): `~/.openclaw/workspace/skills/computer-use/scripts/setup-vnc.sh` — that path installs a WM; the minimal `Xvfb` + `x11vnc`-only setup does not.

---

*Document generated from a troubleshooting session: DOSBox on `DISPLAY=:99`, dialog 確認 button, automation via `xdotool` without a window manager.*
