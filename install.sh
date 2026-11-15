#!/usr/bin/env bash
# Syn's Noctalia: a thin personal layer over CachyOS's Hyprland + Noctalia setup.
#
#   curl -fsSL https://raw.githubusercontent.com/Syncrose1/syns-noctalia/main/install.sh | bash
#
# Options (pass after "bash -s --" when piping):
#   --yes          accept every default without asking
#   --dry-run      show what would happen, change nothing
#   --no-packages  skip installing packages
#   --uninstall    restore the configs from the most recent backup
#   --help         show this help
#
# Everything it replaces is backed up to ~/.local/state/syns-noctalia/backups/<timestamp>/ first.

set -euo pipefail

REPO="Syncrose1/syns-noctalia"
BRANCH="${SYNS_NOCTALIA_BRANCH:-main}"
STATE="$HOME/.local/state/syns-noctalia"
SKEL=/etc/skel
PACKAGES=(cachyos-hypr-noctalia grimblast-git inter-font jq bc tesseract tesseract-data-eng imagemagick nwg-displays
          hypridle git quickshell qt6-5compat qt6-multimedia qt6-multimedia-ffmpeg
          gst-plugins-good gst-plugins-bad gst-plugins-ugly gst-libav)
QYLOCK_REPO="https://github.com/Darkkal44/qylock.git"
QYLOCK_COMMIT="c2933f27b655a999911e6699e1b2c67e59cbd428"   # tested with the patch in files/qylock
QYLOCK_DEFAULT_THEMES="clockwork pixel-sakura enfield pixel-rainyroom"

YES=false DRY=false NOPKG=false UNINSTALL=false
usage() {
    cat <<'USAGE'
Syn's Noctalia installer

  curl -fsSL https://raw.githubusercontent.com/Syncrose1/syns-noctalia/main/install.sh | bash
  curl -fsSL .../install.sh | bash -s -- [options]

Options:
  --yes          accept every default without asking
  --dry-run      show what would happen, change nothing
  --no-packages  skip installing packages
  --uninstall    restore the configs from the most recent backup
  --help         show this help
USAGE
}
for arg in "$@"; do
    case "$arg" in
        --yes|-y) YES=true ;;
        --dry-run) DRY=true ;;
        --no-packages) NOPKG=true ;;
        --uninstall) UNINSTALL=true ;;
        --help|-h) usage; exit 0 ;;
        *) echo "Unknown option: $arg (try --help)"; exit 1 ;;
    esac
done

# ---------- output helpers ----------
if [ -t 1 ]; then B=$'\e[1m' D=$'\e[2m' G=$'\e[32m' Y=$'\e[33m' R=$'\e[31m' C=$'\e[36m' N=$'\e[0m'; else B= D= G= Y= R= C= N=; fi
step() { printf '\n%s==> %s%s\n' "$B$C" "$1" "$N"; }
info() { printf '    %s\n' "$1"; }
ok()   { printf '    %s✓%s %s\n' "$G" "$N" "$1"; }
warn() { printf '    %s!%s %s\n' "$Y" "$N" "$1"; }
die()  { printf '%sError:%s %s\n' "$R" "$N" "$1" >&2; exit 1; }

# Prompts read from the terminal, so they work under "curl ... | bash"
TTY=/dev/tty
ask() { # ask "Question" [default Y|N]
    local q=$1 def=${2:-Y} reply
    if $YES; then [ "$def" = Y ]; return; fi
    if [ ! -r "$TTY" ]; then [ "$def" = Y ]; return; fi
    local hint="[Y/n]"; [ "$def" = N ] && hint="[y/N]"
    printf '    %s?%s %s %s ' "$Y" "$N" "$q" "$hint" >"$TTY"
    read -r reply <"$TTY" || reply=""
    reply=${reply:-$def}
    [[ "$reply" =~ ^[Yy] ]]
}

run() { # run a command, or print it in dry-run mode
    if $DRY; then printf '    %s[dry-run]%s %s\n' "$D" "$N" "$*"; else "$@"; fi
}

# ---------- preflight ----------
[ "$(id -u)" -eq 0 ] && die "Run this as your normal user, not root (it uses sudo when needed)."
command -v pacman >/dev/null || die "This needs an Arch-based system with pacman (CachyOS recommended)."
command -v curl >/dev/null || die "curl is required."

