# EJSONKit - Swift EJSON Library

A Swift implementation of Shopify's [EJSON](https://github.com/Shopify/ejson) library for managing encrypted secrets in source control.

## Features

- 🔐 **NaCl Box Encryption** - Uses Curve25519, Salsa20, and Poly1305 via libsodium
- 🔄 **Format Compatible** - Fully compatible with Go EJSON implementation
- 📦 **Recursive JSON Processing** - Automatically encrypts/decrypts nested structures
- 🎯 **Type Preservation** - Maintains JSON types (strings, numbers, booleans, arrays, objects)
- 📁 **File Operations** - Easy file encryption/decryption with public key management
- ✨ **Swift-Native** - Clean, type-safe Swift API

## Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/diogot/swift-ejson.git", from: "1.0.0")
]
```

Then add `EJSONKit` to your target dependencies:

```swift
.target(
    name: "YourTarget",
    dependencies: ["EJSONKit"]
)
```

## Quick Start

### Generate Keys

```swift
import EJSONKit

// Generate a new keypair
let keyPair = try EJSON.generateKeyPair()
print("Public Key:  \(keyPair.publicKey)")
print("Private Key: \(keyPair.privateKey)")
```

### Encrypt & Decrypt Values

```swift
let plaintext = "my secret password"

// Encrypt
let encrypted = try EJSON.encrypt(plaintext, publicKey: keyPair.publicKey)
// Returns: "EJ[1:ephemeral_pk:nonce:ciphertext]"

// Decrypt
let decrypted = try EJSON.decrypt(encrypted, privateKey: keyPair.privateKey)
// Returns: "my secret password"
```

### Work with JSON

```swift
let ejson = EJSON()

// Original JSON
let json: [String: Any] = [
    "database_password": "super_secret",
    "api_key": "my_api_key",
    "nested": [
        "secret": "nested_secret"
    ]
]

// Encrypt all string values
let encrypted = try ejson.encryptJSON(json, publicKey: keyPair.publicKey)

// Decrypt back
let decrypted = try ejson.decryptJSON(encrypted, privateKey: keyPair.privateKey)
```

### File Operations

```swift
// Encrypt a JSON file
try ejson.encryptFile(at: "/path/to/secrets.json", publicKey: keyPair.publicKey)

// Decrypt a JSON file
let secrets = try ejson.decryptFile(at: "/path/to/secrets.json", privateKey: keyPair.privateKey)

// Extract public key from an encrypted file
let publicKey = try ejson.extractPublicKey(from: "/path/to/secrets.json")
```

## EJSON Format

### File Structure

```json
{
  "_public_key": "63ccf05a9492e68e12eeb1c705888aebdcc0080af7e594fc402beb24cce9d14f",
  "database_password": "EJ[1:yF4JKMR4RUJY0hcxKYKDOg==:Yw6rqhvtLx7Kdc1hGtxqPBnx9bxk8kAzTCGNZPwVU5c=:ZCaH/xShYQ==]",
  "nested": {
    "secret": "EJ[1:x7F9KMTR5RUJZ1ida9KDPh==:Zw7sqiwuMy8Ldc2iHuyqQCoy0cyl9lB0UDHOaQxWV6d=:ADcI/yTiZR==]"
  }
}
```

### Encrypted Value Format

`EJ[1:ephemeral_pk:nonce:ciphertext]`

- **`1`** - Version number
- **`ephemeral_pk`** - Base64-encoded ephemeral public key (32 bytes)
- **`nonce`** - Base64-encoded nonce (24 bytes)
- **`ciphertext`** - Base64-encoded encrypted data

### Key Format

Keys are 32-byte Curve25519 keys represented as 64-character hexadecimal strings.

## API Reference

### EJSON Struct

```swift
public struct EJSON {
    public init()

    // Key Management
    public func generateKeyPair() throws -> KeyPair

    // Value Encryption/Decryption
    public func encrypt(_ plaintext: String, publicKey: String) throws -> String
    public func decrypt(_ ciphertext: String, privateKey: String) throws -> String

    // JSON Processing
    public func encryptJSON(_ json: [String: Any], publicKey: String) throws -> [String: Any]
    public func decryptJSON(_ json: [String: Any], privateKey: String) throws -> [String: Any]

