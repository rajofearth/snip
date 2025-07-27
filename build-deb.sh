#!/bin/bash

# Build script for Snip Tool .deb package

set -e

echo "Building Snip Tool .deb package..."

# Check if dpkg-deb is available
if ! command -v dpkg-deb &> /dev/null; then
    echo "Error: dpkg-deb is not installed. Please install it with:"
    echo "sudo apt-get install dpkg-dev"
    exit 1
fi

# Set proper permissions
find snip-tool-deb -type f -exec chmod 644 {} \;
find snip-tool-deb -type d -exec chmod 755 {} \;
chmod +x snip-tool-deb/usr/local/bin/snip-tool
chmod +x snip-tool-deb/DEBIAN/postinst
chmod +x snip-tool-deb/DEBIAN/prerm

# Build the package
dpkg-deb --build snip-tool-deb

# Rename to proper filename
mv snip-tool-deb.deb snip-tool_1.0.0_all.deb

echo "Package built successfully: snip-tool_1.0.0_all.deb"
echo ""
echo "To install the package, run:"
echo "  sudo dpkg -i snip-tool_1.0.0_all.deb"
echo "  sudo apt-get install -f  # If there are dependency issues"
echo ""
echo "To set up the keyboard shortcut after installation:"
echo "  snip-tool --setup-shortcut"
