import Testing
import Foundation
@testable import Navigator

/// Test the TabNavigator functionality including TabNavigationMiddleware
@MainActor
struct TabNavigatorTests {

    // MARK: - Basic Tab Switching Tests

    @Test("Basic tab switching works correctly")
    func testBasicTabSwitching() async throws {
        let router = TabNavigator<MockTab>(defaultTab: .home)

        // Test initial state
        #expect(router.selectedTab == .home)
        #expect(router.isSelected(.home))
        #expect(!router.isSelected(.profile))
        #expect(!router.isSelected(.search))

        // Test tab switching
        router.switchTo(.profile)
        #expect(router.selectedTab == .profile)
        #expect(router.isSelected(.profile))
        #expect(!router.isSelected(.home))
        #expect(!router.isSelected(.search))

        router.switchTo(.search)
        #expect(router.selectedTab == .search)
        #expect(router.isSelected(.search))
        #expect(!router.isSelected(.home))
        #expect(!router.isSelected(.profile))
    }

    @Test("Switching to same tab does nothing")
    func testSwitchToSameTab() async throws {
        let router = TabNavigator<MockTab>(defaultTab: .home)
        let callCount = ThreadSafeCounter()

        struct CountingMiddleware: TabNavigationMiddleware, @unchecked Sendable {
            typealias Tab = MockTab
            let counter: ThreadSafeCounter

            func onTabSwitch(fromTab: MockTab, toTab: MockTab) {
                counter.increment()
            }
        }

        router.addMiddleware(CountingMiddleware(counter: callCount))

        router.switchTo(.home) // Same as current
        #expect(callCount.value == 0) // No middleware call
        #expect(router.selectedTab == .home)
    }

    // MARK: - Middleware Tests

    @Test("TabNavigationMiddleware executes correctly")
    func testTabNavigationMiddleware() async throws {
        let router = TabNavigator<MockTab>(defaultTab: .home)
        let tabTracker = TabSwitchTracker()

        struct TestTabNavigationMiddleware: TabNavigationMiddleware, @unchecked Sendable {
            typealias Tab = MockTab
            let tracker: TabSwitchTracker

            func onTabSwitch(fromTab: MockTab, toTab: MockTab) {
                tracker.recordSwitch(from: fromTab, to: toTab)
            }
        }

        router.addMiddleware(TestTabNavigationMiddleware(tracker: tabTracker))

        // Test middleware execution
        #expect(tabTracker.count == 0)
        #expect(tabTracker.lastFromTab(as: MockTab.self) == nil)
        #expect(tabTracker.lastToTab(as: MockTab.self) == nil)

        router.switchTo(.profile)
        #expect(tabTracker.count == 1)
        #expect(tabTracker.lastFromTab(as: MockTab.self) == .home)
        #expect(tabTracker.lastToTab(as: MockTab.self) == .profile)

        router.switchTo(.search)
        #expect(tabTracker.count == 2)
        #expect(tabTracker.lastFromTab(as: MockTab.self) == .profile)
        #expect(tabTracker.lastToTab(as: MockTab.self) == .search)

        // Switching to same tab is skipped (no middleware call)
        router.switchTo(.search)
        #expect(tabTracker.count == 2) // No change
        #expect(tabTracker.lastFromTab(as: MockTab.self) == .profile) // Still the previous values
        #expect(tabTracker.lastToTab(as: MockTab.self) == .search)
    }

    @Test("Multiple middlewares execute in order")
    func testMultipleMiddlewares() async throws {
        let order = ThreadSafeArray<String>()

        struct FirstMiddleware: TabNavigationMiddleware, @unchecked Sendable {
            typealias Tab = MockTab
            let order: ThreadSafeArray<String>

            func onTabSwitch(fromTab: MockTab, toTab: MockTab) {
                order.append("first")
            }
        }

        struct SecondMiddleware: TabNavigationMiddleware, @unchecked Sendable {
            typealias Tab = MockTab
            let order: ThreadSafeArray<String>

            func onTabSwitch(fromTab: MockTab, toTab: MockTab) {
                order.append("second")
            }
        }

        let router = TabNavigator<MockTab>(defaultTab: .home)
        router.addMiddleware(FirstMiddleware(order: order))
        router.addMiddleware(SecondMiddleware(order: order))

        router.switchTo(.profile)
        #expect(order.values == ["first", "second"])
    }

