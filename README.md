# Fluss SDK

Bluetooth control for Fluss devices in a single API call. Bootstrap the SDK with your
Fluss API key — it fetches the list of devices your account is authorised to control,
and exposes a simple scan / write / trigger API on top of CoreBluetooth (iOS) and
`android.bluetooth.le` (Android).

## Features

- **One-line bootstrap** — pass your API key, get back a working SDK instance.
- **Works offline** — the verified device list is cached securely (iOS Keychain /
  Android EncryptedSharedPreferences) so the SDK keeps working without connectivity.
- **Reactive state** — Combine publishers on iOS, Kotlin Flows on Android. Discovered
  devices, connection state, inbound notifications and Bluetooth-adapter state all
  push events as they happen.
- **Automatic connection management** — the SDK scans, RSSI-sorts, connects to the
  closest authorised device, and auto-reconnects on transient failures.
- **Wi-Fi provisioning helpers** — `getWifi` and `connectToWifi` cover the common
  onboarding flow.
- **Optional telemetry** — opt in with `log: true` and scan/write/trigger events are
  reported to your Fluss dashboard.

## Platform support

| | iOS | Android |
| --- | --- | --- |
| Class | `FlussPublicSdkClient` | `FlussPublicSdk` |
| Distribution | Swift Package Manager (binary xcframework) | Maven Central |
| Minimum | iOS 15 | Android 7.0 (API 24) |
| Reactive surface | Combine | Kotlin Flow |
| Concurrency | `async`/`await` | suspend / completion callbacks |

---

## Installation

### iOS

In Xcode, **File → Add Package Dependencies…** and enter:

```
https://github.com/fluss/FlussSdk-iOS
```

Add the `FlussPublicSdk` product to your app target. Or in `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/fluss/FlussSdk-iOS", from: "1.0.1"),
],
targets: [
    .target(
        name: "YourApp",
        dependencies: [
            .product(name: "FlussPublicSdk", package: "FlussSdk-iOS"),
        ]
    ),
]
```

Add a Bluetooth usage description to your target's `Info.plist`:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>This app uses Bluetooth to communicate with your Fluss devices.</string>
```

### Android

In your module's `build.gradle.kts`:

```kotlin
dependencies {
    implementation("io.fluss:android-fluss-public-sdk:1.0.1")
}
```

(`mavenCentral()` must be in your `settings.gradle.kts` repositories.)

Declare the required permissions in `AndroidManifest.xml`:

```xml
<!-- Android 12 (API 31) and newer -->
<uses-permission android:name="android.permission.BLUETOOTH_SCAN"
    android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />

<!-- Android 11 (API 30) and older -->
<uses-permission android:name="android.permission.BLUETOOTH" android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" android:maxSdkVersion="30" />
```

You must request `BLUETOOTH_SCAN`/`BLUETOOTH_CONNECT` (API 31+) or
`ACCESS_FINE_LOCATION` (API 30 and below) at runtime before initialising the SDK.

---

## Quickstart

### iOS

```swift
import FlussPublicSdk

let sdk = try await FlussPublicSdkClient(apiKey: "YOUR_API_KEY")

sdk.discoveredDevices
    .sink { device, rssi in print("Saw \(device.getName() ?? "?") at \(rssi) dBm") }
    .store(in: &cancellables)

sdk.connectionState
    .filter { _, state in state == .connected }
    .sink { device, _ in
        Task {
            let result = await sdk.trigger(deviceName: device.getName() ?? "")
            print(result.success ? "Triggered" : "Failed: \(result.message)")
        }
    }
    .store(in: &cancellables)
```

### Android

```kotlin
import io.fluss.publicsdk.FlussPublicSdk
import io.fluss.androidBleModule.util.ConnectionState

val sdk = FlussPublicSdk.create(applicationContext, apiKey = "YOUR_API_KEY")

