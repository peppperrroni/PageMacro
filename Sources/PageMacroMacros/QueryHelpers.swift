import SwiftSyntax
import SwiftSyntaxMacros

// MARK: - Parsed locator

enum ParsedLocator {
    case id(String, index: Int?)
    case idExpr(String, index: Int?)
    case label(String, index: Int?)
    case labelContains(String, index: Int?)
    case predicate(String, index: Int?)
    case index(Int)
}

// MARK: - Shared parsed params

struct ParsedElementParams {
    let typeName: String
    let locator: ParsedLocator?
    let actions: [String]?   // nil = use type-specific defaults; [] = no peer methods
}

// MARK: - Argument parsing

func parseElementArgs(from node: AttributeSyntax) throws -> ParsedElementParams {
    guard
        let args = node.arguments?.as(LabeledExprListSyntax.self),
        !args.isEmpty
    else { throw MacroError.invalidArguments }

    let argArray = Array(args)

    guard let member = argArray[0].expression.as(MemberAccessExprSyntax.self) else {
        throw MacroError.invalidElementType
    }
    let typeName = member.declName.baseName.text

    var locator: ParsedLocator? = nil
    var actions: [String]? = nil
    var idx = 1

    // Second arg is the locator only if it has no label (positional)
    if idx < argArray.count && argArray[idx].label == nil {
        guard let parsed = parseLocatorExpr(argArray[idx].expression) else {
            throw MacroError.invalidLocator
        }
        locator = parsed
        idx += 1
    }

    // Remaining labeled args
    for arg in argArray[idx...] {
        if arg.label?.text == "actions",
           let arrayExpr = arg.expression.as(ArrayExprSyntax.self) {
            actions = arrayExpr.elements.compactMap {
                $0.expression.as(MemberAccessExprSyntax.self)?.declName.baseName.text
            }
        }
    }

    return ParsedElementParams(typeName: typeName, locator: locator, actions: actions)
}

/// Parses a `Locator` expression: `.id("email")`, `.labelContains("Welcome")`, `.index(2)`, etc.
func parseLocatorExpr(_ expr: ExprSyntax) -> ParsedLocator? {
    guard
        let call = expr.as(FunctionCallExprSyntax.self),
        let member = call.calledExpression.as(MemberAccessExprSyntax.self)
    else { return nil }

    let caseName = member.declName.baseName.text
    let callArgs = Array(call.arguments)

    switch caseName {
    case "index":
        if let intLit = callArgs.first?.expression.as(IntegerLiteralExprSyntax.self),
           let n = Int(intLit.literal.text) {
            return .index(n)
        }
    case "id":
        if let str = callArgs.first.flatMap({ extractString(from: $0.expression) }) {
            var index: Int? = nil
            for arg in callArgs.dropFirst() {
                if arg.label?.text == "index",
                   let intLit = arg.expression.as(IntegerLiteralExprSyntax.self) {
                    index = Int(intLit.literal.text)
                }
            }
            return .id(str, index: index)
        }
        // Non-literal expression: pass through raw source
        if let firstArg = callArgs.first {
            let rawExpr = firstArg.expression.trimmedDescription
            var index: Int? = nil
            for arg in callArgs.dropFirst() {
                if arg.label?.text == "index",
                   let intLit = arg.expression.as(IntegerLiteralExprSyntax.self) {
                    index = Int(intLit.literal.text)
                }
            }
            return .idExpr(rawExpr, index: index)
        }
        return nil
    case "label", "labelContains", "predicate":
        guard let str = callArgs.first.flatMap({ extractString(from: $0.expression) }) else { return nil }
        var index: Int? = nil
        for arg in callArgs.dropFirst() {
            if arg.label?.text == "index",
               let intLit = arg.expression.as(IntegerLiteralExprSyntax.self) {
                index = Int(intLit.literal.text)
            }
        }
        switch caseName {
        case "id":           return .id(str, index: index)
        case "label":        return .label(str, index: index)
        case "labelContains": return .labelContains(str, index: index)
        case "predicate":    return .predicate(str, index: index)
        default: break
        }
    default: break
    }
    return nil
}

