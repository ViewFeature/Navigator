//
//  RouteMacroTests.swift
//  NavigatorMacrosTests
//
//  Created by Claude on 2025/11/12.
//

import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing

@testable import NavigatorMacros

/// Tests for the @Route macro functionality.
///
/// Verifies that the @Route macro correctly generates:
/// - Navigatable protocol conformance
/// - parse(from:) static method
/// - url(scheme:) instance method
/// - path property
/// - hash(into:) function for Hashable
/// - == operator for Equatable
@Suite("Route Macro Tests")
@MainActor
struct RouteMacroTests {
	// MARK: - Test Configuration

	private let testMacros: [String: Macro.Type] = [
		"Route": RouteMacro.self
	]

	// MARK: - Basic @Route Macro Tests

	@Test("Route macro with simple enum")
	func routeMacroSimpleEnum() async throws {
		assertMacroExpansion(
			"""
			@Route
			enum TestRoute {
				case home
				case profile
				case settings
			}
			""",
			expandedSource: """
			enum TestRoute {
				case home
				case profile
				case settings

				nonisolated var path: String {
					switch self {
					case .home: return "/home"
					case .profile: return "/profile"
					case .settings: return "/settings"
					}
				}

				nonisolated func url(scheme: String) throws -> URL {
					var components = URLComponents()
					components.scheme = scheme

					switch self {
					case .home:
						components.host = "home"
					case .profile:
						components.host = "profile"
					case .settings:
						components.host = "settings"
					}

					guard let url = components.url else {
						throw NavigatorParseError.invalidURL("\\(scheme)://\\(components.host ?? "")")
					}
					return url
				}

				nonisolated static func parse(from url: URL) -> Self? {
					guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
						return nil
					}

					// Custom scheme: myapp://route → host="route"
					let routeName = components.host ?? ""
					let queryItems = components.queryItems ?? []

					switch routeName {
					case "home": return .home
					case "profile": return .profile
					case "settings": return .settings
					default:
						return nil
					}
				}

				nonisolated func hash(into hasher: inout Hasher) {
					switch self {
					case .home:
						hasher.combine("home")
					case .profile:
						hasher.combine("profile")
					case .settings:
						hasher.combine("settings")
					}
				}

				nonisolated static func == (lhs: Self, rhs: Self) -> Bool {
					switch (lhs, rhs) {
					case (.home, .home): return true
					case (.profile, .profile): return true
					case (.settings, .settings): return true
					default: return false
					}
				}
			}

			extension TestRoute: Navigatable, @unchecked Sendable {
			}
			""",
			macros: testMacros
		)
	}

	@Test("Route macro with parameters")
	func routeMacroWithParameters() async throws {
		assertMacroExpansion(
			"""
			@Route
			enum TestRoute {
				case user(id: String)
				case search(query: String, limit: Int)
			}
			""",
			expandedSource: """
			enum TestRoute {
				case user(id: String)
				case search(query: String, limit: Int)

				nonisolated var path: String {
					switch self {
					case .user(_): return "/user"
					case .search(_, _): return "/search"
					}
				}

				nonisolated func url(scheme: String) throws -> URL {
					var components = URLComponents()
					components.scheme = scheme

					switch self {
					case .user(let id):
						components.host = "user"
						components.queryItems = [URLQueryItem(name: "id", value: String(id))]
					case .search(let query, let limit):
						components.host = "search"
						components.queryItems = [URLQueryItem(name: "query", value: String(query)), URLQueryItem(name: "limit", value: String(limit))]
					}

					guard let url = components.url else {
						throw NavigatorParseError.invalidURL("\\(scheme)://\\(components.host ?? "")")
					}
					return url
				}

				nonisolated static func parse(from url: URL) -> Self? {
					guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
						return nil
					}

					// Custom scheme: myapp://route → host="route"
					let routeName = components.host ?? ""
					let queryItems = components.queryItems ?? []

					switch routeName {
					case "user":
						guard let id: String = URLParser.optionalParam("id", from: queryItems) else { return nil }
						return .user(id: id)
					case "search":
						guard let query: String = URLParser.optionalParam("query", from: queryItems) else { return nil }
						guard let limit: Int = URLParser.optionalParam("limit", from: queryItems) else { return nil }
						return .search(query: query, limit: limit)
					default:
						return nil
					}
				}

				nonisolated func hash(into hasher: inout Hasher) {
					switch self {
					case .user(let id):
						hasher.combine("user")
						hasher.combine(id)
					case .search(let query, let limit):
						hasher.combine("search")
						hasher.combine(query)
						hasher.combine(limit)
					}
				}

				nonisolated static func == (lhs: Self, rhs: Self) -> Bool {
					switch (lhs, rhs) {
					case (.user(let lhsId), .user(let rhsId)): return lhsId == rhsId
					case (.search(let lhsQuery, let lhsLimit), .search(let rhsQuery, let rhsLimit)): return lhsQuery == rhsQuery && lhsLimit == rhsLimit
					default: return false
					}
				}
			}

			extension TestRoute: Navigatable, @unchecked Sendable {
			}
			""",
			macros: testMacros
		)
	}

