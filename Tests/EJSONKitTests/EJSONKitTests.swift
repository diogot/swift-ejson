import XCTest
@testable import EJSONKit

final class EJSONKitTests: XCTestCase {

    // MARK: - Key Generation Tests

    func testKeyPairGeneration() throws {
        let ejson = EJSON()
        let keyPair = try ejson.generateKeyPair()

        // Verify key format (64-character hex strings)
        XCTAssertEqual(keyPair.publicKey.count, 64)
        XCTAssertEqual(keyPair.privateKey.count, 64)

        // Verify keys are valid hex
        XCTAssertNotNil(UInt64(keyPair.publicKey.prefix(16), radix: 16))
        XCTAssertNotNil(UInt64(keyPair.privateKey.prefix(16), radix: 16))

        // Verify keys are different
        XCTAssertNotEqual(keyPair.publicKey, keyPair.privateKey)
    }

    func testStaticKeyPairGeneration() throws {
        let keyPair = try EJSON.generateKeyPair()

        XCTAssertEqual(keyPair.publicKey.count, 64)
        XCTAssertEqual(keyPair.privateKey.count, 64)
    }

    func testMultipleKeyPairsAreUnique() throws {
        let keyPair1 = try EJSON.generateKeyPair()
        let keyPair2 = try EJSON.generateKeyPair()

        XCTAssertNotEqual(keyPair1.publicKey, keyPair2.publicKey)
        XCTAssertNotEqual(keyPair1.privateKey, keyPair2.privateKey)
    }

    // MARK: - Basic Encryption/Decryption Tests

    func testBasicEncryptDecrypt() throws {
        let ejson = EJSON()
        let keyPair = try ejson.generateKeyPair()
        let plaintext = "Hello, EJSON!"

        let encrypted = try ejson.encrypt(plaintext, publicKey: keyPair.publicKey)
        let decrypted = try ejson.decrypt(encrypted, privateKey: keyPair.privateKey)

        XCTAssertEqual(decrypted, plaintext)
    }

    func testEncryptedValueFormat() throws {
        let ejson = EJSON()
        let keyPair = try ejson.generateKeyPair()
        let plaintext = "test"

        let encrypted = try ejson.encrypt(plaintext, publicKey: keyPair.publicKey)

        // Verify format: EJ[1:...:...:...]
        XCTAssertTrue(encrypted.hasPrefix("EJ["))
        XCTAssertTrue(encrypted.hasSuffix("]"))

        let content = String(encrypted.dropFirst(3).dropLast(1))
        let parts = content.split(separator: ":")

        XCTAssertEqual(parts.count, 4)
        XCTAssertEqual(parts[0], "1") // Version
    }

    func testStaticEncryptDecrypt() throws {
        let keyPair = try EJSON.generateKeyPair()
        let plaintext = "Static test"

        let encrypted = try EJSON.encrypt(plaintext, publicKey: keyPair.publicKey)
        let decrypted = try EJSON.decrypt(encrypted, privateKey: keyPair.privateKey)

        XCTAssertEqual(decrypted, plaintext)
    }

    func testEncryptDecryptEmptyString() throws {
        let keyPair = try EJSON.generateKeyPair()
        let plaintext = ""

        let encrypted = try EJSON.encrypt(plaintext, publicKey: keyPair.publicKey)
        let decrypted = try EJSON.decrypt(encrypted, privateKey: keyPair.privateKey)

        XCTAssertEqual(decrypted, plaintext)
    }

    func testEncryptDecryptUnicode() throws {
        let keyPair = try EJSON.generateKeyPair()
        let plaintext = "Hello, 世界! 🌍 Привет"

        let encrypted = try EJSON.encrypt(plaintext, publicKey: keyPair.publicKey)
        let decrypted = try EJSON.decrypt(encrypted, privateKey: keyPair.privateKey)

        XCTAssertEqual(decrypted, plaintext)
    }