func extractString(from expr: ExprSyntax) -> String? {
    guard
        let strLit = expr.as(StringLiteralExprSyntax.self),
        let seg = strLit.segments.first?.as(StringSegmentSyntax.self)
    else { return nil }
    return seg.content.text
}

// MARK: - ContainerType parsing

struct ParsedContainer {
    let typeName: String
    let id: String?
    let label: String?
    let index: Int?
}

/// Parses a `ContainerType` expression: either `.scrollView(id: "x")` or bare `.scrollView`.
func parseContainerExpr(_ expr: ExprSyntax) -> ParsedContainer? {
    // .scrollView(id: "content") — call with associated values
    if let call = expr.as(FunctionCallExprSyntax.self),
       let member = call.calledExpression.as(MemberAccessExprSyntax.self) {
        let typeName = member.declName.baseName.text
        var id: String? = nil
        var label: String? = nil
        var index: Int? = nil
        for arg in call.arguments {
            switch arg.label?.text {
            case "id":    id = extractString(from: arg.expression)
            case "label": label = extractString(from: arg.expression)
            case "index":
                if let intLit = arg.expression.as(IntegerLiteralExprSyntax.self) {
                    index = Int(intLit.literal.text)
                }
            default: break
            }
        }
        return ParsedContainer(typeName: typeName, id: id, label: label, index: index)
    }
    // .scrollView — bare member access (all associated-value defaults apply)
    if let member = expr.as(MemberAccessExprSyntax.self) {
        return ParsedContainer(typeName: member.declName.baseName.text, id: nil, label: nil, index: nil)
    }
    return nil
}

/// Maps a `ContainerType` case name to the XCUIElementQuery property name.
func containerTypeToQueryProperty(_ name: String) -> String {
    switch name {
    case "scrollView":      return "scrollViews"
    case "table":           return "tables"
    case "collectionView":  return "collectionViews"
    case "cell":            return "cells"
    case "navigationBar":   return "navigationBars"
    case "tabBar":          return "tabBars"
    case "toolbar":         return "toolbars"
    case "alert":           return "alerts"
    case "webView":         return "webViews"
    case "picker":          return "pickers"
    case "datePicker":      return "datePickers"
    default:                return "otherElements"
    }
}

// MARK: - Query builder

func buildQuery(root: String, queryProp: String, locator: ParsedLocator?) -> String {
    switch locator {
    case nil:
        return "\(root).\(queryProp).firstMatch"
    case .id(let str, let index):
        let access = index.map { ".element(boundBy: \($0))" } ?? ".firstMatch"
        return "\(root).\(queryProp).matching(identifier: \"\(str)\")\(access)"
    case .idExpr(let expr, let index):
        let access = index.map { ".element(boundBy: \($0))" } ?? ".firstMatch"
        return "\(root).\(queryProp).matching(identifier: \(expr))\(access)"
    case .label(let str, let index):
        let access = index.map { ".element(boundBy: \($0))" } ?? ".firstMatch"
        return "\(root).\(queryProp).matching(NSPredicate(format: \"label == %@\", \"\(str)\"))\(access)"
    case .labelContains(let str, let index):
        let access = index.map { ".element(boundBy: \($0))" } ?? ".firstMatch"
        return "\(root).\(queryProp).matching(NSPredicate(format: \"label CONTAINS %@\", \"\(str)\"))\(access)"
    case .predicate(let str, let index):
        let access = index.map { ".element(boundBy: \($0))" } ?? ".firstMatch"
        return "\(root).\(queryProp).matching(NSPredicate(format: \"\(str)\"))\(access)"
    case .index(let n):
        return "\(root).\(queryProp).element(boundBy: \(n))"
    }
}

// MARK: - Element type → XCUIElementQuery property name

