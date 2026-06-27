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

// tapEmail(), typeTextIntoEmail(_:), tapLoginButton(),
// assertLoginButtonExists(timeout:) — all generated.
```

## Table of Contents

- [Installation](#installation)
- [Why PageMacro](#why-pagemacro)
- [Quick Start](#quick-start)
- [@Page](#page)
- [@Element](#element)
- [Locators](#locators)
- [Screen Verification](#screen-verification)
- [Scoped Pages](#scoped-pages)
- [Element Lists](#element-lists)
- [Multi-App Support](#multi-app-support)
- [Generated Methods](#generated-methods)
- [Default Actions per Type](#default-actions-per-type)
- [Supported Element Types](#supported-element-types)

---

## Installation

### Swift Package Manager

```swift
.package(url: "https://github.com/peppperrroni/PageMacro", from: "2.0.0")
```

```swift
.target(
    name: "MyAppUITests",
    dependencies: ["PageMacro"]
)
```

**Requirements:** Swift 6.0+ · Xcode 16+ · iOS 17+

---

## Why PageMacro

Without tooling, every page object is hundreds of lines of boilerplate:

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

PageMacro replaces all of it with declarations. The result is a fluent, chainable API that reads like a test script:

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

## Quick Start

```swift
import PageMacro

@Page
struct LoginPage {
    @Element(.textField, .id("email"), verify: true)
    var email: XCUIElement

    @Element(.secureTextField, .id("password"), verify: true)
    var password: XCUIElement

    @Element(.button, .id("login"), verify: true)
    var loginButton: XCUIElement

    @Element(.staticText, .id("welcome"), actions: [.assertExists, .assertLabel])
    var welcomeLabel: XCUIElement
}
```

---

## @Page

Applied to a struct. Generates `app`, `_scope`, and two initializers:

```swift
@Page
struct LoginPage { ... }

LoginPage()              // uses XCUIApplication()
LoginPage(app: myApp)    // custom instance
```

---

## @Element

```swift
@Element(_ type: ElementType, _ locator: Locator?, actions: [ElementAction]?, verify: Bool)
```

| Parameter | Description |
|---|---|
| `type` | Element kind — `.button`, `.textField`, etc. |
| `locator` | How to find it. Omit for `.firstMatch` |
| `actions` | Methods to generate. Defaults per type. Pass `[]` to suppress all |
| `verify` | Include in `verifyDefaultScreen()` |

---

## Locators

| Locator | Use when |
|---|---|
| `.id("login")` | Element has an accessibility identifier (preferred) |
| `.id("ok", index: 1)` | Multiple elements share the same identifier |
| `.label("Sign In")` | Exact label match |
| `.labelContains("Welcome")` | Partial or dynamic label |
| `.predicate("enabled == true AND label CONTAINS 'Item'")` | Any `NSPredicate` expression |
| `.index(2)` | Nth element, no string filter |
| _(omitted)_ | Single element of that type in scope |

Expression-based identifiers are also supported:

```swift
@Element(.button, .id(AccessibilityID.login.rawValue))
var loginButton: XCUIElement
```

If a locator argument is provided but cannot be parsed, the macro throws a compile-time error instead of silently falling back.

---

## Screen Verification

Mark elements that define the screen with `verify: true`. `@Page` generates `verifyDefaultScreen(timeout:)`:

```swift
@Page
struct LoginPage {
    @Element(.textField, .id("email"), verify: true)
    var email: XCUIElement

    @Element(.button, .id("login"), verify: true)
    var loginButton: XCUIElement
}

LoginPage().verifyDefaultScreen()           // immediate
LoginPage().verifyDefaultScreen(timeout: 5) // wait up to 5s per element
```

---

## Scoped Pages

Narrow all element queries to a container:

```swift
@Page(scope: .scrollView(id: "loginScroll"))
struct LoginPage {
    @Element(.textField, .id("email"))  // queries inside loginScroll
    var email: XCUIElement
}
```

Supported: `.scrollView`, `.table`, `.collectionView`, `.alert`, `.navigationBar`, `.tabBar`, `.toolbar`, `.webView`, `.picker`, `.datePicker`, `.view` — each with optional `id:`, `label:`, `index:`.

---

## Element Lists

Model repeated elements with the same structure using `@ElementList`:

```swift
struct PropertyCell: ElementComponent {
    let app: XCUIApplication
    let _scope: XCUIElement

