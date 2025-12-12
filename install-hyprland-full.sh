#!/usr/bin/env bash
set -euo pipefail

# === USER EDITABLE PATHS ===
HYPREPO="${HOME}/hypRice"                       # path to your hypRice repo
CAELESTIA_CLONE="${HOME}/caelestia-shell"      # temporary clone location for caelestia repo
QUICK_CONFIG_DST="${HYPREPO}/.config/quickshell/caelestia"

# === start ===
echo "🔧 System update..."
sudo pacman -Syu --noconfirm

echo "📦 Installing minimal core packages for Hyprland + QuickShell..."
# minimal required runtime packages for Wayland / Hyprland session + common helpers
sudo pacman -S --needed --noconfirm \
  hyprland \
  swww \
  wl-clipboard \
  wlroots \
  pipewire pipewire-pulse wireplumber \
  wireplumber-pulse \
  xdg-desktop-portal-hyprland xdg-utils \
  networkmanager bluez bluez-utils \
  pavucontrol \
  brightnessctl \
  git curl wget unzip \
  fontconfig \
  cmake ninja gcc make pkgconf extra-cmake-modules qt6-base qt6-declarative qt6-wayland

# (Note: qt6-* packages are needed for building/running QuickShell QML apps)

echo "🔌 Enabling essential services..."
sudo systemctl enable --now NetworkManager
sudo systemctl enable --now bluetooth

# === yay (AUR helper) install if missing ===
if ! command -v yay &>/dev/null; then
  echo "🎛 Installing yay (AUR helper)..."
  tmpd="$(mktemp -d)"
  pushd "$tmpd" >/dev/null
  git clone https://aur.archlinux.org/yay.git
  cd yay
  makepkg -si --noconfirm
  popd >/dev/null
  rm -rf "$tmpd"
else
  echo "✅ yay already installed."
fi

# === Try to install quickshell from AUR (preferred) ===
echo "🧩 Attempting to install QuickShell from AUR (quickshell or quickshell-git)..."
if ! yay -S --noconfirm quickshell quickshell-git 2>/dev/null; then
  echo "⚠️ quickshell package install via AUR failed or packages not available. Falling back to clone/build instructions."
  AUR_OK=false
else
  echo "✅ QuickShell installed from AUR."
  AUR_OK=true
fi

# === If AUR install failed, clone Caelestia shell repo and copy config into hypRice ===
if [ "$AUR_OK" = false ]; then
  echo "📂 Cloning Caelestia shell repo for local config copy (no system install)..."
  # remove any previous clone
  rm -rf "$CAELESTIA_CLONE"
  git clone https://github.com/caelestia-dots/shell.git "$CAELESTIA_CLONE"

  echo "📁 Creating QuickShell config destination inside hypRice..."
  mkdir -p "$QUICK_CONFIG_DST"

  # Back up existing config if present
  if [ -d "$QUICK_CONFIG_DST" ] && [ "$(ls -A "$QUICK_CONFIG_DST")" ]; then
    echo "⚠️ Existing QuickShell config found at $QUICK_CONFIG_DST — backing up."
    ts=$(date +%s)
    mv "$QUICK_CONFIG_DST" "${QUICK_CONFIG_DST}.bak.${ts}"
    mkdir -p "$QUICK_CONFIG_DST"
  fi

  echo "🔁 Copying only config + components + modules + assets to hypRice repo (minimal set QuickShell expects)..."
  cp -a "$CAELESTIA_CLONE/config" "$QUICK_CONFIG_DST/" || true
  cp -a "$CAELESTIA_CLONE/components" "$QUICK_CONFIG_DST/" || true
  cp -a "$CAELESTIA_CLONE/modules" "$QUICK_CONFIG_DST/" || true
  cp -a "$CAELESTIA_CLONE/assets" "$QUICK_CONFIG_DST/" || true

  echo "✅ QuickShell config and QML assets copied to: $QUICK_CONFIG_DST"
  echo "💡 You can now run QuickShell from the repo-config with:"
  echo "   qs -c ${QUICK_CONFIG_DST}   # if 'qs' binary installed"
  echo "Or run the system binary once you've built/installed it."

  echo "ℹ️ NOTE: this fallback does NOT build a system-wide QuickShell binary. If you later want to build QuickShell from source, install the additional build deps and run cmake/ninja per QuickShell README."
fi

# === Create minimal Hyprland config (stripped down) if missing or user wants it ===
echo "🛠 Creating minimal Hyprland config if it does not exist..."
mkdir -p "${HOME}/.config/hypr"
if [ ! -f "${HOME}/.config/hypr/hyprland.conf" ]; then
  cat > "${HOME}/.config/hypr/hyprland.conf" <<'HYPR_CONF'
# Minimal Hyprland config for QuickShell testing
$mod = SUPER

# Launchers
bind = $mod, Return, exec, foot
bind = $mod, D, exec, rofi -show drun

# Audio keys
bind = ,XF86AudioRaiseVolume,exec,pactl set-sink-volume @DEFAULT_SINK@ +5%
bind = ,XF86AudioLowerVolume,exec,pactl set-sink-volume @DEFAULT_SINK@ -5%
bind = ,XF86AudioMute,exec,pactl set-sink-mute @DEFAULT_SINK@ toggle

# Brightness keys
bind = ,XF86MonBrightnessUp,exec,brightnessctl set +5%
bind = ,XF86MonBrightnessDown,exec,brightnessctl set 5%-

# Autostart minimal (do not start terminals or extras)
exec-once = swww init && swww img ~/Pictures/wallpaper.jpg
exec-once = wireplumber
exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
exec-once = hyprlock

general {
  gaps_in = 5
  gaps_out = 10
  border_size = 2
}
decoration {
  rounding = 8
}
animations {
  enabled = true
}
HYPR_CONF
  echo "✅ Minimal Hyprland config created at ~/.config/hypr/hyprland.conf"
else
  echo "✅ Hyprland config already present at ~/.config/hypr/hyprland.conf"
fi

echo "🎉 Finished. Summary:"
echo " - Hyprland & runtime packages installed"
if [ "$AUR_OK" = true ]; then
  echo " - QuickShell installed from AUR"
else
  echo " - QuickShell not installed; Caelestia config copied into $QUICK_CONFIG_DST for testing"
fi
echo " - HypRice dotfiles path: $HYPREPO"
echo ""
echo "To test QuickShell (fallback config mode):"
echo "  qs -c ${QUICK_CONFIG_DST}   # if 'qs' installed"
echo ""
echo "If you want me to: "
echo "  • add a build step to compile QuickShell from source (system install)"
echo "  • or copy additional dotfiles from another repo into hypRice (app-specific files)"
echo "say: 'build quickshell from source' or 'copy app dotfiles' and I will update the script."

exit 0
