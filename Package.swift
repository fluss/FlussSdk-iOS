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
            url: "https://github.com/fluss/FlussSdk-iOS/releases/download/v1.0.1/FlussPublicSdk.xcframework.zip",                                                  
            checksum: "b50be6466b4047dfe66f85a0467bf96d4de010bea518325dbace27e3b5cb9794"                                                                                                                        
        ),
    ]                                                                                                                                                              
)  