    func testEncryptDecryptLongString() throws {
        let keyPair = try EJSON.generateKeyPair()
        let plaintext = String(repeating: "A", count: 10000)

        let encrypted = try EJSON.encrypt(plaintext, publicKey: keyPair.publicKey)
        let decrypted = try EJSON.decrypt(encrypted, privateKey: keyPair.privateKey)

        XCTAssertEqual(decrypted, plaintext)
    }

    func testDecryptWithWrongKey() throws {
        let keyPair1 = try EJSON.generateKeyPair()
        let keyPair2 = try EJSON.generateKeyPair()
        let plaintext = "Secret"

        let encrypted = try EJSON.encrypt(plaintext, publicKey: keyPair1.publicKey)

        // Attempting to decrypt with wrong key should fail
        XCTAssertThrowsError(try EJSON.decrypt(encrypted, privateKey: keyPair2.privateKey)) { error in
            XCTAssertEqual(error as? EJSON.EJSONError, .decryptionFailed)
        }
    }

    func testDecryptInvalidFormat() throws {
        let keyPair = try EJSON.generateKeyPair()
        let invalidFormats = [
            "not encrypted",
            "EJ[invalid]",
            "EJ[1:only:two:parts]extra",
            "EJ[2:wrong:version:here]",
            "",
        ]

        for invalid in invalidFormats {
            XCTAssertThrowsError(try EJSON.decrypt(invalid, privateKey: keyPair.privateKey)) { error in
                XCTAssert(error is EJSON.EJSONError)
            }
        }
    }

    // MARK: - JSON Encryption/Decryption Tests

    func testEncryptJSONSimple() throws {
        let ejson = EJSON()
        let keyPair = try ejson.generateKeyPair()

        let json: [String: Any] = [
            "username": "admin",
            "password": "secret123"
        ]

        let encrypted = try ejson.encryptJSON(json, publicKey: keyPair.publicKey)

        // Verify _public_key was added
        XCTAssertEqual(encrypted["_public_key"] as? String, keyPair.publicKey)

        // Verify values are encrypted
        let encryptedPassword = encrypted["password"] as? String
        XCTAssertNotNil(encryptedPassword)
        XCTAssertTrue(encryptedPassword!.hasPrefix("EJ["))

        let encryptedUsername = encrypted["username"] as? String
        XCTAssertNotNil(encryptedUsername)
        XCTAssertTrue(encryptedUsername!.hasPrefix("EJ["))
    }

    func testDecryptJSONSimple() throws {
        let ejson = EJSON()
        let keyPair = try ejson.generateKeyPair()

        let json: [String: Any] = [
            "username": "admin",
            "password": "secret123"
        ]

        let encrypted = try ejson.encryptJSON(json, publicKey: keyPair.publicKey)
        let decrypted = try ejson.decryptJSON(encrypted, privateKey: keyPair.privateKey)

        // Verify values are decrypted
        XCTAssertEqual(decrypted["username"] as? String, "admin")
        XCTAssertEqual(decrypted["password"] as? String, "secret123")

        // Verify _public_key is preserved
        XCTAssertEqual(decrypted["_public_key"] as? String, keyPair.publicKey)
    }

    func testEncryptJSONNested() throws {
        let ejson = EJSON()
        let keyPair = try ejson.generateKeyPair()

        let json: [String: Any] = [
            "database": [
                "host": "localhost",
                "password": "db_secret"
            ],
            "api_key": "api_secret"
        ]

        let encrypted = try ejson.encryptJSON(json, publicKey: keyPair.publicKey)
        let decrypted = try ejson.decryptJSON(encrypted, privateKey: keyPair.privateKey)

        // Verify nested values
        let database = decrypted["database"] as? [String: Any]
        XCTAssertNotNil(database)
        XCTAssertEqual(database?["host"] as? String, "localhost")
        XCTAssertEqual(database?["password"] as? String, "db_secret")
        XCTAssertEqual(decrypted["api_key"] as? String, "api_secret")
    }

