/// Actions that can be generated as fluent helper methods on a Page Object.
///
/// Pass to `@Element(actions:)` to specify which methods are generated.
/// If `actions:` is omitted, a sensible default set is chosen per element type.
public enum ElementAction: Sendable {
    // MARK: - Gestures
    case tap
    case doubleTap
    case longPress
    case swipeUp
    case swipeDown
    case swipeLeft
    case swipeRight
    case scrollToVisible

    // MARK: - Text input
    case typeText
    case clearText

    // MARK: - Assertions
    case assertExists
    case assertNotExists
    case assertDisappear
    case assertEnabled
    case assertDisabled
    case assertSelected
    case assertNotSelected
    case assertValue
    case assertLabel
    case assertPlaceholder
    case assertOn
    case assertOff
}

// MARK: - XCUIElement helpers

#if canImport(XCTest)
import XCTest

@MainActor
public extension XCUIElement {

    /// Taps the element and deletes its current text content character by character.
    @discardableResult
    func clearText() -> XCUIElement {
        guard let currentText = value as? String, !currentText.isEmpty else { return self }
        tap()
        typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: currentText.count))
        return self
    }
}
#endif
