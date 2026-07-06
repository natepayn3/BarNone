#!/usr/bin/env bash

# Exit immediately if any command returns a non-zero status
set -e

QUICKSHELL_DIR="$HOME/.config/quickshell/Aethr"

# 📦 1. Install official repository dependencies
echo "Installing system dependencies..."
sudo pacman -S --needed --noconfirm \
    hyprland \
    satty \
    grim \
    slurp \
    bluez \
    bluez-utils \
    networkmanager \
    wireplumber \
    pipewire \
    pipewire-audio \
    pipewire-pulse \
    pipewire-alsa \
    qt6-multimedia \
    playerctl \
    base-devel \
    git \
    fish \
    showmethekey

# 🧬 2. Force bootstrap yay if missing
if ! command -v yay &>/dev/null; then
    echo "yay not found. Bootstrapping yay from the AUR..."
    BUILD_DIR=$(mktemp -d)
    git clone https://aur.archlinux.org/yay.git "$BUILD_DIR"
    (cd "$BUILD_DIR" && makepkg -si --noconfirm)
    rm -rf "$BUILD_DIR"
fi

# 🛸 3. Build quickshell-git and font dependencies
echo "Installing quickshell-git and AUR fonts via yay..."
yay -S --aur --noconfirm --needed \
    quickshell-git \
    ttf-material-symbols-variable-git \
    ttf-material-icons

# 🔐 4. Grant hardware access and configure passwordless sudo
echo "Configuring hardware permissions and sudo rules..."

# Add user to input group for device access
sudo usermod -aG input "$USER"

# Create NOPASSWD rule for showmethekey-cli
# Note: Ensure the path is correct for your system; /usr/bin/showmethekey-cli is the standard binary
echo "$USER ALL=(ALL) NOPASSWD: /usr/bin/showmethekey-cli" | sudo tee /etc/sudoers.d/showmethekey > /dev/null
sudo chmod 0440 /etc/sudoers.d/showmethekey

# 📂 5. Setup quickshell directory and clone the repository
echo "Deploying repository workspace..."
mkdir -p "$HOME/.config/quickshell"

if [ -d "$QUICKSHELL_DIR" ]; then
    echo "Updating existing workspace..."
    (cd "$QUICKSHELL_DIR" && git reset --hard HEAD && git pull)
else
    echo "Cloning Aethr into target directory..."
    git clone https://github.com/natepayn3/Aethr.git "$QUICKSHELL_DIR"
fi

# ⚙️ 6. Activate hardware runtime daemons and user audio engines
echo "Initializing service engines..."
sudo systemctl enable --now bluetooth.service NetworkManager.service
systemctl --user enable --now pipewire.service pipewire-pulse.service wireplumber.service

# 🛠️ 7. Append Aethr startup daemons to hyprland.lua if not already present
HYPRLAND_LUA="$HOME/.config/hypr/hyprland.lua"

if [ -f "$HYPRLAND_LUA" ]; then
    if ! grep -q 'qs -c Aethr' "$HYPRLAND_LUA"; then
        echo "Adding Aethr startup hooks to hyprland.lua..."
        
        # Inject the Lua block cleanly
        printf '\nhl.on("hyprland.start", function () \n  hl.exec_cmd("qs -c Aethr")\n  hl.exec_cmd("awww-daemon")\nend)\n' >> "$HYPRLAND_LUA"
    else
        echo "Aethr startup hooks already present in hyprland.lua. Skipping..."
    fi
else
    echo "⚠️ hyprland.lua not found at $HYPRLAND_LUA. Skipping configuration append."
fi

echo "Done! Aethr workspace deployment complete. Please log out and back in for group changes to take effect."
