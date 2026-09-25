//
//  LiteBootstrapForms.swift
//  NexilisLite
//
//  The two pre-asset forms (Android: BootstrapLoginActivity / BootstrapTfaActivity), drawn like
//  NexilisLite's own screens:
//
//    Login  ->  SignUpSignIn (Palio.storyboard): pb_user, divider, grey prompt, rounded fields with
//               the eye toggle, italic disclaimer, "Sign-Up/Sign-In" bar with Submit; the OTP step is
//               Lite's own VerifyEmail sheet.
//    TFA    ->  TFAPasswordVC: badge, splash (or the configured TFA logo), bold method title, prompt,
//               300x48 password field with the eye toggle, "Powered by Nexilis".
//
//  Only the look is Lite's. No database, no nuSDK, nothing that needs the session or the protected
//  asset - the shared transport, device proof and assertion checks are in the base class.
//

import Foundation
import UIKit
import LocalAuthentication
import CryptoKit
@_implementationOnly import NotificationBannerSwift
import NexilisZTA

class LiteBootstrapFormViewController: UIViewController {

    var onFinish: ((Result<String, Error>) -> Void)?
    let identity: LiteBootstrapIdentity
    let bindingID: String
    let client: LiteBootstrapHTTPSClient
    /// One attempt = all its stages: fixed for the form, and handed from the first login to the TFA that
    /// completes it. The backend keys the attempt, its idempotency and its account on it.
    let attemptID: String
    private(set) var busy = false
    private var lastSubmit: TimeInterval = 0
    private var loader: UIAlertController?
    /// When this form's Face ID / Touch ID last succeeded (system uptime). The device-key read of the same
    /// Submit reuses it whatever Lite's timer says, so one Submit is one prompt.
    private var verifiedAt: TimeInterval = 0

