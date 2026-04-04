import XCTest
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
@testable import XCUIPageMacros

private let testMacros: [String: any Macro.Type] = [
    "Page": PageMacro.self,
    "Element": ElementMacro.self,
]

final class MacroExpansionTests: XCTestCase {

    // MARK: - @Page

    func testPageAddsAppAndInit() {
        assertMacroExpansion(
            """
            @Page
            struct LoginPage {
            }
            """,
            expandedSource: """
            struct LoginPage {

                let app: XCUIApplication

                init(app: XCUIApplication) {
                    self.app = app
                }
            }
            """,
            macros: testMacros
        )
    }

    func testPageOnClassDiagnostic() {
        assertMacroExpansion(
            """
            @Page
            class LoginVC {
            }
            """,
            expandedSource: """
            class LoginVC {
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "@Page can only be applied to a struct", line: 1, column: 1)
            ],
            macros: testMacros
        )
    }

    // MARK: - @Element

    func testElementTextField() {
        assertMacroExpansion(
            """
            @Element(.textField, id: "email")
            var email: XCUIElement
            """,
            expandedSource: """
            var email: XCUIElement {
                get {
                    app.textFields["email"]
                }
            }
            """,
            macros: testMacros
        )
    }

    func testElementSecureTextField() {
        assertMacroExpansion(
            """
            @Element(.secureTextField, id: "password")
            var password: XCUIElement
            """,
            expandedSource: """
            var password: XCUIElement {
                get {
                    app.secureTextFields["password"]
                }
            }
            """,
            macros: testMacros
        )
    }

    func testElementButton() {
        assertMacroExpansion(
            """
            @Element(.button, id: "login")
            var loginButton: XCUIElement
            """,
            expandedSource: """
            var loginButton: XCUIElement {
                get {
                    app.buttons["login"]
                }
            }
            """,
            macros: testMacros
        )
    }
}
