#!/bin/bash

# Exit on error
set -e

echo "🔧 Updating system..."
sudo pacman -Syu --noconfirm

echo "📦 Installing core packages..."
sudo pacman -S --noconfirm \
  hyprland kitty swww wl-clipboard waybar \
  networkmanager bluez bluez-utils \
  pipewire pipewire-pulse wireplumber \
  xdg-desktop-portal-hyprland xdg-utils \
  git curl wget nano unzip

echo "🔌 Enabling essential services..."
sudo systemctl enable --now NetworkManager
sudo systemctl enable --now bluetooth

echo "🎛 Installing yay (AUR helper)..."
if ! command -v yay &> /dev/null; then
  cd /tmp
  git clone https://aur.archlinux.org/yay.git
  cd yay
  makepkg -si --noconfirm
fi

echo "🖼 Setting up wallpaper..."
mkdir -p ~/Pictures
curl -L https://wallpapercave.com/wp/wp5128413.jpg -o ~/Pictures/wallpaper.jpg

echo "🛠 Setting up Hyprland config..."
mkdir -p ~/.config/hypr

cat > ~/.config/hypr/hyprland.conf <<EOF
# Hyprland minimal config

\$mod = SUPER

# Keybinds
bind = \$mod, Return, exec, kitty

# Autostart
exec-once = kitty
exec-once = swww init && swww img ~/Pictures/wallpaper.jpg
exec-once = waybar

# Monitor and input
monitor=,preferred,auto,1
input {
  kb_layout = us
}
general {
  gaps_in = 5
  gaps_out = 10
  border_size = 2
  col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
  col.inactive_border = rgba(595959aa)
}
decoration {
  rounding = 10
}
animations {
  enabled = true
}
EOF

echo "✅ Done! Reboot and run 'Hyprland' from TTY to start your session."