    // File Operations
    public func encryptFile(at path: String, publicKey: String) throws
    public func decryptFile(at path: String, privateKey: String) throws -> [String: Any]
    public func extractPublicKey(from path: String) throws -> String

    // Static convenience methods
    public static func generateKeyPair() throws -> KeyPair
    public static func encrypt(_ plaintext: String, publicKey: String) throws -> String
    public static func decrypt(_ ciphertext: String, privateKey: String) throws -> String
}
```

### KeyPair

```swift
public struct KeyPair {
    public let publicKey: String   // 64-char hex string
    public let privateKey: String  // 64-char hex string
}
```

### Errors

```swift
public enum EJSONError: Error {
    case sodiumInitializationFailed
    case invalidKeyFormat
    case invalidHexString
    case invalidBase64String
    case encryptionFailed
    case decryptionFailed
    case invalidEncryptedFormat
    case invalidJSONData
    case missingPublicKey
    case fileNotFound
    case fileReadError
    case fileWriteError
}
```

## How It Works

### Encryption Process

1. **Generate ephemeral keypair** - A new keypair is created for each encryption
2. **Create nonce** - A random 24-byte nonce is generated
3. **Encrypt** - NaCl Box encryption using:
   - Recipient's public key
   - Ephemeral private key
   - Random nonce
4. **Format** - Package into `EJ[1:ephemeral_pk:nonce:ciphertext]`

### Decryption Process

1. **Parse** - Extract ephemeral public key, nonce, and ciphertext from `EJ[1:...]` format
2. **Decrypt** - NaCl Box decryption using:
   - Ephemeral public key
   - Recipient's private key
   - Nonce from encrypted value
3. **Return** - Original plaintext

### JSON Processing

The library recursively walks the JSON tree and:
- **Encrypts** all string values (except `_public_key`)
- **Preserves** all other types (numbers, booleans, null)
- **Maintains** structure (nested objects and arrays)
- **Adds** `_public_key` field to root object

## Compatibility

This library is **fully compatible** with the [Go EJSON implementation](https://github.com/Shopify/ejson):

- ✅ Files encrypted with Go EJSON can be decrypted with EJSONKit
- ✅ Files encrypted with EJSONKit can be decrypted with Go EJSON
- ✅ Identical encrypted value format
- ✅ Same key format (64-character hex strings)

## Security Considerations

- **Private keys** should never be committed to source control
- **Public keys** are safe to commit (they're in the encrypted files anyway)
- Use secure key storage (Keychain, environment variables, etc.)
- The `_public_key` field is never encrypted (it's needed for decryption)
- Each encryption uses a unique ephemeral keypair and nonce

## Examples

### Complete Workflow

```swift
import EJSONKit

// 1. Generate keys (do this once)
let keyPair = try EJSON.generateKeyPair()
print("Store this private key securely:", keyPair.privateKey)

// 2. Create secrets file
let secrets: [String: Any] = [
    "database": [
        "host": "db.example.com",
        "username": "admin",
        "password": "super_secret_password"
    ],
    "api_keys": [
        "stripe": "sk_live_...",
        "twilio": "AC..."
    ]
]

let secretsData = try JSONSerialization.data(withJSONObject: secrets)
try secretsData.write(to: URL(fileURLWithPath: "secrets.json"))

// 3. Encrypt the file
let ejson = EJSON()
try ejson.encryptFile(at: "secrets.json", publicKey: keyPair.publicKey)

// 4. Commit the encrypted file (safe!)
// git add secrets.json
// git commit -m "Add encrypted secrets"

// 5. Later, decrypt when needed
let decrypted = try ejson.decryptFile(at: "secrets.json", privateKey: keyPair.privateKey)
let dbPassword = (decrypted["database"] as? [String: Any])?["password"] as? String
```

### Working with Environment

```swift
// Store keys in environment variables
let publicKey = ProcessInfo.processInfo.environment["EJSON_PUBLIC_KEY"]!
let privateKey = ProcessInfo.processInfo.environment["EJSON_PRIVATE_KEY"]!

