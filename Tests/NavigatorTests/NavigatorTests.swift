import Foundation
@testable import Navigator
import Testing

/// Test the Navigator functionality
@MainActor
struct NavigatorTests {
    // MARK: - Basic Navigation Tests

    @Test("Basic navigation works correctly")
    func testBasicNavigation() async throws {
        let router = Navigator<MockRoute>()

        // Test initial state
        #expect(router.path.isEmpty)
        #expect(router.path.isEmpty)
        #expect(router.path.last == nil)

        // Test navigation
        router.push(.home)
        #expect(router.path.count == 1)
        #expect(router.path.first == .home)
        #expect(!router.path.isEmpty)
        #expect(router.path.last == .home)

        router.push(.profile(userId: "123"))
        #expect(router.path.count == 2)
        #expect(router.path.last == .profile(userId: "123"))
    }

    @Test("Pop navigation works correctly")
    func testPopNavigation() async throws {
        let router = Navigator<MockRoute>()

        // Build up a path
        router.push(.home)
        router.push(.profile(userId: "123"))
        router.push(.search(query: "test", limit: 10))
        #expect(router.path.count == 3)

        // Test single pop
        router.pop()
        #expect(router.path.count == 2)
        #expect(router.path.last == .profile(userId: "123"))

        // Test pop to root
        router.popToRoot()
        #expect(router.path.isEmpty)
    }

    @Test("Multiple pop works correctly")
    func testMultiplePop() async throws {
        let router = Navigator<MockRoute>()

        // Build up a path with 5 routes
        router.push(.home)
        router.push(.profile(userId: "1"))
        router.push(.profile(userId: "2"))
        router.push(.profile(userId: "3"))
        router.push(.search(query: "test", limit: 10))
        #expect(router.path.count == 5)

        // Test popping 3 routes
        router.pop(count: 3)
        #expect(router.path.count == 2)
        #expect(router.path.last == .profile(userId: "1"))

        // Test popping more than available
        router.pop(count: 10)
        #expect(router.path.isEmpty)
    }

    @Test("Pop from empty stack does nothing")
    func testPopFromEmptyStack() async throws {
        let router = Navigator<MockRoute>()

        // Test popping from empty stack
        router.pop()
        #expect(router.path.isEmpty)

        router.pop(count: 5)
        #expect(router.path.isEmpty)
    }

    // MARK: - Pop to Route Tests

    @Test("Pop to specific route works correctly")
    func testPopToRoute() async throws {
        let router = Navigator<MockRoute>()

        // Build up a path
        router.push(.home)
        router.push(.profile(userId: "123"))
        router.push(.settings)
        router.push(.search(query: "test", limit: 10))
        #expect(router.path.count == 4)

        // Pop to profile
        router.pop(to: .profile(userId: "123"))
        #expect(router.path.count == 2)
        #expect(router.path.last == .profile(userId: "123"))

        // Pop to home
        router.pop(to: .home)
        #expect(router.path.count == 1)
        #expect(router.path.last == .home)
    }

    @Test("Pop to non-existent route does nothing")
    func testPopToNonExistentRoute() async throws {
        let router = Navigator<MockRoute>()

        router.push(.home)
        router.push(.settings)
        #expect(router.path.count == 2)

        // Try to pop to a route not in stack
        router.pop(to: .profile(userId: "123"))
        #expect(router.path.count == 2)
        #expect(router.path.last == .settings)
    }

    @Test("Pop to route already at top does nothing")
    func testPopToCurrentRoute() async throws {
        let router = Navigator<MockRoute>()

        router.push(.home)
        router.push(.settings)
        #expect(router.path.count == 2)

        // Pop to current route (already at top)
        router.pop(to: .settings)
        #expect(router.path.count == 2)
        #expect(router.path.last == .settings)
    }

    @Test("Pop to route with duplicates pops to last occurrence")
    func testPopToRouteWithDuplicates() async throws {
        let router = Navigator<MockRoute>()

        // Build path with duplicate routes
        router.push(.home)
        router.push(.profile(userId: "1"))
        router.push(.home)  // duplicate
        router.push(.settings)
        #expect(router.path.count == 4)

        // Should pop to the last (shallowest) .home
        router.pop(to: .home)
        #expect(router.path.count == 3)
        #expect(router.path == [.home, .profile(userId: "1"), .home])
    }

    // MARK: - Path State Tests

