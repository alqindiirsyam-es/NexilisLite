//
//  QRProfileController.swift
//  Pods
//
//  Created by Maronakins on 17/01/25.
//

import UIKit
import CoreImage

class QRProfileController: UIViewController {
    var qrCodeImage: UIImage?

    var fPin : String?
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white

        // Generate a QR code
        let qrCodeString = fPin
        qrCodeImage = generateQRCode(from: qrCodeString!)

        guard let qrCodeImage = qrCodeImage else { return }

        // Add an image view to display the QR code
        let imageView = UIImageView(image: qrCodeImage)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)

        // Add a share button
        let shareButton = UIButton(type: .system)
        shareButton.setTitle("Share QR Code", for: .normal)
        shareButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        shareButton.addTarget(self, action: #selector(shareQRCode), for: .touchUpInside)
        shareButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(shareButton)

        // Add constraints
        NSLayoutConstraint.activate([
//            label.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
//            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 200),
            imageView.heightAnchor.constraint(equalToConstant: 200),

            shareButton.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20),
            shareButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    @objc func shareQRCode() {
        guard let qrCodeImage = qrCodeImage else { return }

        // Create the activity view controller
        let activityViewController = UIActivityViewController(activityItems: [qrCodeImage], applicationActivities: nil)

        // Present the activity view controller
        present(activityViewController, animated: true, completion: nil)
    }

    func generateQRCode(from string: String) -> UIImage? {
        let data = string.data(using: String.Encoding.ascii)

        // Create a QR code filter
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            filter.setValue("Q", forKey: "inputCorrectionLevel") // Error correction level: L, M, Q, H

            // Generate the QR code image
            if let outputImage = filter.outputImage {
                let transform = CGAffineTransform(scaleX: 10, y: 10) // Scale the image
                let scaledImage = outputImage.transformed(by: transform)

                // Convert to UIImage
                return UIImage(ciImage: scaledImage)
            }
        }
        return nil
    }
}
