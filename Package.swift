// swift-tools-version: 5.9
//
//  Package.swift
//  NexilisLite
//
//  Swift Package Manager manifest. Mirrors NexilisLite.podspec so the library
//  can be consumed either via CocoaPods or via SPM.
//
//  nuSDKService lives in its own package (../nuSDKService) because StreamShield
//  needs it too, and SwiftPM requires target names to be unique across the
//  package graph. See that package's Package.swift for the details.
//
//  NOTE: nuSDKService is shipped as a device-only (ios-arm64) binary framework.
//  Building for the iOS Simulator is therefore not supported — same limitation
//  the podspec expresses with EXCLUDED_ARCHS[sdk=iphonesimulator*] = arm64.
//

import PackageDescription

let package = Package(
    name: "NexilisLite",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "NexilisLite",
            targets: ["NexilisLite"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.10.2"),
        .package(url: "https://github.com/SDWebImage/SDWebImage.git", from: "5.20.0"),
        .package(url: "https://github.com/scalessec/Toast-Swift.git", from: "5.1.1"),
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.19"),
        .package(url: "https://github.com/LeonardoCardoso/SwiftLinkPreview.git", from: "3.4.0"),
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.2"),
        .package(url: "https://github.com/Daltron/NotificationBanner.git", from: "4.0.0"),
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "11.14.0"),
        // Provides the SQLCipher-enabled sqlite3 that FMDB is compiled against.
        .package(url: "https://github.com/sqlcipher/SQLCipher.swift.git", from: "4.11.0"),
        // Shared with StreamShield. Switch to a URL + version when publishing —
        // see README-SPM.md.
        .package(path: "../nuSDKService")
    ],
    targets: [
        // MARK: - Vendored dependencies (no upstream SPM support)

        // FMDB 2.7.12, byte-for-byte the sources CocoaPods installs for the
        // `FMDB/SQLCipher` subspec, compiled with -DSQLITE_HAS_CODEC so that
        // `setKey:` is available and linked against SQLCipher instead of the
        // system libsqlite3.
        .target(
            name: "FMDB",
            dependencies: [
                .product(name: "SQLCipher", package: "SQLCipher.swift")
            ],
            path: "SPMSupport/FMDB",
            exclude: ["LICENSE.txt"],
            publicHeadersPath: "include",
            cSettings: [
                .define("SQLITE_HAS_CODEC"),
                .define("SQLCIPHER_CRYPTO"),
                // Routes FMDB's `#import <sqlite3.h>` to SQLCipher's header
                // instead of the SDK's. See shim/sqlite3.h.
                .headerSearchPath("shim")
            ]
        ),

        // Popover 1.3.0 (corin8823/Popover) — upstream ships no Package.swift.
        .target(
            name: "Popover",
            path: "SPMSupport/Popover",
            exclude: ["LICENSE"]
        ),

        // MARK: - NexilisLite

        .target(
            name: "NexilisLite",
            dependencies: [
                .product(name: "nuSDKService", package: "nuSDKService"),
                "FMDB",
                "Popover",
                "Alamofire",
                "SDWebImage",
                "SwiftLinkPreview",
                "KeychainAccess",
                "ZIPFoundation",
                .product(name: "Toast", package: "Toast-Swift"),
                .product(name: "NotificationBannerSwift", package: "NotificationBanner"),
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk")
            ],
            path: "NexilisLite",
            exclude: [
                "Info.plist",
                "NexilisLite.h"
            ],
            sources: ["Source"],
            resources: [
                .process("Resource")
            ]
        )
    ]
)
