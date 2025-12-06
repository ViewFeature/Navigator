import Foundation
@testable import Navigator
import Testing

/// Tests for URLParser utilities.
///
/// These tests verify the correctness of URL parsing operations:
/// - Path component extraction
/// - Query parameter extraction (required)
/// - Query parameter extraction (with defaults)
/// - Type conversion for various types
/// - Error handling for missing/invalid parameters
@Suite("URLParser Tests")
@MainActor
struct URLParserTests {
    // MARK: - Path Parsing Tests

    @Test("Parse path components with empty path")
    func parsePathComponentsEmptyPath() async throws {
        // Given
        let path = ""

        // When
        let components = URLParser.parsePathComponents(path)

        // Then
        #expect(components.isEmpty)
    }

    @Test("Parse path components with root path")
    func parsePathComponentsRootPath() async throws {
        // Given
        let path = "/"

        // When
        let components = URLParser.parsePathComponents(path)

        // Then
        #expect(components.isEmpty)
    }

    @Test("Parse path components with single component")
    func parsePathComponentsSingleComponent() async throws {
        // Given
        let path = "/home"

        // When
        let components = URLParser.parsePathComponents(path)

        // Then
        #expect(components == ["home"])
    }

    @Test("Parse path components with multiple components")
    func parsePathComponentsMultipleComponents() async throws {
        // Given
        let path = "/books/123/chapters/5"

        // When
        let components = URLParser.parsePathComponents(path)

        // Then
        #expect(components == ["books", "123", "chapters", "5"])
    }

    @Test("Parse path components with trailing slash")
    func parsePathComponentsTrailingSlash() async throws {
        // Given
        let path = "/books/123/"

        // When
        let components = URLParser.parsePathComponents(path)

        // Then
        #expect(components == ["books", "123"])
    }

    @Test("Parse path components with multiple slashes")
    func parsePathComponentsMultipleSlashes() async throws {
        // Given
        let path = "//books///123//"

        // When
        let components = URLParser.parsePathComponents(path)

        // Then
        #expect(components == ["books", "123"])
    }

    // MARK: - Query Value Extraction Tests

    @Test("Query value extraction with existing parameter")
    func queryValueExistingParameter() async throws {
        // Given
        let queryItems = [
            URLQueryItem(name: "userId", value: "123"),
            URLQueryItem(name: "page", value: "2")
        ]

        // When
        let value: String? = URLParser.optionalParam("userId", from: queryItems)

        // Then
        #expect(value == "123")
    }

    @Test("Query value extraction with missing parameter")
    func queryValueMissingParameter() async throws {
        // Given
        let queryItems = [
            URLQueryItem(name: "userId", value: "123")
        ]

        // When
        let value: String? = URLParser.optionalParam("page", from: queryItems)

        // Then
        #expect(value == nil)
    }

    @Test("Query value extraction with empty value")
    func queryValueEmptyValue() async throws {
        // Given
        let queryItems = [
            URLQueryItem(name: "userId", value: "")
        ]

        // When
        let value: String? = URLParser.optionalParam("userId", from: queryItems)

        // Then
        #expect(value == "")
    }

    @Test("Query value extraction with nil value")
    func queryValueNilValue() async throws {
        // Given
        let queryItems = [
            URLQueryItem(name: "userId", value: nil)
        ]

        // When
        let value: String? = URLParser.optionalParam("userId", from: queryItems)

        // Then
        #expect(value == nil)
    }

    // MARK: - Required Parameter Extraction Tests

    @Test("Extract String parameter successfully")
    func extractParameterStringSuccess() async throws {
        // Given
        let queryItems = [
            URLQueryItem(name: "userId", value: "abc123")
        ]

        // When
        let value: String = try URLParser.param("userId", from: queryItems)

        // Then
        #expect(value == "abc123")
    }

    @Test("Extract Int parameter successfully")
    func extractParameterIntSuccess() async throws {
        // Given
        let queryItems = [
            URLQueryItem(name: "page", value: "42")
        ]

        // When
        let value: Int = try URLParser.param("page", from: queryItems)

        // Then
        #expect(value == 42)
    }

    @Test("Extract Bool parameter successfully")
    func extractParameterBoolSuccess() async throws {
        // Given
        let queryItems = [
            URLQueryItem(name: "isActive", value: "true")
        ]

        // When
        let value: Bool = try URLParser.param("isActive", from: queryItems)

        // Then
        #expect(value == true)
    }

    @Test("Extract Double parameter successfully")
    func extractParameterDoubleSuccess() async throws {
        // Given
        let queryItems = [
            URLQueryItem(name: "price", value: "99.99")
        ]

        // When
        let value: Double = try URLParser.param("price", from: queryItems)

        // Then
        #expect(abs(value - 99.99) < 0.001)
    }

