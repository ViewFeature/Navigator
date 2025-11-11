import SwiftCompilerPlugin
import SwiftSyntaxMacros

/// Swift Compiler Plugin entry point for Navigator macros.
///
/// This plugin registers all macros provided by the Navigator library.
/// Currently provides:
/// - `@Route`: Generates Navigatable protocol conformance for enums
///
/// The plugin is automatically discovered by the Swift compiler when
/// the NavigatorMacros module is imported.
@main
struct NavigatorMacrosPlugin: CompilerPlugin {
	/// List of macros provided by this plugin.
	let providingMacros: [Macro.Type] = [
		RouteMacro.self
	]
}
