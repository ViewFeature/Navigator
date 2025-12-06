import Foundation
@testable import Navigator
import Testing

/// Integration tests for @Route macro runtime behavior.
///
/// These tests verify that the macro-generated code works correctly at runtime:
/// - URL generation produces valid URLs
/// - URL parsing returns correct routes
/// - Round-trip consistency (Route -> URL -> Route)
/// - Edge cases like empty parameters and special characters
@Suite("Macro Integration Tests")
@MainActor
struct MacroIntegrationTests {
    // MARK: - Test Route Definition

    /// Test route using @Route macro for integration testing.
    ///
    /// This enum uses the actual macro to verify runtime behavior
    /// of macro-generated code.
    @Route
    enum TestRoute {
        case home
        case profile(userId: String)
        case search(query: String, limit: Int)
        case article(id: Int, showComments: Bool)
    }

    // MARK: - Basic Round-Trip Tests

    @Test("Simple route round-trip with macro-generated code")
    func simpleRouteRoundTrip() throws {
        // Given
        let route = TestRoute.home

        // When
        let url = try route.url(scheme: "testapp")
        let parsed = TestRoute.parse(from: url)

        // Then
        #expect(parsed == route)
    }

    @Test("Route with String parameter round-trip")
    func stringParameterRoundTrip() throws {
        // Given
        let route = TestRoute.profile(userId: "user123")

        // When
        let url = try route.url(scheme: "testapp")
        let parsed = TestRoute.parse(from: url)

        // Then
        #expect(parsed == route)
    }

    @Test("Route with multiple parameters round-trip")
    func multipleParametersRoundTrip() throws {
        // Given
        let route = TestRoute.search(query: "swift programming", limit: 25)

        // When
        let url = try route.url(scheme: "testapp")
        let parsed = TestRoute.parse(from: url)

        // Then
        #expect(parsed == route)
    }

    @Test("Route with Bool parameter round-trip")
    func boolParameterRoundTrip() throws {
        // Given
        let route = TestRoute.article(id: 42, showComments: true)

        // When
        let url = try route.url(scheme: "testapp")
        let parsed = TestRoute.parse(from: url)

        // Then
        #expect(parsed == route)
    }

    // MARK: - URL Generation Tests

    @Test("Macro-generated URL has correct structure")
    func urlStructure() throws {
        // Given
        let route = TestRoute.profile(userId: "abc123")

        // When
        let url = try route.url(scheme: "myapp")

        // Then
        #expect(url.scheme == "myapp")
        #expect(url.host == "profile")

        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        let userId = components.queryItems?.first(where: { $0.name == "userId" })?.value
        #expect(userId == "abc123")
    }

    @Test("Macro-generated path property is correct")
    func pathProperty() {
        #expect(TestRoute.home.path == "/home")
        #expect(TestRoute.profile(userId: "test").path == "/profile")
        #expect(TestRoute.search(query: "test", limit: 10).path == "/search")
        #expect(TestRoute.article(id: 1, showComments: false).path == "/article")
    }

    // MARK: - URL Parsing Tests

    @Test("Parse valid URL returns correct route")
    func parseValidURL() {
        // Given
        let url = URL(string: "testapp://profile?userId=test123")!

        // When
        let route = TestRoute.parse(from: url)

        // Then
        #expect(route == .profile(userId: "test123"))
    }

    @Test("Parse URL with multiple parameters")
    func parseMultipleParameters() {
        // Given
        let url = URL(string: "testapp://search?query=hello&limit=50")!

        // When
        let route = TestRoute.parse(from: url)

        // Then
        #expect(route == .search(query: "hello", limit: 50))
    }

    @Test("Parse unknown route returns nil")
    func parseUnknownRoute() {
        // Given
        let url = URL(string: "testapp://unknown")!

        // When
        let route = TestRoute.parse(from: url)

        // Then
        #expect(route == nil)
    }

    @Test("Parse URL missing required parameter returns nil")
    func parseMissingParameter() {
        // Given - profile requires userId
        let url = URL(string: "testapp://profile")!

        // When
        let route = TestRoute.parse(from: url)

        // Then
        #expect(route == nil)
    }

    @Test("Parse URL with invalid parameter type returns nil")
    func parseInvalidParameterType() {
        // Given - limit should be Int
        let url = URL(string: "testapp://search?query=test&limit=notanumber")!

        // When
        let route = TestRoute.parse(from: url)

        // Then
        #expect(route == nil)
    }

    // MARK: - Hashable Conformance Tests

    @Test("Macro-generated Hashable works correctly")
    func hashableConformance() {
        // Given
        let route1 = TestRoute.profile(userId: "same")
        let route2 = TestRoute.profile(userId: "same")
        let route3 = TestRoute.profile(userId: "different")

        // Then
        #expect(route1.hashValue == route2.hashValue)
        #expect(route1.hashValue != route3.hashValue)

        // Set behavior
        let set: Set<TestRoute> = [route1, route2, route3]
        #expect(set.count == 2)
    }

    // MARK: - Edge Case Tests

    @Test("Route with special characters in parameter")
    func specialCharacters() throws {
        // Given
        let route = TestRoute.profile(userId: "user-with_special.chars")

        // When
        let url = try route.url(scheme: "testapp")
        let parsed = TestRoute.parse(from: url)

        // Then
        #expect(parsed == route)
    }

    @Test("Route with spaces in parameter")
    func spacesInParameter() throws {
        // Given
        let route = TestRoute.search(query: "hello world", limit: 10)

        // When
        let url = try route.url(scheme: "testapp")
        let parsed = TestRoute.parse(from: url)

        // Then
        #expect(parsed == route)
    }

    @Test("Route with unicode in parameter")
    func unicodeInParameter() throws {
        // Given
        let route = TestRoute.search(query: "検索テスト 🔍", limit: 5)

        // When
        let url = try route.url(scheme: "testapp")
        let parsed = TestRoute.parse(from: url)

        // Then
        #expect(parsed == route)
    }

    @Test("Route with empty string parameter")
    func emptyStringParameter() throws {
        // Given
        let route = TestRoute.search(query: "", limit: 0)

        // When
        let url = try route.url(scheme: "testapp")
        let parsed = TestRoute.parse(from: url)

        // Then
        #expect(parsed == route)
    }

    @Test("Route with false Bool parameter")
    func falseBoolParameter() throws {
        // Given
        let route = TestRoute.article(id: 99, showComments: false)

        // When
        let url = try route.url(scheme: "testapp")
        let parsed = TestRoute.parse(from: url)

        // Then
        #expect(parsed == route)
    }

    @Test("Route with zero Int parameter")
    func zeroIntParameter() throws {
        // Given
        let route = TestRoute.article(id: 0, showComments: true)

        // When
        let url = try route.url(scheme: "testapp")
        let parsed = TestRoute.parse(from: url)

        // Then
        #expect(parsed == route)
    }

    @Test("Route with negative Int parameter")
    func negativeIntParameter() throws {
        // Given
        let route = TestRoute.search(query: "test", limit: -1)

        // When
        let url = try route.url(scheme: "testapp")
        let parsed = TestRoute.parse(from: url)

        // Then
        #expect(parsed == route)
    }
}
