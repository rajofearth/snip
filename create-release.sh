#!/bin/bash
# Create a new GitHub release

set -e

# Get version from control file
VERSION=$(grep '^Version:' snip-tool-deb/DEBIAN/control | awk '{print $2}')
TAG="v$VERSION"
RELEASE_NOTES="Release $TAG"

# Build the package if not already built
if [ ! -f "snip-tool_${VERSION}_all.deb" ]; then
    echo "Building package..."
    ./build-deb.sh
fi

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo "Error: git is not installed. Please install it first."
    exit 1
fi

# Check if hub is installed
if ! command -v hub &> /dev/null; then
    echo "hub (GitHub CLI) is not installed. Installing..."
    # Install hub (GitHub CLI)
    if command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y hub
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y hub
    elif command -v pacman &> /dev/null; then
        sudo pacman -S --noconfirm hub
    else
        echo "Error: Cannot install hub automatically. Please install it manually:"
        echo "  https://github.com/github/hub#installation"
        exit 1
    fi
fi

# Create a git tag
git tag -a "$TAG" -m "Release $TAG"
git push origin "$TAG"

# Create GitHub release
hub release create \
    -a "snip-tool_${VERSION}_all.deb" \
    -m "$RELEASE_NOTES" \
    -e \
    "$TAG"

echo "Release $TAG created successfully!"