lifecycleScope.launch {
    launch {
        sdk.discoveredDevices.collect { (device, rssi) ->
            Log.d("Fluss", "Saw ${device.getName()} at $rssi dBm")
        }
    }
    launch {
        sdk.connectionState
            .filter { (_, state) -> state == ConnectionState.CONNECTED }
            .collect { (device, _) ->
                sdk.trigger(device.getName()) { success, message, _, _ ->
                    Log.d("Fluss", if (success) "Triggered" else "Failed: $message")
                }
            }
    }
}
```

---

## API Reference

<docgen-index>

* [`init(...)`](#init)
* [`startScanning()`](#startscanning)
* [`stopScanning()`](#stopscanning)
* [`write(...)`](#write)
* [`trigger(...)`](#trigger)
* [`getWifi(...)`](#getwifi)
* [`connectToWifi(...)`](#connecttowifi)
* [`cleanup()`](#cleanup)
* [Publishers / Flows](#publishers--flows)
* [Types](#types)
* [Errors](#errors)

</docgen-index>

<docgen-api>

#### init(...)

**iOS**

```swift
init(apiKey: String, log: Bool = false) async throws
```

**Android**

```kotlin
suspend fun FlussPublicSdk.create(
    context: Context,
    apiKey: String,
    log: Boolean = false,
): FlussPublicSdk
```

Initialise the SDK. The first call must be online — the SDK fetches a signed list of
the devices your API key is authorised to control, verifies it against an embedded
public key, and caches the verified envelope locally. Subsequent launches fall back to
the cached envelope if the network is unreachable, so the SDK keeps working offline
until the cached token expires.

Scanning starts automatically once Bluetooth is ready.

| Param | Type | Description |
| --- | --- | --- |
| **`apiKey`** | <code>String</code> | Your Fluss API key. Issued from the Fluss dashboard. |
| **`log`** | <code>Bool</code> | When `true`, scan/write/trigger events are best-effort reported to the Fluss backend. Logger failures never block BLE operations. Default `false`. |

**Throws** `FlussPublicSdkError.noConnectivityAndNoCache` (iOS) /
`FlussPublicSdkException` (Android) if the network fetch fails and no valid cached
envelope is available. See [Errors](#errors).

---

#### startScanning()

**iOS**

```swift
func startScanning() async
```

**Android**

```kotlin
fun startScanning()  // requires BLUETOOTH_SCAN permission
```

Begin scanning for authorised BLE devices. The SDK auto-connects to devices as they
come into range. A no-op if a scan is already in progress. Queued if Bluetooth is not
yet ready — runs automatically once the adapter becomes available.

Called for you by `init` / `create` — you only need to call it manually if you
previously stopped scanning.

---

#### stopScanning()

**iOS**

```swift
func stopScanning() async
```

**Android**

```kotlin
fun stopScanning()  // requires BLUETOOTH_SCAN permission
```

Stop the active scan and disconnect any currently-connected devices.

---

#### write(...)

**iOS**

```swift
func write(deviceName: String, data: String) async -> WriteResult
```

**Android**

```kotlin
fun write(
    deviceName: String,
    data: String,
    completion: (success: Boolean, message: String, keyUsed: String?, timestamp: Long?) -> Unit,
)
```

Send a raw command to a connected device. The SDK signs the payload before transmission
using the device's secret and a rolling timestamp — you pass only the command bytes.

5-second write timeout.

| Param | Type | Description |
| --- | --- | --- |
| **`deviceName`** | <code>String</code> | The device's advertised name. Must match a device authorised by your API key. |
| **`data`** | <code>String</code> | Hex-encoded command bytes, e.g. `"0101"`. |

**Returns** (or passes to completion) a [`WriteResult`](#writeresult).

---

#### trigger(...)

**iOS**

```swift
func trigger(deviceName: String) async -> WriteResult
```

**Android**

```kotlin
fun trigger(
    deviceName: String,
    completion: (success: Boolean, message: String, keyUsed: String?, timestamp: Long?) -> Unit,
)
```

Send the standard actuate command (`"0101"`). Convenience wrapper over `write`.

| Param | Type | Description |
| --- | --- | --- |
| **`deviceName`** | <code>String</code> | Target device's advertised name. |

**Returns** a [`WriteResult`](#writeresult).

---

#### getWifi(...)

**iOS**

```swift
func getWifi(deviceName: String) async -> WriteResult
```

**Android**

```kotlin
fun getWifi(
    deviceName: String,
    completion: (success: Boolean, message: String, keyUsed: String?, timestamp: Long?) -> Unit,
)
```

Ask the device to scan for nearby Wi-Fi networks. The SSID list is returned
**asynchronously** via the [`deviceNotifications`](#publishers--flows) stream — this
call only reports whether the request was dispatched.

The SDK picks the correct command (`0201` on firmware v1+, `12` on v0) automatically.

| Param | Type | Description |
| --- | --- | --- |
| **`deviceName`** | <code>String</code> | Target device's advertised name. |

**Returns** a [`WriteResult`](#writeresult).

---

#### connectToWifi(...)

**iOS**

```swift
func connectToWifi(deviceName: String, index: Int, password: String) async throws -> WriteResult
```

**Android**

```kotlin
fun connectToWifi(
    deviceName: String,
    index: Int,
    password: String,
    completion: (success: Boolean, message: String, keyUsed: String?, timestamp: Long?) -> Unit,
)
```

Instruct the device to join one of the Wi-Fi networks it previously reported via
`getWifi`. The device's join result is delivered asynchronously via
[`deviceNotifications`](#publishers--flows).

| Param | Type | Description |
| --- | --- | --- |
| **`deviceName`** | <code>String</code> | Target device's advertised name. |
| **`index`** | <code>Int</code> | Zero-based index into the SSID list returned by `getWifi`. |
| **`password`** | <code>String</code> | UTF-8 passphrase. Must encode to ≤ 255 bytes. |

**Returns** a [`WriteResult`](#writeresult).

---

#### cleanup()

**Android only**

```kotlin
fun cleanup()  // requires BLUETOOTH_SCAN permission
```

Tear the SDK down: stop scanning, drop connections, cancel internal coroutines. Call
from `Activity.onDestroy()` or wire the SDK as a `LifecycleObserver`.

iOS has no equivalent — release the `FlussPublicSdkClient` instance and ARC handles
teardown.

---

### Publishers / Flows

All event streams are properties on the SDK instance. Subscribe immediately after
`init` / `create` — events fire as they happen and are not replayed, except for
`bluetoothReady` which always replays its current value to new subscribers.

| Property | iOS type | Android type |
| --- | --- | --- |
| `bluetoothReady` | `CurrentValueSubject<Bool, Never>` | `StateFlow<Boolean>` |
| `discoveredDevices` | `PassthroughSubject<(Device, Int), Never>` | `SharedFlow<Pair<Device, Int>>` |
| `connectionState` | `PassthroughSubject<(Device, ConnectionState), Never>` | `SharedFlow<Pair<Device, ConnectionState>>` |
| `deviceNotifications` | `PassthroughSubject<(String, String), Never>` | `SharedFlow<Pair<String, String>>` |
| `bluetoothDenied` | `PassthroughSubject<Bool, Never>` | `SharedFlow<Boolean>` |

---

#### `bluetoothReady`

Emits `true` when the system Bluetooth adapter is powered on and ready, `false`
otherwise. Unlike the other streams this is a `CurrentValueSubject` / `StateFlow`, so
a new subscriber immediately receives the current adapter state without waiting for the
next change.

```swift
// iOS
sdk.bluetoothReady
    .sink { ready in print("Bluetooth adapter ready: \(ready)") }
    .store(in: &cancellables)
