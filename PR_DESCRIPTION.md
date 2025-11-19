# Add Homebrew Installation and Centralized Version Management

This PR adds comprehensive Homebrew support and implements a centralized version management system with fully automated releases.

## 🎯 Overview

This PR makes `ejson` easily installable via Homebrew and establishes a single source of truth for version management across all components (binary, releases, tags, and Homebrew formula).

## ✨ What's New

### 1. Homebrew Installation Support

Users can now install ejson via Homebrew:

```bash
# Via tap (recommended)
brew tap diogot/ejson
brew install ejson

# Or direct installation
brew install https://raw.githubusercontent.com/diogot/swift-ejson/main/Formula/ejson.rb
```

**Created:**
- `Formula/ejson.rb` - Homebrew formula with comprehensive tests
- `HOMEBREW.md` - Complete installation and maintenance guide
- `scripts/update-formula.sh` - Helper script for formula updates

**CLI Improvements:**
- Added `--version`, `-v`, and `version` commands
- Prints version and compatibility information

### 2. Centralized Version Management

**Single Source of Truth** - Version is now defined in one place:
```swift
// Sources/EJSONKit/Version.swift
public static let current = "1.0.0"
```

All components automatically sync from this file:
- ✅ CLI binary `--version` output
- ✅ Git tags
- ✅ GitHub releases
- ✅ Homebrew formula

**Created:**
- `Sources/EJSONKit/Version.swift` - Central version definition
- `scripts/get-version.sh` - Version extraction script
- `VERSION_MANAGEMENT.md` - Comprehensive documentation

### 3. Automated Release Workflow

**New Manual Workflow** (`.github/workflows/create-release.yml`):

Trigger from GitHub Actions UI → Type "release" to confirm → Done!

The workflow automatically:
1. ✅ Extracts version from code
2. ✅ Validates format and runs tests
3. ✅ Builds universal macOS binary (Intel + Apple Silicon)
4. ✅ Creates and pushes git tag
5. ✅ Creates GitHub release with binaries
6. ✅ **Calculates SHA256 and updates Homebrew formula**
7. ✅ Commits updated formula back to main

**Updated:**
- `.github/workflows/release.yml` - Renamed to "Release (Tag-based)", kept for backward compatibility

### 4. Documentation

**New Files:**
- `HOMEBREW.md` - Homebrew installation guide
- `VERSION_MANAGEMENT.md` - Version management documentation

**Updated:**
- `RELEASING.md` - Completely rewritten for automated workflow
- `README.md` - Added Homebrew installation and version management sections

## 📦 Release Process Comparison

### Before This PR:
1. Manually update version in multiple places
2. Create and push git tag
3. Wait for build to complete
4. Download binary and calculate SHA256
5. Manually update Homebrew formula
6. Commit formula changes

### After This PR:
1. Edit `Sources/EJSONKit/Version.swift`
2. Commit and push to main
3. Click "Run workflow" on GitHub Actions
4. Type "release" to confirm
5. ✨ **Done! Everything automated**

## 🎁 Benefits

1. **No Version Drift** - Single source ensures all components stay in sync
2. **Fully Automated Releases** - One-click release process
3. **Easy Installation** - Homebrew support for macOS users
4. **Error-Proof** - Workflow validates version format, prevents duplicate tags
5. **SHA256 Auto-Calculated** - No manual checksum work needed
6. **Formula Auto-Updated** - Committed back to main automatically
7. **Traceable** - Version changes visible in git history

## 📊 Version Synchronization

| Component | Source | How it Syncs |
|-----------|--------|--------------|
| Library Version | `Version.swift` | Direct definition |
| Binary Version | CLI `--version` | Imports from `EJSONKit.Version` |
| Git Tag | GitHub Actions | Extracted via `scripts/get-version.sh` |
| GitHub Release | GitHub Actions | Uses git tag |
| Homebrew Formula | Auto-updated | SHA256 calculated by workflow |

## 🧪 Testing

Version extraction works:
```bash
$ ./scripts/get-version.sh
1.0.0
```

CLI shows version:
```bash
$ swift build && .build/debug/ejson --version
ejson version 1.0.0
Swift EJSON - Compatible with Shopify EJSON
```

## 🚀 How to Create a Release (After Merge)

**Simple 3-step process:**

1. **Update version** in `Sources/EJSONKit/Version.swift`:
   ```swift
   public static let current = "1.0.0"  // Change to new version
   ```

2. **Commit and push to main**:
   ```bash
   git add Sources/EJSONKit/Version.swift
   git commit -m "Bump version to 1.0.0"
   git push origin main
   ```

3. **Trigger workflow**:
   - Go to: https://github.com/diogot/swift-ejson/actions/workflows/create-release.yml
   - Click "Run workflow"
   - Type "release" to confirm
   - Monitor automated process

The workflow handles everything: tag creation, binary building, release creation, and formula updates.

## 📋 Files Changed

### New Files
- `Sources/EJSONKit/Version.swift` - Central version definition
- `Formula/ejson.rb` - Homebrew formula
- `HOMEBREW.md` - Homebrew documentation
- `VERSION_MANAGEMENT.md` - Version management guide
- `.github/workflows/create-release.yml` - Automated release workflow
- `scripts/get-version.sh` - Version extraction script
- `scripts/update-formula.sh` - Formula update helper

### Modified Files
- `Sources/ejson/main.swift` - Added version command using `EJSONKit.Version`
- `.github/workflows/release.yml` - Renamed, updated description
- `README.md` - Added Homebrew installation and version management sections
- `RELEASING.md` - Rewritten for automated workflow

## 🔍 Breaking Changes

None. This PR is fully backward compatible.

## 📝 Next Steps After Merge

1. Test the automated release workflow with version 1.0.0
2. Optionally create a separate tap repository (`homebrew-ejson`) for simpler installation
3. Announce Homebrew availability to users

## 🙏 Notes

- The formula uses placeholder SHA256 initially - it will be updated automatically when the first release is created
- The tag-based workflow (`release.yml`) is kept for backward compatibility
- All documentation has been updated to reflect the new processes
