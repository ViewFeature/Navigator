//
//  TestData.swift
//  CompassTests
//
//  Created by Claude on 2025/11/12.
//

import Foundation
@testable import Navigator

/// Centralized test data and utilities for Compass tests.
///
/// Provides consistent, reusable test data across all test suites:
/// - Common route configurations
/// - Standard query parameters
/// - URL test cases
/// - Error scenarios
/// - Performance test data
struct TestData {
    // MARK: - Common Routes

    /// Standard test routes covering all major scenarios
    static let standardRoutes: [MockRoute] = [
        .home,
        .profile(userId: "test123"),
        .list(filter: "swift"),
        .search(query: "test query", limit: 10)
    ]

    /// Routes with complex parameters for edge case testing
    static let complexRoutes: [MockRoute] = [
        .profile(userId: "user-with-special-chars_123"),
        .list(filter: "filter with spaces & symbols"),
        .search(query: "query with unicode: 🚀 测试", limit: 999),
        .search(query: "", limit: 0) // Edge case: empty values
    ]

    /// Routes for performance testing
    static let performanceRoutes: [MockRoute] = Array(0..<1000).map { index in
        MockRoute.profile(userId: "performance_user_\(index)")
    }

    // MARK: - Common Query Parameters

    /// Standard query items covering various data types
    static let standardQueryItems: [URLQueryItem] = [
        URLQueryItem(name: "userId", value: "123"),
        URLQueryItem(name: "page", value: "2"),
        URLQueryItem(name: "limit", value: "50"),
        URLQueryItem(name: "isActive", value: "true"),
        URLQueryItem(name: "rating", value: "4.5"),
        URLQueryItem(name: "filter", value: "swift")
    ]

    /// Edge case query items for error testing
    static let edgeCaseQueryItems: [URLQueryItem] = [
        URLQueryItem(name: "empty", value: ""),
        URLQueryItem(name: "nil", value: nil),
        URLQueryItem(name: "special-chars", value: "hello & world"),
        URLQueryItem(name: "unicode", value: "测试 🚀"),
        URLQueryItem(name: "long-value", value: String(repeating: "a", count: 1000))
    ]

    /// Invalid query items for error testing
    static let invalidQueryItems: [URLQueryItem] = [
        URLQueryItem(name: "invalidInt", value: "not-a-number"),
        URLQueryItem(name: "invalidBool", value: "maybe"),
        URLQueryItem(name: "invalidDouble", value: "3.14.159")
    ]

    // MARK: - Test URLs

    /// Valid URLs for parsing tests
    static let validURLs: [URL] = [
        URL(string: "testapp://home")!,
        URL(string: "testapp://profile?userId=123")!,
        URL(string: "testapp://list?filter=swift")!,
        URL(string: "testapp://search?query=test&limit=10")!,
        URL(string: "https://home")!,
        URL(string: "customscheme://app/profile?userId=special_user")!
    ]

    /// Invalid URLs for error testing
    static let invalidURLStrings: [String] = [
        "not a url",
        "://missing-scheme",
        "testapp://",
        "testapp://unknown-path",
        "testapp://profile", // Missing required parameter
        ""
    ]

    // MARK: - Error Scenarios

    /// Standard error scenarios for testing
    static let errorScenarios: [(description: String, error: NavigatorParseError)] = [
        ("Invalid URL", .invalidURL("not a url")),
        ("Missing parameter", .missingParameter(name: "userId")),
        ("Invalid parameter", .invalidParameter(name: "page", value: "abc", expected: "Int"))
    ]

    // MARK: - Tab Data

    /// All available mock tabs
    static let allTabs: [MockTab] = MockTab.allCases

    /// Tab with associated routes for testing
    static let tabRouteMapping: [(tab: MockTab, routes: [MockRoute])] = [
        (.home, [.home, .profile(userId: "home_user")]),
        (.search, [.search(query: "search_test", limit: 5), .list(filter: "search")]),
        (.profile, [.profile(userId: "main_user"), .profile(userId: "other_user")])
    ]

    // MARK: - Parameter Combinations

    /// Various parameter type combinations for testing
    static let parameterCombinations: [(name: String, value: String, expectedType: String)] = [
        ("stringParam", "hello", "String"),
        ("intParam", "42", "Int"),
        ("boolParam", "true", "Bool"),
        ("doubleParam", "3.14", "Double"),
        ("negativeInt", "-100", "Int"),
        ("zeroInt", "0", "Int"),
        ("emptyString", "", "String")
    ]

    // MARK: - Path Components

    /// Common path component test cases
    static let pathComponentTestCases: [(input: String, expected: [String])] = [
        ("", []),
        ("/", []),
        ("/home", ["home"]),
        ("/books/123", ["books", "123"]),
        ("/books/123/chapters/5", ["books", "123", "chapters", "5"]),
        ("//books///123//", ["books", "123"]), // Multiple slashes
        ("/user-profile/john_doe", ["user-profile", "john_doe"]) // Special chars
    ]

    // MARK: - Encoding Test Cases

    /// Parameter encoding test cases
    @MainActor
    static let encodingTestCases: [(input: Any, expected: String)] = [
        ("hello", "hello"),
        (42, "42"),
        (true, "true"),
        (false, "false"),
        (3.14, "3.14"),
        (-42, "-42"),
        (0, "0"),
        ("", ""),
        ("hello world", "hello world") // Spaces handled by URLComponents
    ]

    // MARK: - Performance Test Data

    /// Large dataset for performance testing
    static func generatePerformanceRoutes(count: Int) -> [MockRoute] {
        (0..<count).map { index in
            let routeTypes: [MockRoute] = [
                .home,
                .profile(userId: "perf_user_\(index)"),
                .list(filter: "perf_filter_\(index)"),
                .search(query: "perf_query_\(index)", limit: index % 100)
            ]
            return routeTypes[index % routeTypes.count]
        }
    }

    /// Large query parameter set for performance testing
    static func generatePerformanceQueryItems(count: Int) -> [URLQueryItem] {
        (0..<count).map { index in
            URLQueryItem(name: "param\(index)", value: "value\(index)")
        }
    }

    // MARK: - Validation Helpers

    /// Validates that a URL matches expected format
    static func validateURL(_ url: URL, scheme: String, host: String) -> Bool {
        url.scheme == scheme && url.host == host
    }

    /// Validates that query items contain expected parameters
    static func validateQueryItems(_ queryItems: [URLQueryItem], contains expected: [String: String]) -> Bool {
        let queryDict = Dictionary(uniqueKeysWithValues: queryItems.compactMap { item in
            item.value.map { (item.name, $0) }
        })

        return expected.allSatisfy { key, value in
            queryDict[key] == value
        }
    }

    // MARK: - Random Data Generation

    /// Generates random routes for testing
    static func randomRoute() -> MockRoute {
        let routes: [MockRoute] = [
            .home,
            .profile(userId: "random_\(UUID().uuidString.prefix(8))"),
            .list(filter: "random_filter_\(Int.random(in: 1...100))"),
            .search(query: "random_query", limit: Int.random(in: 1...50))
        ]
        return routes.randomElement()!
    }

    /// Generates random tab
    static func randomTab() -> MockTab {
        MockTab.allCases.randomElement()!
    }
}
