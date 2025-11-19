/// Version information for EJSONKit and ejson CLI
///
/// This is the single source of truth for version information.
/// All other version references should derive from this.
public enum Version {
    /// The current version of EJSONKit
    ///
    /// Update this value when preparing a new release.
    /// Format: MAJOR.MINOR.PATCH following Semantic Versioning
    public static let current = "1.0.0"

    /// Full version string with additional information
    public static let full = "ejson version \(current)"

    /// Version description
    public static let description = "Swift EJSON - Compatible with Shopify EJSON"
}
