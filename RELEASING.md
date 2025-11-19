# Release Process

This document describes how to create a new release of swift-ejson.

## Version Management

**Version is defined in code** - The single source of truth for version information is:
```
Sources/EJSONKit/Version.swift
```

All version references (binary, releases, tags, Homebrew formula) automatically sync from this file.

## Prerequisites

- Write access to the repository
- All tests passing on main branch
- All changes merged to main

## Recommended Release Process (Automated)

### 1. Update the Version

Edit `Sources/EJSONKit/Version.swift` and update the version:

```swift
public static let current = "1.0.0"  // Change to your new version
```

Commit and push to main:

```bash
git checkout main
git add Sources/EJSONKit/Version.swift
git commit -m "Bump version to 1.0.0"
git push origin main
```

### 2. Trigger the Release Workflow

Go to the GitHub Actions page:
```
https://github.com/diogot/swift-ejson/actions/workflows/create-release.yml
```

1. Click "Run workflow"
2. Type "release" to confirm
3. Click "Run workflow" button

### 3. Automated Process

The workflow will automatically:

1. ✅ **Validate** - Extract version from code, check tests pass
2. 🏗️ **Build** - Create universal macOS binary (x86_64 + ARM64)
3. 🏷️ **Tag** - Create and push git tag (e.g., v1.0.0)
4. 📦 **Release** - Create GitHub release with binaries
5. 🍺 **Update Formula** - Update Homebrew formula with SHA256
6. ✅ **Commit** - Push updated formula to main

Monitor progress at: `https://github.com/diogot/swift-ejson/actions`

### 4. Verify the Release

After the workflow completes:

1. Go to https://github.com/diogot/swift-ejson/releases
2. Verify the release was created with:
   - Correct version number
   - Binary archive (`.tar.gz`)
   - Checksum file (`.sha256`)
   - Release notes

### 5. Test the Installation

Test the Homebrew installation:

```bash
# Update Homebrew
brew update

# Install via direct URL
brew install https://raw.githubusercontent.com/diogot/swift-ejson/main/Formula/ejson.rb

# Or via tap (if set up)
brew tap diogot/ejson
brew install ejson

# Verify version
ejson --version
```

Test manual download:

```bash
VERSION="1.0.0"
curl -L "https://github.com/diogot/swift-ejson/releases/download/v${VERSION}/ejson-${VERSION}-macos-universal.tar.gz" | tar xz
./ejson --version
```

## Alternative: Manual Release Process

If you prefer manual control or the automated workflow fails:

### 1. Update Version in Code

```bash
# Edit Sources/EJSONKit/Version.swift
git add Sources/EJSONKit/Version.swift
git commit -m "Bump version to 1.0.0"
git push origin main
```

### 2. Create and Push Tag

```bash
VERSION=$(./scripts/get-version.sh)
git tag -a v${VERSION} -m "Release version ${VERSION}"
git push origin v${VERSION}
```

This triggers the tag-based release workflow (release.yml).

### 3. Update Homebrew Formula

After the release is created:

```bash
./scripts/update-formula.sh 1.0.0
git add Formula/ejson.rb
git commit -m "Update Homebrew formula to v1.0.0"
git push origin main
```

## Versioning Guidelines

We follow [Semantic Versioning](https://semver.org/):

- **MAJOR** version: Incompatible API changes
- **MINOR** version: New functionality (backwards compatible)
- **PATCH** version: Bug fixes (backwards compatible)

Examples:
- `v1.0.0` - Initial stable release
- `v1.1.0` - Add new features
- `v1.0.1` - Bug fixes
- `v2.0.0` - Breaking changes

## Troubleshooting

### Build Fails

If the GitHub Actions workflow fails:

1. Check the Actions tab for error details
2. Fix issues in a new commit/PR
3. Delete the tag: `git tag -d v1.0.0 && git push origin :refs/tags/v1.0.0`
4. Create a new tag after fixes are merged

### Release Already Exists

If you need to update a release:

1. Go to the Releases page
2. Edit the release
3. Delete old assets if needed
4. Manually upload new assets (or delete the release and re-run workflow)

## Manual Release (Fallback)

If automated builds fail, you can create a release manually:

### Build Locally on macOS

```bash
# Clean previous builds
rm -rf .build release

# Run build script
./scripts/build-release.sh 1.0.0

# Verify the binary
./release/ejson help
```

### Create Release on GitHub

1. Go to https://github.com/diogot/swift-ejson/releases/new
2. Choose the tag (v1.0.0)
3. Fill in the release title and description
4. Upload the files from `release/` directory:
   - `ejson-1.0.0-macos-universal.tar.gz`
   - `ejson-1.0.0-macos-universal.tar.gz.sha256`
5. Click "Publish release"

## Post-Release

After releasing:

1. **Update Separate Tap (Optional)**:

   If using a separate `homebrew-ejson` tap repository:
   ```bash
   cd ../homebrew-ejson
   cp ../swift-ejson/Formula/ejson.rb Formula/
   git add Formula/ejson.rb
   git commit -m "Update ejson to v1.0.0"
   git push
   ```

   Note: The formula in the main repo is already updated automatically.

2. Announce the release (Twitter, forums, etc.)
3. Update documentation sites if applicable
4. Close related issues/PRs
5. Plan next release milestone

## Version Synchronization

The version system ensures everything stays in sync:

| Component | Source | How it Syncs |
|-----------|--------|--------------|
| **Library Version** | `Sources/EJSONKit/Version.swift` | Direct reference |
| **Binary Version** | CLI `--version` flag | Imports from EJSONKit.Version |
| **Git Tag** | GitHub Actions | Extracted via `scripts/get-version.sh` |
| **GitHub Release** | GitHub Actions | Uses git tag |
| **Homebrew Formula** | `Formula/ejson.rb` | Auto-updated by workflow |

**To change version**: Edit `Sources/EJSONKit/Version.swift` only. Everything else updates automatically.