	@Test("Route macro with custom paths")
	func routeMacroWithCustomPaths() async throws {
		assertMacroExpansion(
			"""
			@Route(customPaths: [
				"user": "/api/users",
				"home": "/dashboard"
			])
			enum TestRoute {
				case user(id: String)
				case home
			}
			""",
			expandedSource: """
			enum TestRoute {
				case user(id: String)
				case home

				nonisolated var path: String {
					switch self {
					case .user(_): return "/api/users"
					case .home: return "/dashboard"
					}
				}

				nonisolated func url(scheme: String) throws -> URL {
					var components = URLComponents()
					components.scheme = scheme

					switch self {
					case .user(let id):
						components.host = "api/users"
						components.queryItems = [URLQueryItem(name: "id", value: String(id))]
					case .home:
						components.host = "dashboard"
					}

					guard let url = components.url else {
						throw NavigatorParseError.invalidURL("\\(scheme)://\\(components.host ?? "")")
					}
					return url
				}

				nonisolated static func parse(from url: URL) -> Self? {
					guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
						return nil
					}

					// Custom scheme: myapp://route → host="route"
					let routeName = components.host ?? ""
					let queryItems = components.queryItems ?? []

					switch routeName {
					case "api/users":
						guard let id: String = URLParser.optionalParam("id", from: queryItems) else { return nil }
						return .user(id: id)
					case "dashboard": return .home
					default:
						return nil
					}
				}

				nonisolated func hash(into hasher: inout Hasher) {
					switch self {
					case .user(let id):
						hasher.combine("user")
						hasher.combine(id)
					case .home:
						hasher.combine("home")
					}
				}

				nonisolated static func == (lhs: Self, rhs: Self) -> Bool {
					switch (lhs, rhs) {
					case (.user(let lhsId), .user(let rhsId)): return lhsId == rhsId
					case (.home, .home): return true
					default: return false
					}
				}
			}

			extension TestRoute: Navigatable, @unchecked Sendable {
			}
			""",
			macros: testMacros
		)
	}

