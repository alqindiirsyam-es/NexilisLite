//
//  GaspolScannerViewController.swift
//  Gaspol
//
//  Created by Qindi on 19/05/22.
//

import Foundation
import UIKit
@_implementationOnly import NotificationBannerSwift
import nuSDKService

public class ScannerViewController: UIViewController, QRScannerViewDelegate {
    
    var scannerView: QRScannerView = {
        let scannerView = QRScannerView()
        return scannerView
    }()
    
    var titleInfo: UILabel = {
        let titleInfo = UILabel()
        titleInfo.text = "Scan the QR Sign-In code on your web browser".localized()
        titleInfo.font = .boldSystemFont(ofSize: 16.0)
        titleInfo.numberOfLines = 0
        titleInfo.textAlignment = .center
        return titleInfo
    }()
    
    public override func viewDidDisappear(_ animated: Bool) {
        if scannerView.isRunning {
            scannerView.stopScanning()
        }
        self.navigationController?.navigationBar.topItem?.title = nil
        self.navigationController?.navigationBar.setNeedsLayout()
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        
        let attributes = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 16.0), NSAttributedString.Key.foregroundColor: UIColor.white]
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : UIColor.mainColor
        navBarAppearance.titleTextAttributes = attributes
        navigationController?.navigationBar.standardAppearance = navBarAppearance
        navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance

        self.title = "Scan QR Code".localized()
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel".localized(), style: .plain, target: self, action: #selector(cancel(sender:)))
        
        self.view.addSubview(scannerView)
        self.view.addSubview(titleInfo)
        scannerView.anchor(left: self.view.leftAnchor, right: self.view.rightAnchor, centerX: self.view.centerXAnchor, centerY: self.view.centerYAnchor, height: self.view.bounds.height / 2)
        titleInfo.anchor(left: self.view.leftAnchor, bottom: scannerView.topAnchor, right: self.view.rightAnchor, paddingBottom: 10.0, centerX: self.view.centerXAnchor)
        
        scannerView.delegate = self
    }
    
    @objc func cancel(sender: Any) {
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        scannerView.startScanning()
    }
    
    func qrScanningDidFail() {
        let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
        imageView.tintColor = .white
        let banner = FloatingNotificationBanner(title: "Scanning Failed. Please try again".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
        banner.show()
        cancel(sender: "")
    }
    
    func qrScanningSucceededWithCode(_ str: String?) {
        if !CheckConnection.isConnectedToNetwork()  || API.nGetCLXConnState() == 0 {
            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
            imageView.tintColor = .white
            let banner = FloatingNotificationBanner(title: "Check your connection".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
            banner.show()
        } else {
            DispatchQueue.global().async {
                if let response = Nexilis.writeSync(message: CoreMessage_TMessageBank.getWebLoginQRCode(f_qrcode: str ?? "")) {
                    if response.isOk() {
                        DispatchQueue.main.async {
                            let imageView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
                            imageView.tintColor = .white
                            let banner = FloatingNotificationBanner(title: "Successfully Sign-In".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .success, colors: nil, iconPosition: .center)
                            banner.show()
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                        imageView.tintColor = .white
                        let banner = FloatingNotificationBanner(title: "Unable to access servers".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                        banner.show()
                    }
                }
            }
        }
        cancel(sender: "")
    }
    
    func qrScanningDidStop() {
        //print("SCANNED STOP")
    }
}
