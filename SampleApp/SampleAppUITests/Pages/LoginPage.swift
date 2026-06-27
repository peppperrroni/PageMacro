import XCTest
import PageMacro

// @Page(scope:) — all elements query within the scroll view.
@Page(scope: .scrollView(id: "loginScroll"))
struct LoginPage {
    @Element(.textField, .id("email"), verify: true)
    var email: XCUIElement

    @Element(.secureTextField, .id("password"), verify: true)
    var password: XCUIElement

    @Element(.button, .id("login"), verify: true)
    var loginButton: XCUIElement

    @Element(.staticText, .id("welcome_label"), actions: [.assertExists, .assertLabel])
    var welcomeLabel: XCUIElement
}
