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

# --- Uninstallation Steps ---

# 1. Remove the Python script
echo "Removing Python script from $INSTALL_DIR/$EXECUTABLE_NAME..."
rm -f "$INSTALL_DIR/$EXECUTABLE_NAME"

# 2. Remove the .desktop file
echo "Removing application menu entry..."
rm -f "$DESKTOP_FILE_DIR/$DESKTOP_FILE_NAME"

# 3. Remove keyboard shortcut (for GNOME/Cinnamon)
if command -v gsettings &> /dev/null; then
    echo "Removing keyboard shortcut..."
    gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "@as []"
    echo "Shortcut removed. You might need to log out and log back in for the change to take effect."
else
    echo "Could not find 'gsettings'. Please remove the keyboard shortcut manually in your system settings."
fi

echo "
Uninstallation complete!

* The application and its menu entry have been removed.
* The keyboard shortcut has been unset.
"
