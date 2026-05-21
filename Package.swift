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
            checksum: "ccb315878557370fa7dec1f3290d8306150f31ce958b4863aad8044635022d11"                                                                                                                        
        ),
    ]                                                                                                                                                              
)  
