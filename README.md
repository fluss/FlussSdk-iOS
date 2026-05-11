# FlussSdk for iOS

Public Swift Package distribution of the Fluss BLE SDK. Drop this in to
scan and operate Fluss devices from any iOS app.

## Install

In Xcode: **File → Add Package Dependencies…** and paste:

```
https://github.com/fluss/FlussSdk-iOS
```

Tick the **FlussPublicSdk** product.

In a `Package.swift`:

```swift
.package(url: "https://github.com/fluss/FlussSdk-iOS", from: "1.0.0"),
```

```swift
.product(name: "FlussPublicSdk", package: "FlussSdk-iOS"),
```

## Usage

```swift
import FlussPublicSdk

let sdk = try await FlussPublicSdkClient(
    apiKey: "YOUR_FLUSS_API_KEY",
    log: false                    // set true to opt-in to telemetry
)

sdk.discoveredDevices.sink { (device, rssi) in
    print("found \(device.deviceId) at \(rssi) dBm")
}

let result = await sdk.trigger(deviceName: "Front Gate")
print(result.success, result.message)
```

The first init must run online so the SDK can fetch and verify the signed
device list. After that it falls back to a keychain-cached envelope while
the token is still valid (default 30 days), so the SDK keeps working when
the user goes offline.

Get an API key at <https://fluss.io>.
