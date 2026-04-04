import XCTest
import XCUIPage

@Page
struct LoginPage {
    @Element(.textField, id: "email")
    var email: XCUIElement

    @Element(.secureTextField, id: "password")
    var password: XCUIElement

    @Element(.button, id: "login")
    var loginButton: XCUIElement

    @Element(.staticText, id: "welcome_label")
    var welcomeLabel: XCUIElement
}
