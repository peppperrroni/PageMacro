/// Marks a struct as a Page Object for XCUITest.
///
/// Generates `let app: XCUIApplication` and `init(app: XCUIApplication)`.
/// Mark individual element properties with `@Element`.
///
/// ```swift
/// @Page
/// struct LoginPage {
///     @Element(.textField, id: "email")
///     var email: XCUIElement
///
///     @Element(.button, id: "login")
///     var loginButton: XCUIElement
/// }
/// ```
@attached(member, names: named(app), named(init))
public macro Page() = #externalMacro(module: "XCUIPageMacros", type: "PageMacro")

/// Generates a computed `XCUIElement` property using an accessibility identifier query.
///
/// - Parameters:
///   - type: The element type (e.g. `.button`, `.textField`).
///   - id: The accessibility identifier string.
///
/// Must be applied to a `var` with an explicit `XCUIElement` type annotation.
///
/// ```swift
/// @Element(.button, id: "submit")
/// var submitButton: XCUIElement
/// ```
@attached(accessor, names: named(get))
public macro Element(_ type: ElementType, id: String) = #externalMacro(module: "XCUIPageMacros", type: "ElementMacro")
