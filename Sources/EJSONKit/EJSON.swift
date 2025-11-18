import Foundation
import Clibsodium

/// EJSONKit provides encryption and decryption of JSON files using NaCl cryptography.
/// Compatible with Shopify's EJSON format: https://github.com/Shopify/ejson
public struct EJSON {

    // MARK: - Types

    /// A cryptographic key pair for EJSON encryption/decryption
    public struct KeyPair {
        /// 64-character hex string representing the public key
        public let publicKey: String
        /// 64-character hex string representing the private key
        public let privateKey: String

        public init(publicKey: String, privateKey: String) {
            self.publicKey = publicKey
            self.privateKey = privateKey
        }
    }

    /// Errors that can occur during EJSON operations
    public enum EJSONError: Error, LocalizedError {
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

        public var errorDescription: String? {
            switch self {
            case .sodiumInitializationFailed:
                return "Failed to initialize libsodium"
            case .invalidKeyFormat:
                return "Invalid key format (expected 64-character hex string)"
            case .invalidHexString:
                return "Invalid hexadecimal string"
            case .invalidBase64String:
                return "Invalid base64 string"
            case .encryptionFailed:
                return "Encryption operation failed"
            case .decryptionFailed:
                return "Decryption operation failed"
            case .invalidEncryptedFormat:
                return "Invalid encrypted value format (expected EJ[1:...])"
            case .invalidJSONData:
                return "Invalid JSON data"
            case .missingPublicKey:
                return "Missing _public_key field in EJSON file"
            case .fileNotFound:
                return "File not found"
            case .fileReadError:
                return "Failed to read file"
            case .fileWriteError:
                return "Failed to write file"
            }
        }
    }

    // MARK: - Constants

    private static let publicKeyField = "_public_key"
    private static let ejsonPrefix = "EJ["
    private static let ejsonVersion = "1"

    // MARK: - Initialization

    public init() {
        // Initialize libsodium
        if sodium_init() < 0 {
            // Initialization already happened or failed
            // We'll check during actual operations
        }
    }

    // MARK: - Key Management

    /// Generate a new cryptographic key pair for EJSON operations
    /// - Returns: A KeyPair containing public and private keys as 64-character hex strings
    /// - Throws: EJSONError if key generation fails
    public func generateKeyPair() throws -> KeyPair {
        guard sodium_init() >= 0 else {
            throw EJSONError.sodiumInitializationFailed
        }

        var publicKey = [UInt8](repeating: 0, count: Int(crypto_box_PUBLICKEYBYTES))
        var privateKey = [UInt8](repeating: 0, count: Int(crypto_box_SECRETKEYBYTES))

        guard crypto_box_keypair(&publicKey, &privateKey) == 0 else {
            throw EJSONError.encryptionFailed
        }

        let publicKeyHex = publicKey.map { String(format: "%02x", $0) }.joined()
        let privateKeyHex = privateKey.map { String(format: "%02x", $0) }.joined()

        return KeyPair(publicKey: publicKeyHex, privateKey: privateKeyHex)
    }

    // MARK: - Value Encryption/Decryption

    /// Encrypt a plaintext string using a public key
    /// - Parameters:
    ///   - plaintext: The string to encrypt
    ///   - publicKey: 64-character hex string representing the public key
    /// - Returns: Encrypted string in EJ[1:ephemeral_pk:nonce:ciphertext] format
    /// - Throws: EJSONError if encryption fails
    public func encrypt(_ plaintext: String, publicKey: String) throws -> String {
        guard sodium_init() >= 0 else {
            throw EJSONError.sodiumInitializationFailed
        }

        // Validate and convert public key from hex
        let recipientPublicKey = try hexToBytes(publicKey)
        guard recipientPublicKey.count == crypto_box_PUBLICKEYBYTES else {
            throw EJSONError.invalidKeyFormat
        }

        // Convert plaintext to bytes
        guard let messageBytes = plaintext.data(using: .utf8) else {
            throw EJSONError.encryptionFailed
        }
        let message = [UInt8](messageBytes)

        // Generate ephemeral keypair for this encryption
        var ephemeralPublicKey = [UInt8](repeating: 0, count: Int(crypto_box_PUBLICKEYBYTES))
        var ephemeralPrivateKey = [UInt8](repeating: 0, count: Int(crypto_box_SECRETKEYBYTES))

        guard crypto_box_keypair(&ephemeralPublicKey, &ephemeralPrivateKey) == 0 else {
            throw EJSONError.encryptionFailed
        }

        // Generate random nonce
        var nonce = [UInt8](repeating: 0, count: Int(crypto_box_NONCEBYTES))
        randombytes_buf(&nonce, nonce.count)

        // Encrypt the message
        var ciphertext = [UInt8](repeating: 0, count: message.count + Int(crypto_box_MACBYTES))

        let result = crypto_box_easy(
            &ciphertext,
            message,
            UInt64(message.count),
            nonce,
            recipientPublicKey,
            ephemeralPrivateKey
        )

        guard result == 0 else {
            throw EJSONError.encryptionFailed
        }

        // Format as EJ[1:ephemeral_pk:nonce:ciphertext]
        let ephemeralPkBase64 = Data(ephemeralPublicKey).base64EncodedString()
        let nonceBase64 = Data(nonce).base64EncodedString()
        let ciphertextBase64 = Data(ciphertext).base64EncodedString()

        return "EJ[1:\(ephemeralPkBase64):\(nonceBase64):\(ciphertextBase64)]"
    }