    @Test("Extract parameter with missing parameter throws error")
    func extractParameterMissingParameter() async throws {
        // Given
        let queryItems = [
            URLQueryItem(name: "userId", value: "123")
        ]

        // When/Then
        #expect(throws: NavigatorParseError.missingParameter(name: "page")) {
            _ = try URLParser.param("page", from: queryItems) as Int
        }
    }

    @Test("Extract parameter with invalid Int conversion throws error")
    func extractParameterInvalidIntConversion() async throws {
        // Given
        let queryItems = [
            URLQueryItem(name: "page", value: "invalid")
        ]

        // When/Then
        #expect(throws: NavigatorParseError.invalidParameter(name: "page", value: "invalid", expected: "Int")) {
            _ = try URLParser.param("page", from: queryItems) as Int
        }
    }

    @Test("Extract parameter with invalid Bool conversion throws error")
    func extractParameterInvalidBoolConversion() async throws {
        // Given
        let queryItems = [
            URLQueryItem(name: "isActive", value: "yes")
        ]

        // When/Then
        #expect(throws: NavigatorParseError.invalidParameter(name: "isActive", value: "yes", expected: "Bool")) {
            _ = try URLParser.param("isActive", from: queryItems) as Bool
        }
    }

    // MARK: - Optional Parameter Extraction Tests (with defaults)

    @Test("Extract parameter with default when parameter exists")
    func extractParameterWithDefaultExistingParameter() async throws {
        // Given
        let queryItems = [
            URLQueryItem(name: "limit", value: "50")
        ]

        // When
        let value: Int = URLParser.optionalParam("limit", from: queryItems) ?? 10

        // Then
        #expect(value == 50)
    }

    @Test("Extract parameter with default when parameter missing")
    func extractParameterWithDefaultMissingParameter() async throws {
        // Given
        let queryItems: [URLQueryItem] = []

        // When
        let value: Int = URLParser.optionalParam("limit", from: queryItems) ?? 10

        // Then
        #expect(value == 10)
    }

    @Test("Extract parameter with default when conversion fails")
    func extractParameterWithDefaultInvalidConversion() async throws {
        // Given
        let queryItems = [
            URLQueryItem(name: "limit", value: "invalid")
        ]

        // When
        let value: Int = URLParser.optionalParam("limit", from: queryItems) ?? 10

        // Then
        #expect(value == 10)
    }

    @Test("Extract parameter with default when value is nil")
    func extractParameterWithDefaultNilValue() async throws {
        // Given
        let queryItems = [
            URLQueryItem(name: "limit", value: nil)
        ]

        // When
        let value: Int = URLParser.optionalParam("limit", from: queryItems) ?? 10

        // Then
        #expect(value == 10)
    }

    @Test("Extract parameter with default when value is empty")
    func extractParameterWithDefaultEmptyValue() async throws {
        // Given
        let queryItems = [
            URLQueryItem(name: "limit", value: "")
        ]

        // When
        let value: Int = URLParser.optionalParam("limit", from: queryItems) ?? 10

        // Then
        #expect(value == 10)
    }

    @Test("Extract Bool parameter with default false value")
    func extractParameterWithDefaultBoolFalse() async throws {
        // Given
        let queryItems = [
            URLQueryItem(name: "showComments", value: "false")
        ]

        // When
        let value: Bool = URLParser.optionalParam("showComments", from: queryItems) ?? true

        // Then
        #expect(value == false)
    }

    // MARK: - Parameterized Tests using TestData

    @Test("Parse path components", arguments: TestData.pathComponentTestCases)
    func parsePathComponentsParameterized(testCase: (input: String, expected: [String])) async throws {
        // When
        let components = URLParser.parsePathComponents(testCase.input)

        // Then
        #expect(components == testCase.expected)
    }

    @Test("Extract standard query items", arguments: TestData.standardQueryItems)
    func extractStandardQueryItems(queryItem: URLQueryItem) async throws {
        // Given
        let queryItems = [queryItem]

        // When
        let value: String? = URLParser.optionalParam(queryItem.name, from: queryItems)

        // Then
        #expect(value == queryItem.value)
    }

    @Test("Handle edge case query items gracefully", arguments: TestData.edgeCaseQueryItems)
    func handleEdgeCaseQueryItems(queryItem: URLQueryItem) async throws {
        // Given
        let queryItems = [queryItem]

        // When - Should not throw, returns nil or empty for edge cases
        let value: String? = URLParser.optionalParam(queryItem.name, from: queryItems)

        // Then - Value should match the query item value (including nil and empty)
        #expect(value == queryItem.value)
    }
}
