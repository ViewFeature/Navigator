import Foundation
@testable import Navigator
import Testing

/// Integration tests for Navigatable protocol.
///
/// These tests verify the complete bidirectional routing flow:
/// - URL -> Route parsing
/// - Route -> URL generation
/// - Round-trip consistency (URL -> Route -> URL)
/// - Nil handling for invalid URLs
@Suite("Navigatable Tests")
@MainActor
struct NavigatableTests {
    // MARK: - URL -> Route Parsing Tests

    @Test("Parse simple route")
    func parseSimpleRoute() throws {
        // Given - Original URL format with host as route name
        let url = URL(string: "myapp://home")!

        // When
        let route = MockRoute.parse(from: url)

        // Then
        #expect(route == .home)
    }

    @Test("Parse route with parameter")
    func parseRouteWithParameter() throws {
        // Given
        let url = URL(string: "myapp://profile?userId=123")!

        // When
        let route = MockRoute.parse(from: url)

        // Then
        #expect(route == .profile(userId: "123"))
    }

    @Test("Parse route with multiple parameters")
    func parseRouteWithMultipleParameters() throws {
        // Given
        let url = URL(string: "myapp://search?query=swift&limit=20")!

        // When
        let route = MockRoute.parse(from: url)

        // Then
        #expect(route == .search(query: "swift", limit: 20))
    }

    @Test("Parse route with optional parameter")
    func parseRouteWithOptionalParameter() throws {
        // Given
        let url = URL(string: "myapp://article?id=42&showComments=true")!

        // When
        let route = MockRoute.parse(from: url)

        // Then
        #expect(route == .article(id: 42, showComments: true))
    }

    @Test("Parse route with default parameter")
    func parseRouteWithDefaultParameter() throws {
        // Given - limit parameter is missing, should use default value
        let url = URL(string: "myapp://search?query=swift")!

        // When
        let route = MockRoute.parse(from: url)

        // Then
        #expect(route == .search(query: "swift", limit: 10))
    }

    @Test("Parse unrecognized route returns nil")
    func parseUnrecognizedRoute() {
        // Given - A URL with an unrecognized route
        let url = URL(string: "myapp://unrecognized")!

        // When
        let route = MockRoute.parse(from: url)

        // Then
        #expect(route == nil)
    }

    @Test("Parse path not found returns nil")
    func parsePathNotFound() {
        // Given
        let url = URL(string: "myapp://unknown/path")!

        // When
        let route = MockRoute.parse(from: url)

        // Then
        #expect(route == nil)
    }

    @Test("Parse missing required parameter returns nil")
    func parseMissingRequiredParameter() {
        // Given - userId parameter is missing
        let url = URL(string: "myapp://profile")!

        // When
        let route = MockRoute.parse(from: url)

        // Then
        #expect(route == nil)
    }

    @Test("Parse invalid parameter type returns nil")
    func parseInvalidParameterType() {
        // Given - id should be Int, but is string
        let url = URL(string: "myapp://article?id=invalid")!

        // When
        let route = MockRoute.parse(from: url)

        // Then
        #expect(route == nil)
    }

    @Test("Parse scheme-only URL returns nil")
    func parseSchemeOnlyURL() {
        // Given - Only scheme, no route (e.g., deep link launch without route)
        let url = URL(string: "myapp://")!

        // When
        let route = MockRoute.parse(from: url)

        // Then
        #expect(route == nil)
    }

    // MARK: - Route -> URL Generation Tests

    @Test("URL generation for simple route")
    func urlGenerationSimpleRoute() throws {
        // Given
        let route = MockRoute.home

        // When
        let url = try route.url(scheme: "myapp")

        // Then - Host + Path integration: host as route name
        #expect(url.scheme == "myapp")
        #expect(url.host == "home")
        #expect(url.path == "")
        #expect(url.query == nil)
    }

    @Test("URL generation for route with parameter")
    func urlGenerationRouteWithParameter() throws {
        // Given
        let route = MockRoute.profile(userId: "123")

        // When
        let url = try route.url(scheme: "myapp")

        // Then - Host + Path integration: host as route name
        #expect(url.scheme == "myapp")
        #expect(url.host == "profile")
        #expect(url.path == "")
        #expect(url.query == "userId=123")
    }

