# CLAUDE.md - Project Context

## Project Overview

**swift-ejson** is a Swift implementation of Shopify's EJSON library for managing encrypted secrets in source control. The library module is named **EJSONKit** following Apple-style framework naming conventions.

**Reference Implementation:** https://github.com/Shopify/ejson

## Purpose

Provide a native Swift library that can:
- Encrypt and decrypt individual values using NaCl cryptography
- Process JSON files with selective encryption of sensitive values
- Maintain format compatibility with the Go EJSON implementation
- Enable secure secret management in Swift-based projects

## Core Architecture

### Module Name: EJSONKit

```swift
import EJSONKit

// Key generation
let keyPair: EJSONKit.KeyPair = try EJSONKit.generateKeyPair()

// Value encryption/decryption
let encrypted = try EJSONKit.encrypt("secret", publicKey: key)
let decrypted = try EJSONKit.decrypt(encrypted, privateKey: key)

// File operations
let manager = EJSONKit.Manager()
try manager.encryptFile(at: path, publicKey: key)
```

### Core Components

1. **Key Management**
   - Generate keypairs (32-byte Curve25519 keys)
   - Format: 64-character hex strings
   - Functions: `generateKeyPair() -> (publicKey: String, privateKey: String)`

2. **Value Encryption/Decryption**
   - Encrypt individual string values
   - Format: `EJ[1:ephemeral_pk:nonce:ciphertext]`
   - Base64 encoding for binary data
   - NaCl Box encryption (Curve25519 + Salsa20 + Poly1305)

3. **Recursive JSON Processing**
   - Walk JSON tree and encrypt string values
   - Preserve structure (objects, arrays, types)
   - Special handling for `_public_key` field (never encrypt)
   - Support nested structures

4. **File Operations**
   - Read/write EJSON files
   - Validate format
   - Extract public key from files

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

- **`1`**: Version number
- **`ephemeral_pk`**: Base64-encoded ephemeral public key (32 bytes)
- **`nonce`**: Base64-encoded nonce (24 bytes)
- **`ciphertext`**: Base64-encoded encrypted data

## Dependencies

### swift-sodium (v0.9.1+)
- **Repository:** https://github.com/jedisct1/swift-sodium
- **Provides:** NaCl cryptography primitives
- **Includes:** Precompiled Clibsodium.xcframework
- **No external tools required**

## Development Guidelines

### Compatibility Requirements
1. **Must be compatible with Go EJSON**
   - Encrypted files must decrypt with Go ejson
   - Files encrypted by Go ejson must decrypt in Swift
   - Identical format for all components

2. **Format Compliance**
   - Exact `EJ[1:...]` format
   - Base64 encoding (standard, not URL-safe)
   - 64-character hex for public keys
   - Preserve `_public_key` field

### Testing Strategy
1. Start with single-value encryption/decryption
2. Create test files with Go ejson, decrypt in Swift
3. Create test files in Swift, decrypt with Go ejson
4. Test recursive JSON processing
5. Test edge cases: unicode, nested structures, arrays

### Error Handling
- Invalid key formats
- Corrupted encrypted data
- Format mismatches
- Missing `_public_key` field
- Type preservation errors

## Key Design Decisions

### Naming
- **Repository:** `swift-ejson` (follows Swift package conventions)
- **Module:** `EJSONKit` (Apple-style framework naming)
- **Rationale:** Professional feel, clean imports, unlikely conflicts

### API Design
```swift
public struct EJSON {
    private let sodium = Sodium()

    public func generateKeyPair() throws -> (publicKey: String, privateKey: String)
    public func encrypt(_ plaintext: String, publicKey: String) throws -> String
    public func decrypt(_ ciphertext: String, privateKey: String) throws -> String
    public func encryptFile(at path: String, publicKey: String) throws
    public func decryptFile(at path: String, privateKey: String) throws -> [String: Any]
}
```

## Implementation Approach

1. **Start small:** Basic encrypt/decrypt of single values
2. **Verify compatibility:** Cross-test with Go ejson
3. **Build incrementally:** Add recursive JSON support
4. **Test extensively:** Use Go ejson as reference

## Main Challenges

1. **Format compatibility** - Must match Go implementation exactly
2. **Recursive encryption** - Walk JSON tree correctly
3. **Type preservation** - Distinguish encrypted vs. plain values
4. **Error handling** - Graceful handling of invalid data
5. **Public key handling** - Never encrypt `_public_key` field

## References

- **EJSON Go Library:** https://github.com/Shopify/ejson
- **EJSON Format Specification:** https://github.com/Shopify/ejson/blob/master/DESIGN.md
- **NaCl Cryptography:** https://nacl.cr.yp.to/
- **swift-sodium:** https://github.com/jedisct1/swift-sodium

## Project Status

This is a new implementation being developed from scratch. Current branch: `claude/create-claude-m-01BpUYz6ugCSShzyTaWy4nRx`

## Integration Target

This library will be integrated with Xproject's secret management system (EJSONService) to provide standardized EJSON encryption/decryption capabilities.
