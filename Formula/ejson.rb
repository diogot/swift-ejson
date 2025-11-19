class Ejson < Formula
  desc "Swift implementation of Shopify's EJSON for managing encrypted secrets"
  homepage "https://github.com/diogot/swift-ejson"
  version "1.0.0"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/diogot/swift-ejson/releases/download/v1.0.0/ejson-1.0.0-macos-universal.tar.gz"
      sha256 "PLACEHOLDER_SHA256_WILL_BE_UPDATED_ON_RELEASE"
    else
      url "https://github.com/diogot/swift-ejson/releases/download/v1.0.0/ejson-1.0.0-macos-universal.tar.gz"
      sha256 "PLACEHOLDER_SHA256_WILL_BE_UPDATED_ON_RELEASE"
    end
  end

  def install
    bin.install "ejson"
  end

  test do
    # Test version command
    assert_match "ejson version", shell_output("#{bin}/ejson --version")

    # Test help command
    assert_match "Usage: ejson", shell_output("#{bin}/ejson help")

    # Test keygen command (generates a keypair)
    output = shell_output("#{bin}/ejson keygen")
    assert_match "Public Key:", output
    assert_match "Private Key:", output
  end

  def caveats
    <<~EOS
      ejson has been installed!

      To get started:
        1. Generate a keypair:
           ejson keygen

        2. Create a secrets file with the public key:
           echo '{"_public_key": "YOUR_PUBLIC_KEY", "secret": "value"}' > secrets.json

        3. Encrypt the file:
           ejson encrypt secrets.json

        4. Store the private key in the keydir:
           mkdir -p /opt/ejson/keys
           echo "YOUR_PRIVATE_KEY" > /opt/ejson/keys/YOUR_PUBLIC_KEY

        5. Decrypt the file:
           ejson decrypt secrets.json

      For more information: https://github.com/diogot/swift-ejson
    EOS
  end
end