    func testEncryptJSONWithArrays() throws {
        let ejson = EJSON()
        let keyPair = try ejson.generateKeyPair()

        let json: [String: Any] = [
            "secrets": ["secret1", "secret2", "secret3"],
            "config": [
                "hosts": ["host1", "host2"]
            ]
        ]

        let encrypted = try ejson.encryptJSON(json, publicKey: keyPair.publicKey)
        let decrypted = try ejson.decryptJSON(encrypted, privateKey: keyPair.privateKey)

        // Verify arrays
        let secrets = decrypted["secrets"] as? [String]
        XCTAssertNotNil(secrets)
        XCTAssertEqual(secrets?.count, 3)
        XCTAssertEqual(secrets?[0], "secret1")
        XCTAssertEqual(secrets?[1], "secret2")
        XCTAssertEqual(secrets?[2], "secret3")

        let config = decrypted["config"] as? [String: Any]
        let hosts = config?["hosts"] as? [String]
        XCTAssertEqual(hosts?.count, 2)
        XCTAssertEqual(hosts?[0], "host1")
        XCTAssertEqual(hosts?[1], "host2")
    }

    func testEncryptJSONMixedTypes() throws {
        let ejson = EJSON()
        let keyPair = try ejson.generateKeyPair()

        let json: [String: Any] = [
            "string": "value",
            "number": 42,
            "float": 3.14,
            "bool": true,
            "null": NSNull()
        ]

        let encrypted = try ejson.encryptJSON(json, publicKey: keyPair.publicKey)
        let decrypted = try ejson.decryptJSON(encrypted, privateKey: keyPair.privateKey)

        // Verify string is encrypted and decrypted
        XCTAssertEqual(decrypted["string"] as? String, "value")

        // Verify other types are preserved
        XCTAssertEqual(decrypted["number"] as? Int, 42)
        XCTAssertEqual(decrypted["float"] as? Double, 3.14, accuracy: 0.001)
        XCTAssertEqual(decrypted["bool"] as? Bool, true)
        XCTAssertTrue(decrypted["null"] is NSNull)
    }

    func testPublicKeyFieldNeverEncrypted() throws {
        let ejson = EJSON()
        let keyPair = try ejson.generateKeyPair()

        let json: [String: Any] = [
            "_public_key": keyPair.publicKey,
            "password": "secret"
        ]

        let encrypted = try ejson.encryptJSON(json, publicKey: keyPair.publicKey)

        // Verify _public_key is not encrypted
        let publicKey = encrypted["_public_key"] as? String
        XCTAssertEqual(publicKey, keyPair.publicKey)
        XCTAssertFalse(publicKey?.hasPrefix("EJ[") ?? true)

        // Verify password is encrypted
        let password = encrypted["password"] as? String
        XCTAssertTrue(password?.hasPrefix("EJ[") ?? false)
    }

    // MARK: - File Operations Tests

