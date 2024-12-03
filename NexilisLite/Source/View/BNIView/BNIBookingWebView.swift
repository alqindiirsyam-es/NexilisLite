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

public class BNIBookingWebView: UIViewController, WKNavigationDelegate, UIScrollViewDelegate, UIGestureRecognizerDelegate, WKScriptMessageHandler, SFSpeechRecognizerDelegate {
    var webView = WKWebView()
    let closeButton = UIButton()
    public var customUrl = ""
    
    var isAllowSpeech = false
    
    let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "id"))

    var recognitionRequest : SFSpeechAudioBufferRecognitionRequest?
    var recognitionTask : SFSpeechRecognitionTask?
    let audioEngine = AVAudioEngine()
    var alertController = LibAlertController()
    
    public override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        let customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.5 Mobile/15E148 Safari/604.1 \(Utils.getUserAgent())"
        let finalUserAgent = "\(customUserAgent)"
        configuration.applicationNameForUserAgent = finalUserAgent
        webView = WKWebView(frame: .zero, configuration: configuration)
        
        view.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
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
        stringQMS = stringQMS + "&lang=\(intLang)&theme=\(self.traitCollection.userInterfaceStyle == .dark ? "0" : "1")"
        let url = URL(string: "\(stringQMS)")!
        loadURLWithCookie(url: url)
    }
    
    func loadURLWithCookie(url: URL) {
        var urlRequest = URLRequest(url: url)
        let cookieHeader = Utils.getCookiesMobile()
        urlRequest.addValue(cookieHeader, forHTTPHeaderField: "Cookie")
        let customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.5 Mobile/15E148 Safari/604.1 \(Utils.getUserAgent())"
        urlRequest.setValue(customUserAgent, forHTTPHeaderField: "User-Agent")
        
        if let cookies = HTTPCookieStorage.shared.cookies {
            for cookie in cookies {
                webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie)
            }
        }
        webView.load(urlRequest)
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
            showToast(message: param1, controller: self.tabBarController!)
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
            Database.shared.database?.inTransaction({ fmdb, rollback in
                do {
                    _ = Database.shared.deleteRecord(fmdb: fmdb, table: "GROUPZ", _where: "")
                    _ = Database.shared.deleteRecord(fmdb: fmdb, table: "GROUPZ_MEMBER", _where: "")
                    _ = Database.shared.deleteRecord(fmdb: fmdb, table: "DISCUSSION_FORUM", _where: "")
                    _ = Nexilis.write(message: CoreMessage_TMessageBank.getPostRegistration(p_pin: User.getMyPin() ?? ""))
                } catch {
                    rollback.pointee = true
                    print("Access database error: \(error.localizedDescription)")
                }
            })
            let alert = LibAlertController(title: "Successfully changed".localized(), message: "Please open the app again to see the changes".localized(), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK".localized(), style: .default, handler: {(_) in
                exit(0)
            }))
            self.present(alert, animated: true, completion: nil)
        }  else if message.name == "finishForm" {
            if self.webView.canGoBack {
                self.webView.goBack()
            } else {
                self.dismiss(animated: true)
            }
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
    
    public func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            let credential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
            completionHandler(.useCredential, credential)
        }
        else {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}