    init(identity: LiteBootstrapIdentity, bindingID: String, client: LiteBootstrapHTTPSClient, attemptID: String? = nil) {
        self.identity = identity
        self.bindingID = bindingID
        self.client = client
        self.attemptID = attemptID ?? UUID().uuidString
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel".localized(), style: .plain,
                                                           target: self, action: #selector(cancel))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Submit".localized(), style: .plain,
                                                            target: self, action: #selector(submitTapped))
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        buildForm()
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(_:)),
                                               name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(_:)),
                                               name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    // MARK: Keyboard

    /// Keeps the field being typed in above the keyboard: a form with a scroll view (TFA) gets the keyboard's
    /// height as bottom inset and scrolls the field into view; one without (Login) is moved up only as far as
    /// the field needs.
    @objc private func keyboardWillChangeFrame(_ note: Notification) {
        guard isViewLoaded, view.window != nil else { return }
        let hiding = note.name == UIResponder.keyboardWillHideNotification
        let endFrame = (note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect) ?? .zero
        let duration = (note.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double) ?? 0.25
        let keyboard = view.convert(endFrame, from: nil)
        let overlap = hiding ? 0 : max(0, view.bounds.maxY - keyboard.minY)
        let field = view.firstResponderDescendant

        if let scroll = view.firstScrollViewDescendant {
            let bottom = max(0, overlap - (view.bounds.maxY - scroll.frame.maxY))
            UIView.animate(withDuration: duration) {
                scroll.contentInset.bottom = bottom
                scroll.verticalScrollIndicatorInsets.bottom = bottom
                if let field, !hiding {
                    scroll.scrollRectToVisible(field.convert(field.bounds, to: scroll).insetBy(dx: 0, dy: -16), animated: false)
                }
            }
            return
        }
        var shift: CGFloat = 0
        if let field, !hiding {
            let fieldBottom = field.convert(field.bounds, to: view).maxY + 16 - view.transform.ty
            shift = min(0, keyboard.minY - fieldBottom)
        }
        UIView.animate(withDuration: duration) { self.view.transform = CGAffineTransform(translationX: 0, y: shift) }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Lite's bar: the app's main colour (black in dark mode), white bold title, white items.
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : .mainColor
        appearance.titleTextAttributes = [.font: UIFont.boldSystemFont(ofSize: 16), .foregroundColor: UIColor.white]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.overrideUserInterfaceStyle = .dark
    }

    func buildForm() {}
    func submitForm() {}

    @objc private func submitTapped() {
        guard !busy, ProcessInfo.processInfo.systemUptime - lastSubmit >= 2 else { return }
        lastSubmit = ProcessInfo.processInfo.systemUptime
        view.endEditing(true)
        submitForm()
    }

    @objc func dismissKeyboard() { view.endEditing(true) }

    @objc func cancel() { closeApp("sign-in dibatalkan") }

    /// Cancelling the sign-in, or running out of attempts, ends the app - as Lite's own TFAPasswordVC does
    /// (exit after the third failure): there is nothing behind the Sentinel cover to go back to, and no key
    /// for the asset without a sign-in. Nothing is sent or kept: the receipt and any login stage are dropped.
    func closeApp(_ reason: String) {
        NXLogger.general.publicInfo("[BootstrapAuth] \(reason) - aplikasi ditutup")
        LiteBootstrapReceipt.clear()
        LiteBootstrapLoginStage.clear()
        view.endEditing(true)
        hideLoader { exit(0) }
    }

    func finish(_ result: Result<String, Error>) {
        let done = onFinish
        onFinish = nil
        hideLoader { done?(result) }
    }

    // MARK: Lite look

    var fieldTint: UIColor { traitCollection.userInterfaceStyle == .dark ? .white : .mainColor }

    /// The eye button Lite puts on its password fields.
    func eyeButton(for field: UITextField) -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "eye.slash.fill"), for: .normal)
        button.tintColor = traitCollection.userInterfaceStyle == .dark ? .white : .black
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addAction(UIAction { [weak field, weak button] _ in
            guard let field else { return }
            field.isSecureTextEntry.toggle()
            button?.setImage(UIImage(systemName: field.isSecureTextEntry ? "eye.slash.fill" : "eye.fill"), for: .normal)
        }, for: .touchUpInside)
        return button
    }

    /// A failure, as an alert on this form's own window. Lite's floating banner went to the app's main
    /// window, which sits below the form's (.alert + 5), so the reader never saw it.
    func showFailure(_ text: String) {
        NXLogger.general.publicInfo("[BootstrapAuth] alert gagal ditampilkan")
        let alert = UIAlertController(title: "Sign-in gagal", message: text, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        var top: UIViewController = navigationController ?? self
        while let presented = top.presentedViewController, !presented.isBeingDismissed { top = presented }
        if top is UIAlertController, top !== loader {
            // One failure at a time: a second one replaces the text instead of stacking alerts.
            (top as? UIAlertController)?.message = text
            return
        }
        top.present(alert, animated: true)
    }

    /// Lite's "Please wait..." loader, presented from this form's own window.
    private func showLoader() {
        let alert = UIAlertController(title: nil, message: "Please wait...".localized(), preferredStyle: .alert)
        let spinner = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        spinner.style = .medium
        spinner.startAnimating()
        alert.view.addSubview(spinner)
        loader = alert
        (navigationController ?? self).present(alert, animated: true)
    }

    func hideLoader(_ then: @escaping () -> Void) {
        guard let loader else { then(); return }
        self.loader = nil
        loader.dismiss(animated: true, completion: then)
    }

    private func setBusy(_ value: Bool) {
        busy = value
        navigationItem.rightBarButtonItem?.isEnabled = !value
    }

    // MARK: Transport

    /// The fields every operation carries (Android: commonRequest), plus `platform`.
    func commonRequest() -> [String: Any] {
        [
            "install_id": bindingID,
            "device_id_hint": "",
            "auth_attempt_id": attemptID,
            // The connection id the session will use once the asset is open, on every stage (Android: B10).
            LiteBootstrapKeys.connectionID: identity.connectionID,
            "platform": "ios",
            "AAN": APIS.getAppNm(),
            "A95": Bundle.main.bundleIdentifier ?? "",
            "AID": UIDevice.current.identifierForVendor?.uuidString ?? "",
            "SD01": Int64(Date().timeIntervalSince1970 * 1000),
        ]
    }

    /// Runs one operation off the main thread: challenge + device proof where asked, the call, the
    /// answer back on the main thread.
    func execute(_ operation: String, _ request: [String: Any], deviceProof: Bool) {
        guard !busy else { return }
        setBusy(true)
        showLoader()
        let identity = self.identity, client = self.client
        // HSA reads the device key through Utils.authenticateWithBiometrics, which honours Lite's shared
        // timer (lastAuthenticationTime + authentication_duration, 30 s by default): right after the form's
        // own prompt it does not ask again.
        let justVerified = verifiedAt != 0 && ProcessInfo.processInfo.systemUptime - verifiedAt < 15
        let promptForKey = identity.hsa && !justVerified
        var request = request
        let common = commonRequest()
        NXLogger.general.publicInfo("[BootstrapAuth] \(operation) dikirim ke \(LiteBootstrapAuth.baseURL.host ?? "?")")
        Task.detached {
            do {
                if deviceProof {
                    if LiteBootstrapDeviceProof.hasDeviceKey {
                        var challengeRequest = common
                        challengeRequest[LiteBootstrapKeys.account] = identity.fPin
                        let challenge = try await client.challenge(challengeRequest)
                        guard challenge[LiteBootstrapKeys.code] as? String == "00" else {
                            throw LiteBootstrapError(Self.message(challenge))
                        }
                        guard let requestID = challenge["request_id"] as? String, !requestID.isEmpty else {
                            throw LiteBootstrapError("Request ID challenge tidak tersedia.")
                        }
                        try LiteBootstrapDeviceProof.add(to: &request, challenge: challenge[LiteBootstrapKeys.challenge] as? String,
                                                          hsa: promptForKey)
                        request["BOOTSTRAP_REQUEST_ID"] = requestID
                    } else {
                        try LiteBootstrapDeviceProof.add(to: &request, challenge: nil, hsa: promptForKey)
                    }
                }
                let response: [String: Any]
                switch operation {
                case "login": response = try await client.login(request)
                case "otp/send": response = try await client.sendOtp(request)
                case "otp/verify": response = try await client.verifyOtp(request)
                case "tfa": response = try await client.tfa(request)
                default: throw LiteBootstrapError("Operasi autentikasi tidak dikenal.")
                }
                // The code only: never the body, which can carry the assertion and profile data.
                NXLogger.general.publicInfo("[BootstrapAuth] \(operation) dijawab A97=\(response[LiteBootstrapKeys.code] as? String ?? "-")")
                await MainActor.run {
                    self.setBusy(false)
                    self.hideLoader { self.onBusinessResponse(operation, response) }
                }
            } catch {
                NXLogger.general.publicError("[BootstrapAuth] \(operation) gagal: \(error.localizedDescription)")
                await MainActor.run {
                    self.setBusy(false)
                    self.hideLoader { self.showFailure(error.localizedDescription) }
                }
            }
        }
    }

    func onBusinessResponse(_ operation: String, _ response: [String: Any]) {}

    /// A successful answer - the one /tfa gives, which alone carries the assertion. Checked for shape here;
    /// /zta/bootstrap/auth verifies the signature. The contract (Android, c6fb120f): A00 is the CLM connection
    /// id this device sent as B10, nothing else; A00real is the stable account; the assertion is bound to this
    /// install (binding_id) and to that account (acct_sha256 = SHA-256 of A00real). Its `sub` is a separate
    /// per-attempt ZTA alias and is compared with neither.
    func complete(_ response: [String: Any], firstLogin: Bool = false) {
        do {
            guard response[LiteBootstrapKeys.code] as? String == "00" else { throw LiteBootstrapError("Respons sukses tidak valid.") }
            let account = response[LiteBootstrapKeys.account] as? String ?? ""
            let stable = response[LiteBootstrapKeys.accountReal] as? String ?? ""
            guard !account.isEmpty, account == identity.connectionID, !stable.isEmpty else {
                throw LiteBootstrapError("Akun respons tidak cocok.")
            }
            let assertion = response["idp_assertion"] as? String ?? ""
            let parts = assertion.split(separator: ".", omittingEmptySubsequences: false)
            guard parts.count == 3, let claims = Self.decodeClaims(String(parts[1])),
                  !(claims["sub"] as? String ?? "").isEmpty, claims["binding_id"] as? String == bindingID,
                  (claims["acct_sha256"] as? String ?? "").lowercased() == Self.sha256Hex(stable),
                  (claims["platform"] as? String ?? "ios") == "ios" else {
                throw LiteBootstrapError("Assertion tidak cocok dengan akun/instalasi.")
            }
            LiteBootstrapReceipt.store(LiteBootstrapReceipt(binding: bindingID, returningUser: !firstLogin && identity.returningUser,
                                                            account: account, businessResponse: response,
                                                            createdAt: ProcessInfo.processInfo.systemUptime))
            NXLogger.general.publicInfo("[BootstrapAuth] sign-in pra-aset diterima; assertion diteruskan ke ZTA")
            finish(.success(assertion))
        } catch {
            // A successful backend operation with a malformed ZTA proof is not retried automatically.
            LiteBootstrapReceipt.clear()
            finish(.failure(error))
        }
    }

    static func sha256Hex(_ text: String) -> String {
        SHA256.hash(data: Data(text.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    static func decodeClaims(_ part: String) -> [String: Any]? {
        var base64 = part.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        while base64.count % 4 != 0 { base64 += "=" }
        guard let data = Data(base64Encoded: base64) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
    }

    static func message(_ response: [String: Any]) -> String {
        let text = response[LiteBootstrapKeys.message] as? String ?? ""
        return text.isEmpty ? "Autentikasi ditolak (\(response[LiteBootstrapKeys.code] as? String ?? "unknown"))." : text
    }

    // MARK: Biometrics

    var biometricAvailable: Bool {
        LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }

    /// Face ID / Touch ID on Lite's shared timer: skipped while an earlier success is inside
    /// `authentication_duration` (30 s by default), recorded in `lastAuthenticationTime` when it runs - so the
    /// device key, the master key and Lite's own screens that follow within the window ask nothing more.
    /// The evaluated context is handed to MasterKeyUtil for the biometric-bound master key read at connect.
    func biometric(_ reason: String, success: @escaping () -> Void, failure: @escaping (LAError.Code?) -> Void) {
        // Utils.authenticateWithBiometrics is the timer (skips inside the window, records a success) and
        // shares the confirmation with the master key; the form uses it rather than a prompt of its own.
        Utils.authenticateWithBiometrics { ok, _ in
            DispatchQueue.main.async {
                if ok { self.verifiedAt = ProcessInfo.processInfo.systemUptime; success() } else { failure(nil) }
            }
        }
    }
}

// MARK: - Login (never signed in on this install) - SignUpSignIn

final class LiteBootstrapLoginViewController: LiteBootstrapFormViewController {
    private let prompt = UILabel()
    private let user = UITextField()
    private let password = PasswordTextField()
    private lazy var eye = eyeButton(for: password)
    private let disclaimer = UILabel()
    private var invalidOtpCount = 0
    private var pendingEmail = ""
    /// The password of a username login, kept in memory only until its /tfa stage has been sent.
    private var pendingSecret = ""

    private static var nicknamePrompt: String { "Please enter your registered nickname or email address to Sign-In".localized() }

    /// Mode 1 (HSA) signs in existing accounts only: "Sign-In", and no nickname sign-up disclaimer.
    /// Mode 2 keeps Lite's "Sign-Up/Sign-In" with the disclaimer.
    private var signInOnly: Bool { identity.hsa }

    override func buildForm() {
        title = signInOnly ? "Sign-In".localized() : "Sign-Up/Sign-In".localized()
        let bundle = Bundle.resourceBundle(for: Nexilis.self)

        let avatar = UIImageView(image: UIImage(named: "pb_user", in: bundle, with: nil))
        avatar.contentMode = .scaleAspectFit
        let divider = UIView()
        divider.backgroundColor = UIColor(white: 0.667, alpha: 1)

        prompt.text = Self.nicknamePrompt
        prompt.font = .systemFont(ofSize: 15)
        prompt.textColor = .systemGray
        prompt.textAlignment = .center
        prompt.numberOfLines = 0

        user.placeholder = "Your Nickname".localized()
        user.borderStyle = .roundedRect
        user.font = .systemFont(ofSize: 14)
        user.autocapitalizationType = .none
        user.autocorrectionType = .no
        user.keyboardType = .emailAddress
        user.tintColor = fieldTint
        user.addTarget(self, action: #selector(userChanged), for: .editingChanged)

        password.placeholder = "Password".localized()
        password.borderStyle = .roundedRect
        password.font = .systemFont(ofSize: 14)
        password.isSecureTextEntry = true
        password.tintColor = fieldTint
        password.addPadding(.right(40))

        disclaimer.text = "Disclaimer : Signing up with a nickname provides full privacy since".localized()
            + " \(Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "") "
            + "does not know your identity, which is usually linked to your email account or mobile number. However, if you use a nickname, we will not be able to reset your password if you lose or forget it, so please keep your password secure.".localized()
        disclaimer.font = .italicSystemFont(ofSize: 14)
        disclaimer.textColor = .systemGray
        disclaimer.numberOfLines = 0
        disclaimer.isHidden = signInOnly

        for v in [avatar, divider, prompt, user, password, eye, disclaimer] as [UIView] {
            v.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(v)
        }
        let safe = view.safeAreaLayoutGuide, margins = view.layoutMarginsGuide
        NSLayoutConstraint.activate([
            avatar.topAnchor.constraint(equalTo: safe.topAnchor, constant: 40),
            avatar.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            avatar.widthAnchor.constraint(equalToConstant: 240),
            avatar.heightAnchor.constraint(equalToConstant: 128),
            divider.topAnchor.constraint(equalTo: avatar.bottomAnchor, constant: 10),
            divider.leadingAnchor.constraint(equalTo: margins.leadingAnchor, constant: 20),
            divider.trailingAnchor.constraint(equalTo: margins.trailingAnchor, constant: -20),
            divider.heightAnchor.constraint(equalToConstant: 2),
            prompt.topAnchor.constraint(equalTo: divider.bottomAnchor, constant: 20),
            prompt.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 40),
            prompt.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -40),
            user.topAnchor.constraint(equalTo: prompt.bottomAnchor, constant: 10),
            user.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 20),
            user.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -20),
            user.heightAnchor.constraint(equalToConstant: 34),
            password.topAnchor.constraint(equalTo: user.bottomAnchor, constant: 10),
            password.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 20),
            password.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -20),
            password.heightAnchor.constraint(equalToConstant: 34),
            eye.centerYAnchor.constraint(equalTo: password.centerYAnchor),
            eye.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -31),
            disclaimer.topAnchor.constraint(equalTo: password.bottomAnchor, constant: 30),
            disclaimer.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 40),
            disclaimer.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -40),
        ])
    }

    private func isEmail(_ value: String) -> Bool {
        value.range(of: "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}$", options: .regularExpression) != nil
    }

    /// An e-mail signs in by OTP: no password, no nickname disclaimer - as SignUpSignIn's e-mail mode.
    @objc private func userChanged() {
        let email = isEmail(user.text ?? "")
        password.isHidden = email
        eye.isHidden = email
        disclaimer.isHidden = email || signInOnly
        prompt.text = email ? "Please enter your registered email address.".localized() : Self.nicknamePrompt
    }

    override func submitForm() {
        let name = (user.text ?? "").trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { showFailure("Username/email wajib diisi."); return }
        if isEmail(name) {
            pendingEmail = name
            var request = commonRequest()
            request[LiteBootstrapKeys.email] = name
            request[LiteBootstrapKeys.businessEntity] = LiteBootstrapAuth.businessEntityKey
            execute("otp/send", request, deviceProof: false)
            return
        }
        guard name.range(of: "^[a-zA-Z0-9 ]*$", options: .regularExpression) != nil else {
            showFailure("Username hanya boleh alfanumerik."); return
        }
        let secret = password.text ?? ""
        if biometricAvailable {
            biometric("Verify your identity to continue with login.", success: { [weak self] in
                self?.login(name: name, secret: secret)
            }, failure: { [weak self] _ in self?.showFailure("Biometric or passcode authentication required".localized()) })
        } else {
            login(name: name, secret: secret)
        }
    }

    private func login(name: String, secret: String) {
        pendingSecret = secret
        var request = commonRequest()
        request[LiteBootstrapKeys.name] = name
        request[LiteBootstrapKeys.password] = secret
        request[LiteBootstrapKeys.businessEntity] = LiteBootstrapAuth.businessEntityKey
        execute("login", request, deviceProof: true)
    }

    /// Lite's own OTP sheet (VerifyEmail): six boxes, closes itself with the code.
    private func showOtpSheet(errCode: String = "") {
        let sheet = VerifyEmail()
        sheet.email = pendingEmail
        sheet.showWrongOTP = errCode
        sheet.isDismiss = { [weak self] code in
            guard let self else { return }
            guard self.biometricAvailable else { self.showFailure("Biometrik harus tersedia untuk login OTP."); return }
            self.biometric("Verify your identity to continue with login.", success: {
                var request = self.commonRequest()
                request[LiteBootstrapKeys.email] = self.pendingEmail
                request[LiteBootstrapKeys.businessEntity] = LiteBootstrapAuth.businessEntityKey
                request["OTP"] = code
                self.execute("otp/verify", request, deviceProof: true)
            }, failure: { _ in self.showFailure("Biometric or passcode authentication required".localized()) })
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            (self.navigationController ?? self).present(sheet, animated: true)
        }
    }

    override func onBusinessResponse(_ operation: String, _ response: [String: Any]) {
        let code = response[LiteBootstrapKeys.code] as? String ?? ""
        guard code == "00" else {
            if operation == "otp/verify", code == "4t" || code == "3t" {
                invalidOtpCount += 1
                if invalidOtpCount >= 3 { closeApp("OTP salah tiga kali"); return }
                showOtpSheet(errCode: code)   // VerifyEmail shows "Invalid OTP" / "Expired OTP" itself
                return
            }
            switch code {
            case "20": showFailure("Invalid user / Username and password does not match".localized())
            case "11": showFailure("Failed, unknown user".localized())
            case "4u": showFailure("Failed, blocked user".localized())
            case "13": showFailure("Failed, This user is not registered on this device".localized())
            default: showFailure(Self.message(response))
            }
            return
        }
        if operation == "otp/send" { showOtpSheet(); return }
        if operation == "tfa" { completeAfterAutomaticTfa(response); return }
        var reply = response
        // Username login: the legacy form forwards the typed nickname; keep A92 when the backend leaves it out
        // (an e-mail login keeps the profile name the backend returns). Android: BootstrapLoginActivity.
        if operation == "login", (reply[LiteBootstrapKeys.name] as? String ?? "").trimmingCharacters(in: .whitespaces).isEmpty {
            reply[LiteBootstrapKeys.name] = (user.text ?? "").trimmingCharacters(in: .whitespaces)
        }
        startTfaAfterLogin(reply, typedPassword: operation == "login")
    }

    /// The backend issues the assertion only at /tfa, so a good first login is stage one: the TFA form follows
    /// with the same attempt id and connection id, and its answer completes the sign-in. Mode 1 only; the Middle
    /// (mode 2) first install is not chained (Android, 45eeb487).
    private func startTfaAfterLogin(_ loginReply: [String: Any], typedPassword: Bool) {
        guard identity.hsa else { pendingSecret = ""; complete(loginReply, firstLogin: true); return }
        LiteBootstrapLoginStage.stage(binding: bindingID, attempt: attemptID, reply: loginReply)
        // A username login already has the password the TFA stage asks for: send /tfa with it at once, in
        // the same attempt, and go straight into the app - no second form. Only an e-mail (OTP) login, which
        // typed no password, gets the TFA form.
        if typedPassword, !pendingSecret.isEmpty {
            var request = commonRequest()
            request[LiteBootstrapKeys.password] = pendingSecret
            request["act"] = "Sign In"
            pendingSecret = ""
            execute("tfa", request, deviceProof: true)
            return
        }
        let tfa = LiteBootstrapTfaViewController(identity: identity, bindingID: bindingID, client: client,
                                                 attemptID: attemptID, afterLogin: true)
        tfa.onFinish = onFinish
        onFinish = nil
        navigationController?.pushViewController(tfa, animated: true)
    }

    /// The answer to the automatic /tfa stage: the staged login reply with what /tfa decides laid over it.
    private func completeAfterAutomaticTfa(_ response: [String: Any]) {
        guard var merged = LiteBootstrapLoginStage.reply(binding: bindingID, attempt: attemptID) else {
            finish(.failure(LiteBootstrapError("Tahap login kedaluwarsa; ulangi dari awal."))); return
        }
        for (key, value) in response { merged[key] = value }
        complete(merged, firstLogin: true)
    }
}