# ---------- uninstall ----------
if $UNINSTALL; then
    step "Restoring your previous configs"
    mapfile -t backups < <(ls -1d "$STATE"/backups/*/ 2>/dev/null | sort)
    [ ${#backups[@]} -gt 0 ] || die "No backup found in $STATE/backups."
    # Default to the oldest backup: your setup from before Syn's Noctalia was first installed
    latest=${backups[0]%/}
    if [ ${#backups[@]} -gt 1 ] && ! $YES && [ -r "$TTY" ]; then
        info "Backups (one per install run):"
        for i in "${!backups[@]}"; do
            label=""; [ "$i" -eq 0 ] && label="  <- before the first install (default)"
            info "  $((i + 1))) $(basename "${backups[$i]}")$label"
        done
        printf '    %s?%s Restore which? [1] ' "$Y" "$N" >"$TTY"
        read -r pick <"$TTY" || pick=""
        if [[ "$pick" =~ ^[0-9]+$ ]] && [ "$pick" -ge 1 ] && [ "$pick" -le ${#backups[@]} ]; then
            latest=${backups[$((pick - 1))]%/}
        fi
    fi
    info "Backup: ${latest/#$HOME/~}"
    ask "Restore this backup over your current configs?" Y || exit 0
    while IFS= read -r rel; do
        [ -n "$rel" ] || continue
        run rm -rf "${HOME:?}/$rel"
        if [ -e "$latest/files/$rel" ]; then
            run mkdir -p "$(dirname "$HOME/$rel")"
            run cp -a "$latest/files/$rel" "$HOME/$rel"
        fi
        ok "$rel"
    done <"$latest/manifest"
    info "Packages and the pacman hook were left in place."
    command -v hyprctl >/dev/null && [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ] && run hyprctl reload >/dev/null
    printf '\n%sRestored.%s\n' "$G" "$N"
    exit 0
fi

printf '%sSyn'"'"'s Noctalia%s %s(CachyOS Hyprland + Noctalia, plus Syn'"'"'s layer)%s\n' "$B" "$N" "$D" "$N"
$DRY && warn "Dry run: nothing will be changed."

# ---------- get the repo files ----------
SRC=""
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || true)
if [ -n "$script_dir" ] && [ -d "$script_dir/files/hypr" ]; then
    SRC="$script_dir/files"
else
    TMP=$(mktemp -d)
    trap 'rm -rf "$TMP"' EXIT
    curl -fsSL "https://codeload.github.com/$REPO/tar.gz/refs/heads/$BRANCH" | tar -xz -C "$TMP" \
        || die "Could not download $REPO."
    SRC=$(echo "$TMP"/*/files)
fi

