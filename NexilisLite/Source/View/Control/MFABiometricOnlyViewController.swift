//
//  MFABiometricOnlyViewController.swift
//  Pods
//
//  Created by Maronakins on 01/08/25.
//

import UIKit
import LocalAuthentication

class MFAOnlyBiometricViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .clear // Equivalent to setBackgroundColor(Color.TRANSPARENT)
        dummyNextStep()
    }

    private func dummyNextStep() {
        // This is where you would call the biometric authentication
        biometricAuth(onSuccess: {
            Nexilis.shared.authDelegate?.onAuthenticationSucceeded()
            self.dismiss(animated: true, completion: nil) // Equivalent to finish()
        }, onFailed: { error in
            Nexilis.shared.authDelegate?.onAuthenticationFailed(error: error)
            // Handle the error here, e.g., show a dialog
        })
    }
    
    private func biometricAuth(onSuccess: @escaping () -> Void, onFailed: @escaping (Error?) -> Void) {
        let context = LAContext()
        var error: NSError?

        // 1. Check if the device can evaluate the biometric policy.
        // This is equivalent to BiometricManager.canAuthenticate in Java.
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Confirm your identity" // This is the title of the prompt

            // 2. Present the biometric authentication prompt.
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        // Biometric authentication succeeded.
                        onSuccess()
                    } else {
                        // Biometric authentication failed or was cancelled.
                        onFailed(authenticationError)
                    }
                }
            }
        } else {
            // Biometrics are not available or an error occurred.
            // This handles cases like a user not having Touch ID/Face ID enabled.
            onFailed(error)
        }
    }
}

// Protocol to handle the authentication result
public protocol AuthenticationDelegate: AnyObject {
    func onAuthenticationSucceeded()
    func onAuthenticationFailed(error: Error?)
}