    /// Decrypt an encrypted string using a private key
    /// - Parameters:
    ///   - ciphertext: Encrypted string in EJ[1:...] format
    ///   - privateKey: 64-character hex string representing the private key
    /// - Returns: Decrypted plaintext string
    /// - Throws: EJSONError if decryption fails or format is invalid
    public func decrypt(_ ciphertext: String, privateKey: String) throws -> String {
        guard sodium_init() >= 0 else {
            throw EJSONError.sodiumInitializationFailed
        }

        // Parse the EJ[1:...] format
        let components = try parseEncryptedValue(ciphertext)

        // Validate and convert private key from hex
        let recipientPrivateKey = try hexToBytes(privateKey)
        guard recipientPrivateKey.count == crypto_box_SECRETKEYBYTES else {
            throw EJSONError.invalidKeyFormat
        }

        // Decrypt the message
        var decrypted = [UInt8](repeating: 0, count: components.ciphertext.count - Int(crypto_box_MACBYTES))

        let result = crypto_box_open_easy(
            &decrypted,
            components.ciphertext,
            UInt64(components.ciphertext.count),
            components.nonce,
            components.ephemeralPublicKey,
            recipientPrivateKey
        )

        guard result == 0 else {
            throw EJSONError.decryptionFailed
        }

        // Convert decrypted bytes to string
        guard let plaintext = String(bytes: decrypted, encoding: .utf8) else {
            throw EJSONError.decryptionFailed
        }

        return plaintext
    }

    // MARK: - JSON Processing

    /// Recursively encrypt all string values in a JSON object
    /// - Parameters:
    ///   - json: JSON object as [String: Any]
    ///   - publicKey: 64-character hex string representing the public key
    /// - Returns: JSON object with encrypted string values
    /// - Throws: EJSONError if encryption fails
    public func encryptJSON(_ json: [String: Any], publicKey: String) throws -> [String: Any] {
        var result = json

        // Add or preserve the _public_key field
        result[Self.publicKeyField] = publicKey

        // Recursively encrypt values
        for (key, value) in json {
            // Never encrypt the _public_key field
            if key == Self.publicKeyField {
                continue
            }

            result[key] = try encryptValue(value, publicKey: publicKey)
        }

        return result
    }

    /// Recursively decrypt all encrypted values in a JSON object
    /// - Parameters:
    ///   - json: JSON object with encrypted values
    ///   - privateKey: 64-character hex string representing the private key
    /// - Returns: JSON object with decrypted string values
    /// - Throws: EJSONError if decryption fails
    public func decryptJSON(_ json: [String: Any], privateKey: String) throws -> [String: Any] {
        var result = json

        for (key, value) in json {
            // Never decrypt the _public_key field
            if key == Self.publicKeyField {
                continue
            }

            result[key] = try decryptValue(value, privateKey: privateKey)
        }

        return result
    }

    // MARK: - File Operations

    /// Encrypt a JSON file
    /// - Parameters:
    ///   - path: Path to the JSON file
    ///   - publicKey: 64-character hex string representing the public key
    /// - Throws: EJSONError if file operations or encryption fails
    public func encryptFile(at path: String, publicKey: String) throws {
        // Read the file
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            throw EJSONError.fileReadError
        }