```

```kotlin
// Android
lifecycleScope.launch {
    sdk.bluetoothReady.collect { ready ->
        Log.d("Fluss", "Bluetooth adapter ready: $ready")
    }
}
```

---

#### `discoveredDevices`

Fires `(device, rssi)` each time an authorised device advertises. `rssi` is the signal
strength in dBm (a negative integer — closer to zero means stronger signal). The SDK
uses RSSI to auto-connect to the nearest device.

`rssi == 0` is a **sentinel value** meaning the device has stopped advertising (no
advertisement seen for ~2 seconds). Use it to remove the device from any UI list.

```swift
// iOS
sdk.discoveredDevices
    .sink { device, rssi in
        if rssi == 0 {
            // device went away
        } else {
            print("\(device.getName() ?? "unknown") at \(rssi) dBm")
        }
    }
    .store(in: &cancellables)
```

```kotlin
// Android
lifecycleScope.launch {
    sdk.discoveredDevices.collect { (device, rssi) ->
        if (rssi == 0) {
            // device went away
        } else {
            Log.d("Fluss", "${device.getName()} at $rssi dBm")
        }
    }
}
```

---

#### `connectionState`

Emits `(device, state)` each time a device transitions connection state. Possible
states are defined in [`ConnectionState`](#connectionstate). Wait for `.connected` /
`CONNECTED` before calling `write`, `trigger`, `getWifi`, or `connectToWifi`.

```swift
// iOS
sdk.connectionState
    .filter { _, state in state == .connected }
    .sink { device, _ in
        Task { await sdk.trigger(deviceName: device.getName() ?? "") }
    }
    .store(in: &cancellables)
```

```kotlin
// Android
lifecycleScope.launch {
    sdk.connectionState
        .filter { (_, state) -> state == ConnectionState.CONNECTED }
        .collect { (device, _) ->
            sdk.trigger(device.getName()) { success, message, _, _ -> }
        }
}
```

---

#### `deviceNotifications`

Emits `(deviceName, hexPayload)` when a device sends an asynchronous BLE notification.
This is the delivery channel for responses to `getWifi` (SSID list) and `connectToWifi`
(join result) — those methods only confirm the request was dispatched; the actual result
arrives here.

`hexPayload` is a lowercase hex string of the raw bytes sent by the device firmware.

```swift
// iOS
sdk.deviceNotifications
    .sink { deviceName, hexPayload in
        print("\(deviceName) notified: \(hexPayload)")
    }
    .store(in: &cancellables)
