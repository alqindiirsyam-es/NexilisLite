import UIKit

final class TOTPInputViewController: UIViewController {

    // MARK: - UI

    private let backgroundImageView = UIImageView()

    private let scvwLoading = UIScrollView()
    private let scvwScan = UIScrollView()
    private let scvwInput = UIScrollView()

    // Scan
    private let qrImageView = UIImageView()
    private let btnNext = UIButton(type: .system)

    // Input
    private let edtCode = UITextField()
    private let btnSubmit = UIButton(type: .system)

    // MARK: - State

    private let userId: String
    private let password: String

    private var savedSecret: String?
    private var generatedSecret: String?

    // MARK: - Callbacks

    var onSuccess: (() -> Void)?
    var onFailure: (() -> Void)?

    // MARK: - Init

    init(userId: String, password: String) {
        self.userId = userId
        self.password = password
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("Storyboard not supported")
    }

    // MARK: - Lifecycle

    override func loadView() {
        view = UIView()
        view.backgroundColor = .systemBackground
        setupLayout()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        savedSecret = Utils.getTOTPSecret()
        checkNeedTOTP()
    }
}

private extension TOTPInputViewController {

    enum L {
        static let contentWidth: CGFloat = 300
        static let buttonHeight: CGFloat = 46
        static let qrSize: CGFloat = 300
    }

    func setupLayout() {

        // Background
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        backgroundImageView.contentMode = .scaleAspectFill
        view.addSubview(backgroundImageView)

        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        // ScrollViews
        [scvwLoading, scvwScan, scvwInput].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
            NSLayoutConstraint.activate([
                $0.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                $0.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                $0.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                $0.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
            $0.isHidden = true
        }

        setupLoading()
        setupScan()
        setupInput()

        scvwLoading.isHidden = false
    }
}

private extension TOTPInputViewController {

    func setupLoading() {
        let stack = verticalStack()
        scvwLoading.addSubview(stack)
        center(stack, in: scvwLoading)

        stack.addArrangedSubview(spacer(30))
        let loadingHeaderImage = image(height: 160)
        loadingHeaderImage.image = UIImage(named: "pb_user")
        stack.addArrangedSubview(loadingHeaderImage)
        stack.addArrangedSubview(separator())
        stack.addArrangedSubview(label("Checking OTP...", size: 17))
    }
}

private extension TOTPInputViewController {

    func setupScan() {
        let stack = verticalStack()
        scvwScan.addSubview(stack)
        center(stack, in: scvwScan)

        stack.addArrangedSubview(spacer(30))

        qrImageView.contentMode = .scaleAspectFit
        qrImageView.widthAnchor.constraint(equalToConstant: L.qrSize).isActive = true
        qrImageView.heightAnchor.constraint(equalToConstant: L.qrSize).isActive = true
        stack.addArrangedSubview(qrImageView)

        stack.addArrangedSubview(separator())
        stack.addArrangedSubview(label("Scan to Setup OTP", size: 17))
        stack.addArrangedSubview(label(
            "Scan the above code from your Authenticator app to setup OTP",
            size: 12
        ))

        btnNext.setTitle("Next", for: .normal)
        btnNext.heightAnchor.constraint(equalToConstant: L.buttonHeight).isActive = true
        btnNext.widthAnchor.constraint(equalToConstant: L.contentWidth).isActive = true
        btnNext.addTarget(self, action: #selector(goToInput), for: .touchUpInside)
        stylePrimaryButton(btnNext)
        stack.addArrangedSubview(btnNext)
    }
}

private extension TOTPInputViewController {

