// swift-tools-version: 6.0
import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "XCUIPage",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "XCUIPage", targets: ["XCUIPage"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "602.0.0"),
    ],
    targets: [
        .macro(
            name: "XCUIPageMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            ]
        ),
        .target(
            name: "XCUIPage",
            dependencies: ["XCUIPageMacros"]
        ),
        .testTarget(
            name: "XCUIPageTests",
            dependencies: [
                "XCUIPageMacros",
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
    ]
)