    @Test("Path state works correctly")
    func testPathState() async throws {
        let router = Navigator<MockRoute>()

        // Test empty state
        #expect(router.path.isEmpty)
        #expect(router.path.isEmpty)
        #expect(router.path.last == nil)

        // Test with navigation
        router.push(.home)
        #expect(!router.path.isEmpty)
        #expect(router.path.count == 1)
        #expect(router.path.last == .home)

        router.push(.profile(userId: "test"))
        #expect(!router.path.isEmpty)
        #expect(router.path.count == 2)
        #expect(router.path.last == .profile(userId: "test"))

        // Test after pop to root
        router.popToRoot()
        #expect(router.path.isEmpty)
        #expect(router.path.isEmpty)
        #expect(router.path.last == nil)
    }

    // MARK: - Middleware Tests

    @Test("Middleware onPop is called for each route in pop(to:)")
    func testMiddlewareOnPopTo() async throws {
        let tracker = ThreadSafeArray<MockRoute>()

        struct TrackingMiddleware: NavigationMiddleware, @unchecked Sendable {
            typealias Route = MockRoute
            let tracker: ThreadSafeArray<MockRoute>

            func onPop(route: Route) {
                tracker.append(route)
            }
        }

        let router = Navigator<MockRoute>()
        router.addMiddleware(TrackingMiddleware(tracker: tracker))

        // Build up navigation stack
        router.push(.home)
        router.push(.profile(userId: "123"))
        router.push(.settings)
        router.push(.search(query: "test", limit: 10))
        #expect(router.path.count == 4)

        // Pop to profile
        router.pop(to: .profile(userId: "123"))
        #expect(router.path.count == 2)

        // Verify middleware was called for each popped route in reverse order
        #expect(tracker.values == [.search(query: "test", limit: 10), .settings])
    }

    @Test("Middleware integration works correctly")
    func testMiddlewareIntegration() async throws {
        let navigationCount = ThreadSafeCounter()
        let popCount = ThreadSafeCounter()

        struct TestMiddleware: NavigationMiddleware, @unchecked Sendable {
            typealias Route = MockRoute

            let onNavigateHandler: @Sendable () -> Void
            let onPopHandler: @Sendable () -> Void

            func onNavigate(to route: Route) {
                onNavigateHandler()
            }

            func onPop(route: Route) {
                onPopHandler()
            }

            func onPopToRoot(removedRoutes: [Route]) {}
        }

        let middleware = TestMiddleware(
            onNavigateHandler: { navigationCount.increment() },
            onPopHandler: { popCount.increment() }
        )

        let router = Navigator<MockRoute>()
        router.addMiddleware(middleware)

        router.push(.home)
        #expect(navigationCount.value == 1)

        router.push(.profile(userId: "123"))
        #expect(navigationCount.value == 2)

        router.pop()
        #expect(popCount.value == 1)

        // Test middleware clearing
        router.clearMiddlewares()
        router.push(.search(query: "test", limit: 10))
        #expect(navigationCount.value == 2) // Should not increment
    }

    @Test("Multiple middlewares execute in order")
    func testMultipleMiddlewares() async throws {
        let order = ThreadSafeArray<String>()

        struct FirstMiddleware: NavigationMiddleware, @unchecked Sendable {
            typealias Route = MockRoute
            let order: ThreadSafeArray<String>

            func onNavigate(to route: Route) {
                order.append("first")
            }

            func onPop(route: Route) {
                order.append("first-pop")
            }
        }

        struct SecondMiddleware: NavigationMiddleware, @unchecked Sendable {
            typealias Route = MockRoute
            let order: ThreadSafeArray<String>

            func onNavigate(to route: Route) {
                order.append("second")
            }

            func onPop(route: Route) {
                order.append("second-pop")
            }
        }

        let router = Navigator<MockRoute>()
        router.addMiddleware(FirstMiddleware(order: order))
        router.addMiddleware(SecondMiddleware(order: order))

        router.push(.home)
        #expect(order.values == ["first", "second"])

        order.removeAll()
        router.pop()
        #expect(order.values == ["first-pop", "second-pop"])
    }

