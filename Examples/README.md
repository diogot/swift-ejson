# EJSONKit Examples

This directory contains example code demonstrating how to use EJSONKit.

## Running Examples

To run these examples, you'll need to have Swift installed and the EJSONKit package available.

### Basic Usage Example

```bash
swift Examples/BasicUsage.swift
```

Demonstrates:
- Key generation
- Single value encryption/decryption
- JSON object encryption/decryption
- Nested structure handling

### File Operations Example

```bash
swift Examples/FileOperations.swift
```

Demonstrates:
- Creating secrets files
- Encrypting files
- Extracting public keys from files
- Decrypting files
- File cleanup

## Example Scenarios

### Scenario 1: Environment Configuration

```swift
import EJSONKit

// Generate keys once
let keyPair = try EJSON.generateKeyPair()

// Store private key in secure location (e.g., environment variable)
// Store public key in your config file

// Create config
let config: [String: Any] = [
    "production": [
        "database_url": "postgresql://user:password@host/db",
        "redis_url": "redis://password@host:6379"
    ],
    "staging": [
        "database_url": "postgresql://user:password@staging-host/db",
        "redis_url": "redis://password@staging-host:6379"
    ]
]

// Encrypt and save
let ejson = EJSON()
let encrypted = try ejson.encryptJSON(config, publicKey: keyPair.publicKey)
let data = try JSONSerialization.data(withJSONObject: encrypted)
try data.write(to: URL(fileURLWithPath: "config/secrets.ejson"))

// Commit to git (safe!)
// git add config/secrets.ejson
// git commit -m "Add encrypted config"
```

### Scenario 2: Decrypting in Production

```swift
import EJSONKit

// Private key from environment variable
guard let privateKey = ProcessInfo.processInfo.environment["EJSON_PRIVATE_KEY"] else {
    fatalError("EJSON_PRIVATE_KEY not set")
}

// Decrypt config
let ejson = EJSON()
let secrets = try ejson.decryptFile(
    at: "config/secrets.ejson",
    privateKey: privateKey
)

// Use the secrets
if let prod = secrets["production"] as? [String: String] {
    let databaseURL = prod["database_url"]
    let redisURL = prod["redis_url"]
    // Connect to services...
}
```

### Scenario 3: CI/CD Integration

```swift
import EJSONKit

// In your build/deploy script
func loadSecrets(for environment: String) throws -> [String: Any] {
    let ejson = EJSON()

    // Private key from CI environment variable
    guard let privateKey = ProcessInfo.processInfo.environment["EJSON_PRIVATE_KEY"] else {
        throw ConfigError.missingPrivateKey
    }

    // Decrypt secrets
    let allSecrets = try ejson.decryptFile(
        at: "config/secrets.ejson",
        privateKey: privateKey
    )

    // Extract environment-specific secrets
    guard let envSecrets = allSecrets[environment] as? [String: Any] else {
        throw ConfigError.invalidEnvironment
    }

    return envSecrets
}

// Usage
let prodSecrets = try loadSecrets(for: "production")
```

### Scenario 4: Rotating Secrets

```swift
import EJSONKit

// Generate new keypair
let newKeyPair = try EJSON.generateKeyPair()
let ejson = EJSON()

// Decrypt with old key
let secrets = try ejson.decryptFile(
    at: "secrets.ejson",
    privateKey: oldPrivateKey
)

// Re-encrypt with new key
try ejson.encryptFile(
    at: "secrets.ejson",
    publicKey: newKeyPair.publicKey
)

print("Rotated to new key: \(newKeyPair.publicKey)")
print("Update EJSON_PRIVATE_KEY to: \(newKeyPair.privateKey)")
```

## Tips

1. **Never commit private keys** - Store them in:
   - Environment variables
   - CI/CD secrets
   - Password managers
   - Secure key vaults

2. **Public keys are safe to commit** - They're in the encrypted files anyway

3. **Use environment-specific configs** - Organize secrets by environment:
   ```json
   {
     "_public_key": "...",
     "development": { ... },
     "staging": { ... },
     "production": { ... }
   }
   ```

4. **Backup private keys** - If you lose the private key, you can't decrypt

5. **Rotate keys periodically** - Generate new keypairs and re-encrypt

## Common Patterns

### Pattern: Singleton Config Manager

```swift
class ConfigManager {
    static let shared = ConfigManager()
    private let ejson = EJSON()
    private var secrets: [String: Any]?

    private init() {}

    func loadSecrets() throws {
        guard let privateKey = ProcessInfo.processInfo.environment["EJSON_PRIVATE_KEY"] else {
            throw ConfigError.missingKey
        }

        secrets = try ejson.decryptFile(
            at: "config/secrets.ejson",
            privateKey: privateKey
        )
    }

    func get(_ key: String) -> Any? {
        return secrets?[key]
    }
}

// Usage
try ConfigManager.shared.loadSecrets()
let dbPassword = ConfigManager.shared.get("database_password") as? String
```

### Pattern: Type-Safe Configuration

```swift
struct AppSecrets: Codable {
    let databasePassword: String
    let apiKey: String
    let stripeKey: String
}

func loadTypedSecrets() throws -> AppSecrets {
    let ejson = EJSON()
    guard let privateKey = ProcessInfo.processInfo.environment["EJSON_PRIVATE_KEY"] else {
        throw ConfigError.missingKey
    }

    let secrets = try ejson.decryptFile(
        at: "secrets.ejson",
        privateKey: privateKey
    )

    let data = try JSONSerialization.data(withJSONObject: secrets)
    return try JSONDecoder().decode(AppSecrets.self, from: data)
}
```