```

```kotlin
// Android
lifecycleScope.launch {
    sdk.deviceNotifications.collect { (deviceName, hexPayload) ->
        Log.d("Fluss", "$deviceName notified: $hexPayload")
    }
}
```

---

#### `bluetoothDenied`

Fires `true` when the OS reports that the user has denied Bluetooth permission.
Use this to show an in-app prompt directing the user to Settings.

```swift
// iOS
sdk.bluetoothDenied
    .filter { $0 }
    .sink { _ in showBluetoothPermissionAlert() }
    .store(in: &cancellables)
```

```kotlin
// Android
lifecycleScope.launch {
    sdk.bluetoothDenied.collect { denied ->
        if (denied) showBluetoothPermissionRationale()
    }
}
```

---

### Types

#### WriteResult

```swift
public struct WriteResult {
    public let success: Bool      // true if the bytes hit the characteristic OK
    public let message: String    // status / error text
    public let keyUsed: String?   // the userId used to authenticate the write
    public let timestamp: Int?    // unix seconds used as the auth nonce
}
```

Android delivers the same four fields via the completion callback:
`(success: Boolean, message: String, keyUsed: String?, timestamp: Long?) -> Unit`.

`keyUsed` and `timestamp` are diagnostic — useful for correlating with server-side
audit logs. Both are `null` only when the SDK couldn't build an auth payload at all
(e.g. the device disconnected before the write was attempted).

#### Device

Opaque handle to a discovered peripheral. Useful methods on both platforms:

```swift
device.getName()    // String?   — advertised name
device.getId()      // String    — stable identifier (UUID on iOS, MAC on Android)
device.getVersion() // [Int]     — [major, minor, patch], or [0,0,0] if unknown
```

#### ConnectionState

```swift
// iOS
public enum ConnectionState {
    case disconnected
    case connecting
    case connected
}
```

```kotlin
// Android (additionally emits .DISCONNECTING)
enum class ConnectionState {
    DISCONNECTED, CONNECTING, CONNECTED, DISCONNECTING
}
```

---

### Errors

#### Init-time errors

| Type | When | Recovery |
| --- | --- | --- |
| **`unauthorized`** | API key was rejected. | Surface to the user. Don't retry automatically. |
| **`transport`** / **`http`** (5xx) | Network failure or backend error. | Retry with backoff. |
| **`payloadDeviceMismatch`** / **`invalidSignature`** | Signed envelope failed verification — possible tampering. | Fail closed. Don't retry. |
| **`tokenExpired`** | Cached envelope past expiry; the user has been offline too long. | Prompt to reconnect to the internet — the next successful init refreshes the cache. |
| **`noConnectivityAndNoCache`** | Can't reach the API and no valid cache. | Retry once online. |

```swift
// iOS
do {
    let sdk = try await FlussPublicSdkClient(apiKey: "...")
} catch let error as FlussPublicSdkError {
    // .noConnectivityAndNoCache(underlying: ...)
} catch let error as ApiError {
    // .unauthorized, .http(status:, body:), .transport(...), .payloadDeviceMismatch, ...
} catch let error as VerificationError {
    // .invalidSignature, .tokenExpired(expiresAt:), ...
}
```

```kotlin
// Android
try {
    val sdk = FlussPublicSdk.create(applicationContext, apiKey = "...")
} catch (e: FlussPublicSdkException) {
    when (val cause = e.cause) {
        is ApiException.Unauthorized -> /* bad API key */
        is ApiException.Http         -> /* cause.status, cause.body */
        is ApiException.Transport    -> /* network failure */
        ApiException.PayloadDeviceMismatch -> /* tampered envelope */
        else -> /* ... */
    }
}
```

#### Runtime errors

Write / trigger / getWifi / connectToWifi never throw — they report status through
[`WriteResult`](#writeresult). Common `message` values:

| Message | Meaning |
| --- | --- |
| `"Device not found"` | No device with that name has been discovered yet. Wait for `discoveredDevices`. |
| `"Device not connected"` | Device is in range but not yet connected. Wait for `connectionState == .connected`. |
| `"Write timeout."` | The device didn't acknowledge the write within 5 seconds. |
| `"Device disconnected"` | The device dropped during the write. The SDK reconnects automatically — retry once connected. |
| `"Characteristic not found."` | The connected peripheral doesn't expose the expected service — likely a firmware mismatch. |

The SDK automatically reconnects after 5 consecutive write failures to a connected
device. You don't need to do this yourself.

</docgen-api>

---

## Support

- **Issues**: [github.com/fluss/FlussSdk-iOS/issues](https://github.com/fluss/FlussSdk-iOS/issues)
  / file an Android issue on the Maven Central listing.
- **API keys**: issued from the Fluss dashboard at [fluss.io](https://fluss.io).
- **Email**: [alistair@fluss.io](mailto:alistair@fluss.io).

## License

Proprietary. © Fluss.
