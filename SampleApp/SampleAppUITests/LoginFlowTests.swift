import XCTest

@MainActor
final class LoginFlowTests: XCTestCase {
    private var app: XCUIApplication!
    private var login: LoginPage!

    override func setUp() async throws {
        try await super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        login = LoginPage(app: app)
    }

    override func tearDown() async throws {
        app.terminate()
        try await super.tearDown()
    }

    func testLoginWithValidCredentials() {
        login
            .tapEmail()
            .typeTextIntoEmail("user@example.com")
            .tapPassword()
            .typeTextIntoPassword("secret123")
            .assertLoginButtonExists()
            .assertLoginButtonEnabled()
            .tapLoginButton()
            .assertWelcomeLabelExists(timeout: 5)
    }

    func testLoginButtonExistsOnLaunch() {
        login.verifyDefaultScreen()
    }

    func testEmailFieldPlaceholder() {
        login
            .assertEmailPlaceholder("Email")
            .assertPasswordPlaceholder("Password")
    }
}
