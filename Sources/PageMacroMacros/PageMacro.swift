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

        let bundleID = parseStringArg(labeled: "bundle", from: node)
        let container = parseContainerArg(labeled: "scope", from: node)

        let appProperty: DeclSyntax = "let app: XCUIApplication"

        // _scope is always generated so @Element/@Scope can use it as a root.
        // Without a page scope it simply forwards to `app`.
        let scopeProperty: DeclSyntax
        if let container {
            let queryProp = containerTypeToQueryProperty(container.typeName)
            let locator: ParsedLocator? = {
                if let id = container.id    { return .id(id, index: container.index) }
                if let lbl = container.label { return .label(lbl, index: container.index) }
                if let n = container.index  { return .index(n) }
                return nil
            }()
            let query = buildQuery(root: "app", queryProp: queryProp, locator: locator)
            scopeProperty = "var _scope: XCUIElement { \(raw: query) }"
        } else {
            scopeProperty = "var _scope: XCUIElement { app }"
        }

        var decls: [DeclSyntax] = [appProperty, scopeProperty]

        if let bundleID {
            let initializer: DeclSyntax = """
                init() {
                    self.app = XCUIApplication(bundleIdentifier: "\(raw: bundleID)")
                }
                """
            decls.append(initializer)
        } else {
            let initWithApp: DeclSyntax = """
                init(app: XCUIApplication) {
                    self.app = app
                }
                """
            let initDefault: DeclSyntax = """
                init() {
                    self.app = XCUIApplication()
                }
                """
            decls.append(contentsOf: [initWithApp, initDefault])
        }

        let verifyProps = collectVerifyProps(from: declaration)
        if !verifyProps.isEmpty {
            let waitBranch = verifyProps.map { prop in
                "        XCTAssertTrue(\(prop).waitForExistence(timeout: timeout), file: file, line: line)"
            }.joined(separator: "\n")
            let immediateBranch = verifyProps.map { prop in
                "        XCTAssertTrue(\(prop).exists, file: file, line: line)"
            }.joined(separator: "\n")
            let verifyMethod: DeclSyntax = """
                /// Asserts that all core elements of this page exist.
                /// Pass `timeout` to wait up to that many seconds for each element before asserting.
                @discardableResult
                @MainActor
                func verifyDefaultScreen(timeout: TimeInterval? = nil, file: StaticString = #filePath, line: UInt = #line) -> Self {
                    if let timeout {
                \(raw: waitBranch)
                    } else {
                \(raw: immediateBranch)
                    }
                    return self
                }
                """
            decls.append(verifyMethod)
        }

        return decls
    }

    // MARK: - Helpers

    private static func parseStringArg(labeled label: String, from node: AttributeSyntax) -> String? {
        guard let args = node.arguments?.as(LabeledExprListSyntax.self) else { return nil }
        for arg in args {
            guard
                arg.label?.text == label,
                let strLit = arg.expression.as(StringLiteralExprSyntax.self),
                let seg = strLit.segments.first?.as(StringSegmentSyntax.self)
            else { continue }
            return seg.content.text
        }
        return nil
    }

    /// Collects property names of all `@Element`-annotated vars that have `verify: true`.
    private static func collectVerifyProps(from declaration: some DeclGroupSyntax) -> [String] {
        var result: [String] = []
        for member in declaration.memberBlock.members {
            guard
                let varDecl = member.decl.as(VariableDeclSyntax.self),
                let binding = varDecl.bindings.first,
                let namePattern = binding.pattern.as(IdentifierPatternSyntax.self)
            else { continue }

            for attrElement in varDecl.attributes {
                guard
                    let attr = attrElement.as(AttributeSyntax.self),
                    attr.attributeName.trimmedDescription == "Element",
                    let args = attr.arguments?.as(LabeledExprListSyntax.self)
                else { continue }

                for arg in args where arg.label?.text == "verify" {
                    if let boolLit = arg.expression.as(BooleanLiteralExprSyntax.self),
                       boolLit.literal.text == "true" {
                        result.append(namePattern.identifier.text)
                    }
                }
            }
        }
        return result
    }

    /// Parses a `ContainerType` expression for a labeled argument (e.g. `scope: .scrollView(id: "x")`).
    private static func parseContainerArg(labeled label: String, from node: AttributeSyntax) -> ParsedContainer? {
        guard let args = node.arguments?.as(LabeledExprListSyntax.self) else { return nil }
        for arg in args {
            guard arg.label?.text == label else { continue }
            return parseContainerExpr(arg.expression)
        }
        return nil
    }
}

enum PageMacroError: Error, CustomStringConvertible {
    case onlyApplicableToStruct

    var description: String {
        "@Page can only be applied to a struct"
    }
}
