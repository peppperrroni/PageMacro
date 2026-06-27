import XCTest
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
@testable import PageMacroMacros

private let testMacros: [String: any Macro.Type] = [
    "ElementList": ElementListMacro.self,
]

final class ElementListMacroTests: XCTestCase {

    // MARK: - Element type only (no container)

    func testElementListButtonsNoContainer() {
        assertMacroExpansion(
            """
            @ElementList(.button, row: SoundRow.self)
            var sounds: ElementList<SoundRow>
            """,
            expandedSource: """
            var sounds: ElementList<SoundRow> {
                get {
                    ElementList<SoundRow>(app: app, query: _scope.buttons)
                }
            }
            """,
            macros: testMacros
        )
    }

    func testElementListCellsNoContainer() {
        assertMacroExpansion(
            """
            @ElementList(.cell, row: PropertyCell.self)
            var properties: ElementList<PropertyCell>
            """,
            expandedSource: """
            var properties: ElementList<PropertyCell> {
                get {
                    ElementList<PropertyCell>(app: app, query: _scope.cells)
                }
            }
            """,
            macros: testMacros
        )
    }

    // MARK: - With container

    func testElementListWithCollectionView() {
        assertMacroExpansion(
            """
            @ElementList(.cell, .collectionView(id: "property_results"), row: PropertyCell.self)
            var properties: ElementList<PropertyCell>
            """,
            expandedSource: """
            var properties: ElementList<PropertyCell> {
                get {
                    ElementList<PropertyCell>(app: app, query: _scope.collectionViews.matching(identifier: "property_results").firstMatch.cells)
                }
            }
            """,
            macros: testMacros
        )
    }

    func testElementListWithTable() {
        assertMacroExpansion(
            """
            @ElementList(.cell, .table(id: "results_table"), row: ResultRow.self)
            var results: ElementList<ResultRow>
            """,
            expandedSource: """
            var results: ElementList<ResultRow> {
                get {
                    ElementList<ResultRow>(app: app, query: _scope.tables.matching(identifier: "results_table").firstMatch.cells)
                }
            }
            """,
            macros: testMacros
        )
    }

    // MARK: - With container using label

    func testElementListWithContainerLabel() {
        assertMacroExpansion(
            """
            @ElementList(.cell, .table(label: "Results"), row: ResultRow.self)
            var results: ElementList<ResultRow>
            """,
            expandedSource: """
            var results: ElementList<ResultRow> {
                get {
                    ElementList<ResultRow>(app: app, query: _scope.tables.matching(NSPredicate(format: "label == %@", "Results")).firstMatch.cells)
                }
            }
            """,
            macros: testMacros
        )
    }

    // MARK: - With container using index

    func testElementListWithContainerIndex() {
        assertMacroExpansion(
            """
            @ElementList(.cell, .collectionView(index: 0), row: ItemCell.self)
            var items: ElementList<ItemCell>
            """,
            expandedSource: """
            var items: ElementList<ItemCell> {
                get {
                    ElementList<ItemCell>(app: app, query: _scope.collectionViews.element(boundBy: 0).cells)
                }
            }
            """,
            macros: testMacros
        )
    }

    // MARK: - Bare container (no locator)

    func testElementListWithBareContainer() {
        assertMacroExpansion(
            """
            @ElementList(.cell, .table, row: RowCell.self)
            var rows: ElementList<RowCell>
            """,
            expandedSource: """
            var rows: ElementList<RowCell> {
                get {
                    ElementList<RowCell>(app: app, query: _scope.tables.firstMatch.cells)
                }
            }
            """,
            macros: testMacros
        )
    }

    // MARK: - Buttons inside a table

    func testElementListButtonsInTable() {
        assertMacroExpansion(
            """
            @ElementList(.button, .table(id: "actions"), row: ActionRow.self)
            var actions: ElementList<ActionRow>
            """,
            expandedSource: """
            var actions: ElementList<ActionRow> {
                get {
                    ElementList<ActionRow>(app: app, query: _scope.tables.matching(identifier: "actions").firstMatch.buttons)
                }
            }
            """,
            macros: testMacros
        )
    }
}
