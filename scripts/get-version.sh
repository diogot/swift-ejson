#!/bin/bash
set -e

# Extract version from Version.swift
# This is the single source of truth for version information

VERSION_FILE="Sources/EJSONKit/Version.swift"

if [ ! -f "$VERSION_FILE" ]; then
    echo "Error: Version file not found at $VERSION_FILE" >&2
    exit 1
fi

# Extract version string from: public static let current = "1.0.0"
VERSION=$(grep -E 'static let current = "' "$VERSION_FILE" | sed -E 's/.*"([^"]+)".*/\1/')

if [ -z "$VERSION" ]; then
    echo "Error: Could not extract version from $VERSION_FILE" >&2
    exit 1
fi

# Validate version format (MAJOR.MINOR.PATCH)
if ! echo "$VERSION" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
    echo "Error: Invalid version format: $VERSION (expected MAJOR.MINOR.PATCH)" >&2
    exit 1
fi

echo "$VERSION"