# ---------- packages ----------
step "Packages"
missing=()
for p in "${PACKAGES[@]}"; do pacman -Qq "$p" >/dev/null 2>&1 || missing+=("$p"); done
if [ ${#missing[@]} -eq 0 ]; then
    ok "All installed: ${PACKAGES[*]}"
elif $NOPKG; then
    warn "Skipping (--no-packages). Missing: ${missing[*]}"
else
    info "Missing: ${missing[*]}"
    if ! pacman -Si cachyos-hypr-noctalia >/dev/null 2>&1 && [[ " ${missing[*]} " == *" cachyos-hypr-noctalia "* ]]; then
        die "cachyos-hypr-noctalia isn't in your repos. This setup needs CachyOS (or the CachyOS repos)."
    fi
    info "Installed with 'pacman -S --needed' (no full system upgrade)."
    if ask "Install them now?" Y; then
        run sudo pacman -S --needed "${missing[@]}" || die "Package install failed. If pacman says a package is out of date, run 'sudo pacman -Syu' first, then re-run this."
        ok "Installed"
    else
        warn "Skipped. Some features won't work until these are installed."
    fi
fi

# AUR extras (need paru or yay)
aur_install() { # aur_install <package> <question>
    pacman -Qq "$1" >/dev/null 2>&1 && { ok "$1 already installed"; return; }
    if [ -z "${AUR:-}" ]; then warn "No AUR helper (paru/yay), so $1 was skipped."; return; fi
    if ask "$2" Y; then
        run "$AUR" -S --needed "$1" && ok "$1 installed" || warn "$1 failed to install"
    fi
}
if ! $NOPKG; then
    AUR=$(command -v paru || command -v yay || true)
    aur_install ai-usagebar-bin "Install ai-usagebar-bin from the AUR for the AI Usage bar plugin (Claude, Grok, Codex... quotas)?"
    aur_install linux-wallpaperengine-git "Install linux-wallpaperengine-git from the AUR for live Wallpaper Engine wallpapers (w-engine plugin; needs Wallpaper Engine on Steam; builds from source, takes a few minutes)?"
fi
if command -v ai-usagebar >/dev/null 2>&1 && ask "Turn on AI Usage for the AI tools already logged in on this machine?" Y; then
    run ai-usagebar detect >/dev/null && ok "AI Usage: enabled every provider with credentials here (change in the plugin's panel)"
fi
[ -d "$SKEL/.config/hypr" ] || $DRY || die "$SKEL/.config/hypr is missing; cachyos-hypr-noctalia must be installed."

# ---------- backup ----------
TS=$(date +%Y%m%d-%H%M%S)
BACKUP="$STATE/backups/$TS"
MANAGED=(
    .config/hypr
    .config/kitty
    .config/uwsm
    .config/noctalia/config.toml
    .local/state/noctalia/settings.toml
    .config/qt6ct/qt6ct.conf
    .local/bin/bar-scroll
    .local/bin/sync-cachyos-config
    .local/bin/ocr-region
    .local/share/applications/nwg-displays.desktop
    .local/bin/lock-screen
    .local/bin/lock-theme
    .local/share/quickshell-lockscreen
    .local/share/qylock
    .config/qylock
)
step "Backing up your current configs"
run mkdir -p "$BACKUP/files"
$DRY || printf '%s\n' "${MANAGED[@]}" >"$BACKUP/manifest"
for rel in "${MANAGED[@]}"; do
    if [ -e "$HOME/$rel" ]; then
        run mkdir -p "$(dirname "$BACKUP/files/$rel")"
        run cp -a "$HOME/$rel" "$BACKUP/files/$rel"
    fi
done
ok "Saved to ${BACKUP/#$HOME/~} (undo with --uninstall)"

# ---------- CachyOS base ----------
step "CachyOS stock config (the base layer)"
run mkdir -p "$HOME/.config/hypr/config" "$HOME/.config/kitty" "$HOME/.config/uwsm" "$HOME/.config/noctalia"
run cp "$SKEL"/.config/hypr/config/*.lua "$HOME/.config/hypr/config/"
run cp "$SKEL/.config/hypr/xdph.conf" "$HOME/.config/hypr/xdph.conf"
if $DRY; then info "[dry-run] write ~/.config/kitty/cachyos.conf from the stock kitty.conf"
else sed '/# BEGIN_KITTY_THEME/,/# END_KITTY_THEME/d' "$SKEL/.config/kitty/kitty.conf" >"$HOME/.config/kitty/cachyos.conf"; fi
run cp "$SKEL/.config/uwsm/env" "$HOME/.config/uwsm/env.cachyos"
run cp "$SKEL/.config/noctalia/config.toml" "$HOME/.config/noctalia/config.toml"
ok "Hyprland, kitty, uwsm and Noctalia base copied from /etc/skel"

# First-time extras CachyOS ships (GTK/Qt theming, cursor); only added where missing
extras=(.config/gtk-3.0/settings.ini .config/gtk-3.0/gtk.css .config/gtk-4.0/gtk.css .config/qt6ct/qt6ct.conf
        .config/xsettingsd/xsettingsd.conf .config/swash/settings.ini .icons/default/index.theme)
added=0
for rel in "${extras[@]}"; do
    if [ -e "$SKEL/$rel" ] && [ ! -e "$HOME/$rel" ]; then
        run mkdir -p "$(dirname "$HOME/$rel")"; run cp "$SKEL/$rel" "$HOME/$rel"; added=$((added + 1))
    fi
done
if [ -d "$SKEL/.local/share/icons/Bibata-Modern-Ice" ] && [ ! -d "$HOME/.local/share/icons/Bibata-Modern-Ice" ]; then
    run mkdir -p "$HOME/.local/share/icons"; run cp -a "$SKEL/.local/share/icons/Bibata-Modern-Ice" "$HOME/.local/share/icons/"; added=$((added + 1))
fi
[ $added -gt 0 ] && ok "Added $added missing theming file(s)"
# qt6ct can't expand $USER in its colour path
if [ -f "$HOME/.config/qt6ct/qt6ct.conf" ]; then
    run sed -i "s|^color_scheme_path=/home/\$USER/|color_scheme_path=$HOME/|" "$HOME/.config/qt6ct/qt6ct.conf"
fi

# ---------- Syn's layer ----------
step "Syn's layer"
run mkdir -p "$HOME/.config/hypr/user/hosts" "$HOME/.local/bin" "$HOME/.config/kitty/themes" "$HOME/Pictures/Screenshots"
run cp "$SRC/hypr/hyprland.lua" "$HOME/.config/hypr/hyprland.lua"
run cp "$SRC/hypr/user/shared.lua" "$SRC/hypr/user/vars.lua" "$HOME/.config/hypr/user/"
run cp "$SRC"/hypr/user/hosts/*.lua "$HOME/.config/hypr/user/hosts/"
# Noctalia generates themes/noctalia.conf and noctalia.lua; make sure the includes resolve before it first runs
[ -f "$HOME/.config/kitty/themes/noctalia.conf" ] || run touch "$HOME/.config/kitty/themes/noctalia.conf"
if [ ! -f "$HOME/.config/hypr/noctalia.lua" ]; then
    if $DRY; then info "[dry-run] create a placeholder ~/.config/hypr/noctalia.lua"
    else printf -- '-- Placeholder; Noctalia overwrites this with its colours\nreturn { apply_theme = function() end }\n' >"$HOME/.config/hypr/noctalia.lua"; fi
fi
run cp "$SRC/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf"
run cp "$SRC/uwsm/env" "$HOME/.config/uwsm/env"
run install -m755 "$SRC/bin/bar-scroll" "$SRC/bin/sync-cachyos-config" "$SRC/bin/ocr-region" \
    "$SRC/bin/lock-screen" "$SRC/bin/lock-theme" "$HOME/.local/bin/"
run cp "$SRC/hypr/hypridle.conf" "$HOME/.config/hypr/hypridle.conf"
run mkdir -p "$HOME/.local/share/applications"
run cp "$SRC/applications/nwg-displays.desktop" "$HOME/.local/share/applications/"  # searchable as "Monitor Settings"
ok "Keybinds, workspaces, theming, kitty, bar scrolling, OCR, lock wiring and sync script"

# ---------- this machine ----------
HOST=${SYNS_NOCTALIA_HOST:-$(cat /etc/hostname 2>/dev/null || hostname)}
HOSTFILE="$HOME/.config/hypr/user/hosts/$HOST.lua"
TMP_HOST=$(mktemp)
trap 'rm -f "$TMP_HOST"; rm -rf "${TMP:-}"' EXIT
step "This machine ($HOST)"
if [ -f "$HOSTFILE" ]; then
    ok "Using the saved settings in user/hosts/$HOST.lua"
elif command -v hyprctl >/dev/null && [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ] && command -v jq >/dev/null; then
    mons=$(hyprctl monitors -j | jq -r 'sort_by(.name | test("^eDP") | not) | .[] | "\(.name)\t\(.description)"')
    count=$(printf '%s\n' "$mons" | grep -c . || true)
    info "Detected $count monitor(s):"
    printf '%s\n' "$mons" | while IFS=$'\t' read -r name desc; do info "  $name  ($desc)"; done
    if ask "Create a host file for them (workspaces 1-10 split across monitors)?" Y; then
        {
            echo "-- Machine-specific settings for $HOST (generated by Syn's Noctalia; edit freely)."
            echo "-- hyprland.lua calls vars() right after CachyOS's variables, and setup() after everything else."
            echo; echo "local M = {}"; echo; echo "function M.vars()"
            i=1; printf '%s\n' "$mons" | while IFS=$'\t' read -r name desc; do echo "    MONITOR$i = \"$name\""; i=$((i + 1)); done
            echo "    PRIMARY_MONITOR = MONITOR1"; echo "end"; echo
            echo "function M.setup()"
            echo "    -- Monitors matched by model, so they work on any port. Adjust mode/position/scale as needed."
            printf '%s\n' "$mons" | while IFS=$'\t' read -r name desc; do
                echo "    hl.monitor({ output = \"desc:$desc\", mode = \"preferred\", position = \"auto-right\", scale = \"auto\" })"
            done
            echo "    hl.monitor({ output = \"\", mode = \"preferred\", position = \"auto-right\", scale = \"auto\" })"
            echo
            echo "    -- Workspaces 1-10 split evenly across monitors"
            echo "    local mons = {}"
            echo "    for i = 1, $count do mons[i] = _G[\"MONITOR\" .. i] end"
            echo "    local per = math.ceil(10 / #mons)"
            echo "    for ws = 1, 10 do"
            echo "        local m = math.min(#mons, math.floor((ws - 1) / per) + 1)"
            echo "        hl.workspace_rule({ workspace = tostring(ws), monitor = mons[m], default = ((ws - 1) % per == 0), persistent = true })"
            echo "    end"
            echo "end"; echo; echo "return M"
        } >"$TMP_HOST"
    fi
else
    warn "Not running inside Hyprland, so monitors can't be detected."
    info "Everything still works; workspaces follow CachyOS defaults. Re-run this from Hyprland to create a host file."
fi
if [ -n "${TMP_HOST:-}" ] && [ -s "$TMP_HOST" ]; then
    run cp "$TMP_HOST" "$HOSTFILE"; ok "Created user/hosts/$HOST.lua"
fi

# ---------- Noctalia settings ----------
step "Noctalia settings (bar look, font, screenshots, brightness, scroll actions)"
NSET="$HOME/.local/state/noctalia/settings.toml"
if [ -f "$NSET" ] && ! ask "Replace your Noctalia settings with Syn's? (yours are in the backup)" Y; then
    warn "Kept your Noctalia settings"
else
    run mkdir -p "$(dirname "$NSET")"
    if $DRY; then info "[dry-run] write $NSET"
    else sed "s|@HOME@|$HOME|g" "$SRC/noctalia/settings.toml" >"$NSET"; fi
    ok "Installed"
fi

# ---------- lock screen (qylock) ----------
step "Lock screen (qylock themes by Darkkal44)"
QS_DIR="$HOME/.local/share/quickshell-lockscreen"
QY_THEMES="$HOME/.local/share/qylock/themes"
if ask "Install the animated qylock lock screen (replaces Noctalia's lock)?" Y; then
    if ! command -v git >/dev/null || ! command -v quickshell >/dev/null; then
        $DRY || die "qylock needs git and quickshell (from the package step)."
    fi
    QY_SRC="$STATE/qylock-src"
    if $DRY; then
        info "[dry-run] fetch qylock $QYLOCK_COMMIT (themes only on demand)"
        themes="$QYLOCK_DEFAULT_THEMES"
    else
        # Sparse, blob-less clone: only the lock engine and the chosen themes are downloaded
        if [ ! -d "$QY_SRC/.git" ]; then
            rm -rf "$QY_SRC"
            git clone -q --filter=blob:none --sparse --no-checkout "$QYLOCK_REPO" "$QY_SRC" || die "Could not download qylock."
        fi
        git -C "$QY_SRC" fetch -q --filter=blob:none origin "$QYLOCK_COMMIT" 2>/dev/null || true
        available=$(git -C "$QY_SRC" ls-tree -d --name-only "$QYLOCK_COMMIT:themes" | tr '\n' ' ')
        themes="$QYLOCK_DEFAULT_THEMES"
        if ! $YES && [ -r "$TTY" ]; then
            info "Available themes: $available"
            info "Previews: https://github.com/Darkkal44/qylock#gallery"
            printf '    %s?%s Themes to install [%s]: ' "$Y" "$N" "$QYLOCK_DEFAULT_THEMES" >"$TTY"
            read -r pick <"$TTY" || pick=""
            [ -n "$pick" ] && themes="$pick"
        fi
        sel="quickshell-lockscreen"
        for t in $themes; do
            if printf ' %s ' "$available" | grep -q " $t "; then sel="$sel themes/$t"
            else warn "Unknown theme '$t', skipped"; fi
        done
        info "Downloading: ${sel#quickshell-lockscreen}"
        git -C "$QY_SRC" sparse-checkout set $sel >/dev/null
        git -C "$QY_SRC" checkout -q "$QYLOCK_COMMIT" || die "Could not check out qylock."
    fi

    # Lock engine + Syn's patch (fade-to-desktop unlock, emergency fallback screen)
    run rm -rf "$QS_DIR"
    run cp -r "$QY_SRC/quickshell-lockscreen" "$QS_DIR"
    if $DRY; then info "[dry-run] patch lock_shell.qml"
    else (cd "$QS_DIR" && patch -s -p1 <"$SRC/qylock/lock_shell.qml.patch") || die "qylock patch failed to apply."; fi
    run mkdir -p "$QS_DIR/fallback" "$QY_THEMES"
    run cp "$SRC/qylock/fallback/Main.qml" "$QS_DIR/fallback/Main.qml"
    run chmod +x "$QS_DIR/lock.sh"
    for t in $themes; do
        [ -d "$QY_SRC/themes/$t" ] || continue
        run rm -rf "${QY_THEMES:?}/$t"; run cp -r "$QY_SRC/themes/$t" "$QY_THEMES/$t"
    done
    run ln -sfn "$QY_THEMES" "$QS_DIR/themes_link"
    $DRY || git -C "$QY_SRC" show "$QYLOCK_COMMIT:LICENSE" >"$HOME/.local/share/qylock/LICENSE" 2>/dev/null || true
    # Clockwork: dark orbital dial with the windup animation
    for c in "$QY_THEMES"/clockwork/*/theme.conf; do
        [ -f "$c" ] && run sed -i 's/^themeMode=.*/themeMode=dark/; s/^enableWindup=.*/enableWindup=true/' "$c"
    done
    # Keep the current theme if it's valid, otherwise pick a sensible default
    cur=$(cat "$HOME/.config/qylock/theme" 2>/dev/null || true)
    if [ -z "$cur" ] || [ ! -f "$QY_THEMES/$cur/Main.qml" ]; then
        if [ -f "$QY_THEMES/clockwork/orbital/Main.qml" ]; then cur="clockwork/orbital"
        else cur=$(find "$QY_THEMES" -name Main.qml -printf '%h\n' 2>/dev/null | sed "s|^$QY_THEMES/||" | sort | head -1); fi
        run mkdir -p "$HOME/.config/qylock"
        $DRY || echo "$cur" >"$HOME/.config/qylock/theme"
    fi
    ok "qylock installed (theme: ${cur:-clockwork/orbital}). Switch with: lock-theme"
    ok "Super+L, the session menu and sleep all lock through hypridle -> lock-screen"
else
    # Keep Noctalia's own lock screen in charge
    if [ -f "$NSET" ]; then
        run sed -i '/^\[lockscreen\]/,/^\[/ { s/^enabled = false/enabled = true/; s/^lock_before_suspend = false/lock_before_suspend = true/ }' "$NSET"
    fi
    warn "Kept Noctalia's lock screen (lock-screen falls back to it)"
fi

# ---------- optional system tweaks ----------
step "Optional system tweaks (need sudo)"
if [ ! -f /etc/pacman.d/hooks/cachyos-hypr-noctalia-sync.hook ]; then
    if ask "Add a pacman hook that reminds you to run sync-cachyos-config when CachyOS's defaults update?" Y; then
        run sudo install -Dm644 "$SRC/pacman/cachyos-hypr-noctalia-sync.hook" /etc/pacman.d/hooks/cachyos-hypr-noctalia-sync.hook
        ok "Hook added"
    fi
else
    ok "Pacman hook already present"
fi
in_i2c=false; id -nG | tr ' ' '\n' | grep -qx i2c && in_i2c=true
i2c_mod=false; { lsmod 2>/dev/null | grep -q '^i2c_dev'; } && i2c_mod=true
if ! $in_i2c || ! $i2c_mod; then
    if ask "Enable external-monitor brightness control (DDC/CI: i2c-dev module + i2c group)?" Y; then
        run sudo sh -c 'echo i2c-dev > /etc/modules-load.d/i2c-dev.conf'
        run sudo modprobe i2c-dev
        getent group i2c >/dev/null || run sudo groupadd --system i2c
        run sudo usermod -aG i2c "$USER"
        ok "Enabled (log out and back in for the group change)"
    fi
else
    ok "DDC/CI brightness already set up"
fi

# ---------- apply ----------
step "Applying"
if command -v hyprctl >/dev/null && [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
    run hyprctl reload >/dev/null && ok "Hyprland reloaded"
    errs=$($DRY || hyprctl configerrors 2>/dev/null | grep -v '^\s*$' || true)
    [ -n "${errs:-}" ] && warn "Hyprland reported: $errs"
    command -v noctalia >/dev/null && { run noctalia msg config-reload >/dev/null 2>&1 && ok "Noctalia reloaded" || true; }
    pkill -USR1 -x kitty 2>/dev/null || true
    if command -v hypridle >/dev/null && ! pgrep -x hypridle >/dev/null; then
        run hyprctl dispatch 'hl.dsp.exec_cmd("hypridle")' >/dev/null && ok "hypridle started"
    fi
else
    info "Log in to the Hyprland session to see everything."
fi

printf '\n%sDone.%s Tap Super for the launcher, Super+Z for Noctalia settings, Ctrl+Alt+Del for the session menu.\n' "$G$B" "$N"
printf '%sKeep up with CachyOS updates: sync-cachyos-config  |  Undo: re-run with --uninstall%s\n' "$D" "$N"
