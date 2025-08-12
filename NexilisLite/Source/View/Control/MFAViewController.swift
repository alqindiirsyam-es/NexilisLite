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
import nuSDKService

// MARK: - MFA Class
class MFAViewController: UIViewController {
    static let STEP_NEEDED_FIDO = 1
    static let STEP_NEEDED_FIDO_PWD = 2
    static let STEP_NEEDED_FIDO_PWD_BIOMETRIC = 3
    
    var STEP_NEEDED = STEP_NEEDED_FIDO_PWD
    var METHOD = ""

    private let imageViewBackground = UIImageView()
    private let scrollView = UIScrollView()
    private let mainStackView = UIStackView()
    private let headerImageView1 = UIImageView()
    private let headerImageView2 = UIImageView()
    private let headerTitleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let passwordTextField = UITextField()
    private let passwordVisibilityButton = UIButton(type: .system)
    private let poweredStackView = UIStackView()
    private let poweredLabel = UILabel()
    private let poweredImageView = UIImageView()

    private var isPasswordVisible = false

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel".localized(), style: .plain, target: self, action: #selector(cancel(sender:)))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Submit".localized(), style: .plain, target: self, action: #selector(submitAction))
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tapGesture)
        setupUI()
        setupLayout()
        loadData()
        updateUIBasedOnMethod()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let attributes = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 16.0), NSAttributedString.Key.foregroundColor: UIColor.white]
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : UIColor.mainColor
        navBarAppearance.titleTextAttributes = attributes
        navigationController?.navigationBar.standardAppearance = navBarAppearance
        navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow),
                                                   name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide),
                                                   name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc private func keyboardWillShow(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        
        let keyboardHeight = keyboardFrame.height
        let bottomInset = keyboardHeight - view.safeAreaInsets.bottom
        scrollView.contentInset.bottom = bottomInset - 20
        scrollView.verticalScrollIndicatorInsets.bottom = bottomInset - 20
        
        // ✅ Scroll password field above keyboard
        let passwordFrameInScroll = scrollView.convert(passwordTextField.frame, from: passwordTextField.superview)
        scrollView.scrollRectToVisible(passwordFrameInScroll, animated: true)
    }

    @objc private func keyboardWillHide(notification: Notification) {
        scrollView.contentInset = .zero
        scrollView.verticalScrollIndicatorInsets = .zero
    }
    
    @objc func cancel(sender: Any) {
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    @objc func dismissKeyboard() {
        passwordTextField.resignFirstResponder()
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
        headerImageView1.image = UIImage(named: "pb_mfa_bjb", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)
        headerImageView1.heightAnchor.constraint(equalToConstant: 100).isActive = true
        mainStackView.addArrangedSubview(headerImageView1)

        headerImageView2.contentMode = .scaleAspectFit
        headerImageView2.image = UIImage(named: "pb_mfa_splash", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)
        headerImageView2.heightAnchor.constraint(equalToConstant: 200).isActive = true
        mainStackView.addArrangedSubview(headerImageView2)

        // Header Title Label
        headerTitleLabel.font = .boldSystemFont(ofSize: 17)
        headerTitleLabel.textAlignment = .center
        headerTitleLabel.numberOfLines = 0
        mainStackView.addArrangedSubview(headerTitleLabel)

        // Subtitle Label
        subtitleLabel.text = "Please input your password to continue"
        subtitleLabel.font = .systemFont(ofSize: 12)
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
        passwordTextField.font = .systemFont(ofSize: 15)
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
        passwordVisibilityButton.tintColor = .black
        passwordContainerView.addSubview(passwordVisibilityButton)
        
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
            imageViewBackground.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
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
        let poweredText = "Nexilis"
        if !poweredText.isEmpty {
            poweredLabel.text = "Powered by \(poweredText)"
        }
    }
    
    // MARK: - Actions
    @objc private func togglePasswordVisibility() {
        isPasswordVisible.toggle()
        passwordTextField.isSecureTextEntry = !isPasswordVisible
        let iconName = isPasswordVisible ? "eye.fill" : "eye.slash.fill"
        passwordVisibilityButton.setImage(UIImage(systemName: iconName), for: .normal)
    }

    @objc private func submitAction() {
        if !CheckConnection.isConnectedToNetwork() || API.nGetCLXConnState() == 0 {
            self.view.makeToast("Check your connection".localized(), duration: 2.0, position: .center)
            return
        }
        guard let password = passwordTextField.text, !password.trimmingCharacters(in: .whitespaces).isEmpty else {
            self.view.makeToast("Password cannot be empty.".localized(), duration: 2.0, position: .center)
            return
        }

        guard password.count >= 6 else {
            self.view.makeToast("Password must be at least 6 characters.".localized(), duration: 2.0, position: .center)
            return
        }

        submit()
    }

    private func submit() {
        guard let password = passwordTextField.text else { return }
        Nexilis.showLoader()
        
        DispatchQueue.global().async {
            do {
                // 1. Encrypt password
                let encryptedPwd = password
                
                // 2. Create message for the server
                let me = User.getMyPin() ?? ""
                let tMessage = CoreMessage_TMessageBank.getMFAValidation(data: me)
                tMessage.mBodies[CoreMessage_TMessageKey.PSWD] = encryptedPwd
                tMessage.mBodies[CoreMessage_TMessageKey.ACTVITY] = self.METHOD
                var hasKey = false
                if !KeyManagerNexilis.hasGeneratedKey() {
                    KeyManagerNexilis.generateKey()
                    KeyManagerNexilis.saveMarker()
                } else {
                    hasKey = true
                }
                guard let privateKey = KeyManagerNexilis.getPrivateKey(useBiometric: false) else {
                    KeyManagerNexilis.deleteKey()
                    KeyManagerNexilis.deleteMarker()
                    DispatchQueue.main.async {
                        Nexilis.hideLoader {
                            let errorMessage = "Failed to get Private Key"
                            let dialog = DialogErrorMFA()
                            dialog.modalTransitionStyle = .crossDissolve
                            dialog.modalPresentationStyle = .overCurrentContext
                            dialog.errorDesc = errorMessage
                            dialog.method = self.METHOD
                            dialog.isDismiss = { res in
                                if res == 0 {
                                    self.navigationController?.dismiss(animated: true, completion: {
                                        APIS.getMFACallback()?("Failed: \(errorMessage)")
                                    })
                                }
                            }
                            UIApplication.shared.visibleViewController?.present(dialog, animated: true)
                        }
                    }
                    return
                }
                if let response = Nexilis.writeAndWait(message: CoreMessage_TMessageBank.getChalanger()) {
                    if response.isOk() {
                        let data = response.getBody(key: CoreMessage_TMessageKey.DATA, default_value: "")
                        if data.isEmpty {
                            DispatchQueue.main.async {
                                KeyManagerNexilis.deleteKey()
                                KeyManagerNexilis.deleteMarker()
                                Nexilis.hideLoader {
                                    let errorMessage = "Failed to get Auth Data"
                                    let dialog = DialogErrorMFA()
                                    dialog.modalTransitionStyle = .crossDissolve
                                    dialog.modalPresentationStyle = .overCurrentContext
                                    dialog.errorDesc = errorMessage
                                    dialog.method = self.METHOD
                                    dialog.isDismiss = { res in
                                        if res == 0 {
                                            self.navigationController?.dismiss(animated: true, completion: {
                                                APIS.getMFACallback()?("Failed: \(errorMessage)")
                                            })
                                        }
                                    }
                                    UIApplication.shared.visibleViewController?.present(dialog, animated: true)
                                }
                            }
                            return
                        }
                        let df = HMACDeviceFingerprintNexilis.generate()
                        tMessage.mBodies[CoreMessage_TMessageKey.FINGERPRINT] = df
                        if hasKey {
                            var sign = ""
                            if let dataSign = "\(data)!\(df)".data(using: .utf8) {
                                if let signature = KeyManagerNexilis.sign(data: dataSign, privateKey: privateKey) {
                                    sign = signature.base64EncodedString()
                                }
                            }
                            tMessage.mBodies[CoreMessage_TMessageKey.SIGNATURE] = sign
                        } else {
                            if let publicKey = KeyManagerNexilis.getRSAX509PublicKeyBase64(privateKey: privateKey) {
                                tMessage.mBodies[CoreMessage_TMessageKey.PUBLIC_KEY] = publicKey
                            }
                        }
                        let secret = "JBSWY3DPEHPK3PXP" // Google Authenticator example
                        let otp = try TOTPGenerator.generateTOTP(base32Secret: secret, digits: 6, timeStepSeconds: 30)
                        tMessage.mBodies[CoreMessage_TMessageKey.TOTP] = otp
                        if let response = Nexilis.writeAndWait(message: tMessage) {
                            if response.isOk() {
                                if self.STEP_NEEDED == MFAViewController.STEP_NEEDED_FIDO_PWD_BIOMETRIC {
                                    self.biometricAuth()
                                } else {
                                    DispatchQueue.main.async {
                                        Nexilis.hideLoader {
                                            self.navigationController?.dismiss(animated: true, completion: {
                                                UIApplication.shared.visibleViewController?.view.makeToast("Successfully Authenticated".localized(), duration: 3)
                                                self.dismissKeyboard()
                                                APIS.getMFACallback()?("Success")
                                            })
                                        }
                                    }
                                }
                            }
                            else {
                                DispatchQueue.main.async {
                                    KeyManagerNexilis.deleteKey()
                                    KeyManagerNexilis.deleteMarker()
                                    Nexilis.hideLoader {
                                        let errorMessage = response.getBody(key: CoreMessage_TMessageKey.MESSAGE_TEXT)
                                        let dialog = DialogErrorMFA()
                                        dialog.modalTransitionStyle = .crossDissolve
                                        dialog.modalPresentationStyle = .overCurrentContext
                                        dialog.errorDesc = errorMessage
                                        dialog.method = self.METHOD
                                        dialog.isDismiss = { res in
                                            if res == 0 {
                                                self.navigationController?.dismiss(animated: true, completion: {
                                                    APIS.getMFACallback()?("Failed: \(errorMessage)")
                                                })
                                            }
                                        }
                                        UIApplication.shared.visibleViewController?.present(dialog, animated: true)
                                    }
                                }
                            }
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        KeyManagerNexilis.deleteKey()
                        KeyManagerNexilis.deleteMarker()
                        Nexilis.hideLoader {
                            let errorMessage = "Failed to get Auth Data"
                            let dialog = DialogErrorMFA()
                            dialog.modalTransitionStyle = .crossDissolve
                            dialog.modalPresentationStyle = .overCurrentContext
                            dialog.errorDesc = errorMessage
                            dialog.method = self.METHOD
                            dialog.isDismiss = { res in
                                if res == 0 {
                                    self.navigationController?.dismiss(animated: true, completion: {
                                        APIS.getMFACallback()?("Failed: \(errorMessage)")
                                    })
                                }
                            }
                            UIApplication.shared.visibleViewController?.present(dialog, animated: true)
                        }
                    }
                }
            } catch {
                
            }
        }
    }

    private func biometricAuth() {
        let semaphore = DispatchSemaphore(value: 0)
        var result = false

        Utils.authenticateWithBiometrics { success, errorMessage in
            if success {
                print("Access granted!")
                result = true
            } else {
                print("Access denied: \(errorMessage ?? "Unknown error")")
            }
            semaphore.signal()
        }

        semaphore.wait()

        if result {
            DispatchQueue.main.async {
                Nexilis.hideLoader {
                    self.navigationController?.dismiss(animated: true, completion: {
                        UIApplication.shared.visibleViewController?.view.makeToast("Successfully Authenticated".localized(), duration: 3)
                        self.dismissKeyboard()
                        APIS.getMFACallback()?("Success")
                    })
                }
            }
        } else {
            KeyManagerNexilis.deleteKey()
            KeyManagerNexilis.deleteMarker()
            DispatchQueue.main.async {
                Nexilis.hideLoader {
                    let errorMessage = "Gagal mendeteksi Biometric (Fingerprint/Face ID)"
                    let dialog = DialogErrorMFA()
                    dialog.modalTransitionStyle = .crossDissolve
                    dialog.modalPresentationStyle = .overCurrentContext
                    dialog.errorDesc = errorMessage
                    dialog.method = self.METHOD
                    dialog.isDismiss = { res in
                        if res == 0 {
                            self.navigationController?.dismiss(animated: true, completion: {
                                APIS.getMFACallback()?("Failed: \(errorMessage)")
                            })
                        }
                    }
                    UIApplication.shared.visibleViewController?.present(dialog, animated: true)
                }
            }
        }
    }
    
    private func updateUIBasedOnMethod() {
        headerTitleLabel.text = METHOD
    }
}