	@Test("Route macro with public enum")
	func routeMacroPublicEnum() async throws {
		assertMacroExpansion(
			"""
			@Route
			public enum TestRoute {
				case home
				case profile
			}
			""",
			expandedSource: """
			public enum TestRoute {
				case home
				case profile

				public nonisolated var path: String {
					switch self {
					case .home: return "/home"
					case .profile: return "/profile"
					}
				}

				public nonisolated func url(scheme: String) throws -> URL {
					var components = URLComponents()
					components.scheme = scheme

					switch self {
					case .home:
						components.host = "home"
					case .profile:
						components.host = "profile"
					}

					guard let url = components.url else {
						throw NavigatorParseError.invalidURL("\\(scheme)://\\(components.host ?? "")")
					}
					return url
				}

				public nonisolated static func parse(from url: URL) -> Self? {
					guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
						return nil
					}

					// Custom scheme: myapp://route → host="route"
					let routeName = components.host ?? ""
					let queryItems = components.queryItems ?? []

					switch routeName {
					case "home": return .home
					case "profile": return .profile
					default:
						return nil
					}
				}

				public nonisolated func hash(into hasher: inout Hasher) {
					switch self {
					case .home:
						hasher.combine("home")
					case .profile:
						hasher.combine("profile")
					}
				}

				public nonisolated static func == (lhs: Self, rhs: Self) -> Bool {
					switch (lhs, rhs) {
					case (.home, .home): return true
					case (.profile, .profile): return true
					default: return false
					}
				}
			}

			extension TestRoute: Navigatable, @unchecked Sendable {
			}
			""",
			macros: testMacros
		)
	}

	// MARK: - RouteMacroError Tests

	@Test("RouteMacroError notAnEnum description")
	func testRouteMacroErrorDescription() async throws {
		let error = RouteMacroError.notAnEnum
		#expect(error.description == "@Route can only be applied to enum types")
	}

	// MARK: - RouteMacroDiagnostic Tests

	@Test("RouteMacroDiagnostic unknownCaseName properties")
	func testRouteMacroDiagnosticUnknownCaseName() async throws {
		let diagnostic = RouteMacroDiagnostic.unknownCaseName(
			key: "invalidCase",
			availableCases: ["home", "profile", "settings"],
			suggestion: "home"
		)

		// Test message
		#expect(diagnostic.message.contains("Unknown case name 'invalidCase'"))
		#expect(diagnostic.message.contains("home, profile, settings"))
		#expect(diagnostic.message.contains("Did you mean 'home'?"))

		// Test diagnosticID exists (MessageID properties are private)
		_ = diagnostic.diagnosticID

		// Test severity
		#expect(diagnostic.severity == .warning)
	}

	// MARK: - RouteDefinition and RouteParameter Tests

	@Test("RouteDefinition initialization")
	func testRouteDefinitionInitialization() async throws {
		let params = [
			RouteParameter(name: "id", type: "String"),
			RouteParameter(name: "limit", type: "Int")
		]
		let definition = RouteDefinition(
			caseName: "search",
			path: "/api/search",
			parameters: params
		)

		#expect(definition.caseName == "search")
		#expect(definition.path == "/api/search")
		#expect(definition.parameters.count == 2)
		#expect(definition.parameters[0].name == "id")
		#expect(definition.parameters[0].type == "String")
		#expect(definition.parameters[1].name == "limit")
		#expect(definition.parameters[1].type == "Int")
	}

	@Test("RouteParameter initialization")
	func testRouteParameterInitialization() async throws {
		let param = RouteParameter(name: "userId", type: "String")

		#expect(param.name == "userId")
		#expect(param.type == "String")
	}

	// MARK: - RouteMacroHelpers Tests

	@Test("Route macro with empty customPaths dictionary")
	func testEmptyCustomPathsDictionary() async throws {
		assertMacroExpansion(
			"""
			@Route(customPaths: [:])
			enum TestRoute {
				case home
			}
			""",
			expandedSource: """
			enum TestRoute {
				case home

				nonisolated var path: String {
					switch self {
					case .home: return "/home"
					}
				}

				nonisolated func url(scheme: String) throws -> URL {
					var components = URLComponents()
					components.scheme = scheme

					switch self {
					case .home:
						components.host = "home"
					}

					guard let url = components.url else {
						throw NavigatorParseError.invalidURL("\\(scheme)://\\(components.host ?? "")")
					}
					return url
				}

				nonisolated static func parse(from url: URL) -> Self? {
					guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
						return nil
					}

					// Custom scheme: myapp://route → host="route"
					let routeName = components.host ?? ""
					let queryItems = components.queryItems ?? []

					switch routeName {
					case "home": return .home
					default:
						return nil
					}
				}

				nonisolated func hash(into hasher: inout Hasher) {
					switch self {
					case .home:
						hasher.combine("home")
					}
				}

				nonisolated static func == (lhs: Self, rhs: Self) -> Bool {
					switch (lhs, rhs) {
					case (.home, .home): return true
					default: return false
					}
				}
			}

			extension TestRoute: Navigatable, @unchecked Sendable {
			}
			""",
			macros: testMacros
		)
	}