func elementTypeToQueryProperty(_ name: String) -> String {
    switch name {
    case "textField":         return "textFields"
    case "secureTextField":   return "secureTextFields"
    case "button":            return "buttons"
    case "staticText":        return "staticTexts"
    case "image":             return "images"
    case "cell":              return "cells"
    case "toggle":            return "switches"
    case "slider":            return "sliders"
    case "segmentedControl":  return "segmentedControls"
    case "datePicker":        return "datePickers"
    case "picker":            return "pickers"
    case "pickerWheel":       return "pickerWheels"
    case "scrollView":        return "scrollViews"
    case "table":             return "tables"
    case "collectionView":    return "collectionViews"
    case "navigationBar":     return "navigationBars"
    case "tabBar":            return "tabBars"
    case "toolbar":           return "toolbars"
    case "activityIndicator": return "activityIndicators"
    case "alert":             return "alerts"
    case "searchField":       return "searchFields"
    case "link":              return "links"
    case "webView":           return "webViews"
    default:                  return "otherElements"
    }
}

// MARK: - Peer method builder

// swiftlint:disable function_body_length
func buildMethod(action: String, propName: String) -> DeclSyntax? {
    let cap = propName.prefix(1).uppercased() + propName.dropFirst()
    switch action {

    // MARK: Gestures
    case "tap":
        return """
            /// Taps the `\(raw: propName)` element.
            @discardableResult
            @MainActor
            func tap\(raw: cap)() -> Self {
                \(raw: propName).tap()
                return self
            }
            """
    case "doubleTap":
        return """
            /// Double-taps the `\(raw: propName)` element.
            @discardableResult
            @MainActor
            func doubleTap\(raw: cap)() -> Self {
                \(raw: propName).doubleTap()
                return self
            }
            """
    case "longPress":
        return """
            /// Long-presses the `\(raw: propName)` element (1 second).
            @discardableResult
            @MainActor
            func longPress\(raw: cap)() -> Self {
                \(raw: propName).press(forDuration: 1)
                return self
            }
            """
    case "swipeUp":
        return """
            /// Swipes up on the `\(raw: propName)` element.
            @discardableResult
            @MainActor
            func swipeUp\(raw: cap)() -> Self {
                \(raw: propName).swipeUp()
                return self
            }
            """
    case "swipeDown":
        return """
            /// Swipes down on the `\(raw: propName)` element.
            @discardableResult
            @MainActor
            func swipeDown\(raw: cap)() -> Self {
                \(raw: propName).swipeDown()
                return self
            }
            """
    case "swipeLeft":
        return """
            /// Swipes left on the `\(raw: propName)` element.
            @discardableResult
            @MainActor
            func swipeLeft\(raw: cap)() -> Self {
                \(raw: propName).swipeLeft()
                return self
            }
            """
    case "swipeRight":
        return """
            /// Swipes right on the `\(raw: propName)` element.
            @discardableResult
            @MainActor
            func swipeRight\(raw: cap)() -> Self {
                \(raw: propName).swipeRight()
                return self
            }
            """
    case "scrollToVisible":
        return """
            /// Scrolls the nearest ancestor scroll view until `\(raw: propName)` is visible.
            @discardableResult
            @MainActor
            func scrollToVisible\(raw: cap)() -> Self {
                \(raw: propName).scrollToVisible()
                return self
            }
            """

    // MARK: Text input
    case "typeText":
        return """
            /// Types `text` into the `\(raw: propName)` element.
            @discardableResult
            @MainActor
            func typeTextInto\(raw: cap)(_ text: String) -> Self {
                \(raw: propName).typeText(text)
                return self
            }
            """
    case "clearText":
        return """
            /// Clears all text from the `\(raw: propName)` element.
            @discardableResult
            @MainActor
            func clear\(raw: cap)() -> Self {
                \(raw: propName).clearText()
                return self
            }
            """

    // MARK: Assertions — all support optional timeout for waiting
    case "assertExists":
        return """
            /// Asserts that `\(raw: propName)` exists. Pass `timeout` to wait up to that many seconds before asserting.
            @discardableResult
            @MainActor
            func assert\(raw: cap)Exists(timeout: TimeInterval? = nil, file: StaticString = #filePath, line: UInt = #line) -> Self {
                if let timeout {
                    XCTAssertTrue(\(raw: propName).waitForExistence(timeout: timeout), file: file, line: line)
                } else {
                    XCTAssertTrue(\(raw: propName).exists, file: file, line: line)
                }
                return self
            }
            """
    case "assertNotExists":
        return """
            /// Asserts that `\(raw: propName)` does not exist. Pass `timeout` to wait for it to disappear first.
            @discardableResult
            @MainActor
            func assert\(raw: cap)NotExists(timeout: TimeInterval? = nil, file: StaticString = #filePath, line: UInt = #line) -> Self {
                if let timeout {
                    let pred = NSPredicate(format: "exists == false")
                    let exp = XCTNSPredicateExpectation(predicate: pred, object: \(raw: propName))
                    XCTWaiter().wait(for: [exp], timeout: timeout)
                }
                XCTAssertFalse(\(raw: propName).exists, file: file, line: line)
                return self
            }
            """
    case "assertDisappear":
        return """
            /// Waits for `\(raw: propName)` to disappear, then asserts it is gone.
            @discardableResult
            @MainActor
            func assert\(raw: cap)Disappear(timeout: TimeInterval? = nil, file: StaticString = #filePath, line: UInt = #line) -> Self {
                if let timeout {
                    let pred = NSPredicate(format: "exists == false")
                    let exp = XCTNSPredicateExpectation(predicate: pred, object: \(raw: propName))
                    XCTWaiter().wait(for: [exp], timeout: timeout)
                }
                XCTAssertFalse(\(raw: propName).exists, file: file, line: line)
                return self
            }
            """
    case "assertEnabled":
        return """
            /// Asserts that `\(raw: propName)` is enabled. Pass `timeout` to poll until the condition is met.
            @discardableResult
            @MainActor
            func assert\(raw: cap)Enabled(timeout: TimeInterval? = nil, file: StaticString = #filePath, line: UInt = #line) -> Self {
                if let timeout {
                    let pred = NSPredicate(format: "enabled == true")
                    let exp = XCTNSPredicateExpectation(predicate: pred, object: \(raw: propName))
                    XCTWaiter().wait(for: [exp], timeout: timeout)
                }
                XCTAssertTrue(\(raw: propName).isEnabled, file: file, line: line)
                return self
            }
            """
    case "assertDisabled":
        return """
            /// Asserts that `\(raw: propName)` is disabled. Pass `timeout` to poll until the condition is met.
            @discardableResult
            @MainActor
            func assert\(raw: cap)Disabled(timeout: TimeInterval? = nil, file: StaticString = #filePath, line: UInt = #line) -> Self {
                if let timeout {
                    let pred = NSPredicate(format: "enabled == false")
                    let exp = XCTNSPredicateExpectation(predicate: pred, object: \(raw: propName))
                    XCTWaiter().wait(for: [exp], timeout: timeout)
                }
                XCTAssertFalse(\(raw: propName).isEnabled, file: file, line: line)
                return self
            }
            """
    case "assertSelected":
        return """
            /// Asserts that `\(raw: propName)` is selected. Pass `timeout` to poll until the condition is met.
            @discardableResult
            @MainActor
            func assert\(raw: cap)Selected(timeout: TimeInterval? = nil, file: StaticString = #filePath, line: UInt = #line) -> Self {
                if let timeout {
                    let pred = NSPredicate(format: "selected == true")
                    let exp = XCTNSPredicateExpectation(predicate: pred, object: \(raw: propName))
                    XCTWaiter().wait(for: [exp], timeout: timeout)
                }
                XCTAssertTrue(\(raw: propName).isSelected, file: file, line: line)
                return self
            }
            """
    case "assertNotSelected":
        return """
            /// Asserts that `\(raw: propName)` is not selected. Pass `timeout` to poll until the condition is met.
            @discardableResult
            @MainActor
            func assert\(raw: cap)NotSelected(timeout: TimeInterval? = nil, file: StaticString = #filePath, line: UInt = #line) -> Self {
                if let timeout {
                    let pred = NSPredicate(format: "selected == false")
                    let exp = XCTNSPredicateExpectation(predicate: pred, object: \(raw: propName))
                    XCTWaiter().wait(for: [exp], timeout: timeout)
                }
                XCTAssertFalse(\(raw: propName).isSelected, file: file, line: line)
                return self
            }
            """
    case "assertLabel":
        return """
            /// Asserts that `\(raw: propName)`'s label equals `expected`. Pass `timeout` to wait for the label first.
            @discardableResult
            @MainActor
            func assert\(raw: cap)Label(_ expected: String, timeout: TimeInterval? = nil, file: StaticString = #filePath, line: UInt = #line) -> Self {
                if let timeout {
                    let pred = NSPredicate(format: "label == %@", expected)
                    let exp = XCTNSPredicateExpectation(predicate: pred, object: \(raw: propName))
                    XCTWaiter().wait(for: [exp], timeout: timeout)
                }
                XCTAssertEqual(\(raw: propName).label, expected, file: file, line: line)
                return self
            }
            """
    case "assertValue":
        return """
            /// Asserts that `\(raw: propName)`'s value equals `expected`. Pass `timeout` to wait for the value first.
            @discardableResult
            @MainActor
            func assert\(raw: cap)Value(_ expected: String, timeout: TimeInterval? = nil, file: StaticString = #filePath, line: UInt = #line) -> Self {
                if let timeout { _ = \(raw: propName).waitForExistence(timeout: timeout) }
                XCTAssertEqual(\(raw: propName).value as? String ?? "", expected, file: file, line: line)
                return self
            }
            """
    case "assertPlaceholder":
        return """
            /// Asserts that `\(raw: propName)`'s placeholder equals `expected`.
            @discardableResult
            @MainActor
            func assert\(raw: cap)Placeholder(_ expected: String, file: StaticString = #filePath, line: UInt = #line) -> Self {
                XCTAssertEqual(\(raw: propName).placeholderValue, expected, file: file, line: line)
                return self
            }
            """
    case "assertOn":
        return """
            /// Asserts that `\(raw: propName)` is ON (value == "1").
            @discardableResult
            @MainActor
            func assert\(raw: cap)On(timeout: TimeInterval? = nil, file: StaticString = #filePath, line: UInt = #line) -> Self {
                if let timeout { _ = \(raw: propName).waitForExistence(timeout: timeout) }
                XCTAssertEqual(\(raw: propName).value as? String, "1", file: file, line: line)
                return self
            }
            """
    case "assertOff":
        return """
            /// Asserts that `\(raw: propName)` is OFF (value == "0").
            @discardableResult
            @MainActor
            func assert\(raw: cap)Off(timeout: TimeInterval? = nil, file: StaticString = #filePath, line: UInt = #line) -> Self {
                if let timeout { _ = \(raw: propName).waitForExistence(timeout: timeout) }
                XCTAssertEqual(\(raw: propName).value as? String, "0", file: file, line: line)
                return self
            }
            """
    default:
        return nil
    }
}
// swiftlint:enable function_body_length

// MARK: - Errors

enum MacroError: Error, CustomStringConvertible {
    case invalidArguments
    case invalidElementType
    case invalidLocator

    var description: String {
        switch self {
        case .invalidArguments:   return "Macro requires at least an element type argument"
        case .invalidElementType: return "First argument must be an ElementType member (e.g. .button)"
        case .invalidLocator:     return "Locator argument could not be parsed. Use a string literal, e.g. .id(\"myId\")"
        }
    }
}
