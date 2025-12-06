import Foundation
@testable import Navigator
import Testing

/// Tests for NavigatorParseError enum.
///
/// These tests verify:
/// - All error cases are correctly defined
/// - Error descriptions are accurate and helpful
/// - Equatable conformance works correctly
/// - LocalizedError provides proper descriptions
@Suite("NavigatorParseError Tests")
@MainActor
struct NavigatorParseErrorTests {
    // MARK: - Error Case Tests

    @Test("Invalid URL error description")
    func invalidURLDescription() async throws {
        // Given
        let error = NavigatorParseError.invalidURL("https://invalid url")

        // When
        let description = error.description

        // Then
        #expect(description == "Invalid URL: https://invalid url")
    }

    @Test("Missing parameter error description")
    func missingParameterDescription() async throws {
        // Given
        let error = NavigatorParseError.missingParameter(name: "userId")

        // When
        let description = error.description

        // Then
        #expect(description == "Missing required parameter: userId")
    }

    @Test("Invalid parameter error description")
    func invalidParameterDescription() async throws {
        // Given
        let error = NavigatorParseError.invalidParameter(
            name: "page",
            value: "abc",
            expected: "Int"
        )

        // When
        let description = error.description

        // Then
        #expect(description == "Invalid parameter 'page': got 'abc', expected Int")
    }

    // MARK: - LocalizedError Tests

    @Test("Invalid URL localized description")
    func invalidURLLocalizedDescription() async throws {
        // Given
        let error = NavigatorParseError.invalidURL("test")

        // When
        let localizedDescription = error.errorDescription

        // Then
        #expect(localizedDescription != nil)
        #expect(localizedDescription == error.description)
    }

    // MARK: - Equatable Tests

    @Test("Same invalid URL errors are equal")
    func equatableSameInvalidURLErrors() async throws {
        // Given
        let error1 = NavigatorParseError.invalidURL("test")
        let error2 = NavigatorParseError.invalidURL("test")

        // Then
        #expect(error1 == error2)
    }

    @Test("Different invalid URL errors are not equal")
    func equatableDifferentInvalidURLErrors() async throws {
        // Given
        let error1 = NavigatorParseError.invalidURL("test1")
        let error2 = NavigatorParseError.invalidURL("test2")

        // Then
        #expect(error1 != error2)
    }

    @Test("Same missing parameter errors are equal")
    func equatableSameMissingParameterErrors() async throws {
        // Given
        let error1 = NavigatorParseError.missingParameter(name: "userId")
        let error2 = NavigatorParseError.missingParameter(name: "userId")

        // Then
        #expect(error1 == error2)
    }

    @Test("Different missing parameter errors are not equal")
    func equatableDifferentMissingParameterErrors() async throws {
        // Given
        let error1 = NavigatorParseError.missingParameter(name: "userId")
        let error2 = NavigatorParseError.missingParameter(name: "page")

        // Then
        #expect(error1 != error2)
    }

    @Test("Same invalid parameter errors are equal")
    func equatableSameInvalidParameterErrors() async throws {
        // Given
        let error1 = NavigatorParseError.invalidParameter(
            name: "page",
            value: "abc",
            expected: "Int"
        )
        let error2 = NavigatorParseError.invalidParameter(
            name: "page",
            value: "abc",
            expected: "Int"
        )

        // Then
        #expect(error1 == error2)
    }

    @Test("Different invalid parameter errors by name are not equal")
    func equatableDifferentInvalidParameterErrorsName() async throws {
        // Given
        let error1 = NavigatorParseError.invalidParameter(
            name: "page",
            value: "abc",
            expected: "Int"
        )
        let error2 = NavigatorParseError.invalidParameter(
            name: "limit",
            value: "abc",
            expected: "Int"
        )

        // Then
        #expect(error1 != error2)
    }

    @Test("Different invalid parameter errors by value are not equal")
    func equatableDifferentInvalidParameterErrorsValue() async throws {
        // Given
        let error1 = NavigatorParseError.invalidParameter(
            name: "page",
            value: "abc",
            expected: "Int"
        )
        let error2 = NavigatorParseError.invalidParameter(
            name: "page",
            value: "xyz",
            expected: "Int"
        )

        // Then
        #expect(error1 != error2)
    }

    @Test("Different error types are not equal")
    func equatableDifferentErrorTypes() async throws {
        // Given
        let error1 = NavigatorParseError.invalidURL("test")
        let error2 = NavigatorParseError.missingParameter(name: "test")

        // Then
        #expect(error1 != error2)
    }

    // MARK: - Sendable Conformance Test

    @Test("Sendable conformance verification")
    func sendableConformance() async throws {
        // Given
        let error = NavigatorParseError.invalidURL("test")

        // When/Then - Compile-time check
        // If this compiles, Sendable conformance is working
        await withCheckedContinuation { continuation in
            Task {
                _ = error
                continuation.resume()
            }
        }
    }
}