	@Test("Route macro with enum without cases")
	func testEnumWithoutCases() async throws {
		assertMacroExpansion(
			"""
			@Route
			enum EmptyRoute {
			}
			""",
			expandedSource: """
			enum EmptyRoute {

				nonisolated var path: String {
					switch self {
					}
				}

				nonisolated func url(scheme: String) throws -> URL {
					var components = URLComponents()
					components.scheme = scheme

					switch self {
					}

					guard let url = components.url else {
						throw NavigatorParseError.invalidURL("\\(scheme)://\\(components.host ?? "")")
					}
					return url
				}

				nonisolated static func parse(from url: URL) -> Self? {
					guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
						return nil
					}

					// Custom scheme: myapp://route → host="route"
					let routeName = components.host ?? ""
					let queryItems = components.queryItems ?? []

					switch routeName {
					default:
						return nil
					}
				}

				nonisolated func hash(into hasher: inout Hasher) {
					switch self {
					}
				}

				nonisolated static func == (lhs: Self, rhs: Self) -> Bool {
					switch (lhs, rhs) {
					default: return false
					}
				}
			}

			extension EmptyRoute: Navigatable, @unchecked Sendable {
			}
			""",
			macros: testMacros
		)
	}

	@Test("Route macro with similar case names for Levenshtein suggestion")
	func testLevenshteinSuggestion() async throws {
		// Test that the macro suggests "profile" when "profle" (typo) is provided
		assertMacroExpansion(
			"""
			@Route(customPaths: [
				"profle": "/user/profile"
			])
			enum TestRoute {
				case home
				case profile
				case settings
			}
			""",
			expandedSource: """
			enum TestRoute {
				case home
				case profile
				case settings

				nonisolated var path: String {
					switch self {
					case .home: return "/home"
					case .profile: return "/profile"
					case .settings: return "/settings"
					}
				}

				nonisolated func url(scheme: String) throws -> URL {
					var components = URLComponents()
					components.scheme = scheme

					switch self {
					case .home:
						components.host = "home"
					case .profile:
						components.host = "profile"
					case .settings:
						components.host = "settings"
					}

					guard let url = components.url else {
						throw NavigatorParseError.invalidURL("\\(scheme)://\\(components.host ?? "")")
					}
					return url
				}

				nonisolated static func parse(from url: URL) -> Self? {
					guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
						return nil
					}

					// Custom scheme: myapp://route → host="route"
					let routeName = components.host ?? ""
					let queryItems = components.queryItems ?? []

					switch routeName {
					case "home": return .home
					case "profile": return .profile
					case "settings": return .settings
					default:
						return nil
					}
				}

				nonisolated func hash(into hasher: inout Hasher) {
					switch self {
					case .home:
						hasher.combine("home")
					case .profile:
						hasher.combine("profile")
					case .settings:
						hasher.combine("settings")
					}
				}

				nonisolated static func == (lhs: Self, rhs: Self) -> Bool {
					switch (lhs, rhs) {
					case (.home, .home): return true
					case (.profile, .profile): return true
					case (.settings, .settings): return true
					default: return false
					}
				}
			}

			extension TestRoute: Navigatable, @unchecked Sendable {
			}
			""",
			diagnostics: [
				DiagnosticSpec(
					message:
						"Unknown case name 'profle' in customPaths. Available cases are: home, profile, settings. Did you mean 'profile'?",
					line: 1,
					column: 1,
					severity: .warning
				)
			],
			macros: testMacros
		)
	}

