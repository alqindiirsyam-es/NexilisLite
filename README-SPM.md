# NexilisLite — Swift Package Manager

NexilisLite ships through **both** CocoaPods (`NexilisLite.podspec`) and SwiftPM
(`Package.swift`). The two build the exact same sources — `NexilisLite/Source`
for code and `NexilisLite/Resource` for resources — so there is one codebase to
maintain, not two.

---

## Consuming the package

### From a local checkout

```swift
.package(path: "../NexilisLibraryiOS/NexilisLite")
```

In Xcode: **File → Add Package Dependencies… → Add Local…** and pick the
`NexilisLite` folder (the one containing `Package.swift`).

### From a git URL

SwiftPM requires `Package.swift` to sit at the **root of a repository**, and here
it lives in a subfolder of `NexilisLibraryiOS`. To publish over a URL, push the
`NexilisLite` folder to a repository of its own (see *Publishing* below), then:

```swift
.package(url: "https://<your-host>/NexilisLite.git", from: "5.0.22")
```

### Target dependency

```swift
.target(name: "YourApp", dependencies: [
    .product(name: "NexilisLite", package: "NexilisLite")
])
```

---

## ⚠️ Device-only — the Simulator is not supported

`nuSDKService` is distributed as an **arm64 device-only** binary. There is no
simulator slice, so anything depending on NexilisLite builds and runs on real
hardware only:

```
-destination 'generic/platform=iOS'      # ✅
-destination 'platform=iOS Simulator,…'  # ❌ no such slice
```

This is not an SPM limitation — the podspec expresses the same thing with
`EXCLUDED_ARCHS[sdk=iphonesimulator*] = arm64`. It goes away the day
nuSDKService ships a simulator slice; regenerate the xcframework and it will be
picked up automatically.

---

## Layout

```
NexilisLite/
├── Package.swift                       SPM manifest
├── NexilisLite.podspec                 CocoaPods spec (unchanged)
├── NexilisLite/
│   ├── Source/                         library sources  — shared by both
│   └── Resource/                       images, sounds, fonts, .lproj, storyboard
├── Frameworks/
│   └── nuSDKService.xcframework        binary target (generated, committed)
├── SPMSupport/                         deps with no upstream SPM support
│   ├── FMDB/                           FMDB 2.7.12 + SQLCipher shim
│   └── Popover/                        Popover 1.3.0
└── Scripts/
    └── make-nusdkservice-xcframework.sh
```

### Why `Frameworks/` and `SPMSupport/` exist

| Pod | SPM status | What we do |
|---|---|---|
| `nuSDKService` | ships a bare `.framework` | SPM binary targets only accept `.xcframework`, so we repackage it — see the script below |
| `FMDB/SQLCipher` | no released SPM support | vendored (MIT), compiled with `-DSQLITE_HAS_CODEC` against [`sqlcipher/SQLCipher.swift`](https://github.com/sqlcipher/SQLCipher.swift) |
| `Popover` | upstream has no `Package.swift` | vendored (MIT), unmodified |

Everything else resolves normally from GitHub: Alamofire, SDWebImage,
Toast-Swift, ZIPFoundation, SwiftLinkPreview, KeychainAccess,
NotificationBanner, firebase-ios-sdk.

#### The FMDB SQLCipher shim

SQLCipher is an XCFramework, so its header is `<SQLCipher/sqlite3.h>` — but
FMDB's `.m` files import the unqualified `<sqlite3.h>`, which would resolve to
the SDK's stock sqlite3, the one **without** `sqlite3_key`/`sqlite3_rekey`.
`SPMSupport/FMDB/shim/sqlite3.h` sits on the FMDB target's header search path
and forwards the unqualified import to SQLCipher. That keeps the vendored FMDB
sources byte-for-byte identical to what CocoaPods installs, so encrypted
databases behave the same under either build system.

---

## Maintenance

### Bumping nuSDKService

```bash
Scripts/make-nusdkservice-xcframework.sh 5.0.3
```

Downloads the release zip, repackages it as an xcframework, and writes
`Frameworks/nuSDKService.xcframework`. Commit the result and bump the version in
both `NexilisLite.podspec` and the `Podfile`. (The script falls back to the local
CocoaPods cache if the download endpoint is unreachable.)

### Bumping any other dependency

Change it in **both** `NexilisLite.podspec` and `Package.swift` — they are
independent manifests and nothing cross-checks them.

### Keeping both build systems green

The source is shared, so a change that compiles under one can still break the
other. Two differences to watch for:

* **Module names.** `pod 'Toast-Swift'` builds a module called `Toast_Swift`;
  the SPM product is `Toast`. `Source/APIS.swift` and
  `Source/View/Control/ContactChatViewController.swift` bridge this with
  `#if SWIFT_PACKAGE`.
* **Transitive imports.** CocoaPods frameworks leak `UIKit` into files that
  never imported it; SPM does not. If you hit *"cannot find 'UIApplication' in
  scope"*, add the missing `import UIKit` — it is correct under both.

Resource lookup is already handled: `Bundle.resourceBundle(for:)` in
`Source/Extension.swift` returns `Bundle.module` under SwiftPM and the
`NexilisLite.bundle` resource bundle under CocoaPods. Call sites need no changes.

---

## Publishing to a standalone repository

```bash
cd /path/to/NexilisLibraryiOS

# One-time: split the NexilisLite folder into its own history
git subtree split --prefix=NexilisLite -b spm-nexilislite

git push https://<your-host>/NexilisLite.git spm-nexilislite:main

# Tag the version. SwiftPM accepts either "5.0.22" or "v5.0.22" — pick one
# convention and stick to it.
git clone https://<your-host>/NexilisLite.git /tmp/NexilisLite
cd /tmp/NexilisLite && git tag 5.0.22 && git push origin 5.0.22
```

Keep the tag in step with `spec.version` in the podspec so CocoaPods and SPM
consumers get the same code for a given version number.

To publish updates later, re-run `git subtree split` and push again.

---

## Verifying a change

```bash
# SPM (from a scratch consumer package that depends on this one)
xcodebuild -scheme <consumer> -destination 'generic/platform=iOS' build

# CocoaPods
pod install
xcodebuild -workspace NexilisLite.xcworkspace -scheme NexilisLite \
           -destination 'generic/platform=iOS' build
```

Note that `xcodebuild` inside this folder picks up `NexilisLite.xcodeproj`, not
`Package.swift`. To build the package itself, add it to a scratch consumer
package (a folder containing only a `Package.swift` that depends on this one)
and build that.
