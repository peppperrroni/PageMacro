import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

public struct PageMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard declaration.is(StructDeclSyntax.self) else {
            throw PageMacroError.onlyApplicableToStruct
        }

        let appProperty: DeclSyntax = "let app: XCUIApplication"
        let initializer: DeclSyntax = """
            init(app: XCUIApplication) {
                self.app = app
            }
            """
        return [appProperty, initializer]
    }
}

enum PageMacroError: Error, CustomStringConvertible {
    case onlyApplicableToStruct

    var description: String {
        "@Page can only be applied to a struct"
    }
}
