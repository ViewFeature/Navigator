import Foundation

// MARK: - Route Macro

/// Auto-generates Navigatable protocol implementation for enums.
///
/// This macro analyzes enum cases and generates:
/// - `path` property for URL path component
/// - `url(scheme:) throws` method for URL generation
/// - `parse(from:) -> Self?` static method for URL parsing (returns nil on failure)
/// - `Navigatable` and `Sendable` protocol conformance
///
/// ## Basic Usage
/// ```swift
/// @Route
/// enum AppRoute {
///     case home
///     case profile(id: String)
///     case settings
/// }
/// ```
///
/// ## Custom Paths
/// ```swift
/// @Route(customPaths: [
///     "profile": "/user/profile",
///     "settings": "/app/settings"
/// ])
/// enum AppRoute {
///     case home
///     case profile(id: String)
///     case settings
/// }
/// ```
///
/// ## Parameters
/// - Associated values are automatically treated as query parameters
/// - Parameter names become query parameter names
/// - Supports `LosslessStringConvertible` types (String, Int, Bool, Double, etc.)
///
/// ## Swift 6 Concurrency
/// For Xcode projects with `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`,
/// no additional attributes are needed:
/// ```swift
/// @Route
/// enum AppRoute {
///     case home
///     case profile(id: String)
/// }
/// ```
///
/// For projects without default MainActor isolation, add `@MainActor`:
/// ```swift
/// @Route
/// @MainActor
/// enum AppRoute {
///     case home
///     case profile(id: String)
/// }
/// ```
@attached(member, names: named(path), named(url(scheme:)), named(parse(from:)), named(hash(into:)), named(==))
@attached(extension, conformances: Navigatable, Sendable)
public macro Route(customPaths: [String: String] = [:]) = #externalMacro(module: "NavigatorMacros", type: "RouteMacro")
