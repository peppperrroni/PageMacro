#if canImport(XCTest)
import XCTest

@MainActor
public struct ElementList<Row: ElementComponent>: Sendable {
    private let app: XCUIApplication
    private let query: XCUIElementQuery

    nonisolated public init(app: XCUIApplication, query: XCUIElementQuery) {
        self.app = app
        self.query = query
    }

    public var count: Int { query.count }

    public subscript(_ index: Int) -> Row {
        Row(app: app, scope: query.element(boundBy: index))
    }

    public subscript(id id: String) -> Row {
        Row(app: app, scope: query.matching(identifier: id).firstMatch)
    }

    public func matching(identifier id: String) -> Row {
        Row(app: app, scope: query.matching(identifier: id).firstMatch)
    }

    public func matching(_ predicate: NSPredicate) -> Row {
        Row(app: app, scope: query.matching(predicate).firstMatch)
    }

    public func containing(_ text: String) -> Row {
        let predicate = NSPredicate(format: "label CONTAINS %@", text)
        return Row(app: app, scope: query.containing(predicate).firstMatch)
    }
}
#endif