    func testEncryptDecryptFile() throws {
        let ejson = EJSON()
        let keyPair = try ejson.generateKeyPair()

        // Create a test file
        let tempDir = FileManager.default.temporaryDirectory
        let testFile = tempDir.appendingPathComponent("test_\(UUID().uuidString).json")

        let json: [String: Any] = [
            "database_password": "super_secret",
            "api_key": "my_api_key",
            "nested": [
                "secret": "nested_secret"
            ]
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
        try jsonData.write(to: testFile)

        // Encrypt the file
        try ejson.encryptFile(at: testFile.path, publicKey: keyPair.publicKey)

        // Verify file was encrypted
        let encryptedData = try Data(contentsOf: testFile)
        let encryptedJSON = try JSONSerialization.jsonObject(with: encryptedData) as? [String: Any]
        XCTAssertNotNil(encryptedJSON)
        XCTAssertEqual(encryptedJSON?["_public_key"] as? String, keyPair.publicKey)

        let encryptedPassword = encryptedJSON?["database_password"] as? String
        XCTAssertTrue(encryptedPassword?.hasPrefix("EJ[") ?? false)

        // Decrypt the file
        let decrypted = try ejson.decryptFile(at: testFile.path, privateKey: keyPair.privateKey)

        // Verify decrypted values
        XCTAssertEqual(decrypted["database_password"] as? String, "super_secret")
        XCTAssertEqual(decrypted["api_key"] as? String, "my_api_key")

        let nested = decrypted["nested"] as? [String: Any]
        XCTAssertEqual(nested?["secret"] as? String, "nested_secret")

        // Clean up
        try? FileManager.default.removeItem(at: testFile)
    }

    func testExtractPublicKey() throws {
        let ejson = EJSON()
        let keyPair = try ejson.generateKeyPair()

        // Create a test file with _public_key
        let tempDir = FileManager.default.temporaryDirectory
        let testFile = tempDir.appendingPathComponent("test_\(UUID().uuidString).json")

        let json: [String: Any] = [
            "_public_key": keyPair.publicKey,
            "password": "secret"
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
        try jsonData.write(to: testFile)

        // Extract public key
        let extractedKey = try ejson.extractPublicKey(from: testFile.path)

        XCTAssertEqual(extractedKey, keyPair.publicKey)

        // Clean up
        try? FileManager.default.removeItem(at: testFile)
    }

    func testDecryptFileMissingPublicKey() throws {
        let ejson = EJSON()
        let keyPair = try ejson.generateKeyPair()

        // Create a test file without _public_key
        let tempDir = FileManager.default.temporaryDirectory
        let testFile = tempDir.appendingPathComponent("test_\(UUID().uuidString).json")

        let json: [String: Any] = [
            "password": "secret"
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
        try jsonData.write(to: testFile)

        // Decryption should fail
        XCTAssertThrowsError(try ejson.decryptFile(at: testFile.path, privateKey: keyPair.privateKey)) { error in
            XCTAssertEqual(error as? EJSON.EJSONError, .missingPublicKey)
        }

        // Clean up
        try? FileManager.default.removeItem(at: testFile)
    }

    func testFileNotFound() throws {
        let ejson = EJSON()
        let keyPair = try ejson.generateKeyPair()

        let nonExistentFile = "/tmp/nonexistent_\(UUID().uuidString).json"

        XCTAssertThrowsError(try ejson.encryptFile(at: nonExistentFile, publicKey: keyPair.publicKey)) { error in
            XCTAssertEqual(error as? EJSON.EJSONError, .fileReadError)
        }

        XCTAssertThrowsError(try ejson.decryptFile(at: nonExistentFile, privateKey: keyPair.privateKey)) { error in
            XCTAssertEqual(error as? EJSON.EJSONError, .fileReadError)
        }
    }

    // MARK: - Error Handling Tests

    func testInvalidPublicKeyFormat() throws {
        let ejson = EJSON()

        let invalidKeys = [
            "invalid",
            "short",
            "not_hex_chars_zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz",
            String(repeating: "x", count: 64), // 64 chars but not hex
        ]

        for invalidKey in invalidKeys {
            XCTAssertThrowsError(try ejson.encrypt("test", publicKey: invalidKey)) { error in
                XCTAssert(error is EJSON.EJSONError)
            }
        }
    }

    func testInvalidPrivateKeyFormat() throws {
        let ejson = EJSON()
        let keyPair = try ejson.generateKeyPair()
        let encrypted = try ejson.encrypt("test", publicKey: keyPair.publicKey)

        let invalidKeys = [
            "invalid",
            "short",
            String(repeating: "x", count: 64),
        ]

        for invalidKey in invalidKeys {
            XCTAssertThrowsError(try ejson.decrypt(encrypted, privateKey: invalidKey)) { error in
                XCTAssert(error is EJSON.EJSONError)
            }
        }
    }

    // MARK: - Edge Cases

    func testEncryptAlreadyEncryptedValue() throws {
        let ejson = EJSON()
        let keyPair = try ejson.generateKeyPair()

        let plaintext = "secret"
        let encrypted1 = try ejson.encrypt(plaintext, publicKey: keyPair.publicKey)

        // Encrypting an already encrypted value should not double-encrypt in JSON context
        let json: [String: Any] = ["password": encrypted1]
        let encryptedJSON = try ejson.encryptJSON(json, publicKey: keyPair.publicKey)

        // The value should remain encrypted (not double-encrypted)
        let password = encryptedJSON["password"] as? String
        XCTAssertEqual(password, encrypted1)

        // Should still decrypt correctly
        let decrypted = try ejson.decryptJSON(encryptedJSON, privateKey: keyPair.privateKey)
        XCTAssertEqual(decrypted["password"] as? String, plaintext)
    }

    func testDecryptPlainValue() throws {
        let ejson = EJSON()
        let keyPair = try ejson.generateKeyPair()

        // Plain values in JSON should remain plain
        let json: [String: Any] = [
            "_public_key": keyPair.publicKey,
            "plain_value": "not_encrypted"
        ]

        let decrypted = try ejson.decryptJSON(json, privateKey: keyPair.privateKey)
        XCTAssertEqual(decrypted["plain_value"] as? String, "not_encrypted")
    }

    func testSpecialCharactersInValues() throws {
        let keyPair = try EJSON.generateKeyPair()

        let specialStrings = [
            "with:colons:in:it",
            "with[brackets]",
            "with]closing]brackets",
            "EJ[looks like encrypted but isn't]",
            "with\nnewlines\nand\ttabs",
            #"with "quotes" and 'apostrophes'"#,
        ]

        for special in specialStrings {
            let encrypted = try EJSON.encrypt(special, publicKey: keyPair.publicKey)
            let decrypted = try EJSON.decrypt(encrypted, privateKey: keyPair.privateKey)
            XCTAssertEqual(decrypted, special, "Failed for: \(special)")
        }
    }

    func testDeeplyNestedJSON() throws {
        let ejson = EJSON()
        let keyPair = try ejson.generateKeyPair()

        let json: [String: Any] = [
            "level1": [
                "level2": [
                    "level3": [
                        "level4": [
                            "level5": "deep_secret"
                        ]
                    ]
                ]
            ]
        ]

        let encrypted = try ejson.encryptJSON(json, publicKey: keyPair.publicKey)
        let decrypted = try ejson.decryptJSON(encrypted, privateKey: keyPair.privateKey)

        // Navigate to deep value
        let level1 = decrypted["level1"] as? [String: Any]
        let level2 = level1?["level2"] as? [String: Any]
        let level3 = level2?["level3"] as? [String: Any]
        let level4 = level3?["level4"] as? [String: Any]
        let level5 = level4?["level5"] as? String

        XCTAssertEqual(level5, "deep_secret")
    }

    // MARK: - Performance Tests

    func testPerformanceKeyGeneration() throws {
        measure {
            for _ in 0..<10 {
                _ = try? EJSON.generateKeyPair()
            }
        }
    }

    func testPerformanceEncryption() throws {
        let keyPair = try EJSON.generateKeyPair()
        let plaintext = "test secret"

        measure {
            for _ in 0..<100 {
                _ = try? EJSON.encrypt(plaintext, publicKey: keyPair.publicKey)
            }
        }
    }

    func testPerformanceDecryption() throws {
        let keyPair = try EJSON.generateKeyPair()
        let plaintext = "test secret"
        let encrypted = try EJSON.encrypt(plaintext, publicKey: keyPair.publicKey)

        measure {
            for _ in 0..<100 {
                _ = try? EJSON.decrypt(encrypted, privateKey: keyPair.privateKey)
            }
        }
    }
}