    @Test("Middleware can be cleared")
    func testMiddlewareClearing() async throws {
        let callCount = ThreadSafeCounter()

        struct CountingMiddleware: NavigationMiddleware, @unchecked Sendable {
            typealias Route = MockRoute
            let counter: ThreadSafeCounter

            func onNavigate(to route: Route) {
                counter.increment()
            }

            func onPop(route: Route) {
                counter.increment()
            }
        }

        let router = Navigator<MockRoute>()
        router.addMiddleware(CountingMiddleware(counter: callCount))

        router.push(.home)
        #expect(callCount.value == 1)

        router.clearMiddlewares()
        router.push(.settings)
        #expect(callCount.value == 1) // Should not increment after clearing
    }

    @Test("Middleware onPopToRoot is called correctly")
    func testMiddlewareOnPopToRoot() async throws {
        let tracker = ThreadSafeArray<MockRoute>()

        struct PopToRootMiddleware: NavigationMiddleware, @unchecked Sendable {
            typealias Route = MockRoute
            let tracker: ThreadSafeArray<MockRoute>

            func onPopToRoot(removedRoutes: [Route]) {
                for route in removedRoutes {
                    tracker.append(route)
                }
            }
        }

        let router = Navigator<MockRoute>()
        router.addMiddleware(PopToRootMiddleware(tracker: tracker))

        // Build up navigation stack
        router.push(.home)
        router.push(.profile(userId: "123"))
        router.push(.settings)
        #expect(router.path.count == 3)

        // Pop to root
        router.popToRoot()
        #expect(router.path.isEmpty)

        // Verify middleware received removed routes in reverse order
        #expect(tracker.values == [.settings, .profile(userId: "123"), .home])
    }

    @Test("Middleware onPop is called for each route in pop(count:)")
    func testMiddlewareOnPopCount() async throws {
        let tracker = ThreadSafeArray<MockRoute>()

        struct TrackingMiddleware: NavigationMiddleware, @unchecked Sendable {
            typealias Route = MockRoute
            let tracker: ThreadSafeArray<MockRoute>

            func onPop(route: Route) {
                tracker.append(route)
            }
        }

        let router = Navigator<MockRoute>()
        router.addMiddleware(TrackingMiddleware(tracker: tracker))

        // Build up navigation stack
        router.push(.home)
        router.push(.profile(userId: "1"))
        router.push(.profile(userId: "2"))
        router.push(.settings)
        #expect(router.path.count == 4)

        // Pop 2 routes
        router.pop(count: 2)
        #expect(router.path.count == 2)

        // Verify middleware was called for each popped route in reverse order
        #expect(tracker.values == [.settings, .profile(userId: "2")])
    }

    // MARK: - Navigation with detail and list routes

    @Test("Navigation with detail route works correctly")
    func testDetailRouteNavigation() async throws {
        let router = Navigator<MockRoute>()

        router.push(.detail(id: "item-123"))
        #expect(router.path.count == 1)
        #expect(router.path.last == .detail(id: "item-123"))

        router.push(.detail(id: "item-456"))
        #expect(router.path.count == 2)

        router.pop()
        #expect(router.path.last == .detail(id: "item-123"))
    }

    @Test("Navigation with list route works correctly")
    func testListRouteNavigation() async throws {
        let router = Navigator<MockRoute>()

        router.push(.list(filter: "active"))
        #expect(router.path.count == 1)
        #expect(router.path.last == .list(filter: "active"))

        router.push(.list(filter: "archived"))
        #expect(router.path.count == 2)

        router.popToRoot()
        #expect(router.path.isEmpty)
    }

    // MARK: - Default Middleware Implementation Tests

    @Test("Middleware default implementations work correctly")
    func testMiddlewareDefaultImplementations() async throws {
        // This middleware uses all default implementations (empty methods)
        struct DefaultMiddleware: NavigationMiddleware {
            typealias Route = MockRoute
            // No custom implementations - uses protocol defaults
        }

        let router = Navigator<MockRoute>()
        router.addMiddleware(DefaultMiddleware())

        // These should work without crashing (default implementations do nothing)
        router.push(.home)
        router.push(.profile(userId: "123"))
        router.pop()
        router.popToRoot()

        #expect(router.path.isEmpty)
    }

