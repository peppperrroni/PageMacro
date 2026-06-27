/// Marks a struct as a Page Object for XCUITest.
///
/// Generates:
/// - `let app: XCUIApplication`
/// - `var _scope: XCUIElement` — the root all `@Element`/`@Scope` queries chain from.
///   Forwards to `app` unless `scope:` is set.
/// - `init(app:)` — or `init()` when `bundle:` is provided.
///
/// **Parameters**
/// - `bundle:` pins the page to a specific app by bundle identifier.
/// - `scope:` narrows every element query to a specific container using a `ContainerType`
///   with the locator embedded (e.g. `.scrollView(id: "formContainer")`). All `@Element`
///   and `@Scope` accessors in the struct will root their queries in this element.
///
/// ```swift
/// // Standard — caller provides the app
/// @Page
/// struct LoginPage {
///     @Element(.textField, id: "email")
///     var email: XCUIElement
/// }
///
/// // Scoped — all elements query within the "formContainer" scroll view
/// @Page(scope: .scrollView(id: "formContainer"))
/// struct RegistrationPage {
///     @Element(.textField, id: "name")
///     var nameField: XCUIElement
/// }
///
/// // Bundle-pinned — useful for Safari or other system apps
/// @Page(bundle: "com.apple.mobilesafari")
/// struct SafariPage {
///     @Element(.button, id: "done")
///     var doneButton: XCUIElement
/// }
/// ```
@attached(member, names: named(app), named(_scope), named(init), named(verifyDefaultScreen))
public macro Page(
    bundle: String? = nil,
    scope: ContainerType? = nil
) = #externalMacro(module: "PageMacroMacros", type: "PageMacro")

/// Generates a computed `XCUIElement` accessor and fluent helper methods.
///
/// Queries relative to the page's `_scope` (set by `@Page(scope:)`, or `app` by default).
/// The second argument is a `Locator` that describes how to find the element.
///
/// ```swift
/// @Element(.textField,  .id("email"))
/// var email: XCUIElement
///
/// @Element(.button,     .id("submit"), actions: [.tap, .assertExists, .assertEnabled])
/// var submitButton: XCUIElement
///
/// @Element(.staticText, .labelContains("Welcome"))
/// var welcomeLabel: XCUIElement
///
/// @Element(.cell,       .predicate("enabled == true AND label CONTAINS 'Item'"))
/// var featuredCell: XCUIElement
///
/// @Element(.button,     .index(2))
/// var thirdButton: XCUIElement
///
/// @Element(.button,     .id("ok", index: 1))
/// var secondOkButton: XCUIElement
/// ```
@attached(accessor, names: named(get))
@attached(peer, names: arbitrary)
public macro Element(
    _ type: ElementType,
    _ locator: Locator? = nil,
    actions: [ElementAction]? = nil,
    verify: Bool = false
) = #externalMacro(module: "PageMacroMacros", type: "ElementMacro")

/// Generates a computed `ElementList<Row>` accessor for repeated elements.
///
/// The first argument specifies the element type to query (e.g. `.button`, `.cell`).
/// An optional second argument narrows the query to a container.
///
/// ```swift
/// @ElementList(.button, row: SoundRow.self)
/// var sounds: ElementList<SoundRow>
///
/// @ElementList(.cell, .table(id: "results"), row: ResultRow.self)
/// var results: ElementList<ResultRow>
/// ```
@attached(accessor, names: named(get))
public macro ElementList(
    _ type: ElementType,
    _ container: ContainerType? = nil,
    row: Any.Type
) = #externalMacro(module: "PageMacroMacros", type: "ElementListMacro")
