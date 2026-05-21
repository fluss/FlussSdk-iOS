// swift-tools-version: 6.3.1
import PackageDescription                                 

let package = Package(
    name: "FlussSdk-iOS",
    platforms: [
        .iOS(.v15)
    ],                                                                                                                                                             
    products: [
        .library(                                                                                                                                                  
            name: "FlussPublicSdk",                       
            targets: ["FlussPublicSdk"]
        ),
    ],
    targets: [
        .binaryTarget(                                                                                                                                             
            name: "FlussPublicSdk",
            url: "https://github.com/fluss/FlussSdk-iOS/releases/download/v1.0.4/FlussPublicSdk.xcframework.zip",                                                  
            checksum: "a55268757d2639ac4e550496af0a2b3720636ea1b812af46e0845c02942f2dd4"                                                                                                                        
        ),
    ]                                                                                                                                                              
)  
