# Version Management

## Single Source of Truth

The version for swift-ejson is defined in **one place only**:

```
Sources/EJSONKit/Version.swift
```

All other components automatically sync from this file:
- CLI binary `--version` output
- Git tags
- GitHub releases
- Homebrew formula

## Updating the Version

To release a new version:

1. **Edit the version file**:
   ```swift
   // Sources/EJSONKit/Version.swift
   public static let current = "1.1.0"  // Update this line
   ```

2. **Commit and push**:
   ```bash
   git add Sources/EJSONKit/Version.swift
   git commit -m "Bump version to 1.1.0"
   git push origin main
   ```

3. **Trigger the release**:
   - Go to GitHub Actions: https://github.com/diogot/swift-ejson/actions/workflows/create-release.yml
   - Click "Run workflow"
   - Type "release" to confirm
   - The workflow will:
     - Extract version from code
     - Create git tag (v1.1.0)
     - Build binaries
     - Create GitHub release
     - Update Homebrew formula

## How It Works

### Version Extraction

The script `scripts/get-version.sh` extracts the version from code:

```bash
VERSION=$(./scripts/get-version.sh)
echo $VERSION  # Outputs: 1.0.0
```

This is used by:
- Manual release commands
- GitHub Actions workflows
- Build scripts

### CLI Binary

The binary imports the version directly:

```swift
// Sources/ejson/main.swift
import EJSONKit

func printVersion() {
    print(Version.full)       // "ejson version 1.0.0"
    print(Version.description) // "Swift EJSON - Compatible with Shopify EJSON"
}
```

### GitHub Actions

The `create-release.yml` workflow:

1. Runs `./scripts/get-version.sh` to extract version
2. Validates the version format
3. Checks if tag already exists
4. Creates tag, release, and updates formula automatically

### Homebrew Formula

The formula is automatically updated by the release workflow with:
- Correct version number
- Download URL with version
- SHA256 checksum of the binary

## Version Format

We follow [Semantic Versioning](https://semver.org/):

```
MAJOR.MINOR.PATCH
```

Examples:
- `1.0.0` - Initial release
- `1.1.0` - New features (backward compatible)
- `1.0.1` - Bug fixes
- `2.0.0` - Breaking changes

The version must match the regex: `^[0-9]+\.[0-9]+\.[0-9]+$`

## Validation

The version extraction script validates:
- File exists (`Sources/EJSONKit/Version.swift`)
- Version can be extracted
- Format is valid (MAJOR.MINOR.PATCH)

The release workflow validates:
- Version format is correct
- Tag doesn't already exist
- Tests pass before releasing

## Manual Override

If you need to bypass the automated workflow:

```bash
# Get current version from code
VERSION=$(./scripts/get-version.sh)

# Create tag manually
git tag -a v${VERSION} -m "Release version ${VERSION}"
git push origin v${VERSION}

# This triggers the tag-based release workflow (release.yml)
# Then manually update the formula:
./scripts/update-formula.sh ${VERSION}
```

## Benefits

1. **No version drift** - Binary, releases, and formula always match
2. **Single update point** - Change version in one place
3. **Automated releases** - Less manual work, fewer errors
4. **Validation** - Prevents duplicate tags and invalid versions
5. **Traceable** - Version changes are visible in git history

## Checking Current Version

```bash
# From code
./scripts/get-version.sh

# From binary (if built)
.build/release/ejson --version

# From installed binary
ejson --version
```

## For Contributors

When working on features:
- **Don't** manually update version numbers in PRs
- **Do** wait for maintainers to bump version before release
- Version bumps happen on `main` branch only
- Releases are created from `main` branch

## For Maintainers

Release checklist:
1. ✅ All PRs merged to main
2. ✅ All tests passing
3. ✅ Update `Sources/EJSONKit/Version.swift`
4. ✅ Commit version bump
5. ✅ Run manual release workflow
6. ✅ Verify release was created
7. ✅ Test installation

See [RELEASING.md](RELEASING.md) for detailed instructions.