	@Test("Route macro with unlabeled parameter")
	func testUnlabeledParameter() async throws {
		assertMacroExpansion(
			"""
			@Route
			enum TestRoute {
				case detail(_ id: String)
			}
			""",
			expandedSource: """
			enum TestRoute {
				case detail(_ id: String)

				nonisolated var path: String {
					switch self {
					case .detail(_): return "/detail"
					}
				}

				nonisolated func url(scheme: String) throws -> URL {
					var components = URLComponents()
					components.scheme = scheme

					switch self {
					case .detail(let id):
						components.host = "detail"
						components.queryItems = [URLQueryItem(name: "id", value: String(id))]
					}

					guard let url = components.url else {
						throw NavigatorParseError.invalidURL("\\(scheme)://\\(components.host ?? "")")
					}
					return url
				}

				nonisolated static func parse(from url: URL) -> Self? {
					guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
						return nil
					}

					// Custom scheme: myapp://route → host="route"
					let routeName = components.host ?? ""
					let queryItems = components.queryItems ?? []

					switch routeName {
					case "detail":
						guard let id: String = URLParser.optionalParam("id", from: queryItems) else { return nil }
						return .detail(id)
					default:
						return nil
					}
				}

				nonisolated func hash(into hasher: inout Hasher) {
					switch self {
					case .detail(let id):
						hasher.combine("detail")
						hasher.combine(id)
					}
				}

				nonisolated static func == (lhs: Self, rhs: Self) -> Bool {
					switch (lhs, rhs) {
					case (.detail(let lhsId), .detail(let rhsId)): return lhsId == rhsId
					default: return false
					}
				}
			}

			extension TestRoute: Navigatable, @unchecked Sendable {
			}
			""",
			macros: testMacros
		)
	}

	// MARK: - Error Handling Tests

	@Test("Route macro with invalid custom path key")
	func routeMacroInvalidCustomPathKey() async throws {
		assertMacroExpansion(
			"""
			@Route(customPaths: [
				"nonExistentCase": "/api/invalid"
			])
			enum TestRoute {
				case home
			}
			""",
			expandedSource: """
			enum TestRoute {
				case home

				nonisolated var path: String {
					switch self {
					case .home: return "/home"
					}
				}

				nonisolated func url(scheme: String) throws -> URL {
					var components = URLComponents()
					components.scheme = scheme

					switch self {
					case .home:
						components.host = "home"
					}

					guard let url = components.url else {
						throw NavigatorParseError.invalidURL("\\(scheme)://\\(components.host ?? "")")
					}
					return url
				}

				nonisolated static func parse(from url: URL) -> Self? {
					guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
						return nil
					}

					// Custom scheme: myapp://route → host="route"
					let routeName = components.host ?? ""
					let queryItems = components.queryItems ?? []

					switch routeName {
					case "home": return .home
					default:
						return nil
					}
				}

				nonisolated func hash(into hasher: inout Hasher) {
					switch self {
					case .home:
						hasher.combine("home")
					}
				}

				nonisolated static func == (lhs: Self, rhs: Self) -> Bool {
					switch (lhs, rhs) {
					case (.home, .home): return true
					default: return false
					}
				}
			}

			extension TestRoute: Navigatable, @unchecked Sendable {
			}
			""",
			diagnostics: [
				DiagnosticSpec(
					message:
						"Unknown case name 'nonExistentCase' in customPaths. Available cases are: home. Did you mean 'home'?",
					line: 1,
					column: 1,
					severity: .warning
				)
			],
			macros: testMacros
		)
	}
}