    @Test("URL generation for route with multiple parameters")
    func urlGenerationRouteWithMultipleParameters() throws {
        // Given
        let route = MockRoute.search(query: "swift", limit: 20)

        // When
        let url = try route.url(scheme: "myapp")

        // Then - Host + Path integration: host as route name
        #expect(url.scheme == "myapp")
        #expect(url.host == "search")
        #expect(url.path == "")

        // Query parameters can be in any order
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        let queryItems = components.queryItems!

        #expect(queryItems.count == 2)
        #expect(queryItems.contains(URLQueryItem(name: "query", value: "swift")))
        #expect(queryItems.contains(URLQueryItem(name: "limit", value: "20")))
    }

    @Test("URL generation with custom scheme")
    func urlGenerationCustomScheme() throws {
        // Given
        let route = MockRoute.home

        // When
        let url = try route.url(scheme: "myapp")

        // Then - Host + Path integration: host as route name
        #expect(url.scheme == "myapp")
        #expect(url.host == "home")
        #expect(url.path == "")
    }

    @Test("URL generation with special characters in parameters")
    func urlGenerationSpecialCharacters() throws {
        // Given
        let route = MockRoute.search(query: "hello world", limit: 10)

        // When
        let url = try route.url(scheme: "myapp")

        // Then - Host + Path integration: host as route name
        // URLComponents automatically handles percent encoding
        #expect(url.scheme == "myapp")
        #expect(url.host == "search")
        #expect(url.path == "")

        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        let queryValue = components.queryItems?.first(where: { $0.name == "query" })?.value

        #expect(queryValue == "hello world") // Decoded value
    }

    // MARK: - Bidirectional Round-Trip Tests

    @Test("Round-trip for simple route")
    func roundTripSimpleRoute() throws {
        // Given
        let originalRoute = MockRoute.home

        // When
        let url = try originalRoute.url(scheme: "myapp")
        let parsedRoute = MockRoute.parse(from: url)

        // Then
        #expect(parsedRoute == originalRoute)
    }

    @Test("Round-trip for route with parameter")
    func roundTripRouteWithParameter() throws {
        // Given
        let originalRoute = MockRoute.profile(userId: "abc123")

        // When
        let url = try originalRoute.url(scheme: "myapp")
        let parsedRoute = MockRoute.parse(from: url)

        // Then
        #expect(parsedRoute == originalRoute)
    }

    @Test("Round-trip for route with multiple parameters")
    func roundTripRouteWithMultipleParameters() throws {
        // Given
        let originalRoute = MockRoute.search(query: "swift programming", limit: 50)

        // When
        let url = try originalRoute.url(scheme: "myapp")
        let parsedRoute = MockRoute.parse(from: url)

        // Then
        #expect(parsedRoute == originalRoute)
    }

    @Test("Round-trip for route with bool parameter")
    func roundTripRouteWithBoolParameter() throws {
        // Given
        let originalRoute = MockRoute.article(id: 42, showComments: true)

        // When
        let url = try originalRoute.url(scheme: "myapp")
        let parsedRoute = MockRoute.parse(from: url)

        // Then
        #expect(parsedRoute == originalRoute)
    }

    @Test("Round-trip for all standard routes", arguments: TestData.standardRoutes)
    func roundTripAllRoutes(route: MockRoute) throws {
        // When
        let url = try route.url(scheme: "myapp")
        let parsedRoute = MockRoute.parse(from: url)

        // Then
        #expect(parsedRoute == route, "Round-trip failed for route: \(route)")
    }

    // MARK: - URLComponents Integration Tests

    @Test("URLComponents consistency")
    func urlComponentsConsistency() throws {
        // Given
        let route = MockRoute.profile(userId: "123")

        // When
        let url = try route.url(scheme: "testapp")
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)!

