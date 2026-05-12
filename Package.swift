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
            url: "https://github.com/fluss/FlussSdk-iOS/releases/download/v1.0.0/FlussPublicSdk.xcframework.zip",                                                  
            checksum: "7f3ffa4c3c539be55d5efbb6bb86c6cbe95b05787cf666fc4d15fbbcd1dd0770"                                                                                                                        
        ),
    ]                                                                                                                                                              
)  