        // Parse JSON
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw EJSONError.invalidJSONData
        }

        // Encrypt the JSON
        let encrypted = try encryptJSON(json, publicKey: publicKey)

        // Write back to file
        let outputData = try JSONSerialization.data(withJSONObject: encrypted, options: [.prettyPrinted, .sortedKeys])

        do {
            try outputData.write(to: URL(fileURLWithPath: path))
        } catch {
            throw EJSONError.fileWriteError
        }
    }

    /// Decrypt a JSON file
    /// - Parameters:
    ///   - path: Path to the encrypted JSON file
    ///   - privateKey: 64-character hex string representing the private key
    /// - Returns: Decrypted JSON object
    /// - Throws: EJSONError if file operations or decryption fails
    public func decryptFile(at path: String, privateKey: String) throws -> [String: Any] {
        // Read the file
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            throw EJSONError.fileReadError
        }

        // Parse JSON
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw EJSONError.invalidJSONData
        }

        // Verify _public_key exists
        guard json[Self.publicKeyField] != nil else {
            throw EJSONError.missingPublicKey
        }

        // Decrypt the JSON
        return try decryptJSON(json, privateKey: privateKey)
    }

    /// Extract the public key from an EJSON file
    /// - Parameter path: Path to the EJSON file
    /// - Returns: The public key as a 64-character hex string
    /// - Throws: EJSONError if file operations fail or public key is missing
    public func extractPublicKey(from path: String) throws -> String {
        // Read the file
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            throw EJSONError.fileReadError
        }

        // Parse JSON
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw EJSONError.invalidJSONData
        }

        // Extract public key
        guard let publicKey = json[Self.publicKeyField] as? String else {
            throw EJSONError.missingPublicKey
        }

        return publicKey
    }

    // MARK: - Helper Methods

    /// Recursively encrypt a value (handles strings, objects, and arrays)
    private func encryptValue(_ value: Any, publicKey: String) throws -> Any {
        if let stringValue = value as? String {
            // Only encrypt if it's not already encrypted
            if stringValue.hasPrefix(Self.ejsonPrefix) {
                return stringValue
            }
            return try encrypt(stringValue, publicKey: publicKey)
        } else if let dictValue = value as? [String: Any] {
            var result = [String: Any]()
            for (key, val) in dictValue {
                result[key] = try encryptValue(val, publicKey: publicKey)
            }
            return result
        } else if let arrayValue = value as? [Any] {
            return try arrayValue.map { try encryptValue($0, publicKey: publicKey) }
        } else {
            // Return other types as-is (numbers, booleans, null)
            return value
        }
    }

    /// Recursively decrypt a value (handles strings, objects, and arrays)
    private func decryptValue(_ value: Any, privateKey: String) throws -> Any {
        if let stringValue = value as? String {
            // Only decrypt if it's in EJ[...] format
            if stringValue.hasPrefix(Self.ejsonPrefix) {
                return try decrypt(stringValue, privateKey: privateKey)
            }
            return stringValue
        } else if let dictValue = value as? [String: Any] {
            var result = [String: Any]()
            for (key, val) in dictValue {
                result[key] = try decryptValue(val, privateKey: privateKey)
            }
            return result
        } else if let arrayValue = value as? [Any] {
            return try arrayValue.map { try decryptValue($0, privateKey: privateKey) }
        } else {
            // Return other types as-is (numbers, booleans, null)
            return value
        }
    }

    /// Parse an encrypted value in EJ[1:ephemeral_pk:nonce:ciphertext] format
    private func parseEncryptedValue(_ encrypted: String) throws -> (ephemeralPublicKey: [UInt8], nonce: [UInt8], ciphertext: [UInt8]) {
        // Check format: EJ[1:...:...:...]
        guard encrypted.hasPrefix("EJ[") && encrypted.hasSuffix("]") else {
            throw EJSONError.invalidEncryptedFormat
        }

        // Remove prefix and suffix
        let content = String(encrypted.dropFirst(3).dropLast(1))
        let parts = content.split(separator: ":")

        guard parts.count == 4 && parts[0] == Self.ejsonVersion else {
            throw EJSONError.invalidEncryptedFormat
        }

        // Decode components
        guard let ephemeralPkData = Data(base64Encoded: String(parts[1])),
              let nonceData = Data(base64Encoded: String(parts[2])),
              let ciphertextData = Data(base64Encoded: String(parts[3])) else {
            throw EJSONError.invalidBase64String
        }

        return (
            ephemeralPublicKey: [UInt8](ephemeralPkData),
            nonce: [UInt8](nonceData),
            ciphertext: [UInt8](ciphertextData)
        )
    }

    /// Convert hex string to bytes
    private func hexToBytes(_ hex: String) throws -> [UInt8] {
        guard hex.count % 2 == 0 else {
            throw EJSONError.invalidHexString
        }

        var bytes = [UInt8]()
        var index = hex.startIndex

        while index < hex.endIndex {
            let nextIndex = hex.index(index, offsetBy: 2)
            let byteString = hex[index..<nextIndex]

            guard let byte = UInt8(byteString, radix: 16) else {
                throw EJSONError.invalidHexString
            }

            bytes.append(byte)
            index = nextIndex
        }

        return bytes
    }
}

// MARK: - Convenience Extensions

extension EJSON {
    /// Static convenience method for generating keypairs
    public static func generateKeyPair() throws -> KeyPair {
        return try EJSON().generateKeyPair()
    }

    /// Static convenience method for encrypting values
    public static func encrypt(_ plaintext: String, publicKey: String) throws -> String {
        return try EJSON().encrypt(plaintext, publicKey: publicKey)
    }

    /// Static convenience method for decrypting values
    public static func decrypt(_ ciphertext: String, privateKey: String) throws -> String {
        return try EJSON().decrypt(ciphertext, privateKey: privateKey)
    }
}