        // Then
        #expect(components.host == "profile")
        #expect(components.queryItems?.count == 1)
        #expect(components.queryItems?[0].name == "userId")
        #expect(components.queryItems?[0].value == "123")
    }

    @Test("URLComponents with empty query items")
    func urlComponentsEmptyQueryItems() throws {
        // Given
        let route = MockRoute.home

        // When
        let url = try route.url(scheme: "testapp")
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)!

        // Then
        #expect(components.host == "home")
        #expect(components.queryItems?.isEmpty != false)
    }

    // MARK: - Complex Route Tests

    @Test("Parse complex route")
    func parseComplexRoute() throws {
        // Given - Complex route with path components
        let url = URL(string: "myapp://settings/detail?section=privacy")!

        // When
        let route = MockRoute.parse(from: url)

        // Then
        #expect(route == .settingsDetail(section: "privacy"))
    }

    @Test("URL generation for complex route")
    func urlGenerationComplexRoute() throws {
        // Given
        let route = MockRoute.settingsDetail(section: "privacy")

        // When
        let url = try route.url(scheme: "myapp")

        // Then - Complex route generates host + path
        #expect(url.scheme == "myapp")
        #expect(url.host == "settings")
        #expect(url.path == "/detail")
        #expect(url.query == "section=privacy")
    }

    @Test("Round-trip for complex route")
    func roundTripComplexRoute() throws {
        // Given
        let originalRoute = MockRoute.settingsDetail(section: "account")

        // When
        let url = try originalRoute.url(scheme: "myapp")
        let parsedRoute = MockRoute.parse(from: url)

        // Then
        #expect(parsedRoute == originalRoute)
    }

    // MARK: - Detail and List Route Tests

    @Test("Parse detail route")
    func parseDetailRoute() throws {
        // Given
        let url = URL(string: "myapp://detail?id=item-123")!

        // When
        let route = MockRoute.parse(from: url)

        // Then
        #expect(route == .detail(id: "item-123"))
    }

    @Test("Parse list route")
    func parseListRoute() throws {
        // Given
        let url = URL(string: "myapp://list?filter=active")!

        // When
        let route = MockRoute.parse(from: url)

        // Then
        #expect(route == .list(filter: "active"))
    }

    @Test("Round-trip for detail route")
    func roundTripDetailRoute() throws {
        // Given
        let originalRoute = MockRoute.detail(id: "special-item")

        // When
        let url = try originalRoute.url(scheme: "myapp")
        let parsedRoute = MockRoute.parse(from: url)

        // Then
        #expect(parsedRoute == originalRoute)
    }

    @Test("Round-trip for list route")
    func roundTripListRoute() throws {
        // Given
        let originalRoute = MockRoute.list(filter: "archived")

        // When
        let url = try originalRoute.url(scheme: "myapp")
        let parsedRoute = MockRoute.parse(from: url)

        // Then
        #expect(parsedRoute == originalRoute)
    }

    // MARK: - Edge Case Tests with Complex Routes

    @Test("Round-trip for complex routes with special characters", arguments: TestData.complexRoutes)
    func roundTripComplexRoutes(route: MockRoute) throws {
        // When
        let url = try route.url(scheme: "myapp")
        let parsedRoute = MockRoute.parse(from: url)

        // Then
        #expect(parsedRoute == route, "Round-trip failed for complex route: \(route)")
    }

    @Test("URL generation handles special characters in userId")
    func urlGenerationSpecialCharsInUserId() throws {
        // Given - userId with special characters
        let route = MockRoute.profile(userId: "user-with-special-chars_123")

        // When
        let url = try route.url(scheme: "myapp")

        // Then - URL should be valid and contain the encoded parameter
        #expect(url.scheme == "myapp")
        #expect(url.host == "profile")

        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        let userId = components.queryItems?.first(where: { $0.name == "userId" })?.value
        #expect(userId == "user-with-special-chars_123")
    }

    @Test("URL generation handles spaces and symbols in filter")
    func urlGenerationSpacesAndSymbols() throws {
        // Given - filter with spaces and symbols
        let route = MockRoute.list(filter: "filter with spaces & symbols")

        // When
        let url = try route.url(scheme: "myapp")
        let parsedRoute = MockRoute.parse(from: url)

        // Then - round-trip should preserve the value
        #expect(parsedRoute == route)
    }

    @Test("URL generation handles unicode in query")
    func urlGenerationUnicode() throws {
        // Given - query with unicode characters
        let route = MockRoute.search(query: "query with unicode: 🚀 测试", limit: 999)

        // When
        let url = try route.url(scheme: "myapp")
        let parsedRoute = MockRoute.parse(from: url)

        // Then - round-trip should preserve unicode
        #expect(parsedRoute == route)
    }

    @Test("URL generation handles empty query string")
    func urlGenerationEmptyQuery() throws {
        // Given - empty query string edge case
        let route = MockRoute.search(query: "", limit: 0)

        // When
        let url = try route.url(scheme: "myapp")
        let parsedRoute = MockRoute.parse(from: url)

        // Then - round-trip should preserve empty values
        #expect(parsedRoute == route)
    }
}
