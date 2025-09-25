//
//  BNIBookingWebView.swift
//  FMDB
//
//  Created by Qindi on 01/04/22.
//

import Foundation
import UIKit
import WebKit
import Speech
import CommonCrypto

public class BNIBookingWebView: UIViewController, WKNavigationDelegate, UIScrollViewDelegate, UIGestureRecognizerDelegate, WKScriptMessageHandler, SFSpeechRecognizerDelegate, ImageVideoPickerDelegate {
    var webView: WKWebView!
    let closeButton = UIButton()
    public var customUrl = ""
    public var isSecureBrowser = false
    let textField = UITextField()
    
    var isAllowSpeech = false
    
    let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "id"))

    var recognitionRequest : SFSpeechAudioBufferRecognitionRequest?
    var recognitionTask : SFSpeechRecognitionTask?
    let audioEngine = AVAudioEngine()
    var alertController = LibAlertController()
    
    var indexImageVideoWv = 0
    var imageVideoPicker: ImageVideoPicker!
    var blockedCertificate = ""
    var allowedURLs = Set<String>()
    var loadingURL = false
    
    var onDismiss: (() -> Void)?
    
    public override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if self.isBeingDismissed || self.isMovingFromParent {
            onDismiss?()
        }
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        let attributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : UIColor.mainColor
        navBarAppearance.titleTextAttributes = attributes
        navigationController?.navigationBar.standardAppearance = navBarAppearance
        navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance
        
        let backButton = UIBarButtonItem(image: UIImage(systemName: "chevron.backward"), style: .plain, target: self, action: #selector(self.didTapExit))
        self.navigationItem.leftBarButtonItem = backButton
        
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        loadContentBlocker(into: configuration) { [self] in
            DispatchQueue.main.async {
                self.initializeWebView(with: configuration)
            }
        }
    }
    
    @objc func didTapExit(sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func initializeWebView(with configuration: WKWebViewConfiguration) {
        let customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.5 Mobile/15E148 Safari/604.1 \(Utils.getUserAgent())"
        let finalUserAgent = "\(customUserAgent)"
        configuration.applicationNameForUserAgent = finalUserAgent
        webView = WKWebView(frame: .zero, configuration: configuration)
        
        let containerView = UIView()
        containerView.backgroundColor = .white
        if isSecureBrowser {
            title = "Secure Browser".localized()
            view.addSubview(containerView)
            containerView.translatesAutoresizingMaskIntoConstraints = false
            containerView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
            containerView.heightAnchor.constraint(equalToConstant: 44).isActive = true
            
            containerView.addSubview(textField)
            textField.translatesAutoresizingMaskIntoConstraints = false
            textField.leftAnchor.constraint(equalTo: containerView.leftAnchor, constant: 10.0).isActive = true
            textField.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
            textField.heightAnchor.constraint(equalToConstant: 40).isActive = true
            textField.widthAnchor.constraint(equalToConstant: view.bounds.size.width - 80).isActive = true
            textField.layer.borderColor = UIColor.lightGray.cgColor
            textField.layer.borderWidth = 1.0
            textField.layer.cornerRadius = 5.0
            textField.clipsToBounds = true
            
            let buttonGo = UIButton(type: .custom)
            buttonGo.setTitle("Go".localized(), for: .normal)
            buttonGo.setTitleColor(.black, for: .normal)
            buttonGo.addTarget(self, action: #selector(goAction), for: .touchUpInside)
            containerView.addSubview(buttonGo)
            buttonGo.translatesAutoresizingMaskIntoConstraints = false
            buttonGo.leftAnchor.constraint(equalTo: textField.rightAnchor, constant: 10.0).isActive = true
            buttonGo.rightAnchor.constraint(equalTo: containerView.rightAnchor, constant: -10.0).isActive = true
            buttonGo.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
            buttonGo.heightAnchor.constraint(equalToConstant: 40).isActive = true
        }
        
        view.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        if isSecureBrowser {
            webView.topAnchor.constraint(equalTo: containerView.bottomAnchor).isActive = true
        } else {
            webView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        }
        webView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        webView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        webView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true

        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.delegate = self
        
        let contentController = webView.configuration.userContentController
        contentController.add(self, name: "sendQueueBNI")
        contentController.add(self, name: "checkProfile")
        contentController.add(self, name: "setIsProductModalOpen")
        contentController.add(self, name: "toggleVoiceSearch")
        contentController.add(self, name: "blockUser")
        contentController.add(self, name: "showAlert")
        contentController.add(self, name: "closeProfile")
        contentController.add(self, name: "successChangeTheme")
        contentController.add(self, name: "finishForm")
        contentController.add(self, name: "shareText")
        contentController.add(self, name: "openGalleryiOS")
        
        let source: String = "var meta = document.createElement('meta');" +
            "meta.name = 'viewport';" +
            "meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';" +
            "var head = document.getElementsByTagName('head')[0];" +
            "head.appendChild(meta);" +
        "$('#header-layout').find('.col-8').removeClass('col-8').addClass('col');" +
        "$('#header-layout').find('.col-4').removeClass('col-4').addClass('col');"
        let script: WKUserScript = WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        contentController.addUserScript(script)
        
        let cookieScript1 = "document.cookie = '\(Utils.getCookiesMobile().components(separatedBy: ";")[0])';"
        let cookieScriptInjection1 = WKUserScript(source: cookieScript1, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        configuration.userContentController.addUserScript(cookieScriptInjection1)
        
        let cookieScript2 = "document.cookie = '\(Utils.getCookiesMobile().components(separatedBy: ";")[1])';"
        let cookieScriptInjection2 = WKUserScript(source: cookieScript2, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        configuration.userContentController.addUserScript(cookieScriptInjection2)
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(reloadWebView(_:)), for: .valueChanged)
        webView.scrollView.addSubview(refreshControl)
        
        webView.isOpaque = false
        webView.backgroundColor = .white
        webView.scrollView.backgroundColor = .white
        
        var stringQMS = "https://sqbni.murni.id:4200/bnibookingonline/#/?userid="
        if !customUrl.isEmpty {
            stringQMS = customUrl
        }
        if stringQMS.lowercased().contains("?userid=") {
            let name = User.getData(pin: User.getMyPin())!.fullName
            stringQMS += name
        } else if stringQMS.lowercased().contains("?f_pin=") {
            stringQMS += User.getMyPin()!
        }
        
        if stringQMS.contains("<<f_pin>>") {
            stringQMS = stringQMS.replacingOccurrences(of: "<<f_pin>>", with: User.getMyPin()!)
        }
        let lang: String = SecureUserDefaults.shared.value(forKey: "i18n_language") ?? "en"
        var intLang = 0
        if lang == "id" {
            intLang = 1
        }
        if stringQMS.contains("?") {
            stringQMS = stringQMS + "&lang=\(intLang)&theme=\(self.traitCollection.userInterfaceStyle == .dark ? "0" : "1")"
        } else {
            stringQMS = stringQMS + "?lang=\(intLang)&theme=\(self.traitCollection.userInterfaceStyle == .dark ? "0" : "1")"
        }
        if let url = URL(string: "\(stringQMS)") {
            if !isSecureBrowser {
                loadURLWithCookie(url: url)
            } else {
                if let url = URL(string: "https://google.com/") {
                    loadURLWithCookie(url: url)
                }
            }
        } else if isSecureBrowser {
            if let url = URL(string: "https://google.com/") {
                loadURLWithCookie(url: url)
            }
        }
    }
    
    func loadContentBlocker(into config: WKWebViewConfiguration, completion: @escaping () -> Void) {
        // Define ad-blocking rules directly in Swift as a string
        let contentRules = #"""
        [
          {
            "trigger": {
              "url-filter": "doubleclick.net"
            },
            "action": {
              "type": "block"
            }
          },
          {
            "trigger": {
              "url-filter": "googlesyndication.com"
            },
            "action": {
              "type": "block"
            }
          },
          {
            "trigger": {
              "url-filter": "taboola.com"
            },
            "action": {
              "type": "block"
            }
          },
          {
            "trigger": {
              "url-filter": "outbrain.com"
            },
            "action": {
              "type": "block"
            }
          }
        ]
        """#

        WKContentRuleListStore.default().compileContentRuleList(forIdentifier: "AdBlocker", encodedContentRuleList: contentRules) { ruleList, error in
            if let ruleList = ruleList {
                config.userContentController.add(ruleList)
            } else {
                print("Failed to compile content rule list: \(error?.localizedDescription ?? "Unknown error")")
            }
            completion()
        }
    }
    
    @objc func goAction() {
        if let text = textField.text, !text.isEmpty {
            var urlString = text
            if !text.starts(with: "www.") && !text.starts(with: "https://") {
                urlString = "https://www.google.com/search?q=\(text)"
            }
            urlString = urlString.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: " ", with: "+")
            if let url = URL(string: urlString) {
                loadURLWithCookie(url: url)
            }
        }
    }
    
    func loadURLWithCookie(url: URL) {
        var urlRequest = URLRequest(url: url)
        let customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.5 Mobile/15E148 Safari/604.1 \(Utils.getUserAgent())"
        urlRequest.setValue(customUserAgent, forHTTPHeaderField: "User-Agent")
        if let cookies = HTTPCookieStorage.shared.cookies(for: url) {
            for cookie in cookies {
                webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie)
            }
            textField.text = url.absoluteString
            webView.load(urlRequest)
        }
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
    }
    
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "sendQueueBNI" {
            guard let dict = message.body as? [String: AnyObject],
                  let param1 = dict["param1"] as? String else {
                return
            }
            DispatchQueue.global().async {
                let _ = Nexilis.writeSync(message: CoreMessage_TMessageBank.queueBNI(service_id: param1), timeout: 30 * 1000)
            }
        }
        if message.name == "checkProfile" {
            guard let dict = message.body as? [String: AnyObject],
                  let param1 = dict["param1"] as? String,
                  let param2 = dict["param2"] as? String else {
                return
            }
            if Nexilis.checkIsChangePerson() {
                if param2 == "like" {
                    self.webView.evaluateJavaScript("likeProduct('\(param1)',1,true);")
                } else if param2 == "comment" {
                    self.webView.evaluateJavaScript("openComment('\(param1.split(separator: "|")[0])',\(param1.split(separator: "|")[1]),true);")
                } else if param2 == "report_user" {
                    self.webView.evaluateJavaScript("reportUser('\(param1)',true);")
                } else if param2 == "report_content" {
                    self.webView.evaluateJavaScript("reportContent('\(param1.split(separator: "|")[0])','\(param1.split(separator: "|")[1])',true);")
                } else if param2 == "block_user" {
                    self.webView.evaluateJavaScript("blockUser('\(param1)',true);")
                } else if param2 == "follow_user" {
                    self.webView.evaluateJavaScript("followUser('\(param1.split(separator: "|")[0])',\(param1.split(separator: "|")[1]),true);")
                } else if param2 == "homepage" || param2 == "gif" {
                    self.webView.evaluateJavaScript("window.location.href = '\(param1)';")
                } else if param2 == "block_content" {
                    self.webView.evaluateJavaScript("blockContent('\(param1)',true);")
                } else {
                    self.webView.evaluateJavaScript("openNewPost(true);")
                }
            } else {
                self.webView.evaluateJavaScript("{if(pauseAll){pauseAll();}}")
            }
        } else if message.name == "setIsProductModalOpen" {
            guard let dict = message.body as? [String: AnyObject],
                  let param1 = dict["param1"] as? Bool else {
                return
            }
            if param1 {
                if self.webView.scrollView.contentOffset.y < 0 { // Move tableView to top
                    self.webView.scrollView.setContentOffset(CGPoint.zero, animated: true)
                }
            }
        } else if message.name == "toggleVoiceSearch" {
            if !isAllowSpeech {
                setupSpeech()
            } else {
                runVoice()
            }
        } else if message.name == "blockUser" {
            guard let dict = message.body as? [String: AnyObject],
                  let param1 = dict["param1"] as? String,
                  let param2 = dict["param2"] as? Bool else {
                return
            }
            if param2 {
                DispatchQueue.global().async {
                    if let response = Nexilis.writeAndWait(message: CoreMessage_TMessageBank.getBlock(l_pin: param1)) {
                        if response.isOk() {
                            DispatchQueue.main.async {
                                Database.shared.database?.inTransaction({ (fmdb, rollback) in
                                    do {
                                        _ = Database.shared.updateRecord(fmdb: fmdb, table: "BUDDY", cvalues: [
                                            "ex_block" : "1"
                                        ], _where: "f_pin = '\(param1)'")
                                    } catch {
                                        rollback.pointee = true
                                        print("Access database error: \(error.localizedDescription)")
                                    }
                                })
                            }
                        }
                    }
                }
            } else {
                DispatchQueue.global().async {
                    if let response = Nexilis.writeAndWait(message: CoreMessage_TMessageBank.getUnBlock(l_pin: param1)) {
                        if response.isOk() {
                            DispatchQueue.main.async {
                                Database.shared.database?.inTransaction({ (fmdb, rollback) in
                                    do {
                                        _ = Database.shared.updateRecord(fmdb: fmdb, table: "BUDDY", cvalues: [
                                            "ex_block" : "0"
                                        ], _where: "f_pin = '\(param1)'")
                                    } catch {
                                        rollback.pointee = true
                                        print("Access database error: \(error.localizedDescription)")
                                    }
                                })
                            }
                        }
                    }
                }
            }
        } else if message.name == "showAlert" {
            guard let dict = message.body as? [String: AnyObject],
                  let param1 = dict["param1"] as? String else {
                return
            }
            self.view.makeToast(param1, duration: 3)
        } else if message.name == "blockUser" {
            guard let dict = message.body as? [String: AnyObject],
                  let param1 = dict["param1"] as? String,
                  let param2 = dict["param2"] as? Bool else {
                return
            }
            if param2 {
                DispatchQueue.global().async {
                    if let response = Nexilis.writeAndWait(message: CoreMessage_TMessageBank.getBlock(l_pin: param1)) {
                        if response.isOk() {
                            DispatchQueue.main.async {
                                Database.shared.database?.inTransaction({ (fmdb, rollback) in
                                    do {
                                        _ = Database.shared.updateRecord(fmdb: fmdb, table: "BUDDY", cvalues: [
                                            "ex_block" : "1"
                                        ], _where: "f_pin = '\(param1)'")
                                    } catch {
                                        rollback.pointee = true
                                        print("Access database error: \(error.localizedDescription)")
                                    }
                                })
                            }
                        }
                    }
                }
            } else {
                DispatchQueue.global().async {
                    if let response = Nexilis.writeAndWait(message: CoreMessage_TMessageBank.getUnBlock(l_pin: param1)) {
                        if response.isOk() {
                            DispatchQueue.main.async {
                                Database.shared.database?.inTransaction({ (fmdb, rollback) in
                                    do {
                                        _ = Database.shared.updateRecord(fmdb: fmdb, table: "BUDDY", cvalues: [
                                            "ex_block" : "0"
                                        ], _where: "f_pin = '\(param1)'")
                                    } catch {
                                        rollback.pointee = true
                                        print("Access database error: \(error.localizedDescription)")
                                    }
                                })
                            }
                        }
                    }
                }
            }
        } else if message.name == "successChangeTheme" {
            guard let dict = message.body as? [String: AnyObject],
                  let param1 = dict["param1"] as? String,
                  let param2 = dict["param2"] as? Bool else {
                return
            }
            Utils.setMyTheme(value: param1)
            Utils.setIsLoadThemeFromOther(value: true)
            Utils.resetValueSuperApp()
            Utils.setLastTabSelected(value: 0)
            if let jsonArray = try! JSONSerialization.jsonObject(with: param1.data(using: String.Encoding.utf8)!, options: JSONSerialization.ReadingOptions()) as? [AnyObject] {
                do {
                    for json in jsonArray {
                        if json["KEY"]  as! String == "app_builder_url_webview_1" {
                            Utils.setURLFirstTab(value: json["VALUE"] as! String)
                        }
                        if json["KEY"]  as! String == "app_builder_url_webview_2" {
                            Utils.setURLThirdTab(value: json["VALUE"] as! String)
                        }
                        if json["KEY"]  as! String == "app_builder_url_webview_3" {
                            Utils.setURLWv3(value: json["VALUE"] as! String)
                        }
                        if json["KEY"]  as! String == "app_builder_url_webview_4" {
                            Utils.setURLWv4(value: json["VALUE"] as! String)
                        }
                        if json["KEY"]  as! String == "app_builder_url_webview_5" {
                            Utils.setURLWv5(value: json["VALUE"] as! String)
                        }
                        if json["KEY"]  as! String == "app_builder_url_webview_6" {
                            Utils.setURLWv6(value: json["VALUE"] as! String)
                        }
                        if json["KEY"]  as! String == "app_builder_url_status_update" {
                            Utils.setURLStatusUpdate(value: json["VALUE"] as! String)
                        }
                        if json["KEY"]  as! String == "app_builder_custom_tab" {
                            Utils.setCustomTab(cust: json["VALUE"] as! String)
                        }
                        if json["KEY"]  as! String == "app_builder_icon_dock" {
                            Utils.setIconDock(value: json["VALUE"] as! String)
                        }
                        if json["KEY"]  as! String == "app_builder_background" {
                            Utils.setBackground(value: json["VALUE"] as! String)
                        }
                        if json["KEY"]  as! String == "app_builder_background_light" {
                            Utils.setBackgroundLight(value: json["VALUE"] as! String)
                        }
                        if json["KEY"]  as! String == "app_builder_background_dark" {
                            Utils.setBackgroundDark(value: json["VALUE"] as! String)
                        }
                        if json["KEY"]  as! String == "app_builder_background_1" {
                            Utils.setBackgroundTab1(value: json["VALUE"] as! String)
                        }
                        if json["KEY"]  as! String == "app_builder_background_2" {
                            Utils.setBackgroundTab2(value: json["VALUE"] as! String)
                        }
                        if json["KEY"]  as! String == "app_builder_background_3" {
                            Utils.setBackgroundTab3(value: json["VALUE"] as! String)
                        }
                        if json["KEY"]  as! String == "app_builder_background_4" {
                            Utils.setBackgroundTab4(value: json["VALUE"] as! String)
                        }
                        if json["KEY"]  as! String == "app_builder_background_5" {
                            Utils.setBackgroundTab5(value: json["VALUE"] as! String)
                        }
                        if json["KEY"]  as! String == "app_builder_background_6" {
                            Utils.setBackgroundTab6(value: json["VALUE"] as! String)
                        }
                        if json["KEY"]  as! String == "access_model" {
                            Utils.setCpaasMode(mode: Int(json["VALUE"] as! String) ?? 0)
                        }
                        if json["KEY"]  as! String == "app_builder_custom_buttons" {
                            Utils.setCustomButtons(value: json["VALUE"] as! String)
                        }
                        if json["KEY"]  as! String == "cpaas_icon" {
                            Utils.setIconDock(value: json["VALUE"] as! String)
                        }
                        if json["KEY"]  as! String == "tab1_icon" {
                            Utils.setTab1Icon(value: json["VALUE"] as! String)
                        }
                        if json["KEY"]  as! String == "tab2_icon" {
                            Utils.setTab2Icon(value: json["VALUE"] as! String)
                        }
                        if json["KEY"]  as! String == "tab3_icon" {
                            Utils.setTab3Icon(value: json["VALUE"] as! String)
                        }
                        if json["KEY"]  as! String == "tab4_icon" {
                            Utils.setTab4Icon(value: json["VALUE"] as! String)
                        }
                        if json["KEY"]  as! String == "tab5_icon" {
                            Utils.setTab5Icon(value: json["VALUE"] as! String)
                        }
                        if json["KEY"]  as! String == "tab6_icon" {
                            Utils.setTab6Icon(value: json["VALUE"] as! String)
                        }
                        if json["KEY"]  as! String == "app_builder_button_icon" {
                            Utils.setButtonIcon(value: json["VALUE"] as! String)
                        }
                        if json["KEY"]  as! String == "reverse_tab_color" {
                            Utils.setReverseTab(value: json["VALUE"] as! String)
                        }
                        if json["KEY"]  as! String == "icon_size" {
                            Utils.setIconDockSize(value: json["VALUE"] as! String)
                        }
                        if json["KEY"]  as! String == "app_id" {
                            changeIconApp(appId: json["VALUE"] as! String)
                        }
                    }
                } catch {
                }
            }
//            Database.shared.database?.inTransaction({ fmdb, rollback in
//                do {
//                    _ = Database.shared.deleteRecord(fmdb: fmdb, table: "GROUPZ", _where: "")
//                    _ = Database.shared.deleteRecord(fmdb: fmdb, table: "GROUPZ_MEMBER", _where: "")
//                    _ = Database.shared.deleteRecord(fmdb: fmdb, table: "DISCUSSION_FORUM", _where: "")
//                    _ = Nexilis.write(message: CoreMessage_TMessageBank.getPostRegistration(p_pin: User.getMyPin() ?? ""))
//                } catch {
//                    rollback.pointee = true
//                    print("Access database error: \(error.localizedDescription)")
//                }
//            })
            let alert = LibAlertController(title: "Successfully changed".localized(), message: "Please open the app again to see the changes".localized(), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK".localized(), style: .default, handler: {(_) in
                exit(0)
            }))
            self.present(alert, animated: true, completion: nil)
        } else if message.name == "finishForm" {
            if self.webView.canGoBack {
                self.webView.goBack()
            } else {
                self.dismiss(animated: true)
            }
        } else if message.name == "shareText" {
            guard let dict = message.body as? [String: AnyObject],
                  let param1 = dict["param1"] as? String else {
                return
            }
            if loadingURL {
                return
            }
            let activityViewController = UIActivityViewController(activityItems: [param1], applicationActivities: nil)
            self.present(activityViewController, animated: true, completion: nil)
        }  else if message.name == "openGalleryiOS" {
            guard let dict = message.body as? [String: AnyObject],
                  let param1 = dict["param1"] as? Int else {
                return
            }
            indexImageVideoWv = param1
            let alertController = LibAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            
            if let action = self.actionImageVideo(for: "image", title: "Choose Photo".localized()) {
                alertController.addAction(action)
            }
            if let action = self.actionImageVideo(for: "video", title: "Choose Video".localized()) {
                alertController.addAction(action)
            }
            alertController.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil))
            self.present(alertController, animated: true)
        }
    }
    
    private func actionImageVideo(for type: String, title: String) -> UIAlertAction? {
        return UIAlertAction(title: title, style: .default) { [unowned self] _ in
            switch type {
            case "image":
                imageVideoPicker.present(source: .imageAlbum)
            case "video":
                imageVideoPicker.present(source: .videoAlbum)
            default:
                imageVideoPicker.present(source: .imageAlbum)
            }
        }
    }
    
    public func didSelect(imagevideo: Any?) {
        if imagevideo != nil {
            let imageData = imagevideo! as! [UIImagePickerController.InfoKey : Any]
            if (imageData[.mediaType] as! String == "public.image") {
                let compressedImage = (imageData[.originalImage] as! UIImage).pngData()!
                let base64String = compressedImage.base64EncodedString()
                let base64ToWeb = "data:image/jpeg;base64,\(base64String)"
                webView.evaluateJavaScript("loadFromMobile('\(base64ToWeb)',\(indexImageVideoWv))") { (result, error) in
                    if let error = error {
                        print("Error executing JavaScript: \(error)")
                    }
                }
            } else {
                guard var dataVideo = try? Data(contentsOf: imageData[.mediaURL] as! URL) else {
                    return
                }
                let sizeOfVideo = Double(dataVideo.count / 1048576)
                if (sizeOfVideo > 10.0) {
                    let compressedURL = NSURL.fileURL(withPath: NSTemporaryDirectory() + UUID().uuidString + ".mp4")
                    compressVideo(inputURL: imageData[.mediaURL] as! URL,
                                  outputURL: compressedURL) { exportSession in
                        guard let session = exportSession else {
                            return
                        }
                        
                        switch session.status {
                        case .unknown:
                            break
                        case .waiting:
                            break
                        case .exporting:
                            break
                        case .completed:
                            guard let compressedData = try? Data(contentsOf: compressedURL) else {
                                return
                            }
                            dataVideo = compressedData
                        case .failed:
                            break
                        case .cancelled:
                            break
                        @unknown default:
                            break
                        }
                    }
                }
                let base64String = dataVideo.base64EncodedString()
                let base64ToWeb = "data:video/mp4;base64,\(base64String)"
                webView.evaluateJavaScript("loadFromMobile('\(base64ToWeb)',\(indexImageVideoWv))") { (result, error) in
                    if let error = error {
                        print("Error executing JavaScript: \(error)")
                    }
                }
            }
        }
    }
    
    func compressVideo(inputURL: URL,
                       outputURL: URL,
                       handler:@escaping (_ exportSession: AVAssetExportSession?) -> Void) {
        let urlAsset = AVURLAsset(url: inputURL, options: nil)
        guard let exportSession = AVAssetExportSession(asset: urlAsset,
                                                       presetName: AVAssetExportPresetMediumQuality) else {
            handler(nil)
            
            return
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.exportAsynchronously {
            handler(exportSession)
        }
    }
    
    func changeIconApp(appId: String) {
        let digisalesKey = "1694457466830"
        let nuKey = "1693550500075"
        let iknKey = "1693542580518"
        let diginetsKey = "1693456149709"
        let biKey = "1692873053159"
        let nxcookKey = "1692863737543"
        let nxsportKey = "1692863037019"
        let bpkhKey = "1711023277251"
        let disiniKey = "1711024221024"
        let gudegKey = "1712052403416"
        let kmiKey = "1713407687550"
        let waKey = "1744166263877"
        if appId == waKey {
            Utils.setIsWATheme(value: true)
        } else {
            Utils.setIsWATheme(value: false)
        }
        switch appId {
        case digisalesKey:
            UIApplication.shared.setAlternateIconName("digisales_icon")
        case nuKey:
            UIApplication.shared.setAlternateIconName("nu_icon")
        case iknKey:
            UIApplication.shared.setAlternateIconName("ikn_icon")
        case diginetsKey:
            UIApplication.shared.setAlternateIconName("diginets_icon")
        case biKey:
            UIApplication.shared.setAlternateIconName("bi_icon")
        case nxcookKey:
            UIApplication.shared.setAlternateIconName("nxcook_icon")
        case nxsportKey:
            UIApplication.shared.setAlternateIconName("nxsport_icon")
        case bpkhKey:
            UIApplication.shared.setAlternateIconName("bpkh_icon")
        case disiniKey:
            UIApplication.shared.setAlternateIconName("disini_icon")
        case gudegKey:
            UIApplication.shared.setAlternateIconName("gudeg_icon")
        case kmiKey:
            UIApplication.shared.setAlternateIconName("kmi_icon")
        default:
            UIApplication.shared.setAlternateIconName(nil)
        }
    }
    
    func setupSpeech() {

        self.speechRecognizer?.delegate = self

        SFSpeechRecognizer.requestAuthorization { (authStatus) in

            var isButtonEnabled = false

            switch authStatus {
            case .authorized:
                isButtonEnabled = true

            case .denied:
                isButtonEnabled = false
                //print("User denied access to speech recognition")

            case .restricted:
                isButtonEnabled = false
                //print("Speech recognition restricted on this device")

            case .notDetermined:
                isButtonEnabled = false
                //print("Speech recognition not yet authorized")
            @unknown default:
                isButtonEnabled = false
            }

            OperationQueue.main.addOperation() {
                self.isAllowSpeech = isButtonEnabled
                if isButtonEnabled {
                    SecureUserDefaults.shared.set(isButtonEnabled, forKey: "allowSpeech")
                    self.runVoice()
                }
            }
        }
    }
    
    func runVoice() {
        if !audioEngine.isRunning {
            alertController = LibAlertController(title: "Start Recording".localized(), message: "Say something, I'm listening!".localized(), preferredStyle: .alert)
            self.present(alertController, animated: true)
            self.webView.evaluateJavaScript("toggleVoiceButton(true)")
            self.startRecording()
        }
    }
    
    func startRecording() {

        // Clear all previous session data and cancel task
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }

        // Create instance of audio session to record voice
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSession.Category.record, mode: .default, options: [])
            try audioSession.setMode(AVAudioSession.Mode.measurement)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            //print("audioSession properties weren't set because of an error.")
        }

        self.recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

        let inputNode = audioEngine.inputNode

        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }

        recognitionRequest.shouldReportPartialResults = true

        self.recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in

            var isFinal = false
            var text = ""

            if result != nil {
                text = result?.bestTranscription.formattedString ?? ""
                isFinal = (result?.isFinal)!
                self.alertController.dismiss(animated: true)
                self.audioEngine.stop()
                self.recognitionRequest?.endAudio()
            } else {
                self.alertController.dismiss(animated: true)
            }

            if error != nil || isFinal {
                if error == nil {
                    self.webView.evaluateJavaScript("toggleVoiceButton(false)")
                    self.webView.evaluateJavaScript("submitVoiceSearch('\(text)')")
                } else {
                    self.audioEngine.stop()
                    self.recognitionRequest?.endAudio()
                }
                inputNode.removeTap(onBus: 0)

                self.recognitionRequest = nil
                self.recognitionTask = nil

                self.isAllowSpeech = true
            }
        })

        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }

        self.audioEngine.prepare()

        do {
            try self.audioEngine.start()
        } catch {
            //print("audioEngine couldn't start because of an error.")
        }
    }
    
    @objc func reloadWebView(_ sender: UIRefreshControl) {
        webView.reload()
        sender.endRefreshing()
    }
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping @MainActor (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
//            print("return 0")
            decisionHandler(.cancel)
            return
        }
        
        if let scheme = url.scheme?.lowercased(), scheme.hasPrefix("itms") || scheme == "mailto" || scheme == "tel" {
            DispatchQueue.main.async {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
//            print("return 1 \(url.absoluteString)")
            decisionHandler(.cancel)
            return
        }

        guard navigationAction.targetFrame?.isMainFrame == true else {
            decisionHandler(.allow)
//            print("return 2 \(url.absoluteString)")
            return
        }

        if loadingURL {
            decisionHandler(.cancel)
//            print("return 3 \(url.absoluteString)")
            return
        }

        loadingURL = true

        if allowedURLs.contains(url.absoluteString) {
            loadingURL = false
            decisionHandler(.allow)
//            print("return 4 \(url.absoluteString)")
            return
        }
        
        validateSSLCertificate(url: url) { [weak self] isValid in
            guard let self = self else {
//                print("return 5 \(url.absoluteString)")
                decisionHandler(.cancel)
                return
            }

            DispatchQueue.main.async {
                if isValid {
                    self.allowedURLs.insert(url.absoluteString)
                    self.loadingURL = false
//                    print("return 6 \(url.absoluteString)")
                    decisionHandler(.allow)
                } else {
                    let host = url.host ?? ""
                    var messageText = "You're about to access a website that is not currently trusted by your Nexilis Browser. This website's security certificate is not recognized.\n\nDo you wish to proceed to <<domain>> and trust the website's security certificate?\n\nNote: Adding a website to the trusted list may increase your risk of security vulnerability".localized()
                    messageText = messageText.replacingOccurrences(of: "<<domain>>", with: host)

                    let alert = UIAlertController(title: "Warning Unknown Url!".localized(),
                                                  message: messageText,
                                                  preferredStyle: .alert)

                    alert.addAction(UIAlertAction(title: "Yes", style: .default) { _ in
                        let storedCertificate = Utils.getCertificatePinningWebview()
                        if let jsonData = storedCertificate.data(using: .utf8),
                           let certJson = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: String] {
                            var certJson = certJson
                            certJson[host] = self.blockedCertificate
                            if let jsonData = try? JSONSerialization.data(withJSONObject: certJson, options: []),
                               let jsonString = String(data: jsonData, encoding: .utf8) {
                                Utils.setCertificatePinningWebview(value: jsonString)
                            }
                        }

                        self.allowedURLs.insert(url.absoluteString)
                        self.loadingURL = false
                        decisionHandler(.allow)
                    })

                    alert.addAction(UIAlertAction(title: "No", style: .cancel) { _ in
                        self.loadingURL = false
                        decisionHandler(.cancel)
                    })

                    if self.presentedViewController == nil {
                        self.present(alert, animated: true, completion: nil)
                    } else {
                        self.loadingURL = false
//                        print("return 7 \(url.absoluteString)")
                        decisionHandler(.cancel)
                    }
                }
            }
        }
    }
    
    private func validateSSLCertificate(url: URL, completion: @escaping (Bool) -> Void) {
        let session = URLSession(configuration: .ephemeral, delegate: self, delegateQueue: nil)
        let request = URLRequest(url: url)

        let task = session.dataTask(with: request) { _, response, error in
            if let error = error {
                completion(false)
                return
            }
            completion(true)
        }
        task.resume()
    }
}

extension BNIBookingWebView: URLSessionDelegate {
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        if let publicKeyHash = extractPublicKeyHash(from: serverTrust) {
            let domain = challenge.protectionSpace.host
            let storedCertificate = Utils.getCertificatePinningWebview()
            if let jsonData = storedCertificate.data(using: .utf8),
               let certJson = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: String] {
                if publicKeyHash == certJson[domain] {
                    completionHandler(.useCredential, URLCredential(trust: serverTrust))
                } else {
                    blockedCertificate = publicKeyHash
                    completionHandler(.cancelAuthenticationChallenge, nil)
                }
            }
        } else {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
    
    func extractPublicKeyHash(from serverTrust: SecTrust) -> String? {
        guard let certificate = SecTrustGetCertificateAtIndex(serverTrust, 0) else { return nil }
        guard let publicKey = SecCertificateCopyKey(certificate) else { return nil }
        
        var error: Unmanaged<CFError>?
        guard let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, &error) as Data? else {
            return nil
        }
        
        // Compute SHA-256 hash
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        publicKeyData.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(publicKeyData.count), &hash)
        }
        
        let hashData = Data(hash)
        let base64Hash = hashData.base64EncodedString()
        
        return base64Hash
    }
}
