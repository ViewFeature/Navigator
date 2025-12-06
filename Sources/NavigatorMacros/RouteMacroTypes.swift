import Foundation
import SwiftDiagnostics
import SwiftSyntax

// MARK: - Supporting Types

/// Internal representation of a route case extracted from enum definition.
///
/// Used during macro expansion to store parsed enum case information
/// before generating the implementation code.
///
/// Example: For `case profile(id: String)` with customPath "/user/profile":
/// - caseName: "profile"
/// - path: "/user/profile"
/// - parameters: [RouteParameter(name: "id", type: "String")]
struct RouteDefinition {
	/// The enum case name (e.g., "home", "profile")
	let caseName: String

	/// The URL path for this route (e.g., "/home", "/user/profile")
	let path: String

	/// Associated value parameters for this case
	let parameters: [RouteParameter]
}

/// Internal representation of an associated value parameter.
///
/// Stores parameter metadata for URL query parameter generation.
///
/// Example: For `case article(articleId id: String)`:
/// - name: "id" (internal name used in code)
/// - type: "String"
struct RouteParameter {
	/// Parameter name used in generated code
	let name: String

	/// Swift type name (e.g., "String", "Int")
	let type: String

	/// Parameter name escaped with backticks if it's a Swift keyword.
	/// Use this for variable declarations in generated code.
	var escapedName: String {
		name.escapedIfKeyword
	}
}

// MARK: - Swift Keyword Escaping

extension String {
	/// Returns the string wrapped in backticks if it's a Swift keyword.
	var escapedIfKeyword: String {
		Self.swiftKeywords.contains(self) ? "`\(self)`" : self
	}

	/// Swift reserved keywords that require backticks when used as identifiers.
	private static let swiftKeywords: Set<String> = [
		// Declaration keywords
		"associatedtype", "class", "deinit", "enum", "extension", "fileprivate",
		"func", "import", "init", "inout", "internal", "let", "open", "operator",
		"private", "precedencegroup", "protocol", "public", "rethrows", "static",
		"struct", "subscript", "typealias", "var",
		// Statement keywords
		"break", "case", "catch", "continue", "default", "defer", "do", "else",
		"fallthrough", "for", "guard", "if", "in", "repeat", "return", "throw",
		"switch", "where", "while",
		// Expression/type keywords
		"Any", "as", "await", "catch", "false", "is", "nil", "self", "Self",
		"super", "throws", "true", "try",
		// Pattern keywords
		"_"
	]
}

/// Errors that can occur during @Route macro expansion.
/// These are compile-time errors that prevent code generation.
enum RouteMacroError: Error, CustomStringConvertible {
	case notAnEnum

	var description: String {
		switch self {
		case .notAnEnum:
			return "@Route can only be applied to enum types"
		}
	}
}

// MARK: - Diagnostics

/// Compile-time diagnostics for @Route macro usage.
/// These generate warnings/errors in Xcode without preventing compilation.
enum RouteMacroDiagnostic: DiagnosticMessage {
	case unknownCaseName(key: String, availableCases: [String], suggestion: String)

	var message: String {
		switch self {
		case .unknownCaseName(let key, let availableCases, let suggestion):
			return
				"Unknown case name '\(key)' in customPaths. Available cases are: "
				+ "\(availableCases.joined(separator: ", ")). Did you mean '\(suggestion)'?"
		}
	}

	var diagnosticID: MessageID {
		switch self {
		case .unknownCaseName:
			return MessageID(domain: "NavigatorMacros", id: "unknownCaseName")
		}
	}

	var severity: DiagnosticSeverity {
		switch self {
		case .unknownCaseName:
			return .warning
		}
	}
}