    @Test("Middleware with partial implementation works correctly")
    func testMiddlewarePartialImplementation() async throws {
        let navigationCount = ThreadSafeCounter()

        // Only implements onNavigate, uses defaults for onPop and onPopToRoot
        struct PartialMiddleware: NavigationMiddleware, @unchecked Sendable {
            typealias Route = MockRoute
            let counter: ThreadSafeCounter

            func onNavigate(to route: Route) {
                counter.increment()
            }
            // onPop and onPopToRoot use default empty implementations
        }

        let router = Navigator<MockRoute>()
        router.addMiddleware(PartialMiddleware(counter: navigationCount))

        router.push(.home)
        #expect(navigationCount.value == 1)

        router.push(.settings)
        #expect(navigationCount.value == 2)

        // Pop uses default implementation (should not crash)
        router.pop()
        router.popToRoot()

        #expect(navigationCount.value == 2)
    }

    // MARK: - Duplicate Middleware Prevention Tests

    @Test("Duplicate middleware of same type is ignored")
    func testDuplicateMiddlewareIgnored() async throws {
        let callCount = ThreadSafeCounter()

        struct CountingMiddleware: NavigationMiddleware, @unchecked Sendable {
            typealias Route = MockRoute
            let counter: ThreadSafeCounter

            func onNavigate(to route: Route) {
                counter.increment()
            }
        }

        let router = Navigator<MockRoute>()
        router.addMiddleware(CountingMiddleware(counter: callCount))
        router.addMiddleware(CountingMiddleware(counter: callCount)) // duplicate - ignored

        router.push(.home)
        #expect(callCount.value == 1) // Only one middleware registered
        #expect(router.middlewares.count == 1)
    }

    @Test("Middleware can be removed by type")
    func testRemoveMiddlewareByType() async throws {
        let callCount = ThreadSafeCounter()

        struct CountingMiddleware: NavigationMiddleware, @unchecked Sendable {
            typealias Route = MockRoute
            let counter: ThreadSafeCounter

            func onNavigate(to route: Route) {
                counter.increment()
            }
        }

        let router = Navigator<MockRoute>()
        router.addMiddleware(CountingMiddleware(counter: callCount))

        router.push(.home)
        #expect(callCount.value == 1)

        // Remove middleware by type
        let removed = router.removeMiddleware(CountingMiddleware.self)
        #expect(removed == true)

        // Middleware should no longer be called
        router.push(.settings)
        #expect(callCount.value == 1) // Should not increment
    }

    @Test("Removing non-existent middleware type returns false")
    func testRemoveNonExistentMiddlewareType() async throws {
        let router = Navigator<MockRoute>()

        struct DummyMiddleware: NavigationMiddleware {
            typealias Route = MockRoute
        }

        struct OtherMiddleware: NavigationMiddleware {
            typealias Route = MockRoute
        }

        router.addMiddleware(DummyMiddleware())

        // Try to remove a different type
        let removed = router.removeMiddleware(OtherMiddleware.self)
        #expect(removed == false)
        #expect(router.middlewares.count == 1)
    }

    // MARK: - Boundary Value Tests

    @Test("Pop with count 0 does nothing")
    func testPopCountZero() {
        let router = Navigator<MockRoute>()

        router.push(.home)
        router.push(.settings)
        #expect(router.path.count == 2)

        // Pop with count 0 should do nothing
        router.pop(count: 0)
        #expect(router.path.count == 2)
        #expect(router.path == [.home, .settings])
    }

    @Test("Pop with negative count does nothing")
    func testPopNegativeCount() {
        let router = Navigator<MockRoute>()

        router.push(.home)
        router.push(.profile(userId: "123"))
        router.push(.settings)
        #expect(router.path.count == 3)

        // Pop with negative count should do nothing
        router.pop(count: -1)
        #expect(router.path.count == 3)

        router.pop(count: -100)
        #expect(router.path.count == 3)
        #expect(router.path == [.home, .profile(userId: "123"), .settings])
    }

    @Test("Pop with count 0 does not trigger middleware")
    func testPopCountZeroNoMiddleware() {
        let popCount = ThreadSafeCounter()

        struct CountingMiddleware: NavigationMiddleware, @unchecked Sendable {
            typealias Route = MockRoute
            let counter: ThreadSafeCounter

            func onPop(route: Route) {
                counter.increment()
            }
        }

        let router = Navigator<MockRoute>()
        router.addMiddleware(CountingMiddleware(counter: popCount))

        router.push(.home)
        router.push(.settings)

        // Pop with count 0 should not trigger middleware
        router.pop(count: 0)
        #expect(popCount.value == 0)

        // Pop with negative count should not trigger middleware
        router.pop(count: -5)
        #expect(popCount.value == 0)
    }
}
