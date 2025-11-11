import Foundation
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

// MARK: - Helper Methods: Parameter Extraction

extension RouteMacro {
	/// Extract customPaths dictionary from @Route macro attribute.
	/// Returns empty dictionary if no customPaths argument or parsing fails.
	static func extractCustomPaths(from node: AttributeSyntax) -> [String: String] {
		guard let arguments = node.arguments,
			case let .argumentList(argList) = arguments
		else {
			return [:]
		}

		// Find the customPaths argument
		for arg in argList {
			// Check if this is the customPaths parameter
			if let label = arg.label, label.text == "customPaths",
				let dictExpr = arg.expression.as(DictionaryExprSyntax.self) {
				return parseDictionaryExpression(dictExpr)
			}
		}

		// If no label, first argument might be customPaths
		if let firstArg = argList.first,
			let dictExpr = firstArg.expression.as(DictionaryExprSyntax.self) {
			return parseDictionaryExpression(dictExpr)
		}

		return [:]
	}

	/// Parse DictionaryExprSyntax into [String: String]
	private static func parseDictionaryExpression(_ dictExpr: DictionaryExprSyntax) -> [String: String] {
		var result: [String: String] = [:]

		guard let elements = dictExpr.content.as(DictionaryElementListSyntax.self) else {
			return result
		}

		for element in elements {
			if let keyStr = extractStringLiteral(element.key),
				let valueStr = extractStringLiteral(element.value) {
				result[keyStr] = valueStr
			}
		}

		return result
	}

	/// Extract string literal value from expression
	private static func extractStringLiteral(_ expr: ExprSyntax) -> String? {
		guard let stringLiteral = expr.as(StringLiteralExprSyntax.self),
			let segment = stringLiteral.segments.first,
			case let .stringSegment(text) = segment
		else {
			return nil
		}

		return text.content.text
	}
}

// MARK: - Helper Methods: Case Analysis

extension RouteMacro {
	/// Analyze enum cases and extract route information
	static func analyzeEnumCases(
		_ enumDecl: EnumDeclSyntax,
		customPaths: [String: String]
	) throws -> [RouteDefinition] {
		var routes: [RouteDefinition] = []

		for member in enumDecl.memberBlock.members {
			guard let caseDecl = member.decl.as(EnumCaseDeclSyntax.self) else {
				continue
			}

			for element in caseDecl.elements {
				let caseName = element.name.text

				// Get custom path if provided, otherwise use default
				let path = customPaths[caseName] ?? "/\(caseName)"

				// Extract parameters
				let parameters = try extractParameters(from: element)

				routes.append(
					RouteDefinition(
						caseName: caseName,
						path: path,
						parameters: parameters
					))
			}
		}

		return routes
	}

	/// Extract parameters from enum case.
	///
	/// Handles both labeled and unlabeled parameters:
	/// - `case article(id: String)` → secondName is nil, firstName is "id"
	/// - `case article(articleId id: String)` → secondName is "id", firstName is "articleId"
	private static func extractParameters(from element: EnumCaseElementSyntax) throws
		-> [RouteParameter] {
		guard let parameterClause = element.parameterClause else {
			return []
		}

		var parameters: [RouteParameter] = []

		for param in parameterClause.parameters {
			// Use secondName (internal name) if available, otherwise firstName (external label)
			let paramName = param.secondName?.text ?? param.firstName?.text ?? ""
			let typeName = param.type.description.trimmingCharacters(in: .whitespaces)

			if !paramName.isEmpty {
				parameters.append(
					RouteParameter(
						name: paramName,
						type: typeName
					))
			}
		}

		return parameters
	}
}

// MARK: - Helper Methods: Validation

extension RouteMacro {
	/// Validate customPaths keys against actual case names
	static func validateCustomPaths(
		customPaths: [String: String],
		caseNames: [String],
		node: AttributeSyntax,
		context: some MacroExpansionContext
	) {
		for key in customPaths.keys where !caseNames.contains(key) {
			// Find closest match using Levenshtein distance
			let suggestion = findClosestMatch(key, in: caseNames)

			context.diagnose(
				Diagnostic(
					node: node,
					message: RouteMacroDiagnostic.unknownCaseName(
						key: key,
						availableCases: caseNames,
						suggestion: suggestion
					)
				)
			)
		}
	}

	/// Find closest match using Levenshtein distance
	private static func findClosestMatch(_ target: String, in candidates: [String]) -> String {
		guard !candidates.isEmpty else { return target }

		return candidates.min(by: { levenshtein($0, target) < levenshtein($1, target) }) ?? target
	}

	/// Calculate Levenshtein distance between two strings.
	/// Note: This runs at compile time during macro expansion.
	/// Performance: O(n*m) time, O(n*m) space complexity.
	private static func levenshtein(_ lhs: String, _ rhs: String) -> Int {
		let lhsCount = lhs.count
		let rhsCount = rhs.count

		if lhsCount == 0 { return rhsCount }
		if rhsCount == 0 { return lhsCount }

		var matrix = Array(repeating: Array(repeating: 0, count: rhsCount + 1), count: lhsCount + 1)

		for leftIndex in 0...lhsCount {
			matrix[leftIndex][0] = leftIndex
		}

		for rightIndex in 0...rhsCount {
			matrix[0][rightIndex] = rightIndex
		}

		let lhsArray = Array(lhs)
		let rhsArray = Array(rhs)

		for leftIndex in 1...lhsCount {
			for rightIndex in 1...rhsCount {
				let cost = lhsArray[leftIndex - 1] == rhsArray[rightIndex - 1] ? 0 : 1
				matrix[leftIndex][rightIndex] = min(
					matrix[leftIndex - 1][rightIndex] + 1,  // deletion
					matrix[leftIndex][rightIndex - 1] + 1,  // insertion
					matrix[leftIndex - 1][rightIndex - 1] + cost  // substitution
				)
			}
		}

		return matrix[lhsCount][rhsCount]
	}
}
