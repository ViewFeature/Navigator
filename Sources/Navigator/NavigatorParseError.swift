import Foundation

// MARK: - Routing Errors

/// Routing errors used by URL parsing and macro-generated code.
///
/// Protocol conformance:
/// - Error: Standard Swift error handling
/// - LocalizedError: Provides user-friendly error descriptions
/// - Equatable: Enables error comparison in tests and conditional logic
/// - Sendable: Thread-safe for concurrent error handling
public enum NavigatorParseError: Error, LocalizedError, Equatable, Sendable {
	/// Malformed URL string that cannot be parsed.
	case invalidURL(String)

	/// Required query parameter is missing from the URL.
	case missingParameter(name: String)

	/// Query parameter value could not be converted to the expected type.
	case invalidParameter(name: String, value: String, expected: String)

	public var description: String {
		errorDescription ?? "Unknown error"
	}

	public var errorDescription: String? {
		switch self {
		case .invalidURL(let url):
			return "Invalid URL: \(url)"
		case .missingParameter(let name):
			return "Missing required parameter: \(name)"
		case .invalidParameter(let name, let value, let expected):
			return "Invalid parameter '\(name)': got '\(value)', expected \(expected)"
		}
	}
}
