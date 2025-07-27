#!/bin/bash

# Check for root privileges
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root. Please use sudo."
    exit 1
fi

# --- Configuration ---
APP_NAME="Snip Tool"
INSTALL_DIR="/usr/local/bin"
EXECUTABLE_NAME="snip-tool"
DESKTOP_FILE_DIR="/usr/share/applications"
DESKTOP_FILE_NAME="snip-tool.desktop"
ICON_NAME="accessories-screenshot"
PYTHON_SCRIPT="snip.py"

# --- Dependency Check ---
REQUIRED_PACKAGES=("scrot" "xclip" "python3-tk" "python3-pil" "python3-pil.imagetk")

function check_packages() {
    local missing_packages=()
    for pkg in "${REQUIRED_PACKAGES[@]}"; do
        if ! dpkg -l | grep -q "^ii.*$pkg"; then
            missing_packages+=("$pkg")
        fi
    done

    if [ ${#missing_packages[@]} -gt 0 ]; then
        echo "The following required packages are missing: ${missing_packages[*]}"
        read -p "Do you want to install them now? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            apt-get update && apt-get install -y "${missing_packages[@]}"
            if [ $? -ne 0 ]; then
                echo "Error: Failed to install dependencies. Please install them manually and try again."
                exit 1
            fi
        else
            echo "Installation aborted. Please install the required packages manually."
            exit 1
        fi
    fi
}

# --- Installation Steps ---

# 1. Check for dependencies
check_packages

# 2. Copy the Python script to the installation directory
echo "Installing Python script to $INSTALL_DIR/$EXECUTABLE_NAME..."
cp "$PYTHON_SCRIPT" "$INSTALL_DIR/$EXECUTABLE_NAME"
chmod +x "$INSTALL_DIR/$EXECUTABLE_NAME"

# 3. Create the .desktop file
echo "Creating application menu entry..."
cat << EOF > "$DESKTOP_FILE_DIR/$DESKTOP_FILE_NAME"
[Desktop Entry]
Name=$APP_NAME
Exec=$INSTALL_DIR/$EXECUTABLE_NAME
Icon=$ICON_NAME
Type=Application
Categories=Utility;Graphics;
Comment=A simple snipping tool for taking screenshots.
Terminal=false
EOF

# 4. Set up keyboard shortcut (for GNOME/Cinnamon)
SHORTCUT_COMMAND="gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command '$INSTALL_DIR/$EXECUTABLE_NAME'"
SHORTCUT_NAME="gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ name '$APP_NAME'"
SHORTCUT_BINDING="gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ binding '<Primary><Shift>S'"

if command -v gsettings &> /dev/null; then
    echo "Setting up keyboard shortcut (Ctrl+Shift+S)..."
    eval $SHORTCUT_COMMAND
    eval $SHORTCUT_NAME
    eval $SHORTCUT_BINDING
    gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/']"
    echo "Shortcut created. You might need to log out and log back in for it to take effect."
else
    echo "Could not find 'gsettings'. Please set the keyboard shortcut manually in your system settings."
    echo "Command: $INSTALL_DIR/$EXECUTABLE_NAME"
fi

echo "
Installation complete!

* You can now launch '$APP_NAME' from your application menu.
* Or use the keyboard shortcut: Ctrl+Shift+S
"
