# Release Process

This document describes how to create a new release of swift-ejson.

## Prerequisites

- Write access to the repository
- All tests passing on main branch
- Updated CHANGELOG (if applicable)

## Release Steps

### 1. Prepare the Release

Ensure all changes for the release are merged to the main branch:

```bash
git checkout main
git pull origin main
```

### 2. Update Version References

Update version references in documentation if needed:

- README.md (example version numbers in CLI installation)
- Package.swift (if you maintain a version constant)

### 3. Create and Push a Tag

Create a version tag following semantic versioning (vMAJOR.MINOR.PATCH):

```bash
# Create an annotated tag
git tag -a v1.0.0 -m "Release version 1.0.0"

# Push the tag to GitHub
git push origin v1.0.0
```

### 4. Automated Build Process

Once you push the tag, GitHub Actions will automatically:

1. **Run Tests** - Ensure all tests pass on macOS and Linux
2. **Build macOS Binary** - Create a universal binary (x86_64 + ARM64)
3. **Create Archive** - Package the binary as `.tar.gz`
4. **Calculate Checksums** - Generate SHA256 checksums
5. **Create GitHub Release** - Publish release with all artifacts
6. **Upload Assets** - Attach binaries and checksums

You can monitor the progress at: `https://github.com/diogot/swift-ejson/actions`

### 5. Verify the Release

After the workflow completes:

1. Go to https://github.com/diogot/swift-ejson/releases
2. Verify the release was created with:
   - Release notes
   - Binary archive (`.tar.gz`)
   - Checksum file (`.sha256`)

### 6. Test the Release

Download and test the binary:

```bash
VERSION="1.0.0"
curl -L "https://github.com/diogot/swift-ejson/releases/download/v${VERSION}/ejson-${VERSION}-macos-universal.tar.gz" | tar xz
./ejson help
./ejson keygen
```

Verify the checksum:

```bash
curl -L "https://github.com/diogot/swift-ejson/releases/download/v${VERSION}/ejson-${VERSION}-macos-universal.tar.gz.sha256" -o ejson.sha256
shasum -a 256 -c ejson.sha256
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

1. Announce the release (Twitter, forums, etc.)
2. Update documentation sites if applicable
3. Close related issues/PRs
4. Plan next release milestone
