# PageMacro

**Stop writing XCUITest page objects by hand.**

PageMacro is a Swift macro library that generates element accessors, fluent action methods, and assertion helpers from a two-line declaration — at compile time, with full type safety and Xcode autocomplete.

```swift
@Page
struct LoginPage {
    @Element(.textField, .id("email"))
    var email: XCUIElement

    @Element(.button, .id("login"))
    var loginButton: XCUIElement
}

// That's it. tapEmail(), typeTextIntoEmail(_:), tapLoginButton(),
// assertLoginButtonExists(timeout:) — all generated.
```

---

## Why PageMacro

Without tooling, every page object is hundreds of lines of near-identical boilerplate:

```swift
struct LoginPage {
    let app: XCUIApplication
    init(app: XCUIApplication) { self.app = app }

    var email: XCUIElement {
        app.textFields.matching(identifier: "email").firstMatch
    }
    func tapEmail() -> Self { email.tap(); return self }
    func typeTextIntoEmail(_ text: String) -> Self {
        email.typeText(text); return self
    }
    // … repeated for every element, every action, every assertion
}
```

PageMacro replaces all of it with declarations:

```swift
@Page
struct LoginPage {
    @Element(.textField, .id("email"))
    var email: XCUIElement

    @Element(.secureTextField, .id("password"))
    var password: XCUIElement

    @Element(.button, .id("login"))
    var loginButton: XCUIElement

    @Element(.staticText, .id("welcome_label"), actions: [.assertExists, .assertLabel])
    var welcomeLabel: XCUIElement
}
```

The result is a fluent, chainable API that reads like a test script:

```swift
func testLoginFlow() {
    LoginPage()
        .tapEmail()
        .typeTextIntoEmail("user@example.com")
        .tapPassword()
        .typeTextIntoPassword("s3cr3t")
        .tapLoginButton()
        .assertWelcomeLabelExists(timeout: 5)
}
```

---

## Features

- **Zero boilerplate** — element accessors, tap/type/swipe/assert methods all generated
- **Fluent API** — every method returns `Self` for chaining
- **Compile-time generation** — no scripts, no templates, no separate build step
- **Xcode autocomplete** — every generated method has a `///` doc comment
- **Flexible locators** — identifier, label, predicate, index, or `.firstMatch`
- **Smart defaults** — per-type action sets out of the box, fully overridable
- **Screen verification** — mark key elements with `verify: true`, get `verifyDefaultScreen(timeout:)` for free
- **Element lists / reusable row objects** — model repeated elements as typed row components with `@ElementList`
- **Scoped queries** — narrow all element lookups to a container with `@Page(scope:)`
- **Multi-app support** — target any app by bundle ID with `@Page(bundle:)`

---

## Installation

### Swift Package Manager

```swift
// Package.swift
.package(url: "https://github.com/peppperrroni/PageMacro", from: "1.0.0")
```

```swift
// In your UITest target:
.target(
    name: "MyAppUITests",
    dependencies: ["PageMacro"]
)
```

**Requirements:** Swift 6.0+ · Xcode 16+ · iOS 17+

---

## Usage

### `@Page`

Applied to a struct. Generates `app`, `_scope`, and two initializers:

```swift
@Page
struct LoginPage { ... }

LoginPage()              // uses XCUIApplication()
LoginPage(app: myApp)    // custom instance — useful when you need launch arguments
```

Need launch arguments? Pass your configured instance:

```swift
let app = XCUIApplication()
app.launchArguments = ["--reset-state"]
app.launch()

LoginPage(app: app).verifyDefaultScreen()
```

### `@Element`

```swift
@Element(_ type: ElementType, _ locator: Locator? = nil, actions: [ElementAction]? = nil, verify: Bool = false)
```

| Parameter | Description |
|---|---|
| `type` | Element kind — `.button`, `.textField`, etc. |
| `locator` | How to find it. Omit for `.firstMatch` |
| `actions` | Methods to generate. Defaults per type. Pass `[]` to suppress all |
| `verify` | Include in `verifyDefaultScreen()` |

