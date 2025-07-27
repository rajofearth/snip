# Snip Tool

A simple snipping tool for Linux Mint (and other Debian-based distributions) that allows you to take screenshots of a selected area and copies them to your clipboard.

## Dependencies

This tool requires the following packages to be installed:

*   `scrot`
*   `xclip`
*   `python3-tk`
*   `python3-pil`
*   `python3-pil.imagetk`

The installation script will attempt to install these for you if they are missing.

## Installation

1.  Make the installation script executable:

    ```bash
    chmod +x install.sh
    ```

2.  Run the installation script with `sudo`:

    ```bash
    sudo ./install.sh
    ```

The script will:

*   Install the necessary dependencies.
*   Copy the application to `/usr/local/bin/snip-tool`.
*   Create an application menu entry.
*   Set up a keyboard shortcut: `Ctrl+Shift+S`.

## How to Use

*   **From the application menu:** Launch "Snip Tool".
*   **With the keyboard shortcut:** Press `Ctrl+Shift+S`.

Your screen will freeze, allowing you to click and drag to select an area. Once you release the mouse button, the selected area will be copied to your clipboard.

## Uninstallation

1.  Make the uninstallation script executable:

    ```bash
    chmod +x uninstall.sh
    ```

2.  Run the uninstallation script with `sudo`:

    ```bash
    sudo ./uninstall.sh
    ```

This will remove the application, the menu entry, and the keyboard shortcut.
