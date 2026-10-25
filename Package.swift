// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PomodoroPal",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "PomodoroPal", targets: ["PomodoroPal"])],
    targets: [.executableTarget(name: "PomodoroPal", path: "Sources/PomodoroPal")],
    swiftLanguageModes: [.v5]
)