### Locators

| Locator | Use when |
|---|---|
| `.id("login")` | Element has an accessibility identifier (preferred) |
| `.id("ok", index: 1)` | Multiple elements share the same identifier |
| `.label("Sign In")` | Exact label match |
| `.labelContains("Welcome")` | Partial or dynamic label |
| `.predicate("enabled == true AND label CONTAINS 'Item'")` | Any `NSPredicate` expression |
| `.index(2)` | Nth element, no string filter |
| _(omitted)_ | Single element of that type in scope |

### Screen Verification

Mark elements that define the screen with `verify: true`. `@Page` generates `verifyDefaultScreen(timeout:)` that asserts all of them exist:

```swift
@Page
struct LoginPage {
    @Element(.textField, .id("email"), verify: true)
    var email: XCUIElement
    @Element(.secureTextField, .id("password"), verify: true)
    var password: XCUIElement
    @Element(.button, .id("login"), verify: true)
    var loginButton: XCUIElement
}

LoginPage().verifyDefaultScreen()           // immediate
LoginPage().verifyDefaultScreen(timeout: 5) // wait up to 5 s per element
```

Only generated when at least one element has `verify: true`.

### Scoped Pages

Narrow all element queries to a container:

```swift
@Page(scope: .scrollView(id: "loginScroll"))
struct LoginPage {
    @Element(.textField, .id("email"))  // queries inside loginScroll, not the full app
    var email: XCUIElement
}
```

Supported container types: `.scrollView(id:)`, `.table(id:)`, `.collectionView(id:)`, `.alert(label:)`, and more.

### Reusable Elements / Element Lists

When a container has repeated elements with the same structure, model each element as an `ElementComponent` and use `@ElementList` to generate a typed accessor. The first argument specifies the element type to query:

```swift
@Page
struct SearchResultsPage {
    @ElementList(.cell, .collectionView(id: "property_results"), row: PropertyCell.self)
    var properties: ElementList<PropertyCell>
}

struct PropertyCell: ElementComponent {
    let app: XCUIApplication
    let _scope: XCUIElement   // the cell element

    var titleLabel: XCUIElement {
        _scope.staticTexts["property_title"].firstMatch
    }
    var priceLabel: XCUIElement {
        _scope.staticTexts["property_price"].firstMatch
    }

    init(app: XCUIApplication, scope: XCUIElement) {
        self.app = app
        self._scope = scope
    }
}
```

Access elements by index, identifier, or text content:

```swift
func testSearchResults() {
    let page = SearchResultsPage()

    // By index
    let firstCell = page.properties[0]
    XCTAssertTrue(firstCell.titleLabel.exists)

    // By accessibility identifier
    let specific = page.properties[id: "property_42"]
    XCTAssertEqual(specific.priceLabel.label, "$350,000")

    // By text content
    let match = page.properties.containing("Beach House")
    match.element.tap()

    // Count
    XCTAssertGreaterThan(page.properties.count, 0)
}
```

`@ElementList` works with or without a container. Without a container, it queries `_scope.{elementType}` directly (useful inside a scoped page):

```swift
@Page(scope: .table(id: "results"))
struct ResultsPage {
    @ElementList(.cell, row: ResultCell.self)
    var results: ElementList<ResultCell>
}
```

You can also query non-cell element types:

```swift
@Page
struct SettingsPage {
    @ElementList(.button, row: ActionRow.self)
    var actions: ElementList<ActionRow>
}
```

#### `ElementList` API

| Method / Subscript | Returns | Description |
|---|---|---|
| `count` | `Int` | Number of elements matching the query |
| `[index]` | `Row` | Element at the given index (zero-based) |
| `[id: "x"]` | `Row` | First element matching the accessibility identifier |
| `matching(identifier:)` | `Row` | Same as subscript by id |
| `matching(_: NSPredicate)` | `Row` | First element matching a predicate |
| `containing("text")` | `Row` | First element whose label contains the text |

### Testing Other Apps

