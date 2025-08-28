//
//  CloneCheck.swift
//  Pods
//
//  Created by Maronakins on 25/08/25.
//

import UIKit
import Darwin

final class CloneCheck {
    
    // MARK: - Expected values (replace with your own)
    private static let expectedBundleId = "com.yourcompany.yourapp"
    private static let expectedTeamId   = "ABCDE12345" // <-- Your real Apple Team ID
    
    // MARK: - Public
    
    /// Run this at startup, e.g. in AppDelegate didFinishLaunching
    static func enforceAllChecks(window: inout UIWindow?) {
        if isJailbroken() {
            showBlockAlertAndExit(window: &window)
        } else {
            if !isValidOrigin() {
                showWarningAlert(window: &window,
                                 message: "This app build may not be official. Please use the version from the App Store.")
            } else if !isFromAppStore() {
                showWarningAlert(window: &window,
                                 message: "This app was not installed from the App Store. For security, we recommend using the official App Store version.")
            }
        }
    }
    
    // MARK: - Jailbreak detection
    
    private static func isJailbroken() -> Bool {
        return hasSuspiciousFiles() ||
               canWriteOutsideSandbox()
    }
    
    private static func hasSuspiciousFiles() -> Bool {
        let suspiciousPaths = [
            "/Applications/Cydia.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt"
        ]
        
        for path in suspiciousPaths {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }
        return false
    }
    
    private static func canWriteOutsideSandbox() -> Bool {
        let testPath = "/private/jb_test.txt"
        do {
            try "test".write(toFile: testPath, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(atPath: testPath)
            return true
        } catch {
            return false
        }
    }
    
    // MARK: - Build origin checks
    
    private static func isValidOrigin() -> Bool {
        return isBundleIdValid() && isTeamIdValid()
    }
    
    private static func isBundleIdValid() -> Bool {
        let bundleId = Bundle.main.bundleIdentifier ?? ""
        return bundleId == expectedBundleId
    }
    
    private static func isTeamIdValid() -> Bool {
        guard let dict = Bundle.main.infoDictionary,
              let teamId = dict["com.apple.developer.team-identifier"] as? String else {
            return false
        }
        return teamId == expectedTeamId
    }
    
    // MARK: - App Store check
    
    private static func isFromAppStore() -> Bool {
        // App Store builds don’t have a provisioning profile
        if Bundle.main.path(forResource: "embedded", ofType: "mobileprovision") != nil {
            return false
        }
        
        // App Store builds have "Store" receipt
        if let appStoreReceiptURL = Bundle.main.appStoreReceiptURL?.lastPathComponent {
            return appStoreReceiptURL == "receipt"
        }
        
        return false
    }
    
    // MARK: - Alerts
    
    private static func showBlockAlertAndExit(window: inout UIWindow?) {
        let alert = UIAlertController(
            title: "Security Warning",
            message: "This app cannot run on jailbroken devices.",
            preferredStyle: .alert
        )
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = UIViewController()
        window?.makeKeyAndVisible()
        
        window?.rootViewController?.present(alert, animated: true) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                exit(0)
            }
        }
    }
    
    private static func showWarningAlert(window: inout UIWindow?, message: String) {
        let alert = UIAlertController(
            title: "Notice",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = UIViewController()
        window?.makeKeyAndVisible()
        
        window?.rootViewController?.present(alert, animated: true)
    }
}