// MARK: - TFA (signed in on this install before) - TFAPasswordVC

final class LiteBootstrapTfaViewController: LiteBootstrapFormViewController {
    /// This TFA completes a first login in the same attempt (the device is not a returning one yet).
    private let afterLogin: Bool
    private let scrollView = UIScrollView()
    private let stack = UIStackView()
    private let password = UITextField()
    private var invalidPasswordCount = 0
    private var invalidBiometricCount = 0

    init(identity: LiteBootstrapIdentity, bindingID: String, client: LiteBootstrapHTTPSClient,
         attemptID: String? = nil, afterLogin: Bool = false) {
        self.afterLogin = afterLogin
        super.init(identity: identity, bindingID: bindingID, client: client, attemptID: attemptID)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    override func buildForm() {
        title = "Sign In".localized()
        // The first-login stage it completes must still be there; never skip it (process death, expiry).
        if afterLogin, LiteBootstrapLoginStage.reply(binding: bindingID, attempt: attemptID) == nil {
            DispatchQueue.main.async { self.finish(.failure(LiteBootstrapError("Tahap login tidak ditemukan; ulangi dari awal."))) }
        }
        let bundle = Bundle.resourceBundle(for: Nexilis.self)

        scrollView.showsVerticalScrollIndicator = false
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 16

        let badge = UIImageView(image: UIImage(named: "pb_ic_attach_spc_badge", in: bundle, with: nil))
        badge.contentMode = .scaleAspectFit
        badge.heightAnchor.constraint(equalToConstant: 100).isActive = true
        stack.addArrangedSubview(badge)

        // The institution's TFA logo when Lite has it cached; no network before the asset is open.
        let splash = UIImageView()
        splash.contentMode = .scaleAspectFit
        let logo = Utils.getTfaLogo()
        splash.image = (!logo.isEmpty ? ImageCache.shared.image(forKey: logo) : nil)
            ?? UIImage(named: "pb_mfa_splash_sign_in", in: bundle, with: nil)
        splash.heightAnchor.constraint(equalToConstant: 230).isActive = true
        stack.addArrangedSubview(splash)

        let heading = UILabel()
        heading.text = "Sign In"
        heading.font = .boldSystemFont(ofSize: 17)
        heading.textAlignment = .center
        heading.numberOfLines = 0
        stack.addArrangedSubview(heading)

        let subtitle = UILabel()
        subtitle.text = "Please input your password to continue".localized()
        subtitle.font = .systemFont(ofSize: 12)
        subtitle.textAlignment = .center
        subtitle.numberOfLines = 0
        stack.addArrangedSubview(subtitle)
        stack.setCustomSpacing(12, after: subtitle)

        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.widthAnchor.constraint(equalToConstant: 300).isActive = true
        container.heightAnchor.constraint(equalToConstant: 48).isActive = true
        password.placeholder = "Type your password...".localized()
        password.isSecureTextEntry = true
        password.font = .systemFont(ofSize: 15)
        password.borderStyle = .roundedRect
        password.autocapitalizationType = .none
        password.autocorrectionType = .no
        password.tintColor = fieldTint
        password.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(password)
        let eye = eyeButton(for: password)
        container.addSubview(eye)
        stack.addArrangedSubview(container)

        let poweredLabel = UILabel()
        poweredLabel.text = "Powered by Nexilis"
        poweredLabel.font = .systemFont(ofSize: 12)
        let poweredImage = UIImageView(image: UIImage(named: "pb_powered_button", in: bundle, with: nil)
                                        ?? UIImage(named: "pb_powered_button"))
        poweredImage.contentMode = .scaleAspectFit
        let powered = UIStackView(arrangedSubviews: [poweredLabel, poweredImage])
        powered.axis = .horizontal
        powered.alignment = .center
        powered.spacing = 8

        for v in [scrollView, stack, powered] as [UIView] { v.translatesAutoresizingMaskIntoConstraints = false }
        view.addSubview(scrollView)
        scrollView.addSubview(stack)
        view.addSubview(powered)
        let safe = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: safe.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            scrollView.bottomAnchor.constraint(equalTo: powered.topAnchor, constant: -8),
            stack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stack.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            password.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            password.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            password.topAnchor.constraint(equalTo: container.topAnchor),
            password.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            eye.trailingAnchor.constraint(equalTo: password.trailingAnchor, constant: -8),
            eye.centerYAnchor.constraint(equalTo: password.centerYAnchor),
            eye.widthAnchor.constraint(equalToConstant: 40),
            eye.heightAnchor.constraint(equalToConstant: 40),
            poweredImage.widthAnchor.constraint(equalToConstant: 25),
            poweredImage.heightAnchor.constraint(equalToConstant: 25),
            powered.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -16),
            powered.bottomAnchor.constraint(equalTo: safe.bottomAnchor, constant: -8),
        ])
    }

    override func submitForm() {
        let secret = password.text ?? ""
        guard !secret.trimmingCharacters(in: .whitespaces).isEmpty else {
            view.makeToast("Password cannot be empty.".localized(), duration: 2.0, position: .center); return
        }
        guard secret.count >= 6 else {
            view.makeToast("Password must be at least 6 characters.".localized(), duration: 2.0, position: .center); return
        }
        // Password first; Face ID / Touch ID only on Submit (as Lite's TFAPasswordVC), and only when Lite's
        // shared timer says the last success is older than authentication_duration.
        if identity.hsa {
            guard biometricAvailable else { showFailure("Biometrik wajib tersedia untuk autentikasi HSA."); return }
            biometric("Confirm Identity", success: { [weak self] in
                self?.invalidBiometricCount = 0
                self?.validate(secret)
            }, failure: { [weak self] _ in self?.countBiometricFailure() })
            return
        }
        validate(secret)
    }

    private func validate(_ secret: String) {
        var request = commonRequest()
        // After a first login the backend already knows the account from the attempt; a returning user names it.
        if !afterLogin { request[LiteBootstrapKeys.account] = identity.fPin }
        request[LiteBootstrapKeys.password] = secret
        request["act"] = "Sign In"
        execute("tfa", request, deviceProof: true)
    }

    private func countBiometricFailure() {
        invalidBiometricCount += 1
        if invalidBiometricCount >= 3 { closeApp("biometrik gagal tiga kali") }
        else { showFailure("Biometric Failed".localized() + " (\(invalidBiometricCount)/3)") }
    }

    override func onBusinessResponse(_ operation: String, _ response: [String: Any]) {
        if response[LiteBootstrapKeys.code] as? String == "00" {
            guard afterLogin else { complete(response); return }
            // The continuation after the asset opens applies ONE login-shaped reply: the login stage's, with what
            // /tfa decides laid over it (A00/A00real, IDL, the assertion).
            guard var merged = LiteBootstrapLoginStage.reply(binding: bindingID, attempt: attemptID) else {
                finish(.failure(LiteBootstrapError("Tahap login kedaluwarsa; ulangi dari awal."))); return
            }
            for (key, value) in response { merged[key] = value }
            complete(merged, firstLogin: true)
            return
        }
        let text = Self.message(response)
        if text.lowercased().contains("password") {
            invalidPasswordCount += 1
            if invalidPasswordCount >= 3 { closeApp("password salah tiga kali"); return }
        }
        showFailure(text)
    }
}

private extension UIView {
    var firstResponderDescendant: UIView? {
        if isFirstResponder { return self }
        for sub in subviews { if let found = sub.firstResponderDescendant { return found } }
        return nil
    }
    var firstScrollViewDescendant: UIScrollView? {
        for sub in subviews {
            if let scroll = sub as? UIScrollView, !(scroll is UITextView) { return scroll }
            if let found = sub.firstScrollViewDescendant { return found }
        }
        return nil
    }
}
