import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

public struct ElementMacro: AccessorMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AccessorDeclSyntax] {
        guard
            let args = node.arguments?.as(LabeledExprListSyntax.self),
            args.count == 2
        else {
            throw ElementMacroError.invalidArguments
        }

        // First arg: .textField, .button, etc.
        let typeArg = args[args.startIndex]
        guard let member = typeArg.expression.as(MemberAccessExprSyntax.self) else {
            throw ElementMacroError.invalidElementType
        }
        let queryProperty = elementTypeToQueryProperty(member.declName.baseName.text)

        // Second arg: id: "someIdentifier"
        let idArg = args[args.index(after: args.startIndex)]
        guard
            idArg.label?.text == "id",
            let stringLit = idArg.expression.as(StringLiteralExprSyntax.self),
            let segment = stringLit.segments.first?.as(StringSegmentSyntax.self)
        else {
            throw ElementMacroError.invalidId
        }
        let id = segment.content.text

        let accessor: AccessorDeclSyntax = "get { app.\(raw: queryProperty)[\"\(raw: id)\"] }"
        return [accessor]
    }

    private static func elementTypeToQueryProperty(_ name: String) -> String {
        switch name {
        case "textField":         return "textFields"
        case "secureTextField":   return "secureTextFields"
        case "button":            return "buttons"
        case "staticText":        return "staticTexts"
        case "image":             return "images"
        case "cell":              return "cells"
        case "toggle":            return "switches"
        case "slider":            return "sliders"
        case "segmentedControl":  return "segmentedControls"
        case "datePicker":        return "datePickers"
        case "picker":            return "pickers"
        case "pickerWheel":       return "pickerWheels"
        case "scrollView":        return "scrollViews"
        case "table":             return "tables"
        case "collectionView":    return "collectionViews"
        case "navigationBar":     return "navigationBars"
        case "tabBar":            return "tabBars"
        case "toolbar":           return "toolbars"
        case "activityIndicator": return "activityIndicators"
        case "alert":             return "alerts"
        case "searchField":       return "searchFields"
        case "link":              return "links"
        case "webView":           return "webViews"
        default:                  return "otherElements"
        }
    }
}

enum ElementMacroError: Error, CustomStringConvertible {
    case invalidArguments
    case invalidElementType
    case invalidId

    var description: String {
        switch self {
        case .invalidArguments:  return "@Element requires two arguments: type and id:"
        case .invalidElementType: return "@Element first argument must be an ElementType member (e.g. .button)"
        case .invalidId:         return "@Element id: argument must be a string literal"
        }
    }
}
