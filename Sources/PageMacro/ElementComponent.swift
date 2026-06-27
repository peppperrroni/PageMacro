#if canImport(XCTest)
import XCTest

@MainActor
public protocol ElementComponent {
    var app: XCUIApplication { get }
    var _scope: XCUIElement { get }
    init(app: XCUIApplication, scope: XCUIElement)
}

extension ElementComponent {
    public var element: XCUIElement { _scope }
    public var exists: Bool { _scope.exists }

    @discardableResult
    public func tap() -> Self {
        _scope.tap()
        return self
    }

    @discardableResult
    public func assertExists(timeout: TimeInterval? = nil, file: StaticString = #filePath, line: UInt = #line) -> Self {
        if let timeout {
            XCTAssertTrue(_scope.waitForExistence(timeout: timeout), "Element not found", file: file, line: line)
        } else {
            XCTAssertTrue(_scope.exists, "Element not found", file: file, line: line)
        }
        return self
    }

    @discardableResult
    public func assertNotExists(file: StaticString = #filePath, line: UInt = #line) -> Self {
        XCTAssertFalse(_scope.exists, "Element should not exist", file: file, line: line)
        return self
    }
}
#endif
