import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct XCUIPagePlugin: CompilerPlugin {
    let providingMacros: [any Macro.Type] = [
        PageMacro.self,
        ElementMacro.self,
    ]
}
