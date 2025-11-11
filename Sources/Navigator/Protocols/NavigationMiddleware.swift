import Foundation

/// Middleware protocol for intercepting navigation events.
///
/// Implement this protocol to add cross-cutting concerns like analytics,
/// logging, or validation to navigation operations.
///
/// - Important: Middleware methods are called synchronously on the main actor.
///   Avoid blocking operations. For async work, use `Task.detached`:
///
/// ```swift
/// struct AnalyticsMiddleware: NavigationMiddleware {
///     func onNavigate(to route: AppRoute) {
///         // Synchronous: OK for quick operations
///         Logger.log("Navigating to \(route.path)")
///
///         // Async: Use Task.detached for network/heavy operations
///         Task.detached {
///             await Analytics.track("navigation", route: route.path)
///         }
///     }
/// }
/// ```
public protocol NavigationMiddleware<Route>: Sendable {
	/// The route type this middleware handles
	associatedtype Route: Navigatable

	/// Called when navigating to a new route.
	/// - Parameter route: The destination route
	@MainActor
	func onNavigate(to route: Route)

	/// Called when popping from the navigation stack.
	/// - Parameter route: The route being removed
	@MainActor
	func onPop(route: Route)

	/// Called when popping to root, after all routes have been removed.
	/// - Parameter removedRoutes: All routes that were removed (in removal order, deepest first)
	@MainActor
	func onPopToRoot(removedRoutes: [Route])
}

// MARK: - Default Implementations

extension NavigationMiddleware {
	/// Default empty implementation for onNavigate.
	@MainActor
	public func onNavigate(to route: Route) {}

	/// Default empty implementation for onPop.
	@MainActor
	public func onPop(route: Route) {}

	/// Default empty implementation for onPopToRoot.
	@MainActor
	public func onPopToRoot(removedRoutes: [Route]) {}
}