    init(app: XCUIApplication, scope: XCUIElement) {
        self.app = app
        self._scope = scope
    }

    @Element(.staticText, .id("property_title"))
    var title: XCUIElement

    @Element(.staticText, .id("property_price"))
    var price: XCUIElement
}

@Page
struct ResultsPage {
    @ElementList(.cell, .collectionView(id: "results"), row: PropertyCell.self)
    var properties: ElementList<PropertyCell>
}
```

### Access by index, id, or text

```swift
// By index
page.properties[0].tap()

// By accessibility identifier
page.properties[id: "property_42"]
    .assertTitleLabel("Modern 2 bed flat")

// By contained text
page.properties.containing("Beach House").tap()

// Count
XCTAssertGreaterThan(page.properties.count, 0)
```

### Without a container

When used inside a scoped page or when elements are at the root level:

```swift
@Page
struct SettingsPage {
    @ElementList(.button, row: ActionRow.self)
    var actions: ElementList<ActionRow>
}
```

### ElementComponent protocol

Every `ElementComponent` conformer gets these methods for free:

| Method | Description |
|---|---|
| `tap()` | Taps the element |
| `assertExists(timeout:)` | Asserts the element exists |
| `assertNotExists()` | Asserts the element does not exist |
| `element` | The underlying `XCUIElement` |
| `exists` | Whether the element exists |

### ElementList API

| Method / Subscript | Returns | Description |
|---|---|---|
| `count` | `Int` | Number of matching elements |
| `[index]` | `Row` | Element at zero-based index |
| `[id: "x"]` | `Row` | First element matching the identifier |
| `matching(identifier:)` | `Row` | Same as subscript by id |
| `matching(_: NSPredicate)` | `Row` | First element matching a predicate |
| `containing("text")` | `Row` | First element whose label contains the text |

---

## Multi-App Support

```swift
@Page(bundle: "com.apple.mobilesafari")
struct SafariPage {
    @Element(.button, .id("Done"))
    var doneButton: XCUIElement
}

SafariPage().tapDoneButton()
```

---

## Generated Methods

Given `@Element(.button, .id("submit"))` on `var submitButton`:

| Action | Generated Method |
|---|---|
| `.tap` | `tapSubmitButton()` |
| `.doubleTap` | `doubleTapSubmitButton()` |
| `.longPress` | `longPressSubmitButton()` |
| `.typeText` | `typeTextIntoSubmitButton(_ text:)` |
| `.clearText` | `clearSubmitButton()` |
| `.swipeUp/Down/Left/Right` | `swipeUpSubmitButton()` etc. |
| `.scrollToVisible` | `scrollToVisibleSubmitButton()` |
| `.assertExists` | `assertSubmitButtonExists(timeout:)` |
| `.assertNotExists` | `assertSubmitButtonNotExists(timeout:)` |
| `.assertDisappear` | `assertSubmitButtonDisappear(timeout:)` |
| `.assertEnabled` | `assertSubmitButtonEnabled(timeout:)` |
| `.assertDisabled` | `assertSubmitButtonDisabled(timeout:)` |
| `.assertSelected` | `assertSubmitButtonSelected(timeout:)` |
| `.assertNotSelected` | `assertSubmitButtonNotSelected(timeout:)` |
| `.assertValue` | `assertSubmitButtonValue(_ expected:)` |
| `.assertLabel` | `assertSubmitButtonLabel(_ expected:)` |
| `.assertPlaceholder` | `assertSubmitButtonPlaceholder(_ expected:)` |
| `.assertOn` | `assertSubmitButtonOn(timeout:)` |
| `.assertOff` | `assertSubmitButtonOff(timeout:)` |

All methods return `Self` for chaining. All assertion methods accept an optional `timeout`.

---

## Default Actions per Type

| Element type | Default actions |
|---|---|
| `.textField`, `.searchField` | `tap`, `typeText`, `clearText`, `assertExists`, `assertValue`, `assertPlaceholder` |
| `.secureTextField` | `tap`, `typeText`, `clearText`, `assertExists`, `assertPlaceholder` |
| `.button` | `tap`, `assertExists`, `assertEnabled`, `assertDisabled` |
| `.staticText` | `assertExists`, `assertLabel` |
| `.cell` | `tap`, `assertExists` |
| `.toggle` | `tap`, `assertExists`, `assertOn`, `assertOff` |
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
