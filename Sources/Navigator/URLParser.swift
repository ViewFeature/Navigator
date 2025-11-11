import Foundation

// MARK: - URL Parser

/// Utility for parsing URLs and extracting route components.
///
/// Provides helper methods for:
/// - Route key extraction from URL paths
/// - Query parameter extraction with type conversion
/// - URL construction for custom schemes
///
/// All methods are `nonisolated` because this is a pure utility enum
/// with no mutable state or side effects, allowing calls from any actor context.
public enum URLParser {

	// MARK: - Route Key Extraction

	/// Extract route key from URL path
	///
	/// Examples:
	/// - "/home" → "home"
	/// - "/user/profile" → "user/profile"
	/// - "article" → "article"
	public nonisolated static func routeKey(from path: String) -> String {
		return path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
	}

	/// Parse path components from URL path
	///
	/// Examples:
	/// - "/user/profile" → ["user", "profile"]
	/// - "home" → ["home"]
	public nonisolated static func parsePathComponents(_ path: String) -> [String] {
		let cleanPath = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
		return cleanPath.isEmpty ? [] : cleanPath.split(separator: "/").map(String.init)
	}

	// MARK: - Parameter Extraction

	/// Extract parameter from query items with type conversion.
	///
	/// Type safety: Only supports LosslessStringConvertible types (String, Int, Bool, etc.)
	/// URL decoding: URLQueryItem.value is automatically URL-decoded by Foundation
	/// Performance: O(n) linear search through queryItems array
	///
	/// - Parameters:
	///   - name: Parameter name to extract (case-sensitive)
	///   - queryItems: Array of URL query items to search
	/// - Returns: Converted parameter value (empty strings are valid and processed)
	/// - Throws: NavigatorParseError.missingParameter if not found, .invalidParameter if conversion fails
	public nonisolated static func param<T>(_ name: String, from queryItems: [URLQueryItem]) throws -> T
	where T: LosslessStringConvertible {
		guard let queryItem = queryItems.first(where: { $0.name == name }),
			let value = queryItem.value
		else {
			throw NavigatorParseError.missingParameter(name: name)
		}

		guard let convertedValue = T(value) else {
			throw NavigatorParseError.invalidParameter(name: name, value: value, expected: String(describing: T.self))
		}

		return convertedValue
	}

	/// Extract optional parameter from query items with type conversion.
	///
	/// Returns nil for missing parameters or conversion failures.
	/// Use `param<T>` instead if you need to distinguish between these cases.
	///
	/// - Parameters:
	///   - name: Parameter name to extract (case-sensitive)
	///   - queryItems: Array of URL query items to search
	/// - Returns: Converted value, or nil if missing/invalid
	public nonisolated static func optionalParam<T>(_ name: String, from queryItems: [URLQueryItem]) -> T?
	where T: LosslessStringConvertible {
		guard let queryItem = queryItems.first(where: { $0.name == name }),
			let value = queryItem.value
		else {
			return nil
		}

		return T(value)
	}

	// MARK: - URL Construction

	/// Construct URL from path and query items for custom URL schemes.
	///
	/// For custom schemes (e.g., "myapp://route"), the path is used as the host component.
	/// Query encoding: URLComponents handles proper query parameter encoding automatically.
	///
	/// - Parameters:
	///   - path: Route name (e.g., "home", "profile") - used as URL host
	///   - queryItems: Query parameters (empty array acceptable)
	///   - scheme: Custom URL scheme (e.g., "myapp", "example")
	/// - Returns: Valid URL for deep linking
	/// - Throws: NavigatorParseError.invalidURL if URL construction fails
	public nonisolated static func constructURL(path: String, queryItems: [URLQueryItem], scheme: String) throws -> URL {
		var components = URLComponents()
		components.scheme = scheme
		components.host = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))

		if !queryItems.isEmpty {
			components.queryItems = queryItems
		}

		guard let url = components.url else {
			throw NavigatorParseError.invalidURL("\(scheme)://\(path)")
		}
		return url
	}
}

