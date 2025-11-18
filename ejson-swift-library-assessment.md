# EJSON Swift Library - Implementation Assessment

## Overview

Assessment for creating a Swift equivalent of Shopify's [EJSON Go library](https://github.com/Shopify/ejson), a utility for managing encrypted secrets in source control.

**Reference Implementation:** https://github.com/Shopify/ejson

**Estimated Effort:** 2-3 weeks of focused work

**Difficulty:** Moderate

## Library Naming

**Repository Name:** `swift-ejson`
**Module Name:** `EJSONKit`

### Rationale

- **Repository**: `swift-ejson` follows the Swift package naming convention (matches `swift-sodium` dependency)
- **Module**: `EJSONKit` uses Apple-style framework naming (HealthKit, CoreDataKit, etc.)
- Unlikely to conflict with other packages
- Professional, framework-like feel
- Clean import and usage

### Example Usage

```swift
// Package.swift
name: "swift-ejson"
.library(name: "EJSONKit", targets: ["EJSONKit"])

// Usage in code
import EJSONKit

let manager = EJSONKit.Manager()
try manager.encryptFile(at: path, publicKey: key)

// Or static methods
try EJSONKit.encrypt("secret", publicKey: key)

// Types namespace nicely
let keyPair: EJSONKit.KeyPair = try EJSONKit.generateKeyPair()
```

## What Makes It Easier

1. **Crypto is handled**: swift-sodium provides all the NaCl Box primitives (Curve25519 + Salsa20 + Poly1305) you need
2. **Format is well-defined**: `EJ[1:ephemeral_pk:nonce:ciphertext]` is straightforward
3. **JSON parsing exists**: Swift's Codable handles JSON natively
4. **Reference implementation**: The Go library serves as a specification

## Core Components Needed

### 1. Key Management (~2-3 days)
```swift
- generateKeyPair() -> (publicKey: String, privateKey: String)
- Key format: 32-byte keys as 64-char hex strings
```

### 2. Value Encryption/Decryption (~3-4 days)
```swift
- encrypt(value: String, publicKey: String) -> String  // Returns EJ[1:...]
- decrypt(value: String, privateKey: String) -> String
- Parse/format the EJ[1:...] structure
```

### 3. Recursive JSON Processing (~4-5 days)
```swift
- encryptJSON(json: [String: Any], publicKey: String) -> [String: Any]
- decryptJSON(json: [String: Any], privateKey: String) -> [String: Any]
- Handle nested objects, arrays, preserve _public_key field
```

### 4. File Operations (~2 days)
```swift
- encryptFile(path: String, publicKey: String)
- decryptFile(path: String, privateKey: String) -> [String: Any]
```

### 5. Testing & Compatibility (~5-7 days)
```swift
- Unit tests for each component
- Integration tests with Go ejson files
- Edge cases (nested structures, unicode, etc.)
```

## Main Challenges

1. **Format compatibility**: Must produce output that Go ejson can decrypt and vice versa
2. **Recursive encryption**: Need to walk JSON tree, encrypt string values, preserve structure
3. **Error handling**: Invalid keys, corrupted data, format mismatches
4. **Type preservation**: Distinguish between encrypted strings (`EJ[1:...]`) and plain values
5. **Public key extraction**: Handle `_public_key` field specially

## Recommended Approach

1. **Start small**: Get basic encrypt/decrypt of single values working first
2. **Verify compatibility**: Create test files with Go ejson, decrypt in Swift
3. **Build up**: Add recursive JSON support
4. **Test extensively**: Use Go ejson as reference for test vectors

## Example Core API

```swift
import Sodium
import Foundation

public struct EJSON {
    private let sodium = Sodium()

    public func generateKeyPair() throws -> (publicKey: String, privateKey: String)
    public func encrypt(_ plaintext: String, publicKey: String) throws -> String
    public func decrypt(_ ciphertext: String, privateKey: String) throws -> String
    public func encryptFile(at path: String, publicKey: String) throws
    public func decryptFile(at path: String, privateKey: String) throws -> [String: Any]
}
```

## EJSON File Format

EJSON files contain a JSON object with encrypted values:

```json
{
  "_public_key": "63ccf05a9492e68e12eeb1c705888aebdcc0080af7e594fc402beb24cce9d14f",
  "database_password": "EJ[1:yF4JKMR4RUJY0hcxKYKDOg==:Yw6rqhvtLx7Kdc1hGtxqPBnx9bxk8kAzTCGNZPwVU5c=:ZCaH/xShYQ==]",
  "api_key": "EJ[1:C3s0AexqRVoZV5m0ZkNMrw==:CExNz8HkrQBgCZXH0m5CEnKRzH/tK3pL5RxH1KR9bZc=:1MjPqxJt2xM5y3q=]",
  "nested": {
    "secret": "EJ[1:x7F9KMTR5RUJZ1ida9KDPh==:Zw7sqiwuMy8Ldc2iHuyqQCoy0cyl9lB0UDHOaQxWV6d=:ADcI/yTiZR==]"
  }
}
```

### Format Breakdown

- **`_public_key`**: 64-character hex string (32-byte public key)
- **Encrypted values**: `EJ[1:ephemeral_pk:nonce:ciphertext]`
  - `1`: Version number
  - `ephemeral_pk`: Base64-encoded ephemeral public key
  - `nonce`: Base64-encoded nonce
  - `ciphertext`: Base64-encoded encrypted data

## Dependencies

- **swift-sodium** (v0.9.1+): Provides NaCl cryptography
  - Repository: https://github.com/jedisct1/swift-sodium
  - Includes precompiled Clibsodium.xcframework
  - No external tools required

## Integration with Xproject

This library would be used in Phase 1 of the secret management implementation:

1. **EJSONService** (Sources/Xproject/Services/EJSONService.swift) would use this library
2. Replace direct Sodium calls with EJSON library API
3. Simplify implementation by delegating format handling
4. Improve testability and maintainability

## References

- **EJSON Go Library**: https://github.com/Shopify/ejson
- **EJSON Format Specification**: https://github.com/Shopify/ejson/blob/master/DESIGN.md
- **NaCl Cryptography**: https://nacl.cr.yp.to/
- **swift-sodium**: https://github.com/jedisct1/swift-sodium

## Next Steps

1. Create proof-of-concept for core encryption/decryption
2. Validate format compatibility with Go ejson
3. Implement recursive JSON processing
4. Add comprehensive test suite
5. Integrate with Xproject's secret management system
