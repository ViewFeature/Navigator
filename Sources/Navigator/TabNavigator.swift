import Foundation
import Observation
import SwiftUI

// MARK: - Tabbed Router

/// Tabbed router for managing tab selection and state.
///
/// TabNavigator focuses exclusively on tab management in Compass.
/// It provides a clean, focused API for tab selection without mixing
/// navigation responsibilities, following the single responsibility principle.
///
/// **Design Philosophy:**
/// - Single responsibility: Tab management only
/// - No navigation logic: Pure tab state management
/// - SwiftUI native: Direct binding with TabView
/// - Lightweight: Minimal overhead and complexity
///
/// **Use Cases:**
/// - Tab selection management
/// - Tab state persistence
/// - Tab-related UI state
/// - Multi-tab application coordination
///
/// **Integration Pattern:**
/// Each tab should have its own Navigator for independent navigation:
///
/// ```swift
/// // Create independent routers for each tab
/// @State private var homeRouter = Navigator<HomeRoute>()
/// @State private var profileRouter = Navigator<ProfileRoute>()
/// @State private var tabRouter = TabNavigator<AppTab>(defaultTab: .home)
///
/// TabView(selection: $tabRouter.selectedTab) {
///     NavigationStack(path: $homeRouter.path) {
///         HomeView()
///             .navigationDestination(for: HomeRoute.self) { route in
///                 homeRouteView(for: route)
///             }
///     }
///     .tabItem { Label("Home", systemImage: "house") }
///     .tag(AppTab.home)
///
///     NavigationStack(path: $profileRouter.path) {
///         ProfileView()
///             .navigationDestination(for: ProfileRoute.self) { route in
///                 profileRouteView(for: route)
///             }
///     }
///     .tabItem { Label("Profile", systemImage: "person") }
///     .tag(AppTab.profile)
/// }
/// .environment(tabRouter)
/// ```
@MainActor
@Observable
public final class TabNavigator<Tab: Hashable> {
	// MARK: - Tab State

	/// Currently selected tab.
	///
	/// This property is directly bound to SwiftUI's TabView selection.
	/// Observable changes automatically trigger SwiftUI view updates.
	/// The tab type must conform to Hashable for TabView integration.
	///
	/// Automatic middleware execution on tab changes ensures consistent tracking.
	public var selectedTab: Tab {
		didSet {
			guard oldValue != selectedTab else { return }
			for middleware in middlewares {
				middleware.onTabSwitch(fromTab: oldValue, toTab: selectedTab)
			}
		}
	}

	// MARK: - Middleware System

	/// Active middlewares executed in registration order.
	///
	/// Middlewares are called synchronously for each tab switching operation.
	/// They enable cross-cutting concerns like analytics, logging, validation, etc.
	/// Each middleware type can only be registered once; duplicates are ignored.
	///
	/// **Thread Safety:** Middleware methods must be thread-safe if called
	/// from non-main actors, though TabNavigator itself is @MainActor.
	public private(set) var middlewares: [any TabNavigationMiddleware<Tab>] = []

	// MARK: - Initialization

	/// Create a tabbed router with the specified default tab.
	///
	/// The router starts with the provided default tab selected,
	/// ready to manage tab selection state.
	///
	/// - Parameter defaultTab: The initially selected tab
	public init(defaultTab: Tab) {
		self.selectedTab = defaultTab
	}

	// MARK: - Tab Management

	/// Switch to the specified tab.
	///
	/// This method updates the selected tab, which automatically:
	/// 1. Executes all registered middlewares via didSet
	/// 2. Triggers SwiftUI view updates via @Observable
	/// 3. Prevents duplicate execution for same tab values
	///
	/// - Parameter tab: The tab to switch to
	public func switchTo(_ tab: Tab) {
		selectedTab = tab  // didSet automatically handles middleware execution
	}

	/// Check if the specified tab is currently selected.
	///
	/// - Parameter tab: The tab to check
	/// - Returns: true if the tab is currently selected, false otherwise
	public func isSelected(_ tab: Tab) -> Bool {
		selectedTab == tab
	}

	// MARK: - Middleware Management

	/// Add middleware to the execution chain.
	///
	/// Middleware will be executed for all future tab switching operations
	/// in the order they were added. Each middleware type can only be
	/// registered once; duplicate types are silently ignored.
	///
	/// - Parameter middleware: Middleware to add to the execution chain
	public func addMiddleware(_ middleware: any TabNavigationMiddleware<Tab>) {
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
	public func removeMiddleware<M: TabNavigationMiddleware>(_ middlewareType: M.Type) -> Bool where M.Tab == Tab {
		guard let index = middlewares.firstIndex(where: { type(of: $0) == middlewareType }) else {
			return false
		}
		middlewares.remove(at: index)
		return true
	}

	/// Remove all middlewares from this router.
	///
	/// After calling this method, no middleware will be executed
	/// for tab switching operations until new middleware is added.
	public func clearMiddlewares() {
		middlewares.removeAll()
	}
}
