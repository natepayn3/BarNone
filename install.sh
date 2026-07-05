#!/usr/bin/env fish

# Target workspace path
set QUICKSHELL_DIR "$HOME/.config/quickshell/Aethr"

# Clear terminal and render the complete, verified ASCII art banner for Aethr
clear
echo -e "\033[0;34m    _     _____ _____ _   _ ____   "
echo -e "   / \   | ____|_   _| | | |  _ \  "
echo -e "  / _ \  |  _|   | | | |_| | |_) | "
echo -e " / ___ \ | |___  | | |  _  |  _ <  "
echo -e "/_/   \_\|_____| |_| |_| |_|_| \_\ \033[0m"
echo -e "\033[1;30m───────────────────────────────────\033[0m"
echo ""

# Prompt user for confirmation before proceeding
echo -e "\033[0;32m➔ Ready to deploy the Aethr workspace.\033[0m"
read -P "Press ENTER to continue or Ctrl+C to abort..." confirm

# Terminate execution if any step fails after the prompt
set -e

# 📦 1. Install base system dependencies (including fish)
echo "Installing system dependencies..."
sudo pacman -S --needed --noconfirm \
    hyprland \
    satty \
    bluez \
    bluez-utils \
    networkmanager \
    wireplumber \
    pipewire \
    pipewire-audio \
    pipewire-pulse \
    pipewire-alsa \
    base-devel \
    git \
    fish

# 🧬 2. Force bootstrap yay if missing, then build quickshell-git exclusively with yay
if not command -v yay >/dev/null 2>&1
    echo "yay not found. Bootstrapping yay from the AUR..."
    set BUILD_DIR (mktemp -d)
    git clone https://aur.archlinux.org/yay.git $BUILD_DIR
    cd $BUILD_DIR
    makepkg -si --noconfirm
    cd -
    rm -rf $BUILD_DIR
end

echo "Installing quickshell-git via yay..."
yay -S --aur --noconfirm --needed quickshell-git

# 📂 3. Setup quickshell directory and clone the repository
echo "Deploying repository workspace..."
mkdir -p "$HOME/.config/quickshell"

if test -d $QUICKSHELL_DIR
    echo "Updating existing workspace..."
    cd $QUICKSHELL_DIR
    git reset --hard HEAD
    git pull
    cd -
else
    echo "Cloning Aethr into target directory..."
    git clone https://github.com/natepayn3/Aethr.git $QUICKSHELL_DIR
end

# ⚙️ 4. Activate hardware runtime daemons and user audio engines
echo "Initializing service engines..."
sudo systemctl enable --now bluetooth.service NetworkManager.service
systemctl --user enable --now pipewire.service pipewire-pulse.service wireplumber.service

# 🛠️ 5. Append Aethr startup daemons to hyprland.lua if not already present
set HYPRLAND_LUA "$HOME/.config/hypr/hyprland.lua"

if test -f $HYPRLAND_LUA
    if not grep -q 'qs -c Aethr' $HYPRLAND_LUA
        echo "Adding Aethr startup hooks to hyprland.lua..."
        
        # Inject the Lua block directly via format strings without EOF
        printf '\nhl.on("hyprland.start", function () \n  hl.exec_cmd("qs -c Aethr")\n  hl.exec_cmd("awww-daemon")\nend)\n' >> $HYPRLAND_LUA
    else
        echo "Aethr startup hooks already present in hyprland.lua. Skipping..."
    fi
else
    echo "⚠️ hyprland.lua not found at $HYPRLAND_LUA. Skipping configuration append."
end

echo "Done! Aethr workspace deployment complete."