    @Test("Middleware can be cleared")
    func testMiddlewareClearing() async throws {
        let callCount = ThreadSafeCounter()

        struct CountingMiddleware: TabNavigationMiddleware, @unchecked Sendable {
            typealias Tab = MockTab
            let counter: ThreadSafeCounter

            func onTabSwitch(fromTab: MockTab, toTab: MockTab) {
                counter.increment()
            }
        }

        let router = TabNavigator<MockTab>(defaultTab: .home)
        router.addMiddleware(CountingMiddleware(counter: callCount))

        router.switchTo(.profile)
        #expect(callCount.value == 1)

        // Clear middlewares
        router.clearMiddlewares()

        router.switchTo(.search)
        #expect(callCount.value == 1) // Should remain 1, not increase
    }

    // MARK: - All Tabs Tests

    @Test("Can switch to all tabs", arguments: MockTab.allCases)
    func testSwitchToAllTabs(tab: MockTab) async throws {
        let router = TabNavigator<MockTab>(defaultTab: .home)

        router.switchTo(tab)
        #expect(router.selectedTab == tab)
        #expect(router.isSelected(tab))
    }

    // MARK: - Default Middleware Implementation Tests

    @Test("TabNavigationMiddleware default implementation works correctly")
    func testTabNavigationMiddlewareDefaultImplementation() async throws {
        // This middleware uses the default implementation (empty method)
        struct DefaultTabMiddleware: TabNavigationMiddleware {
            typealias Tab = MockTab
            // No custom implementation - uses protocol default
        }

        let router = TabNavigator<MockTab>(defaultTab: .home)
        router.addMiddleware(DefaultTabMiddleware())

        // These should work without crashing (default implementation does nothing)
        router.switchTo(.profile)
        router.switchTo(.search)
        router.switchTo(.home)

        #expect(router.selectedTab == .home)
    }

    // MARK: - Duplicate Middleware Prevention Tests

    @Test("Duplicate tab middleware of same type is ignored")
    func testDuplicateTabMiddlewareIgnored() async throws {
        let callCount = ThreadSafeCounter()

        struct CountingMiddleware: TabNavigationMiddleware, @unchecked Sendable {
            typealias Tab = MockTab
            let counter: ThreadSafeCounter

            func onTabSwitch(fromTab: MockTab, toTab: MockTab) {
                counter.increment()
            }
        }

        let router = TabNavigator<MockTab>(defaultTab: .home)
        router.addMiddleware(CountingMiddleware(counter: callCount))
        router.addMiddleware(CountingMiddleware(counter: callCount)) // duplicate - ignored

        router.switchTo(.profile)
        #expect(callCount.value == 1) // Only one middleware registered
        #expect(router.middlewares.count == 1)
    }

    @Test("Tab middleware can be removed by type")
    func testRemoveTabMiddlewareByType() async throws {
        let callCount = ThreadSafeCounter()

        struct CountingMiddleware: TabNavigationMiddleware, @unchecked Sendable {
            typealias Tab = MockTab
            let counter: ThreadSafeCounter

            func onTabSwitch(fromTab: MockTab, toTab: MockTab) {
                counter.increment()
            }
        }

        let router = TabNavigator<MockTab>(defaultTab: .home)
        router.addMiddleware(CountingMiddleware(counter: callCount))

        router.switchTo(.profile)
        #expect(callCount.value == 1)

        // Remove middleware by type
        let removed = router.removeMiddleware(CountingMiddleware.self)
        #expect(removed == true)

        // Middleware should no longer be called
        router.switchTo(.search)
        #expect(callCount.value == 1) // Should not increment
    }

    @Test("Removing non-existent tab middleware type returns false")
    func testRemoveNonExistentTabMiddlewareType() async throws {
        let router = TabNavigator<MockTab>(defaultTab: .home)

        struct DummyMiddleware: TabNavigationMiddleware {
            typealias Tab = MockTab
        }

        struct OtherMiddleware: TabNavigationMiddleware {
            typealias Tab = MockTab
        }

        router.addMiddleware(DummyMiddleware())

        // Try to remove a different type
        let removed = router.removeMiddleware(OtherMiddleware.self)
        #expect(removed == false)
        #expect(router.middlewares.count == 1)
    }
}
