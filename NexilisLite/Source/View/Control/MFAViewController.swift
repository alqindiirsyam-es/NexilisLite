//
//  MFAViewController.swift
//  Pods
//
//  Created by Maronakins on 01/08/25.
//

import UIKit
import Foundation
import os
import LocalAuthentication

// MARK: - MFA Class
class MFAViewController: UIViewController {

    // MARK: - Constants & Variables
    private let TAG = "MFA"

    // Step definitions mirroring the Java code
    static let STEP_NEEDED_FIDO = 1
    static let STEP_NEEDED_FIDO_PWD = 2
    static let STEP_NEEDED_FIDO_PWD_FINGER = 3
    static let STEP_NEEDED_FINGER = 4
    
    // Properties to be set on initialization
    var STEP_NEEDED = STEP_NEEDED_FIDO_PWD
    var METHOD = ""
    
    private var mfaState = "open"
    private var challengeString = ""

    // MARK: - UI Components
    private let imageViewBackground = UIImageView()
    private let scrollView = UIScrollView()
    private let mainStackView = UIStackView()
    private let headerImageView1 = UIImageView()
    private let headerImageView2 = UIImageView()
    private let headerTitleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let passwordTextField = UITextField()
    private let passwordVisibilityButton = UIButton(type: .system)
    private let submitButton = UIButton(type: .system)
    private let poweredStackView = UIStackView()
    private let poweredLabel = UILabel()
    private let poweredImageView = UIImageView()

