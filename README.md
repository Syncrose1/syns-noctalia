# Syn's Noctalia

My Hyprland + [Noctalia](https://noctalia.dev) setup for CachyOS, as a thin layer on top of
CachyOS's own `cachyos-hypr-noctalia` config, so upstream improvements keep flowing in.

```sh
curl -fsSL https://raw.githubusercontent.com/Syncrose1/syns-noctalia/main/install.sh | bash
```

Everything it replaces is backed up first, and every step asks before acting.
Options go after `bash -s --`:

```sh
curl -fsSL https://raw.githubusercontent.com/Syncrose1/syns-noctalia/main/install.sh | bash -s -- --dry-run
```

| Option | |
|---|---|
| `--dry-run` | Show what would happen, change nothing |
| `--yes` | Accept every default without asking |
| `--no-packages` | Skip package installation |
| `--uninstall` | Restore a backup (defaults to your setup from before the first install) |

## What you get

**Keys**
- Tap **Super** for the launcher (Super+Space also works)
- **Super+1…0**: workspace 1–10 · **Super+Shift+N**: move window there · **Super+Alt+N**: send it without following
- **Super+Shift+S**: screenshot. Drag to crop, or click a window (grimblast); saved to `~/Pictures/Screenshots` and copied
- **Super+Shift+T**: OCR. Drag a region (or click a window) and its text is copied to the clipboard; offline via tesseract, no API key
- **Ctrl+Super+T**: wallpaper picker
- **Ctrl+Alt+Delete**: session menu (lock, log out, suspend, reboot, shut down)
- **Super+Alt+S**: send window to the scratchpad (Super+S shows it)
- Super+scroll switches workspaces

**Desktop**
- Workspaces always visible and split across monitors (per machine, see below)
- Scroll on the empty left half of the bar for brightness, right half for volume
- External monitor brightness over DDC/CI
- Monitor utility: **Monitor Settings** in the launcher (nwg-displays; also found by "display", "nwg", "resolution") to drag monitors around and set resolution, refresh rate, scale and rotation. It asks to keep the change and reverts otherwise; the layout is saved to `~/.config/hypr/monitors.lua`, which loads last
- Flush bar, Inter font, slim workspace dots, quiet status icons that reveal on hover
- Dolphin tiles; Qt/KDE apps follow Noctalia's colours (`QT_QPA_PLATFORMTHEME=kde`)
- UK keyboard, normal pointer acceleration
- Kitty at 85% opacity: **Ctrl+Alt+↑/↓** to adjust, **Ctrl+Alt+0** to reset; closes without confirming

## How it's layered

| Owner | Files |
|---|---|
| CachyOS (stock, refreshed from `/etc/skel`) | `~/.config/hypr/config/*.lua`, `kitty/cachyos.conf`, `uwsm/env.cachyos`, `noctalia/config.toml` |
| This repo | `~/.config/hypr/hyprland.lua`, `~/.config/hypr/user/`, `kitty/kitty.conf`, `uwsm/env`, Noctalia's `settings.toml`, `~/.local/bin/{bar-scroll,ocr-region,sync-cachyos-config}` |
| Noctalia (generated) | `~/.config/hypr/noctalia.lua`, `kitty/themes/noctalia.conf` |
| Monitor utility (per machine) | `~/.config/hypr/monitors.lua`, `~/.config/hypr/workspaces.lua` |

`hyprland.lua` loads CachyOS's modules in their stock order, then `user/shared.lua` (every machine),
then `user/hosts/<hostname>.lua` (this machine's monitors and workspaces). Later settings win, so the
stock files never need editing.

When `cachyos-hypr-noctalia` updates, a pacman hook reminds you to run:

```sh
sync-cachyos-config           # see what CachyOS changed
sync-cachyos-config --apply   # take it; your layer stays on top
```

## New machine

The installer creates `user/hosts/<hostname>.lua` from the detected monitors (run it from inside
Hyprland for that). Tweak modes, positions and scale there, then copy it into this repo's
`files/hypr/user/hosts/` so it's restored next time.

## Requirements

CachyOS (or the CachyOS repos) for `cachyos-hypr-noctalia`. The installer adds `grimblast-git`,
`inter-font`, `jq`, `bc`, `tesseract`, `tesseract-data-eng`, `imagemagick` and `nwg-displays`, using `pacman -S --needed` (no full system upgrade).
