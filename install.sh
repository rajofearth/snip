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
ICON_DIR="/usr/share/icons/hicolor/256x256/apps"
ICON_NAME="snip-tool"
ICON_FILE="snip-tool.png"
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

# 3. Install the custom icon
echo "Installing custom icon..."
if [ -f "$ICON_FILE" ]; then
    mkdir -p "$ICON_DIR"
    cp "$ICON_FILE" "$ICON_DIR/$ICON_FILE"
    chmod 644 "$ICON_DIR/$ICON_FILE"
    
    # Update icon cache
    if command -v gtk-update-icon-cache &> /dev/null; then
        gtk-update-icon-cache -f -t /usr/share/icons/hicolor/ 2>/dev/null || true
    fi
    echo "Custom icon installed successfully."
else
    echo "Warning: Icon file '$ICON_FILE' not found. Using default system icon."
    ICON_NAME="accessories-screenshot"
fi

# 4. Create the .desktop file
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

# 5. Set up keyboard shortcut
echo "Setting up keyboard shortcut (Ctrl+Shift+S)..."

if command -v gsettings &> /dev/null; then
    # Determine desktop environment
    DE="unknown"
    if [ -n "$XDG_CURRENT_DESKTOP" ]; then
        DE="$(echo "$XDG_CURRENT_DESKTOP" | tr '[:upper:]' '[:lower:]')"
    elif [ -n "$DESKTOP_SESSION" ]; then
        DE="$(echo "$DESKTOP_SESSION" | tr '[:upper:]' '[:lower:]')"
    else
        # Fallback: try to get from gsettings
        DE="$(gsettings get org.gnome.desktop.session session-name 2>/dev/null | sed "s/'//g" || echo "unknown")"
    fi
    
    echo "Detected desktop environment: $DE"
    
    if [[ "$DE" == *"gnome"* || "$DE" == *"cinnamon"* || "$DE" == *"ubuntu"* ]]; then
        # Get current custom keybindings
        CUSTOM_KEYBINDINGS=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)

        # Find an available custom keybinding slot
        NEW_BINDING_PATH=""
        for i in $(seq 0 9); do # Check custom0 to custom9
            BINDING_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom$i/"
            if ! echo "$CUSTOM_KEYBINDINGS" | grep -q "$BINDING_PATH"; then
                NEW_BINDING_PATH="$BINDING_PATH"
                break
            fi
        done

        if [ -n "$NEW_BINDING_PATH" ]; then
            gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"$NEW_BINDING_PATH" name "$APP_NAME"
            gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"$NEW_BINDING_PATH" command "$INSTALL_DIR/$EXECUTABLE_NAME"
            gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"$NEW_BINDING_PATH" binding "<Primary><Shift>s"

            # Add the new binding path to the list of custom keybindings
            if [ "$CUSTOM_KEYBINDINGS" == "@as []" ]; then
                # Empty array, create new one with our binding
                gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['$NEW_BINDING_PATH']"
            else
                # Parse existing array and append new binding
                # Remove the outer brackets and quotes, split by comma, then rebuild
                EXISTING_PATHS=$(echo "$CUSTOM_KEYBINDINGS" | sed "s/\[//g" | sed "s/\]//g" | sed "s/'//g")
                if [ -n "$EXISTING_PATHS" ]; then
                    NEW_KEYBINDINGS="['$(echo "$EXISTING_PATHS" | sed "s/, /', '/g")', '$NEW_BINDING_PATH']"
                else
                    NEW_KEYBINDINGS="['$NEW_BINDING_PATH']"
                fi
                gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$NEW_KEYBINDINGS"
            fi
            echo "Keyboard shortcut (Ctrl+Shift+S) has been set up successfully!"
            echo "If the shortcut doesn't work immediately, try logging out and back in."
        else
            echo "Could not find an available custom keybinding slot (custom0-custom9 are all in use)."
            echo "Please set the keyboard shortcut manually in your system settings."
        fi
    elif [[ "$DE" == *"kde"* || "$DE" == *"plasma"* ]]; then
        echo "KDE/Plasma detected. Attempting to set up shortcut using kwriteconfig5..."
        if command -v kwriteconfig5 &> /dev/null; then
            # Create a custom shortcut for KDE
            kwriteconfig5 --file kglobalshortcutsrc --group "$APP_NAME" --key "_k_friendly_name" "$APP_NAME"
            kwriteconfig5 --file kglobalshortcutsrc --group "$APP_NAME" --key "launch" "Ctrl+Shift+S,none,$APP_NAME"
            kwriteconfig5 --file khotkeysrc --group "Data" --key "DataCount" "1"
            kwriteconfig5 --file khotkeysrc --group "Data_1" --key "Comment" "$APP_NAME"
            kwriteconfig5 --file khotkeysrc --group "Data_1" --key "Enabled" "true"
            kwriteconfig5 --file khotkeysrc --group "Data_1" --key "Name" "$APP_NAME"
            kwriteconfig5 --file khotkeysrc --group "Data_1" --key "Type" "SIMPLE_ACTION_DATA"
            kwriteconfig5 --file khotkeysrc --group "Data_1Actions" --key "ActionsCount" "1"
            kwriteconfig5 --file khotkeysrc --group "Data_1Actions0" --key "CommandURL" "$INSTALL_DIR/$EXECUTABLE_NAME"
            kwriteconfig5 --file khotkeysrc --group "Data_1Actions0" --key "Type" "COMMAND_URL"
            kwriteconfig5 --file khotkeysrc --group "Data_1Triggers" --key "TriggersCount" "1"
            kwriteconfig5 --file khotkeysrc --group "Data_1Triggers0" --key "Key" "Ctrl+Shift+S"
            kwriteconfig5 --file khotkeysrc --group "Data_1Triggers0" --key "Type" "SHORTCUT"
            echo "KDE shortcut configured. You may need to restart KDE or log out/in for it to take effect."
        else
            echo "kwriteconfig5 not found. Please set the keyboard shortcut manually in KDE System Settings."
        fi
    else
        echo "Desktop environment '$DE' is not fully supported for automatic shortcut setup."
        echo "Please set the keyboard shortcut manually in your system settings:"
        echo "  - Shortcut: Ctrl+Shift+S"
        echo "  - Command: $INSTALL_DIR/$EXECUTABLE_NAME"
    fi
else
    echo "gsettings not found. Checking for alternative methods..."
    
    # Try alternative methods for different desktop environments
    if command -v kwriteconfig5 &> /dev/null; then
        echo "KDE detected. Please set the keyboard shortcut manually in System Settings > Shortcuts."
    elif command -v xfconf-query &> /dev/null; then
        echo "XFCE detected. Please set the keyboard shortcut manually in Settings > Keyboard > Application Shortcuts."
    else
        echo "Please set the keyboard shortcut manually in your desktop environment's settings:"
        echo "  - Shortcut: Ctrl+Shift+S"
        echo "  - Command: $INSTALL_DIR/$EXECUTABLE_NAME"
    fi
fi

echo "
Installation complete!

* You can now launch '$APP_NAME' from your application menu.
* Or use the keyboard shortcut: Ctrl+Shift+S
"
