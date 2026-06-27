import SwiftSyntax
import SwiftSyntaxMacros

public struct ElementListMacro: AccessorMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AccessorDeclSyntax] {
        // Parse arguments
        guard let args = node.arguments?.as(LabeledExprListSyntax.self),
              !args.isEmpty else {
            throw MacroError.invalidArguments
        }

        let argArray = Array(args)
        var elementTypeName: String? = nil
        var container: ParsedContainer? = nil
        var rowTypeName: String? = nil

        var idx = 0

        // First arg: required unlabeled ElementType (e.g. .button, .cell)
        if idx < argArray.count && argArray[idx].label == nil {
            if let member = argArray[idx].expression.as(MemberAccessExprSyntax.self) {
                elementTypeName = member.declName.baseName.text
                idx += 1
            }
        }

        guard let elemType = elementTypeName else {
            throw MacroError.invalidElementType
        }

        // Second arg: optional unlabeled ContainerType
        if idx < argArray.count && argArray[idx].label == nil {
            container = parseContainerExpr(argArray[idx].expression)
            if container != nil { idx += 1 }
        }

        // Look for row: argument
        for arg in argArray[idx...] {
            if arg.label?.text == "row",
               let memberAccess = arg.expression.as(MemberAccessExprSyntax.self),
               memberAccess.declName.baseName.text == "self",
               let base = memberAccess.base {
                // Extract the type name from "PropertyCell.self"
                if let declRef = base.as(DeclReferenceExprSyntax.self) {
                    rowTypeName = declRef.baseName.text
                }
            }
        }

        guard let rowType = rowTypeName else {
            throw MacroError.invalidArguments
        }

        let elementQuery = elementTypeToQueryProperty(elemType)

        // Build the query string
        let query: String
        if let container = container {
            let containerQuery = containerTypeToQueryProperty(container.typeName)
            var containerAccess = "_scope.\(containerQuery)"

            if let id = container.id {
                containerAccess += ".matching(identifier: \"\(id)\").firstMatch"
            } else if let label = container.label {
                containerAccess += ".matching(NSPredicate(format: \"label == %@\", \"\(label)\")).firstMatch"
            } else if let index = container.index {
                containerAccess += ".element(boundBy: \(index))"
            } else {
                containerAccess += ".firstMatch"
            }

            query = "\(containerAccess).\(elementQuery)"
        } else {
            query = "_scope.\(elementQuery)"
        }

        let accessor: AccessorDeclSyntax = """
            get {
                ElementList<\(raw: rowType)>(app: app, query: \(raw: query))
            }
            """

        return [accessor]
    }
}
