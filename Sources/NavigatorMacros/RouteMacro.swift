import Foundation
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Macro implementation for @Route.
///
/// This macro generates:
/// 1. static func parse(from:) implementation (via MemberMacro)
/// 2. func url(scheme:) implementation (via MemberMacro)
/// 3. var path: String property (via MemberMacro)
/// 4. Navigatable protocol conformance (via ExtensionMacro)
///
/// Key features:
/// - Automatic enum case analysis (no attributes on cases required)
/// - Optional customPaths parameter for external API integration
/// - Compile-time validation with warnings for typos
/// - Uses URLParser.param() from v4.2.1 for concise code generation
public struct RouteMacro: MemberMacro, ExtensionMacro {

	// MARK: - MemberMacro

	public static func expansion(
		of node: AttributeSyntax,
		providingMembersOf declaration: some DeclGroupSyntax,
		conformingTo protocols: [TypeSyntax],
		in context: some MacroExpansionContext
	) throws -> [DeclSyntax] {
		// Ensure this is applied to an enum
		guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
			throw RouteMacroError.notAnEnum
		}

		// Extract customPaths parameter from macro attribute
		let customPaths = extractCustomPaths(from: node)

		// Analyze enum cases
		let routeInfo = try analyzeEnumCases(enumDecl, customPaths: customPaths)

		// Validate customPaths keys against actual case names
		let caseNames = routeInfo.map { $0.caseName }
		validateCustomPaths(
			customPaths: customPaths,
			caseNames: caseNames,
			node: node,
			context: context
		)

		// Detect if enum is public
		let isPublic = enumDecl.modifiers.contains { modifier in
			modifier.name.tokenKind == .keyword(.public)
		}

		// Generate only the methods required by Navigatable protocol
		let pathProperty = try generatePathProperty(routeInfo: routeInfo, isPublic: isPublic)
		let urlFunction = try generateURLFunction(routeInfo: routeInfo, isPublic: isPublic)
		let parseFromURLFunction = try generateParseFromURLFunction(routeInfo: routeInfo, isPublic: isPublic)

		// Generate nonisolated Hashable/Equatable conformance to avoid
		// MainActor-isolated synthesized conformance issues with Swift 5/6 interop
		let hashFunction = try generateHashFunction(routeInfo: routeInfo, isPublic: isPublic)
		let equalsFunction = try generateEqualsFunction(routeInfo: routeInfo, isPublic: isPublic)

		return [pathProperty, urlFunction, parseFromURLFunction, hashFunction, equalsFunction]
	}

	// MARK: - ExtensionMacro

	public static func expansion(
		of node: AttributeSyntax,
		attachedTo declaration: some DeclGroupSyntax,
		providingExtensionsOf type: some TypeSyntaxProtocol,
		conformingTo protocols: [TypeSyntax],
		in context: some MacroExpansionContext
	) throws -> [ExtensionDeclSyntax] {
		// Ensure this is applied to an enum
		guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
			throw RouteMacroError.notAnEnum
		}

		// Extract customPaths parameter from macro attribute
		let customPaths = extractCustomPaths(from: node)

		// Analyze enum cases
		let routeInfo = try analyzeEnumCases(enumDecl, customPaths: customPaths)

		// Validate customPaths keys against actual case names
		let caseNames = routeInfo.map { $0.caseName }
		validateCustomPaths(
			customPaths: customPaths,
			caseNames: caseNames,
			node: node,
			context: context
		)

		// Generate extension for protocol conformances
		// Use @unchecked Sendable to avoid MainActor-isolated synthesized conformance issues
		let extensionDecl: DeclSyntax =
			"""
			extension \(type): Navigatable, @unchecked Sendable {
			}
			"""

		return [extensionDecl.cast(ExtensionDeclSyntax.self)]
	}
}
