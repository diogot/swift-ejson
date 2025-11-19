#!/bin/bash
set -e

# Script to update the Homebrew formula with the correct SHA256 checksum
# Usage: ./scripts/update-formula.sh <version>
# Example: ./scripts/update-formula.sh 1.0.0

if [ $# -ne 1 ]; then
    echo "Usage: $0 <version>"
    echo "Example: $0 1.0.0"
    exit 1
fi

VERSION=$1
FORMULA_FILE="Formula/ejson.rb"
RELEASE_URL="https://github.com/diogot/swift-ejson/releases/download/v${VERSION}/ejson-${VERSION}-macos-universal.tar.gz"

echo "Updating Homebrew formula for version ${VERSION}..."

# Check if formula file exists
if [ ! -f "$FORMULA_FILE" ]; then
    echo "Error: Formula file not found at $FORMULA_FILE"
    exit 1
fi

# Download the release tarball
echo "Downloading release tarball..."
TEMP_FILE=$(mktemp)
trap "rm -f $TEMP_FILE" EXIT

if ! curl -L -f -o "$TEMP_FILE" "$RELEASE_URL"; then
    echo "Error: Failed to download release from $RELEASE_URL"
    echo "Make sure the release v${VERSION} exists on GitHub"
    exit 1
fi

# Calculate SHA256
echo "Calculating SHA256 checksum..."
if command -v sha256sum &> /dev/null; then
    SHA256=$(sha256sum "$TEMP_FILE" | awk '{print $1}')
elif command -v shasum &> /dev/null; then
    SHA256=$(shasum -a 256 "$TEMP_FILE" | awk '{print $1}')
else
    echo "Error: Neither sha256sum nor shasum found"
    exit 1
fi

echo "SHA256: $SHA256"

# Create backup of formula
cp "$FORMULA_FILE" "${FORMULA_FILE}.backup"

# Update the formula
echo "Updating formula..."

# Update version
sed -i.tmp "s/version \".*\"/version \"${VERSION}\"/" "$FORMULA_FILE"

# Update URL
sed -i.tmp "s|download/v[0-9.]\+/ejson-[0-9.]\+-macos-universal.tar.gz|download/v${VERSION}/ejson-${VERSION}-macos-universal.tar.gz|g" "$FORMULA_FILE"

# Update SHA256 (replace PLACEHOLDER or existing hash)
sed -i.tmp "s/sha256 \".*\"/sha256 \"${SHA256}\"/" "$FORMULA_FILE"

# Clean up sed backup files
rm -f "${FORMULA_FILE}.tmp"

echo ""
echo "Formula updated successfully!"
echo ""
echo "Changes made to $FORMULA_FILE:"
echo "  - version: ${VERSION}"
echo "  - sha256: ${SHA256}"
echo ""
echo "Please review the changes:"
git diff "$FORMULA_FILE" || diff -u "${FORMULA_FILE}.backup" "$FORMULA_FILE" || true
echo ""
echo "If everything looks good:"
echo "  1. Commit: git add $FORMULA_FILE && git commit -m \"Update formula to v${VERSION}\""
echo "  2. Push: git push"
echo ""
echo "To restore the backup: mv ${FORMULA_FILE}.backup $FORMULA_FILE"