// Use them
let ejson = EJSON()
try ejson.encryptFile(at: "secrets.json", publicKey: publicKey)
let secrets = try ejson.decryptFile(at: "secrets.json", privateKey: privateKey)
```

## Command Line Interface

EJSONKit includes a command-line tool compatible with the [Go EJSON CLI](https://github.com/Shopify/ejson).

### Installation

#### Pre-built Binaries (Recommended)

Download the latest release for your platform from [GitHub Releases](https://github.com/diogot/swift-ejson/releases):

**macOS (Universal Binary - Intel & Apple Silicon):**

```bash
# Download and install the latest version
curl -L https://github.com/diogot/swift-ejson/releases/latest/download/ejson-macos-universal.tar.gz | tar xz
sudo mv ejson /usr/local/bin/
ejson --version
```

**Verify the checksum:**

```bash
# Download checksum
curl -L https://github.com/diogot/swift-ejson/releases/latest/download/ejson-macos-universal.tar.gz.sha256 -o ejson.sha256

# Verify
shasum -a 256 -c ejson.sha256
```

#### Build from Source

If you prefer to build from source:

```bash
# Clone the repository
git clone https://github.com/diogot/swift-ejson.git
cd swift-ejson

# Build the CLI
swift build -c release

# Install to PATH
cp .build/release/ejson /usr/local/bin/
```

**Requirements:**
- Swift 6.2+
- Linux only: libsodium-dev (`apt-get install libsodium-dev`)
- macOS: No additional dependencies (uses bundled libsodium)

### Usage

```
ejson <command> [options]

Commands:
  keygen            Generate a new keypair
  encrypt <file>... Encrypt one or more EJSON files
  decrypt <file>    Decrypt an EJSON file

Global Options:
  -keydir <path>    Path to keydir (default: /opt/ejson/keys or $EJSON_KEYDIR)
  --version, -v     Print version and exit

Keygen Options:
  -w                Write private key to keydir and print only public key
```

### CLI Examples

**Generate a keypair:**

```bash
# Print both keys to stdout
ejson keygen

# Write private key to keydir, print only public key
ejson keygen -w
```

**Encrypt a file:**

```bash
# Create a secrets file
cat > secrets.json << EOF
{
  "_public_key": "your_public_key_here",
  "database_password": "secret123",
  "api_key": "my_api_key"
}
EOF

# Encrypt it (modifies file in-place)
ejson encrypt secrets.json
```

**Decrypt a file:**

```bash
# Decrypt and print to stdout (doesn't modify file)
ejson decrypt secrets.json
```

**Custom keydir:**

```bash
# Using environment variable
export EJSON_KEYDIR=~/.ejson/keys
ejson decrypt secrets.json

# Using command line option
ejson -keydir ~/.ejson/keys decrypt secrets.json
```

### Key Storage

Private keys are stored in the keydir (default: `/opt/ejson/keys` or `$EJSON_KEYDIR`) with the filename matching the public key:

```
/opt/ejson/keys/
  └── 63ccf05a9492e68e12eeb1c705888aebdcc0080af7e594fc402beb24cce9d14f
```

Keys are saved with `0600` permissions (readable only by owner).

## Testing

The library includes comprehensive tests covering:

- Key generation and validation
- Single value encryption/decryption
- Unicode and special character handling
- Recursive JSON processing
- File operations
- Error handling
- Edge cases
- Performance benchmarks

Run tests with:

```bash
swift test
```

## Dependencies

- [swift-sodium](https://github.com/jedisct1/swift-sodium) (v0.10.0+) - Provides NaCl cryptography primitives with bundled libsodium

## Requirements

- Swift 6.2+
- macOS 10.15+ / iOS 13+ / tvOS 13+ / watchOS 6+
- Linux: libsodium-dev package required

## Contributing

Contributions are welcome! Please ensure:

- All tests pass
- New features include tests
- Code follows Swift conventions
- Changes maintain compatibility with Go EJSON

### Version Management

The version is managed via the `VERSION` file at the project root. Before creating a release:

1. Update the `VERSION` file with the new version number
2. Commit and push to `main`
3. Trigger the Release workflow manually from GitHub Actions

## License

MIT License - See LICENSE file for details

## References

- [Shopify EJSON](https://github.com/Shopify/ejson) - Original Go implementation
- [EJSON Format Specification](https://github.com/Shopify/ejson/blob/master/DESIGN.md)
- [NaCl Cryptography](https://nacl.cr.yp.to/)
- [libsodium](https://libsodium.gitbook.io/doc/)

## Credits

Inspired by Shopify's excellent EJSON library. This Swift implementation aims to bring the same security and ease-of-use to Swift projects.