    private var isPasswordVisible = false

    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupLayout()
        loadData()
        updateUIBasedOnMethod()
        updateUIBasedOnMode()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Notify delegate if the view is closed prematurely
        if mfaState == "open" {
            Nexilis.shared.mfaDelegate?.onFailed(error: "back")
        }
    }

    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground

        // Background Image View
        imageViewBackground.contentMode = .scaleAspectFill
        imageViewBackground.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageViewBackground)

        // Scroll View
        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        // Main Stack View
        mainStackView.axis = .vertical
        mainStackView.alignment = .center
        mainStackView.spacing = 16
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(mainStackView)

        // Header Images
        headerImageView1.contentMode = .scaleAspectFit
        headerImageView1.image = UIImage(named: "pb_mfa_bjb")
        headerImageView1.heightAnchor.constraint(equalToConstant: 100).isActive = true
        mainStackView.addArrangedSubview(headerImageView1)

        headerImageView2.contentMode = .scaleAspectFit
        headerImageView2.image = UIImage(named: "pb_mfa_splash")
        headerImageView2.heightAnchor.constraint(equalToConstant: 200).isActive = true
        mainStackView.addArrangedSubview(headerImageView2)

        // Header Title Label
        headerTitleLabel.font = UIFont(name: "Poppins-Bold", size: 17)
        headerTitleLabel.textAlignment = .center
        headerTitleLabel.numberOfLines = 0
        mainStackView.addArrangedSubview(headerTitleLabel)

        // Subtitle Label
        subtitleLabel.text = "Please input your password to continue"
        subtitleLabel.font = UIFont(name: "Poppins-Regular", size: 12)
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        mainStackView.addArrangedSubview(subtitleLabel)
        
        // Password Input Container
        let passwordContainerView = UIView()
        passwordContainerView.translatesAutoresizingMaskIntoConstraints = false
        passwordContainerView.widthAnchor.constraint(equalToConstant: 300).isActive = true
        passwordContainerView.heightAnchor.constraint(equalToConstant: 48).isActive = true
        mainStackView.addArrangedSubview(passwordContainerView)
        
        // Password Text Field
        passwordTextField.placeholder = "Type your password..."
        passwordTextField.isSecureTextEntry = true
        passwordTextField.font = UIFont(name: "Poppins-Regular", size: 15)
        passwordTextField.borderStyle = .roundedRect
        passwordTextField.keyboardType = .default
        passwordTextField.autocapitalizationType = .none
        passwordTextField.autocorrectionType = .no
        passwordTextField.translatesAutoresizingMaskIntoConstraints = false
        passwordContainerView.addSubview(passwordTextField)
        
        // Password Visibility Button
        passwordVisibilityButton.setImage(UIImage(systemName: "eye.slash.fill"), for: .normal)
        passwordVisibilityButton.addTarget(self, action: #selector(togglePasswordVisibility), for: .touchUpInside)
        passwordVisibilityButton.translatesAutoresizingMaskIntoConstraints = false
        passwordContainerView.addSubview(passwordVisibilityButton)
        
        // Submit Button
        submitButton.setTitle("SUBMIT", for: .normal)
        submitButton.backgroundColor = UIColor(hex: "#14507f")
        submitButton.setTitleColor(.white, for: .normal)
        submitButton.layer.cornerRadius = 24
        submitButton.titleLabel?.font = UIFont(name: "Poppins-Regular", size: 16)
        submitButton.addTarget(self, action: #selector(submitAction), for: .touchUpInside)
        submitButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
        submitButton.widthAnchor.constraint(equalToConstant: 300).isActive = true
        mainStackView.addArrangedSubview(submitButton)
        
        mainStackView.setCustomSpacing(12, after: subtitleLabel)
        mainStackView.setCustomSpacing(24, after: passwordContainerView)

        // Powered By StackView
        poweredStackView.axis = .horizontal
        poweredStackView.alignment = .center
        poweredStackView.spacing = 8
        poweredStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(poweredStackView)

        poweredLabel.text = "Powered by"
        poweredLabel.font = .systemFont(ofSize: 12)
        poweredStackView.addArrangedSubview(poweredLabel)

        poweredImageView.contentMode = .scaleAspectFit
        poweredImageView.image = UIImage(named: "pb_powered_button")
        poweredImageView.widthAnchor.constraint(equalToConstant: 25).isActive = true
        poweredImageView.heightAnchor.constraint(equalToConstant: 25).isActive = true
        poweredStackView.addArrangedSubview(poweredImageView)
    }

    private func setupLayout() {
        NSLayoutConstraint.activate([
            // Background
            imageViewBackground.topAnchor.constraint(equalTo: view.topAnchor),
            imageViewBackground.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageViewBackground.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageViewBackground.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Scroll View
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            scrollView.bottomAnchor.constraint(equalTo: poweredStackView.topAnchor, constant: -8),

            // Main Stack View
            mainStackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            mainStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            mainStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            mainStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            mainStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Password Field
            passwordTextField.leadingAnchor.constraint(equalTo: passwordTextField.superview!.leadingAnchor),
            passwordTextField.trailingAnchor.constraint(equalTo: passwordTextField.superview!.trailingAnchor),
            passwordTextField.topAnchor.constraint(equalTo: passwordTextField.superview!.topAnchor),
            passwordTextField.bottomAnchor.constraint(equalTo: passwordTextField.superview!.bottomAnchor),
            
            // Password Visibility Button
            passwordVisibilityButton.trailingAnchor.constraint(equalTo: passwordTextField.trailingAnchor, constant: -8),
            passwordVisibilityButton.centerYAnchor.constraint(equalTo: passwordTextField.centerYAnchor),
            passwordVisibilityButton.widthAnchor.constraint(equalToConstant: 40),
            passwordVisibilityButton.heightAnchor.constraint(equalToConstant: 40),

            // Powered by
            poweredStackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            poweredStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
        ])
    }
    
    // MARK: - Data & Logic
    private func loadData() {
        // Fetch and apply "Powered By" text from shared configuration
        let poweredText = "Nexilis"
        if !poweredText.isEmpty {
            poweredLabel.text = "Powered by \(poweredText)"
        }
        
        setBackground()
    }
    
    private func randomizeBackground(from list: String) {
        
    }

    private func setBackground() {

    }
    
    // MARK: - Actions
    @objc private func togglePasswordVisibility() {
        isPasswordVisible.toggle()
        passwordTextField.isSecureTextEntry = !isPasswordVisible
        let iconName = isPasswordVisible ? "eye.fill" : "eye.slash.fill"
        passwordVisibilityButton.setImage(UIImage(systemName: iconName), for: .normal)
    }

    @objc private func submitAction() {
        // Check for network connectivity
//        if Nexilis.shared.getNetworkState() != 1 {
//            self.showToast(message: "Connection failed. Please check your network.")
//            return
//        }
//        
        guard let password = passwordTextField.text, !password.trimmingCharacters(in: .whitespaces).isEmpty else {
            self.showToast(message: "Password cannot be empty.")
            return
        }

        guard password.count >= 6 else {
            self.showToast(message: "Password must be at least 6 characters.")
            return
        }

        if STEP_NEEDED == MFAViewController.STEP_NEEDED_FIDO_PWD_FINGER {
            biometricAuth()
        } else {
            submit()
        }
    }

    private func submit() {
        guard let password = passwordTextField.text else { return }
        self.showToast(message: "Please wait...", duration: 2.0)
        
        DispatchQueue.global().async {
            // 1. Encrypt password
            let encryptedPwd = password
            
            // 2. Create message for the server
            var tMessage = TMessage()
            tMessage.mBodies[CoreMessage_TMessageKey.PSWD] = encryptedPwd
            tMessage.mBodies[CoreMessage_TMessageKey.ACTVITY] =  self.METHOD
            
            // 3. Add FIDO and TOTP data to the message
            self.getFIDO(tMessage: &tMessage)
            do {
                let totp = try TOTPGenerator.generate(base32Secret: "JBSWY3DPEHPK3PXP", digits: 6, timeStepSeconds: 30)
                tMessage.mBodies[CoreMessage_TMessageKey.TOTP] = totp
            } catch {
                os_log("Failed to generate TOTP: %{public}@", log: .default, type: .error, error.localizedDescription)
            }

            // 4. Send the message and wait for a response
            if let response = Nexilis.writeAndWait(message: tMessage) {
                DispatchQueue.main.async {
//                    guard let response = response else {
//                        self.showToast(message: "Connection failed.")
//                        Nexilis.shared.mfaDelegate?.onFailed(error: "Connection failed.")
//                        self.dismiss(animated: true)
//                        return
//                    }
                    
                    if response.isOk() {
                        self.mfaState = "success"
                        self.showToast(message: "Success!")
                        Nexilis.shared.mfaDelegate?.onSuccess()
                        self.dismiss(animated: true)
                    } else {
                        self.mfaState = "failed"
                        let errorMessage = response.mBodies[CoreMessage_TMessageKey.MESSAGE_TEXT] ?? "An unknown error occurred."
                        self.showToast(message: errorMessage)
                        Nexilis.shared.mfaDelegate?.onFailed(error: errorMessage)
                        self.dismiss(animated: true)
                    }
                }
            }
        }
    }
    
    private func getFIDO(tMessage: inout TMessage) {
//        do {
//            let fingerprint = try HMACDeviceFingerprint.generate()
//            tMessage.putBody(key: CoreMessage_TMessageKey.FINGERPRINT, value: fingerprint)
//            
//            if KeyManagerNexilis.hasGeneratedKey() {
//                // If key exists, sign the challenge and fingerprint
//                let signature = try KeyManagerNexilis.sign(data: self.challengeString + "!" + fingerprint)
//                tMessage.putBody(key: CoreMessage_TMessageKey.SIGNATURE, value: signature)
//            } else {
//                // Otherwise, generate a new key and send the public part
//                try KeyManagerNexilis.generateKey()
//                let publicKey = try KeyManagerNexilis.getPublicKeyEncoded()
//                tMessage.putBody(key: CoreMessage_TMessageKey.PUBLIC_KEY, value: publicKey)
//            }
//        } catch {
//            os_log("FIDO operation failed: %{public}@", log: .default, type: .error, error.localizedDescription)
//        }
    }

    private func biometricAuth() {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Confirm your identity to proceed"
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] success, authenticationError in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    if success {
                        os_log("Biometric authentication succeeded.", log: .default, type: .info)
                        self.showToast(message: "Please wait...", duration: 2.0)
                        if KeyManagerNexilis.hasGeneratedKey() {
                            self.requestAuth() // FIDO flow
                        } else {
                            self.submit() // Standard password submission
                        }
                    } else {
                        os_log("Biometric authentication failed.", log: .default, type: .error)
                        let errorMessage = authenticationError?.localizedDescription ?? "Authentication failed."
                        self.showToast(message: errorMessage)
                    }
                }
            }
        } else {
            os_log("Biometrics not available. Falling back to standard submission.", log: .default, type: .info)
            // If biometrics are not available on the device, proceed with the standard submission.
            self.submit()
        }
    }
    
    private func requestAuth() {
        DispatchQueue.global().async {
            // Request a challenge from the server
            var appname = APIS.getAppNm()
            if let response = Nexilis.writeAndWait(message: CoreMessage_TMessageBank.getAuthRequest(data: appname)) {
                
                if !response.isOk()  {
                    self.showToast(message: "Action failed: Could not get challenge.")
                    return
                }
                
                // On success, store the challenge and then proceed with the final submission
                self.challengeString = response.getBody(key: CoreMessage_TMessageKey.DATA) ?? ""
                self.submit()
            }
        }
    }

    // MARK: - UI Updates
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateUIBasedOnMode()
            setBackground()
        }
    }
    
    private func updateUIBasedOnMode() {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        let textColor: UIColor = isDarkMode ? .white : .black
        let placeholderColor: UIColor = .gray
        
        passwordTextField.textColor = textColor
        passwordTextField.attributedPlaceholder = NSAttributedString(
            string: "Type your password...",
            attributes: [.foregroundColor: placeholderColor]
        )
        passwordVisibilityButton.tintColor = textColor
        headerTitleLabel.textColor = textColor
        subtitleLabel.textColor = isDarkMode ? .lightGray : .darkGray
        poweredLabel.textColor = isDarkMode ? .lightGray : .darkGray
        submitButton.backgroundColor = isDarkMode ? UIColor(hex: "#2E77AE") : UIColor(hex: "#14507f")
    }
    
    private func updateUIBasedOnMethod() {
        if METHOD.contains("Sign Up") {
            headerTitleLabel.text = "Register"
        } else {
            headerTitleLabel.text = "Authenticate Your Account"
        }
    }
}

