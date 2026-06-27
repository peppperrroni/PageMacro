/// A container element type used with `@Scope` and `@Page(scope:)`.
///
/// Unlike `ElementType`, `ContainerType` only includes element types that can
/// contain child elements. The locator (id, label, index) is embedded directly
/// as associated values rather than passed as separate arguments.
///
/// ```swift
/// @Scope(.scrollView(id: "formContainer"))
/// var formScroll: XCUIElement
///
/// @Scope(.table(id: "results"), in: "formScroll")
/// var resultsTable: XCUIElement
///
/// @Page(scope: .scrollView(id: "loginScroll"))
/// struct LoginPage { ... }
/// ```
public enum ContainerType: Sendable {
    case scrollView(id: String? = nil, label: String? = nil, index: Int? = nil)
    case table(id: String? = nil, label: String? = nil, index: Int? = nil)
    case collectionView(id: String? = nil, label: String? = nil, index: Int? = nil)
    case cell(id: String? = nil, label: String? = nil, index: Int? = nil)
    case navigationBar(id: String? = nil, label: String? = nil, index: Int? = nil)
    case tabBar(id: String? = nil, label: String? = nil, index: Int? = nil)
    case toolbar(id: String? = nil, label: String? = nil, index: Int? = nil)
    case alert(id: String? = nil, label: String? = nil, index: Int? = nil)
    case webView(id: String? = nil, label: String? = nil, index: Int? = nil)
    case picker(id: String? = nil, label: String? = nil, index: Int? = nil)
    case datePicker(id: String? = nil, label: String? = nil, index: Int? = nil)
    case view(id: String? = nil, label: String? = nil, index: Int? = nil)
}
