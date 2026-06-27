import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct PageMacroPlugin: CompilerPlugin {
    let providingMacros: [any Macro.Type] = [
        PageMacro.self,
        ElementMacro.self,
        ElementListMacro.self,
    ]
}
