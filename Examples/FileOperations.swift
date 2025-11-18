import Foundation
import EJSONKit

/// Example demonstrating file encryption/decryption
func fileOperationsExample() {
    do {
        print("=== File Operations Example ===\n")

        let ejson = EJSON()

        // 1. Generate keys
        print("1. Generating keypair...")
        let keyPair = try ejson.generateKeyPair()
        print("   Keys generated ✅\n")

        // 2. Create a secrets file
        print("2. Creating secrets.json file...")
        let tempDir = FileManager.default.temporaryDirectory
        let secretsFile = tempDir.appendingPathComponent("secrets.json")

        let secrets: [String: Any] = [
            "database": [
                "host": "db.example.com",
                "port": 5432,
                "username": "admin",
                "password": "super_secret_password",
                "ssl": true
            ],
            "api_keys": [
                "stripe": "sk_live_51ABC123...",
                "twilio": "AC1234567890abcdef",
                "sendgrid": "SG.abc123..."
            ],
            "encryption": [
                "algorithm": "AES-256",
                "key": "0123456789abcdef0123456789abcdef"
            ]
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: secrets, options: .prettyPrinted)
        try jsonData.write(to: secretsFile)
        print("   File created at: \(secretsFile.path)")
        print("   Original content:")
        if let content = try? String(contentsOf: secretsFile) {
            print("   \(content)\n")
        }

        // 3. Encrypt the file
        print("3. Encrypting secrets.json...")
        try ejson.encryptFile(at: secretsFile.path, publicKey: keyPair.publicKey)
        print("   File encrypted ✅")
        print("   Encrypted content:")
        if let content = try? String(contentsOf: secretsFile) {
            print("   \(content)\n")
        }

        // 4. Extract public key
        print("4. Extracting public key from file...")
        let extractedKey = try ejson.extractPublicKey(from: secretsFile.path)
        print("   Extracted: \(extractedKey)")
        print("   Matches:   \(extractedKey == keyPair.publicKey ? "✅" : "❌")\n")

        // 5. Decrypt the file
        print("5. Decrypting secrets.json...")
        let decrypted = try ejson.decryptFile(at: secretsFile.path, privateKey: keyPair.privateKey)
        print("   File decrypted ✅")

        // 6. Verify decrypted content
        print("\n6. Verifying decrypted content:")
        if let database = decrypted["database"] as? [String: Any] {
            print("   Database host: \(database["host"] as? String ?? "N/A")")
            print("   Database password: \(database["password"] as? String ?? "N/A")")
        }
        if let apiKeys = decrypted["api_keys"] as? [String: String] {
            print("   Stripe key: \(apiKeys["stripe"] ?? "N/A")")
            print("   Twilio key: \(apiKeys["twilio"] ?? "N/A")")
        }

        // 7. Clean up
        print("\n7. Cleaning up...")
        try FileManager.default.removeItem(at: secretsFile)
        print("   Temporary file removed ✅")

        print("\n✅ All file operations completed successfully!")

    } catch let error as EJSON.EJSONError {
        print("❌ EJSON Error: \(error.localizedDescription)")
    } catch {
        print("❌ Unexpected error: \(error)")
    }
}

// Run the example
fileOperationsExample()
