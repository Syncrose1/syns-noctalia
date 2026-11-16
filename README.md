# Syn's Noctalia

My Hyprland + [Noctalia](https://noctalia.dev) setup for CachyOS, as a thin layer on top of
CachyOS's own `cachyos-hypr-noctalia` config, so upstream improvements keep flowing in.

```sh
curl -fsSL https://raw.githubusercontent.com/Syncrose1/syns-noctalia/main/install.sh | bash
```

Everything it replaces is backed up first, and every step asks before acting.

**Already installed?** Run the same command any time and it opens a menu instead:
change the lock screen theme (preview, switch, or download more), update / reinstall,
pull CachyOS's latest defaults, arrange monitors, show the keyboard shortcuts, or restore a backup.

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
- **Super+L**: lock (qylock, see below)
- **Ctrl+Alt+Delete**: session menu (lock, log out, suspend, reboot, shut down)
- **Super+Alt+S**: send window to the scratchpad (Super+S shows it)
- Super+scroll switches workspaces

**Desktop**
- Workspaces always visible and split across monitors (per machine, see below)
- Scroll on the empty left half of the bar for brightness, right half for volume
- External monitor brightness over DDC/CI
- Monitor utility: **Monitor Settings** in the launcher (nwg-displays; also found by "display", "nwg", "resolution") to drag monitors around and set resolution, refresh rate, scale and rotation. It asks to keep the change and reverts otherwise; the layout is saved to `~/.config/hypr/monitors.lua`, which loads last
- Flush bar, Inter font, quiet status icons that reveal on hover; workspaces alone in the centre as rounded boxes showing each workspace's app icons (active one outlined in the accent colour), and the window title on the left so they never shift
- Dolphin tiles; Qt/KDE apps follow Noctalia's colours (`QT_QPA_PLATFORMTHEME=kde`)
- UK keyboard, normal pointer acceleration
- AI Usage in the bar (Claude Code, SuperGrok, …) via the `ai-usagebar` plugin; display profiles via the `nwg-displays` plugin (`/nwg` in the launcher)
- Video and GIF wallpapers via the `mpvpaper` plugin (film icon on the bar): drop files into `~/Pictures/Wallpapers`, shared with still wallpapers. Pauses when covered; slideshows supported. The installer can copy in the video wallpapers from a Wallpaper Engine library
- Kitty at 85% opacity: **Ctrl+Alt+↑/↓** to adjust, **Ctrl+Alt+0** to reset; closes without confirming

## Lock screen

Animated lock screens from [**qylock**](https://github.com/Darkkal44/qylock) by Darkkal44 (GPL-3.0),
downloaded from upstream at a pinned commit during install. Only the themes you choose are fetched;
the defaults are Clockwork (orbital dial with windup), Pixel Sakura, Enfield and Pixel Rainy Room.

```sh
lock-theme                     # list installed themes (current one marked)
lock-theme pixel-sakura        # switch; partial names like "clockwork" work
lock-theme --preview enfield   # preview in a window without locking
```

Additions on top of upstream (`files/qylock/`):
- **Fade-to-desktop unlock**: each monitor is snapshotted (privately, in memory) just before
  locking, and after a correct password the lock fades into it, so the real unlock is seamless.
  Snapshots are deleted straight after and never shown before authentication.
- **Emergency fallback**: if a theme fails to load, a plain password screen appears instead of a
  black one, so you can always unlock.
- `lock-screen` validates the theme, force-closes a lock that hangs after unlocking, and never
  waits on a screenshot (1s limit).

Super+L, the session menu, Noctalia's idle actions and sleep all go through
`loginctl lock-session`, which hypridle turns into `lock-screen`. Noctalia's own lock is disabled
(declining qylock in the installer keeps it instead). If anything ever goes wrong while locked:
Ctrl+Alt+F3, log in, run `hyprctl --instance 0 dispatch 'hl.dsp.exec_cmd("~/.local/bin/lock-screen")'`,
then Ctrl+Alt+F1.

## How it's layered

| Owner | Files |
|---|---|
| CachyOS (stock, refreshed from `/etc/skel`) | `~/.config/hypr/config/*.lua`, `kitty/cachyos.conf`, `uwsm/env.cachyos`, `noctalia/config.toml` |
| This repo | `~/.config/hypr/hyprland.lua`, `~/.config/hypr/user/`, `kitty/kitty.conf`, `uwsm/env`, Noctalia's `settings.toml`, `~/.config/hypr/hypridle.conf`, `~/.local/bin/{bar-scroll,ocr-region,lock-screen,lock-theme,sync-cachyos-config}` |
| qylock (upstream + patch) | `~/.local/share/quickshell-lockscreen`, `~/.local/share/qylock/themes`, `~/.config/qylock/theme` |
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
`inter-font`, `jq`, `bc`, `tesseract`, `tesseract-data-eng`, `imagemagick`, `nwg-displays`, `hypridle`,
`git`, `quickshell` and the Qt/GStreamer video packages qylock needs, using `pacman -S --needed`
(no full system upgrade). Optionally from the AUR with paru or yay: `ai-usagebar-bin`.

## Credits

- [qylock](https://github.com/Darkkal44/qylock) by Darkkal44, GPL-3.0. `files/qylock/` patches it; see its gallery for theme previews and wallpaper credits.
- [Noctalia](https://noctalia.dev), [CachyOS](https://cachyos.org)'s `cachyos-hypr-noctalia`, and the plugin authors (felipeartur/ai-usagebar, micahg/nwg-displays, mpvpaper).
