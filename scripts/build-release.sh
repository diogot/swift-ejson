#!/bin/bash
set -e

# Build script for creating release binaries of ejson CLI
# Supports building universal binaries for macOS (x86_64 + arm64)

VERSION=${1:-"dev"}
PRODUCT_NAME="ejson"
BUILD_DIR=".build"
RELEASE_DIR="release"

echo "Building ${PRODUCT_NAME} version ${VERSION}..."

# Detect platform
if [[ "$OSTYPE" == "darwin"* ]]; then
    PLATFORM="macos"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    PLATFORM="linux"
else
    echo "Unsupported platform: $OSTYPE"
    exit 1
fi

# Clean previous builds
rm -rf "$BUILD_DIR"
rm -rf "$RELEASE_DIR"
mkdir -p "$RELEASE_DIR"

if [[ "$PLATFORM" == "macos" ]]; then
    echo "Building for macOS..."

    # Check if we can build universal binaries
    if swift --version | grep -q "Apple Swift"; then
        echo "Building universal binary (x86_64 + arm64)..."

        # Build for x86_64
        echo "Building for x86_64..."
        swift build -c release --arch x86_64

        # Build for arm64
        echo "Building for arm64..."
        swift build -c release --arch arm64

        # Create universal binary
        echo "Creating universal binary..."
        lipo -create \
            "$BUILD_DIR/x86_64-apple-macosx/release/$PRODUCT_NAME" \
            "$BUILD_DIR/arm64-apple-macosx/release/$PRODUCT_NAME" \
            -output "$RELEASE_DIR/$PRODUCT_NAME"

        ARCHIVE_NAME="${PRODUCT_NAME}-${VERSION}-macos-universal.tar.gz"
    else
        # Non-Apple Swift (shouldn't happen on macOS, but just in case)
        echo "Building for current architecture..."
        swift build -c release
        cp "$BUILD_DIR/release/$PRODUCT_NAME" "$RELEASE_DIR/"
        ARCHIVE_NAME="${PRODUCT_NAME}-${VERSION}-macos.tar.gz"
    fi

elif [[ "$PLATFORM" == "linux" ]]; then
    echo "Building for Linux..."
    swift build -c release
    cp "$BUILD_DIR/release/$PRODUCT_NAME" "$RELEASE_DIR/"
    ARCHIVE_NAME="${PRODUCT_NAME}-${VERSION}-linux-$(uname -m).tar.gz"
fi

# Verify the binary
echo "Verifying binary..."
"$RELEASE_DIR/$PRODUCT_NAME" --version 2>&1 || "$RELEASE_DIR/$PRODUCT_NAME" help > /dev/null

# Create archive
echo "Creating archive: $ARCHIVE_NAME"
cd "$RELEASE_DIR"
tar -czf "$ARCHIVE_NAME" "$PRODUCT_NAME"

# Create latest archive (without version) for GitHub latest release URL
if [[ "$PLATFORM" == "macos" ]]; then
    LATEST_ARCHIVE="${PRODUCT_NAME}-macos-universal.tar.gz"
else
    LATEST_ARCHIVE="${PRODUCT_NAME}-linux-$(uname -m).tar.gz"
fi
cp "$ARCHIVE_NAME" "$LATEST_ARCHIVE"
cd ..

# Calculate checksums
echo "Calculating checksums..."
if command -v sha256sum &> /dev/null; then
    sha256sum "$RELEASE_DIR/$ARCHIVE_NAME" > "$RELEASE_DIR/$ARCHIVE_NAME.sha256"
    sha256sum "$RELEASE_DIR/$LATEST_ARCHIVE" > "$RELEASE_DIR/$LATEST_ARCHIVE.sha256"
elif command -v shasum &> /dev/null; then
    shasum -a 256 "$RELEASE_DIR/$ARCHIVE_NAME" > "$RELEASE_DIR/$ARCHIVE_NAME.sha256"
    shasum -a 256 "$RELEASE_DIR/$LATEST_ARCHIVE" > "$RELEASE_DIR/$LATEST_ARCHIVE.sha256"
fi

echo ""
echo "Build complete!"
echo "Binary: $RELEASE_DIR/$PRODUCT_NAME"
echo "Archive: $RELEASE_DIR/$ARCHIVE_NAME"
if [[ -f "$RELEASE_DIR/$ARCHIVE_NAME.sha256" ]]; then
    echo "Checksum: $RELEASE_DIR/$ARCHIVE_NAME.sha256"
    cat "$RELEASE_DIR/$ARCHIVE_NAME.sha256"
fi

# Show binary info
echo ""
echo "Binary info:"
if [[ "$PLATFORM" == "macos" ]]; then
    file "$RELEASE_DIR/$PRODUCT_NAME"
    if command -v lipo &> /dev/null; then
        lipo -info "$RELEASE_DIR/$PRODUCT_NAME"
    fi
else
    file "$RELEASE_DIR/$PRODUCT_NAME"
fi

ls -lh "$RELEASE_DIR/"
