# 三國志V (san5) — Headless DOSBox Automation

Automate **Romance of the Three Kingdoms V** (威力加強版) on a virtual X display (`:99`) so agents or scripts can start the game and pass the CD-ROM **確認** (Confirm) dialog without a physical monitor.

## What this repo does

| Step | Action |
|------|--------|
| 1 | Mount game folder as `C:` and `D:` (CD-ROM) |
| 2 | Run `PLAY.BAT` → `SAN586.COM` → `MAIN.EXE` |
| 3 | Press **Enter** to advance intro screens |
| 4 | **Capture mouse** inside DOSBox, then click **確認** on the “insert CD” dialog |
| 5 | Game reaches the main menu |

See [docs/dosbox-gui-click-troubleshooting.md](docs/dosbox-gui-click-troubleshooting.md) for why Openbox and mouse capture matter (X11 cursor ≠ DOS mouse).

---

## Tools required

### System packages (Ubuntu/Debian)

```bash
sudo apt install -y \
  xvfb \
  x11vnc \
  openbox \
  dosbox \
  xdotool \
  scrot
```

| Package | Role |
|---------|------|
| **Xvfb** | Virtual framebuffer display `:99` (no real monitor) |
| **openbox** | Window manager — focus so input reaches DOSBox |
| **x11vnc** | View/control the display over VNC (optional for humans) |
| **dosbox** | DOS emulator (0.74-3) |
| **xdotool** | Focus windows, keys, and X11 mouse (capture + click sequence) |
| **scrot** | Screenshots for debugging (`/tmp/san5_after_start.png`) |

### Game files

Install the game under a fixed path (default in `start.sh`):

```text
/home/chenchen/Games/san5/
```

Must include `PLAY.BAT`, `MAIN.EXE`, `SAN586.COM`, and data files. Edit `SAN5=` in `start.sh` if your path differs.

### DOSBox config

Uses `~/.dosbox/dosbox-0.74-3.conf`. Important settings:

```ini
[sdl]
autolock=true    # first click inside window captures mouse for the game
```

Do **not** send **Ctrl+F10** before automating clicks — that **unlocks** the mouse. A dedicated **capture click** in the center of the window is required before clicking UI buttons.

---

## Display stack

Typical startup (manual or scripted):

```bash
# 1. Virtual display
Xvfb :99 -screen 0 1024x768x24 &

# 2. Window manager (required for reliable focus)
DISPLAY=:99 openbox &

# 3. VNC (optional — watch from another machine)
x11vnc -display :99 -forever -shared -passwd YOUR_PASSWORD &

# 4. Game + automation
cd /home/chenchen/code/san5
./start.sh
```

All automation scripts use `DISPLAY=:99` (or `$DISPLAY` if already set).

---

## Passing the confirmation screen

The game shows a dialog:

> 請將三國志V 威力加強版 光碟片放入光碟機。

with a green **確認** button. Keyboard **Enter** often does **not** work on this dialog; the **DOS mouse** must be used after capture.

### Automation flow (`start.sh`)

1. `killall dosbox` — one instance only  
2. Start **openbox** on `:99` if not running  
3. Start **DOSBox** with:

   ```text
   mount c /home/chenchen/Games/san5
   mount d /home/chenchen/Games/san5 -t cdrom
   c:
   play
   ```

4. Wait ~8 seconds  
5. **Enter** — advance from intro (OPEN → MAIN → dialog)  
6. **`scripts/click-dosbox.sh`** — pass **確認**

### Why `click-dosbox.sh` uses two clicks

DOSBox with `autolock=true` only routes mouse input to the game after a **capture click** inside the 800×600 client:

1. **Capture click** at center `(400, 300)` — enables DOS mouse  
2. **Target click** at `(400, 320)` — **確認** button (default coords for 800×600 window)

```bash
DISPLAY=:99 ./scripts/click-dosbox.sh          # default 確認 position
DISPLAY=:99 ./scripts/click-dosbox.sh 400 320  # explicit coordinates
```

Custom capture point:

```bash
CAPTURE_X=400 CAPTURE_Y=300 DISPLAY=:99 ./scripts/click-dosbox.sh 400 320
```

### Keyboard fallback

If mouse automation fails, try:

```bash
DISPLAY=:99 ./scripts/confirm-dosbox.sh   # sends Return to DOSBox window
```

This works on some screens but **not** reliably on the CD **確認** dialog.

---

## Quick start

```bash
# Install tools (once)
sudo apt install xvfb x11vnc openbox dosbox xdotool scrot

# Start display + WM (if not already running)
Xvfb :99 -screen 0 1024x768x24 &
DISPLAY=:99 openbox &

# Run game and pass confirmation
cd /home/chenchen/code/san5
chmod +x start.sh scripts/*.sh
./start.sh
```

Check result:

```bash
display /tmp/san5_after_start.png   # or open via VNC
```

---

## Scripts

| Script | Purpose |
|--------|---------|
| `start.sh` | Full launch: mounts, `play`, Enter, capture+click **確認**, screenshot |
| `scripts/click-dosbox.sh` | Capture click + click at coordinates (pass **確認** or other UI) |
| `scripts/confirm-dosbox.sh` | Send **Return** only (fallback) |

---

## Playing the game after automation

After **確認**, the main menu appears. Further play can use:

- **Same pattern**: `click-dosbox.sh <x> <y>` for each menu item (capture click runs every time unless you keep mouse captured)  
- **Keyboard**: `xdotool key` for menus that accept keys  
- **VNC**: connect to `x11vnc` and use a real mouse (capture still applies on first click)

Mounting `D:` as the same folder with `-t cdrom` satisfies the “insert disc” check for this install; for other setups you may need a real `.iso` on `D:`.

---

## Troubleshooting

| Problem | Check |
|---------|--------|
| Click does nothing | Openbox running? One DOSBox only? Run capture click before button (see `click-dosbox.sh`) |
| Sent Ctrl+F10 | That **unlocks** mouse — remove it from automation |
| `autolock=false` | Set `autolock=true` in `dosbox.conf` and restart DOSBox |
| Two DOSBox windows | `killall dosbox` then run `start.sh` once |
| Cursor moves but game ignores | X11 cursor ≠ DOS mouse — see [docs/dosbox-gui-click-troubleshooting.md](docs/dosbox-gui-click-troubleshooting.md) |
| ALSA errors | Harmless on headless; ignore or use `SDL_AUDIODRIVER=dummy` |

---

## License / game files

Game assets are not included in this repo. You must own/install 三國志V separately under `SAN5` path above.
