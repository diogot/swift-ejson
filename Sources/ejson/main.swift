import Foundation
import EJSONKit

// MARK: - CLI Configuration

let defaultKeyDir = "/opt/ejson/keys"

func getKeyDir() -> String {
    if let envKeyDir = ProcessInfo.processInfo.environment["EJSON_KEYDIR"] {
        return envKeyDir
    }
    return defaultKeyDir
}

// MARK: - Error Handling

enum CLIError: Error, LocalizedError {
    case invalidArguments
    case keyDirNotFound
    case privateKeyNotFound(publicKey: String)
    case invalidCommand

    var errorDescription: String? {
        switch self {
        case .invalidArguments:
            return "Invalid arguments"
        case .keyDirNotFound:
            return "Key directory not found"
        case .privateKeyNotFound(let publicKey):
            return "Private key not found for public key: \(publicKey)"
        case .invalidCommand:
            return "Invalid command"
        }
    }
}

func printError(_ message: String) {
    FileHandle.standardError.write("Error: \(message)\n".data(using: .utf8)!)
}

func exitWithError(_ message: String, code: Int32 = 1) -> Never {
    printError(message)
    exit(code)
}

// MARK: - Key Management

func loadPrivateKey(publicKey: String, keyDir: String) throws -> String {
    let keyPath = "\(keyDir)/\(publicKey)"

    guard let privateKey = try? String(contentsOfFile: keyPath, encoding: .utf8) else {
        throw CLIError.privateKeyNotFound(publicKey: publicKey)
    }

    return privateKey.trimmingCharacters(in: .whitespacesAndNewlines)
}

func savePrivateKey(publicKey: String, privateKey: String, keyDir: String) throws {
    let keyPath = "\(keyDir)/\(publicKey)"

    // Create key directory if it doesn't exist
    let fileManager = FileManager.default
    if !fileManager.fileExists(atPath: keyDir) {
        try fileManager.createDirectory(atPath: keyDir, withIntermediateDirectories: true, attributes: nil)
    }

    try privateKey.write(toFile: keyPath, atomically: true, encoding: .utf8)

    // Set restrictive permissions (0600)
    #if os(Linux) || os(macOS)
    try fileManager.setAttributes([.posixPermissions: 0o600], ofItemAtPath: keyPath)
    #endif
}

// MARK: - Commands

func keygenCommand(args: [String]) {
    var writeToKeyDir = false
    var keyDir = getKeyDir()
    var i = 0

    // Parse options
    while i < args.count {
        let arg = args[i]
        if arg == "-w" {
            writeToKeyDir = true
            i += 1
        } else if arg == "-keydir" {
            i += 1
            if i >= args.count {
                exitWithError("Missing value for -keydir option")
            }
            keyDir = args[i]
            i += 1
        } else {
            exitWithError("Unknown option: \(arg)")
        }
    }

    // Generate keypair
    let ejson = EJSON()
    guard let keyPair = try? ejson.generateKeyPair() else {
        exitWithError("Failed to generate keypair")
    }

    if writeToKeyDir {
        // Write private key to keydir and print only public key
        do {
            try savePrivateKey(publicKey: keyPair.publicKey, privateKey: keyPair.privateKey, keyDir: keyDir)
            print("Public Key:")
            print(keyPair.publicKey)
        } catch {
            exitWithError("Failed to write key to keydir: \(error.localizedDescription)")
        }
    } else {
        // Print both keys
        print("Public Key:")
        print(keyPair.publicKey)
        print("\nPrivate Key:")
        print(keyPair.privateKey)
    }
}

func encryptCommand(args: [String]) {
    let files = args

    if files.isEmpty {
        exitWithError("Usage: ejson encrypt file...")
    }

    // Process each file
    let ejson = EJSON()
    for file in files {
        do {
            // Extract public key from file
            let publicKey = try ejson.extractPublicKey(from: file)

            // Encrypt the file
            try ejson.encryptFile(at: file, publicKey: publicKey)

            print("Encrypted \(file)")
        } catch {
            exitWithError("Failed to encrypt \(file): \(error.localizedDescription)")
        }
    }
}

func decryptCommand(args: [String]) {
    var keyDir = getKeyDir()
    var file: String?
    var i = 0

    // Parse options
    while i < args.count {
        let arg = args[i]
        if arg == "-keydir" {
            i += 1
            if i >= args.count {
                exitWithError("Missing value for -keydir option")
            }
            keyDir = args[i]
            i += 1
        } else if file == nil {
            file = arg
            i += 1
        } else {
            exitWithError("Only one file can be decrypted at a time")
        }
    }

    guard let filePath = file else {
        exitWithError("Usage: ejson decrypt [options] file")
    }

    // Decrypt the file
    let ejson = EJSON()
    do {
        // Extract public key from file
        let publicKey = try ejson.extractPublicKey(from: filePath)

        // Load private key
        let privateKey = try loadPrivateKey(publicKey: publicKey, keyDir: keyDir)

        // Decrypt the file
        let decrypted = try ejson.decryptFile(at: filePath, privateKey: privateKey)

        // Output as JSON
        let jsonData = try JSONSerialization.data(withJSONObject: decrypted, options: [.prettyPrinted, .sortedKeys])
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            print(jsonString)
        }
    } catch CLIError.privateKeyNotFound(let publicKey) {
        exitWithError("Private key not found in \(keyDir)/\(publicKey)")
    } catch {
        exitWithError("Failed to decrypt \(filePath): \(error.localizedDescription)")
    }
}

func printUsage() {
    print("""
    Usage: ejson <command> [options]

    Commands:
      keygen            Generate a new keypair
      encrypt <file>... Encrypt one or more EJSON files
      decrypt <file>    Decrypt an EJSON file

    Global Options:
      -keydir <path>    Path to keydir (default: /opt/ejson/keys or $EJSON_KEYDIR)

    Keygen Options:
      -w                Write private key to keydir and print only public key

    Examples:
      ejson keygen
      ejson keygen -w
      ejson encrypt secrets.ejson
      ejson decrypt secrets.ejson
      ejson -keydir ~/.ejson/keys decrypt secrets.ejson
    """)
}

// MARK: - Main

func main() {
    let args = Array(CommandLine.arguments.dropFirst())

    guard !args.isEmpty else {
        printUsage()
        exit(0)
    }

    let command = args[0]
    let commandArgs = Array(args.dropFirst())

    switch command {
    case "keygen":
        keygenCommand(args: commandArgs)
    case "encrypt":
        encryptCommand(args: commandArgs)
    case "decrypt":
        decryptCommand(args: commandArgs)
    case "-h", "--help", "help":
        printUsage()
    default:
        exitWithError("Unknown command: \(command)\nRun 'ejson help' for usage information")
    }
}

main()
