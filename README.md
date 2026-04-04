# XCUIPage

Swift macros that eliminate boilerplate in XCUITest Page Objects.

## The problem

Every Page Object in XCUITest requires the same scaffolding:

```swift
struct LoginPage {
    let app: XCUIApplication

    var email: XCUIElement { app.textFields["email"] }
    var password: XCUIElement { app.secureTextFields["password"] }
    var loginButton: XCUIElement { app.buttons["login"] }

    init(app: XCUIApplication) { self.app = app }
}
```

## The solution

```swift
import XCUIPage

@Page
struct LoginPage {
    @Element(.textField, id: "email")
    var email: XCUIElement

    @Element(.secureTextField, id: "password")
    var password: XCUIElement

    @Element(.button, id: "login")
    var loginButton: XCUIElement
}
```

`@Page` generates the `app` property and `init`. `@Element` generates the computed accessor.

## Usage

```swift
let login = LoginPage(app: XCUIApplication())
login.email.tap()
login.email.typeText("user@example.com")
login.loginButton.tap()
```

## Supported element types

| `ElementType`       | XCUIApplication query     |
|---------------------|---------------------------|
| `.textField`        | `textFields`              |
| `.secureTextField`  | `secureTextFields`        |
| `.button`           | `buttons`                 |
| `.staticText`       | `staticTexts`             |
| `.image`            | `images`                  |
| `.cell`             | `cells`                   |
| `.toggle`           | `switches`                |
| `.slider`           | `sliders`                 |
| `.segmentedControl` | `segmentedControls`       |
| `.datePicker`       | `datePickers`             |
| `.picker`           | `pickers`                 |
| `.pickerWheel`      | `pickerWheels`            |
| `.scrollView`       | `scrollViews`             |
| `.table`            | `tables`                  |
| `.collectionView`   | `collectionViews`         |
| `.navigationBar`    | `navigationBars`          |
| `.tabBar`           | `tabBars`                 |
| `.toolbar`          | `toolbars`                |
| `.activityIndicator`| `activityIndicators`      |
| `.alert`            | `alerts`                  |
| `.searchField`      | `searchFields`            |
| `.link`             | `links`                   |
| `.webView`          | `webViews`                |

## Swift Package Manager

```swift
.package(url: "https://github.com/peppperrroni/XCUIPage", from: "1.0.0")
```

```swift
// In your UITest target:
.target(
    name: "MyAppUITests",
    dependencies: ["XCUIPage"]
)
```

## Requirements

- Swift 6.0+
- Xcode 16+
- iOS 17+

## License

MIT
