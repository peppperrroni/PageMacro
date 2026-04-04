import XCTest

final class LoginFlowTests: XCTestCase {
    private var app: XCUIApplication!
    private var login: LoginPage!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        login = LoginPage(app: app)
    }

    override func tearDown() {
        app.terminate()
        super.tearDown()
    }

    func testLoginWithValidCredentials() {
        login.email.tap()
        login.email.typeText("user@example.com")

        login.password.tap()
        login.password.typeText("secret123")

        login.loginButton.tap()

        XCTAssertTrue(login.welcomeLabel.waitForExistence(timeout: 2))
    }

    func testLoginButtonExistsOnLaunch() {
        XCTAssertTrue(login.loginButton.exists)
        XCTAssertTrue(login.email.exists)
        XCTAssertTrue(login.password.exists)
    }
}
