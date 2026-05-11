// swift-tools-version: 5.9
import PackageDescription

// Public binary distribution of the Fluss BLE SDK. The source lives in the
// private `fluss/NativeBleModule` repo; this package only bundles the compiled
// xcframeworks. Consumers add this package's URL to Xcode and tick the single
// `FlussPublicSdk` product — the iOSBleSdk dependency is pulled transparently.
//
// Both URLs and checksums below are rewritten by the publish workflow at
// `fluss/NativeBleModule/.github/workflows/publishIosSdk.yml`.

let package = Package(
    name: "FlussSdk-iOS",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "FlussPublicSdk",
            targets: ["FlussPublicSdk", "iOSBleSdk"]
        ),
    ],
    targets: [
        .binaryTarget(
            name: "iOSBleSdk",
            url: "https://github.com/fluss/FlussSdk-iOS/releases/download/v0.0.0/iOSBleSdk.xcframework.zip",
            checksum: "0000000000000000000000000000000000000000000000000000000000000000"
        ),
        .binaryTarget(
            name: "FlussPublicSdk",
            url: "https://github.com/fluss/FlussSdk-iOS/releases/download/v0.0.0/FlussPublicSdk.xcframework.zip",
            checksum: "0000000000000000000000000000000000000000000000000000000000000000"
        ),
    ]
)
