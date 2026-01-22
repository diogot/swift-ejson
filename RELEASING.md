# Release Process

This document describes how to create a new release of swift-ejson.

## Version Management

The version is managed via the `VERSION` file at the project root. This file is the single source of truth for the version number and is read at build time by the `BuildVersionPlugin` to inject the version into the CLI binary.

## Prerequisites

- Write access to the repository
- All tests passing on main branch

## Release Steps

### 1. Update the VERSION file

Edit the `VERSION` file to contain the new version number:

```bash
echo "1.2.3" > VERSION
```

Follow [Semantic Versioning](https://semver.org/):
- **MAJOR** version: Incompatible API changes
- **MINOR** version: New functionality (backwards compatible)
- **PATCH** version: Bug fixes (backwards compatible)

### 2. Commit and Push

```bash
git add VERSION
git commit -m "Bump version to 1.2.3"
git push origin main
```

### 3. Trigger the Release Workflow

1. Go to the [Actions tab](https://github.com/diogot/swift-ejson/actions)
2. Select the "Release" workflow from the left sidebar
3. Click "Run workflow" button
4. Select the `main` branch
5. Click "Run workflow"

### 4. Automated Build Process

The Release workflow will automatically:

1. **Validate version** - Ensure VERSION > latest tag and tag doesn't exist
2. **Run tests** - Ensure all tests pass
3. **Build macOS binary** - Create a universal binary (x86_64 + ARM64)
4. **Create archive** - Package the binary as `.tar.gz`
5. **Calculate checksums** - Generate SHA256 checksums
6. **Create GitHub Release** - Publish release with tag `v{VERSION}`
7. **Upload assets** - Attach binaries and checksums

### 5. Verify the Release

After the workflow completes:

1. Go to https://github.com/diogot/swift-ejson/releases
2. Verify the release was created with:
   - Correct version tag (e.g., `v1.2.3`)
   - Release notes
   - Binary archive (`.tar.gz`)
   - Checksum file (`.sha256`)

### 6. Test the Release

Download and test the binary:

```bash
VERSION="1.2.3"
curl -L "https://github.com/diogot/swift-ejson/releases/download/v${VERSION}/ejson-${VERSION}-macos-universal.tar.gz" | tar xz
./ejson --version
./ejson keygen
```

Verify the checksum:

```bash
curl -L "https://github.com/diogot/swift-ejson/releases/download/v${VERSION}/ejson-${VERSION}-macos-universal.tar.gz.sha256" -o ejson.sha256
shasum -a 256 -c ejson.sha256
```

## Troubleshooting

### Version Validation Fails

If the release workflow fails with version validation errors:

1. **"Tag already exists"** - The VERSION matches an existing release. Bump the version.
2. **"Version must be greater than latest tag"** - Ensure VERSION > latest tag (e.g., 1.2.3 > 1.2.2)

### Build Fails

If the GitHub Actions workflow fails:

1. Check the Actions tab for error details
2. Fix issues in a new commit/PR
3. Merge to main
4. Re-run the Release workflow

## Manual Release (Fallback)

If automated builds fail, you can create a release manually:

### Build Locally on macOS

```bash
# Clean previous builds
rm -rf .build release

# Run build script
./scripts/build-release.sh 1.2.3

# Verify the binary
./release/ejson --version
```

### Create Release on GitHub

1. Create and push a tag: `git tag v1.2.3 && git push origin v1.2.3`
2. Go to https://github.com/diogot/swift-ejson/releases/new
3. Choose the tag (v1.2.3)
4. Fill in the release title and description
5. Upload the files from `release/` directory
6. Click "Publish release"
