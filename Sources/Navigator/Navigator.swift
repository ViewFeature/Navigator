import Foundation
import Observation
import SwiftUI

// MARK: - Navigation Router

/// Simple navigation router for single-stack navigation.
///
/// Navigator is the foundation class for navigation in Compass.
/// It provides a clean, focused API for managing a single navigation stack with
/// full SwiftUI integration and middleware support.
///
/// **Design Philosophy:**
/// - Single responsibility: Navigation management only
/// - Type safety: Generic Route type ensures compile-time safety
/// - SwiftUI native: Direct binding with NavigationStack
/// - Extensible: Middleware system for analytics, logging, etc.
///
/// **Use Cases:**
/// - Single navigation stack without tabs
/// - Simple push/pop navigation
/// - Modal content navigation
/// - Lightweight routing scenarios
///
/// **Example:**
/// ```swift
/// @State private var router = Navigator<AppRoute>()
///
/// NavigationStack(path: $router.path) {
///     HomeView()
///         .navigationDestination(for: AppRoute.self) { route in
///             routeView(for: route)
///         }
/// }
/// .environment(router)
/// ```
@MainActor
@Observable
public final class Navigator<Route: Navigatable> {
	// MARK: - Navigation State

	/// Current navigation path stack.
	///
	/// This property is directly bound to SwiftUI's NavigationStack.
	/// Observable changes automatically trigger SwiftUI view updates.
	/// Each element represents a pushed view in the navigation hierarchy.
	public var path: [Route] = []

	// MARK: - Middleware System

	/// Active middlewares executed in registration order.
	///
	/// Middlewares are called synchronously for each navigation operation.
	/// They enable cross-cutting concerns like analytics, logging, validation, etc.
	/// Each middleware type can only be registered once; duplicates are ignored.
	///
	/// **Thread Safety:** Middleware methods must be thread-safe if called
	/// from non-main actors, though Navigator itself is @MainActor.
	public private(set) var middlewares: [any NavigationMiddleware<Route>] = []

	// MARK: - Initialization

	/// Create a navigation router with empty initial state.
	///
	/// The router starts with an empty navigation path, ready to accept
	/// navigation commands and middleware registrations.
	public init() {}

	// MARK: - Core Navigation Methods

	/// Push a route onto the navigation stack.
	///
	/// Calls `onNavigate` on all middlewares after updating the path.
	///
	/// - Parameter route: The route to push onto the stack
	public func push(_ route: Route) {
		path.append(route)
		for middleware in middlewares {
			middleware.onNavigate(to: route)
		}
	}

	/// Pop the current route from the navigation stack.
	///
	/// Calls `onPop` on all middlewares with the removed route.
	/// Does nothing if the navigation stack is empty.
	public func pop() {
		guard !path.isEmpty else { return }
		let route = path.removeLast()
		for middleware in middlewares {
			middleware.onPop(route: route)
		}
	}

	/// Pop to root by clearing the entire navigation stack.
	///
	/// Calls `onPopToRoot` once with all removed routes after clearing the stack.
	public func popToRoot() {
		guard !path.isEmpty else { return }
		let removedRoutes = Array(path.reversed())
		path.removeAll()
		for middleware in middlewares {
			middleware.onPopToRoot(removedRoutes: removedRoutes)
		}
	}

	/// Pop multiple routes from the navigation stack.
	///
	/// Calls `onPop` for each removed route in reverse order.
	/// Handles boundary conditions (pops all routes if count exceeds stack depth).
	///
	/// - Parameter count: Number of routes to pop (must be positive)
	public func pop(count: Int) {
		guard !isEmpty else { return }

		let actualCount = min(count, path.count)
		guard actualCount > 0 else { return }

		let removedRoutes = path.suffix(actualCount).reversed()
		path.removeLast(actualCount)
		for route in removedRoutes {
			for middleware in middlewares {
				middleware.onPop(route: route)
			}
		}
	}

	/// Pop to a specific route in the navigation stack.
	///
	/// Removes all routes above the specified route, keeping the target route.
	/// If the route appears multiple times, pops to the last (shallowest) occurrence.
	/// Does nothing if the route is not found in the stack.
	///
	/// - Parameter route: The route to pop to
	public func pop(to route: Route) {
		guard let index = path.lastIndex(of: route) else { return }

		let removeCount = path.count - index - 1
		guard removeCount > 0 else { return }

		let removedRoutes = path.suffix(removeCount).reversed()
		path.removeLast(removeCount)
		for removedRoute in removedRoutes {
			for middleware in middlewares {
				middleware.onPop(route: removedRoute)
			}
		}
	}

	// MARK: - Middleware Management

	/// Add middleware to this navigation router.
	///
	/// Middleware will be executed for all future navigation operations
	/// in the order they were added. Each middleware type can only be
	/// registered once; duplicate types are silently ignored.
	///
	/// - Parameter middleware: Middleware to add to the execution chain
	public func addMiddleware(_ middleware: any NavigationMiddleware<Route>) {
		let newType = type(of: middleware)
		let alreadyExists = middlewares.contains { type(of: $0) == newType }
		guard !alreadyExists else { return }
		middlewares.append(middleware)
	}

	/// Remove middleware of the specified type from this router.
	///
	/// - Parameter middlewareType: The type of middleware to remove
	/// - Returns: true if the middleware was found and removed, false otherwise
	@discardableResult
	public func removeMiddleware<M: NavigationMiddleware>(_ middlewareType: M.Type) -> Bool where M.Route == Route {
		guard let index = middlewares.firstIndex(where: { type(of: $0) == middlewareType }) else {
			return false
		}
		middlewares.remove(at: index)
		return true
	}

	/// Remove all middlewares from this router.
	///
	/// Clears the middleware execution chain. Useful for testing
	/// or resetting router state.
	public func clearMiddlewares() {
		middlewares.removeAll()
	}
}