    func setupInput() {
        let stack = verticalStack()
        scvwInput.addSubview(stack)
        center(stack, in: scvwInput)

        stack.addArrangedSubview(spacer(30))
        let inputHeaderImage = image(height: 160)
        inputHeaderImage.image = UIImage(named: "pb_user")
        stack.addArrangedSubview(inputHeaderImage)
        stack.addArrangedSubview(separator())
        stack.addArrangedSubview(label("Input OTP", size: 17))
        stack.addArrangedSubview(label(
            "Please input the OTP code shown in your Authenticator App",
            size: 12
        ))

        edtCode.textAlignment = .center
        edtCode.keyboardType = .numberPad
        edtCode.placeholder = "OTP Code"
        edtCode.layer.borderWidth = 1
        edtCode.layer.cornerRadius = 6
        edtCode.heightAnchor.constraint(equalToConstant: L.buttonHeight).isActive = true
        edtCode.widthAnchor.constraint(equalToConstant: L.contentWidth).isActive = true
        edtCode.addTarget(self, action: #selector(limitOTP), for: .editingChanged)
        stack.addArrangedSubview(edtCode)

        btnSubmit.setTitle("Submit", for: .normal)
        btnSubmit.heightAnchor.constraint(equalToConstant: L.buttonHeight).isActive = true
        btnSubmit.widthAnchor.constraint(equalToConstant: L.contentWidth).isActive = true
        btnSubmit.addTarget(self, action: #selector(submitCode), for: .touchUpInside)
        stylePrimaryButton(btnSubmit)
        stack.addArrangedSubview(btnSubmit)
    }
    
    @objc private func limitOTP() {
        if let text = edtCode.text, text.count > 6 {
            edtCode.text = String(text.prefix(6))
        }
    }
}

private extension TOTPInputViewController {

    func showLoading() {
        scvwLoading.isHidden = false
        scvwScan.isHidden = true
        scvwInput.isHidden = true
    }

    func showScan() {
        scvwLoading.isHidden = true
        scvwScan.isHidden = false
        scvwInput.isHidden = true

        generatedSecret = TOTPManager.generateSecretKey()
        let issuer = Bundle.main.object(
            forInfoDictionaryKey: APIS.getAppNm()
        ) as? String ?? "Nexilis"

        qrImageView.image = TOTPManager.generateQRCode(
            account: userId,
            issuer: issuer,
            secret: generatedSecret!
        )
    }

    func showInput() {
        scvwLoading.isHidden = true
        scvwScan.isHidden = true
        scvwInput.isHidden = false
    }

    @objc func goToInput() {
        showInput()
    }

    @objc func submitCode() {
        guard let code = edtCode.text, !code.isEmpty else {
            alert("Please input OTP Code")
            return
        }

        let secret = savedSecret ?? generatedSecret!
        let valid = TOTPManager.verifyTOTP(secret: secret, code: code)

        if valid {
            if savedSecret == nil {
                Utils.setTOTPSecret(value: secret)
            }
            onSuccess?()
        } else {
            onFailure?()
        }

        dismiss(animated: true)
    }
}

private extension TOTPInputViewController {

    func checkNeedTOTP() {
        DispatchQueue.global(qos: .background).async {

            let appNm = APIS.getAppNm()
            var didRespond = false

            if let result = Nexilis.writeSync(
                message: CoreMessage_TMessageBank.getNeedScanTOTP(
                    apiKey: appNm,
                    username: self.userId,
                    password: self.password
                )
            ), result.isOk() {

                let data = result.getBody(key: CoreMessage_TMessageKey.DATA)
                didRespond = true

                DispatchQueue.main.async {
                    switch data {
                    case "1":
                        // Force QR
                        self.showScan()

                    case "0":
                        // Input only IF secret exists
                        if self.savedSecret == nil {
                            self.showScan()
                        } else {
                            self.showInput()
                        }

                    default:
                        // Error fallback
                        self.savedSecret == nil
                            ? self.showScan()
                            : self.showInput()
                    }
                }
            }

            // ⬇️ Android-style fallback (timeout / error)
            if !didRespond {
                DispatchQueue.main.async {
                    self.savedSecret == nil
                        ? self.showScan()
                        : self.showInput()
                }
            }
        }
    }

}

private extension TOTPInputViewController {

    func verticalStack() -> UIStackView {
        let s = UIStackView()
        s.axis = .vertical
        s.alignment = .center
        s.spacing = 12
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }

    func center(_ v: UIView, in container: UIView) {
        NSLayoutConstraint.activate([
            v.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            v.topAnchor.constraint(equalTo: container.topAnchor),
            v.widthAnchor.constraint(equalTo: container.widthAnchor)
        ])
    }

    func spacer(_ h: CGFloat) -> UIView {
        let v = UIView()
        v.heightAnchor.constraint(equalToConstant: h).isActive = true
        return v
    }

    func separator() -> UIView {
        let v = UIView()
        v.backgroundColor = .systemGray3
        v.widthAnchor.constraint(equalToConstant: L.contentWidth - 60).isActive = true
        v.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return v
    }

    func label(_ text: String, size: CGFloat) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = .systemFont(ofSize: size)
        l.textAlignment = .center
        l.numberOfLines = 0
        l.widthAnchor.constraint(equalToConstant: L.contentWidth).isActive = true
        return l
    }

    func image(height: CGFloat) -> UIImageView {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.heightAnchor.constraint(equalToConstant: height).isActive = true
        return iv
    }

    func alert(_ msg: String) {
        let a = UIAlertController(title: nil, message: msg, preferredStyle: .alert)
        a.addAction(.init(title: "OK", style: .default))
        present(a, animated: true)
    }
    
    func stylePrimaryButton(_ button: UIButton) {
        button.backgroundColor = UIColor.systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
    }

}

private extension TOTPInputViewController {

    func showQrCode() {
        scvwLoading.isHidden = true
        scvwScan.isHidden = false
        scvwInput.isHidden = true

        generatedSecret = TOTPManager.generateSecretKey()

        let issuer: String = {
            if let name = Bundle.main.object(forInfoDictionaryKey: APIS.getAppNm()) as? String,
               !name.isEmpty {
                return name
            }
            return "Nexilis"
        }()

        qrImageView.image = TOTPManager.generateQRCode(
            account: userId,
            issuer: issuer,
            secret: generatedSecret!
        )
    }

    func showInputCode() {
        scvwLoading.isHidden = true
        scvwScan.isHidden = true
        scvwInput.isHidden = false
    }
}

