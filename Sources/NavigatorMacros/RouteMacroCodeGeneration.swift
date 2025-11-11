import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder

// MARK: - Helper Methods: Current Code Generation (Used in main expansion)

extension RouteMacro {
	/// Generate path property for Navigatable conformance.
	///
	/// Generated code example:
	/// ```swift
	/// var path: String {
	///     switch self {
	///     case .home: return "/home"
	///     case .profile(_): return "/profile"
	///     }
	/// }
	/// ```
	static func generatePathProperty(routeInfo: [RouteDefinition], isPublic: Bool = false) throws -> DeclSyntax {
		var caseClauses: [String] = []

		for route in routeInfo {
			if route.parameters.isEmpty {
				caseClauses.append("case .\(route.caseName): return \"\(route.path)\"")
			} else {
				let wildcards = route.parameters.map { _ in "_" }.joined(separator: ", ")
				caseClauses.append("case .\(route.caseName)(\(wildcards)): return \"\(route.path)\"")
			}
		}

		let publicModifier = isPublic ? "public " : ""
		let propertyBody: DeclSyntax =
			"""
			\(raw: publicModifier)var path: String {
				switch self {
				\(raw: caseClauses.joined(separator: "\n\t\t"))
				}
			}
			"""

		return propertyBody
	}

	/// Generate url(scheme:) function for custom URL schemes.
	///
	/// URL format: `scheme://routeName?param1=value1&param2=value2`
	///
	/// - Note: The route name is used as the URL host component.
	///   Custom paths with slashes (e.g., "/app/settings") are only applied
	///   to the `path` property, not to URL generation. URL generation always
	///   uses the case name as the host for valid URL construction.
	///
	/// Generated code example:
	/// ```swift
	/// func url(scheme: String) throws -> URL {
	///     var components = URLComponents()
	///     components.scheme = scheme
	///     switch self {
	///     case .home:
	///         components.host = "home"
	///     case .profile(let id):
	///         components.host = "profile"
	///         components.queryItems = [URLQueryItem(name: "id", value: String(id))]
	///     }
	///     guard let url = components.url else {
	///         throw NavigatorParseError.invalidURL("\(scheme)://\(components.host ?? "")")
	///     }
	///     return url
	/// }
	/// ```
	static func generateURLFunction(routeInfo: [RouteDefinition], isPublic: Bool = false) throws -> DeclSyntax {
		let publicModifier = isPublic ? "public " : ""

		// Generate switch cases for URL construction
		var caseClauses: [String] = []

		for route in routeInfo {
			// Always use case name as host for valid URL construction
			// (custom paths may contain slashes which are invalid in URL host)
			let hostName = route.caseName

			if route.parameters.isEmpty {
				caseClauses.append(
					"""
					case .\(route.caseName):
						components.host = "\(hostName)"
					""")
			} else {
				let paramNames = route.parameters.map { "let \($0.escapedName)" }.joined(separator: ", ")
				let queryItems = route.parameters.map {
					"URLQueryItem(name: \"\($0.name)\", value: String(\($0.escapedName)))"
				}.joined(separator: ", ")

				caseClauses.append(
					"""
					case .\(route.caseName)(\(paramNames)):
						components.host = "\(hostName)"
						components.queryItems = [\(queryItems)]
					""")
			}
		}

		let functionBody: DeclSyntax =
			"""
			\(raw: publicModifier)func url(scheme: String) throws -> URL {
				var components = URLComponents()
				components.scheme = scheme

				switch self {
				\(raw: caseClauses.joined(separator: "\n\t\t"))
				}

				guard let url = components.url else {
					throw NavigatorParseError.invalidURL("\\(scheme)://\\(components.host ?? "")")
				}
				return url
			}
			"""

		return functionBody
	}

	/// Generate parse(from:) function for custom URL schemes.
	///
	/// Parses URL format: `scheme://routeName?param1=value1&param2=value2`
	///
	/// Generated code example:
	/// ```swift
	/// static func parse(from url: URL) -> Self? {
	///     guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
	///         return nil
	///     }
	///     let routeName = components.host ?? ""
	///     let queryItems = components.queryItems ?? []
	///     switch routeName {
	///     case "home": return .home
	///     case "profile":
	///         guard let id: String = URLParser.optionalParam("id", from: queryItems) else { return nil }
	///         return .profile(id: id)
	///     default:
	///         return nil
	///     }
	/// }
	/// ```
	static func generateParseFromURLFunction(
		routeInfo: [RouteDefinition],
		isPublic: Bool = false
	) throws -> DeclSyntax {
		let publicModifier = isPublic ? "public " : ""
		let caseClauses = generateParseCaseClauses(routeInfo: routeInfo)

		let functionBody: DeclSyntax =
			"""
			\(raw: publicModifier)static func parse(from url: URL) -> Self? {
				guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
					return nil
				}

				// Custom scheme: myapp://route → host="route"
				let routeName = components.host ?? ""
				let queryItems = components.queryItems ?? []

				switch routeName {
				\(raw: caseClauses.joined(separator: "\n\t\t"))
				default:
					return nil
				}
			}
			"""

		return functionBody
	}

