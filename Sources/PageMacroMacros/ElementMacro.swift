import SwiftSyntax
import SwiftSyntaxMacros

public struct ElementMacro: AccessorMacro, PeerMacro {

    // MARK: - AccessorMacro

    public static func expansion(
        of node: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AccessorDeclSyntax] {
        let params = try parseElementArgs(from: node)
        let queryProp = elementTypeToQueryProperty(params.typeName)
        let query = buildQuery(root: "_scope", queryProp: queryProp, locator: params.locator)
        let accessor: AccessorDeclSyntax = "get { \(raw: query) }"
        return [accessor]
    }

    // MARK: - PeerMacro

    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard
            let varDecl = declaration.as(VariableDeclSyntax.self),
            let binding = varDecl.bindings.first,
            let namePattern = binding.pattern.as(IdentifierPatternSyntax.self)
        else { return [] }

        let propName = namePattern.identifier.text
        let params = try parseElementArgs(from: node)
        let actions = params.actions ?? defaultActions(for: params.typeName)

        return actions.compactMap { buildMethod(action: $0, propName: propName) }
    }

    // MARK: - Default actions per element type

    private static func defaultActions(for typeName: String) -> [String] {
        switch typeName {
        case "textField", "searchField":
            return ["tap", "typeText", "clearText", "assertExists", "assertValue", "assertPlaceholder"]
        case "secureTextField":
            return ["tap", "typeText", "clearText", "assertExists", "assertPlaceholder"]
        case "button":
            return ["tap", "assertExists", "assertEnabled", "assertDisabled"]
        case "staticText":
            return ["assertExists", "assertLabel"]
        case "cell":
            return ["tap", "assertExists"]
        case "toggle":
            return ["tap", "assertExists", "assertOn", "assertOff"]
        case "scrollView", "table", "collectionView":
            return ["swipeUp", "swipeDown", "assertExists"]
        default:
            return ["tap", "assertExists"]
        }
    }
}

// Keep the old error type as a typealias so any remaining references compile.
typealias ElementMacroError = MacroError