// MARK: - Helper Extensions & Mocks

// Helper for Hex Color
extension UIColor {
    convenience init(hex: String) {
        var cString: String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if cString.hasPrefix("#") { cString.removeFirst() }
        guard cString.count == 6 else { self.init(white: 0.6, alpha: 1.0); return }
        
        var rgbValue: UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)
        
        self.init(red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
                  green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
                  blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
                  alpha: 1.0)
    }
}

// Helper to show Android-style Toast messages
extension UIViewController {
    func showToast(message: String, duration: Double = 3.0) {
        let toastLabel = UILabel()
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        toastLabel.textColor = .white
        toastLabel.font = .systemFont(ofSize: 14.0)
        toastLabel.textAlignment = .center
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10
        toastLabel.clipsToBounds = true
        
        self.view.addSubview(toastLabel)
        
        toastLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            toastLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            toastLabel.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -50),
            toastLabel.widthAnchor.constraint(lessThanOrEqualTo: self.view.widthAnchor, constant: -40),
            toastLabel.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        UIView.animate(withDuration: 0.5, delay: duration, options: .curveEaseOut, animations: {
            toastLabel.alpha = 0.0
        }, completion: { _ in
            toastLabel.removeFromSuperview()
        })
    }
}

// Delegate protocol for callbacks
public protocol MFADelegate: AnyObject {
    func onSuccess()
    func onFailed(error: String)
}

