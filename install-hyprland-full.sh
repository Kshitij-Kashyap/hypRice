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

echo "🧑‍💻 Detecting GPU and installing appropriate drivers..."

# Detect GPU and install drivers
if lspci | grep -i 'VGA' | grep -i 'Intel'; then
  echo "Intel GPU detected. Installing Intel drivers..."
  sudo pacman -S --noconfirm xf86-video-intel
elif lspci | grep -i 'VGA' | grep -i 'AMD'; then
  echo "AMD GPU detected. Installing AMD drivers..."
  sudo pacman -S --noconfirm xf86-video-amdgpu
elif lspci | grep -i 'VGA' | grep -i 'NVIDIA'; then
  echo "NVIDIA GPU detected. Installing NVIDIA drivers..."
  sudo pacman -S --noconfirm nvidia nvidia-utils
else
  echo "No supported GPU detected. Please manually install appropriate drivers."
fi

# Check for VMware or similar virtual environment
if systemctl list-units --type=service | grep -q "vmtoolsd"; then
  echo "✅ VMware detected. Installing open-vm-tools for better VM integration..."
  sudo pacman -S --noconfirm open-vm-tools
  sudo systemctl enable --now vmtoolsd
elif systemd-detect-virt | grep -q 'vmware'; then
  echo "✅ VMware detected. Installing open-vm-tools for better VM integration..."
  sudo pacman -S --noconfirm open-vm-tools
  sudo systemctl enable --now vmtoolsd
else
  echo "❌ No VMware tools detected. If using a VM, you may want to install open-vm-tools manually."
fi

# Create minimal Hyprland config with a dummy file if missing
echo "🛠 Setting up Hyprland config..."
mkdir -p ~/.config/hypr

# Create dummy hyprland.conf if missing
if [ ! -f ~/.config/hypr/hyprland.conf ]; then
  cat > ~/.config/hypr/hyprland.conf <<EOF
# Hyprland minimal config (dummy file)

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
  echo "✅ Dummy Hyprland config created."
else
  echo "✅ Hyprland config already exists."
fi

echo "✅ Done! Reboot and run 'Hyprland' from TTY to start your session."
