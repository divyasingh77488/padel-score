// swift-tools-version:5.9
import PackageDescription

let package = Package(
  name: "PadelScoreKit",
  platforms: [.watchOS(.v10), .iOS(.v17), .macOS(.v14)],
  products: [
    .library(name: "PadelScoreKit", targets: ["PadelScoreKit"])
  ],
  targets: [
    .target(name: "PadelScoreKit"),
    .testTarget(name: "PadelScoreKitTests", dependencies: ["PadelScoreKit"]),
  ]
)
