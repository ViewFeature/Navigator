import Foundation

/// Protocol for navigation destinations.
///
/// All conforming types must be Hashable for NavigationStack integration.
/// When using the `@Route` macro, all required conformances (Hashable, Sendable)
/// are generated automatically with nonisolated implementations.
///
/// For manual implementation without the macro:
/// ```swift
/// enum AppRoute: Navigatable {
///     case home
///     case profile(id: String)
///
///     var path: String {
///         switch self {
///         case .home: return "home"
///         case .profile: return "profile"
///         }
///     }
///
///     func url(scheme: String) throws -> URL {
///         // Implementation
///     }
///
///     static func parse(from url: URL) -> Self? {
///         // Implementation
///     }
/// }
/// ```
public protocol Navigatable: Hashable {
	/// The URL path component for this route.
	/// Should not include leading slash for consistency.
	var path: String { get }

	/// Generate URL for this route with the specified scheme.
	/// - Parameter scheme: URL scheme (e.g., "myapp", "example")
	/// - Returns: Valid URL for this route
	/// - Throws: NavigatorParseError.invalidURL if URL construction fails
	func url(scheme: String) throws -> URL

	/// Parse route from URL.
	///
	/// Returns nil for:
	/// - Invalid URL format
	/// - Unknown route path (e.g., scheme-only URLs like "myapp://")
	/// - Missing required parameters
	/// - Invalid parameter types
	///
	/// - Parameter url: URL to parse into route instance
	/// - Returns: Parsed route instance, or nil if parsing fails
	static func parse(from url: URL) -> Self?
}
