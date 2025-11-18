import Foundation
import EJSONKit

/// Example demonstrating basic EJSON usage
func basicUsageExample() {
    do {
        print("=== Basic EJSON Usage Example ===\n")

        // 1. Generate a keypair
        print("1. Generating keypair...")
        let keyPair = try EJSON.generateKeyPair()
        print("   Public Key:  \(keyPair.publicKey)")
        print("   Private Key: \(keyPair.privateKey)\n")

        // 2. Encrypt a single value
        print("2. Encrypting a secret value...")
        let plaintext = "my_database_password"
        let encrypted = try EJSON.encrypt(plaintext, publicKey: keyPair.publicKey)
        print("   Plaintext:  \(plaintext)")
        print("   Encrypted:  \(encrypted)\n")

        // 3. Decrypt the value
        print("3. Decrypting the value...")
        let decrypted = try EJSON.decrypt(encrypted, privateKey: keyPair.privateKey)
        print("   Decrypted:  \(decrypted)")
        print("   Matches:    \(decrypted == plaintext ? "✅" : "❌")\n")

        // 4. Encrypt a JSON object
        print("4. Encrypting a JSON object...")
        let ejson = EJSON()
        let secrets: [String: Any] = [
            "database_password": "super_secret_123",
            "api_key": "sk_live_abc123",
            "nested": [
                "secret": "nested_value"
            ]
        ]

        let encryptedJSON = try ejson.encryptJSON(secrets, publicKey: keyPair.publicKey)
        print("   Encrypted JSON:")
        if let jsonData = try? JSONSerialization.data(withJSONObject: encryptedJSON, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print("   \(jsonString)\n")
        }

        // 5. Decrypt the JSON object
        print("5. Decrypting the JSON object...")
        let decryptedJSON = try ejson.decryptJSON(encryptedJSON, privateKey: keyPair.privateKey)
        print("   Database password: \(decryptedJSON["database_password"] as? String ?? "N/A")")
        print("   API key: \(decryptedJSON["api_key"] as? String ?? "N/A")")
        if let nested = decryptedJSON["nested"] as? [String: Any] {
            print("   Nested secret: \(nested["secret"] as? String ?? "N/A")")
        }

        print("\n✅ All operations completed successfully!")

    } catch let error as EJSON.EJSONError {
        print("❌ EJSON Error: \(error.localizedDescription)")
    } catch {
        print("❌ Unexpected error: \(error)")
    }
}

// Run the example
basicUsageExample()
