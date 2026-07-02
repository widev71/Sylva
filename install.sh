#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# install.sh  –  Setup hyprland dotfiles setelah clone
# Jalankan dari dalam folder repo:
#   cd ~/.config/hypr && bash install.sh
# ─────────────────────────────────────────────────────────────
set -e

HYPR_DIR="$HOME/.config/hypr"
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
RESET="\e[0m"

info()  { echo -e "${GREEN}[INFO]${RESET}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
error() { echo -e "${RED}[ERR] ${RESET}  $*"; exit 1; }

# ── 0. Sanity check ───────────────────────────────────────────
[[ -d "$HYPR_DIR" ]] || error "Jalankan dari dalam $HYPR_DIR"

# ── 1. settings.json ──────────────────────────────────────────
if [[ ! -f "$HYPR_DIR/settings.json" ]]; then
    info "Membuat settings.json dari template default..."
    cp "$HYPR_DIR/default_settings.json" "$HYPR_DIR/settings.json"
    info "✅ settings.json dibuat. Edit sesuai kebutuhan."
else
    warn "settings.json sudah ada, skip."
fi

# ── 2. Chmod scripts ──────────────────────────────────────────
info "Mengatur permission script..."
find "$HYPR_DIR/scripts" -name "*.sh" -exec chmod +x {} \;
find "$HYPR_DIR/scripts" -name "*.py" -exec chmod +x {} \;
info "✅ Semua script sudah executable."

# ── 3. Cek dependencies ───────────────────────────────────────
info "Mengecek dependencies..."

DEPS=(
    "hyprland:hyprland"
    "quickshell:quickshell"
    "matugen:matugen"
    "swayosd-client:swayosd"
    "playerctl:playerctl"
    "cliphist:cliphist"
    "wl-copy:wl-clipboard"
    "hypridle:hypridle"
    "hyprlock:hyprlock"
    "nm-applet:network-manager-applet"
    "grim:grim"
    "slurp:slurp"
    "imagemagick:imagemagick"
    "zbar:zbar"
    "jq:jq"
    "inotifywait:inotify-tools"
    "pw-play:pipewire"
)

MISSING=()
for dep in "${DEPS[@]}"; do
    cmd="${dep%%:*}"
    pkg="${dep##*:}"
    if ! command -v "$cmd" &>/dev/null; then
        MISSING+=("$pkg")
        warn "  ❌ $cmd ($pkg)"
    else
        info "  ✅ $cmd"
    fi
done

if [[ ${#MISSING[@]} -gt 0 ]]; then
    echo ""
    warn "Package yang belum terinstall:"
    echo "  paru -S ${MISSING[*]}"
    echo ""
    read -rp "Install sekarang dengan paru? (y/N): " choice
    if [[ "$choice" =~ ^[Yy]$ ]]; then
        paru -S --needed "${MISSING[@]}"
    else
        warn "Skip install. Jalankan manual."
    fi
fi

# ── 4. Optional: Setup Git hooks ──────────────────────────────
info "Menyiapkan Git pre-commit hook..."
HOOK_DIR="$HYPR_DIR/.git/hooks"
if [[ -d "$HOOK_DIR" ]]; then
    cat > "$HOOK_DIR/pre-commit" << 'HOOK'
#!/bin/bash
# Jangan commit settings.json (data pribadi)
if git diff --cached --name-only | grep -q "^settings\.json$"; then
    echo "❌ STOP: settings.json terdeteksi di staged files!"
    echo "   Jalankan: git reset HEAD settings.json"
    exit 1
fi
HOOK
    chmod +x "$HOOK_DIR/pre-commit"
    info "✅ Pre-commit hook terpasang (cegah commit settings.json)."
fi

# ── 5. Done ───────────────────────────────────────────────────
echo ""
echo -e "${GREEN}╔═══════════════════════════════════════╗${RESET}"
echo -e "${GREEN}║     ✅ Setup selesai!                  ║${RESET}"
echo -e "${GREEN}╚═══════════════════════════════════════╝${RESET}"
echo ""
echo "Langkah berikutnya:"
echo "  1. Edit ~/.config/hypr/settings.json sesuai preferensi"
echo "  2. Set wallpaper: Super+W → pilih wallpaper directory"
echo "  3. Restart Hyprland atau reboot"
echo ""