	/// Generate nonisolated hash(into:) function for Hashable conformance.
	///
	/// Required to avoid MainActor-isolated synthesized conformance issues
	/// when the library is built with Swift 6 but the client uses Swift 5.
	///
	/// Generated code example:
	/// ```swift
	/// nonisolated func hash(into hasher: inout Hasher) {
	///     switch self {
	///     case .home:
	///         hasher.combine("home")
	///     case .profile(let id):
	///         hasher.combine("profile")
	///         hasher.combine(id)
	///     }
	/// }
	/// ```
	static func generateHashFunction(routeInfo: [RouteDefinition], isPublic: Bool = false) throws -> DeclSyntax {
		let publicModifier = isPublic ? "public " : ""
		var caseClauses: [String] = []

		for route in routeInfo {
			if route.parameters.isEmpty {
				caseClauses.append(
					"""
					case .\(route.caseName):
						hasher.combine("\(route.caseName)")
					""")
			} else {
				let paramNames = route.parameters.map { "let \($0.escapedName)" }.joined(separator: ", ")
				var hashStatements = ["hasher.combine(\"\(route.caseName)\")"]
				for param in route.parameters {
					hashStatements.append("hasher.combine(\(param.escapedName))")
				}
				caseClauses.append(
					"""
					case .\(route.caseName)(\(paramNames)):
						\(hashStatements.joined(separator: "\n\t\t\t"))
					""")
			}
		}

		let functionBody: DeclSyntax =
			"""
			\(raw: publicModifier)nonisolated func hash(into hasher: inout Hasher) {
				switch self {
				\(raw: caseClauses.joined(separator: "\n\t\t"))
				}
			}
			"""

		return functionBody
	}

	/// Generate nonisolated == operator for Equatable conformance.
	///
	/// Required to avoid MainActor-isolated synthesized conformance issues
	/// when the library is built with Swift 6 but the client uses Swift 5.
	///
	/// Generated code example:
	/// ```swift
	/// nonisolated static func == (lhs: Self, rhs: Self) -> Bool {
	///     switch (lhs, rhs) {
	///     case (.home, .home): return true
	///     case (.profile(let lhsId), .profile(let rhsId)): return lhsId == rhsId
	///     default: return false
	///     }
	/// }
	/// ```
	static func generateEqualsFunction(routeInfo: [RouteDefinition], isPublic: Bool = false) throws -> DeclSyntax {
		let publicModifier = isPublic ? "public " : ""
		var caseClauses: [String] = []

		for route in routeInfo {
			if route.parameters.isEmpty {
				caseClauses.append("case (.\(route.caseName), .\(route.caseName)): return true")
			} else {
				let lhsParams = route.parameters.map { "let lhs\($0.name.capitalized)" }.joined(separator: ", ")
				let rhsParams = route.parameters.map { "let rhs\($0.name.capitalized)" }.joined(separator: ", ")
				let comparisons = route.parameters.map { "lhs\($0.name.capitalized) == rhs\($0.name.capitalized)" }
					.joined(separator: " && ")
				caseClauses.append(
					"case (.\(route.caseName)(\(lhsParams)), .\(route.caseName)(\(rhsParams))): return \(comparisons)")
			}
		}
		caseClauses.append("default: return false")

		let functionBody: DeclSyntax =
			"""
			\(raw: publicModifier)nonisolated static func == (lhs: Self, rhs: Self) -> Bool {
				switch (lhs, rhs) {
				\(raw: caseClauses.joined(separator: "\n\t\t"))
				}
			}
			"""

		return functionBody
	}

	/// Generate case clauses for parse(from:) function using URLParser.optionalParam<T>
	private static func generateParseCaseClauses(routeInfo: [RouteDefinition]) -> [String] {
		var caseClauses: [String] = []

		for route in routeInfo {
			// Use case name for URL parsing (matches url(scheme:) generation)
			let routeName = route.caseName

			if route.parameters.isEmpty {
				caseClauses.append("case \"\(routeName)\": return .\(route.caseName)")
			} else {
				var paramExtractions: [String] = []
				for param in route.parameters {
					// Use guard + URLParser.optionalParam<T> for optional extraction
					paramExtractions.append(
						"guard let \(param.escapedName): \(param.type) = URLParser.optionalParam(\"\(param.name)\", from: queryItems) else { return nil }"
					)
				}
				let paramNames = route.parameters.map { "\($0.name): \($0.escapedName)" }.joined(separator: ", ")
				caseClauses.append(
					"""
					case "\(routeName)":
						\(paramExtractions.joined(separator: "\n\t\t\t"))
						return .\(route.caseName)(\(paramNames))
					""")
			}
		}

		return caseClauses
	}
}