```swift
@Page(bundle: "com.apple.mobilesafari")
struct SafariPage {
    @Element(.button, .id("Done"))
    var doneButton: XCUIElement
}

SafariPage().tapDoneButton()  // bundle ID is baked in at compile time
```

---

## Generated Methods

Given `var submitButton: XCUIElement`, `@Element(.button, .id("submit"))` generates:

| Action | Method |
|---|---|
| `.tap` | `tapSubmitButton() -> Self` |
| `.doubleTap` | `doubleTapSubmitButton() -> Self` |
| `.longPress` | `longPressSubmitButton() -> Self` |
| `.typeText` | `typeTextIntoSubmitButton(_ text: String) -> Self` |
| `.clearText` | `clearSubmitButton() -> Self` |
| `.swipeUp/Down/Left/Right` | `swipeUp/Down/Left/RightSubmitButton() -> Self` |
| `.scrollToVisible` | `scrollToVisibleSubmitButton() -> Self` |
| `.assertExists` | `assertSubmitButtonExists(timeout:file:line:) -> Self` |
| `.assertNotExists` | `assertSubmitButtonNotExists(timeout:file:line:) -> Self` |
| `.assertDisappear` | `assertSubmitButtonDisappear(timeout:file:line:) -> Self` |
| `.assertEnabled` | `assertSubmitButtonEnabled(timeout:file:line:) -> Self` |
| `.assertDisabled` | `assertSubmitButtonDisabled(timeout:file:line:) -> Self` |
| `.assertSelected` | `assertSubmitButtonSelected(timeout:file:line:) -> Self` |
| `.assertNotSelected` | `assertSubmitButtonNotSelected(timeout:file:line:) -> Self` |
| `.assertValue` | `assertSubmitButtonValue(_ expected:timeout:file:line:) -> Self` |
| `.assertLabel` | `assertSubmitButtonLabel(_ expected:timeout:file:line:) -> Self` |
| `.assertPlaceholder` | `assertSubmitButtonPlaceholder(_ expected:file:line:) -> Self` |

All assertion methods take an optional `timeout: TimeInterval?` — omit for an immediate check, pass a value to poll:

```swift
login.assertLoginButtonExists()          // immediate
login.assertWelcomeLabelExists(timeout: 5) // polls up to 5 s
login.assertLoginButtonEnabled(timeout: 2) // waits until actually enabled
```

### Default actions per element type

| Element type | Default actions |
|---|---|
| `.textField`, `.searchField` | `tap`, `typeText`, `clearText`, `assertExists`, `assertValue`, `assertPlaceholder` |
| `.secureTextField` | `tap`, `typeText`, `clearText`, `assertExists`, `assertPlaceholder` |
| `.button` | `tap`, `assertExists`, `assertEnabled`, `assertDisabled` |
| `.staticText` | `assertExists`, `assertLabel` |
| `.cell` | `tap`, `assertExists` |
| `.toggle` | `tap`, `assertExists`, `assertSelected`, `assertNotSelected` |
| `.scrollView`, `.table`, `.collectionView` | `swipeUp`, `swipeDown`, `assertExists` |
| everything else | `tap`, `assertExists` |

---

## Supported Element Types

| Value | Maps to |
|---|---|
| `.textField` | `textFields` |
| `.secureTextField` | `secureTextFields` |
| `.button` | `buttons` |
| `.staticText` | `staticTexts` |
| `.image` | `images` |
| `.cell` | `cells` |
| `.toggle` | `switches` |
| `.slider` | `sliders` |
| `.segmentedControl` | `segmentedControls` |
| `.datePicker` | `datePickers` |
| `.picker` | `pickers` |
| `.pickerWheel` | `pickerWheels` |
| `.scrollView` | `scrollViews` |
| `.table` | `tables` |
| `.collectionView` | `collectionViews` |
| `.navigationBar` | `navigationBars` |
| `.tabBar` | `tabBars` |
| `.toolbar` | `toolbars` |
| `.activityIndicator` | `activityIndicators` |
| `.alert` | `alerts` |
| `.searchField` | `searchFields` |
| `.link` | `links` |
| `.webView` | `webViews` |
