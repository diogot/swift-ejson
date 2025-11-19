# Homebrew Installation Guide

This guide explains how to install `ejson` via Homebrew.

## Installation Options

### Option 1: Direct Formula Installation (Quick)

You can install directly from the formula file without setting up a tap:

```bash
brew install https://raw.githubusercontent.com/diogot/swift-ejson/main/Formula/ejson.rb
```

### Option 2: Using a Homebrew Tap (Recommended)

A Homebrew tap provides a better user experience with simpler commands.

#### For Users

Once the tap is set up, install with:

```bash
# Add the tap
brew tap diogot/ejson

# Install ejson
brew install ejson
```

To upgrade:

```bash
brew upgrade ejson
```

To uninstall:

```bash
brew uninstall ejson
brew untap diogot/ejson
```

#### For Maintainers: Setting Up a Tap

1. **Create a tap repository** named `homebrew-ejson`:
   ```bash
   # Create a new repository on GitHub: diogot/homebrew-ejson
   git clone https://github.com/diogot/homebrew-ejson.git
   cd homebrew-ejson
   ```

2. **Copy the formula**:
   ```bash
   # Create Formula directory in the tap
   mkdir -p Formula

   # Copy the formula from this repo
   cp /path/to/swift-ejson/Formula/ejson.rb Formula/
   ```

3. **Update the SHA256 checksum** after creating a release:
   ```bash
   # Download the release tarball
   VERSION="1.0.0"
   curl -L -o ejson.tar.gz "https://github.com/diogot/swift-ejson/releases/download/v${VERSION}/ejson-${VERSION}-macos-universal.tar.gz"

   # Calculate SHA256
   shasum -a 256 ejson.tar.gz

   # Update the sha256 value in Formula/ejson.rb
   ```

4. **Commit and push**:
   ```bash
   git add Formula/ejson.rb
   git commit -m "Add ejson formula v${VERSION}"
   git push origin main
   ```

5. **Test the tap**:
   ```bash
   brew tap diogot/ejson
   brew install ejson
   ejson --version
   ```

## Updating the Formula for New Releases

### Automated Updates (Recommended)

The formula is **automatically updated** when a release is created using the GitHub Actions workflow. The maintainer only needs to:

1. Update version in `Sources/EJSONKit/Version.swift`
2. Trigger the "Create Release" workflow
3. Everything else happens automatically:
   - Git tag created
   - Binary built
   - Release created
   - **Formula updated with correct SHA256**

See [RELEASING.md](RELEASING.md) for complete instructions.

### Manual Updates (If Needed)

If you need to manually update the formula:

1. **Use the update script**:
   ```bash
   # This script downloads the release and updates the formula
   ./scripts/update-formula.sh 1.1.0

   # Review the changes
   git diff Formula/ejson.rb

   # Commit and push
   git add Formula/ejson.rb
   git commit -m "Update formula to v1.1.0"
   git push origin main
   ```

2. **For separate tap repository**:
   ```bash
   cd homebrew-ejson
   cp ../swift-ejson/Formula/ejson.rb Formula/
   git add Formula/ejson.rb
   git commit -m "Update ejson to v1.1.0"
   git push origin main
   ```

3. **Users can then upgrade**:
   ```bash
   brew update
   brew upgrade ejson
   ```

### Version Management

Version is centrally managed in `Sources/EJSONKit/Version.swift`. All releases and formula updates sync from this single source. This ensures the binary version, git tags, GitHub releases, and Homebrew formula are always in sync.

## Testing the Formula Locally

Before pushing changes, test the formula locally:

```bash
# Install from local formula
brew install --build-from-source Formula/ejson.rb

# Or test without installing
brew audit --strict Formula/ejson.rb
brew test Formula/ejson.rb

# Uninstall after testing
brew uninstall ejson
```

## Submitting to Homebrew Core (Optional)

For wider distribution, you can submit to the official Homebrew repository:

1. **Requirements**:
   - Project must be stable and well-maintained
   - Binaries should be notarized (macOS)
   - Formula must follow Homebrew guidelines

2. **Process**:
   ```bash
   # Fork homebrew-core
   # Add formula to Formula/ejson.rb
   # Submit a pull request
   ```

See: https://docs.brew.sh/Adding-Software-to-Homebrew

## Troubleshooting

### Formula Not Found

If `brew install ejson` fails with "No available formula":

1. Ensure the tap is added: `brew tap diogot/ejson`
2. Update Homebrew: `brew update`
3. Try the direct URL installation method

### SHA256 Mismatch

If installation fails with SHA256 mismatch:

1. The formula needs to be updated with the correct checksum
2. Contact the maintainer or open an issue

### Binary Not Found After Installation

If `ejson` command is not found:

1. Check if it's installed: `brew list ejson`
2. Check your PATH: `echo $PATH | grep -o '/usr/local/bin'`
3. Try running with full path: `/usr/local/bin/ejson --version`
4. Restart your terminal

## Resources

- [Homebrew Formula Cookbook](https://docs.brew.sh/Formula-Cookbook)
- [Homebrew Taps Documentation](https://docs.brew.sh/Taps)
- [swift-ejson Repository](https://github.com/diogot/swift-ejson)
