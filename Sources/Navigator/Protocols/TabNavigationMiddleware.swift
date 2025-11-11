import Foundation

/// Middleware protocol for intercepting tab switching events.
///
/// Implement this protocol to add cross-cutting concerns like analytics,
/// logging, or validation to tab operations.
///
/// - Important: Middleware methods are called synchronously on the main actor.
///   Avoid blocking operations. For async work, use `Task.detached`:
///
/// ```swift
/// struct TabAnalyticsMiddleware: TabNavigationMiddleware {
///     func onTabSwitch(fromTab: AppTab, toTab: AppTab) {
///         // Synchronous: OK for quick operations
///         Logger.log("Switched from \(fromTab) to \(toTab)")
///
///         // Async: Use Task.detached for network/heavy operations
///         Task.detached {
///             await Analytics.track("tab_switch", from: fromTab, to: toTab)
///         }
///     }
/// }
/// ```
public protocol TabNavigationMiddleware<Tab>: Sendable {
	/// The tab type this middleware handles
	associatedtype Tab: Hashable

	/// Called when switching between tabs.
	/// - Parameter fromTab: The previous tab
	/// - Parameter toTab: The new tab being selected
	@MainActor
	func onTabSwitch(fromTab: Tab, toTab: Tab)
}

// MARK: - Default Implementations

extension TabNavigationMiddleware {
	/// Default empty implementation for onTabSwitch.
	@MainActor
	public func onTabSwitch(fromTab: Tab, toTab: Tab) {}
}
