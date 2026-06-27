import XCTest
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
@testable import PageMacroMacros

private let testMacros: [String: any Macro.Type] = [
    "Page": PageMacro.self,
    "Element": ElementMacro.self,
]

final class MacroExpansionTests: XCTestCase {

    // MARK: - @Page

    func testPageAddsAppScopeAndInit() {
        assertMacroExpansion(
            """
            @Page
            struct LoginPage {
            }
            """,
            expandedSource: """
            struct LoginPage {

                let app: XCUIApplication

                var _scope: XCUIElement {
                    app
                }

                init(app: XCUIApplication) {
                    self.app = app
                }

                init() {
                    self.app = XCUIApplication()
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

    func testPageWithBundle() {
        assertMacroExpansion(
            """
            @Page(bundle: "com.apple.mobilesafari")
            struct SafariPage {
            }
            """,
            expandedSource: """
            struct SafariPage {

                let app: XCUIApplication

                var _scope: XCUIElement {
                    app
                }

                init() {
                    self.app = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
                }
            }
            """,
            macros: testMacros
        )
    }

    func testPageWithScope() {
        assertMacroExpansion(
            """
            @Page(scope: .scrollView(id: "formContainer"))
            struct RegistrationPage {
            }
            """,
            expandedSource: """
            struct RegistrationPage {

                let app: XCUIApplication

                var _scope: XCUIElement {
                    app.scrollViews.matching(identifier: "formContainer").firstMatch
                }

                init(app: XCUIApplication) {
                    self.app = app
                }

                init() {
                    self.app = XCUIApplication()
                }
            }
            """,
            macros: testMacros
        )
    }

    // MARK: - @Element: query format

    func testElementIdLocator() {
        assertMacroExpansion(
            """
            @Element(.textField, .id("email"), actions: [])
            var email: XCUIElement
            """,
            expandedSource: """
            var email: XCUIElement {
                get {
                    _scope.textFields.matching(identifier: "email").firstMatch
                }
            }
            """,
            macros: testMacros
        )
    }

    func testElementIdLocatorWithIndex() {
        assertMacroExpansion(
            """
            @Element(.button, .id("ok", index: 1), actions: [])
            var okButton: XCUIElement
            """,
            expandedSource: """
            var okButton: XCUIElement {
                get {
                    _scope.buttons.matching(identifier: "ok").element(boundBy: 1)
                }
            }
            """,
            macros: testMacros
        )
    }

    func testElementLabelLocator() {
        assertMacroExpansion(
            """
            @Element(.staticText, .label("Welcome"), actions: [])
            var welcomeLabel: XCUIElement
            """,
            expandedSource: """
            var welcomeLabel: XCUIElement {
                get {
                    _scope.staticTexts.matching(NSPredicate(format: "label == %@", "Welcome")).firstMatch
                }
            }
            """,
            macros: testMacros
        )
    }

    func testElementLabelContainsLocator() {
        assertMacroExpansion(
            """
            @Element(.staticText, .labelContains("Welcome"), actions: [])
            var welcomeLabel: XCUIElement
            """,
            expandedSource: """
            var welcomeLabel: XCUIElement {
                get {
                    _scope.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Welcome")).firstMatch
                }
            }
            """,
            macros: testMacros
        )
    }

    func testElementPredicateLocator() {
        assertMacroExpansion(
            """
            @Element(.cell, .predicate("enabled == true AND label CONTAINS 'Item'"), actions: [])
            var featuredCell: XCUIElement
            """,
            expandedSource: """
            var featuredCell: XCUIElement {
                get {
                    _scope.cells.matching(NSPredicate(format: "enabled == true AND label CONTAINS 'Item'")).firstMatch
                }
            }
            """,
            macros: testMacros
        )
    }

    func testElementIndexLocator() {
        assertMacroExpansion(
            """
            @Element(.button, .index(2), actions: [])
            var thirdButton: XCUIElement
            """,
            expandedSource: """
            var thirdButton: XCUIElement {
                get {
                    _scope.buttons.element(boundBy: 2)
                }
            }
            """,
            macros: testMacros
        )
    }

    func testElementNoLocator() {
        assertMacroExpansion(
            """
            @Element(.activityIndicator, actions: [])
            var spinner: XCUIElement
            """,
            expandedSource: """
            var spinner: XCUIElement {
                get {
                    _scope.activityIndicators.firstMatch
                }
            }
            """,
            macros: testMacros
        )
    }

    // MARK: - @Element: peer methods

    func testElementTapAction() {
        assertMacroExpansion(
            """
            @Element(.button, .id("login"), actions: [.tap])
            var loginButton: XCUIElement
            """,
            expandedSource: """
            var loginButton: XCUIElement {
                get {
                    _scope.buttons.matching(identifier: "login").firstMatch
                }
            }

            /// Taps the `loginButton` element.
            @discardableResult
            @MainActor
            func tapLoginButton() -> Self {
                loginButton.tap()
                return self
            }
            """,
            macros: testMacros
        )
    }

    func testElementAssertExistsAction() {
        assertMacroExpansion(
            """
            @Element(.button, .id("submit"), actions: [.assertExists])
            var submitButton: XCUIElement
            """,
            expandedSource: """
            var submitButton: XCUIElement {
                get {
                    _scope.buttons.matching(identifier: "submit").firstMatch
                }
            }

            /// Asserts that `submitButton` exists. Pass `timeout` to wait up to that many seconds before asserting.
            @discardableResult
            @MainActor
            func assertSubmitButtonExists(timeout: TimeInterval? = nil, file: StaticString = #filePath, line: UInt = #line) -> Self {
                if let timeout {
                    XCTAssertTrue(submitButton.waitForExistence(timeout: timeout), file: file, line: line)
                } else {
                    XCTAssertTrue(submitButton.exists, file: file, line: line)
                }
                return self
            }
            """,
            macros: testMacros
        )
    }

    func testElementTypeTextAction() {
        assertMacroExpansion(
            """
            @Element(.textField, .id("email"), actions: [.typeText])
            var email: XCUIElement
            """,
            expandedSource: """
            var email: XCUIElement {
                get {
                    _scope.textFields.matching(identifier: "email").firstMatch
                }
            }

            /// Types `text` into the `email` element.
            @discardableResult
            @MainActor
            func typeTextIntoEmail(_ text: String) -> Self {
                email.typeText(text)
                return self
            }
            """,
            macros: testMacros
        )
    }

    func testElementScrollToVisibleAction() {
        assertMacroExpansion(
            """
            @Element(.button, .id("submit"), actions: [.scrollToVisible])
            var submitButton: XCUIElement
            """,
            expandedSource: """
            var submitButton: XCUIElement {
                get {
                    _scope.buttons.matching(identifier: "submit").firstMatch
                }
            }

            /// Scrolls the nearest ancestor scroll view until `submitButton` is visible.
            @discardableResult
            @MainActor
            func scrollToVisibleSubmitButton() -> Self {
                submitButton.scrollToVisible()
                return self
            }
            """,
            macros: testMacros
        )
    }

    func testPageVerifyDefaultScreen() {
        assertMacroExpansion(
            """
            @Page
            struct CheckoutPage {
                @Element(.button, .id("pay"), verify: true, actions: [])
                var payButton: XCUIElement

                @Element(.staticText, .id("total"), verify: true, actions: [])
                var totalLabel: XCUIElement

                @Element(.button, .id("cancel"), actions: [])
                var cancelButton: XCUIElement
            }
            """,
            expandedSource: """
            struct CheckoutPage {
                @Element(.button, .id("pay"), verify: true, actions: [])
                var payButton: XCUIElement

                @Element(.staticText, .id("total"), verify: true, actions: [])
                var totalLabel: XCUIElement

                @Element(.button, .id("cancel"), actions: [])
                var cancelButton: XCUIElement

                let app: XCUIApplication

                var _scope: XCUIElement {
                    app
                }

                init(app: XCUIApplication) {
                    self.app = app
                }

                init() {
                    self.app = XCUIApplication()
                }

                /// Asserts that all core elements of this page exist.
                /// Pass `timeout` to wait up to that many seconds for each element before asserting.
                @discardableResult
                @MainActor
                func verifyDefaultScreen(timeout: TimeInterval? = nil, file: StaticString = #filePath, line: UInt = #line) -> Self {
                    if let timeout {
                        XCTAssertTrue(payButton.waitForExistence(timeout: timeout), file: file, line: line)
                        XCTAssertTrue(totalLabel.waitForExistence(timeout: timeout), file: file, line: line)
                    } else {
                        XCTAssertTrue(payButton.exists, file: file, line: line)
                        XCTAssertTrue(totalLabel.exists, file: file, line: line)
                    }
                    return self
                }
            }
            """,
            macros: ["Page": PageMacro.self]
        )
    }
}
