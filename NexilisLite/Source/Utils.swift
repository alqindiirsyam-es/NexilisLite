//
//  Utils.swift
//  Runner
//
//  Created by Rifqy Fakhrul Rijal on 13/08/20.
//  Copyright © 2020 The Chromium Authors. All rights reserved.
//

import Foundation
import UIKit
import NotificationBannerSwift
import nuSDKService
import CoreLocation
import CryptoKit
import LocalAuthentication
import AVFoundation
import AVKit
import PDFKit
import SDWebImage
//import var CommonCrypto.CC_MD5_DIGEST_LENGTH
//import func CommonCrypto.CC_MD5
//import typealias CommonCrypto.CC_LONG

public final class Utils {
    public static let M_USER_ANDROID_ID = "UNK"
    public static let CPAAS_VERSION = "UCPaaS-Nexilis.\(Nexilis.cpaasVersion)"
    
    public static func getCurrentTime()->Int64 {
        return Int64(Date().timeIntervalSince1970)
    }
    
    public static func getCurrentTimeMillis()->Int64 {
        return Int64(Date().timeIntervalSince1970 * 1000)
    }
    
    public static func getCurrentTimeNanos()->Int64 {
        return Int64(Date().timeIntervalSince1970 * 1000_000_000)
    }
    
    public static func getElapsedRealtime() -> Int64 {
        return Int64((ProcessInfo().systemUptime).rounded()) // SystemClock.elapsedRealtime();
    }
    
    public static func getElapsedRealtimeMillis() -> Int64 {
        return Int64((ProcessInfo().systemUptime * 1000).rounded()) // SystemClock.elapsedRealtime();
    }
    
    public static func getElapsedRealtimeNanos() -> Int64 {
        return Int64((ProcessInfo().systemUptime * 1000_000_000).rounded()) // SystemClock.elapsedRealtimeNano();
    }
    
    public static func getForceAnonymous() -> Bool {
        if let value: Bool = SecureUserDefaults.shared.value(forKey: "force_anonymous") {
            return value
        }
        return false
    }
    
    public static func setForceAnonymous(value: Bool){
        SecureUserDefaults.shared.set(value, forKey: "force_anonymous")
    }
    
    public static func getSetProfile() -> Bool {
        if let value: Bool = SecureUserDefaults.shared.value(forKey: "is_change_profile") {
            return value
        }
        return false
    }
    
    public static func setProfile(value: Bool){
        SecureUserDefaults.shared.set(value, forKey: "is_change_profile")
    }
    
    static func setIconCenter(value: String){
        SecureUserDefaults.shared.set(value, forKey: "pb_fb_icon_center_self")
    }
    
    static func getIconCenter() -> String {
        if let value: String = SecureUserDefaults.shared.value(forKey: "pb_fb_icon_center_self") {
            return value
        }
        return ""
    }
    
    static func setIconCenterAnim2(value: String){
        SecureUserDefaults.shared.set(value, forKey: "pb_fb_icon_center_self_mode2")
    }
    
    static func getIconCenterAnim2() -> String {
        if let value: String = SecureUserDefaults.shared.value(forKey: "pb_fb_icon_center_self_mode2") {
            return value
        }
        return ""
    }
    
    static func setIconCenterAnim4(value: String){
        SecureUserDefaults.shared.set(value, forKey: "pb_fb_icon_center_self_mode4")
    }
    
    static func getIconCenterAnim4() -> String {
        if let value: String = SecureUserDefaults.shared.value(forKey: "pb_fb_icon_center_self_mode4") {
            return value
        }
        return ""
    }
    
    static func setURLFirstTab(value: String) {
        SecureUserDefaults.shared.set(value, forKey: "app_builder_url_first_tab")
    }
    
    static func setURLThirdTab(value: String) {
        SecureUserDefaults.shared.set(value, forKey: "app_builder_url_third_tab")
    }
    
    static func setURLStatusUpdate(value: String) {
        SecureUserDefaults.shared.set(value, forKey: "app_builder_url_status_update")
    }
    
    static func setURLBase(value: String) {
        SecureUserDefaults.shared.set(value, forKey: "app_builder_url_base")
    }
    
    static func setURLQMS(value: String) {
        SecureUserDefaults.shared.set(value, forKey: "app_builder_url_qms")
    }
    
    static func setIconDock(value: String) {
        SecureUserDefaults.shared.set(value, forKey: "app_builder_icon_dock")
    }
    
    static func setIconSS(value: String) {
        SecureUserDefaults.shared.set(value, forKey: "app_builder_icon_ss")
    }
    
    static func setBackground(value: String) {
        SecureUserDefaults.shared.set(value, forKey: "app_builder_background")
    }
    
    static func setURLPrivacyPolicy(value: String){
        SecureUserDefaults.shared.set(value, forKey: "app_builder_url_privacy_policy")
    }
    
    static func setEnablePrivacyPolicy(value: Bool){
        SecureUserDefaults.shared.set(value, forKey: "app_builder_enable_privacy_policy")
    }
    
    static func setCustomTab(cust: String){
        SecureUserDefaults.shared.set(cust, forKey: "custom_tab")
    }
    
    static func setACTheme(value: String){
        SecureUserDefaults.shared.set(value, forKey: "app_builder_ac_theme")
    }
    
    static func setButtonURL(value: String){
        SecureUserDefaults.shared.set(value, forKey: "app_builder_button_url")
    }
    
    static func setCustomButtons(value: String){
        SecureUserDefaults.shared.set(value, forKey: "app_builder_custom_buttons")
    }
    
    public static func getCustomButtons() -> String {
        if let value: String = SecureUserDefaults.shared.value(forKey: "app_builder_custom_buttons") {
            return value
        }
        return ""
    }
    
    static func setCustomFBIcon(value: String){
        SecureUserDefaults.shared.set(value, forKey: "app_builder_button_icon")
    }
    
    static func getCustomFBIcon() -> String {
        if let value: String = SecureUserDefaults.shared.value(forKey: "app_builder_button_icon") {
            return value
        }
        return ""
    }
    
    static func setEnableMobileBuilder(value: String){
        SecureUserDefaults.shared.set(value, forKey: "app_builder_enable_mobile_builder")
    }
    public static func getEnableMobileBuilder() -> String {
        if let value: String = SecureUserDefaults.shared.value(forKey: "app_builder_enable_mobile_builder") {
            return value
        }
        return "0"
    }
    
    static func setFinishInitPrefs(value: Bool){
        SecureUserDefaults.shared.set(value, forKey: "finish_init_prefs")
    }
    
    public static func getFinishInitPrefsr() -> Bool {
        if let value: Bool = SecureUserDefaults.shared.value(forKey: "finish_init_prefs") {
            return value
        }
        return false
    }
    
    static func setConfigModeFB(value: String) {
        SecureUserDefaults.shared.set(value, forKey: "fb_config_mode")
    }
    
    static func getConfigModeFB() -> String {
        if let value: String = SecureUserDefaults.shared.value(forKey: "fb_config_mode") {
            return value
        }
        return "1"
    }
    
    static func setAfterConfigFB(value: Bool) {
        SecureUserDefaults.shared.set(value, forKey: "after_fb_config_mode")
    }
    
    static func getAfterConfigFB() -> Bool {
        if let value: Bool = SecureUserDefaults.shared.value(forKey: "after_fb_config_mode") {
            return value
        }
        return false
    }
    
    static func setCookiesMobile(value: String) {
        SecureUserDefaults.shared.set(value, forKey: "cookies_mobile")
    }

    public static func getCookiesMobile() -> String {
        if let value: String = SecureUserDefaults.shared.value(forKey: "cookies_mobile") {
            return value
        }
        return ""
    }
    
    static func setCookiesMobileForStorage(value: String) {
        SecureUserDefaults.shared.set(value, forKey: "cookies_mobile_storage")
    }

    public static func getCookiesMobileForStorage() -> String {
        if let value: String = SecureUserDefaults.shared.value(forKey: "cookies_mobile_storage") {
            return value
        }
        return ""
    }
    
    static func getBackground() -> String {
        if let value: String = SecureUserDefaults.shared.value(forKey: "app_builder_background") {
            return value
        }
        return ""
    }
    
    static func setBackgroundLight(value: String) {
        SecureUserDefaults.shared.set(value, forKey: "app_builder_background_light")
    }

    static func getBackgroundLight() -> String {
        if let value: String = SecureUserDefaults.shared.value(forKey: "app_builder_background_light") {
            return value
        }
        return ""
    }
    
    static func setBackgroundDark(value: String) {
        SecureUserDefaults.shared.set(value, forKey: "app_builder_background_dark")
    }

    static func getBackgroundDark() -> String {
        if let value: String = SecureUserDefaults.shared.value(forKey: "app_builder_background_dark") {
            return value
        }
        return ""
    }
    
    static func setMaxRetryUpload(value: String) {
        SecureUserDefaults.shared.set(value, forKey: "max_retry_upload")
    }

    static func getMaxRetryUpload() -> String {
        if let value: String = SecureUserDefaults.shared.value(forKey: "max_retry_upload") {
            return value
        }
        return "5"
    }
    
    static func setAuthenticationDuration(value: String) {
        SecureUserDefaults.shared.set(value, forKey: "authentication_duration")
    }

    static func getAuthenticationDuration() -> String {
        if let value: String = SecureUserDefaults.shared.value(forKey: "authentication_duration") {
            return value
        }
        return ""
    }
    
    static func setMaxRetryTimeUpload(value: String) {
        SecureUserDefaults.shared.set(value, forKey: "max_retry_time_upload")
    }

    static func getMaxRetryTimeUpload() -> String {
        if let value: String = SecureUserDefaults.shared.value(forKey: "max_retry_time_upload") {
            return value
        }
        return "60000"
    }
    
    static func setWhatsappCenter(value: String) {
        SecureUserDefaults.shared.set(value, forKey: "whatsapp_center")
    }

    static func getWhatsappCenter() -> String {
        if let value: String = SecureUserDefaults.shared.value(forKey: "whatsapp_center") {
            return value
        }
        return "08115881946"
    }
    
    static func setSMSCenter(value: String) {
        SecureUserDefaults.shared.set(value, forKey: "sms_center")
    }

    static func getSMSCenter() -> String {
        if let value: String = SecureUserDefaults.shared.value(forKey: "sms_center") {
            return value
        }
        return "081290009799"
    }
    
    static func setCallCenter(value: String) {
        SecureUserDefaults.shared.set(value, forKey: "call_center")
    }

    static func getCallCenter() -> String {
        if let value: String = SecureUserDefaults.shared.value(forKey: "call_center") {
            return value
        }
        return "1500046"
    }
    
    static func setValidTrans(value: String) {
        SecureUserDefaults.shared.set(value, forKey: "enable_valid_trans")
    }

    static func getValidTrans() -> String {
        if let value: String = SecureUserDefaults.shared.value(forKey: "enable_valid_trans") {
            return value
        }
        return "0"
    }
    
    static func setFeatureAccess(value: String) {
        SecureUserDefaults.shared.set(value, forKey: "pb_feature_access")
    }

    static func getFeatureAccess() -> String {
        if let value: String = SecureUserDefaults.shared.value(forKey: "pb_feature_access") {
            return value
        }
        return ""
    }
    
    static func setFeatureAccessAlert(value: String) {
        SecureUserDefaults.shared.set(value, forKey: "pb_feature_access_alert")
    }

    static func getFeatureAccessAlert() -> String {
        if let value: String = SecureUserDefaults.shared.value(forKey: "pb_feature_access_alert") {
            return value
        }
        return ""
    }
    static func setChatbotGreetings(value: String) {
        SecureUserDefaults.shared.set(value, forKey: "chatbot_greetings")
    }

    static func getChatbotGreetings() -> String {
        if let value: String = SecureUserDefaults.shared.value(forKey: "chatbot_greetings") {
            return value
        }
        return "Welcome..."
    }
    
    
    public static func sGetCurrentDateTime(sFormat: String!) -> String! {
        let todaysDate = NSDate()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = sFormat
        return dateFormatter.string(from: todaysDate as Date)
    }
    
    public static func setCertificatePinningWebview(value: String) {
        SecureUserDefaults.shared.set(value, forKey: "pb_certificate_pinning_webview")
    }

    public static func getCertificatePinningWebview() -> String {
        if let value: String = SecureUserDefaults.shared.value(forKey: "pb_certificate_pinning_webview") {
            return value
        }
        return ""
    }

    // Fix: the hardcoded default pin used to only ever get written once
    // (`if getCertificatePinningWebview().isEmpty`). That meant any device that had
    // already run the app even a single time kept whatever value was seeded back
    // then FOREVER - a corrected/updated default in a later app version would never
    // reach existing installs. This version counter lets `connect()` detect "the
    // hardcoded default changed since what's on this device" and force a refresh,
    // without needing to wipe the user's other stored settings.
    public static func setCertificatePinningSeedVersion(_ version: Int) {
        SecureUserDefaults.shared.set(version, forKey: "pb_certificate_pinning_seed_version")
    }

    public static func getCertificatePinningSeedVersion() -> Int {
        return SecureUserDefaults.shared.value(forKey: "pb_certificate_pinning_seed_version") ?? 0
    }
    
    public static func setWhitelistFileExt(value: String) {
        SecureUserDefaults.shared.set(value, forKey: "pb_whitelist_file_ext")
    }

    public static func getWhitelistFileExt() -> String {
        if let value: String = SecureUserDefaults.shared.value(forKey: "pb_whitelist_file_ext") {
            return value
        }
        return ""
    }
    
    public static func setUserMSISDN(value: String) {
        SecureUserDefaults.shared.set(value, forKey: "pb_user_msisdn")
    }

    public static func getUserMSISDN() -> String {
        if let value: String = SecureUserDefaults.shared.value(forKey: "pb_user_msisdn") {
            return value
        }
        return ""
    }
    
    public static func setAcceptDisclaimerConsentMic(value: Bool) {
        SecureUserDefaults.shared.set(value, forKey: "accept_disclaimer_consent_mic")
    }

    public static func acceptDisclaimerConsentMic() -> Bool {
        if let value: Bool = SecureUserDefaults.shared.value(forKey: "accept_disclaimer_consent_mic") {
            return value
        }
        return false
    }
    
    public static func setAcceptDisclaimerConsentCamera(value: Bool) {
        SecureUserDefaults.shared.set(value, forKey: "accept_disclaimer_consent_camera")
    }

    public static func acceptDisclaimerConsentCamera() -> Bool {
        if let value: Bool = SecureUserDefaults.shared.value(forKey: "accept_disclaimer_consent_camera") {
            return value
        }
        return false
    }
    
//    public static func getMD5(string: String) -> Data {
//        let length = Int(CC_MD5_DIGEST_LENGTH)
//        let messageData = string.data(using:.utf8)!
//        var digestData = Data(count: length)
//
//        _ = digestData.withUnsafeMutableBytes { digestBytes -> UInt8 in
//            messageData.withUnsafeBytes { messageBytes -> UInt8 in
//                if let messageBytesBaseAddress = messageBytes.baseAddress, let digestBytesBlindMemory = digestBytes.bindMemory(to: UInt8.self).baseAddress {
//                    let messageLength = CC_LONG(messageData.count)
//                    CC_MD5(messageBytesBaseAddress, messageLength, digestBytesBlindMemory)
//                }
//                return 0
//            }
//        }
//        return digestData
//    }
    
    public static let callDurationFormatter: DateComponentsFormatter = {
        let dateFormatter: DateComponentsFormatter
        dateFormatter = DateComponentsFormatter()
        dateFormatter.unitsStyle = .positional
        dateFormatter.allowedUnits = [.minute, .second]
        dateFormatter.zeroFormattingBehavior = .pad
        
        return dateFormatter
    }()
    
    static func getGreetingsTimeDefaultWelcome() -> String {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        let minute = calendar.component(.minute, from: Date())
        var time: String

        if hour < 10 || (hour == 10 && minute <= 0) {
            time = "1"
        } else if hour < 15 || (hour == 15 && minute <= 0) {
            time = "2"
        } else {
            time = "3"
        }
        
        return time
    }
    
    public static func previewMessageText(chat: Chat) -> Any {
        if chat.credential == "1" && chat.lock == "2" {
            return ("🚫 _"+"Message has expired".localized()+"_").richText(group_id: chat.pin)
        } else if chat.messageScope == MessageScope.CALL || chat.messageScope == MessageScope.MISSED_CALL {
            let imageAttachment = NSTextAttachment()
            var stringImage = ""
            let isVideo = chat.messageText.lowercased().contains("video")
            let type = chat.messageText.lowercased().contains("incoming") ? "1" : chat.messageText.lowercased().contains("outgoing") ? "2" : "3"
            var textPreview = ""
            if isVideo && type == "2" {
                stringImage = "arrow.up.right.video.fill"
                textPreview = "Video call".localized()
            } else if !isVideo && type == "2" {
                stringImage = "phone.fill.arrow.up.right"
                textPreview = "Audio call".localized()
            } else if isVideo {
                stringImage = "arrow.down.left.video.fill"
                textPreview = type == "3" ? "Missed video call".localized() : "Video call".localized()
            } else {
                stringImage = "phone.fill.arrow.down.left"
                textPreview = type == "3" ? "Missed audio call".localized() : "Audio call".localized()
            }
            if let image = UIImage(systemName: stringImage)?.withRenderingMode(.alwaysTemplate) {
                let imageView = UIImageView(image: image)
                if type == "3" {
                    imageView.tintColor = .red
                } else {
                    imageView.tintColor = .gray
                }
                
                // Render the UIImageView to UIImage with tint applied
                UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, false, 0.0)
                imageView.layer.render(in: UIGraphicsGetCurrentContext()!)
                let tintedImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                
                imageAttachment.image = tintedImage
            }

            let imageSize = CGSize(width: 18, height: 18)
            imageAttachment.bounds = CGRect(x: 0, y: -2, width: isVideo ? imageSize.width + 8 : imageSize.width, height: imageSize.height)

            let imageString = NSAttributedString(attachment: imageAttachment)
            let textString = NSAttributedString(string: " " + textPreview, attributes: [
                .font: UIFont.systemFont(ofSize: 14 + String.offset()),
                .foregroundColor: UIColor.gray
            ])
            
            let finalString = NSMutableAttributedString()
            finalString.append(imageString)
            finalString.append(textString)
            
            return finalString
        } else if chat.credential == "1" {
            return showNSMutableAttributedString("Confidential Message".localized())
        } else if chat.attachmentFlag == "27" {
            return showNSMutableAttributedString(("📄 " + "Live Streaming".localized()))
        } else if chat.attachmentFlag == "61" {
            let textName = chat.messageText.components(separatedBy: "~")[0]
            let textAfterName = chat.messageText.component(1, separatedBy: "~")
            return (textName + " " + textAfterName.localized()).richText(group_id: chat.pin)
        } else if chat.attachmentFlag == "26" {
            return showNSMutableAttributedString(("📄 " + "Seminar".localized()))
        } else if chat.attachmentFlag == "25" {
            return showNSMutableAttributedString("📄 " + "Video Conference Room".localized())
        } else if !chat.audio.isEmpty {
            // A voice note says what it is and how long it runs; an ordinary audio attachment is
            // just audio, and the flag it travelled under is what tells the two apart.
            if chat.attachmentFlag == "60" {
                let mic = NSTextAttachment()
                mic.image = UIImage(systemName: "mic.fill")?.withTintColor(.gray, renderingMode: .alwaysOriginal)
                mic.bounds = CGRect(x: 0, y: -2, width: 13, height: 15)
                var text = "Voice Message".localized()
                if let seconds = AudioDurationStore.seconds(forFileNamed: chat.audio) {
                    text += String(format: " (%d:%02d)", seconds / 60, seconds % 60)
                }
                let line = NSMutableAttributedString(attachment: mic)
                line.append(NSAttributedString(string: " " + text, attributes: [
                    .font: UIFont.systemFont(ofSize: 12 + String.offset()),
                    .foregroundColor: UIColor.gray
                ]))
                return line
            }
            return showNSMutableAttributedString(("♫ " + "Audio".localized()))
        } else if !chat.image.isEmpty {
            if !chat.messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return "📷 \(chat.messageText)".richText(group_id: chat.pin)
            } else {
                return showNSMutableAttributedString(("📷 " + "Photo".localized()))
            }
        }
        else if !chat.gif.isEmpty {
            if !chat.messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return "🎬 \(chat.messageText)".richText(group_id: chat.pin)
            } else {
                return showNSMutableAttributedString("🎬 GIF")
            }
        }
        else if !chat.video.isEmpty {
            if !chat.messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return "📹 \(chat.messageText)".richText(group_id: chat.pin)
            } else {
                return showNSMutableAttributedString(("📹 " + "Video".localized()))
            }
        }
        else if !chat.file.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            if chat.messageScope == "18" {
                return showNSMutableAttributedString(("📄 Form"))
            }
            let nameFile = chat.messageText.components(separatedBy: "|")[0]
            let dataText = chat.messageText.component(1, separatedBy: "|")
            if !dataText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return ("📄 " + dataText).richText(group_id: chat.pin)
            }
            return showNSMutableAttributedString(("📄 \(nameFile)"))
        } else if chat.attachmentFlag == "11" {
            return showNSMutableAttributedString(("❤️ " + "Sticker".localized()))
        }
        else {
            return chat.messageText.richText(group_id: chat.pin)
        }
    }
    
    private static func showNSMutableAttributedString(_ text: String) -> NSMutableAttributedString {
        let font = UIFont.systemFont(ofSize: 12 + String.offset())
        return NSMutableAttributedString(string: text, attributes: [NSAttributedString.Key.font: font])
    }
    
    static func getURLBase() -> String {
        if let value: String = SecureUserDefaults.shared.value(forKey: "app_builder_url_base") {
            return value
        }
        return "https://nexilis.io/"
    }
    
    public static func getIconDock() -> String {
        if let value: String = SecureUserDefaults.shared.value(forKey: "app_builder_icon_dock") {
            return value
        }
        return ""
    }
    
    public static func getUrlDock() -> String? {
        return Utils.getURLBase() + "get_file_from_path?img=" + Utils.getIconDock()
    }
    
    static func setDefaultCC(value: String){
        SecureUserDefaults.shared.set(value, forKey: "default_cc")
    }
    
    static func getDefaultCC() -> String? {
        if let value: String = SecureUserDefaults.shared.value(forKey: "default_cc") {
            return value
        }
        return nil
    }
    
    static func setFloatingAnim(value: String){
        SecureUserDefaults.shared.set(value, forKey: "fb_floating_anim")
    }
    
    static func getFloatingAnim() -> String {
        if let value: String = SecureUserDefaults.shared.value(forKey: "fb_floating_anim") {
            return value
        }
        return "1~1"
    }
    
    static func setFBIconBg(value: String){
        SecureUserDefaults.shared.set(value, forKey: "fb_icon_with_bg")
    }
    
    static func getFBIconBg() -> String {
        if let value: String = SecureUserDefaults.shared.value(forKey: "fb_icon_with_bg") {
            return value
        }
        return "0"
    }
    
    static func setHistoryPullFB(value: String){
        SecureUserDefaults.shared.set(value, forKey: "history_pull_fb")
    }
    
    static func getHistoryPullFB() -> String {
        if let value: String = SecureUserDefaults.shared.value(forKey: "history_pull_fb") {
            return value
        }
        return ""
    }
    
    static func setFBItemBg(value: String){
        SecureUserDefaults.shared.set(value, forKey: "fb_item_with_bg")
    }
    
    static func getFBItemBg() -> String {
        if let value: String = SecureUserDefaults.shared.value(forKey: "fb_item_with_bg") {
            return value
        }
        return "1"
    }
    
    static func setBEId(value: String){
        SecureUserDefaults.shared.set(value, forKey: "be_id")
    }
    
    static func getBEId() -> String {
        if let value: String = SecureUserDefaults.shared.value(forKey: "be_id") {
            return value
        }
        return ""
    }
    
    static func setDomainOpr(value: String){
        SecureUserDefaults.shared.set(value, forKey: "domain_opr")
    }
    
    public static func getDomainOpr() -> String {
        if let value: String = SecureUserDefaults.shared.value(forKey: "domain_opr") {
            return value
        }
        return "https://nexilis.io/"
    }
    
    static func setIpPortOpr(value: String){
        SecureUserDefaults.shared.set(value, forKey: "ip_opr")
    }
    
    static func getIpOpr() -> String {
        if let value: String = SecureUserDefaults.shared.value(forKey: "ip_opr") {
            return value
        }
        return "34.101.172.194:42823"
    }
    
    static func setHarcodedIp(value: String){
        SecureUserDefaults.shared.set(value, forKey: "harcoded_ip")
    }
    
    static func getHarcodedIp() -> String {
        if let value: String = SecureUserDefaults.shared.value(forKey: "harcoded_ip") {
            return value
        }
        return ""
    }
    
    static func setUserAgent(value: String){
        SecureUserDefaults.shared.set(value, forKey: "user_agent")
    }
    
    public static func getUserAgent() -> String {
        if let value: String = SecureUserDefaults.shared.value(forKey: "user_agent") {
            return value
        }
        return "easySoftIndonesia"
    }
    
    public static func setSecureFolderEncrypt(value: String){
        SecureUserDefaults.shared.set(value, forKey: "secure_folder_encrypt_key")
    }
    
    public static func getSecureFolderEncrypt() -> String {
        if let value: String = SecureUserDefaults.shared.value(forKey: "secure_folder_encrypt_key") {
            return value
        }
        return ""
    }
    
    public static func setSecureFolderEncryptIv(value: String){
        SecureUserDefaults.shared.set(value, forKey: "secure_folder_encrypt_key_iv")
    }
    
    public static func getSecureFolderEncryptIv() -> String {
        if let value: String = SecureUserDefaults.shared.value(forKey: "secure_folder_encrypt_key_iv") {
            return value
        }
        return ""
    }
    
    public static func setSecureFolderOffline(value: String){
        SecureUserDefaults.shared.set(value, forKey: "secure_folder_offline")
    }
    
    public static func getSecureFolderOffline() -> String {
        if let value: String = SecureUserDefaults.shared.value(forKey: "secure_folder_offline") {
            return value
        }
        return "0"
    }
    
    public static func setTOTPSecret(value: String) {
        SecureUserDefaults.shared.set(value, forKey: "totp_secret")
    }

    public static func getTOTPSecret() -> String? {
        if let value: String = SecureUserDefaults.shared.value(forKey: "totp_secret") {
            return value
        }
        return nil
    }
    
    public static func setEnableTOTP(value: String) {
        SecureUserDefaults.shared.set(value, forKey: "enable_totp")
    }
    
    public static func getEnableTOTP() -> String {
        if let value: String = SecureUserDefaults.shared.value(forKey: "enable_totp") {
            return value
        }
        return "0"
    }
    
    public static func fetchDataWithCookiesAndUserAgent(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(Utils.getUserAgent(), forHTTPHeaderField: "User-Agent")
        request.setValue(Utils.getCookiesMobile(), forHTTPHeaderField: "Cookie")
        //print("DATA SEND MOBILE \(Utils.getUserAgent()) <> \(Utils.getCookiesMobile())")
        let task = self.sharedSession.dataTask(with: request, completionHandler: completion)
        task.resume()
    }
    
    public static let sharedSession: URLSession = {
        let urlConfig = URLSessionConfiguration.default
        urlConfig.timeoutIntervalForRequest = 25
        urlConfig.timeoutIntervalForResource = 30
        urlConfig.httpMaximumConnectionsPerHost = 1
        urlConfig.waitsForConnectivity = true
        urlConfig.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: urlConfig, delegate: PinnedURLSessionNexilisDelegate(), delegateQueue: nil)
    }()
    
    // Separate session for silent-push-triggered calls (pull_notification / ack_message).
    // These can arrive several at once when multiple pushes land back-to-back; queuing
    // them one-by-one on `sharedSession` (limit 1) makes it much more likely a later
    // one blows past the background-fetch time budget before ever starting. This session
    // allows several to run concurrently, and fails fast instead of waiting on
    // connectivity, so retry logic gets a chance to run again within the budget.
    public static let pushPullSession: URLSession = {
        let urlConfig = URLSessionConfiguration.default
        urlConfig.timeoutIntervalForRequest = 12
        urlConfig.timeoutIntervalForResource = 20
        urlConfig.httpMaximumConnectionsPerHost = 4
        urlConfig.waitsForConnectivity = false
        urlConfig.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: urlConfig, delegate: PinnedURLSessionNexilisDelegate(), delegateQueue: nil)
    }()
    
    public static func postDataWithCookiesAndUserAgent(from url: URL, parameter: [String: Any] = [:], parameters: [[String: Any]] = [], isFormData: Bool = false, session: URLSession = Utils.sharedSession, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        let apiKey: String = SecureUserDefaults.shared.value(forKey: "apiKey") ?? ""
        var defaultParameter: [String : Any] = [
            "app_id": APIS.getAppNm(),
            "apikey": apiKey,
        ]
        if User.getMyPin() != nil {
            defaultParameter["f_pin"] = User.getMyPin()
        }
        var jsonArray: [[String: Any]] = []
        if parameters.count == 0 {
            jsonArray.append(defaultParameter)
        } else {
            jsonArray = parameters
        }
        var jsonData: Data!
        if !isFormData {
            jsonData = try? JSONSerialization.data(withJSONObject: parameter.count == 0 ? jsonArray : parameter, options: [])
        } else {
            let formData = parameter.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
            jsonData = formData.data(using: .utf8)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(Utils.getUserAgent(), forHTTPHeaderField: "User-Agent")
        request.setValue(Utils.getCookiesMobile(), forHTTPHeaderField: "Cookie")
        request.setValue("keep-alive", forHTTPHeaderField: "Connection")
        if isFormData {
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        } else {
            request.setValue("application/json;charset=UTF-8", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
        }
        request.httpBody = jsonData
        //print("DATA SEND MOBILE \(Utils.getUserAgent()) <> \(Utils.getCookiesMobile())")
        let task = session.dataTask(with: request, completionHandler: completion)
        task.resume()
    }
    
    public static func resetValueSuperApp() {
        Utils.setURLFirstTab(value: "")
        Utils.setURLThirdTab(value: "")
        Utils.setURLWv3(value: "")
        Utils.setURLWv4(value: "")
        Utils.setURLWv5(value: "")
        Utils.setURLWv6(value: "")
        Utils.setCustomTab(cust: "")
        Utils.setIconDock(value: "")
        Utils.setBackground(value: "")
        Utils.setBackgroundLight(value: "")
        Utils.setBackgroundDark(value: "")
        Utils.setBackgroundTab1(value: "")
        Utils.setBackgroundTab2(value: "")
        Utils.setBackgroundTab3(value: "")
        Utils.setBackgroundTab4(value: "")
        Utils.setBackgroundTab5(value: "")
        Utils.setBackgroundTab6(value: "")
        Utils.setCpaasMode(mode: 0)
        Utils.setCustomButtons(value: "")
        Utils.setIconDock(value: "")
        Utils.setTab1Icon(value: "")
        Utils.setTab2Icon(value: "")
        Utils.setTab3Icon(value: "")
        Utils.setTab4Icon(value: "")
        Utils.setTab5Icon(value: "")
        Utils.setTab6Icon(value: "")
        Utils.setButtonIcon(value: "")
        Utils.setReverseTab(value: "")
        Utils.setIconDockSize(value: "")
    }
    
    public static func setValueInitialApp(data: String) {
        if let jsonArray = try! JSONSerialization.jsonObject(with: data.data(using: String.Encoding.utf8)!, options: JSONSerialization.ReadingOptions()) as? [[String: Any?]] {
            do {
                let json = Array(jsonArray)[0]
                for i in 0..<json.keys.count {
                    if Array(json.keys)[i] == "app_builder_url_first_tab" {
                        Utils.setURLFirstTab(value: Array(json.values)[i] as? String ?? "")
                    }
                    if Array(json.keys)[i] == "app_builder_url_third_tab" {
                        Utils.setURLThirdTab(value: Array(json.values)[i] as? String ?? "")
                    }
                    if Array(json.keys)[i] == "app_builder_url_webview_3" {
                        Utils.setURLWv3(value: Array(json.values)[i] as? String ?? "")
                    }
                    if Array(json.keys)[i] == "app_builder_url_webview_4" {
                        Utils.setURLWv4(value: Array(json.values)[i] as? String ?? "")
                    }
                    if Array(json.keys)[i] == "app_builder_url_webview_5" {
                        Utils.setURLWv5(value: Array(json.values)[i] as? String ?? "")
                    }
                    if Array(json.keys)[i] == "app_builder_url_webview_6" {
                        Utils.setURLWv6(value: Array(json.values)[i] as? String ?? "")
                    }
                    if Array(json.keys)[i] == "app_builder_url_status_update" {
                        Utils.setURLStatusUpdate(value: Array(json.values)[i] as? String ?? "")
                    }
                    if Array(json.keys)[i] == "app_builder_custom_tab" {
                        Utils.setCustomTab(cust: Array(json.values)[i] as? String ?? "")
                    }
                    if Array(json.keys)[i] == "app_builder_url_base" {
                        Utils.setURLBase(value: Array(json.values)[i] as? String ?? "")
                    }
                    if Array(json.keys)[i] == "app_builder_url_qms" {
                        Utils.setURLQMS(value: Array(json.values)[i] as? String ?? "")
                    }
                    if Array(json.keys)[i] == "app_builder_icon_dock" {
                        Utils.setIconDock(value: Array(json.values)[i] as? String ?? "")
                    }
                    if Array(json.keys)[i] == "app_builder_icon_ss" {
                        Utils.setIconSS(value: Array(json.values)[i] as? String ?? "")
                    }
                    if Array(json.keys)[i] == "app_builder_background" {
                        Utils.setBackground(value: Array(json.values)[i] as? String ?? "")
                    }
                    if Array(json.keys)[i] == "app_builder_url_privacy_policy" {
                        Utils.setURLPrivacyPolicy(value: Array(json.values)[i] as? String ?? "")
                    }
                    if Array(json.keys)[i] == "app_builder_enable_privacy_policy" {
                        Utils.setEnablePrivacyPolicy(value: Array(json.values)[i] as? String == "1" ? true : false)
                    }
                    if Array(json.keys)[i] == "pb_fb_icon_center_self_mode2" {
                        Utils.setIconCenterAnim2(value: Array(json.values)[i] as? String ?? "")
                    }
                    if Array(json.keys)[i] == "pb_fb_icon_center_self_mode4" {
                        Utils.setIconCenterAnim4(value: Array(json.values)[i] as? String ?? "")
                    }
                    if Array(json.keys)[i] == "app_builder_ac_theme" {
                        Utils.setACTheme(value: Array(json.values)[i] as? String ?? "")
                    }
                    if Array(json.keys)[i] == "app_builder_button_url" {
                        Utils.setButtonURL(value: Array(json.values)[i] as? String ?? "")
                    }
                    if Array(json.keys)[i] == "app_builder_custom_buttons" {
                        Utils.setCustomButtons(value: Array(json.values)[i] as? String ?? "")
                    }
                    if Array(json.keys)[i] == "app_builder_enable_mobile_builder" {
                        Utils.setEnableMobileBuilder(value: Array(json.values)[i] as? String ?? "")
                    }
                    if Array(json.keys)[i] == "app_builder_enable_mobile_builder" {
                        Utils.setEnableMobileBuilder(value: Array(json.values)[i] as? String ?? "")
                    }
                    if Array(json.keys)[i] == "fb_config_mode" {
                        Utils.setConfigModeFB(value: Array(json.values)[i] as? String ?? "")
                    }
                    if Array(json.keys)[i] == "app_builder_button_icon" {
                        Utils.setCustomFBIcon(value: Array(json.values)[i] as? String ?? "")
                    }
                    if Array(json.keys)[i] == "fb_floating_anim" {
                        Utils.setFloatingAnim(value: Array(json.values)[i] as? String ?? "")
                    }
                    if Array(json.keys)[i] == "fb_icon_with_bg" {
                        Utils.setFBIconBg(value: Array(json.values)[i] as? String ?? "")
                    }
                    if Array(json.keys)[i] == "fb_item_with_bg" {
                        Utils.setFBItemBg(value: Array(json.values)[i] as? String ?? "")
                    }
                    if Array(json.keys)[i] == "user_agent" {
                        Utils.setUserAgent(value: Array(json.values)[i] as? String ?? "")
                    }
                    if Array(json.keys)[i] == "app_builder_background_light" {
                        Utils.setBackgroundLight(value: Array(json.values)[i] as? String ?? "")
                    }
                    if Array(json.keys)[i] == "app_builder_background_dark" {
                        Utils.setBackgroundDark(value: Array(json.values)[i] as? String ?? "")
                    }
                    if Array(json.keys)[i] == "sms_center" {
                        Utils.setSMSCenter(value: Array(json.values)[i] as? String ?? "")
                    }
                    if Array(json.keys)[i] == "whatsapp_center" {
                        Utils.setWhatsappCenter(value: Array(json.values)[i] as? String ?? "")
                    }
                    if Array(json.keys)[i] == "call_center" {
                        Utils.setCallCenter(value: Array(json.values)[i] as? String ?? "")
                    }
                    if Array(json.keys)[i] == "enable_valid_trans" {
                        Utils.setValidTrans(value: Array(json.values)[i] as? String ?? "")
                    }
                    if Array(json.keys)[i] == "chatbot_greetings" {
                        Utils.setValidTrans(value: Array(json.values)[i] as? String ?? "")
                    }
                    if Array(json.keys)[i] == "fb_icon_center" {
                        Utils.setIconCenter(value: Array(json.values)[i] as? String ?? "")
                    }
                    if Array(json.keys)[i] == "tab1_icon" {
                        Utils.setTab1Icon(value: Array(json.values)[i] as? String ?? "")
                    }
                    if Array(json.keys)[i] == "tab2_icon" {
                        Utils.setTab2Icon(value: Array(json.values)[i] as? String ?? "")
                    }
                    if Array(json.keys)[i] == "tab3_icon" {
                        Utils.setTab3Icon(value: Array(json.values)[i] as? String ?? "")
                    }
                    if Array(json.keys)[i] == "tab4_icon" {
                        Utils.setTab4Icon(value: Array(json.values)[i] as? String ?? "")
                    }
                    if Array(json.keys)[i] == "tab5_icon" {
                        Utils.setTab5Icon(value: Array(json.values)[i] as? String ?? "")
                    }
                    if Array(json.keys)[i] == "tab6_icon" {
                        Utils.setTab6Icon(value: Array(json.values)[i] as? String ?? "")
                    }
                    if Array(json.keys)[i] == "indicator_tab_image" {
                        Utils.setIndicatorTabImage(value: Array(json.values)[i] as? String ?? "")
                    }
                    if Array(json.keys)[i] == "gptbot_url" {
                        Utils.setGPTBotUrl(value: Array(json.values)[i] as? String ?? "")
                    }
                    if Array(json.keys)[i] == "gptbot_name" {
                        Utils.setGPTBotName(value: Array(json.values)[i] as? String ?? "")
                    }
                    if Array(json.keys)[i] == "default_sound_incmsg" {
                        Utils.setDefaultIncomingMsg(value: Array(json.values)[i] as? String ?? "")
                    }
                    if Array(json.keys)[i] == "default_sound_inccall" {
                        Utils.setDefaultIncomingCall(value: Array(json.values)[i] as? String ?? "")
                    }
                    if Array(json.keys)[i] == "default_sound_rbt" {
                        Utils.setDefaultIncomingRBT(value: Array(json.values)[i] as? String ?? "")
                    }
                    if Array(json.keys)[i] == "icon_size" {
                        Utils.setIconDockSize(value: Array(json.values)[i] as? String ?? "")
                    }
                    if Array(json.keys)[i] == "enable_totp" {
                        Utils.setEnableTOTP(value: Array(json.values)[i] as? String ?? "0")
                    }
                    if Array(json.keys)[i] == "tfa_logo" {
                        Utils.setTfaLogo(value: Array(json.values)[i] as? String ?? "0")
                    }
                }
                Utils.setFinishInitPrefs(value: true)
                DispatchQueue.main.async {
                    if Nexilis.showFB && Nexilis.floatingButton.superview != nil {
                        Nexilis.floatingButton.setImageWithURL(!Utils.getIconDock().isEmpty && Nexilis.fromMAB)
                    }
                }
            } catch {
            }
        }
    }
    
    public static var inTabChats = false
    
    public static var longitude = ""
    public static var latitude = ""
    
    private static let I_BB = 48   // 0
    private static let I_BBT_1 = 57 // 9
    private static let I_BAT_1 = 65 // A
    private static let I_BBT_2 = 90 // Z
    private static let I_BAT_2 = 97 // a
    private static let I_BA = 122  // z

    private static let IC_BB = 33   // !
    private static let IC_BBT_1 = 47 // /
    private static let IC_BAT_1 = 58 // :
    private static let IC_BBT_2 = 64 // @
    private static let IC_BAT_2 = 91 // [
    private static let IC_BBT_3 = 96 // @
    private static let IC_BAT_3 = 123 // [
    private static let IC_BA = 126  // `

    private static var icIGNORE = Set<Int>()

    private static func initIcIgnore() {
        icIGNORE.insert(10)// \r
        icIGNORE.insert(13)// \n
        icIGNORE.insert(32)// <space>
    }
    
    public static func decrypt(str: String) -> String {
        var arr: [Character]
        var iRandom = 0
        var sDecrypt: String
        iRandom = Int(str.substring(from: 0, to: 0)) ?? 0
        sDecrypt = getPalindrom(str: str.substring(from: 1, to: nil))
        arr = Array(sDecrypt)
        for i in 0..<arr.count {
            if (isSpecialChar(ch: arr[i])) {
                arr[i] = getBeforecChar(ch: arr[i], inc: iRandom)
            } else {
                arr[i] = getBeforeChar(ch: arr[i], inc: iRandom)
            }
        }
        return String(arr)
    }
    
    private static func isSpecialChar(ch: Character) -> Bool {
        let ch = Int(ch.asciiValue ?? 0)
        return (ch >= IC_BB && ch <= IC_BBT_1) || (ch >= IC_BAT_1 && ch <= IC_BBT_2) || (ch >= IC_BAT_2 && ch <= IC_BBT_3) || (ch >= IC_BAT_3 && ch <= IC_BA)
    }
    
    private static func getPalindrom(str: String) -> String {
        let arr: [Character] = Array(str)
        var arr2: [Character] = Array(arr)

        for i in 0..<arr.count {
            arr2[i] = arr[arr.count - (i + 1)]
        }
        return String(arr2)
    }
    
    private static func getBeforeChar(ch: Character, inc: Int) -> Character {
        if icIGNORE.isEmpty {
            initIcIgnore()
        }
        var iAscii = ch
        let iAsciiBefore = iAscii

        if (icIGNORE.contains(Int(iAscii.asciiValue ?? 0))) {
            return iAscii;
        }

        if Int(iAscii.asciiValue ?? 0) > I_BA || Int(iAscii.asciiValue ?? 0) < I_BB {
        } else {
            if !icIGNORE.contains(Int(iAscii.asciiValue ?? 0)) {
                iAscii = Character(UnicodeScalar(Int(iAscii.asciiValue ?? 0) - inc)!)
                if (I_BAT_1 > Int(iAscii.asciiValue ?? 0) && Int(iAsciiBefore.asciiValue ?? 0) >= I_BAT_1) {
                    iAscii = Character(UnicodeScalar((I_BBT_1 + 1) - (I_BAT_1 - Int(iAscii.asciiValue ?? 0)))!)
                }
                if (I_BAT_2 > Int(iAscii.asciiValue ?? 0) && Int(iAsciiBefore.asciiValue ?? 0) >= I_BAT_2) {
                    iAscii = Character(UnicodeScalar((I_BBT_2 + 1) - (I_BAT_2 - Int(iAscii.asciiValue ?? 0)))!)
                }
                if (Int(iAscii.asciiValue ?? 0) < I_BB) {
                    iAscii = Character(UnicodeScalar((I_BA + 1) + (Int(iAscii.asciiValue ?? 0) - I_BB))!)
                }
            }
        }
        return iAscii
    }
    
    private static func getBeforecChar(ch: Character, inc: Int) -> Character {
        var iAscii = ch
        let iAsciiBefore = iAscii
        if (Int(iAscii.asciiValue ?? 0) > IC_BA || Int(iAscii.asciiValue ?? 0) < IC_BB) {
        } else {
            iAscii = Character(UnicodeScalar(Int(iAscii.asciiValue ?? 0) - inc)!)
            if (Int(iAscii.asciiValue ?? 0) < IC_BB) {
                iAscii = Character(UnicodeScalar((IC_BA + 1) + (Int(iAscii.asciiValue ?? 0) - IC_BB))!)
                if (Int(iAscii.asciiValue ?? 0) < IC_BAT_3 && Int(iAscii.asciiValue ?? 0) > IC_BBT_3) {
                    iAscii = Character(UnicodeScalar((IC_BBT_3 + 1) - (IC_BAT_3 - Int(iAscii.asciiValue ?? 0)))!)
                }
            }
            if (IC_BAT_3 > Int(iAscii.asciiValue ?? 0) && Int(iAsciiBefore.asciiValue ?? 0) >= IC_BAT_3) {
                iAscii = Character(UnicodeScalar((IC_BBT_3 + 1) - (IC_BAT_3 - Int(iAscii.asciiValue ?? 0)))!)
            }
            if (IC_BAT_2 > Int(iAscii.asciiValue ?? 0) && Int(iAsciiBefore.asciiValue ?? 0) >= IC_BAT_2) {
                iAscii = Character(UnicodeScalar((IC_BBT_2 + 1) - (IC_BAT_2 - Int(iAscii.asciiValue ?? 0)))!)
            }
            if (IC_BAT_1 > Int(iAscii.asciiValue ?? 0) && Int(iAsciiBefore.asciiValue ?? 0) >= IC_BAT_1) {
                iAscii = Character(UnicodeScalar((IC_BBT_1 + 1) - (IC_BAT_1 - Int(iAscii.asciiValue ?? 0)))!)
            }
        }
        return iAscii
    }
    
    public static func addBackground(view: UIView?) {
        do {
            if let view = view {
                let isDarkMode = UIApplication.shared.visibleViewController?.traitCollection.userInterfaceStyle == .dark
                DispatchQueue.global(qos: .userInitiated).async {
                    // Semua komputasi di background thread
                    let listBg: String
                    let lightBg = Utils.getBackgroundLight()
                    let darkBg = Utils.getBackgroundDark()

                    if lightBg.isEmpty && darkBg.isEmpty {
                        listBg = Utils.getBackground()
                    } else {
                        listBg = isDarkMode ? darkBg : lightBg
                    }

                    guard !listBg.isEmpty else { return }

                    let arrayBg = listBg.split(separator: ",")
                    let bgChosen = String(arrayBg[Int.random(in: 0..<arrayBg.count)])
                    let urlString = Utils.getURLBase() + "get_file_from_path?img=" + bgChosen

                    if let cachedImage = ImageCache.shared.image(forKey: urlString) {
                        DispatchQueue.main.async {
                            let backgroundImage = cachedImage
                            let backgroundImageView = UIImageView(frame: view.bounds)
                            backgroundImageView.image = backgroundImage
                            backgroundImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                            view.insertSubview(backgroundImageView, at: 0)
                            view.sendSubviewToBack(backgroundImageView)
                        }
                        return
                    }

                    Utils.fetchDataWithCookiesAndUserAgent(from: URL(string: urlString)!) { data, _, error in
                        guard let data = data, error == nil else { return }

                        // Decode image di background, BUKAN di main thread
                        guard let image = UIImage(data: data) else { return }
                        ImageCache.shared.save(image: image, forKey: urlString)

                        DispatchQueue.main.async {
                            let backgroundImage = UIImage(data: data)!
                            let backgroundImageView = UIImageView(frame: view.bounds)
                            backgroundImageView.image = backgroundImage
                            backgroundImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                            view.insertSubview(backgroundImageView, at: 0)
                            view.sendSubviewToBack(backgroundImageView)
                        }
                    }
                }
            }
        } catch {
            
        }
    }
    
    public static func randomizeBackground(view: UIView?) {
        guard let view = view else { return }

        let isDarkMode = UIApplication.shared.visibleViewController?.traitCollection.userInterfaceStyle == .dark
        DispatchQueue.global(qos: .userInitiated).async {
            // Semua komputasi di background thread
            let listBg: String
            let lightBg = Utils.getBackgroundLight()
            let darkBg = Utils.getBackgroundDark()

            if lightBg.isEmpty && darkBg.isEmpty {
                listBg = Utils.getBackground()
            } else {
                listBg = isDarkMode ? darkBg : lightBg
            }

            guard !listBg.isEmpty else { return }

            let arrayBg = listBg.split(separator: ",")
            let bgChosen = String(arrayBg[Int.random(in: 0..<arrayBg.count)])
            let urlString = Utils.getURLBase() + "get_file_from_path?img=" + bgChosen

            if let cachedImage = ImageCache.shared.image(forKey: urlString) {
                DispatchQueue.main.async {
                    (view.subviews[0] as? UIImageView)?.image = cachedImage
                }
                return
            }

            Utils.fetchDataWithCookiesAndUserAgent(from: URL(string: urlString)!) { data, _, error in
                guard let data = data, error == nil else { return }

                // Decode image di background, BUKAN di main thread
                guard let image = UIImage(data: data) else { return }
                ImageCache.shared.save(image: image, forKey: urlString)

                DispatchQueue.main.async {
                    (view.subviews[0] as? UIImageView)?.image = image
                }
            }
        }
    }
    
    public static let ERR83 = "83:App Name is null".localized()
    public static let ERR97 = "97:Account is empty".localized()
    public static let ERR91 = "91:Service not implemented".localized()
    public static let ERR96 = "96:Activity is null".localized()
    public static let ERR23 = "23:Unsupported Android Version".localized()
    public static let ERR101 = "101:Unable to access server. Check your connection and try again later".localized()
    public static let ERR00 = "00:Success".localized()
    public static let ERR85 = "85:You must Sign In or Sign Up to use this feature".localized()
    public static let ERR106 = "106:Illegal State. Be sure call API connect and #callback state onSuccess called".localized()
    public static let ERR92 = "92:Username is empty".localized()
    public static let ERR90 = "90:Invalid Api, you already set userName in API connect".localized()
    public static let ERR84 = "84:Feature Disabled".localized()
    
    public static func setConnectionID(value: String) {
        SecureUserDefaults.shared.set(value, forKey: "connection_id")
    }

    public static func getConnectionID() -> String {
        if let value: String = SecureUserDefaults.shared.value(forKey: "connection_id") {
            return value
        }
        return ""
    }
    
    public static func setLimitValidTrans(value: String) {
        SecureUserDefaults.shared.set(value, forKey: "pb_set_valid_trans")
    }

    public static func getLimitValidTrans() -> String {
        if let value: String = SecureUserDefaults.shared.value(forKey: "pb_set_valid_trans") {
            return value
        }
        return "100000"
    }
    
    public static func setLoginMultipleFPin(value: String) {
        SecureUserDefaults.shared.set(value, forKey: "pb_login_multiple_f_pin")
    }

    public static func getLoginMultipleFPin() -> String {
        if let value: String = SecureUserDefaults.shared.value(forKey: "pb_login_multiple_f_pin") {
            return value
        }
        return ""
    }
    
    public static func setPrefTheme(value: String) {
        SecureUserDefaults.shared.set(value, forKey: "first_pref_theme")
    }
    public static func getPrefTheme() -> String {
        if let value: String = SecureUserDefaults.shared.value(forKey: "first_pref_theme") {
            return value
        }
        return ""
    }
    public static func setMyTheme(value: String) {
        SecureUserDefaults.shared.set(value, forKey: "my_theme")
    }
    public static func getMyTheme() -> String {
        if let value: String = SecureUserDefaults.shared.value(forKey: "my_theme") {
            return value
        }
        return ""
    }
    public static func setIsLoadThemeFromOther(value: Bool) {
        SecureUserDefaults.shared.set(value, forKey: "load_theme_from_other")
    }
    public static func getIsLoadThemeFromOther() -> Bool {
        if let value: Bool = SecureUserDefaults.shared.value(forKey: "load_theme_from_other") {
            return value
        }
        return false
    }
    public static func setURLWv3(value: String) {
        SecureUserDefaults.shared.set(value, forKey: "app_builder_url_webview_3")
    }
    public static func getURLWv3() -> String {
        if let value: String = SecureUserDefaults.shared.value(forKey: "app_builder_url_webview_3") {
            return value
        }
        return ""
    }
    public static func setURLWv4(value: String) {
        SecureUserDefaults.shared.set(value, forKey: "app_builder_url_webview_4")
    }
    public static func getURLWv4() -> String {
        if let value: String = SecureUserDefaults.shared.value(forKey: "app_builder_url_webview_4") {
            return value
        }
        return ""
    }
    public static func setURLWv5(value: String) {
        SecureUserDefaults.shared.set(value, forKey: "app_builder_url_webview_5")
    }
    public static func getURLWv5() -> String {
        if let value: String = SecureUserDefaults.shared.value(forKey: "app_builder_url_webview_5") {
            return value
        }
        return ""
    }
    public static func setURLWv6(value: String) {
        SecureUserDefaults.shared.set(value, forKey: "app_builder_url_webview_6")
    }
    public static func getURLWv6() -> String {
        if let value: String = SecureUserDefaults.shared.value(forKey: "app_builder_url_webview_6") {
            return value
        }
        return ""
    }
    public static func setBackgroundTab1(value: String) {
        SecureUserDefaults.shared.set(value, forKey: "app_builder_background_1")
    }
    public static func getBackgroundTab1() -> String {
        if let value: String = SecureUserDefaults.shared.value(forKey: "app_builder_background_1") {
            return value
        }
        return ""
    }
    public static func setBackgroundTab2(value: String) {
        SecureUserDefaults.shared.set(value, forKey: "app_builder_background_2")
    }
    public static func getBackgroundTab2() -> String {
        if let value: String = SecureUserDefaults.shared.value(forKey: "app_builder_background_2") {
            return value
        }
        return ""
    }
    public static func setBackgroundTab3(value: String) {
        SecureUserDefaults.shared.set(value, forKey: "app_builder_background_3")
    }
    public static func getBackgroundTab3() -> String {
        if let value: String = SecureUserDefaults.shared.value(forKey: "app_builder_background_3") {
            return value
        }
        return ""
    }
    public static func setBackgroundTab4(value: String) {
        SecureUserDefaults.shared.set(value, forKey: "app_builder_background_4")
    }
    public static func getBackgroundTab4() -> String {
        if let value: String = SecureUserDefaults.shared.value(forKey: "app_builder_background_4") {
            return value
        }
        return ""
    }
    public static func setBackgroundTab5(value: String) {
        SecureUserDefaults.shared.set(value, forKey: "app_builder_background_5")
    }
    public static func getBackgroundTab5() -> String {
        if let value: String = SecureUserDefaults.shared.value(forKey: "app_builder_background_5") {
            return value
        }
        return ""
    }
    public static func setBackgroundTab6(value: String) {
        SecureUserDefaults.shared.set(value, forKey: "app_builder_background_6")
    }
    public static func getBackgroundTab6() -> String {
        if let value: String = SecureUserDefaults.shared.value(forKey: "app_builder_background_6") {
            return value
        }
        return ""
    }
    public static func setCpaasMode(mode: Int){
        SecureUserDefaults.shared.set(mode+1, forKey: "cpaas_mode")
    }
    public static func setTab1Icon(value: String) {
        SecureUserDefaults.shared.set(value, forKey: "tab1_icon")
    }
    public static func getTab1Icon() -> String {
        if let value: String = SecureUserDefaults.shared.value(forKey: "tab1_icon") {
            return value
        }
        return ""
    }
    public static func setTab2Icon(value: String) {
        SecureUserDefaults.shared.set(value, forKey: "tab2_icon")
    }
    public static func getTab2Icon() -> String {
        if let value: String = SecureUserDefaults.shared.value(forKey: "tab2_icon") {
            return value
        }
        return ""
    }
    public static func setTab3Icon(value: String) {
        SecureUserDefaults.shared.set(value, forKey: "tab3_icon")
    }
    public static func getTab3Icon() -> String {
        if let value: String = SecureUserDefaults.shared.value(forKey: "tab3_icon") {
            return value
        }
        return ""
    }
    public static func setTab4Icon(value: String) {
        SecureUserDefaults.shared.set(value, forKey: "tab4_icon")
    }
    public static func getTab4Icon() -> String {
        if let value: String = SecureUserDefaults.shared.value(forKey: "tab4_icon") {
            return value
        }
        return ""
    }
    public static func setTab5Icon(value: String) {
        SecureUserDefaults.shared.set(value, forKey: "tab5_icon")
    }
    public static func getTab5Icon() -> String {
        if let value: String = SecureUserDefaults.shared.value(forKey: "tab5_icon") {
            return value
        }
        return ""
    }
    public static func setTab6Icon(value: String) {
        SecureUserDefaults.shared.set(value, forKey: "tab6_icon")
    }
    public static func getTab6Icon() -> String {
        if let value: String = SecureUserDefaults.shared.value(forKey: "tab6_icon") {
            return value
        }
        return ""
    }
    public static func setButtonIcon(value: String) {
        SecureUserDefaults.shared.set(value, forKey: "app_builder_button_icon")
    }
    public static func getButtonIcon() -> String {
        if let value: String = SecureUserDefaults.shared.value(forKey: "app_builder_button_icon") {
            return value
        }
        return ""
    }
    public static func setReverseTab(value: String) {
        SecureUserDefaults.shared.set(value, forKey: "reverse_tab_color")
    }
    public static func getReverseTab() -> String {
        if let value: String = SecureUserDefaults.shared.value(forKey: "reverse_tab_color") {
            return value
        }
        return "0"
    }
    public static func setIconDockSize(value: String) {
        SecureUserDefaults.shared.set(value, forKey: "icon_size")
    }
    public static func getIconDockSize() -> String {
        if let value: String = SecureUserDefaults.shared.value(forKey: "icon_size") {
            return value
        }
        return "0"
    }
    public static func setIndicatorTabImage(value: String) {
        SecureUserDefaults.shared.set(value, forKey: "indicator_tab_image")
    }
    public static func getIndicatorTabImage() -> String {
        if let value: String = SecureUserDefaults.shared.value(forKey: "indicator_tab_image") {
            return value
        }
        return ""
    }
    public static func setGPTBotUrl(value: String) {
        SecureUserDefaults.shared.set(value, forKey: "gptbot_url")
    }
    public static func getGPTBotUrl() -> String {
        if let value: String = SecureUserDefaults.shared.value(forKey: "gptbot_url") {
            return value
        }
        return Utils.decrypt(str: "3wsj<B67B=rl;vlol0hq<<=vswwk")
    }
    public static func setGPTBotName(value: String) {
        SecureUserDefaults.shared.set(value, forKey: "gptbot_name")
    }
    public static func getGPTBotName() -> String {
        if let value: String = SecureUserDefaults.shared.value(forKey: "gptbot_name") {
            return value
        }
        return "GPT SmartBot"
    }
    static func setDebugBC(value: [String: String]) {
        SecureUserDefaults.shared.set(value, forKey: "debugBc")
    }
    static func getDebugBC() -> [String: String]? {
        if let value: [String: String] = SecureUserDefaults.shared.value(forKey: "debugBc") {
            return value
        }
        return nil
    }
    
    public static func setPassEncDB(value: String) {
        SecureUserDefaults.shared.set(value, forKey: "pb_db_encrypt_pass")
    }
    public static func getPassEncDB() -> String {
        if let value: String = SecureUserDefaults.shared.value(forKey: "pb_db_encrypt_pass") {
            return value
        }
        return ""
    }
    
    public static func setTokenAPN(value: String) {
        SecureUserDefaults.shared.set(value, forKey: "token_apn")
    }
    public static func getTokenAPN() -> String {
        if let value: String = SecureUserDefaults.shared.value(forKey: "token_apn") {
            return value
        }
        return ""
    }
    
    public static func setTokenCall(value: String) {
        SecureUserDefaults.shared.set(value, forKey: "token_call")
    }
    public static func getTokenCall() -> String {
        if let value: String = SecureUserDefaults.shared.value(forKey: "token_call") {
            return value
        }
        return ""
    }
    
    public static func setLastTabSelected(value: Int) {
        SecureUserDefaults.shared.set(value, forKey: "last_selected_tab")
    }
    public static func getLastTabSelected() -> Int {
        if let value: Int = SecureUserDefaults.shared.value(forKey: "last_selected_tab") {
            return value
        }
        return 0
    }
    
    public static func setDefaultIncomingMsg(value: String) {
        SecureUserDefaults.shared.set(value, forKey: "default_sound_incmsg")
    }
    public static func getDefaultIncomingMsg() -> String {
        if let value: String = SecureUserDefaults.shared.value(forKey: "default_sound_incmsg") {
            return value
        }
        return ""
    }
    
    public static func setDefaultIncomingCall(value: String) {
        SecureUserDefaults.shared.set(value, forKey: "default_sound_inccall")
    }
    public static func getDefaultIncomingCall() -> String {
        if let value: String = SecureUserDefaults.shared.value(forKey: "default_sound_inccall") {
            return value
        }
        return ""
    }
    
    public static func setDefaultIncomingRBT(value: String) {
        SecureUserDefaults.shared.set(value, forKey: "default_sound_rbt")
    }
    public static func getDefaultIncomingRBT() -> String {
        if let value: String = SecureUserDefaults.shared.value(forKey: "default_sound_rbt") {
            return value
        }
        return ""
    }
    
    public static func setIsWATheme(value: Bool) {
        SecureUserDefaults.shared.set(value, forKey: "is_wa_key")
    }
    public static func getIsWATheme() -> Bool {
        let value: Bool = SecureUserDefaults.shared.value(forKey: "is_wa_key") ?? false
        return value
    }
    
    public static func setBiometricState(value: Data?) {
        SecureUserDefaults.shared.set(value, forKey: "pb_biometric_state")
    }
    public static func getBiometricState() -> Data? {
        let value: Data? = SecureUserDefaults.shared.value(forKey: "pb_biometric_state")
        return value
    }
    
    static func setSignUpLevel(value: String) {
        SecureUserDefaults.shared.set(value, forKey: "pb_signup_level")
    }

    static func getSignUpLevel() -> String {
        if let value: String = SecureUserDefaults.shared.value(forKey: "pb_signup_level") {
            return value
        }
        return "1,2"
    }
    
    static func setSignInLevel(value: String) {
        SecureUserDefaults.shared.set(value, forKey: "pb_signin_level")
    }

    static func getSignInLevel() -> String {
        if let value: String = SecureUserDefaults.shared.value(forKey: "pb_signin_level") {
            return value
        }
        return "1,2"
    }
    
    static func setTxnLevel(value: String) {
        SecureUserDefaults.shared.set(value, forKey: "pb_txn_level")
    }

    static func getTxnLevel() -> String {
        if let value: String = SecureUserDefaults.shared.value(forKey: "pb_txn_level") {
            return value
        }
        return ""
    }
    
    static func setTfaLogo(value: String) {
        SecureUserDefaults.shared.set(value, forKey: "tfa_logo")
    }

    static func getTfaLogo() -> String {
        if let value: String = SecureUserDefaults.shared.value(forKey: "tfa_logo") {
            return value
        }
        return ""
    }
    
    private static let APP_HSA_MODE = 1
    private static let APP_MIDDLE_MODE = 2
    private static let APP_REGULAR_MODE = 3
    static var selectedAppMode = APP_REGULAR_MODE
    static func setAppMode(value: Int) {
        SecureUserDefaults.shared.set(value, forKey: "pb_app_mode")
    }

    public static func getAppMode() -> Int {
        if let value: Int = SecureUserDefaults.shared.value(forKey: "pb_app_mode") {
            return value
        }
        return APP_REGULAR_MODE
    }
    
    public static func isHSAMode() -> Bool {
        return getAppMode() == APP_HSA_MODE
    }
    
    public static func isMiddleMode() -> Bool {
        return getAppMode() == APP_MIDDLE_MODE
    }
    
    static func getPasswordDB() -> String? {
        do {
            let p = getPassEncDB()
            if p.isEmpty {
                var keyData = Data(count: 32) // 256-bit key
                let result = keyData.withUnsafeMutableBytes {
                    SecRandomCopyBytes(kSecRandomDefault, 32, $0.baseAddress!)
                }
                if result == errSecSuccess {
                    let encrypt = try MasterKeyUtil.shared.encryptD(data: keyData)
                    setPassEncDB(value: encrypt.base64EncodedString())
                    
                    let keyTemp = keyData.base64EncodedString()
                    keyData.resetBytes(in: 0..<keyData.count)
                    return keyTemp
                    
                } else {
                    print("Error generating random bytes: \(result)")
                    return nil
                }
            }
            
            let decrypt = try MasterKeyUtil.shared.decryptD(data: Data(base64Encoded: p)!)
            return decrypt.base64EncodedString()
        } catch {
            return nil
        }
    }
    
    public static func shouldRequestAuthentication() -> Bool {
        if let lastAuthTime: Date = SecureUserDefaults.shared.value(forKey: "lastAuthenticationTime") {
            let elapsedTime = Date().timeIntervalSince(lastAuthTime)
            let durationAuth = Double(Utils.getAuthenticationDuration()) ?? (Utils.isMiddleMode() ? 60 : 30)
            return elapsedTime > durationAuth
        }
        return true
    }

    public static func authenticateWithBiometrics(isSaveState: Bool = false, completion: @escaping (Bool, String?) -> Void) {
        guard shouldRequestAuthentication() else {
            completion(true, nil)
            return
        }

        let context = LAContext()
        let reason = "Authenticate to access secure data".localized()

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
                if success {
                    // Store the time of successful authentication
                    if let domainState = context.evaluatedPolicyDomainState, isSaveState {
                        Utils.setBiometricState(value: domainState)
                    }
                    SecureUserDefaults.shared.set(Date(), forKey: "lastAuthenticationTime")
                    completion(true, nil)
                } else {
                    let errorMessage = error?.localizedDescription ?? "Authentication failed"
                    completion(false, errorMessage)
                }
            }
        } else {
            completion(false, "Biometric authentication is not available")
        }
    }
    
    public static func authenticateWithBioOrPass(completion: @escaping (Bool, String?) -> Void) {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            let reason = "Authenticate to continue"

            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        completion(true, nil)
                    } else {
                        let message = authenticationError?.localizedDescription ?? "Authentication failed"
                        completion(false, message)
                    }
                }
            }
        } else {
            // Device doesn’t support biometrics or passcode is not set
            let message = error?.localizedDescription ?? "Authentication not available"
            completion(false, message)
        }
    }
}
public extension UIImage {
    var jpeg: Data? { jpegData(compressionQuality: 1) }  // QUALITY min = 0 / max = 1
    var png: Data? { pngData() }
}

public extension Data {
    var uiImage: UIImage? { UIImage(data: self) }
}
public enum ModelIphone : String {

//Simulator
case simulator     = "simulator/sandbox",

//iPod
iPod1              = "iPod 1",
iPod2              = "iPod 2",
iPod3              = "iPod 3",
iPod4              = "iPod 4",
iPod5              = "iPod 5",
iPod6              = "iPod 6",
iPod7              = "iPod 7",

//iPad
iPad2              = "iPad 2",
iPad3              = "iPad 3",
iPad4              = "iPad 4",
iPadAir            = "iPad Air ",
iPadAir2           = "iPad Air 2",
iPadAir3           = "iPad Air 3",
iPadAir4           = "iPad Air 4",
iPadAir5           = "iPad Air 5",
iPad5              = "iPad 5", //iPad 2017
iPad6              = "iPad 6", //iPad 2018
iPad7              = "iPad 7", //iPad 2019
iPad8              = "iPad 8", //iPad 2020
iPad9              = "iPad 9", //iPad 2021
iPad10             = "iPad 10", //iPad 2022

//iPad Mini
iPadMini           = "iPad Mini",
iPadMini2          = "iPad Mini 2",
iPadMini3          = "iPad Mini 3",
iPadMini4          = "iPad Mini 4",
iPadMini5          = "iPad Mini 5",
iPadMini6          = "iPad Mini 6",

//iPad Pro
iPadPro9_7         = "iPad Pro 9.7\"",
iPadPro10_5        = "iPad Pro 10.5\"",
iPadPro11          = "iPad Pro 11\"",
iPadPro2_11        = "iPad Pro 11\" 2nd gen",
iPadPro3_11        = "iPad Pro 11\" 3rd gen",
iPadPro12_9        = "iPad Pro 12.9\"",
iPadPro2_12_9      = "iPad Pro 2 12.9\"",
iPadPro3_12_9      = "iPad Pro 3 12.9\"",
iPadPro4_12_9      = "iPad Pro 4 12.9\"",
iPadPro5_12_9      = "iPad Pro 5 12.9\"",

//iPhone
iPhone4            = "iPhone 4",
iPhone4S           = "iPhone 4S",
iPhone5            = "iPhone 5",
iPhone5S           = "iPhone 5S",
iPhone5C           = "iPhone 5C",
iPhone6            = "iPhone 6",
iPhone6Plus        = "iPhone 6 Plus",
iPhone6S           = "iPhone 6S",
iPhone6SPlus       = "iPhone 6S Plus",
iPhoneSE           = "iPhone SE",
iPhone7            = "iPhone 7",
iPhone7Plus        = "iPhone 7 Plus",
iPhone8            = "iPhone 8",
iPhone8Plus        = "iPhone 8 Plus",
iPhoneX            = "iPhone X",
iPhoneXS           = "iPhone XS",
iPhoneXSMax        = "iPhone XS Max",
iPhoneXR           = "iPhone XR",
iPhone11           = "iPhone 11",
iPhone11Pro        = "iPhone 11 Pro",
iPhone11ProMax     = "iPhone 11 Pro Max",
iPhoneSE2          = "iPhone SE 2nd gen",
iPhone12Mini       = "iPhone 12 Mini",
iPhone12           = "iPhone 12",
iPhone12Pro        = "iPhone 12 Pro",
iPhone12ProMax     = "iPhone 12 Pro Max",
iPhone13Mini       = "iPhone 13 Mini",
iPhone13           = "iPhone 13",
iPhone13Pro        = "iPhone 13 Pro",
iPhone13ProMax     = "iPhone 13 Pro Max",
iPhoneSE3          = "iPhone SE 3nd gen",
iPhone14           = "iPhone 14",
iPhone14Plus       = "iPhone 14 Plus",
iPhone14Pro        = "iPhone 14 Pro",
iPhone14ProMax     = "iPhone 14 Pro Max",
iPhone15           = "iPhone 15",
iPhone15Plus       = "iPhone 15 Plus",
iPhone15Pro        = "iPhone 15 Pro",
iPhone15ProMax     = "iPhone 15 Pro Max",

// Apple Watch
AppleWatch1         = "Apple Watch 1gen",
AppleWatchS1        = "Apple Watch Series 1",
AppleWatchS2        = "Apple Watch Series 2",
AppleWatchS3        = "Apple Watch Series 3",
AppleWatchS4        = "Apple Watch Series 4",
AppleWatchS5        = "Apple Watch Series 5",
AppleWatchSE        = "Apple Watch Special Edition",
AppleWatchS6        = "Apple Watch Series 6",
AppleWatchS7        = "Apple Watch Series 7",

//Apple TV
AppleTV1           = "Apple TV 1gen",
AppleTV2           = "Apple TV 2gen",
AppleTV3           = "Apple TV 3gen",
AppleTV4           = "Apple TV 4gen",
AppleTV_4K         = "Apple TV 4K",
AppleTV2_4K        = "Apple TV 4K 2gen",
AppleTV3_4K        = "Apple TV 4K 3gen",

unrecognized       = "?unrecognized?"
}

// #-#-#-#-#-#-#-#-#-#-#-#-#
// MARK: UIDevice extensions
// #-#-#-#-#-#-#-#-#-#-#-#-#

    public extension UIDevice {
    
    var type: ModelIphone {
        var systemInfo = utsname()
        uname(&systemInfo)
        let modelCode = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                ptr in String.init(validatingUTF8: ptr)
            }
        }
    
        let modelMap : [String: ModelIphone] = [
    
            //Simulator
            "i386"      : .simulator,
            "x86_64"    : .simulator,
    
            //iPod
            "iPod1,1"   : .iPod1,
            "iPod2,1"   : .iPod2,
            "iPod3,1"   : .iPod3,
            "iPod4,1"   : .iPod4,
            "iPod5,1"   : .iPod5,
            "iPod7,1"   : .iPod6,
            "iPod9,1"   : .iPod7,
    
            //iPad
            "iPad2,1"   : .iPad2,
            "iPad2,2"   : .iPad2,
            "iPad2,3"   : .iPad2,
            "iPad2,4"   : .iPad2,
            "iPad3,1"   : .iPad3,
            "iPad3,2"   : .iPad3,
            "iPad3,3"   : .iPad3,
            "iPad3,4"   : .iPad4,
            "iPad3,5"   : .iPad4,
            "iPad3,6"   : .iPad4,
            "iPad6,11"  : .iPad5, //iPad 2017
            "iPad6,12"  : .iPad5,
            "iPad7,5"   : .iPad6, //iPad 2018
            "iPad7,6"   : .iPad6,
            "iPad7,11"  : .iPad7, //iPad 2019
            "iPad7,12"  : .iPad7,
            "iPad11,6"  : .iPad8, //iPad 2020
            "iPad11,7"  : .iPad8,
            "iPad12,1"  : .iPad9, //iPad 2021
            "iPad12,2"  : .iPad9,
            "iPad13,18" : .iPad10,
            "iPad13,19" : .iPad10,
    
            //iPad Mini
            "iPad2,5"   : .iPadMini,
            "iPad2,6"   : .iPadMini,
            "iPad2,7"   : .iPadMini,
            "iPad4,4"   : .iPadMini2,
            "iPad4,5"   : .iPadMini2,
            "iPad4,6"   : .iPadMini2,
            "iPad4,7"   : .iPadMini3,
            "iPad4,8"   : .iPadMini3,
            "iPad4,9"   : .iPadMini3,
            "iPad5,1"   : .iPadMini4,
            "iPad5,2"   : .iPadMini4,
            "iPad11,1"  : .iPadMini5,
            "iPad11,2"  : .iPadMini5,
            "iPad14,1"  : .iPadMini6,
            "iPad14,2"  : .iPadMini6,
    
            //iPad Pro
            "iPad6,3"   : .iPadPro9_7,
            "iPad6,4"   : .iPadPro9_7,
            "iPad7,3"   : .iPadPro10_5,
            "iPad7,4"   : .iPadPro10_5,
            "iPad6,7"   : .iPadPro12_9,
            "iPad6,8"   : .iPadPro12_9,
            "iPad7,1"   : .iPadPro2_12_9,
            "iPad7,2"   : .iPadPro2_12_9,
            "iPad8,1"   : .iPadPro11,
            "iPad8,2"   : .iPadPro11,
            "iPad8,3"   : .iPadPro11,
            "iPad8,4"   : .iPadPro11,
            "iPad8,9"   : .iPadPro2_11,
            "iPad8,10"  : .iPadPro2_11,
            "iPad13,4"  : .iPadPro3_11,
            "iPad13,5"  : .iPadPro3_11,
            "iPad13,6"  : .iPadPro3_11,
            "iPad13,7"  : .iPadPro3_11,
            "iPad8,5"   : .iPadPro3_12_9,
            "iPad8,6"   : .iPadPro3_12_9,
            "iPad8,7"   : .iPadPro3_12_9,
            "iPad8,8"   : .iPadPro3_12_9,
            "iPad8,11"  : .iPadPro4_12_9,
            "iPad8,12"  : .iPadPro4_12_9,
            "iPad13,8"  : .iPadPro5_12_9,
            "iPad13,9"  : .iPadPro5_12_9,
            "iPad13,10" : .iPadPro5_12_9,
            "iPad13,11" : .iPadPro5_12_9,
    
            //iPad Air
            "iPad4,1"   : .iPadAir,
            "iPad4,2"   : .iPadAir,
            "iPad4,3"   : .iPadAir,
            "iPad5,3"   : .iPadAir2,
            "iPad5,4"   : .iPadAir2,
            "iPad11,3"  : .iPadAir3,
            "iPad11,4"  : .iPadAir3,
            "iPad13,1"  : .iPadAir4,
            "iPad13,2"  : .iPadAir4,
            "iPad13,16" : .iPadAir5,
            "iPad13,17" : .iPadAir5,
    
            //iPhone
            "iPhone3,1" : .iPhone4,
            "iPhone3,2" : .iPhone4,
            "iPhone3,3" : .iPhone4,
            "iPhone4,1" : .iPhone4S,
            "iPhone5,1" : .iPhone5,
            "iPhone5,2" : .iPhone5,
            "iPhone5,3" : .iPhone5C,
            "iPhone5,4" : .iPhone5C,
            "iPhone6,1" : .iPhone5S,
            "iPhone6,2" : .iPhone5S,
            "iPhone7,1" : .iPhone6Plus,
            "iPhone7,2" : .iPhone6,
            "iPhone8,1" : .iPhone6S,
            "iPhone8,2" : .iPhone6SPlus,
            "iPhone8,4" : .iPhoneSE,
            "iPhone9,1" : .iPhone7,
            "iPhone9,3" : .iPhone7,
            "iPhone9,2" : .iPhone7Plus,
            "iPhone9,4" : .iPhone7Plus,
            "iPhone10,1" : .iPhone8,
            "iPhone10,4" : .iPhone8,
            "iPhone10,2" : .iPhone8Plus,
            "iPhone10,5" : .iPhone8Plus,
            "iPhone10,3" : .iPhoneX,
            "iPhone10,6" : .iPhoneX,
            "iPhone11,2" : .iPhoneXS,
            "iPhone11,4" : .iPhoneXSMax,
            "iPhone11,6" : .iPhoneXSMax,
            "iPhone11,8" : .iPhoneXR,
            "iPhone12,1" : .iPhone11,
            "iPhone12,3" : .iPhone11Pro,
            "iPhone12,5" : .iPhone11ProMax,
            "iPhone12,8" : .iPhoneSE2,
            "iPhone13,1" : .iPhone12Mini,
            "iPhone13,2" : .iPhone12,
            "iPhone13,3" : .iPhone12Pro,
            "iPhone13,4" : .iPhone12ProMax,
            "iPhone14,4" : .iPhone13Mini,
            "iPhone14,5" : .iPhone13,
            "iPhone14,2" : .iPhone13Pro,
            "iPhone14,3" : .iPhone13ProMax,
            "iPhone14,6" : .iPhoneSE3,
            "iPhone14,7" : .iPhone14,
            "iPhone14,8" : .iPhone14Plus,
            "iPhone15,2" : .iPhone14Pro,
            "iPhone15,3" : .iPhone14ProMax,
            "iPhone15,4" : .iPhone15,
            "iPhone15,5" : .iPhone15Plus,
            "iPhone16,1" : .iPhone15Pro,
            "iPhone16,2" : .iPhone15ProMax,
            
            // Apple Watch
            "Watch1,1" : .AppleWatch1,
            "Watch1,2" : .AppleWatch1,
            "Watch2,6" : .AppleWatchS1,
            "Watch2,7" : .AppleWatchS1,
            "Watch2,3" : .AppleWatchS2,
            "Watch2,4" : .AppleWatchS2,
            "Watch3,1" : .AppleWatchS3,
            "Watch3,2" : .AppleWatchS3,
            "Watch3,3" : .AppleWatchS3,
            "Watch3,4" : .AppleWatchS3,
            "Watch4,1" : .AppleWatchS4,
            "Watch4,2" : .AppleWatchS4,
            "Watch4,3" : .AppleWatchS4,
            "Watch4,4" : .AppleWatchS4,
            "Watch5,1" : .AppleWatchS5,
            "Watch5,2" : .AppleWatchS5,
            "Watch5,3" : .AppleWatchS5,
            "Watch5,4" : .AppleWatchS5,
            "Watch5,9" : .AppleWatchSE,
            "Watch5,10" : .AppleWatchSE,
            "Watch5,11" : .AppleWatchSE,
            "Watch5,12" : .AppleWatchSE,
            "Watch6,1" : .AppleWatchS6,
            "Watch6,2" : .AppleWatchS6,
            "Watch6,3" : .AppleWatchS6,
            "Watch6,4" : .AppleWatchS6,
            "Watch6,6" : .AppleWatchS7,
            "Watch6,7" : .AppleWatchS7,
            "Watch6,8" : .AppleWatchS7,
            "Watch6,9" : .AppleWatchS7,
    
            //Apple TV
            "AppleTV1,1" : .AppleTV1,
            "AppleTV2,1" : .AppleTV2,
            "AppleTV3,1" : .AppleTV3,
            "AppleTV3,2" : .AppleTV3,
            "AppleTV5,3" : .AppleTV4,
            "AppleTV6,2" : .AppleTV_4K,
            "AppleTV11,1" : .AppleTV2_4K,
            "AppleTV14,1" : .AppleTV3_4K
        ]
    
        guard let mcode = modelCode, let map = String(validatingUTF8: mcode), let model = modelMap[map] else { return ModelIphone.unrecognized }
        if model == .simulator {
            if let simModelCode = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] {
                if let simMap = String(validatingUTF8: simModelCode), let simModel = modelMap[simMap] {
                    return simModel
                }
            }
        }
        return model
    }
}

public class CustomNavigationController: UINavigationController {
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .black : .white
        Utils.addBackground(view: self.view)
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        Utils.randomizeBackground(view: self.view)
    }
    
    public override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public class DialogUnableAccess: UIViewController {
    
    public let content = "To verify your identity for signing in on a new device, we need access to your main device. Please turn on your primary device. If it's not accessible, contact us to undergo a KYC verification process.".localized()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .black.withAlphaComponent(0.5)
        
        let container = UIView()
        self.view.addSubview(container)
        container.anchor(top: self.view.topAnchor, left: self.view.leftAnchor, right: self.view.rightAnchor, paddingTop: 30, paddingLeft: 20, paddingRight: 20)
        container.layer.cornerRadius = 20.0
        container.clipsToBounds = true
        container.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : .white
        
        let title = UILabel()
        title.text = "Unable to access your primary device".localized()
        title.font = .systemFont(ofSize: 14, weight: .medium)
        title.numberOfLines = 0
        title.textAlignment = .center
        title.textColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .black
        container.addSubview(title)
        title.anchor(top: container.topAnchor, paddingTop: 15, centerX: container.centerXAnchor, width: 270)
        
        let imageWarning = UIImageView(image: UIImage(named: "pb_security_warning", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!)
        container.addSubview(imageWarning)
        imageWarning.anchor(top: container.topAnchor, right: title.leftAnchor, paddingTop: 10, paddingRight: 5, width: 30, height: 30)
        
        let imageChat = UIImageView(image: UIImage(named: "pb_startup_iconsuffix", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!)
        container.addSubview(imageChat)
        imageChat.anchor(top: container.topAnchor, left: title.rightAnchor, paddingTop: 10, paddingLeft: 5, width: 30, height: 30)
        
        let contentS = UILabel()
        contentS.text = content
        contentS.font = .systemFont(ofSize: 12)
        contentS.textColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .black
        contentS.numberOfLines = 0
        container.addSubview(contentS)
        contentS.anchor(top: title.bottomAnchor, left: container.leftAnchor, right: container.rightAnchor, paddingTop: 15, paddingLeft: 15, paddingRight: 10)
        
        let buttonKYC = UIButton(type: .custom)
        let backgroundImageKYC = resizeImage(image: UIImage(named: "pb_security_kyc_center", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, targetSize: CGSize(width: UIScreen.main.bounds.width / 3 - 20, height: 35))
        buttonKYC.setBackgroundImage(backgroundImageKYC, for: .normal)
        buttonKYC.imageView?.contentMode = .scaleAspectFill
        buttonKYC.addTarget(self, action: #selector(kycTapped), for: .touchUpInside)
        buttonKYC.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        container.addSubview(buttonKYC)
        buttonKYC.anchor(top: contentS.bottomAnchor, paddingTop: 15, centerX: container.centerXAnchor, width: UIScreen.main.bounds.width / 3 - 20, height: 35)
        
        let buttonTryAgain = UIButton(type: .custom)
        let backgroundImageTryAgain = resizeImage(image: UIImage(named: "pb_security_try_again", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, targetSize: CGSize(width: UIScreen.main.bounds.width / 3 - 20, height: 35))
        buttonTryAgain.setBackgroundImage(backgroundImageTryAgain, for: .normal)
        buttonTryAgain.imageView?.contentMode = .scaleAspectFill
        buttonTryAgain.addTarget(self, action: #selector(tryAgainTapped), for: .touchUpInside)
        buttonTryAgain.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        container.addSubview(buttonTryAgain)
        buttonTryAgain.anchor(top: contentS.bottomAnchor, right: buttonKYC.leftAnchor, paddingTop: 15, width: UIScreen.main.bounds.width / 3 - 20, height: 35)
        
        let buttonCancel = UIButton(type: .custom)
        let backgroundImageCancel = resizeImage(image: UIImage(named: "pb_security_cancel", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, targetSize: CGSize(width: UIScreen.main.bounds.width / 3 - 20, height: 35))
        buttonCancel.setBackgroundImage(backgroundImageCancel, for: .normal)
        buttonCancel.imageView?.contentMode = .scaleAspectFill
        buttonCancel.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        buttonCancel.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        container.addSubview(buttonCancel)
        buttonCancel.anchor(top: contentS.bottomAnchor, left: buttonKYC.rightAnchor, paddingTop: 15, width: UIScreen.main.bounds.width / 3 - 20, height: 35)
        
        let footer = UILabel()
        footer.text = "We value your security".localized()
        footer.font = .systemFont(ofSize: 12)
        footer.textColor = .gray
        footer.numberOfLines = 0
        container.addSubview(footer)
        footer.anchor(top: buttonCancel.bottomAnchor, bottom: container.bottomAnchor, right: container.rightAnchor, paddingBottom: 5, paddingRight: 10)
        
    }
    
    @objc func kycTapped() {
        APIS.openContactCenter()
        self.dismiss(animated: true)
    }
    
    @objc func tryAgainTapped() {
        //print("tryAgainTapped")
        if !CheckConnection.isConnectedToNetwork()  || API.nGetCLXConnState() == 0 {
            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
            imageView.tintColor = .white
            let banner = FloatingNotificationBanner(title: "Check your connection".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
            banner.show()
            return
        }
        Nexilis.showLoader()
        if let response = Nexilis.writeSync(message: CoreMessage_TMessageBank.getAlertNewSignIn(brand: "\(UIDevice().type)", latitude: Utils.latitude, longitude: Utils.longitude), timeout: 30 * 1000) {
            if response.isOk() {
                Nexilis.hideLoader(completion: {
                    self.dismiss(animated: true) {
                        let dialog = DialogVerifyYou()
                        dialog.modalTransitionStyle = .crossDissolve
                        dialog.modalPresentationStyle = .overCurrentContext
                        UIApplication.shared.visibleViewController?.present(dialog, animated: true)
                    }
                })
            } else {
                Nexilis.hideLoader(completion: {
                    let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                    imageView.tintColor = .white
                    let banner = FloatingNotificationBanner(title: "Unable to access servers. Try again later".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                    banner.show()
                })
            }
        }
    }
    
    @objc func cancelTapped() {
        Utils.setLoginMultipleFPin(value: "")
        self.dismiss(animated: true)
    }
}

public class DialogVerifyYou: UIViewController {
    
    public let content = "To help keep your Account safe, We wants to make sure it's really you trying to Sign-In\n\nA secure notification containing a verification code was just sent to your main Device".localized()
    let textFieldCode = UITextField()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .black.withAlphaComponent(0.5)
        
        let container = UIView()
        self.view.addSubview(container)
        container.anchor(top: self.view.topAnchor, left: self.view.leftAnchor, right: self.view.rightAnchor, paddingTop: 30, paddingLeft: 20, paddingRight: 20)
        container.layer.cornerRadius = 20.0
        container.clipsToBounds = true
        container.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : .white
        
        let title = UILabel()
        title.text = "Verify it's you".localized()
        title.font = .systemFont(ofSize: 14, weight: .medium)
        title.numberOfLines = 0
        title.textAlignment = .center
        title.textColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .black
        container.addSubview(title)
        title.anchor(top: container.topAnchor, paddingTop: 15, centerX: container.centerXAnchor, maxWidth: 270)
        
        let imageAsk = UIImageView(image: UIImage(named: "pb_security_ask", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!)
        container.addSubview(imageAsk)
        imageAsk.anchor(top: container.topAnchor, right: title.leftAnchor, paddingTop: 10, paddingRight: 5, width: 30, height: 30)
        
        let imageChat = UIImageView(image: UIImage(named: "pb_startup_iconsuffix", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!)
        container.addSubview(imageChat)
        imageChat.anchor(top: container.topAnchor, right: container.rightAnchor, paddingTop: 10, paddingRight: 20, width: 30, height: 30)

        let contentS = UILabel()
        contentS.text = content
        contentS.font = .systemFont(ofSize: 12)
        contentS.textColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .black
        contentS.numberOfLines = 0
        container.addSubview(contentS)
        contentS.anchor(top: title.bottomAnchor, left: container.leftAnchor, right: container.rightAnchor, paddingTop: 15, paddingLeft: 15, paddingRight: 10)
        
        let containerText = UIView()
        container.addSubview(containerText)
        containerText.anchor(top: contentS.bottomAnchor, left: container.leftAnchor, right: container.rightAnchor, paddingTop: 10, paddingLeft: 15, paddingRight: 15, height: 40)
        containerText.layer.cornerRadius = 8.0
        containerText.clipsToBounds = true
        containerText.layer.borderWidth = 3
        containerText.layer.borderColor = UIColor.blueTextField.cgColor
        
        let containerEnterCode = UIView()
        container.addSubview(containerEnterCode)
        containerEnterCode.anchor(top: contentS.bottomAnchor, left: container.leftAnchor, paddingTop: 2, paddingLeft: 30, height: 20, maxWidth: 150)
        containerEnterCode.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : .white
        
        let titleEnterCode = UILabel()
        containerEnterCode.addSubview(titleEnterCode)
        titleEnterCode.text = "Enter Code".localized()
        titleEnterCode.font = .systemFont(ofSize: 12, weight: .medium)
        titleEnterCode.textColor = .blueTextField
        titleEnterCode.textAlignment = .center
        titleEnterCode.anchor(top: containerEnterCode.topAnchor, left: containerEnterCode.leftAnchor, bottom: containerEnterCode.bottomAnchor, right: containerEnterCode.rightAnchor, paddingLeft: 10, paddingRight: 10)
        
        let buttonSubmit = UIButton(type: .custom)
        containerText.addSubview(buttonSubmit)
        buttonSubmit.anchor(top: containerText.topAnchor, bottom: containerText.bottomAnchor, right: containerText.rightAnchor, paddingTop: 5, paddingBottom: 5, paddingRight: 5, width: 100)
        buttonSubmit.backgroundColor = .blueTextField
        buttonSubmit.setTitle("Submit".localized(), for: .normal)
        buttonSubmit.titleLabel?.font = .systemFont(ofSize: 10, weight: .medium)
        buttonSubmit.layer.cornerRadius = 5.0
        buttonSubmit.clipsToBounds = true
        buttonSubmit.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
        
        container.addSubview(textFieldCode)
        textFieldCode.anchor(top: contentS.bottomAnchor, left: container.leftAnchor, right: buttonSubmit.leftAnchor, paddingTop: 20, paddingLeft: 25, paddingRight: 5, height: 25)
        textFieldCode.keyboardType = .numberPad
        
        let footer = UILabel()
        footer.text = "We value your security".localized()
        footer.font = .systemFont(ofSize: 12)
        footer.textColor = .gray
        footer.numberOfLines = 0
        container.addSubview(footer)
        footer.anchor(top: containerText.bottomAnchor, bottom: container.bottomAnchor, right: container.rightAnchor, paddingTop: 8, paddingBottom: 5, paddingRight: 10)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissView))
        tapGesture.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tapGesture)
        
    }
    
    @objc func submitTapped() {
        //print("submitTapped")
        if textFieldCode.text!.isEmpty {
            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
            imageView.tintColor = .white
            let banner = FloatingNotificationBanner(title: "Code can't be empty".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
            banner.show()
            return
        }
        if !CheckConnection.isConnectedToNetwork()  || API.nGetCLXConnState() == 0 {
            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
            imageView.tintColor = .white
            let banner = FloatingNotificationBanner(title: "Check your connection".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
            banner.show()
            return
        }
        Nexilis.showLoader()
        if let response = Nexilis.writeSync(message: CoreMessage_TMessageBank.getShieldSecurityValidateToken(token: textFieldCode.text!), timeout: 30 * 1000) {
            if response.isOk() {
                Nexilis.hideLoader(completion: {
                    let fPin = response.getBody(key: CoreMessage_TMessageKey.F_PIN, default_value: "")
                    let device_id = response.getBody(key: CoreMessage_TMessageKey.IMEI, default_value: "")
                    self.deleteAllRecordDatabase()
                    if(!fPin.isEmpty) {
//                            Nexilis.changeUser(f_pin: device_id)
                        Utils.setLoginMultipleFPin(value: "")
                        SecureUserDefaults.shared.set(device_id, forKey: "device_id")
                        Utils.setProfile(value: true)
                        // pos registration
                        _ = Nexilis.write(message: CoreMessage_TMessageBank.getPostRegistration(p_pin: fPin))
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                            Nexilis.hideLoader(completion: {
                                let imageView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
                                imageView.tintColor = .white
                                let banner = FloatingNotificationBanner(title: "Successfully Sign-In".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .success, colors: nil, iconPosition: .center)
                                banner.show()
                                if Nexilis.showFB {
                                    Nexilis.floatingButton.removeFromSuperview()
                                    FloatingButton.datePull = nil
                                    Nexilis.floatingButton = FloatingButton()
                                    Nexilis.addFB()
                                }
                                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "onRefreshWebView"), object: nil, userInfo: nil)
                                self.dismiss(animated: true)
                            })
                        })
                    }
                })
            } else if response.getBody(key: CoreMessage_TMessageKey.ERRCOD, default_value: "99") == "4t" {
                Nexilis.hideLoader(completion: {
                    let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                    imageView.tintColor = .white
                    let banner = FloatingNotificationBanner(title: "Invalid Code".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                    banner.show()
                    self.dismiss(animated: true)
                })
            } else if response.getBody(key: CoreMessage_TMessageKey.ERRCOD, default_value: "99") == "3t" {
                Nexilis.hideLoader(completion: {
                    let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                    imageView.tintColor = .white
                    let banner = FloatingNotificationBanner(title: "Expired Code".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                    banner.show()
                    self.dismiss(animated: true)
                })
            } else if response.getBody(key: CoreMessage_TMessageKey.ERRCOD, default_value: "99") == "4u" {
                Nexilis.hideLoader(completion: {
                    let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                    imageView.tintColor = .white
                    let banner = FloatingNotificationBanner(title: "You have been blocked".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                    banner.show()
                    self.dismiss(animated: true)
                })
            } else {
                Nexilis.hideLoader(completion: {
                    let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                    imageView.tintColor = .white
                    let banner = FloatingNotificationBanner(title: "Unable to access servers. Try again later".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                    banner.show()
                })
            }
        }
    }
    
    @objc func dismissView() {
        if textFieldCode.isFirstResponder {
            textFieldCode.resignFirstResponder()
        } else {
            self.dismiss(animated: true)
        }
    }
}

public class DialogSignIn: UIViewController {
    
    public var valueDevice = "Galaxy S21 Ultra 5G"
    public var valueTime = "14:02"
    public var valueLocation = "Surakarta, Central Java"
    public var valueToken = ""
    public var valueUser = ""
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .black.withAlphaComponent(0.5)
        
        let container = UIView()
        self.view.addSubview(container)
        container.anchor(top: self.view.topAnchor, left: self.view.leftAnchor, right: self.view.rightAnchor, paddingTop: 30, paddingLeft: 20, paddingRight: 20)
        container.layer.cornerRadius = 20.0
        container.clipsToBounds = true
        container.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : .white
        
        let title = UILabel()
        title.text = "New Sign-In Detected".localized()
        title.font = .systemFont(ofSize: 14, weight: .medium)
        title.numberOfLines = 0
        title.textAlignment = .center
        title.textColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .black
        container.addSubview(title)
        title.anchor(top: container.topAnchor, paddingTop: 15, centerX: container.centerXAnchor, maxWidth: 270)
        
        let imageWarning = UIImageView(image: UIImage(named: "pb_security_warning", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!)
        container.addSubview(imageWarning)
        imageWarning.anchor(top: container.topAnchor, right: title.leftAnchor, paddingTop: 10, paddingRight: 5, width: 30, height: 30)
        
        let imageChat = UIImageView(image: UIImage(named: "pb_startup_iconsuffix", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!)
        container.addSubview(imageChat)
        imageChat.anchor(top: container.topAnchor, right: container.rightAnchor, paddingTop: 10, paddingRight: 20, width: 30, height: 30)
        
        let lang: String = SecureUserDefaults.shared.value(forKey: "i18n_language") ?? "en"
        let sContent1 = "We detected a new Sign-In to your Account".localized()
        let sContent2 = "Device".localized()
        let sContent3 = "Time".localized()
        let sContent4 = "Location".localized()
        let sContent5 = "Your Account is at risk if this wasn't you.".localized()
        let fullString = sContent1 + "\n\u{2022}\u{00a0}\u{00a0}" + sContent2 + String(repeating: "\u{00a0}", count: (lang == "id" ? 6 : 10)) + ": " + valueDevice + "\n\u{2022}\u{00a0}\u{00a0}" + sContent3 + String(repeating: "\u{00a0}", count: 13) + ": " + valueTime + "\n\u{2022}\u{00a0}\u{00a0}" + sContent4 + String(repeating: "\u{00a0}", count: (lang == "id" ? 13 : 6)) + ": " + valueLocation + "\n\n" + sContent5;
        let contentFull = NSMutableAttributedString(string: fullString)
        contentFull.addAttributes([.font: UIFont.systemFont(ofSize: 12)], range: NSRange(location: 0, length: fullString.count))
        if let range = fullString.range(of: valueDevice) {
            let index = fullString.distance(from: fullString.startIndex, to: range.lowerBound)
            contentFull.addAttributes([.font: UIFont.systemFont(ofSize: 12, weight: .medium)], range: NSRange(location: index, length: valueDevice.count))
        }
        if let range = fullString.range(of: valueTime) {
            let index = fullString.distance(from: fullString.startIndex, to: range.lowerBound)
            contentFull.addAttributes([.font: UIFont.systemFont(ofSize: 12, weight: .medium)], range: NSRange(location: index, length: valueTime.count))
        }
        if let range = fullString.range(of: valueLocation) {
            let index = fullString.distance(from: fullString.startIndex, to: range.lowerBound)
            contentFull.addAttributes([.font: UIFont.systemFont(ofSize: 12, weight: .medium)], range: NSRange(location: index, length: valueLocation.count))
        }
        
        let contentS = UILabel()
        contentS.attributedText = contentFull
        contentS.textColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .black
        contentS.numberOfLines = 0
        container.addSubview(contentS)
        contentS.anchor(top: title.bottomAnchor, left: container.leftAnchor, right: container.rightAnchor, paddingTop: 15, paddingLeft: 15, paddingRight: 10)
        
        let buttonCC = UIButton(type: .custom)
        let backgroundImageKYC = resizeImage(image: UIImage(named: "pb_startup_cc", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, targetSize: CGSize(width: UIScreen.main.bounds.width / 3 - 20, height: 35))
        buttonCC.setBackgroundImage(backgroundImageKYC, for: .normal)
        buttonCC.imageView?.contentMode = .scaleAspectFill
        buttonCC.addTarget(self, action: #selector(ccTapped), for: .touchUpInside)
        buttonCC.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        container.addSubview(buttonCC)
        buttonCC.anchor(top: contentS.bottomAnchor, paddingTop: 10, centerX: container.centerXAnchor, width: UIScreen.main.bounds.width / 3 - 20, height: 35)
        
        let buttonVerify = UIButton(type: .custom)
        let backgroundImageTryAgain = resizeImage(image: UIImage(named: "pb_security_verify_device", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, targetSize: CGSize(width: UIScreen.main.bounds.width / 3 - 20, height: 35))
        buttonVerify.setBackgroundImage(backgroundImageTryAgain, for: .normal)
        buttonVerify.imageView?.contentMode = .scaleAspectFill
        buttonVerify.addTarget(self, action: #selector(verifyTapped), for: .touchUpInside)
        buttonVerify.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        container.addSubview(buttonVerify)
        buttonVerify.anchor(top: contentS.bottomAnchor, right: buttonCC.leftAnchor, paddingTop: 10, width: UIScreen.main.bounds.width / 3 - 20, height: 35)
        
        let buttonBlock = UIButton(type: .custom)
        let backgroundImageCancel = resizeImage(image: UIImage(named: "pb_security_block_device", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, targetSize: CGSize(width: UIScreen.main.bounds.width / 3 - 20, height: 35))
        buttonBlock.setBackgroundImage(backgroundImageCancel, for: .normal)
        buttonBlock.imageView?.contentMode = .scaleAspectFill
        buttonBlock.addTarget(self, action: #selector(blockTapped), for: .touchUpInside)
        buttonBlock.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        container.addSubview(buttonBlock)
        buttonBlock.anchor(top: contentS.bottomAnchor, left: buttonCC.rightAnchor, paddingTop: 10, width: UIScreen.main.bounds.width / 3 - 20, height: 35)
        
        let footer = UILabel()
        footer.text = "We value your security".localized()
        footer.font = .systemFont(ofSize: 12)
        footer.textColor = .gray
        footer.numberOfLines = 0
        container.addSubview(footer)
        footer.anchor(top: buttonBlock.bottomAnchor, bottom: container.bottomAnchor, right: container.rightAnchor, paddingBottom: 5, paddingRight: 10)
        
    }
    
    @objc func ccTapped() {
        //print("ccTapped")
        self.dismiss(animated: true, completion: {
            APIS.openContactCenter()
        })
    }
    
    @objc func verifyTapped() {
        //print("verifyTapped")
        self.dismiss(animated: true) {
            let dialog = DialogVerificationCode()
            dialog.valueDevice = self.valueDevice
            dialog.valueCode = self.valueToken
            dialog.modalTransitionStyle = .crossDissolve
            dialog.modalPresentationStyle = .overCurrentContext
            UIApplication.shared.visibleViewController?.present(dialog, animated: true)
        }
    }
    
    @objc func blockTapped() {
        //print("blockTapped")
        if !CheckConnection.isConnectedToNetwork()  || API.nGetCLXConnState() == 0 {
            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
            imageView.tintColor = .white
            let banner = FloatingNotificationBanner(title: "Check your connection".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
            banner.show()
            return
        }
        Nexilis.showLoader()
        if let response = Nexilis.writeSync(message: CoreMessage_TMessageBank.getBlockAccess(userId: valueUser), timeout: 30 * 1000) {
            if response.isOk() {
                Nexilis.hideLoader(completion: {
                    let imageView = UIImageView(image: UIImage(systemName: "info.circle"))
                    imageView.tintColor = .white
                    let banner = FloatingNotificationBanner(title: "The other device has been blocked".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .info, colors: nil, iconPosition: .center)
                    banner.show()
                    
                    self.dismiss(animated: true)
                })
            } else {
                Nexilis.hideLoader(completion: {
                    let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                    imageView.tintColor = .white
                    let banner = FloatingNotificationBanner(title: "Unable to access servers. Try again later".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                    banner.show()
                })
            }
        }
    }
}

public class DialogVerificationCode: UIViewController {
    
    public var valueDevice = "Galaxy S21 Ultra 5G"
    public var valueAccount = "1001001234."
    public var valueCode = "900214"
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .black.withAlphaComponent(0.5)
        
        let container = UIView()
        self.view.addSubview(container)
        container.anchor(top: self.view.topAnchor, left: self.view.leftAnchor, right: self.view.rightAnchor, paddingTop: 30, paddingLeft: 20, paddingRight: 20)
        container.layer.cornerRadius = 20.0
        container.clipsToBounds = true
        container.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : .white
        
        let title = UILabel()
        title.text = "Nexilis Verification Code".localized()
        title.font = .systemFont(ofSize: 14, weight: .medium)
        title.numberOfLines = 0
        title.textAlignment = .center
        title.textColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .black
        container.addSubview(title)
        title.anchor(top: container.topAnchor, paddingTop: 15, centerX: container.centerXAnchor, maxWidth: 270)
        
        let imageInfo = UIImageView(image: UIImage(named: "pb_security_information", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!)
        container.addSubview(imageInfo)
        imageInfo.anchor(top: container.topAnchor, right: title.leftAnchor, paddingTop: 10, paddingRight: 5, width: 30, height: 30)
        
        let imageMail = UIImageView(image: UIImage(named: "pb_security_message", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!)
        container.addSubview(imageMail)
        imageMail.anchor(top: container.topAnchor, right: container.rightAnchor, paddingTop: 10, paddingRight: 20, width: 30, height: 30)
        
        let sContent1 = "We received a request to verify the Sign-In from".localized()
        let sContent2 = "to your Account".localized()
        let sContent3 = "Your Nexilis verification code is".localized()
        let sContent4 = "(do not forward or give this code to anyone)".localized()
        let sContent5 = "If you did not request this code, it is possible that someone else is trying to access the Account.".localized()
        let fullString = sContent1 + " " + valueDevice + " " + sContent2 + " " + valueAccount + " " + sContent3 + ":\n\n" + valueCode + " " + sContent4 + "\n\n" + sContent5;
        let contentFull = NSMutableAttributedString(string: fullString)
        contentFull.addAttributes([.font: UIFont.systemFont(ofSize: 12), .foregroundColor: (self.traitCollection.userInterfaceStyle == .dark ? UIColor.white : UIColor.black)], range: NSRange(location: 0, length: fullString.count))
        if let range = fullString.range(of: valueDevice) {
            let index = fullString.distance(from: fullString.startIndex, to: range.lowerBound)
            contentFull.addAttributes([.font: UIFont.systemFont(ofSize: 12, weight: .medium)], range: NSRange(location: index, length: valueDevice.count))
        }
        if let range = fullString.range(of: valueAccount) {
            let index = fullString.distance(from: fullString.startIndex, to: range.lowerBound)
            contentFull.addAttributes([.foregroundColor: UIColor.blueTextField], range: NSRange(location: index, length: valueAccount.count))
        }
        if let range = fullString.range(of: valueCode) {
            let index = fullString.distance(from: fullString.startIndex, to: range.lowerBound)
            contentFull.addAttributes([.font: UIFont.systemFont(ofSize: 18, weight: .medium)], range: NSRange(location: index, length: valueCode.count))
        }
        if let range = fullString.range(of: sContent4) {
            let index = fullString.distance(from: fullString.startIndex, to: range.lowerBound)
            contentFull.addAttributes([.foregroundColor: UIColor.systemRed], range: NSRange(location: index, length: sContent4.count))
        }
        
        let contentS = UILabel()
        contentS.attributedText = contentFull
        contentS.numberOfLines = 0
        container.addSubview(contentS)
        contentS.anchor(top: title.bottomAnchor, left: container.leftAnchor, right: container.rightAnchor, paddingTop: 15, paddingLeft: 15, paddingRight: 10)
        
        let footer = UILabel()
        footer.text = "We value your security".localized()
        footer.font = .systemFont(ofSize: 12)
        footer.textColor = .gray
        footer.numberOfLines = 0
        container.addSubview(footer)
        footer.anchor(top: contentS.bottomAnchor, bottom: container.bottomAnchor, right: container.rightAnchor, paddingTop: 10, paddingBottom: 5, paddingRight: 10)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissView))
        tapGesture.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tapGesture)
        
    }
    
    @objc func dismissView() {
        self.dismiss(animated: true)
    }
}

public class DialogSecurityShield: UIViewController {
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .black.withAlphaComponent(0.5)
        
        let container = UIView()
        self.view.addSubview(container)
        container.anchor(top: self.view.topAnchor, left: self.view.leftAnchor, right: self.view.rightAnchor, paddingTop: 30, paddingLeft: 20, paddingRight: 20)
        container.layer.cornerRadius = 20.0
        container.clipsToBounds = true
        container.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : .white
        
        let title = UILabel()
        title.text = "Your Account is Protected".localized()
        title.font = .systemFont(ofSize: 14, weight: .medium)
        title.numberOfLines = 0
        title.textAlignment = .center
        title.textColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .black
        container.addSubview(title)
        title.anchor(top: container.topAnchor, paddingTop: 15, centerX: container.centerXAnchor, maxWidth: 270)
        
        let imageWarning = UIImageView(image: UIImage(named: "pb_security_warning_green", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!)
        container.addSubview(imageWarning)
        imageWarning.anchor(top: container.topAnchor, right: title.leftAnchor, paddingTop: 10, paddingRight: 5, width: 30, height: 30)
        
        let imageChat = UIImageView(image: UIImage(named: "pb_startup_iconsuffix", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!)
        container.addSubview(imageChat)
        imageChat.anchor(top: container.topAnchor, right: container.rightAnchor, paddingTop: 10, paddingRight: 20, width: 30, height: 30)
        
        let sContent1 = "Security Shield has been activated for your Peace of Mind...".localized()
        let sContent2 = "Account & Transaction Protection".localized()
        let sContent3 = "Early Threat Detection".localized()
        let sContent4 = "Emergency Data Control".localized()
        let sContent5 = "Please feel free to contact us for more information.".localized()
        let fullString = sContent1 + "\n\u{2022}" + String(repeating: "\u{00a0}", count: 2) + sContent2 + "\n\u{2022}" + String(repeating: "\u{00a0}", count: 2) + sContent3 + "\n\u{2022}" + String(repeating: "\u{00a0}", count: 2) + sContent4 + "\n" + sContent5;
        
        let contentS = UILabel()
        contentS.text = fullString
        contentS.textColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .black
        contentS.numberOfLines = 0
        contentS.font = .systemFont(ofSize: 12)
        container.addSubview(contentS)
        contentS.anchor(top: title.bottomAnchor, left: container.leftAnchor, right: container.rightAnchor, paddingTop: 15, paddingLeft: 15, paddingRight: 10)
        
        let buttonCC = UIButton(type: .custom)
        let backgroundImageKYC = resizeImage(image: UIImage(named: "pb_startup_cc", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, targetSize: CGSize(width: UIScreen.main.bounds.width / 3 - 20, height: 35))
        buttonCC.setBackgroundImage(backgroundImageKYC, for: .normal)
        buttonCC.imageView?.contentMode = .scaleAspectFill
        buttonCC.addTarget(self, action: #selector(ccTapped), for: .touchUpInside)
        buttonCC.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        container.addSubview(buttonCC)
        buttonCC.anchor(top: contentS.bottomAnchor, paddingTop: 10, centerX: container.centerXAnchor, width: UIScreen.main.bounds.width / 3 - 20, height: 35)
        
        let buttonActive = UIButton(type: .custom)
        let backgroundImageTryAgain = resizeImage(image: UIImage(named: "pb_startup_activate", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, targetSize: CGSize(width: UIScreen.main.bounds.width / 3 - 20, height: 35))
        buttonActive.setBackgroundImage(backgroundImageTryAgain, for: .normal)
        buttonActive.imageView?.contentMode = .scaleAspectFill
        buttonActive.addTarget(self, action: #selector(activateTapped), for: .touchUpInside)
        buttonActive.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        container.addSubview(buttonActive)
        buttonActive.anchor(top: contentS.bottomAnchor, right: buttonCC.leftAnchor, paddingTop: 10, width: UIScreen.main.bounds.width / 3 - 20, height: 35)
        
        let buttonDeactive = UIButton(type: .custom)
        let backgroundImageCancel = resizeImage(image: UIImage(named: "pb_startup_deactivate", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, targetSize: CGSize(width: UIScreen.main.bounds.width / 3 - 20, height: 35))
        buttonDeactive.setBackgroundImage(backgroundImageCancel, for: .normal)
        buttonDeactive.imageView?.contentMode = .scaleAspectFill
        buttonDeactive.addTarget(self, action: #selector(deactiveTapped), for: .touchUpInside)
        buttonDeactive.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        container.addSubview(buttonDeactive)
        buttonDeactive.anchor(top: contentS.bottomAnchor, left: buttonCC.rightAnchor, paddingTop: 10, width: UIScreen.main.bounds.width / 3 - 20, height: 35)
        
        let footer = UILabel()
        footer.text = "We value your security".localized()
        footer.font = .systemFont(ofSize: 12)
        footer.textColor = .gray
        footer.numberOfLines = 0
        container.addSubview(footer)
        footer.anchor(top: buttonDeactive.bottomAnchor, bottom: container.bottomAnchor, right: container.rightAnchor, paddingBottom: 5, paddingRight: 10)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissView))
        tapGesture.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tapGesture)
        
    }
    
    @objc func ccTapped() {
        //print("ccTapped")
        self.dismiss(animated: true, completion: {
            APIS.openContactCenter()
        })
    }
    
    @objc func activateTapped() {
        //print("activateTapped")
        self.dismiss(animated: true)
    }
    
    @objc func deactiveTapped() {
        //print("deactiveTapped")
        self.dismiss(animated: true)
    }
    
    @objc func dismissView() {
        self.dismiss(animated: true)
    }
}

public class DialogTransactionApproval: UIViewController {
    
    public var valueLink = "https://hdtrack.com"
    public var valueAmount = "$142.90"
    public var packetId = ""
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .black.withAlphaComponent(0.5)
        
        let container = UIView()
        self.view.addSubview(container)
        container.anchor(top: self.view.topAnchor, left: self.view.leftAnchor, right: self.view.rightAnchor, paddingTop: 30, paddingLeft: 20, paddingRight: 20)
        container.layer.cornerRadius = 20.0
        container.clipsToBounds = true
        container.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : .white
        
        let title = UILabel()
        title.text = "Transaction Approval Request".localized()
        title.font = .systemFont(ofSize: 14, weight: .medium)
        title.numberOfLines = 0
        title.textAlignment = .center
        title.textColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .black
        container.addSubview(title)
        title.anchor(top: container.topAnchor, paddingTop: 15, centerX: container.centerXAnchor, maxWidth: 270)
        
        let imageWarning = UIImageView(image: UIImage(named: "pb_security_warning", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!)
        container.addSubview(imageWarning)
        imageWarning.anchor(top: container.topAnchor, right: title.leftAnchor, paddingTop: 10, paddingRight: 5, width: 30, height: 30)
        
        let imageChat = UIImageView(image: UIImage(named: "pb_startup_iconsuffix", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!)
        container.addSubview(imageChat)
        imageChat.anchor(top: container.topAnchor, right: container.rightAnchor, paddingTop: 10, paddingRight: 20, width: 30, height: 30)
        
        let sContent1 = "We have detected a".localized()
        let sContent1a = "Rp."
        let sContent2 = "transaction using credit card no. XXXX-XXXX-XXXX-1234 on".localized()
        let sContent3 = "Before processing your payment, kindly verify and confirm the transaction details.".localized()
        let fullString = sContent1 + " " + sContent1a + " " + formatText(valueAmount) + " " + sContent2 + " " + valueLink + ".\n\n" + sContent3
        let contentFull = NSMutableAttributedString(string: fullString)
        contentFull.addAttributes([.font: UIFont.systemFont(ofSize: 12), .foregroundColor: (self.traitCollection.userInterfaceStyle == .dark ? UIColor.white : UIColor.black)], range: NSRange(location: 0, length: fullString.count))
        if let range = fullString.range(of: valueLink) {
            let index = fullString.distance(from: fullString.startIndex, to: range.lowerBound)
            contentFull.addAttributes([.foregroundColor: UIColor.red, .underlineStyle: NSUnderlineStyle.single.rawValue, .link: URL(string: valueLink)!], range: NSRange(location: index, length: valueLink.count))
        }
        
        let contentS = UILabel()
        contentS.attributedText = contentFull
        contentS.numberOfLines = 0
        container.addSubview(contentS)
        contentS.anchor(top: title.bottomAnchor, left: container.leftAnchor, right: container.rightAnchor, paddingTop: 15, paddingLeft: 15, paddingRight: 10)
        contentS.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(labelTapped))
        contentS.addGestureRecognizer(tapGesture)
        
        let buttonCC = UIButton(type: .custom)
        let backgroundImageKYC = resizeImage(image: UIImage(named: "pb_startup_cc", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, targetSize: CGSize(width: UIScreen.main.bounds.width / 3 - 20, height: 35))
        buttonCC.setBackgroundImage(backgroundImageKYC, for: .normal)
        buttonCC.imageView?.contentMode = .scaleAspectFill
        buttonCC.addTarget(self, action: #selector(ccTapped), for: .touchUpInside)
        buttonCC.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        container.addSubview(buttonCC)
        buttonCC.anchor(top: contentS.bottomAnchor, paddingTop: 10, centerX: container.centerXAnchor, width: UIScreen.main.bounds.width / 3 - 20, height: 35)
        
        let buttonApprove = UIButton(type: .custom)
        let backgroundImageTryAgain = resizeImage(image: UIImage(named: "pb_security_approve", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, targetSize: CGSize(width: UIScreen.main.bounds.width / 3 - 20, height: 35))
        buttonApprove.setBackgroundImage(backgroundImageTryAgain, for: .normal)
        buttonApprove.imageView?.contentMode = .scaleAspectFill
        buttonApprove.addTarget(self, action: #selector(approveTapped), for: .touchUpInside)
        buttonApprove.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        container.addSubview(buttonApprove)
        buttonApprove.anchor(top: contentS.bottomAnchor, right: buttonCC.leftAnchor, paddingTop: 10, width: UIScreen.main.bounds.width / 3 - 20, height: 35)
        
        let buttonReject = UIButton(type: .custom)
        let backgroundImageCancel = resizeImage(image: UIImage(named: "pb_security_reject", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, targetSize: CGSize(width: UIScreen.main.bounds.width / 3 - 20, height: 35))
        buttonReject.setBackgroundImage(backgroundImageCancel, for: .normal)
        buttonReject.imageView?.contentMode = .scaleAspectFill
        buttonReject.addTarget(self, action: #selector(rejectTapped), for: .touchUpInside)
        buttonReject.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        container.addSubview(buttonReject)
        buttonReject.anchor(top: contentS.bottomAnchor, left: buttonCC.rightAnchor, paddingTop: 10, width: UIScreen.main.bounds.width / 3 - 20, height: 35)
        
        let footer = UILabel()
        footer.text = "We value your security".localized()
        footer.font = .systemFont(ofSize: 12)
        footer.textColor = .gray
        footer.numberOfLines = 0
        container.addSubview(footer)
        footer.anchor(top: buttonReject.bottomAnchor, bottom: container.bottomAnchor, right: container.rightAnchor, paddingBottom: 5, paddingRight: 10)
        
    }
    
    @objc func ccTapped() {
        //print("ccTapped")
        self.dismiss(animated: true, completion: {
            APIS.openContactCenter()
        })
    }
    
    @objc func approveTapped() {
        //print("approveTapped")
//        _ = Nexilis.responseString(packetId: packetId, message: "00", timeout: 3000)
        self.dismiss(animated: true)
    }
    
    @objc func rejectTapped() {
        //print("rejectTapped")
//        _ = Nexilis.responseString(packetId: packetId, message: "00", timeout: 3000)
        self.dismiss(animated: true)
    }
    
    @objc func labelTapped(sender: UITapGestureRecognizer) {
        guard let url = URL(string: valueLink) else { return }
        UIApplication.shared.open(url)
    }
    
    func formatText(_ s: String) -> String {
        let text = s
        if text.isEmpty { return "" }
        
        let cleanString = text.replacingOccurrences(of: "[^\\d]", with: "", options: .regularExpression)
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "en_US")
        let formattedString = formatter.string(from: NSNumber(value: Int(cleanString)!)) ?? ""
        
        return formattedString
    }
}

public class ValidationTransactionLimit: UIViewController, UITextFieldDelegate {
    var textField = UITextField()
    var formatter = NumberFormatter()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.topItem?.backButtonTitle = ""
        
        let title = UILabel()
        title.text = "Set a transation validation amount".localized()
        title.font = .systemFont(ofSize: 18, weight: .medium)
        title.numberOfLines = 0
        title.textColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .mainColor
        self.view.addSubview(title)
        title.anchor(top: self.view.safeAreaLayoutGuide.topAnchor, left: self.view.leftAnchor, right: self.view.rightAnchor, paddingTop: 10, paddingLeft: 20, paddingRight: 20)
        
        let content = UILabel()
        content.text = "Any transaction over this amount will display an alert and require you to accept the alert to validate before proceeding with the transaction".localized()
        content.font = .systemFont(ofSize: 14)
        content.numberOfLines = 0
        content.textColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .mainColor
        self.view.addSubview(content)
        content.anchor(top: title.bottomAnchor, left: self.view.leftAnchor, right: self.view.rightAnchor, paddingTop: 5, paddingLeft: 20, paddingRight: 20)
        
        self.view.addSubview(textField)
        textField.anchor(top: content.bottomAnchor, left: self.view.leftAnchor, right: self.view.rightAnchor, paddingTop: 5, paddingLeft: 20, paddingRight: 20, height: 40)
        textField.textAlignment = .center
        textField.keyboardType = .numberPad
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.gray.cgColor
        textField.layer.cornerRadius = 10
        textField.clipsToBounds = true
        textField.text = formatText(Utils.getLimitValidTrans())
        
        textField.delegate = self
        
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        navigationController?.navigationBar.topItem?.backButtonTitle = ""
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Submit".localized(), style: .plain, target: self, action: #selector(submit))
        
        let attributes = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 16.0), NSAttributedString.Key.foregroundColor: UIColor.white]
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : UIColor.mainColor
        navBarAppearance.titleTextAttributes = attributes
        navigationController?.navigationBar.standardAppearance = navBarAppearance
        navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance
        self.navigationController?.navigationBar.topItem?.title = "Validation Transaction Limit".localized()
        self.navigationController?.navigationBar.setNeedsLayout()
        self.title = "Validation Transaction Limit".localized()
    }
    
    @objc func submit() {
        if !textField.text!.isEmpty {
            var text = textField.text!
            text = text.replacingOccurrences(of: ",", with: "", options: .regularExpression)
            Utils.setLimitValidTrans(value: text)
            let imageView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
            imageView.tintColor = .white
            let banner = FloatingNotificationBanner(title: "Successfully changed".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .success, colors: nil, iconPosition: .center)
            banner.show()
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard string != "\n" else {
           return true
        }
        let currentText = textField.text ?? ""
        let newText = (currentText as NSString).replacingCharacters(in: range, with: string)
        let formattedNumber = formatText(newText)
        if formattedNumber.count <= 13 {
            textField.text = formattedNumber
        }
       return false
    }

    func formatText(_ s: String) -> String {
        let text = s
        if text.isEmpty { return "" }
        
        let cleanString = text.replacingOccurrences(of: "[^\\d]", with: "", options: .regularExpression)
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "en_US")
        let formattedString = formatter.string(from: NSNumber(value: Int(cleanString)!)) ?? ""
        
        return formattedString
    }
}

public class DialogErrorMFA: UIViewController {
    
    public var errorDesc = ""
    public var method = ""
    public var hideTryAgain = false
    public var countRetry = 1
    var isDismiss: ((Int) -> ())?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .black.withAlphaComponent(0.5)
        
        let container = UIView()
        self.view.addSubview(container)
        container.anchor(top: self.view.topAnchor, left: self.view.leftAnchor, right: self.view.rightAnchor, paddingTop: 30, paddingLeft: 20, paddingRight: 20)
        container.layer.cornerRadius = 20.0
        container.clipsToBounds = true
        container.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : .white
        
        let title = UILabel()
        title.text = errorDesc
        title.font = .boldSystemFont(ofSize: 14)
        title.numberOfLines = 0
        title.textAlignment = .center
        title.textColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .black
        container.addSubview(title)
        title.anchor(top: container.topAnchor, paddingTop: 15, centerX: container.centerXAnchor, maxWidth: UIScreen.main.bounds.width / 2)
        
        let imageWarning = UIImageView(image: UIImage(named: "pb_security_warning_green", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!)
        container.addSubview(imageWarning)
        imageWarning.anchor(top: container.topAnchor, right: title.leftAnchor, paddingTop: 10, paddingRight: -5, width: 30, height: 30)
        
        let imageLogo = UIImageView(image: UIImage(named: "pb_icon"))
        container.addSubview(imageLogo)
        imageLogo.anchor(top: container.topAnchor, left: container.leftAnchor, paddingTop: 10, paddingLeft: 10, width: 40, height: 40)
        
        let imageChat = UIImageView(image: UIImage(named: "pb_startup_iconsuffix", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!)
        container.addSubview(imageChat)
        imageChat.anchor(top: container.topAnchor, right: container.rightAnchor, paddingTop: 10, paddingRight: 10, width: 30, height: 30)
        
        var contentDesc = "Pastikan data yang anda masukkan benar dan valid!"
        contentDesc += "\nMaksimal Percobaan 3 kali. (\(countRetry)/3)"
        contentDesc += "\nAktivitas: \(method)"
//        if hideTryAgain {
//            contentDesc = "Silakan hubungi Contact Center BJB untuk bantuan lebih lanjut atau Silahkan Sign Up/Sign In Ulang"
//        }
        let contentS = UILabel()
        contentS.tintColor = .label
        contentS.attributedText = contentDesc.richText()
        contentS.numberOfLines = 0
        container.addSubview(contentS)
        contentS.anchor(top: title.bottomAnchor, left: container.leftAnchor, right: container.rightAnchor, paddingTop: 20, paddingLeft: 15, paddingRight: 10)
        
//        let buttonCC = UIButton(type: .custom)
//        buttonCC.setTitle("Call Center", for: .normal)
//        buttonCC.backgroundColor = .gray
//        buttonCC.titleLabel?.textColor = .white
//        buttonCC.titleLabel?.font = .boldSystemFont(ofSize: 14)
//        buttonCC.layer.cornerRadius = 17.5
//        buttonCC.clipsToBounds = true
//        buttonCC.addTarget(self, action: #selector(ccTapped), for: .touchUpInside)
//        container.addSubview(buttonCC)
//        if !hideTryAgain {
//            buttonCC.anchor(top: contentS.bottomAnchor, paddingTop: 20, centerX: container.centerXAnchor, width: UIScreen.main.bounds.width / 3 - 30, height: 35)
//        } else {
//            buttonCC.anchor(top: contentS.bottomAnchor, left: container.leftAnchor, paddingTop: 20, paddingLeft: 5, width: UIScreen.main.bounds.width / 2 - 30, height: 35)
//        }
        
        let buttonTryAgain = UIButton(type: .custom)
        buttonTryAgain.setTitle("Coba Lagi", for: .normal)
        buttonTryAgain.backgroundColor = .blue
        buttonTryAgain.titleLabel?.textColor = .white
        buttonTryAgain.titleLabel?.font = .boldSystemFont(ofSize: 14)
        buttonTryAgain.layer.cornerRadius = 17.5
        buttonTryAgain.clipsToBounds = true
        buttonTryAgain.addTarget(self, action: #selector(tryAgainTapped), for: .touchUpInside)
        
        let buttonReject = UIButton(type: .custom)
        buttonReject.setTitle("Tutup", for: .normal)
        buttonReject.backgroundColor = .red
        buttonReject.titleLabel?.textColor = .white
        buttonReject.titleLabel?.font = .boldSystemFont(ofSize: 14)
        buttonReject.layer.cornerRadius = 17.5
        buttonReject.clipsToBounds = true
        buttonReject.addTarget(self, action: #selector(rejectTapped), for: .touchUpInside)
        
        let stack = UIStackView(arrangedSubviews: [buttonTryAgain, buttonReject])
        stack.axis = .horizontal
        stack.spacing = 10
        stack.alignment = .center
        stack.distribution = .fillEqually
        container.addSubview(stack)
        stack.anchor(top: contentS.bottomAnchor, left: container.leftAnchor, right: container.rightAnchor, paddingTop: 10, paddingLeft: 15, paddingRight: 15, height: 35)
        
        let footer = UILabel()
        footer.text = "We value your security".localized()
        footer.font = .systemFont(ofSize: 12)
        footer.textColor = .gray
        footer.numberOfLines = 0
        container.addSubview(footer)
        footer.anchor(top: stack.bottomAnchor, bottom: container.bottomAnchor, right: container.rightAnchor, paddingBottom: 5, paddingRight: 10)
        
    }
    
    private func getContentDesc() -> String {
        return "Saya mengalami hambatan pada waktu *\(method)*, dikarenakan *\(errorDesc)*"
    }
    
    @objc func ccTapped() {
        let contentDesc = getContentDesc()
        self.dismiss(animated: true, completion: { [self] in
            APIS.openContactCenterWithContext(context: "\(contentDesc)~\(method)~\(errorDesc)")
        })
    }
    
    @objc func tryAgainTapped() {
        self.dismiss(animated: true, completion: {
            self.isDismiss?(1)
        })
    }
    
    @objc func rejectTapped() {
        self.dismiss(animated: true)
        self.isDismiss?(0)
    }
}

public class DialogBroadcastInApp: UIViewController {
    
    public var form: FormM!
    public var formItem: FormItemM!
    public var labelForm = ""
    public var listTitleButton: [String] = []
    public var message: [String: Any] = [:]
    
    private var iconTitleImage: UIImage?
    private var iconSuffixImage: UIImage?
    private var buttonBackgroundImages: [Int: UIImage] = [:]
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .black.withAlphaComponent(0.3)
        DispatchQueue.global().async {
            self.loadDataAndBuildUI()
        }
    }
    
    private func setupUI() {
        let container = UIView()
        self.view.addSubview(container)
        container.anchor(left: self.view.leftAnchor, right: self.view.rightAnchor, paddingLeft: 20, paddingRight: 20, centerY: self.view.centerYAnchor)
        container.layer.cornerRadius = 20.0
        container.clipsToBounds = true
        container.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : .white
        
        let title = UILabel()
        title.text = form.title
        title.font = .boldSystemFont(ofSize: 14)
        title.numberOfLines = 0
        title.textAlignment = .center
        title.textColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .black
        container.addSubview(title)
        title.anchor(top: container.topAnchor, paddingTop: 15, centerX: container.centerXAnchor, maxWidth: UIScreen.main.bounds.width / 2)
        
        let defaultWarningImage = UIImage(named: "pb_security_warning_green", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)
        let imageWarning = UIImageView(image: self.iconTitleImage ?? defaultWarningImage)
        container.addSubview(imageWarning)
        imageWarning.anchor(top: container.topAnchor, right: title.leftAnchor, paddingTop: 10, paddingRight: -5, width: 30, height: 30)
        
        let imageLogo = UIImageView(image: UIImage(named: "pb_icon"))
        container.addSubview(imageLogo)
        imageLogo.anchor(top: container.topAnchor, left: container.leftAnchor, paddingTop: 10, paddingLeft: 10, width: 40, height: 40)
        
        let defaultChatImage = UIImage(named: "pb_startup_iconsuffix", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)
        let imageChat = UIImageView(image: self.iconSuffixImage ?? defaultChatImage)
        container.addSubview(imageChat)
        imageChat.anchor(top: container.topAnchor, right: container.rightAnchor, paddingTop: 10, paddingRight: 10, width: 30, height: 30)
        
        let content = labelForm
        var contentAtt = NSAttributedString(string: "")
        let contentS = UITextView()
        contentS.tintColor = .label
        if HtmlUtils.hasHtmlTag(content) {
            contentAtt = HtmlUtils.toHTMLPreview(content)
            contentS.attributedText = contentAtt
        } else {
            contentS.attributedText = content.richText()
        }
        contentS.isEditable = false
        contentS.isScrollEnabled = false
        contentS.dataDetectorTypes = [.link]
        container.addSubview(contentS)
        contentS.anchor(top: title.bottomAnchor, left: container.leftAnchor, right: container.rightAnchor, paddingTop: 20, paddingLeft: 15, paddingRight: 10)
        
        let spacing: CGFloat = 5
        let buttonHeight: CGFloat = 35
        let maxPerRow = 3
        let parentWidth = UIScreen.main.bounds.width - 40
        
        let containerButton = UIView()
        container.addSubview(containerButton)
        containerButton.anchor(top: contentS.bottomAnchor, left: container.leftAnchor, right: container.rightAnchor, width: parentWidth)
        
        
        let buttonWidth = (parentWidth - (CGFloat(maxPerRow + 1) * spacing)) / CGFloat(maxPerRow)
        var finalRow = 1
        for (index, title) in listTitleButton.enumerated() {
            let row = index / maxPerRow
            let col = index % maxPerRow
            
            let x = spacing + CGFloat(col) * (buttonWidth + spacing)
            let y = spacing + CGFloat(row) * (buttonHeight + spacing)
            
            var finalTitleButton = title
            if title.starts(with: "call_") {
                finalTitleButton = "Call " + title.component(1, separatedBy: "_")
            } else if title == "cc" {
                finalTitleButton = "Contact Center"
            }
            
            let button = UIButton(type: .system)
            button.frame = CGRect(x: x, y: y, width: buttonWidth, height: buttonHeight)
            button.layer.cornerRadius = 17.5
            button.clipsToBounds = true
            button.titleLabel?.font = .boldSystemFont(ofSize: 14)
            button.setTitleColor(.white, for: .normal)
            button.addAction{ btn in
                if title == "cc" {
                    if self.form.formId == "212953" || self.form.formId == "112903"{
                        APIS.openContactCenterWithContext(context: self.formItem.label + "~Transaction~Credit Card~Fraud")
                    } else {
                        APIS.openContactCenterWithContext(context: self.formItem.label)
                    }
                } else if title.starts(with: "call_") {
                    var phone = Utils.getCallCenter()
                    if phone.substring(from: 0, to: 0) == "0" {
                        phone = "+62" + phone.substring(from: 1, to: phone.count)
                    }
                    if let url = URL(string: "tel://\(phone)") {
                        UIApplication.shared.open(url)
                    }
                } else {
                    Database.shared.database?.inTransaction({ (fmdb, rollback) in
                        _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE", cvalues: [
                            "ex_book" : self.message[CoreMessage_TMessageKey.MESSAGE_TEXT] ?? ""
                        ], _where: "message_id = '\(self.message[CoreMessage_TMessageKey.MESSAGE_ID] ?? "")'")
                    })
                    let messageText = self.message[CoreMessage_TMessageKey.MESSAGE_TEXT] as? String ?? ""
                    var messageTextSend = ""
                    if var json = try! JSONSerialization.jsonObject(with: messageText.data(using: String.Encoding.utf8)!, options: JSONSerialization.ReadingOptions()) as? [String: Any] {
                        Database.shared.database?.inTransaction({ fmdb, rollback in
                            if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "select * from FORM_ITEM where form_id = '\(self.formItem.formId)'"), cursor.next() {
                                for columnIndex in 0..<cursor.columnCount {
                                    if let columnName = cursor.columnName(for: columnIndex) {
                                        if let value = cursor.object(forColumn: columnName) {
                                            if columnName == "key" {
                                                json[value as? String ?? ""] = title
                                                break
                                            }
                                        }
                                    }
                                }
                                cursor.close()
                            }
                            if let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
                               let jsonString = String(data: jsonData, encoding: .utf8) {
                                messageTextSend = jsonString
                            }
                        })
                    }
                    let message = CoreMessage_TMessageBank.sendMessage(l_pin: self.form.formId, message_scope_id: MessageScope.FORM, status: "1", message_text: messageTextSend, credential: "0", attachment_flag: "", ex_blog_id: "", message_large_text: "", ex_format: "", image_id: "", audio_id: "", video_id: "", file_id: self.form.formId, thumb_id: "", reff_id: "", read_receipts: "4", chat_id: "", is_call_center: "0", call_center_id: "", opposite_pin: "", specFile: "")
                    OutgoingThread.default.addQueue(message: message)
                    self.dismiss(animated: true)
                }
            }

            if formItem.background.isEmpty {
                button.setTitle(finalTitleButton, for: .normal)
                button.backgroundColor = .systemBlue
            } else {
                let backgrounds = formItem.background.components(separatedBy: ",")
                if index < backgrounds.count {
                    button.setTitle("", for: .normal)
                    if let img =  buttonBackgroundImages[index] {
                        button.setBackgroundImage(img.resizableImage(withCapInsets: .zero, resizingMode: .stretch), for: .normal)
                    }
                }
            }
            
            containerButton.addSubview(button)
            finalRow = row + 1
        }
        
        containerButton.heightAnchor.constraint(equalToConstant: CGFloat(35 * finalRow)).isActive = true
        
        let footer = UILabel()
        footer.text = form.footer
        footer.font = .systemFont(ofSize: 12)
        footer.textColor = .gray
        footer.numberOfLines = 0
        container.addSubview(footer)
        footer.anchor(top: containerButton.bottomAnchor, bottom: container.bottomAnchor, right: container.rightAnchor, paddingTop: 10, paddingBottom: 5, paddingRight: 10)
    }
    
    private func loadDataAndBuildUI() {
        let semaphore = DispatchSemaphore(value: 0)
        if !form.iconTitle.isEmpty {
            getImage(name: form.iconTitle) { result, _, image in
                if result, let img = image {
                    self.iconTitleImage = img
                    semaphore.signal()
                }
            }
            semaphore.wait()
        }
        if !form.iconSuffix.isEmpty {
            getImage(name: form.iconSuffix) { result, _, image in
                if result, let img = image {
                    self.iconSuffixImage = img
                    semaphore.signal()
                }
            }
            semaphore.wait()
        }
        if !formItem.background.isEmpty {
            let backgrounds = formItem.background.components(separatedBy: ",")
            for (index, backgroundName) in backgrounds.enumerated() {
                getImage(name: backgroundName, isResized: false) { result, _, image in
                    if result, let img = image {
                        self.buttonBackgroundImages[index] = img
                        semaphore.signal()
                    }
                }
                semaphore.wait()
            }
        }
        DispatchQueue.main.async {
            self.setupUI()
        }
    }
}

class LocationManager: NSObject, CLLocationManagerDelegate {
    private var locationManager = CLLocationManager()

    override init() {
        super.init()

        self.locationManager.delegate = self
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
        
        if let location = locationManager.location {
            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude
            Utils.latitude = "\(latitude)"
            Utils.longitude = "\(longitude)"
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //print("didUpdateLocations")
        if let location = locations.last {
            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude
            Utils.latitude = "\(latitude)"
            Utils.longitude = "\(longitude)"
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        //print("Failed to find user's location: \(error.localizedDescription)")
    }
}

public extension Utils {
    /// Whether attachments fetch themselves as they come into view.
    ///
    /// On unless the reader has turned it off. The preference is only ever written when the
    /// switch in Settings is used, so nothing stored means it was never touched - which is why
    /// the default belongs here rather than at each place that reads it.
    static var isAutoDownloadOn: Bool {
        return SecureUserDefaults.shared.value(forKey: "autoDownload") ?? true
    }
}

public class SecureUserDefaults {
    public static let shared = SecureUserDefaults()
    private let defaults: UserDefaults

    /// What has already been decoded, kept so it is decoded once.
    ///
    /// Fix: reading one of these is a read from the store, an AES decrypt and a JSON decode, and
    /// a few of them - the signed-in pin, the chosen language - are read over and over while a
    /// single screen is drawn: every chat bubble asked for both. Nothing outside this class
    /// writes these keys, and every way of changing one goes through set or removeValue below,
    /// so what is held here cannot fall behind what is stored.
    private var cache: [String: Any] = [:]
    private let cacheLock = NSLock()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // Save a value
    public func set<T: Codable>(_ value: T, forKey key: String) {
        let encoder = JSONEncoder()
        guard let encodedData = try? encoder.encode(value),
              let encryptedData = try? MasterKeyUtil.shared.encryptP(data: encodedData) else {
            return
        }
        defaults.set(encryptedData, forKey: key)
        cacheLock.lock()
        cache[key] = value
        cacheLock.unlock()
    }

    // Retrieve a value
    public func value<T: Codable>(forKey key: String) -> T? {
        cacheLock.lock()
        let cached = cache[key]
        cacheLock.unlock()
        if let cached = cached {
            // The same cast the decode would have had to satisfy: a value stored as one type
            // and asked for as another is nil here exactly as it was before.
            return cached as? T
        }
        guard let encryptedData = defaults.data(forKey: key),
              let decryptedData = try? MasterKeyUtil.shared.decryptP(data: encryptedData) else {
//            print("Failed to decrypt data \(key)")
            return nil
        }
        let decoder = JSONDecoder()
        guard let decoded = try? decoder.decode(T.self, from: decryptedData) else {
            return nil
        }
        cacheLock.lock()
        cache[key] = decoded
        cacheLock.unlock()
        return decoded
    }

    // Remove a value
    public func removeValue(forKey key: String) {
        defaults.removeObject(forKey: key)
        cacheLock.lock()
        cache.removeValue(forKey: key)
        cacheLock.unlock()
    }
}

public class MessageScope {
    public static let GLOBAL = "1";
    public static let LOCAL = "2";
    public static let WHISPER = "3";
    public static let GROUP = "4";
    public static let CHATROOM = "5";
    public static let PLACE = "6";
    public static let BUDDY = "7";
    public static let FOLLOWER = "8";
    public static let APP = "9";
    public static let BLOG = "10";
    public static let BOT = "11";
    public static let CALL = "12";
    public static let QUOTE = "13";
    public static let DRAW = "14";
    public static let SMS = "15";
    public static let EMAIL = "16";
    public static let LIVE_BRAODCAST = "17";
    public static let FORM = "18";
    public static let MISSED_CALL = "19";
    public static let VIDEO_ATTACHMNET = "20";
    public static let UNREAD_COUNT = "21";
    public static let FAVORITE = "22";
    public static let CALENDAR = "23";
    public static let PILPRES = "25";
    public static let CHATBOT = "26";
    public static let BROADCAST_HISTORY = "30";
    public static let GPT_CHATBOT = "31";
    public static let COMMUNITY = "32";
    public static let CHANNEL = "33";
}

class SecureField : UITextField {

    override init(frame: CGRect) {
        super.init(frame: .zero)
        self.isSecureTextEntry = true
        self.translatesAutoresizingMaskIntoConstraints = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    weak var secureContainer: UIView? {
        let secureView = self.subviews.filter({ subview in
            type(of: subview).description().contains("CanvasView")
        }).first
        secureView?.translatesAutoresizingMaskIntoConstraints = false
        secureView?.isUserInteractionEnabled = true //To enable child view's userInteraction in iOS 13
        return secureView
    }
    
    override var canBecomeFirstResponder: Bool {false}
    override func becomeFirstResponder() -> Bool {false}
}



/// One picture of the conversation, filling the screen and zoomable on its own.
///
/// A page owns its zooming, so moving between pictures is the collection view's job and
/// nothing has to be torn down and set up again on the way past.
final class MediaPageCell: UICollectionViewCell, UIScrollViewDelegate {
    let zoomView = UIScrollView()
    let imageView = SDAnimatedImageView()
    private let videoBadge = UIImageView(image: UIImage(systemName: "play.circle.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 56, weight: .regular)))
    private var loadingName: String?
    private static let loadQueue = DispatchQueue(label: "MediaPage.pictures", qos: .userInitiated)

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(zoomView)
        zoomView.frame = contentView.bounds
        zoomView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        zoomView.delegate = self
        zoomView.minimumZoomScale = 1.0
        zoomView.maximumZoomScale = 3.0
        zoomView.showsVerticalScrollIndicator = false
        zoomView.showsHorizontalScrollIndicator = false
        zoomView.bouncesZoom = true
        zoomView.backgroundColor = .clear
        // Each page carries its own scroll view for zooming, and it runs the full height under the
        // bar as well, so it would draw the same system edge fade the pager does.
        if #available(iOS 26.0, *) {
            zoomView.topEdgeEffect.isHidden = true
            zoomView.bottomEdgeEffect.isHidden = true
            zoomView.leftEdgeEffect.isHidden = true
            zoomView.rightEdgeEffect.isHidden = true
        }

        zoomView.addSubview(imageView)
        imageView.frame = zoomView.bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageView.contentMode = .scaleAspectFit

        contentView.addSubview(videoBadge)
        videoBadge.tintColor = UIColor.white.withAlphaComponent(0.9)
        videoBadge.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            videoBadge.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            videoBadge.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        zoomView.setZoomScale(1.0, animated: false)
        imageView.image = nil
        loadingName = nil
    }

    /// Video pages show their poster here; the player itself belongs to the screen, which puts
    /// it over whichever page has settled.
    func configure(with item: MediaViewerViewController.StripItem, isVideoHost: Bool) {
        // Never: the screen puts a real, tappable play button over a video page as soon as it is
        // shown, so this drew a second one that could not be pressed - and the two crossed over as
        // the page settled.
        videoBadge.isHidden = true
        let name = item.isVideo ? item.thumbFileName : (item.mediaFileName.isEmpty ? item.thumbFileName : item.mediaFileName)
        loadingName = name
        guard !name.isEmpty else {
            imageView.image = nil
            return
        }
        if let cached = Nexilis.imageCache.object(forKey: ("page-" + name) as NSString) {
            imageView.image = cached
            return
        }
        imageView.image = MediaStripCell.thumbnail(named: item.thumbFileName)
        MediaPageCell.loadQueue.async { [weak self] in
            let image = MediaPageCell.picture(named: name)
            DispatchQueue.main.async {
                guard let self = self, self.loadingName == name, let image = image else {
                    return
                }
                self.imageView.image = image
            }
        }
    }

    private static func picture(named name: String) -> UIImage? {
        let key = ("page-" + name) as NSString
        if let cached = Nexilis.imageCache.object(forKey: key) {
            return cached
        }
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        guard let dirPath = paths.first else {
            return nil
        }
        let url = URL(fileURLWithPath: dirPath).appendingPathComponent(name)
        var data: Data?
        if FileManager.default.fileExists(atPath: url.path) {
            data = try? Data(contentsOf: url)
        } else if FileEncryption.shared.isSecureExists(filename: name) {
            if var secure = try? FileEncryption.shared.readSecure(filename: name) {
                if let decrypted = FileEncryption.shared.decryptFileFromServer(data: secure) {
                    secure = decrypted
                }
                data = secure
            }
        }
        guard let data = data else {
            return nil
        }
        let image = SDAnimatedImage(data: data) ?? UIImage(data: data)
        if let image = image {
            Nexilis.imageCache.setObject(image, forKey: key)
        }
        return image
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let size = imageView.frame.size
        let bounds = scrollView.bounds.size
        let vertical = size.height < bounds.height ? (bounds.height - size.height) / 2 : 0
        let horizontal = size.width < bounds.width ? (bounds.width - size.width) / 2 : 0
        scrollView.contentInset = UIEdgeInsets(top: vertical, left: horizontal, bottom: vertical, right: horizontal)
    }
}

/// One thumbnail in the strip along the foot of the viewer.
final class MediaStripCell: UICollectionViewCell {
    let imageView = UIImageView()
    private let videoBadge = UIImageView(image: UIImage(systemName: "play.fill"))

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        imageView.frame = contentView.bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        contentView.layer.cornerRadius = 4
        contentView.clipsToBounds = true
        contentView.addSubview(videoBadge)
        videoBadge.tintColor = .white
        videoBadge.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            videoBadge.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            videoBadge.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            videoBadge.widthAnchor.constraint(equalToConstant: 14),
            videoBadge.heightAnchor.constraint(equalToConstant: 14)
        ])
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    /// The one being looked at is wider and outlined; the rest keep their own brightness.
    ///
    /// Fix: the others used to be drawn at 55% opacity, which is invisible when the pictures are
    /// pale - a strip of screenshots came out as a row of grey smudges. Size and an outline say
    /// which one is current without taking the others' colour away.
    var isCurrent: Bool = false {
        didSet {
            contentView.layer.cornerRadius = isCurrent ? 5 : 2
            contentView.layer.borderWidth = isCurrent ? 2 : 0
            contentView.layer.borderColor = UIColor.white.cgColor
            imageView.alpha = 1.0
        }
    }

    /// The file this cell is waiting for. A cell is handed from one thumbnail to the next as
    /// the strip scrolls, and the answer to the one it used to hold must not land in it.
    private var loadingName: String?

    /// Reading and decoding a hundred small pictures does not belong on the shared pool.
    ///
    /// Fix: it was on DispatchQueue.global(), which this app fills with calls blocked on the
    /// socket - so the work was queued behind them and the strip stayed a row of empty grey
    /// boxes. Its own queue cannot be held up by anything but itself.
    private static let loadQueue = DispatchQueue(label: "MediaStrip.thumbnails", qos: .userInitiated)

    func configure(with item: MediaViewerViewController.StripItem) {
        videoBadge.isHidden = !item.isVideo
        // The thumbnail if there is one, the picture itself if there is not.
        let name = item.thumbFileName.isEmpty ? item.mediaFileName : item.thumbFileName
        loadingName = name
        guard !name.isEmpty else {
            imageView.image = nil
            return
        }
        if let cached = Nexilis.imageCache.object(forKey: name as NSString) {
            imageView.image = cached
            return
        }
        imageView.image = nil
        MediaStripCell.loadQueue.async { [weak self] in
            let image = MediaStripCell.thumbnail(named: name)
            DispatchQueue.main.async {
                guard let self = self, self.loadingName == name else {
                    return
                }
                self.imageView.image = image
            }
        }
    }

    static func thumbnail(named name: String) -> UIImage? {
        if let cached = Nexilis.imageCache.object(forKey: name as NSString) {
            return cached
        }
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        guard let dirPath = paths.first else {
            return nil
        }
        let url = URL(fileURLWithPath: dirPath).appendingPathComponent(name)
        var image: UIImage?
        if FileManager.default.fileExists(atPath: url.path) {
            image = UIImage(contentsOfFile: url.path)
        } else if FileEncryption.shared.isSecureExists(filename: name) {
            if var data = try? FileEncryption.shared.readSecure(filename: name) {
                if let decrypted = FileEncryption.shared.decryptFileFromServer(data: data) {
                    data = decrypted
                }
                image = UIImage(data: data)
            }
        }
        guard let resized = image?.resize(target: CGSize(width: 200, height: 200)) else {
            return image
        }
        Nexilis.imageCache.setObject(resized, forKey: name as NSString)
        return resized
    }
}

extension MediaViewerViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return stripItems.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard indexPath.item < stripItems.count else {
            return collectionView.dequeueReusableCell(withReuseIdentifier: collectionView === pager ? "page" : "strip", for: indexPath)
        }
        let item = stripItems[indexPath.item]
        if collectionView === pager {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "page", for: indexPath)
            (cell as? MediaPageCell)?.configure(with: item, isVideoHost: indexPath.item == currentStripIndex)
            return cell
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "strip", for: indexPath)
        guard let stripCell = cell as? MediaStripCell else {
            return cell
        }
        stripCell.isCurrent = indexPath.item == highlightedStripIndex
        stripCell.configure(with: item)
        return stripCell
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard collectionView !== pager else {
            return
        }
        showStripItem(at: indexPath.item)
    }
}

extension MediaViewerViewController: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView === pager {
            return collectionView.bounds.size
        }
        return indexPath.item == highlightedStripIndex
            ? MediaViewerViewController.stripCurrentItemSize
            : MediaViewerViewController.stripItemSize
    }
}

class MediaViewerViewController: UIViewController, UIGestureRecognizerDelegate, UIScrollViewDelegate {
    
    enum MediaType {
        case image(UIImage)
        case gif(Data)
        case video(URL)
    }

    /// One picture or video of the conversation, as the strip along the bottom needs it.
    public struct StripItem {
        public let messageId: String
        public let thumbFileName: String
        /// The full-size file, so the viewer can move to this one on its own.
        public let mediaFileName: String
        public let isVideo: Bool
        public let caption: String
        public let title: String
        public let subtitle: String
        public let isStarred: Bool

        public init(messageId: String, thumbFileName: String, mediaFileName: String, isVideo: Bool,
                    caption: String, title: String, subtitle: String, isStarred: Bool) {
            self.messageId = messageId
            self.thumbFileName = thumbFileName
            self.mediaFileName = mediaFileName
            self.isVideo = isVideo
            self.caption = caption
            self.title = title
            self.subtitle = subtitle
            self.isStarred = isStarred
        }
    }

    var media: MediaType!

    public let backgroundView = UIView()
    public var titleCustom = ""
    public var subtitleCustom = ""
    /// What was written with the picture, drawn across the bottom of it.
    public var caption = ""
    /// Every picture and video of the conversation, for the strip along the bottom.
    /// Set by whoever opens this screen on a video, so it plays without being asked twice.
    public var autoPlaysOnOpen = false
    public var stripItems: [StripItem] = []
    /// Which of them is on screen.
    public var currentStripIndex = 0 {
        didSet { highlightedStripIndex = currentStripIndex }
    }
    /// Which of them the strip is drawing as current, which runs ahead of the picture during a
    /// drag.
    private var highlightedStripIndex = 0
    /// Asked for by the strip when another picture is chosen.
    public var onAllMedia: ((String) -> Void)?
    public var onGoToMessage: ((String) -> Void)?
    public var onShare: ((String) -> Void)?
    public var onForward: ((String) -> Void)?
    public var onStar: ((String) -> Void)?
    public var onDelete: ((String) -> Void)?
    /// Told which picture was on screen when the viewer closed, so the conversation behind it
    /// can be left showing that one rather than the one that was tapped several swipes ago.
    public var onDismiss: ((String) -> Void)?
    /// Told each time the picture changes, so the conversation underneath can move with it -
    /// then closing the viewer lands on the right message rather than scrolling there after.
    public var onMediaChanged: ((String) -> Void)?

    /// The message the viewer is showing right now, which is what every action above is about.
    public var currentMessageId: String {
        guard currentStripIndex >= 0, currentStripIndex < stripItems.count else {
            return ""
        }
        return stripItems[currentStripIndex].messageId
    }
    /// Whether this picture is already starred, for which way round to draw the star.
    public var isStarred = false
    private let scrollView = UIScrollView()
    private let imageView = SDAnimatedImageView()
    private var statusBarBackgroundView: UIView!
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private let playPauseButton = UIButton(type: .custom)
    /// The band of playback controls that sits under the title while a video is open.
    private let videoBar = UIView()
    private let pipButton = UIButton(type: .system)
    private var pictureInPicture: AVPictureInPictureController?
    /// Carries the player layer, so it is never inside a cell that gets handed to another picture.
    private let videoHost = UIView()
    private var hasBuiltVideoChrome = false
    /// Held so the previous video's ticker can be taken off before the next one puts one on.
    private var timeObserverToken: Any?
    private var isVideoPlaying = false
    public var isSecure = false
    
    private let timeCurrentLabel = UILabel()
    private let timeRemainingLabel = UILabel()
    private let speedButton = UIButton(type: .system)
    private let slider = UISlider()

    private var playbackSpeeds: [Float] = [1.0, 1.5, 2.0, 0.5]
    private var currentSpeedIndex = 0

    var isNavigationBarHidden = false {
        didSet { setNeedsStatusBarAppearanceUpdate() }
    }

    override var prefersStatusBarHidden: Bool {
        return isNavigationBarHidden
    }
    
    private var privacyOverlay: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        return view
    }()
    
    private let blurBackground: UIVisualEffectView = {
        let blur = UIBlurEffect(style: .dark)
        let view = UIVisualEffectView(effect: blur)
        view.alpha = 0.45
        view.layer.cornerRadius = 14
        view.clipsToBounds = true
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .clear
        
        guard let secureView = SecureField().secureContainer else {return}
        if isSecure {
            setupPrivacyOverlay()
            self.view.addSubview(secureView)
        }

        edgesForExtendedLayout = .all
        extendedLayoutIncludesOpaqueBars = true
        navigationController?.navigationBar.isTranslucent = true
        
        if !titleCustom.isEmpty {
            setNavigationTitle(title: titleCustom, subtitle: subtitleCustom)
        }

        // Background view
        backgroundView.backgroundColor = .black
        backgroundView.alpha = 0
        backgroundView.frame = view.bounds
        if isSecure {
            secureView.addSubview(backgroundView)
        } else {
            view.addSubview(backgroundView)
        }

        // The video player still needs somewhere to live; the pictures no longer do.
        scrollView.frame = view.bounds
        scrollView.isUserInteractionEnabled = false
        if isSecure {
            secureView.addSubview(scrollView)
        } else {
            view.addSubview(scrollView)
        }

        setupPager()
        setupTopScrim()

        if stripItems.isEmpty {
            // Opened on something the strip does not carry - a picture that can only be seen
            // once, say. There is nothing to page through, so it is shown on its own the way it
            // always was, and the pager stays out of the way.
            pager.isHidden = true
            scrollView.isUserInteractionEnabled = true
            scrollView.delegate = self
            scrollView.minimumZoomScale = 1.0
            scrollView.maximumZoomScale = 3.0
            scrollView.showsVerticalScrollIndicator = false
            scrollView.showsHorizontalScrollIndicator = false
            scrollView.bouncesZoom = true
            imageView.frame = scrollView.bounds
            imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            imageView.contentMode = .scaleAspectFit
            scrollView.addSubview(imageView)
            configureMedia()
        }

        // Tap gesture to toggle navigation bar
        let tap = UITapGestureRecognizer(target: self, action: #selector(toggleNavigationBar))
        tap.numberOfTapsRequired = 1
        // Fix: a recogniser on the view cancels the touches under it by default, so a tap on a
        // thumbnail in the strip never reached the strip - it just toggled the chrome.
        tap.cancelsTouchesInView = false
        tap.delegate = self
        view.addGestureRecognizer(tap)

        // Pan gesture for swipe-to-dismiss
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.delegate = self
        panGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(panGesture)

        // Fix: a solid strip in the app's colour used to sit across the status bar, and the
        // navigation bar under it was opaque - so a picture stopped short of the top of the
        // screen and was framed rather than shown. The picture now runs the whole height and
        // the chrome floats over it, which is what a viewer is for.
        statusBarBackgroundView = UIView(frame: .zero)
        statusBarBackgroundView.isHidden = true
        view.addSubview(statusBarBackgroundView)
        makeNavigationBarTransparent()
        setupBottomChrome()
        highlightedStripIndex = currentStripIndex
        // The pager has no pages until it has been laid out, so where it opens is settled on the
        // next turn - before anything is shown, and without an animation to see.
        DispatchQueue.main.async { [weak self] in
            guard let self = self, !self.stripItems.isEmpty else {
                return
            }
            guard self.currentStripIndex < self.stripItems.count else {
                return
            }
            self.pager.layoutIfNeeded()
            self.movePager(to: self.currentStripIndex, animated: false)
            self.adoptCurrentPage()
            self.stripCollection.scrollToItem(at: IndexPath(item: self.currentStripIndex, section: 0), at: .centeredHorizontally, animated: false)
        }
    }

    /// Lets the picture run behind the bar rather than beginning underneath it.
    private func makeNavigationBarTransparent() {
        guard let bar = navigationController?.navigationBar else {
            return
        }
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        appearance.shadowColor = .clear
        bar.standardAppearance = appearance
        bar.scrollEdgeAppearance = appearance
        bar.compactAppearance = appearance
        bar.isTranslucent = true
        bar.tintColor = .white
        bar.overrideUserInterfaceStyle = .dark
        // Fix: an appearance is not the whole story. backgroundColor and barTintColor are set
        // straight onto the bar by the shared style this viewer is opened with, and they paint
        // over a transparent appearance - which is why the top stayed blue.
        bar.backgroundColor = .clear
        bar.barTintColor = nil
        bar.shadowImage = UIImage()
        bar.setBackgroundImage(UIImage(), for: .default)
    }
    



    // MARK: - The blur behind the bar

    private let topScrim = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
    private let topScrimMask = CAGradientLayer()

    /// How much of the material is laid over the picture.
    ///
    /// Set on the view rather than in the mask. The mask decides where the blur reaches and how it
    /// fades; alpha decides how strong it is, and composites in proportion, so this figure is the
    /// one to turn when the header wants more or less of it.
    private static let topScrimStrength: CGFloat = 0.6

    /// A light blur behind the bar, fading out downwards.
    ///
    /// Deliberately slight. The picture keeps its colours and shapes; what the blur takes off is
    /// the fine detail that competes with the lettering. Most of the readability is carried by the
    /// halo on the letters themselves, which only darkens the pixels hugging the strokes - so this
    /// can stay thin enough to see straight through.
    private func setupTopScrim() {
        topScrimMask.colors = [
            UIColor.black.cgColor,
            UIColor.black.cgColor,
            UIColor.black.withAlphaComponent(0.6).cgColor,
            UIColor.black.withAlphaComponent(0.25).cgColor,
            UIColor.clear.cgColor
        ]
        topScrimMask.locations = [0.0, 0.35, 0.65, 0.85, 1.0]
        topScrim.layer.mask = topScrimMask
        topScrim.alpha = MediaViewerViewController.topScrimStrength
        topScrim.isUserInteractionEnabled = false
        view.addSubview(topScrim)
    }

    private func layoutTopScrim() {
        // Kept above the pictures, which are added and moved beneath it as pages come and go.
        view.bringSubviewToFront(topScrim)
        let height = (navigationController?.navigationBar.frame.maxY ?? 88) + 40
        topScrim.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: height)
        topScrimMask.frame = topScrim.bounds
    }

    // MARK: - The pager

    private var pager: UICollectionView!
    /// True while the pager is being put where it belongs, so its own scrolling is not mistaken
    /// for the reader turning a page.
    private var isSettingPagerPosition = false

    /// The pictures of the conversation, side by side, one screen wide each.
    ///
    /// Fix: moving between pictures used to be three views shifted by hand with a transform.
    /// That can only ever be worth one picture per drag, it leaves a seam where the views meet
    /// - the black the reader kept seeing across the top - and the strip has to guess how far
    /// along the finger is. A paging collection view is what this always was: the pages are
    /// contiguous, one drag can run the length of the conversation without being lifted, and
    /// how far along it is arrives as a contentOffset rather than as a guess.
    private func setupPager() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = .zero
        pager = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        pager.isPagingEnabled = true
        pager.backgroundColor = .clear
        pager.showsHorizontalScrollIndicator = false
        pager.dataSource = self
        pager.delegate = self
        pager.contentInsetAdjustmentBehavior = .never
        pager.register(MediaPageCell.self, forCellWithReuseIdentifier: "page")
        pager.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        // The dark band across the top of the picture was never ours. From iOS 26 a scroll view
        // sitting under a bar gets an edge effect for free - a soft fade so bar buttons stay
        // readable over whatever scrolls past. It is drawn by the system, keyed to the bar being
        // visible, and takes the bar's dark style, which is why it survived every scrim of ours
        // being removed. Measured off a pair of screenshots of the same picture with the bar shown
        // and hidden, it peaked at 0.85 opacity and ran 150pt down. Turned off on all four edges:
        // this is a full-screen media pager, where nothing should be laid over the picture.
        if #available(iOS 26.0, *) {
            pager.topEdgeEffect.isHidden = true
            pager.bottomEdgeEffect.isHidden = true
            pager.leftEdgeEffect.isHidden = true
            pager.rightEdgeEffect.isHidden = true
        }
        if isSecure, let secureView = SecureField().secureContainer {
            secureView.addSubview(pager)
        } else {
            view.addSubview(pager)
        }
        videoHost.isUserInteractionEnabled = false
        videoHost.isHidden = true
        videoHost.backgroundColor = .clear
        view.addSubview(videoHost)
    }

    /// Puts the pager on a page without it counting as the reader turning one.
    private func movePager(to index: Int, animated: Bool) {
        guard index >= 0, index < stripItems.count, pager != nil else {
            return
        }
        isSettingPagerPosition = true
        pager.scrollToItem(at: IndexPath(item: index, section: 0), at: .centeredHorizontally, animated: animated)
        if !animated {
            isSettingPagerPosition = false
        }
    }

    /// Which page the pager has come to rest on.
    private func pageIndex() -> Int {
        guard pager != nil, pager.bounds.width > 0 else {
            return currentStripIndex
        }
        return max(0, min(stripItems.count - 1, Int(round(pager.contentOffset.x / pager.bounds.width))))
    }

    /// Everything that is about the picture rather than about the page carrying it.
    private func adoptCurrentPage() {
        let index = pageIndex()
        guard index >= 0, index < stripItems.count else {
            return
        }
        let changed = index != currentStripIndex
        currentStripIndex = index
        let item = stripItems[index]

        showChrome(for: index)
        highlightStrip(at: index)
        prepareVideoIfNeeded(for: item)
        if changed {
            onMediaChanged?(item.messageId)
        }
    }

    /// What is written around the picture: who sent it, when, its caption, whether it is starred.
    ///
    /// Kept apart from settling on a page so it can run while the picture is still moving. It used
    /// to be done only once the scroll had finished, which left the name and the date belonging to
    /// the picture the reader had just left while the next one was already most of the way across.
    /// This changes at the same moment the strip marks its new thumbnail, so the whole screen
    /// speaks about one picture at a time.
    private func showChrome(for index: Int) {
        guard index >= 0, index < stripItems.count, index != chromeShowingIndex else {
            return
        }
        chromeShowingIndex = index
        let item = stripItems[index]
        caption = item.caption
        captionLabel.text = item.caption.mentionsAsNames()
        // Fix: this reached for the label's superview, which since the caption was put inside a
        // scroll view is the scroll view - not the box in the stack that has to collapse. Showing
        // and hiding the wrong view left the caption absent whatever the picture carried.
        captionBox?.isHidden = item.caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        // Another picture, another caption - so the one just read is not left open over it.
        isCaptionExpanded = false
        captionLabel.numberOfLines = MediaViewerViewController.collapsedCaptionLines
        captionScroll.setContentOffset(.zero, animated: false)
        refreshCaptionHeight()
        isStarred = item.isStarred
        buildActionBar()
        if !item.title.isEmpty {
            setNavigationTitle(title: item.title, subtitle: item.subtitle)
        }
        // The player is only torn down once the scroll settles, so scrubbing quickly off a video
        // left its button and its control band sitting over a photograph. Anything belonging to a
        // video goes the moment the picture on screen is not one.
        if item.isVideo {
            // Fix: the button and the control band are built the first time a video is set up, and
            // a viewer opened on a photograph has never done that - so scrubbing along to a video
            // set `isHidden = false` on a button that was not in the view at all. Built here too,
            // where the page being a video is first known.
            buildVideoChromeIfNeeded()
            view.setNeedsLayout()
        }
        playPauseButton.isHidden = !item.isVideo || isVideoPlaying
        if !item.isVideo {
            videoBar.isHidden = true
        }
    }

    /// Which picture the writing around the screen is currently describing.
    private var chromeShowingIndex = -1

    /// A video page borrows the screen's player; every other page needs it gone.
    private func prepareVideoIfNeeded(for item: StripItem) {
        stopVideo()
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
            timeObserverToken = nil
        }
        if let item = player?.currentItem {
            NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: item)
        }
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
        player = nil
        isVideoPlaying = false
        videoHost.isHidden = true
        let videoChrome = [playPauseButton, blurBackground, videoBar] as [UIView]
        videoChrome.forEach { $0.isHidden = true }
        videoPageIndex = -1
        guard item.isVideo else {
            return
        }
        videoPageIndex = stripItems.firstIndex(where: { $0.messageId == item.messageId }) ?? -1
        videoChrome.forEach { $0.isHidden = false }
        if let known = resolvedVideoURLs[item.messageId] {
            setupVideo(url: known)
            return
        }
        // Fix: an encrypted video was read, decrypted and written out to a temporary file here, on
        // the main thread, the instant a page settled - so every swipe onto or off a video stalled
        // for as long as that took. It is done away from the main thread now, and the answer is
        // kept so coming back to the same video costs nothing.
        playPauseButton.isHidden = true
        videoBeingResolved = item.messageId
        let wanted = item.messageId
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard case .video(let url)? = MediaViewerViewController.loadMedia(for: item) else {
                return
            }
            DispatchQueue.main.async {
                guard let self = self, self.videoBeingResolved == wanted else {
                    return
                }
                self.resolvedVideoURLs[wanted] = url
                self.setupVideo(url: url)
            }
        }
    }

    /// Where each video was found, so a second visit does not decrypt and write it out again.
    private var resolvedVideoURLs: [String: URL] = [:]
    /// Which video is being fetched, so an answer for one the reader has already left is dropped.
    private var videoBeingResolved = ""
    /// Which page the playing video belongs to, so its layer can travel with that page.
    private var videoPageIndex = -1

    /// Keeps the video sitting on its own page rather than over the whole screen.
    ///
    /// Fix: the player layer was carried by a view the width of the screen that never moved, so
    /// swiping off a video left the video painted on top of whatever was sliding in underneath it
    /// until the scroll settled - which is what made leaving a video look broken rather than
    /// merely slow. It now tracks its page exactly, and slides away with it.
    private func positionVideoHost() {
        guard videoPageIndex >= 0, pager != nil, pager.bounds.width > 0 else {
            return
        }
        let x = CGFloat(videoPageIndex) * pager.bounds.width - pager.contentOffset.x
        videoHost.frame = CGRect(x: x, y: 0, width: view.bounds.width, height: view.bounds.height)
    }

    /// The picture on screen right now, for a transition to grow out of or shrink back into.
    public func currentPictureView() -> UIImageView? {
        guard pager != nil,
              let cell = pager.cellForItem(at: IndexPath(item: currentStripIndex, section: 0)) as? MediaPageCell else {
            return imageView
        }
        return cell.imageView
    }

    /// Moves to one of the conversation's pictures by name.
    ///
    /// For the browser pushed on top of this screen: choosing a picture there comes back to here
    /// rather than to the conversation, and this is how it says which one.
    public func show(messageId: String) {
        guard let index = stripItems.firstIndex(where: { $0.messageId == messageId }) else {
            return
        }
        showStripItem(at: index, animated: false)
    }

    /// Shows another of the conversation's pictures. Everything else follows from the page.
    func showStripItem(at index: Int, animated: Bool = true) {
        guard index >= 0, index < stripItems.count else {
            return
        }
        movePager(to: index, animated: animated)
        if !animated {
            adoptCurrentPage()
        }
    }

    /// Which thumbnail is drawn as the current one, without changing what is on screen.
    func highlightStrip(at index: Int, scrollIntoView: Bool = true) {
        guard index != highlightedStripIndex, index >= 0, index < stripItems.count else {
            return
        }
        let previous = highlightedStripIndex
        highlightedStripIndex = index
        // Only the two that change, and only their size - reloading the strip would throw away
        // every thumbnail still on its way and leave a row of grey boxes.
        for cellIndex in [previous, index] where cellIndex >= 0 && cellIndex < stripItems.count {
            if let cell = stripCollection.cellForItem(at: IndexPath(item: cellIndex, section: 0)) as? MediaStripCell {
                cell.isCurrent = cellIndex == index
            }
        }
        // `performBatchUpdates` re-runs the layout for the whole strip and animates it. Once per
        // picture that is nothing; during a flick it lands twenty times a second, on the main
        // thread, while the strip is trying to decelerate - which is what made the drag feel
        // heavy and cut a fast swipe short. The current thumbnail still marks itself out by its
        // border above; its width settles once the strip comes to rest.
        if !isScrubbingStrip {
            stripCollection.performBatchUpdates(nil)
        }
        // Not while the reader is dragging the strip itself - moving it under their finger is a
        // fight they cannot win.
        guard scrollIntoView else {
            return
        }
        stripCollection.scrollToItem(at: IndexPath(item: index, section: 0), at: .centeredHorizontally, animated: true)
    }

    /// True while the strip is being dragged, so the picture is following the strip rather than
    /// the other way round.
    private var isScrubbingStrip = false

    /// Moves the picture to whichever thumbnail the strip has arrived under its middle.
    private func scrubFromStrip() {
        guard stripCollection.bounds.width > 0, stripItems.count > 1 else {
            return
        }
        let middle = CGPoint(x: stripCollection.contentOffset.x + stripCollection.bounds.width / 2,
                             y: stripCollection.bounds.midY)
        guard let index = nearestStripItem(to: middle), index != pageIndex() else {
            return
        }
        // Straight to the offset rather than `scrollToItem`, which goes through the layout to work
        // out where it is being asked to go. The pager is paged and every page is a screen wide,
        // so where page N starts is simply N screens along.
        highlightStrip(at: index, scrollIntoView: false)
        showChrome(for: index)
        isSettingPagerPosition = true
        pager.setContentOffset(CGPoint(x: CGFloat(index) * pager.bounds.width, y: 0), animated: false)
        isSettingPagerPosition = false
    }

    /// Which thumbnail is under a point - falling back to the nearest one when the point lands in
    /// the gap between two.
    private func nearestStripItem(to point: CGPoint) -> Int? {
        if let indexPath = stripCollection.indexPathForItem(at: point) {
            return indexPath.item
        }
        var best: Int?
        var shortest = CGFloat.greatestFiniteMagnitude
        for cell in stripCollection.visibleCells {
            let distance = abs(cell.center.x - point.x)
            if distance < shortest, let indexPath = stripCollection.indexPath(for: cell) {
                shortest = distance
                best = indexPath.item
            }
        }
        return best
    }

    private func endStripScrub() {
        isScrubbingStrip = false
        adoptCurrentPage()
        // The width the current thumbnail was owed while the strip was moving is given to it now.
        stripCollection.performBatchUpdates(nil)
        stripCollection.scrollToItem(at: IndexPath(item: pageIndex(), section: 0), at: .centeredHorizontally, animated: true)
    }

    /// Keeps how long a video runs, so nothing has to open the file to find out again.
    ///
    /// The length is not sent with a message, and a video kept in the secure store cannot be asked
    /// without being decrypted whole - which is not work a grid of thumbnails should start. So it
    /// is written down the first time something has the file open for its own reasons, and read
    /// from the database ever after.
    public static func rememberVideoDuration(seconds: Int, messageId: String) {
        guard seconds > 0, !messageId.isEmpty else {
            return
        }
        DispatchQueue.global(qos: .utility).async {
            Database.shared.database?.inTransaction({ (fmdb, rollback) in
                do {
                    _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE", cvalues: [
                        "video_duration": seconds
                    ], _where: "message_id = '\(messageId)'")
                } catch {
                    rollback.pointee = true
                }
            })
        }
    }

    /// Reads one of the conversation's files, from wherever it is kept.
    static func loadMedia(for item: StripItem) -> MediaType? {
        let name = item.mediaFileName.isEmpty ? item.thumbFileName : item.mediaFileName
        guard !name.isEmpty else {
            return nil
        }
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        guard let dirPath = paths.first else {
            return nil
        }
        let url = URL(fileURLWithPath: dirPath).appendingPathComponent(name)
        if item.isVideo {
            if FileManager.default.fileExists(atPath: url.path) {
                return .video(url)
            }
            // An encrypted file has to be written out before anything can play it.
            guard var data = try? FileEncryption.shared.readSecure(filename: name) else {
                return nil
            }
            if let decrypted = FileEncryption.shared.decryptFileFromServer(data: data) {
                data = decrypted
            }
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(name)
            guard (try? data.write(to: tempURL)) != nil else {
                return nil
            }
            return .video(tempURL)
        }
        var data: Data?
        if FileManager.default.fileExists(atPath: url.path) {
            data = try? Data(contentsOf: url)
        } else if FileEncryption.shared.isSecureExists(filename: name) {
            if var secure = try? FileEncryption.shared.readSecure(filename: name) {
                if let decrypted = FileEncryption.shared.decryptFileFromServer(data: secure) {
                    secure = decrypted
                }
                data = secure
            }
        }
        guard let data = data, let image = UIImage(data: data) else {
            return nil
        }
        return .image(image)
    }


    // MARK: - Bottom chrome


    /// The strip is a row of small, tightly packed thumbnails with the one being looked at
    /// standing out from them - twice as wide, at its full size, with room either side. That
    /// difference is the only thing saying which picture is on screen, so it has to be plain.
    static let stripItemSize = CGSize(width: 24, height: 40)
    static let stripCurrentItemSize = CGSize(width: 46, height: 40)

    private let captionLabel = UILabel()
    /// How much of a caption is shown before it has been asked for.
    private static let collapsedCaptionLines = 2
    private var isCaptionExpanded = false
    private let captionScroll = UIScrollView()
    private var captionHeight: NSLayoutConstraint!
    /// The box in the bottom stack that the caption lives in - what collapses when there is none.
    private weak var captionBox: UIView?
    private var isMeasuringCaption = false

    /// Opens a caption out to its full length, and folds it back.
    ///
    /// The tap that shows and hides the chrome does not reach here - touches inside the bottom
    /// stack are already its own - so this is the only thing a tap on the caption does.
    @objc private func toggleCaption() {
        isCaptionExpanded.toggle()
        captionLabel.numberOfLines = isCaptionExpanded ? 0 : MediaViewerViewController.collapsedCaptionLines
        UIView.animate(withDuration: 0.2) {
            self.refreshCaptionHeight()
            self.view.layoutIfNeeded()
        }
    }

    /// How tall the caption is allowed to be, and whether it has to be scrolled to be read.
    ///
    /// Opened out, it may grow until its top would reach the header - no further. A caption that
    /// needs more room than that keeps the room and is read by scrolling, so the strip and the
    /// row of actions are never pushed off the screen by somebody's long message.
    private func refreshCaptionHeight() {
        // Belt as well as braces: setting the constraint lays out again, which comes back here.
        guard captionHeight != nil, view.bounds.width > 0, !isMeasuringCaption else {
            return
        }
        isMeasuringCaption = true
        defer { isMeasuringCaption = false }
        let width = max(1, view.bounds.width - 32)
        let text = captionLabel.text ?? ""
        let full = ceil((text as NSString).boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: captionLabel.font as Any],
            context: nil).height)
        let collapsed = ceil(captionLabel.font.lineHeight * CGFloat(MediaViewerViewController.collapsedCaptionLines))

        let wanted: CGFloat
        if isCaptionExpanded {
            // Fix: this measured the room as the bottom stack's height minus the caption's own -
            // and the caption's height is what this method then sets. Each layout pass fed the
            // next a different answer, and the screen span in that loop rather than settling,
            // which is why nothing on it would respond. The other rows are measured directly, so
            // nothing here depends on the value being worked out.
            let others = bottomStack.arrangedSubviews
                .filter { $0 !== captionBox && !$0.isHidden }
                .reduce(CGFloat(0)) { $0 + $1.frame.height }
            let headerBottom = navigationController?.navigationBar.frame.maxY ?? view.safeAreaInsets.top
            let room = view.bounds.height - headerBottom - others - 32
            wanted = min(full, max(collapsed, room))
        } else {
            wanted = min(full, collapsed)
        }
        captionScroll.isScrollEnabled = isCaptionExpanded && full > wanted + 1
        guard abs(captionHeight.constant - wanted) > 0.5 else {
            return
        }
        captionHeight.constant = wanted
    }
    private let bottomStack = UIStackView()
    private var stripCollection: UICollectionView!
    private let actionBar = UIStackView()

    /// What sits over the foot of the picture: what was written with it, every other picture of
    /// the conversation, and what can be done with this one - the same three things, in the same
    /// order, that a reader expects from a photo viewer.
    private func setupBottomChrome() {
        bottomStack.axis = .vertical
        bottomStack.spacing = 0
        bottomStack.alignment = .fill
        view.addSubview(bottomStack)
        bottomStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bottomStack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomStack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomStack.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // The caption, if there was one.
        let captionContainer = UIView()
        // Inside a scroll view, so a caption longer than the screen can be read through rather
        // than either running off the bottom or pushing the strip and the actions out of sight.
        captionScroll.translatesAutoresizingMaskIntoConstraints = false
        captionScroll.showsHorizontalScrollIndicator = false
        captionScroll.isScrollEnabled = false
        captionContainer.addSubview(captionScroll)
        captionScroll.addSubview(captionLabel)
        captionLabel.translatesAutoresizingMaskIntoConstraints = false
        captionHeight = captionScroll.heightAnchor.constraint(equalToConstant: 40)
        NSLayoutConstraint.activate([
            captionScroll.leadingAnchor.constraint(equalTo: captionContainer.leadingAnchor, constant: 16),
            captionScroll.trailingAnchor.constraint(equalTo: captionContainer.trailingAnchor, constant: -16),
            captionScroll.topAnchor.constraint(equalTo: captionContainer.topAnchor, constant: 10),
            captionScroll.bottomAnchor.constraint(equalTo: captionContainer.bottomAnchor, constant: -10),
            captionHeight,
            captionLabel.leadingAnchor.constraint(equalTo: captionScroll.contentLayoutGuide.leadingAnchor),
            captionLabel.trailingAnchor.constraint(equalTo: captionScroll.contentLayoutGuide.trailingAnchor),
            captionLabel.topAnchor.constraint(equalTo: captionScroll.contentLayoutGuide.topAnchor),
            captionLabel.bottomAnchor.constraint(equalTo: captionScroll.contentLayoutGuide.bottomAnchor),
            captionLabel.widthAnchor.constraint(equalTo: captionScroll.frameLayoutGuide.widthAnchor)
        ])
        captionLabel.textColor = .white
        captionLabel.font = UIFont.systemFont(ofSize: 15)
        MediaViewerViewController.applyTextShadow(to: captionLabel)
        captionLabel.numberOfLines = MediaViewerViewController.collapsedCaptionLines
        captionLabel.lineBreakMode = .byTruncatingTail
        // Fix: a caption was shown exactly as it is stored, and a mention is stored as the pin it
        // points at - so a caption that named somebody read "@0254321". The same reading the
        // conversation gives it.
        captionLabel.text = caption.mentionsAsNames()
        // Long captions are cut short until they are asked for.
        captionLabel.isUserInteractionEnabled = true
        captionLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(toggleCaption)))
        captionContainer.isHidden = caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        captionBox = captionContainer
        bottomStack.addArrangedSubview(captionContainer)
        refreshCaptionHeight()

        // Every other picture of the conversation.
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = MediaViewerViewController.stripItemSize
        layout.minimumLineSpacing = 2
        layout.minimumInteritemSpacing = 2
        layout.sectionInset = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
        stripCollection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        stripCollection.backgroundColor = .clear
        stripCollection.showsHorizontalScrollIndicator = false
        stripCollection.dataSource = self
        stripCollection.delegate = self
        stripCollection.register(MediaStripCell.self, forCellWithReuseIdentifier: "strip")
        stripCollection.translatesAutoresizingMaskIntoConstraints = false
        stripCollection.heightAnchor.constraint(equalToConstant: 50).isActive = true
        stripCollection.isHidden = stripItems.count < 2
        // A flick should carry a long way through a conversation's pictures rather than stopping
        // a few thumbnails along.
        stripCollection.decelerationRate = .normal
        stripCollection.alwaysBounceHorizontal = true
        bottomStack.addArrangedSubview(stripCollection)

        // What can be done with this one.
        actionBar.axis = .horizontal
        actionBar.distribution = .fillEqually
        actionBar.alignment = .center
        actionBar.isLayoutMarginsRelativeArrangement = true
        actionBar.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 10, leading: 8, bottom: 6, trailing: 8)
        bottomStack.addArrangedSubview(actionBar)
        buildActionBar()

        view.bringSubviewToFront(bottomStack)

        // Dark enough for white to read on, over any picture.
        let scrim = UIView()
        scrim.backgroundColor = UIColor.black.withAlphaComponent(0.75)
        scrim.isUserInteractionEnabled = false
        bottomStack.insertSubview(scrim, at: 0)
        scrim.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrim.topAnchor.constraint(equalTo: bottomStack.topAnchor),
            scrim.leadingAnchor.constraint(equalTo: bottomStack.leadingAnchor),
            scrim.trailingAnchor.constraint(equalTo: bottomStack.trailingAnchor),
            scrim.bottomAnchor.constraint(equalTo: bottomStack.bottomAnchor)
        ])
    }

    private func buildActionBar() {
        actionBar.arrangedSubviews.forEach { $0.removeFromSuperview() }
        // Fix: this asked whether a player existed, and the row is rebuilt before the previous
        // video is torn down - so arriving on a picture still found the player of the video just
        // left and kept offering play. What matters is what is on screen, which the strip knows.
        let showingVideo: Bool
        if chromeShowingIndex >= 0, chromeShowingIndex < stripItems.count {
            showingVideo = stripItems[chromeShowingIndex].isVideo
        } else {
            showingVideo = player != nil
        }
        let items: [(String, Selector, Bool)] = [
            ("square.and.arrow.up", #selector(tapShare), onShare != nil),
            ("arrowshape.turn.up.right", #selector(tapForward), onForward != nil),
            (isVideoPlaying ? "pause.fill" : "play.fill", #selector(togglePlayPause), showingVideo),
            (isStarred ? "star.fill" : "star", #selector(tapStar), onStar != nil),
            ("trash", #selector(tapDelete), onDelete != nil)
        ]
        for (symbol, action, enabled) in items where enabled {
            let button = UIButton(type: .system)
            button.setImage(UIImage(systemName: symbol, withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)), for: .normal)
            button.tintColor = .white
            button.addTarget(self, action: action, for: .touchUpInside)
            button.heightAnchor.constraint(equalToConstant: 40).isActive = true
            actionBar.addArrangedSubview(button)
        }
        actionBar.isHidden = actionBar.arrangedSubviews.isEmpty
    }

    /// The menu behind the button in the top right.
    func makeOverflowMenu() -> UIMenu {
        var actions: [UIAction] = []
        if let onAllMedia = onAllMedia {
            actions.append(UIAction(title: "All Media".localized(), image: UIImage(systemName: "photo.on.rectangle")) { [weak self] _ in
                onAllMedia(self?.currentMessageId ?? "")
            })
        }
        if let onGoToMessage = onGoToMessage {
            actions.append(UIAction(title: "Go to Message".localized(), image: UIImage(systemName: "bubble.right")) { [weak self] _ in
                onGoToMessage(self?.currentMessageId ?? "")
            })
        }
        return UIMenu(title: "", children: actions)
    }

    @objc private func tapShare() { onShare?(currentMessageId) }
    @objc private func tapForward() { onForward?(currentMessageId) }
    @objc private func tapDelete() { onDelete?(currentMessageId) }
    @objc private func tapStar() {
        isStarred.toggle()
        buildActionBar()
        // The strip was built before the star was pressed, and moving off this picture and back
        // reads its state from there - so without this the star would appear to undo itself.
        let index = currentStripIndex
        if index >= 0, index < stripItems.count {
            let was = stripItems[index]
            stripItems[index] = StripItem(messageId: was.messageId,
                                          thumbFileName: was.thumbFileName,
                                          mediaFileName: was.mediaFileName,
                                          isVideo: was.isVideo,
                                          caption: was.caption,
                                          title: was.title,
                                          subtitle: was.subtitle,
                                          isStarred: isStarred)
        }
        onStar?(currentMessageId)
    }

    /// The chrome along the bottom is not the picture: a touch that lands there belongs to the
    /// strip or to a button, and neither the tap that hides the chrome nor the drag that puts
    /// the viewer away has any business with it.
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer else {
            return true
        }
        // Downwards only. Anything more sideways than down is the reader turning a page, and
        // the pager is already listening for it.
        let velocity = pan.velocity(in: view)
        return abs(velocity.y) > abs(velocity.x)
    }

    /// The pager and the per-page zoom view are scroll views with pans of their own, sitting over
    /// the top of this one. Without this they win the touch outright and the downward drag never
    /// starts. Letting them run together is safe: this pan only begins when the drag is more down
    /// than sideways, and it turns the pager's own scrolling off for the length of the drag.
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                  shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
        return other.view is UIScrollView
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // Fix: the tap that shows and hides the chrome does not cancel touches, so pressing the
        // play button in the middle of the picture started the video *and* took the header and the
        // action row away with it. A touch that lands on a control belongs to that control.
        for control in [playPauseButton, videoBar] where !control.isHidden {
            if control.frame.contains(touch.location(in: control.superview ?? view)) {
                return false
            }
        }
        guard bottomStack.superview != nil, bottomStack.alpha > 0 else {
            return true
        }
        return !bottomStack.frame.contains(touch.location(in: view))
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        refreshCaptionHeight()
        layoutVideoControls()
        layoutTopScrim()
        layoutStripInsets()
        playerLayer?.frame = view.bounds
    }

    /// Lets the first and the last thumbnail reach the middle of the strip.
    ///
    /// Fix: a thumbnail is chosen by being under the strip's centre, and with the row starting
    /// flush at the left edge the first one could never get there - nor the last one at the other
    /// end. However hard the strip was flung, the run stopped a few pictures short of each end.
    /// Half a strip of empty space at either side gives every thumbnail somewhere to be centred.
    private func layoutStripInsets() {
        guard stripCollection != nil, stripCollection.bounds.width > 0 else {
            return
        }
        let side = max(0, (stripCollection.bounds.width - MediaViewerViewController.stripCurrentItemSize.width) / 2)
        guard abs(stripCollection.contentInset.left - side) > 0.5 else {
            return
        }
        let wasAt = stripCollection.contentOffset.x + stripCollection.contentInset.left
        stripCollection.contentInset = UIEdgeInsets(top: 0, left: side, bottom: 0, right: side)
        // Keeping the same thumbnail in the middle rather than letting the new inset shift it.
        stripCollection.contentOffset = CGPoint(x: wasAt - side, y: stripCollection.contentOffset.y)
    }
    
    private func setupPrivacyOverlay() {
        view.addSubview(privacyOverlay)
        privacyOverlay.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            privacyOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            privacyOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            privacyOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            privacyOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        // Add WhatsApp-style message
        let icon = UIImageView(image: UIImage(systemName: "camera.fill"))
        icon.tintColor = .mainColor
        icon.contentMode = .scaleAspectFit

        let label = UILabel()
        label.text = "Screen capture/recording blocked".localized()
        label.font = .systemFont(ofSize: 22, weight: .semibold)
        label.textColor = .white

        let desc = UILabel()
        desc.text = "You tried to take a screenshot.\nFor added privacy, credential messages don’t allow this.".localized()
        desc.font = .systemFont(ofSize: 16)
        desc.textColor = .lightGray
        desc.numberOfLines = 0
        desc.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [icon, label, desc])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 18

        privacyOverlay.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: privacyOverlay.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: privacyOverlay.centerYAnchor),
            stack.leftAnchor.constraint(equalTo: view.leftAnchor),
            stack.rightAnchor.constraint(equalTo: view.rightAnchor),
            icon.widthAnchor.constraint(equalToConstant: 80),
            icon.heightAnchor.constraint(equalToConstant: 80)
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
        isNavigationBarHidden = false
    }

    func animateBackgroundIn() {
        UIView.animate(withDuration: 0.25) {
            self.backgroundView.alpha = 1
        }
    }
    

    /// A soft dark halo behind white text, for reading it over a picture of any colour.
    static func applyTextShadow(to label: UILabel) {
        label.layer.shadowColor = UIColor.black.cgColor
        // Carrying the readability on its own now that nothing is laid over the picture, so it is
        // set firmer than before. It still costs the picture nothing: a layer shadow is drawn from
        // the glyphs, so it only darkens the few pixels hugging the strokes.
        label.layer.shadowOpacity = 0.9
        label.layer.shadowRadius = 5
        label.layer.shadowOffset = .zero
        label.layer.masksToBounds = false
    }

    func setNavigationTitle(title: String, subtitle: String) {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 15)
        titleLabel.textColor = .white
        // Fix: keeping white legible used to mean darkening the whole top of the picture. A
        // shadow on the letters themselves does the same work where it is actually needed -
        // right behind the strokes - so the shadow above can be light enough to see through.
        MediaViewerViewController.applyTextShadow(to: titleLabel)
        titleLabel.textAlignment = .center

        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = UIFont.systemFont(ofSize: 12)
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.85)
        MediaViewerViewController.applyTextShadow(to: subtitleLabel)
        subtitleLabel.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 0

        navigationItem.titleView = stack
    }

    private func configureMedia() {
        switch media! {
        case .image(let img):
            imageView.image = img

        case .gif(let data):
            let animatedImage = SDAnimatedImage(data: data)
            imageView.image = animatedImage

        case .video(let url):
            setupVideo(url: url)
        }
    }

    /// Puts a video on screen. Called every time a video page is arrived at, so it is careful to
    /// build the once-only parts once.
    ///
    /// Fix: this used to do the whole lot on every visit - a second finished-playing observer, a
    /// second periodic observer, another target on the play button so one tap toggled twice, and
    /// the picture layer added to the single-media scroll view, which is not what the pager shows.
    /// Leaving a video and coming back was enough to make the screen unusable.
    private func setupVideo(url: URL) {
        buildVideoChromeIfNeeded()

        player = AVPlayer(url: url)
        let layer = AVPlayerLayer(player: player)
        layer.videoGravity = .resizeAspect
        playerLayer = layer
        // Held by a view of the viewer's own rather than by whichever cell is showing: cells are
        // handed on to other pictures as the reader scrolls, and a player layer left inside one
        // would go with it.
        videoHost.isHidden = false
        positionVideoHost()
        videoHost.layer.addSublayer(layer)
        // No implicit animation on a layer that is simply being placed.
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layer.frame = videoHost.bounds
        CATransaction.commit()

        NotificationCenter.default.addObserver(self, selector: #selector(videoDidFinish), name: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem)
        addPeriodicTimeObserver()

        // Written down while it is open. This is the only moment a video kept encrypted is ever
        // readable without decrypting it on purpose, so it is not passed up.
        let messageId = currentStripIndex < stripItems.count ? stripItems[currentStripIndex].messageId : ""
        DispatchQueue.global(qos: .utility).async {
            let seconds = CMTimeGetSeconds(AVURLAsset(url: url).duration)
            guard seconds.isFinite, seconds > 0 else {
                return
            }
            MediaViewerViewController.rememberVideoDuration(seconds: Int(seconds.rounded()), messageId: messageId)
        }

        isVideoPlaying = false
        playPauseButton.isHidden = false
        slider.value = 0
        timeCurrentLabel.text = "0:00"
        buildActionBar()

        // A video opened from the conversation starts on its own, the way the reference does.
        // Only that one: swiping onto a video further along the strip leaves it waiting, so the
        // reader is not walking into sound they did not ask for.
        if autoPlaysOnOpen {
            autoPlaysOnOpen = false
            togglePlayPause()
        }
    }

    private func buildVideoChromeIfNeeded() {
        guard !hasBuiltVideoChrome else {
            return
        }
        hasBuiltVideoChrome = true
        // Built out of sight; whoever asked for it decides what shows.
        defer {
            playPauseButton.isHidden = true
            videoBar.isHidden = true
        }
        // Large, pale and solid the way the reference draws it, rather than a small dark disc:
        // this is the one thing on an unplayed video that has to be obvious.
        playPauseButton.setImage(UIImage(systemName: "play.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .medium, scale: .default)), for: .normal)
        playPauseButton.tintColor = UIColor.black.withAlphaComponent(0.55)
        playPauseButton.frame = CGRect(x: 0, y: 0, width: 72, height: 72)
        playPauseButton.backgroundColor = UIColor.white.withAlphaComponent(0.85)
        playPauseButton.center = view.center
        playPauseButton.addTarget(self, action: #selector(togglePlayPause), for: .touchUpInside)
        view.addSubview(playPauseButton)
        // Not `circle()`, which clips to bounds and would cut the shadow off. A corner radius on
        // its own still rounds the background; nothing inside the button reaches the edge, so
        // there is nothing that needed clipping anyway.
        playPauseButton.clipsToBounds = false
        playPauseButton.layer.cornerRadius = playPauseButton.bounds.width / 2
        // A pale button on a pale frame of video would otherwise have no edge at all.
        playPauseButton.layer.shadowColor = UIColor.black.cgColor
        playPauseButton.layer.shadowOpacity = 0.35
        playPauseButton.layer.shadowRadius = 8
        playPauseButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        setupVideoControls()
    }
    
    private func setupVideoControls() {
        // A band directly under the title, the way the reference has it - the scrubber used to sit
        // at the foot of the screen, on top of the strip of thumbnails and the row of actions.
        videoBar.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        view.addSubview(videoBar)

        pipButton.setImage(UIImage(systemName: "pip.enter", withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .regular)), for: .normal)
        pipButton.tintColor = .white
        pipButton.addTarget(self, action: #selector(togglePictureInPicture), for: .touchUpInside)
        videoBar.addSubview(pipButton)

        // Current time
        timeCurrentLabel.text = "0:00"
        timeCurrentLabel.textColor = .white
        timeCurrentLabel.font = .systemFont(ofSize: 13)
        videoBar.addSubview(timeCurrentLabel)

        // Remaining time
        timeRemainingLabel.text = "-0:00"
        timeRemainingLabel.textColor = .white
        timeRemainingLabel.font = .systemFont(ofSize: 13)
        timeRemainingLabel.textAlignment = .right
        videoBar.addSubview(timeRemainingLabel)

        // Playback speed button
        speedButton.setTitle("1×", for: .normal)
        speedButton.tintColor = .white
        speedButton.titleLabel?.font = .boldSystemFont(ofSize: 15)
        speedButton.addTarget(self, action: #selector(toggleSpeed), for: .touchUpInside)
        videoBar.addSubview(speedButton)

        // Slider
        let thumbImg = makeThumb(size: 20)
        slider.setThumbImage(thumbImg, for: .normal)
        slider.setThumbImage(thumbImg, for: .highlighted)
        slider.minimumValue = 0
        slider.maximumValue = 1
        slider.tintColor = .white
        slider.addTarget(self, action: #selector(sliderChanged(_:)), for: .valueChanged)
        videoBar.addSubview(slider)

        layoutVideoControls()
    }
    
    func makeThumb(size: CGFloat, color: UIColor = .white) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        return renderer.image { _ in
            let rect = CGRect(origin: .zero, size: CGSize(width: size, height: size))
            color.setFill()
            UIBezierPath(ovalIn: rect).fill()
        }
    }
    
    private func addPeriodicTimeObserver() {
        guard let player = player else { return }

        timeObserverToken = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.2, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            guard let self = self,
                  let item = player.currentItem else { return }

            let durationDouble = item.duration.seconds
            guard durationDouble.isFinite, durationDouble > 0 else { return }

            // ✅ Convert duration ONCE
            let durationSeconds = Int(round(durationDouble))

            // Clamp & convert current ONCE
            let currentDouble = min(max(time.seconds, 0), durationDouble)
            let currentSeconds = min(Int(round(currentDouble)), durationSeconds)

            // ✅ Remaining derived from integers
            let remainingSeconds = max(durationSeconds - currentSeconds, 0)

            self.slider.value = Float(currentDouble / durationDouble)

            self.timeCurrentLabel.text = self.formatTime(seconds: currentSeconds)
            self.timeRemainingLabel.text = "-\(self.formatTime(seconds: remainingSeconds))"
        }
    }
    
    private func formatTime(seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
    
    @objc private func sliderChanged(_ sender: UISlider) {
        guard let duration = player?.currentItem?.duration.seconds, duration > 0 else { return }

        let newTime = Double(sender.value) * duration
        let cmTime = CMTime(seconds: newTime, preferredTimescale: 600)

        player?.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero)
    }
    
    @objc private func toggleSpeed() {
        currentSpeedIndex = (currentSpeedIndex + 1) % playbackSpeeds.count
        let speed = playbackSpeeds[currentSpeedIndex]

        player?.rate = speed
        if !isVideoPlaying { player?.play() } // auto-play when changing speed
        isVideoPlaying = true

        speedButton.setTitle(formatSpeed(speed), for: .normal)
    }
    
    private func formatSpeed(_ value: Float) -> String {
        let intValue = Int(value)
        if value == Float(intValue) {
            return "\(intValue)x"   // 1 → "1x", 2 → "2x"
        } else {
            return "\(value)x"      // keeps 0.5 → "0.5x"
        }
    }
    
    private func layoutVideoControls() {
        let padding: CGFloat = 14
        let labelWidth: CGFloat = 42
        let barHeight: CGFloat = 44
        let top = (navigationController?.navigationBar.frame.maxY ?? 88) + 4
        videoBar.frame = CGRect(x: 0, y: top, width: view.bounds.width, height: barHeight)
        positionVideoHost()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        playerLayer?.frame = videoHost.bounds
        CATransaction.commit()
        playPauseButton.center = CGPoint(x: view.bounds.midX, y: view.bounds.midY)

        let row = (barHeight - 20) / 2
        timeCurrentLabel.frame = CGRect(x: padding, y: row, width: labelWidth, height: 20)
        pipButton.frame = CGRect(x: videoBar.bounds.width - padding - 26, y: row - 3, width: 26, height: 26)
        speedButton.frame = CGRect(x: pipButton.frame.minX - 8 - 30, y: row, width: 30, height: 20)
        timeRemainingLabel.frame = CGRect(x: speedButton.frame.minX - labelWidth - 6, y: row, width: labelWidth, height: 20)
        slider.frame = CGRect(x: timeCurrentLabel.frame.maxX + 8,
                              y: row,
                              width: max(0, timeRemainingLabel.frame.minX - timeCurrentLabel.frame.maxX - 16),
                              height: 20)
        
        let minX = min(
            timeCurrentLabel.frame.minX,
            slider.frame.minX
        )

        let maxX = max(
            speedButton.frame.maxX,
            slider.frame.maxX
        )
        
        let y = timeCurrentLabel.frame.minY - 4
        let height: CGFloat = timeCurrentLabel.frame.height + 8
        blurBackground.frame = CGRect(
            x: minX - 8,                  // left padding
            y: y,                         // top
            width: (maxX - minX) + 16,    // width + horizontal padding
            height: height                // height
        )
    }
    
    @objc private func videoDidFinish() {
        isVideoPlaying = false
        playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
    }

    @objc private func togglePlayPause() {
        guard let player = player else {
            // Pressed while the file is still being read - an encrypted video takes a moment. The
            // intent is remembered rather than dropped, and playing begins as soon as it is ready.
            autoPlaysOnOpen = true
            return
        }

        if isVideoPlaying {
            player.pause()
            playPauseButton.isHidden = false
        } else {
            prepareForVideoPlayback()
            if let currentItem = player.currentItem,
               currentItem.currentTime() >= currentItem.duration {
                player.seek(to: .zero)
            }
            player.play()
            // Nothing over the picture once it is running; pausing is done from the row below.
            playPauseButton.isHidden = true
            videoBar.isHidden = isNavigationBarHidden
        }
        isVideoPlaying.toggle()
        // The action row carries the same play and pause, so it changes with it.
        buildActionBar()
    }

    /// Hands the video to the system's floating window.
    @objc private func togglePictureInPicture() {
        guard let layer = playerLayer, AVPictureInPictureController.isPictureInPictureSupported() else {
            return
        }
        if pictureInPicture == nil {
            pictureInPicture = AVPictureInPictureController(playerLayer: layer)
        }
        guard let controller = pictureInPicture else {
            return
        }
        if controller.isPictureInPictureActive {
            controller.stopPictureInPicture()
        } else {
            controller.startPictureInPicture()
        }
    }
    
    func prepareForVideoPlayback() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(
                .playback,
                mode: .moviePlayback,
                options: [.defaultToSpeaker]
            )
            try audioSession.setActive(true)
        } catch {
            print("Failed to configure audio session for video")
        }
    }
    
    func stopVideo() {
        player?.pause()
        player?.seek(to: .zero)
    }

    @objc private func toggleNavigationBar() {
        guard let navController = navigationController else { return }

        isNavigationBarHidden.toggle()

        UIView.animate(withDuration: 0.25) {
            navController.setNavigationBarHidden(self.isNavigationBarHidden, animated: true)
            self.statusBarBackgroundView.alpha = self.isNavigationBarHidden ? 0 : 1
            // A video waiting to be started keeps its button whatever the chrome is doing - that
            // button is not chrome, it is the only way to start the thing. Once it is running the
            // button is gone anyway, and pausing is done from the row along the bottom.
            self.playPauseButton.alpha = self.isVideoPlaying ? 0 : 1
            // The band of playback controls is chrome, so it goes with the rest of it - it used to
            // be only its contents that faded, leaving an empty grey strip behind.
            self.videoBar.alpha = self.isNavigationBarHidden ? 0 : 1
            self.blurBackground.alpha = self.isNavigationBarHidden ? 0 : 1
            self.bottomStack.alpha = self.isNavigationBarHidden ? 0 : 1
            self.topScrim.alpha = self.isNavigationBarHidden ? 0 : MediaViewerViewController.topScrimStrength
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Before, not after: whatever the conversation does with this needs to have happened by
        // the time the viewer has finished getting out of the way.
        onDismiss?(currentMessageId)
    }

    override func viewDidDisappear(_ animated: Bool) {
        self.stopVideo()
    }

    /// The bubble in the conversation this viewer was opened from, when it was opened from one.
    ///
    /// The zoom transition is what knows about it, so that is what is asked - rather than the
    /// conversation being made to hand it over a second time.
    private func originBubbleView() -> UIImageView? {
        return (navigationController?.transitioningDelegate as? ZoomTransitioningDelegate)?.currentOrigin()
    }

    /// Whatever is carrying the picture on screen, so the drag moves what the reader can see.
    ///
    /// Fix: this used to always move `scrollView`. Once the pictures moved into the pager that
    /// view was no longer the one on screen, so a downward drag ran but shifted something hidden -
    /// which read as the gesture having been taken away.
    private var draggableView: UIView {
        return stripItems.isEmpty ? scrollView : pager
    }

    /// Dragging downwards puts the viewer away. Sideways belongs to the pager, which is a
    /// scroll view and handles it itself.
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        if stripItems.isEmpty {
            guard scrollView.zoomScale == 1.0 else {
                return
            }
        } else {
            guard let page = pager.cellForItem(at: IndexPath(item: currentStripIndex, section: 0)) as? MediaPageCell,
                  page.zoomView.zoomScale == 1.0 else {
                return
            }
        }

        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view)


        switch gesture.state {
        case .began:
            // The pager is a scroll view and would otherwise keep drifting sideways underneath a
            // drag that is meant to be taking the viewer away. It is handed back on the way out.
            pager?.isScrollEnabled = false
            // The conversation comes through as the backdrop fades, and the bubble this picture
            // was opened from is sitting in it still holding the picture - so the same photograph
            // appears twice, one being dragged and one waiting behind. Put away for the drag; if
            // the drag is abandoned it comes straight back, and if it carries through to a dismiss
            // the transition hands it back at the far end.
            originBubbleView()?.isHidden = true

        case .changed:
            let transform = CGAffineTransform(translationX: translation.x, y: translation.y)
            draggableView.transform = transform
            
            // Calculate percentage based on distance from center
            let distance = hypot(translation.x, translation.y)
            let maxDistance = view.bounds.height / 2.0
            let progress = min(distance / maxDistance, 1.0)
            self.backgroundView.alpha = 1.0 - progress
            if isSecure {
                self.privacyOverlay.isHidden = true
            }
            if isVideoPlaying {
                player?.pause()
                playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
            }

        case .ended, .cancelled:
            let distance = abs(translation.y)
            let threshold: CGFloat = 120

            pager?.isScrollEnabled = true

            if distance > threshold || abs(velocity.y) > 500 {
                // Dismiss if far enough or fast swipe
                self.stopVideo()
                NotificationCenter.default.removeObserver(self)
                dismiss(animated: true, completion: nil)
            } else {
                // Return to center if not far enough
                originBubbleView()?.isHidden = false
                if isSecure {
                    self.privacyOverlay.isHidden = false
                }
                if isVideoPlaying {
                    isVideoPlaying = false
                    togglePlayPause()
                }
                UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.8, options: [], animations: {
                    self.draggableView.transform = .identity
                    self.backgroundView.alpha = 1.0
                }, completion: nil)
            }
        default:
            break
        }
    }

    // MARK: - UIScrollViewDelegate

    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return scrollView === self.scrollView ? imageView : nil
    }

    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        guard scrollView === self.scrollView else {
            return
        }
        let size = imageView.frame.size
        let bounds = scrollView.bounds.size
        let vertical = size.height < bounds.height ? (bounds.height - size.height) / 2 : 0
        let horizontal = size.width < bounds.width ? (bounds.width - size.width) / 2 : 0
        scrollView.contentInset = UIEdgeInsets(top: vertical, left: horizontal, bottom: vertical, right: horizontal)
    }

    /// The strip follows the pager as it moves, not once it has arrived: how far along the
    /// finger is comes straight from the offset, so the thumbnail grows while the picture is
    /// still sliding.
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView === stripCollection {
            // Only when the reader is the one moving it. The strip is also scrolled to follow the
            // picture, and treating that as a scrub would have the two chasing each other.
            if isScrubbingStrip {
                scrubFromStrip()
            }
            return
        }
        guard scrollView === pager, pager.bounds.width > 0 else {
            return
        }
        positionVideoHost()
        let nearest = max(0, min(stripItems.count - 1, Int(round(pager.contentOffset.x / pager.bounds.width))))
        highlightStrip(at: nearest)
        showChrome(for: nearest)
    }

    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if scrollView === stripCollection {
            isScrubbingStrip = true
        }
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView === stripCollection {
            endStripScrub()
            return
        }
        guard scrollView === pager else {
            return
        }
        isSettingPagerPosition = false
        adoptCurrentPage()
    }

    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        guard scrollView === pager else {
            return
        }
        isSettingPagerPosition = false
        adoptCurrentPage()
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if scrollView === stripCollection {
            if !decelerate {
                endStripScrub()
            }
            return
        }
        guard scrollView === pager, !decelerate else {
            return
        }
        adoptCurrentPage()
    }
}

class ZoomAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    var isPresenting = true
    var originImageView: UIImageView?

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.45
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromVC = transitionContext.viewController(forKey: .from),
              let toVC = transitionContext.viewController(forKey: .to) else {
            self.originImageView?.isHidden = false
            transitionContext.completeTransition(false)
            return
        }
        guard let originImageView = originImageView, originImageView.window != nil else {
            // No bubble on screen to aim at - a picture whose message is not in the loaded window,
            // say. Flying to a stale reference is worse than not flying at all, so it fades.
            self.originImageView?.isHidden = false
            fadeTransition(using: transitionContext, from: fromVC, to: toVC)
            return
        }

        let container = transitionContext.containerView
        // The bubble keeps its own thumbnail on screen while the snapshot flies over it, so for a
        // moment the same picture is drawn twice - once sitting still in the conversation and once
        // moving. It is put away for the length of the move and handed back at the end.
        originImageView.isHidden = true
        let imageViewSnapshot = UIImageView(image: originImageView.image)
        imageViewSnapshot.contentMode = .scaleAspectFit
        imageViewSnapshot.clipsToBounds = true
        imageViewSnapshot.frame = container.convert(originImageView.bounds, from: originImageView)

        if isPresenting {
            toVC.view.alpha = 0
            container.addSubview(toVC.view)
            // Starts cropped, the way the bubble is actually drawing it, and opens out to the
            // whole picture. Beginning aspect-fit instead put the entire picture inside the
            // bubble's frame for one frame - a visible squeeze before the animation had moved.
            imageViewSnapshot.contentMode = .scaleAspectFill
            container.addSubview(imageViewSnapshot)

            let finalFrame = toVC.view.frame

            UIView.animate(withDuration: transitionDuration(using: transitionContext),
                           delay: 0,
                           usingSpringWithDamping: 0.85,
                           initialSpringVelocity: 0.6,
                           options: .curveEaseOut, animations: {

                imageViewSnapshot.frame = finalFrame
                imageViewSnapshot.contentMode = .scaleAspectFit
                toVC.view.alpha = 1

            }) { _ in
                imageViewSnapshot.removeFromSuperview()
                originImageView.isHidden = false
                transitionContext.completeTransition(true)
            }

        } else {
            let navVC = fromVC as? UINavigationController
            let fromImageVC = navVC?.viewControllers.first as? MediaViewerViewController
            let finalFrame = container.convert(originImageView.bounds, from: originImageView)

            // Fix: the snapshot was put at the bubble's frame and then animated to the bubble's
            // frame - the same place - so closing the viewer never moved anything; the picture
            // simply blinked out. It starts where the picture actually is, full screen, and
            // shrinks from there into the bubble it belongs to.
            let shown = fromImageVC?.currentPictureView()
            if let shown = shown, let picture = shown.image {
                imageViewSnapshot.image = picture
                imageViewSnapshot.frame = container.convert(ZoomAnimator.drawnFrame(of: shown), from: shown.superview)
            } else {
                imageViewSnapshot.frame = container.bounds
            }
            imageViewSnapshot.contentMode = .scaleAspectFit

            container.addSubview(imageViewSnapshot)
            fromImageVC?.view.alpha = 0
            fromImageVC?.backgroundView.alpha = 0 // fade background

            UIView.animate(withDuration: transitionDuration(using: transitionContext),
                           delay: 0,
                           usingSpringWithDamping: 0.85,
                           initialSpringVelocity: 0.6,
                           options: .curveEaseOut, animations: {

                imageViewSnapshot.frame = finalFrame
                imageViewSnapshot.contentMode = .scaleAspectFill

            }) { _ in
                imageViewSnapshot.removeFromSuperview()
                originImageView.isHidden = false
                transitionContext.completeTransition(true)
            }
        }
    }

    private func fadeTransition(using transitionContext: UIViewControllerContextTransitioning,
                                from fromVC: UIViewController,
                                to toVC: UIViewController) {
        let container = transitionContext.containerView
        if isPresenting {
            toVC.view.alpha = 0
            container.addSubview(toVC.view)
        }
        UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
            if self.isPresenting {
                toVC.view.alpha = 1
            } else {
                fromVC.view.alpha = 0
            }
        }, completion: { _ in
            fromVC.view.alpha = 1
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }

    /// Where the picture actually is inside its view, which for an aspect-fit image view is not
    /// the view's own bounds - without this a tall picture appears to jump wider as it starts.
    static func drawnFrame(of view: UIImageView) -> CGRect {
        guard let size = view.image?.size, size.width > 0, size.height > 0 else {
            return view.frame
        }
        let scale = min(view.bounds.width / size.width, view.bounds.height / size.height)
        let drawn = CGSize(width: size.width * scale, height: size.height * scale)
        return CGRect(x: view.frame.origin.x + (view.bounds.width - drawn.width) / 2,
                      y: view.frame.origin.y + (view.bounds.height - drawn.height) / 2,
                      width: drawn.width,
                      height: drawn.height)
    }
}

class ZoomTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
    var originImageView: UIImageView?

    /// Asked for the bubble at the moment a transition starts, rather than being told about it in
    /// advance.
    ///
    /// Fix: the viewer moves between a conversation's pictures on its own, so the bubble it should
    /// shrink back into is not the one it grew out of. It was being updated as pages turned, but a
    /// message far from the one opened has no row on screen to update it from - and a table reuses
    /// its cells, so the reference left over pointed at a bubble now showing something else
    /// entirely. That is what made a dismiss from a distant picture fly to the wrong place.
    var originProvider: (() -> UIImageView?)?

    /// The bubble to use now: whatever the provider says, or the one handed over at the start.
    func currentOrigin() -> UIImageView? {
        return originProvider?() ?? originImageView
    }

    func animationController(forPresented presented: UIViewController,
                             presenting: UIViewController, source: UIViewController)
        -> UIViewControllerAnimatedTransitioning? {
            let animator = ZoomAnimator()
            animator.isPresenting = true
            animator.originImageView = originImageView
            return animator
    }

    func animationController(forDismissed dismissed: UIViewController)
        -> UIViewControllerAnimatedTransitioning? {
            let animator = ZoomAnimator()
            animator.isPresenting = false
            animator.originImageView = currentOrigin()
            return animator
    }
}

public class CallBannerView: UIView {
    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.systemGreen

        let label = UILabel()
        label.text = "Ardi easySoft - Ringing"
        label.textColor = .white
        label.font = UIFont.boldSystemFont(ofSize: 16)

        let endCallButton = UIButton(type: .system)
        endCallButton.setImage(UIImage(systemName: "phone.down.fill"), for: .normal)
        endCallButton.tintColor = .white
        endCallButton.addTarget(self, action: #selector(endCallTapped), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [label, endCallButton])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .equalSpacing
        stack.spacing = 12

        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10)
        ])
    }

    @objc func endCallTapped() {
        print("Call ended")
        self.removeFromSuperview()
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class HtmlUtils {
    private static func unescapeHTMLEntities(_ text: String) -> String {
        var result = text

        // quick named entity replacements
        let named: [String: String] = [
            "&lt;": "<",
            "&gt;": ">",
            "&amp;": "&",
            "&quot;": "\"",
            "&apos;": "'",
            "&#039;": "'" // common single-quote entity in some HTML sources
        ]
        for (k, v) in named {
            result = result.replacingOccurrences(of: k, with: v)
        }

        // decode decimal numeric entities like &#39;
        let decimalPattern = "&#(\\d+);"
        if let decRegex = try? NSRegularExpression(pattern: decimalPattern, options: []) {
            let matches = decRegex.matches(in: result, options: [], range: NSRange(location: 0, length: result.utf16.count))
            for match in matches.reversed() { // reverse so ranges remain valid while replacing
                guard match.numberOfRanges >= 2,
                      let numRange = Range(match.range(at: 1), in: result) else { continue }
                let numStr = String(result[numRange])
                if let code = Int(numStr), let scalar = UnicodeScalar(code) {
                    let char = String(scalar)
                    if let fullRange = Range(match.range(at: 0), in: result) {
                        result.replaceSubrange(fullRange, with: char)
                    }
                }
            }
        }

        // decode hex numeric entities like &#x27;
        let hexPattern = "&#x([0-9a-fA-F]+);"
        if let hexRegex = try? NSRegularExpression(pattern: hexPattern, options: []) {
            let matches = hexRegex.matches(in: result, options: [], range: NSRange(location: 0, length: result.utf16.count))
            for match in matches.reversed() {
                guard match.numberOfRanges >= 2,
                      let hexRange = Range(match.range(at: 1), in: result) else { continue }
                let hexStr = String(result[hexRange])
                if let code = Int(hexStr, radix: 16), let scalar = UnicodeScalar(code) {
                    let char = String(scalar)
                    if let fullRange = Range(match.range(at: 0), in: result) {
                        result.replaceSubrange(fullRange, with: char)
                    }
                }
            }
        }

        return result
    }

    static func toHTMLPreview(_ pText: String, fontSize: CGFloat = 12) -> NSAttributedString {
        let unescaped = unescapeHTMLEntities(pText).replacingOccurrences(of: "\n", with: "<br>")

        let parsed: NSAttributedString = {
            guard let data = unescaped.data(using: .utf8) else { return NSAttributedString(string: unescaped) }
            do {
                return try NSAttributedString(
                    data: data,
                    options: [
                        .documentType: NSAttributedString.DocumentType.html,
                        .characterEncoding: String.Encoding.utf8.rawValue
                    ],
                    documentAttributes: nil
                )
            } catch {
                return NSAttributedString(string: unescaped)
            }
        }()

        // 3) Apply your custom fonts while preserving link attributes
        let mutable = NSMutableAttributedString(attributedString: parsed)
        let normalFont = UIFont.systemFont(ofSize: fontSize)
        let boldFont = UIFont.boldSystemFont(ofSize: fontSize)
        let italicFont = UIFont.italicSystemFont(ofSize: fontSize)
        let boldItalicFont = UIFont.systemFont(ofSize: fontSize, weight: .semibold)

        mutable.enumerateAttribute(.font, in: NSRange(location: 0, length: mutable.length)) { value, range, _ in
            guard let oldFont = value as? UIFont else { return }
            let traits = oldFont.fontDescriptor.symbolicTraits
            let newFont: UIFont
            if traits.contains([.traitBold, .traitItalic]) {
                newFont = boldItalicFont
            } else if traits.contains(.traitBold) {
                newFont = boldFont
            } else if traits.contains(.traitItalic) {
                newFont = italicFont
            } else {
                newFont = normalFont
            }
            // replace font but DO NOT remove link attribute or other attrs
            mutable.addAttribute(.font, value: newFont, range: range)
        }

        return mutable
    }
    
    static func hasHtmlTag(_ pText: String) -> Bool {
        // unescape entities first
        let unescaped = unescapeHTMLEntities(pText)
        
        let pattern = ".*\\<[^>]+>.*"
        if let regex = try? NSRegularExpression(pattern: pattern,
                                                options: [.dotMatchesLineSeparators]) {
            let range = NSRange(location: 0, length: (unescaped as NSString).length)
            return regex.firstMatch(in: unescaped, options: [], range: range) != nil
        }
        return false
    }
}

enum FormFieldType: String {
    case dateChooser
    case dateTimeChooser
    case timeChooser
    case itemChooser
    case inputRadio
    case inputRadioHorizontal
    case inputNumber
    case inputText
    case inputTextMultiline
    case inputCheck
    case inputFile
    case inputPhoto
    case inputProject
    case header
    case transId
    case transStatus
    case transAssigned
    case signature
    case image
    case video
}

// Factory untuk membuat view sesuai tipe
class FormViewFactory {
    
    static func createView(
        type: FormFieldType,
        key: String,
        keyLabel: String,
        valueLabel: String,
        background: UIColor? = nil,
        color: UIColor? = nil
    ) -> UIView {
        
        var result: UIView
        
        switch type {
        case .dateChooser:
            result = createDateChooser(keyLabel: keyLabel, valueLabel: valueLabel)
        case .dateTimeChooser:
            result = createDateTimeChooser()
        case .timeChooser:
            result = createTimeChooser()
        case .itemChooser:
            result = createItemChooser(keyLabel: keyLabel, valueLabel: valueLabel)
        case .inputRadio:
            result = createRadio(keyLabel: keyLabel, valueLabel: valueLabel, color: color)
        case .inputRadioHorizontal:
            result = createRadioHorizontal(keyLabel: keyLabel, valueLabel: valueLabel, color: color)
        case .inputNumber:
            result = createNumberField(keyLabel: keyLabel, valueLabel: valueLabel)
        case .inputText:
            result = createTextField(keyLabel: keyLabel, valueLabel: valueLabel)
        case .inputTextMultiline:
            result = createMultilineTextField(keyLabel: keyLabel, valueLabel: valueLabel)
        case .inputCheck:
            result = createCheckbox(keyLabel: keyLabel, valueLabel: valueLabel)
        case .inputFile:
            result = createButton(title: "Upload File")
        case .inputPhoto:
            result = createButton(title: "Take Photo")
        case .inputProject:
            result = createLabel("\(keyLabel): [Project Picker]")
        case .header:
            result = createHeader(title: keyLabel)
        case .transId:
            result = createLabel("Transaction ID: \(valueLabel)")
        case .transStatus:
            result = createLabel("Status: \(keyLabel)")
        case .transAssigned:
            result = createLabel("Assigned to: \(valueLabel)")
        case .signature:
            result = createButton(title: "Add Signature")
        case .image:
            result = createButton(title: "Pick Image")
        case .video:
            result = createButton(title: "Pick Video")
        }
        
        // optional background
        if let bg = background {
            result.backgroundColor = bg
        }
        
        return result
    }
    
    // MARK: - Builder sederhana
    
    private static func createLabel(_ text: String) -> UIView {
        let label = UILabel()
        label.text = text
        return label
    }
    
    private static func createHeader(title: String) -> UIView {
        let label = UILabel()
        label.text = title
        label.font = UIFont.boldSystemFont(ofSize: 18)
        return label
    }
    
    private static func createButton(title: String) -> UIView {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        return button
    }
    
    private static func createTextField(keyLabel: String, valueLabel: String) -> UIView {
        let textField = UITextField()
        textField.placeholder = keyLabel
        textField.text = valueLabel
        textField.borderStyle = .roundedRect
        return textField
    }
    
    private static func createMultilineTextField(keyLabel: String, valueLabel: String) -> UIView {
        let textView = UITextView()
        textView.text = valueLabel.isEmpty ? keyLabel : valueLabel
        textView.layer.borderWidth = 1
        textView.layer.borderColor = UIColor.gray.cgColor
        textView.layer.cornerRadius = 6
        return textView
    }
    
    private static func createNumberField(keyLabel: String, valueLabel: String) -> UIView {
        let textField = createTextField(keyLabel: keyLabel, valueLabel: valueLabel) as! UITextField
        textField.keyboardType = .numberPad
        return textField
    }
    
    private static func createDateChooser(keyLabel: String, valueLabel: String) -> UIView {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        return picker
    }
    
    private static func createDateTimeChooser() -> UIView {
        let picker = UIDatePicker()
        picker.datePickerMode = .dateAndTime
        return picker
    }
    
    private static func createTimeChooser() -> UIView {
        let picker = UIDatePicker()
        picker.datePickerMode = .time
        return picker
    }
    
    private static func createItemChooser(keyLabel: String, valueLabel: String) -> UIView {
        return createButton(title: "\(keyLabel): \(valueLabel)")
    }
    
    private static func createRadio(keyLabel: String, valueLabel: String, color: UIColor?) -> UIView {
        let button = UIButton(type: .system)
        button.setTitle("○ \(valueLabel)", for: .normal)
        button.tintColor = color ?? .blue
        return button
    }
    
    private static func createRadioHorizontal(keyLabel: String, valueLabel: String, color: UIColor?) -> UIView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        
        let label = UILabel()
        label.text = keyLabel
        
        let button = UIButton(type: .system)
        button.setTitle(valueLabel, for: .normal)
        button.tintColor = color ?? .blue
        
        stack.addArrangedSubview(label)
        stack.addArrangedSubview(button)
        return stack
    }
    
    private static func createCheckbox(keyLabel: String, valueLabel: String) -> UIView {
        let button = UIButton(type: .system)
        button.setTitle("☐ \(keyLabel)", for: .normal)
        return button
    }
}

public final class MessageGuardLite {
    
    // MARK: - Verdict
    public enum Verdict {
        case allow, sanitized, block
    }
    
    // MARK: - Result
    public struct Result {
        public let verdict: Verdict
        public let reason: String
        public let mime: String
        public let data: Data?  // nil for some paths (like PDF->images)
    }
    
    // MARK: - Limits
    public struct Limits {
        public let maxImagePixels: Int
        public let maxImageEdge: Int
        public let pdfMaxPages: Int
        
        public init(maxImagePixels: Int, maxImageEdge: Int, pdfMaxPages: Int) {
            self.maxImagePixels = maxImagePixels
            self.maxImageEdge = maxImageEdge
            self.pdfMaxPages = pdfMaxPages
        }
        
        public static func defaults() -> Limits {
            return Limits(maxImagePixels: 4096 * 4096, maxImageEdge: 4096, pdfMaxPages: 10)
        }
    }
    
    private let limits: Limits
    
    public init(limits: Limits? = nil) {
        self.limits = limits ?? Limits.defaults()
    }
    
    // MARK: - 1. Text Sanitization
    public func sanitizeText(_ utf8: Data) -> Result {
        guard let input = String(data: utf8, encoding: .utf8) else {
            return Result(verdict: .block,
                          reason: "Invalid UTF-8 text",
                          mime: "application/octet-stream",
                          data: nil)
        }
        let pattern = #"[\p{C}&&[^\t\n\r]][\u200B-\u200F\uFEFF\u202A-\u202E]"#
        let regex = try! NSRegularExpression(pattern: pattern)
        let clean = regex.stringByReplacingMatches(in: input,
                                                   options: [],
                                                   range: NSRange(location: 0, length: input.utf16.count),
                                                   withTemplate: "")
        if input == clean {
            return Result(verdict: .allow, reason: "No changes", mime: "text/plain", data: utf8)
        } else {
            return Result(verdict: .sanitized, reason: "Removed control & zero-width characters", mime: "text/plain", data: clean.data(using: .utf8))
        }
    }
    
    // MARK: - 2. HTML Sanitization
    public func sanitizeHtml(_ utf8Html: Data) -> Result {
        guard let input = String(data: utf8Html, encoding: .utf8) else {
            return Result(verdict: .block, reason: "Invalid HTML encoding", mime: "application/octet-stream", data: nil)
        }
        
        var clean = input
        clean = clean.replacingOccurrences(of: "(?is)<(script|style)[^>]*>.*?</\\1>", with: "", options: .regularExpression)
        clean = clean.replacingOccurrences(of: "\\son\\w+=\"[^\"]*\"", with: "", options: .regularExpression)
        clean = clean.replacingOccurrences(of: "(?i)javascript:[^\"']*", with: "", options: .regularExpression)
        
        if input == clean {
            return Result(verdict: .allow, reason: "No changes", mime: "text/html", data: utf8Html)
        } else {
            return Result(verdict: .sanitized, reason: "Sanitized HTML allowlist", mime: "text/html", data: clean.data(using: .utf8))
        }
    }
    
    // MARK: - 3. Image Sanitization
    public func sanitizeImage(_ bytes: Data) -> Result {
        guard let image = UIImage(data: bytes) else {
            return Result(verdict: .block, reason: "Unrecognized or corrupt image", mime: "image/jpeg", data: nil)
        }
        
        let pixels = Int(image.size.width * image.size.height)
        var processed = image
        
        if pixels > limits.maxImagePixels {
            let scale = sqrt(Double(limits.maxImagePixels) / Double(pixels))
            let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            processed = resize(image, to: newSize)
        }
        
        processed = capEdge(processed, maxEdge: limits.maxImageEdge)
        
        guard let out = processed.jpegData(compressionQuality: 0.8) else {
            return Result(verdict: .block, reason: "Failed to re-encode image", mime: "image/jpeg", data: nil)
        }
        
        return Result(verdict: .sanitized,
                      reason: "Re-encoded PNG (metadata/animation removed)",
                      mime: "image/png",
                      data: out)
    }
    
    private func resize(_ image: UIImage, to size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, true, 1.0)
        image.draw(in: CGRect(origin: .zero, size: size))
        let newImg = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImg ?? image
    }
    
    private func capEdge(_ image: UIImage, maxEdge: Int) -> UIImage {
        let w = image.size.width
        let h = image.size.height
        let maxDim = max(w, h)
        if maxDim <= CGFloat(maxEdge) { return image }
        
        let scale = CGFloat(maxEdge) / maxDim
        let newSize = CGSize(width: w * scale, height: h * scale)
        return resize(image, to: newSize)
    }
    
    // MARK: - 4. PDF Sanitization
    public func sanitizePdf(_ pdfData: Data) -> Result {
        guard let pdf = PDFDocument(data: pdfData) else {
            return Result(
                verdict: .block,
                reason: "Unrecognized or corrupt PDF",
                mime: "application/octet-stream",
                data: nil
            )
        }
        
        // ✅ Allowed as-is
        return Result(
            verdict: .allow,
            reason: "PDF is valid and within limits",
            mime: "application/pdf",
            data: pdfData
        )
    }
    
    // MARK: - 5. MIME Sniffing
    public static func sniffMime(_ data: Data) -> String {
        let bytes = [UInt8](data.prefix(8))
        guard bytes.count >= 4 else { return "application/octet-stream" }
        
        if bytes.starts(with: [0x89, 0x50, 0x4E, 0x47]) { return "image/png" }
        if bytes.starts(with: [0xFF, 0xD8]) { return "image/jpeg" }
        if bytes.starts(with: [0x47, 0x49, 0x46]) { return "image/gif" }
        if bytes.starts(with: [0x25, 0x50, 0x44, 0x46]) { return "application/pdf" }
        if bytes.starts(with: [0x50, 0x4B]) { return "application/zip" }
        
        if let s = String(data: data.prefix(32), encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
            if s.hasPrefix("<!doctype html") || s.hasPrefix("<html") || s.hasPrefix("<body") {
                return "text/html"
            }
        }
        
        return "application/octet-stream"
    }
    
    public static func containsHtmlTags(_ input: String) -> Bool {
        let pattern = ".*<[^>]+>.*"
        return input.range(of: pattern, options: .regularExpression) != nil
    }
}

class QRScannerViewController: UIViewController {
    
    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    
    private let scanAreaSize: CGFloat = 280
    
    // Overlay
    private let overlayView = UIView()
    
    private let backButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        button.setTitle(" " + "Scan".localized(), for: .normal)
        button.tintColor = .white
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        button.contentHorizontalAlignment = .leading
        return button
    }()
    
    private let showCodeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "promo-code_white", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.resized(to: CGSize(width: 20, height: 20)), for: .normal)
        button.tintColor = .white
        button.setTitle(" " + "Show Code".localized(), for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.contentHorizontalAlignment = .center
        button.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        button.layer.cornerRadius = 25
        return button
    }()
    
    private let promoButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "discount_white", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.resized(to: CGSize(width: 20, height: 20)), for: .normal)
        button.tintColor = .white
        button.setTitle(" " + "Promo".localized(), for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        button.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        button.layer.cornerRadius = 22
        return button
    }()
    
    private let transferButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "bank-transfer_white", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.resized(to: CGSize(width: 20, height: 20)), for: .normal)
        button.tintColor = .white
        button.setTitle(" " + "Transfer".localized(), for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        button.layer.cornerRadius = 25
        return button
    }()
    
    private let labelPoweredBy: UILabel = {
        let label = UILabel()
        label.text = "Powered by".localized()
        label.font = UIFont.boldSystemFont(ofSize: 22)
        label.textColor = .white
        return label
    }()
    
    private let qrisLogo: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "qris_logo_white", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCamera()
        setupOverlay()
        setupUI()
    }
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video),
              let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice)
        else { return }
        
        if captureSession.canAddInput(videoInput) { captureSession.addInput(videoInput) }
        
        let metadataOutput = AVCaptureMetadataOutput()
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
        
        captureSession.startRunning()
    }
    
    private func setupOverlay() {
        overlayView.frame = view.bounds
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        
        // Create mask with transparent hole
        let path = UIBezierPath(rect: overlayView.bounds)
        let cutoutRect = CGRect(
            x: (view.frame.width - scanAreaSize) / 2,
            y: (view.frame.height - scanAreaSize) / 2,
            width: scanAreaSize,
            height: scanAreaSize
        )
        let cutoutPath = UIBezierPath(roundedRect: cutoutRect, cornerRadius: 8)
        path.append(cutoutPath.reversing())
        
        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        overlayView.layer.mask = maskLayer
        
        view.addSubview(overlayView)
        
        // Add orange corners
        addCornerIndicators(to: overlayView, rect: cutoutRect)
        
        // Combine label + logo
        let poweredStack = UIStackView(arrangedSubviews: [labelPoweredBy, qrisLogo])
        poweredStack.axis = .horizontal
        poweredStack.alignment = .center
        poweredStack.spacing = 6

        view.addSubview(poweredStack)
        poweredStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            poweredStack.topAnchor.constraint(equalTo: overlayView.topAnchor, constant: cutoutRect.maxY + 16),
            poweredStack.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        
        qrisLogo.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            qrisLogo.widthAnchor.constraint(equalToConstant: 80),
            qrisLogo.heightAnchor.constraint(equalToConstant: 80)
        ])
    }
    
    private func addCornerIndicators(to view: UIView, rect: CGRect) {
        let lineLength: CGFloat = 30
        let lineWidth: CGFloat = 4
        let color = UIColor.mainColor.cgColor
        
        func addLine(from: CGPoint, to: CGPoint) {
            let line = CAShapeLayer()
            let path = UIBezierPath()
            path.move(to: from)
            path.addLine(to: to)
            line.path = path.cgPath
            line.strokeColor = color
            line.lineWidth = lineWidth
            view.layer.addSublayer(line)
        }
        
        // Top-left
        addLine(from: rect.origin, to: CGPoint(x: rect.minX + lineLength, y: rect.minY))
        addLine(from: rect.origin, to: CGPoint(x: rect.minX, y: rect.minY + lineLength))
        
        // Top-right
        addLine(from: CGPoint(x: rect.maxX, y: rect.minY),
                to: CGPoint(x: rect.maxX - lineLength, y: rect.minY))
        addLine(from: CGPoint(x: rect.maxX, y: rect.minY),
                to: CGPoint(x: rect.maxX, y: rect.minY + lineLength))
        
        // Bottom-left
        addLine(from: CGPoint(x: rect.minX, y: rect.maxY),
                to: CGPoint(x: rect.minX + lineLength, y: rect.maxY))
        addLine(from: CGPoint(x: rect.minX, y: rect.maxY),
                to: CGPoint(x: rect.minX, y: rect.maxY - lineLength))
        
        // Bottom-right
        addLine(from: CGPoint(x: rect.maxX, y: rect.maxY),
                to: CGPoint(x: rect.maxX - lineLength, y: rect.maxY))
        addLine(from: CGPoint(x: rect.maxX, y: rect.maxY),
                to: CGPoint(x: rect.maxX, y: rect.maxY - lineLength))
    }
    
    private func setupUI() {
        // Back button
        view.addSubview(backButton)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8)
        ])
        backButton.addTarget(self, action: #selector(didTapBack), for: .touchUpInside)
        
        // Bottom buttons
        let stack = UIStackView(arrangedSubviews: [showCodeButton, promoButton, transferButton])
        stack.axis = .horizontal
        stack.spacing = 20
        stack.alignment = .center
        view.addSubview(stack)
        
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        
        showCodeButton.translatesAutoresizingMaskIntoConstraints = false
        transferButton.translatesAutoresizingMaskIntoConstraints = false
        promoButton.translatesAutoresizingMaskIntoConstraints = false
        
        showCodeButton.addTarget(self, action: #selector(didTapShowCode), for: .touchUpInside)
        transferButton.addTarget(self, action: #selector(didTapTransfer), for: .touchUpInside)
        promoButton.addTarget(self, action: #selector(didTapPromo), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            showCodeButton.widthAnchor.constraint(equalToConstant: 120),
            showCodeButton.heightAnchor.constraint(equalToConstant: 50),
            transferButton.widthAnchor.constraint(equalToConstant: 100),
            transferButton.heightAnchor.constraint(equalToConstant: 50),
            promoButton.widthAnchor.constraint(equalToConstant: 80),
            promoButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    @objc private func didTapBack() {
        captureSession.stopRunning()
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func didTapShowCode() {
        showWebview(url: Utils.getURLBase() + "nexilis/pages/read-qr?qr=")
    }
    
    @objc private func didTapTransfer() {
        showWebview(url: Utils.getURLBase() + "nexilis/pages/read-qr?qr=")
    }
    
    @objc private func didTapPromo() {
        showWebview(url: Utils.getURLBase() + "nexilis/pages/read-qr?qr=")
    }
    
    func showWebview(url: String) {
        let controller = BNIBookingWebView()
        controller.customUrl = url
        controller.onDismiss = {
            self.captureSession.startRunning()
        }
        present(controller, animated: true)
    }
}

/// The strip that stands in for a call screen while the call is minimised: who it is with, how
/// long it has been running, mute, and hang up. Tapping it goes back to the call.
/// The strip that keeps a restore in view after its screen has been left.
///
/// Same shape and window as the minimised call: a restore takes minutes, and the reader should be
/// able to get on with the app without losing sight of it or wondering whether it is still running.
public final class RestoreProgressBanner: UIView {

    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let bar = UIProgressView(progressViewStyle: .default)

    static let height: CGFloat = 60
    static let cornerOverhang: CGFloat = 10
    private static let barColor = UIColor(red: 36.0 / 255.0, green: 38.0 / 255.0, blue: 37.0 / 255.0, alpha: 1.0)

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = RestoreProgressBanner.barColor

        iconView.image = UIImage(systemName: "arrow.down.circle.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold))
        iconView.tintColor = .mainColor
        iconView.contentMode = .scaleAspectFit
        addSubview(iconView)
        iconView.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.textColor = .mainColor
        titleLabel.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        bar.progressTintColor = .mainColor
        bar.trackTintColor = UIColor(white: 1, alpha: 0.2)
        bar.layer.cornerRadius = 2
        bar.clipsToBounds = true
        addSubview(bar)
        bar.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: topAnchor, constant: 22),
            iconView.widthAnchor.constraint(equalToConstant: 18),
            iconView.heightAnchor.constraint(equalToConstant: 18),

            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -16),
            titleLabel.centerYAnchor.constraint(equalTo: iconView.centerYAnchor),

            bar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            bar.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            bar.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 8),
            bar.heightAnchor.constraint(equalToConstant: 4)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(text: String, fraction: Double) {
        titleLabel.text = text
        bar.setProgress(Float(min(max(fraction, 0), 1)), animated: true)
    }

    func onTap(_ target: Any, action: Selector) {
        addGestureRecognizer(UITapGestureRecognizer(target: target, action: action))
    }
}

/// Where the restore says how far it has got, whether or not its own screen is on show.
public final class RestoreProgressManager {

    public static let shared = RestoreProgressManager()

    private var banner: RestoreProgressBanner?
    private var window: MiniCallBannerWindow?
    private var text = ""
    private var fraction: Double = 0
    /// Whether a restore is running at all - the strip is only worth showing while one is.
    public private(set) var isRunning = false
    /// What to do when the strip is tapped: put the reader back on the restore screen.
    public var onTap: (() -> Void)?

    private init() {}

    public func begin() {
        isRunning = true
    }

    public func finish() {
        isRunning = false
        hide()
    }

    /// Called from wherever the work is, at whatever rate it likes. Kept even while the strip is
    /// down, so putting it up mid-restore shows the right thing immediately.
    public func report(text: String, fraction: Double) {
        DispatchQueue.main.async {
            self.text = text
            self.fraction = fraction
            self.banner?.update(text: text, fraction: fraction)
        }
    }

    public func show() {
        guard isRunning, banner == nil else {
            banner?.update(text: text, fraction: fraction)
            return
        }
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive })
            ?? UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first else {
            return
        }
        let banner = RestoreProgressBanner()
        banner.update(text: text, fraction: fraction)
        banner.onTap(self, action: #selector(bannerTapped))

        let host = UIViewController()
        host.view.backgroundColor = .clear
        host.view.addSubview(banner)
        banner.translatesAutoresizingMaskIntoConstraints = false

        let window = MiniCallBannerWindow(windowScene: scene)
        window.backgroundColor = .clear
        window.windowLevel = .statusBar + 1
        window.rootViewController = host
        window.isHidden = false

        NSLayoutConstraint.activate([
            banner.leadingAnchor.constraint(equalTo: host.view.leadingAnchor),
            banner.trailingAnchor.constraint(equalTo: host.view.trailingAnchor),
            banner.topAnchor.constraint(equalTo: host.view.safeAreaLayoutGuide.topAnchor),
            banner.heightAnchor.constraint(equalToConstant: RestoreProgressBanner.height + RestoreProgressBanner.cornerOverhang)
        ])
        window.layoutIfNeeded()

        self.window = window
        self.banner = banner

        banner.transform = CGAffineTransform(translationX: 0, y: -(RestoreProgressBanner.height + RestoreProgressBanner.cornerOverhang + window.safeAreaInsets.top))
        UIView.animate(withDuration: 0.30, delay: 0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0.4) {
            banner.transform = .identity
        }
    }

    public func hide() {
        guard let banner = banner, let window = window else {
            return
        }
        self.banner = nil
        self.window = nil
        UIView.animate(withDuration: 0.25, animations: {
            banner.transform = CGAffineTransform(translationX: 0, y: -(RestoreProgressBanner.height + RestoreProgressBanner.cornerOverhang + window.safeAreaInsets.top))
        }, completion: { _ in
            window.isHidden = true
            window.rootViewController = nil
        })
    }

    @objc private func bannerTapped() {
        onTap?()
    }
}

final class MiniCallBanner: UIView {

    private let muteButton = UIButton(type: .system)
    private let endCallButton = UIButton(type: .system)
    private let iconView = UIImageView()
    private let titleLabel = UILabel()

    private var timer: Timer?
    private var name = ""
    /// Asked once a second for what the call screen itself is showing, so the strip never says
    /// something different from the screen behind it.
    private var statusProvider: (() -> String)?

    // Measured off WhatsApp's own call bar: 60pt tall, 40pt round buttons 16pt in from each
    // edge, and the bar itself a near-black rather than a colour.
    static let height: CGFloat = 60
    /// How far the bar carries on below its visible edge, painting the two wedges that make the
    /// page underneath look like it has rounded top corners. See buildCornerMask().
    static let cornerOverhang: CGFloat = 10
    private static let barColor = UIColor(red: 36.0 / 255.0, green: 38.0 / 255.0, blue: 37.0 / 255.0, alpha: 1.0)
    private static let muteColor = UIColor(white: 51.0 / 255.0, alpha: 1.0)
    private static let endColor = UIColor(red: 213.0 / 255.0, green: 46.0 / 255.0, blue: 63.0 / 255.0, alpha: 1.0)
    private static let buttonSize: CGFloat = 40
    private static let sideMargin: CGFloat = 16

    private var isMuted = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    deinit {
        timer?.invalidate()
    }

    private func setupUI() {
        backgroundColor = MiniCallBanner.barColor

        // Green is WhatsApp's; this app's own colour says the same thing here.
        iconView.image = UIImage(systemName: "phone.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold))
        iconView.tintColor = .mainColor
        iconView.contentMode = .scaleAspectFit

        titleLabel.textColor = .mainColor
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textAlignment = .center

        muteButton.tintColor = .white
        muteButton.backgroundColor = MiniCallBanner.muteColor
        muteButton.setImage(UIImage(systemName: "mic.slash.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .regular)), for: .normal)
        muteButton.layer.cornerRadius = MiniCallBanner.buttonSize / 2
        muteButton.clipsToBounds = true

        endCallButton.tintColor = .white
        endCallButton.backgroundColor = MiniCallBanner.endColor
        endCallButton.setImage(UIImage(systemName: "phone.down.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .regular)), for: .normal)
        endCallButton.layer.cornerRadius = MiniCallBanner.buttonSize / 2
        endCallButton.clipsToBounds = true

        let centerStack = UIStackView(arrangedSubviews: [iconView, titleLabel])
        centerStack.axis = .horizontal
        centerStack.spacing = 6
        centerStack.alignment = .center
        centerStack.isUserInteractionEnabled = false

        addSubview(centerStack)
        addSubview(muteButton)
        addSubview(endCallButton)

        centerStack.translatesAutoresizingMaskIntoConstraints = false
        muteButton.translatesAutoresizingMaskIntoConstraints = false
        endCallButton.translatesAutoresizingMaskIntoConstraints = false
        iconView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            centerStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            centerStack.centerYAnchor.constraint(equalTo: topAnchor, constant: MiniCallBanner.height / 2),
            centerStack.leadingAnchor.constraint(greaterThanOrEqualTo: muteButton.trailingAnchor, constant: 8),
            centerStack.trailingAnchor.constraint(lessThanOrEqualTo: endCallButton.leadingAnchor, constant: -8),

            iconView.widthAnchor.constraint(equalToConstant: 22),
            iconView.heightAnchor.constraint(equalToConstant: 18),

            muteButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: MiniCallBanner.sideMargin),
            muteButton.centerYAnchor.constraint(equalTo: topAnchor, constant: MiniCallBanner.height / 2),
            muteButton.widthAnchor.constraint(equalToConstant: MiniCallBanner.buttonSize),
            muteButton.heightAnchor.constraint(equalToConstant: MiniCallBanner.buttonSize),

            endCallButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -MiniCallBanner.sideMargin),
            endCallButton.centerYAnchor.constraint(equalTo: topAnchor, constant: MiniCallBanner.height / 2),
            endCallButton.widthAnchor.constraint(equalToConstant: MiniCallBanner.buttonSize),
            endCallButton.heightAnchor.constraint(equalToConstant: MiniCallBanner.buttonSize)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        buildCornerMask()
    }

    /// The curve belongs to the page, not to this bar.
    ///
    /// In WhatsApp the corners you see are the top corners of the screen underneath: the bar is
    /// a plain rectangle that carries on a little way behind it, and what shows in the two
    /// corners is that bar. Rounding this view's own bottom corners gives the opposite - the
    /// page's square corners poking out past a curved bar. So the bar is drawn a few points
    /// taller than it looks, and everything below its visible edge is masked away except the two
    /// wedges outside where the page's rounded corners would be.
    private func buildCornerMask() {
        let radius = MiniCallBanner.cornerOverhang
        let shape = UIBezierPath(rect: bounds)
        // The page below, with the top corners it appears to have. Taken well past the bottom
        // edge so only its top corners are ever rounded.
        let page = UIBezierPath(roundedRect: CGRect(x: 0, y: MiniCallBanner.height, width: bounds.width, height: max(bounds.height - MiniCallBanner.height, radius) + radius * 2),
                                byRoundingCorners: [.topLeft, .topRight],
                                cornerRadii: CGSize(width: radius, height: radius))
        shape.append(page)
        let mask = CAShapeLayer()
        mask.path = shape.cgPath
        // Even-odd, so the page's shape is punched out of the bar rather than added to it.
        mask.fillRule = .evenOdd
        layer.mask = mask
    }

    /// Only the bar itself takes touches - the overhang is two thin wedges of paint at the very
    /// corners, and the page underneath should keep everything else.
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return point.y >= 0 && point.y <= MiniCallBanner.height && point.x >= 0 && point.x <= bounds.width
    }

    // MARK: - Public API

    func configure(name: String, isMuted: Bool, status: @escaping () -> String) {
        self.name = name
        self.statusProvider = status
        setMuted(isMuted)
        updateTitle()
        startTimer()
    }

    func setMuted(_ muted: Bool) {
        isMuted = muted
        muteButton.backgroundColor = muted ? .white : MiniCallBanner.muteColor
        muteButton.tintColor = muted ? MiniCallBanner.endColor : .white
    }

    func onMute(_ target: Any?, action: Selector) {
        muteButton.addTarget(target, action: action, for: .touchUpInside)
    }

    func onEnd(_ target: Any?, action: Selector) {
        endCallButton.addTarget(target, action: action, for: .touchUpInside)
    }

    /// Fix: a tap on the strip used to be a gesture recogniser on the view. A button is the
    /// dependable way to be tapped - it cannot be beaten to the touch by another recogniser
    /// somewhere above it, and it shows the reader that the strip is something to press. It is
    /// added underneath the mute and hang-up buttons, so those still get their own taps.
    func onTap(_ target: Any?, action: Selector) {
        let tapTarget = UIButton(type: .custom)
        tapTarget.backgroundColor = .clear
        tapTarget.addTarget(target, action: action, for: .touchUpInside)
        insertSubview(tapTarget, at: 0)
        tapTarget.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tapTarget.topAnchor.constraint(equalTo: topAnchor),
            tapTarget.leadingAnchor.constraint(equalTo: leadingAnchor),
            tapTarget.trailingAnchor.constraint(equalTo: trailingAnchor),
            tapTarget.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    func stopUpdating() {
        timer?.invalidate()
        timer = nil
    }

    private func updateTitle() {
        let status = statusProvider?() ?? ""
        titleLabel.text = status.isEmpty ? name : "\(name) - \(status)"
    }

    private func startTimer() {
        timer?.invalidate()
        let timer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateTitle()
        }
        timer.tolerance = 0.2
        // Common mode, or the duration stops counting the moment anything is being scrolled.
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }
}

/// The window the banner lives in.
///
/// Fix: the banner used to be a subview of the key window, which put it under anything presented
/// afterwards - a modal from the library, a picker from the host app - so a call minimised on one
/// screen vanished on the next. A window of its own sits above all of that, and passes every
/// touch outside the strip itself straight through to the app.
final class MiniCallBannerWindow: UIWindow {

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let hit = super.hitTest(point, with: event) else {
            return nil
        }
        return hit === self || hit === rootViewController?.view ? nil : hit
    }
}

/// The window a minimised video call floats in.
///
/// Same reasoning as the audio banner's window: over every page of the app, library or host,
/// and every touch outside the bubble itself belongs to whatever is underneath.
final class MiniVideoCallWindow: UIWindow {

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let hit = super.hitTest(point, with: event) else {
            return nil
        }
        return hit === self || hit === rootViewController?.view ? nil : hit
    }
}

/// A video call carried on in a corner of the screen, the way WhatsApp does it: the call itself
/// keeps running, shrunk into a bubble that can be dragged around and tapped to go back to.
final public class MiniVideoCallManager {

    public static let shared = MiniVideoCallManager()

    private var window: MiniVideoCallWindow?
    private var bubble: UIView?
    /// What was presented for this call - a navigation controller on some routes, the call
    /// screen itself on others. Held strongly: a dismissed view controller is released by UIKit
    /// the moment it goes, and this one's deinit ends the call.
    private var callContainer: UIViewController?
    private weak var call: QmeraVideoViewController?

    private static let size = CGSize(width: 110, height: 160)
    private static let margin: CGFloat = 12

    public var isShowing: Bool {
        return bubble != nil
    }

    private init() {}

    // MARK: - Showing

    func show(for call: QmeraVideoViewController?, container: UIViewController) {
        guard bubble == nil, let call = call else {
            return
        }
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive })
            ?? UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first else {
            return
        }
        self.call = call
        self.callContainer = container

        let host = UIViewController()
        host.view.backgroundColor = .clear

        let bubble = UIView()
        bubble.backgroundColor = .black
        bubble.layer.cornerRadius = 12
        // The call is scaled down inside this, and anything outside the bubble is cut away.
        bubble.clipsToBounds = true
        bubble.layer.shadowColor = UIColor.black.cgColor
        bubble.layer.shadowOpacity = 0.3
        bubble.layer.shadowRadius = 8
        bubble.layer.shadowOffset = CGSize(width: 0, height: 2)
        host.view.addSubview(bubble)

        let window = MiniVideoCallWindow(windowScene: scene)
        window.backgroundColor = .clear
        window.windowLevel = .statusBar + 1
        window.rootViewController = host
        window.isHidden = false

        let screen = window.bounds.size
        bubble.frame = CGRect(x: screen.width - MiniVideoCallManager.size.width - MiniVideoCallManager.margin,
                              y: window.safeAreaInsets.top + MiniVideoCallManager.margin,
                              width: MiniVideoCallManager.size.width,
                              height: MiniVideoCallManager.size.height)

        // The whole call screen is carried across, scaled down - not just the video view. The
        // frames are drawn by the SDK straight into image views inside it, so leaving that
        // hierarchy exactly as it is means the call carries on rendering with nothing rewired.
        container.willMove(toParent: host)
        host.addChild(container)
        bubble.addSubview(container.view)
        container.view.transform = .identity
        container.view.frame = CGRect(origin: .zero, size: screen)
        // Filled rather than fitted: a bubble the shape of a phone screen would otherwise be
        // mostly empty, and what matters is seeing the call.
        let scale = max(MiniVideoCallManager.size.width / screen.width,
                        MiniVideoCallManager.size.height / screen.height)
        container.view.transform = CGAffineTransform(scaleX: scale, y: scale)
        container.view.center = CGPoint(x: bubble.bounds.midX, y: bubble.bounds.midY)
        container.view.isUserInteractionEnabled = false
        container.didMove(toParent: host)

        bubble.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(bubbleTapped)))
        bubble.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(bubbleDragged(_:))))

        self.window = window
        self.bubble = bubble

        bubble.alpha = 0
        bubble.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
        UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4) {
            bubble.alpha = 1
            bubble.transform = .identity
        }
    }

    /// Puts the call screen back, full size.
    public func restore() {
        guard let container = callContainer else {
            dismissBubble()
            return
        }
        guard let presenter = presentationHost() else {
            return
        }
        container.willMove(toParent: nil)
        container.view.removeFromSuperview()
        container.removeFromParent()
        container.view.transform = .identity
        container.view.isUserInteractionEnabled = true
        dismissBubble()
        // A call that was pushed onto a stack rather than presented has no presentation style of
        // its own - left alone it would come back as a half-height sheet. Only the styles that
        // do not cover the screen are replaced; a call opened full screen stays as it was.
        switch container.modalPresentationStyle {
        case .fullScreen, .overFullScreen, .overCurrentContext, .currentContext:
            break
        default:
            container.modalPresentationStyle = .overFullScreen
        }
        presenter.present(container, animated: true, completion: nil)
    }

    /// Called when the call itself is over, however it ended.
    public func callDidEnd() {
        let ending = callContainer
        callContainer = nil
        call = nil
        dismissBubble()
        // Released next turn: this is nearly always called from the call's own code.
        DispatchQueue.main.async {
            _ = ending
        }
    }

    private func dismissBubble() {
        guard let bubble = bubble, let window = window else {
            return
        }
        self.bubble = nil
        self.window = nil
        UIView.animate(withDuration: 0.2, animations: {
            bubble.alpha = 0
            bubble.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
        }, completion: { _ in
            window.isHidden = true
            window.rootViewController = nil
        })
    }

    private func presentationHost() -> UIViewController? {
        let appWindow = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: { !($0 is MiniVideoCallWindow) && !($0 is MiniCallBannerWindow) && !$0.isHidden && $0.rootViewController != nil })
        guard var top = appWindow?.rootViewController else {
            return window?.rootViewController
        }
        for _ in 0..<20 {
            if let presented = top.presentedViewController {
                top = presented
            } else if let tab = top as? UITabBarController, let selected = tab.selectedViewController {
                top = selected
            } else if let navigation = top as? UINavigationController, let visible = navigation.visibleViewController {
                top = visible
            } else {
                break
            }
        }
        return top
    }

    // MARK: - Gestures

    @objc private func bubbleTapped() {
        restore()
    }

    @objc private func bubbleDragged(_ sender: UIPanGestureRecognizer) {
        guard let bubble = bubble, let window = window else {
            return
        }
        switch sender.state {
        case .changed:
            let translation = sender.translation(in: window)
            bubble.center = CGPoint(x: bubble.center.x + translation.x, y: bubble.center.y + translation.y)
            sender.setTranslation(.zero, in: window)
        case .ended, .cancelled:
            // Settles against whichever side it was let go nearest, and never off the screen.
            let insets = window.safeAreaInsets
            let half = MiniVideoCallManager.size.width / 2
            let targetX = bubble.center.x < window.bounds.midX
                ? half + MiniVideoCallManager.margin
                : window.bounds.width - half - MiniVideoCallManager.margin
            let minY = insets.top + MiniVideoCallManager.size.height / 2 + MiniVideoCallManager.margin
            let maxY = window.bounds.height - insets.bottom - MiniVideoCallManager.size.height / 2 - MiniVideoCallManager.margin
            let targetY = min(max(bubble.center.y, minY), max(minY, maxY))
            UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5) {
                bubble.center = CGPoint(x: targetX, y: targetY)
            }
        default:
            break
        }
    }
}

final public class MiniCallBannerManager {

    public static let shared = MiniCallBannerManager()

    private var banner: MiniCallBanner?
    private var window: MiniCallBannerWindow?
    /// The call screen that was minimised.
    ///
    /// Held strongly, and that is the whole point: a dismissed view controller is released by
    /// UIKit the moment it goes, and this one's deinit ends the call. Holding it keeps the call
    /// - its timers, its observers, its audio - alive and lets it be put back exactly as it was.
    /// Released in callDidEnd(), which every ending goes through.
    private var call: QmeraAudioViewController?

    public var isShowing: Bool {
        return banner != nil
    }

    private init() {}

    // MARK: - Showing

    func show(for call: QmeraAudioViewController) {
        // The call is remembered before anything else. A strip left over from an earlier call
        // used to make this return early, and then the strip on screen belonged to a call this
        // object no longer had - tapping it could only take itself away.
        self.call = call
        if let banner = banner {
            banner.configure(name: call.miniBannerTitle, isMuted: call.isMutedNow) { [weak call] in
                return call?.miniBannerStatus ?? ""
            }
            return
        }
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive })
            ?? UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first else {
            return
        }
        let banner = MiniCallBanner()
        banner.configure(name: call.miniBannerTitle, isMuted: call.isMutedNow) { [weak call] in
            return call?.miniBannerStatus ?? ""
        }
        banner.onMute(self, action: #selector(muteTapped))
        banner.onEnd(self, action: #selector(endTapped))
        banner.onTap(self, action: #selector(bannerTapped))

        let host = UIViewController()
        host.view.backgroundColor = .clear
        host.view.addSubview(banner)
        banner.translatesAutoresizingMaskIntoConstraints = false

        let window = MiniCallBannerWindow(windowScene: scene)
        window.backgroundColor = .clear
        // Above everything the app itself can put up, and below the system's own alerts.
        window.windowLevel = .statusBar + 1
        window.rootViewController = host
        window.isHidden = false

        NSLayoutConstraint.activate([
            banner.leadingAnchor.constraint(equalTo: host.view.leadingAnchor),
            banner.trailingAnchor.constraint(equalTo: host.view.trailingAnchor),
            banner.topAnchor.constraint(equalTo: host.view.safeAreaLayoutGuide.topAnchor),
            banner.heightAnchor.constraint(equalToConstant: MiniCallBanner.height + MiniCallBanner.cornerOverhang)
        ])
        window.layoutIfNeeded()

        self.window = window
        self.banner = banner

        banner.transform = CGAffineTransform(translationX: 0, y: -(MiniCallBanner.height + MiniCallBanner.cornerOverhang + window.safeAreaInsets.top))
        UIView.animate(withDuration: 0.30, delay: 0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0.4) {
            banner.transform = .identity
        }
        refreshInsetsIfShowing()
        startInsetWatch()
    }

    /// Puts the call screen back and takes the strip away.
    ///
    /// Fix: this used to ask UIApplication for its "visible" view controller, which is found by
    /// looking for the key window - and there is more than one window on screen now, so that
    /// answer could be the banner's own window (whose root presents nothing anyone can see) or
    /// nothing at all, in which case the tap did nothing. The app's own window is found
    /// explicitly here, and the screen it is presented on top of is walked down from its root.
    public func restore() {
        guard let call = call else {
            dismissBanner()
            return
        }
        guard call.presentingViewController == nil else {
            // Already back on screen somehow; nothing to do but tidy up.
            dismissBanner()
            return
        }
        guard let presenter = presentationHost() else {
            return
        }
        // Full screen on the way back, whatever it was opened with: over-current-context hands
        // the size of the presentation to whichever ancestor happens to define a context, and
        // the one it was opened from is long gone.
        call.modalPresentationStyle = .overFullScreen
        presenter.present(call, animated: true, completion: nil)
        dismissBanner()
    }

    /// The screen the call should be put back on top of: the deepest thing on show in the app's
    /// own window, skipping the banner's window entirely.
    private func presentationHost() -> UIViewController? {
        guard var top = appWindow()?.rootViewController else {
            // Nothing of the app is up - the banner's own window can host it rather than
            // leaving the reader with a strip that does nothing.
            return window?.rootViewController
        }
        for _ in 0..<20 {
            if let presented = top.presentedViewController {
                top = presented
            } else if let tab = top as? UITabBarController, let selected = tab.selectedViewController {
                top = selected
            } else if let navigation = top as? UINavigationController, let visible = navigation.visibleViewController {
                top = visible
            } else {
                break
            }
        }
        return top
    }

    /// Called when the call itself is over, however it ended.
    public func callDidEnd() {
        // Released next turn, not here: this is nearly always called from a method on that very
        // screen, and dropping the last reference to it half way through one of its own methods
        // is a use-after-free waiting to happen.
        let ending = call
        call = nil
        dismissBanner()
        DispatchQueue.main.async {
            _ = ending
        }
    }

    private func dismissBanner() {
        guard let banner = banner, let window = window else {
            return
        }
        self.banner = nil
        self.window = nil
        banner.stopUpdating()
        stopInsetWatch()
        clearInsets()
        UIView.animate(withDuration: 0.25, animations: {
            banner.transform = CGAffineTransform(translationX: 0, y: -(MiniCallBanner.height + MiniCallBanner.cornerOverhang + window.safeAreaInsets.top))
        }, completion: { _ in
            window.isHidden = true
            window.rootViewController = nil
        })
    }

    // MARK: - Making room

    /// Every screen that has been moved down for the strip, and by exactly one strip's height
    /// each.
    ///
    /// Fix: this used to be a single running total applied to "the root view controller" -
    /// whichever one that was at the time. Two things went wrong with that. A screen presented
    /// on top of the root is not inside it and inherits nothing, so on any library page put up
    /// modally the strip sat over the navigation bar. And when the amount was taken back off a
    /// different controller than the one it was added to, the difference stayed - which is the
    /// top of the screen creeping further down every time a call was minimised again. Keeping
    /// the actual controllers means what was added is what gets removed, from the same places.
    private let insetControllers = NSHashTable<UIViewController>.weakObjects()
    private var insetTimer: Timer?

    /// Moves down anything on screen that has not been moved down yet: the window's root, and
    /// every screen presented on top of it. Their own children - tabs, navigation stacks, the
    /// screens inside them - inherit it, so only the outermost of each is touched.
    public func refreshInsetsIfShowing() {
        guard isShowing else {
            return
        }
        guard let root = appWindow()?.rootViewController else {
            return
        }
        var chain: [UIViewController] = []
        var next: UIViewController? = root
        // Presentation only ever nests a few deep; the count is here so a broken hierarchy
        // cannot spin this forever.
        for _ in 0..<20 {
            guard let current = next else {
                break
            }
            chain.append(current)
            next = current.presentedViewController
        }
        // Alerts and action sheets place themselves; moving their safe area only moves them
        // somewhere they were never meant to be.
        for controller in chain where controller !== call
            && !(controller is UIAlertController)
            && !insetControllers.contains(controller) {
            insetControllers.add(controller)
            UIView.animate(withDuration: 0.25) {
                controller.additionalSafeAreaInsets.top += MiniCallBanner.height
                controller.view.layoutIfNeeded()
            }
        }
    }

    private func clearInsets() {
        for controller in insetControllers.allObjects {
            let restored = max(0, controller.additionalSafeAreaInsets.top - MiniCallBanner.height)
            UIView.animate(withDuration: 0.25) {
                controller.additionalSafeAreaInsets.top = restored
                controller.view.layoutIfNeeded()
            }
        }
        insetControllers.removeAllObjects()
    }

    /// Screens come and go while a call is minimised, and most of the ones in this project never
    /// call super in viewDidAppear - so there is no notification to rely on. Looking every half
    /// second costs a walk down a handful of controllers and covers every route.
    private func startInsetWatch() {
        insetTimer?.invalidate()
        let timer = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.refreshInsetsIfShowing()
        }
        timer.tolerance = 0.2
        RunLoop.main.add(timer, forMode: .common)
        insetTimer = timer
    }

    private func stopInsetWatch() {
        insetTimer?.invalidate()
        insetTimer = nil
    }

    /// The app's own window, never the banner's.
    private func appWindow() -> UIWindow? {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: { !($0 is MiniCallBannerWindow) && !$0.isHidden && $0.rootViewController != nil })
    }

    // MARK: - Buttons

    @objc private func muteTapped() {
        guard let call = call else {
            return
        }
        call.didMute(sender: nil)
        banner?.setMuted(call.isMutedNow)
    }

    @objc private func endTapped() {
        call?.endCallFromMiniBanner()
    }

    @objc private func bannerTapped() {
        restore()
    }
}

extension QRScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        
        if let metadataObject = metadataObjects.first,
           let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
           let stringValue = readableObject.stringValue {
            
            captureSession.stopRunning()
//            print("Scanned: \(stringValue)")
            showWebview(url: Utils.getURLBase() + "nexilis/pages/read-qr?qr=" + stringValue)
//            let alert = UIAlertController(title: "QR Result", message: stringValue, preferredStyle: .alert)
//            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
//                self.captureSession.startRunning()
//            })
//            present(alert, animated: true, completion: nil)
        }
    }
}

extension UIImage {
    func resized(to size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

final class PendingMessageStore {

    static let shared = PendingMessageStore()
    private let key = "pending_message_ids_nexilis"

    func save(_ id: String) {
        var list = load()
        if !list.contains(id) {
            list.append(id)
        }
        UserDefaults.standard.set(list, forKey: key)
    }

    func load() -> [String] {
        UserDefaults.standard.stringArray(forKey: key) ?? []
    }

    func remove(_ id: String) {
        var list = load()
        list.removeAll { $0 == id }
        UserDefaults.standard.set(list, forKey: key)
    }
    
    func removeAll() {
        var list = load()
        list.removeAll()
        UserDefaults.standard.set(list, forKey: key)
    }
}

/// Remembers which local message a push actually turned out to be about.
///
/// Fix: the id an APN carries is not always the id the message ends up stored under - the
/// server can answer a pull for one id with a message whose MESSAGE_ID is a different one.
/// Everything downstream keyed off the APN id and so could never find that message again:
/// it stayed in PendingMessageStore forever (every foreground pulled it again, the server
/// answered "nothing left" every time), and tapping its notification looked the message up
/// by the APN id, found nothing, and opened no chat at all.
final class APNMessageAliasStore {

    static let shared = APNMessageAliasStore()
    private let key = "apn_message_id_aliases_nexilis"
    // Only enough history to cover notifications still sitting in Notification Centre.
    private let maxEntries = 200

    func record(apnId: String, storedId: String) {
        guard !apnId.isEmpty, !storedId.isEmpty, apnId != storedId else {
            return
        }
        var map = load()
        map[apnId] = storedId
        if map.count > maxEntries {
            // Nothing here is worth a real LRU; dropping arbitrary excess is fine because a
            // missing alias only costs the lookup it would have saved.
            for staleKey in map.keys.prefix(map.count - maxEntries) {
                map.removeValue(forKey: staleKey)
            }
        }
        UserDefaults.standard.set(map, forKey: key)
    }

    func storedId(forAPNId apnId: String) -> String? {
        return load()[apnId]
    }

    private func load() -> [String: String] {
        return UserDefaults.standard.dictionary(forKey: key) as? [String: String] ?? [:]
    }
}

/// Remembers a notification tap whose chat could not be opened yet.
///
/// Fix: tapping a notification for a message that is not on disk yet used to be a one-shot
/// attempt - one pull, and if that pull failed (no connection yet on a cold launch, the
/// session/cookie not restored, the server momentarily unavailable) the tap was simply lost:
/// no chat opened and the list stayed as it was, until the user backgrounded the app and came
/// back so the socket reconnect finally delivered the message. Recording the request here
/// (UserDefaults, so it also survives the app being killed right after the tap) lets the chat
/// be opened as soon as the message does land, whichever path brings it in.
final class APNPendingOpenStore {

    static let shared = APNPendingOpenStore()
    private let idKey = "apn_pending_open_id_nexilis"
    private let timeKey = "apn_pending_open_time_nexilis"
    /// Opening a chat by itself, long after the tap, would be a surprise rather than a fix.
    private let maxAge: TimeInterval = 10 * 60

    func record(apnId: String) {
        guard !apnId.isEmpty else {
            return
        }
        UserDefaults.standard.set(apnId, forKey: idKey)
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: timeKey)
    }

    /// The id still worth opening, or nil when there is none / it has gone stale.
    func pendingId() -> String? {
        guard let id = UserDefaults.standard.string(forKey: idKey), !id.isEmpty else {
            return nil
        }
        let recordedAt = UserDefaults.standard.double(forKey: timeKey)
        if recordedAt <= 0 || Date().timeIntervalSince1970 - recordedAt > maxAge {
            clear()
            return nil
        }
        return id
    }

    func clear() {
        UserDefaults.standard.removeObject(forKey: idKey)
        UserDefaults.standard.removeObject(forKey: timeKey)
    }
}

/// A card that rises from the foot of the screen carrying a question and a short list of answers.
///
/// Written to replace the system action sheet behind "Delete message?". The system sheet cannot be
/// made to look like this - its title is small grey text, its rows are full-width dividers and its
/// Cancel is a separate slab - so the card is drawn here instead. Nothing about it is specific to
/// deleting: it takes a question and some answers, and it is the caller that decides what they mean.
public final class BottomChoiceSheet: UIViewController {

    public struct Option {
        public let title: String
        public let isDestructive: Bool
        public let handler: () -> Void

        public init(title: String, isDestructive: Bool = false, handler: @escaping () -> Void) {
            self.title = title
            self.isDestructive = isDestructive
            self.handler = handler
        }
    }

    private let question: String
    private let options: [Option]
    private let backdrop = UIView()
    private let card = UIView()
    private var cardBottom: NSLayoutConstraint!

    public init(question: String, options: [Option], appearance: UIUserInterfaceStyle = .unspecified) {
        self.question = question
        self.options = options
        super.init(nibName: nil, bundle: nil)
        // Shown over a picture the card has to stay dark, or a light card lands on a dark photo.
        // Shown over the conversation it follows the app, which is what `.unspecified` leaves it to.
        overrideUserInterfaceStyle = appearance
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) {
        return nil
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear

        backdrop.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        backdrop.alpha = 0
        backdrop.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backdrop)
        backdrop.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapBackdrop)))

        card.backgroundColor = .secondarySystemBackground
        card.layer.cornerRadius = 20
        card.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        card.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(card)

        let title = UILabel()
        title.text = question
        // Not `.semibold`: the app remaps that weight onto a bold-italic face, so asking for it
        // here would set the question in italics.
        title.font = .boldSystemFont(ofSize: 17)
        title.textColor = .label
        title.textAlignment = .center
        title.numberOfLines = 2
        title.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(title)

        let close = UIButton(type: .system)
        close.setImage(UIImage(systemName: "xmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold)), for: .normal)
        close.tintColor = .label
        close.backgroundColor = .tertiarySystemFill
        close.layer.cornerRadius = 18
        close.addTarget(self, action: #selector(tapBackdrop), for: .touchUpInside)
        close.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(close)

        let rows = UIStackView()
        rows.axis = .vertical
        rows.spacing = 10
        rows.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(rows)

        for (index, option) in options.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(option.title, for: .normal)
            button.setTitleColor(option.isDestructive ? .systemRed : .label, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 17)
            button.titleLabel?.adjustsFontSizeToFitWidth = true
            button.titleLabel?.minimumScaleFactor = 0.8
            button.contentHorizontalAlignment = .leading
            button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 22, bottom: 0, right: 22)
            button.backgroundColor = .tertiarySystemBackground
            button.layer.cornerRadius = 27
            button.tag = index
            button.addTarget(self, action: #selector(tapOption(_:)), for: .touchUpInside)
            button.heightAnchor.constraint(equalToConstant: 54).isActive = true
            rows.addArrangedSubview(button)
        }

        cardBottom = card.topAnchor.constraint(equalTo: view.bottomAnchor)
        NSLayoutConstraint.activate([
            backdrop.topAnchor.constraint(equalTo: view.topAnchor),
            backdrop.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backdrop.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backdrop.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            card.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            cardBottom,

            title.topAnchor.constraint(equalTo: card.topAnchor, constant: 22),
            title.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            title.leadingAnchor.constraint(greaterThanOrEqualTo: card.leadingAnchor, constant: 70),

            close.centerYAnchor.constraint(equalTo: title.centerYAnchor),
            close.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            close.widthAnchor.constraint(equalToConstant: 36),
            close.heightAnchor.constraint(equalToConstant: 36),

            rows.topAnchor.constraint(equalTo: close.bottomAnchor, constant: 16),
            rows.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            rows.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            rows.bottomAnchor.constraint(equalTo: card.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        view.layoutIfNeeded()
        cardBottom.isActive = false
        card.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        UIView.animate(withDuration: 0.28, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.6, options: [], animations: {
            self.backdrop.alpha = 1
            self.view.layoutIfNeeded()
        })
    }

    @objc private func tapBackdrop() {
        close(then: nil)
    }

    @objc private func tapOption(_ sender: UIButton) {
        guard sender.tag >= 0, sender.tag < options.count else {
            return
        }
        // The answer is run after the card has gone, so whatever it puts up next - or takes down -
        // is not fighting this one for the screen.
        let handler = options[sender.tag].handler
        close(then: handler)
    }

    private func close(then finish: (() -> Void)?) {
        UIView.animate(withDuration: 0.2, animations: {
            self.backdrop.alpha = 0
            self.card.transform = CGAffineTransform(translationX: 0, y: self.card.bounds.height)
        }, completion: { _ in
            self.dismiss(animated: false) {
                finish?()
            }
        })
    }
}

/// The marks a video bubble carries: how long it runs, and - when the file is not here and cannot
/// be fetched - an offer to fetch it rather than a ring that never fills.
public enum VideoBubbleChrome {

    /// The camcorder and the running time along the foot of a video thumbnail.
    @discardableResult
    public static func addFooter(to host: UIView, seconds: Int) -> UILabel {
        let badge = UIImageView(image: UIImage(systemName: "video.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 11, weight: .medium)))
        badge.tintColor = .white
        badge.contentMode = .scaleAspectFit
        shade(badge.layer)
        badge.translatesAutoresizingMaskIntoConstraints = false
        host.addSubview(badge)

        let length = UILabel()
        length.text = seconds > 0 ? String(format: "%d:%02d", seconds / 60, seconds % 60) : ""
        length.font = .systemFont(ofSize: 11)
        length.textColor = .white
        shade(length.layer)
        length.translatesAutoresizingMaskIntoConstraints = false
        host.addSubview(length)

        NSLayoutConstraint.activate([
            badge.leadingAnchor.constraint(equalTo: host.leadingAnchor, constant: 8),
            badge.bottomAnchor.constraint(equalTo: host.bottomAnchor, constant: -8),
            length.leadingAnchor.constraint(equalTo: badge.trailingAnchor, constant: 5),
            length.centerYAnchor.constraint(equalTo: badge.centerYAnchor)
        ])
        return length
    }

    /// The pale pill in the middle of a video that is not on this device.
    ///
    /// What used to sit here was a progress ring, which meant a file the server will not give up
    /// showed something that looked like it was arriving and never did. This says plainly that it
    /// has to be fetched, and how big it is when that is known.
    @discardableResult
    public static func addUnavailable(to host: UIView, sizeText: String?) -> UIView {
        let pill = UIView()
        pill.backgroundColor = UIColor(white: 0.85, alpha: 0.92)
        pill.layer.cornerRadius = 22
        pill.isUserInteractionEnabled = false
        pill.translatesAutoresizingMaskIntoConstraints = false
        host.addSubview(pill)

        let arrow = UIImageView(image: UIImage(systemName: "arrow.down", withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .medium)))
        arrow.tintColor = UIColor(white: 0.25, alpha: 1)
        arrow.contentMode = .scaleAspectFit
        arrow.translatesAutoresizingMaskIntoConstraints = false
        pill.addSubview(arrow)

        let size = UILabel()
        size.text = sizeText
        size.font = .systemFont(ofSize: 14)
        size.textColor = UIColor(white: 0.25, alpha: 1)
        size.translatesAutoresizingMaskIntoConstraints = false
        pill.addSubview(size)

        NSLayoutConstraint.activate([
            pill.centerXAnchor.constraint(equalTo: host.centerXAnchor),
            pill.centerYAnchor.constraint(equalTo: host.centerYAnchor),
            pill.heightAnchor.constraint(equalToConstant: 44),
            arrow.leadingAnchor.constraint(equalTo: pill.leadingAnchor, constant: 16),
            arrow.centerYAnchor.constraint(equalTo: pill.centerYAnchor),
            arrow.widthAnchor.constraint(equalToConstant: 18),
            size.leadingAnchor.constraint(equalTo: arrow.trailingAnchor, constant: (sizeText?.isEmpty == false) ? 8 : 0),
            size.trailingAnchor.constraint(equalTo: pill.trailingAnchor, constant: -16),
            size.centerYAnchor.constraint(equalTo: pill.centerYAnchor)
        ])
        return pill
    }

    private static func shade(_ layer: CALayer) {
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.5
        layer.shadowRadius = 2
        layer.shadowOffset = .zero
    }
}

public extension Utils {

    /// The mark that says what kind of account somebody is, or nothing for an ordinary one.
    ///
    /// The same reading the profile screen does, in one place - the chat lists show it in front of
    /// a name too, and three copies of "which of these five tests wins" would drift apart.
    /// A flat, fully rounded bar for a slider with nothing drawn behind it - the plain track the
    /// reference gives an audio file, as opposed to the waveform a voice note gets. Kept once it
    /// has been drawn, since it is asked for again for every bubble that scrolls past.
    private static var sliderTracks: [String: UIImage] = [:]
    static func sliderTrack(colour: UIColor, height: CGFloat = 6) -> UIImage {
        let key = "\(colour.description)-\(height)"
        if let known = sliderTracks[key] {
            return known
        }
        let size = CGSize(width: height, height: height)
        let drawn = UIGraphicsImageRenderer(size: size).image { _ in
            colour.setFill()
            UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: height / 2).fill()
        }
        // Stretched from the middle, so the rounded ends stay round however wide the slider is.
        let image = drawn.resizableImage(withCapInsets: UIEdgeInsets(top: 0, left: height / 2, bottom: 0, right: height / 2))
        sliderTracks[key] = image
        return image
    }

    /// What a piece of audio reads as when it is being quoted - in a bubble's reply block and in
    /// the strip above the input bar alike. A voice note says so and how long it runs; an audio
    /// attachment is just audio. Both used to fall through every branch of those two, leaving the
    /// line blank.
    static func audioPreviewLine(attachmentFlag: String, audioName: String, font: UIFont, colour: UIColor) -> NSAttributedString {
        guard attachmentFlag == "60" else {
            return NSAttributedString(string: "\u{266B} " + "Audio".localized(),
                                      attributes: [.font: font, .foregroundColor: colour])
        }
        let mic = NSTextAttachment()
        mic.image = UIImage(systemName: "mic.fill")?.withTintColor(colour, renderingMode: .alwaysOriginal)
        // Sized off the text it sits in rather than a fixed number, since this line is drawn at
        // two different sizes.
        mic.bounds = CGRect(x: 0, y: -font.pointSize * 0.15, width: font.pointSize * 0.85, height: font.pointSize)
        var text = "Voice Message".localized()
        if let seconds = AudioDurationStore.seconds(forFileNamed: audioName) {
            text += String(format: " (%d:%02d)", seconds / 60, seconds % 60)
        }
        let line = NSMutableAttributedString(attachment: mic)
        line.append(NSAttributedString(string: " " + text, attributes: [.font: font, .foregroundColor: colour]))
        return line
    }

    static func accountBadge(forPin pin: String?) -> UIImage? {
        guard let pin = pin, !pin.isEmpty, let user = User.getData(pin: pin) else {
            return nil
        }
        return accountBadge(official: user.official ?? "", userType: user.userType ?? "")
    }

    static func accountBadge(official: String, userType: String) -> UIImage? {
        let bundle = Bundle.resourceBundle(for: Nexilis.self)
        if User.isOfficialRegular(official_account: official) || User.isOfficial(official_account: official) {
            return UIImage(named: "ic_official_flag", in: bundle, with: nil)
        }
        if User.isVerified(official_account: official) {
            return UIImage(named: "ic_verified", in: bundle, with: nil)
        }
        if User.isInternal(userType: userType) {
            return UIImage(named: "ic_internal", in: bundle, with: nil)
        }
        if User.isCallCenter(userType: userType) {
            return UIImage(named: "pb_call_center", in: bundle, with: nil)
        }
        return nil
    }

    /// A name with its account mark set in front of it, or the plain name when there is none.
    static func nameWithBadge(_ name: String, forPin pin: String?, size: CGFloat, color: UIColor) -> NSAttributedString {
        guard let badge = accountBadge(forPin: pin) else {
            return NSAttributedString(string: name, attributes: [.foregroundColor: color])
        }
        let attachment = NSTextAttachment()
        attachment.image = badge
        attachment.bounds = CGRect(x: 0, y: -4, width: size, height: size)
        let line = NSMutableAttributedString(attachment: attachment)
        line.append(NSAttributedString(string: "  " + name, attributes: [.foregroundColor: color]))
        return line
    }
}

// MARK: - Voice notes

/// The bar that takes over the bottom of a conversation while a voice note is being recorded.
///
/// Holds the recorder as well as the controls, so a conversation only has to say where to put it
/// and what to do with what comes back. Both conversations use the same one - there is no version
/// of this for groups and another for people.
public final class VoiceNoteBar: UIView, AVAudioRecorderDelegate, AVAudioPlayerDelegate {

    /// Thrown away: the recording is deleted and nothing is sent.
    public var onCancel: (() -> Void)?
    /// Finished: the file, and how long it runs.
    public var onSend: ((URL, Int) -> Void)?

    /// Measured off the reference, which is a 3x screen: the panel stands 146pt, its two rows sit
    /// 31pt and 83pt down it, the send button is 40pt across and the pause ring 27pt.
    public static let barHeight: CGFloat = 146

    private let capsule = UIView()
    private let playButton = UIButton(type: .system)
    private let timeLabel = UILabel()
    private let wave = VoiceWaveView()
    private let binButton = UIButton(type: .system)
    private let pauseButton = UIButton(type: .system)
    private let sendButton = UIButton(type: .system)

    private var recorder: AVAudioRecorder?
    private var player: AVAudioPlayer?
    private var meter: Timer?
    /// Each stretch of speech between one pause and the next. Folded into one file whenever the
    /// recording stops, so there is only ever one thing to play and one thing to send.
    private var segments: [URL] = []
    private var recordedSoFar: TimeInterval = 0
    private var isPaused = false
    private(set) public var fileURL: URL?

    private var timeLeading: NSLayoutConstraint!
    private var timeTrailing: NSLayoutConstraint!
    private var waveLeading: NSLayoutConstraint!
    private var waveTrailing: NSLayoutConstraint!
    private var pausedWave: [NSLayoutConstraint] = []

    public override init(frame: CGRect) {
        super.init(frame: frame)
        build()
    }

    required init?(coder: NSCoder) {
        return nil
    }

    private func build() {
        backgroundColor = .clear

        capsule.backgroundColor = UIColor { $0.userInterfaceStyle == .dark ? UIColor(white: 1, alpha: 0.10) : UIColor(white: 0, alpha: 0.06) }
        capsule.layer.cornerRadius = 22
        capsule.isHidden = true

        playButton.setImage(UIImage(systemName: "play.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)), for: .normal)
        playButton.tintColor = .label
        playButton.addTarget(self, action: #selector(tapPlay), for: .touchUpInside)
        playButton.isHidden = true

        timeLabel.text = "0:00"
        timeLabel.font = .monospacedDigitSystemFont(ofSize: 19, weight: .regular)
        timeLabel.textColor = .secondaryLabel
        timeLabel.setContentHuggingPriority(.required, for: .horizontal)

        binButton.setImage(UIImage(systemName: "trash", withConfiguration: UIImage.SymbolConfiguration(pointSize: 24, weight: .light)), for: .normal)
        binButton.tintColor = .secondaryLabel
        binButton.addTarget(self, action: #selector(tapBin), for: .touchUpInside)

        pauseButton.tintColor = .systemRed
        pauseButton.addTarget(self, action: #selector(tapPause), for: .touchUpInside)
        showPauseGlyph()

        let plane = UIImage(named: "Send-(White)", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)
        sendButton.setImage(plane?.withRenderingMode(.alwaysOriginal), for: .normal)
        sendButton.imageView?.contentMode = .scaleAspectFit
        sendButton.backgroundColor = .mainColor
        sendButton.layer.cornerRadius = 20
        sendButton.addTarget(self, action: #selector(tapSend), for: .touchUpInside)

        for view in [capsule, playButton, timeLabel, wave, binButton, pauseButton, sendButton] as [UIView] {
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
        }
        sendSubviewToBack(capsule)

        // Two arrangements of the top row, one per state, swapped rather than rebuilt.
        timeLeading = timeLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20)
        timeTrailing = timeLabel.trailingAnchor.constraint(equalTo: capsule.trailingAnchor, constant: -18)
        waveLeading = wave.leadingAnchor.constraint(equalTo: timeLabel.trailingAnchor, constant: 12)
        waveTrailing = wave.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: VoiceNoteBar.barHeight),

            timeLabel.centerYAnchor.constraint(equalTo: topAnchor, constant: 31),
            timeLeading,

            wave.centerYAnchor.constraint(equalTo: timeLabel.centerYAnchor),
            wave.heightAnchor.constraint(equalToConstant: 30),
            waveLeading,
            waveTrailing,

            capsule.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            capsule.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            capsule.centerYAnchor.constraint(equalTo: timeLabel.centerYAnchor),
            capsule.heightAnchor.constraint(equalToConstant: 44),

            playButton.leadingAnchor.constraint(equalTo: capsule.leadingAnchor, constant: 14),
            playButton.centerYAnchor.constraint(equalTo: capsule.centerYAnchor),
            playButton.widthAnchor.constraint(equalToConstant: 24),

            binButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            binButton.centerYAnchor.constraint(equalTo: topAnchor, constant: 83),
            binButton.widthAnchor.constraint(equalToConstant: 30),
            binButton.heightAnchor.constraint(equalToConstant: 30),

            pauseButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            pauseButton.centerYAnchor.constraint(equalTo: binButton.centerYAnchor),
            pauseButton.widthAnchor.constraint(equalToConstant: 30),
            pauseButton.heightAnchor.constraint(equalToConstant: 30),

            sendButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            sendButton.centerYAnchor.constraint(equalTo: binButton.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 40),
            sendButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    /// A ring while it is listening, the bare microphone once it has stopped - which is how the
    /// reference tells the two states apart at a glance.
    private func showPauseGlyph() {
        // The microphone is drawn lighter than the ring: at the same weight it reads as the
        // heavier of the two, which is the wrong way round for what it is.
        let name = isPaused ? "mic" : "pause.circle"
        let size: CGFloat = isPaused ? 24 : 27
        let weight: UIImage.SymbolWeight = isPaused ? .light : .regular
        pauseButton.setImage(UIImage(systemName: name, withConfiguration: UIImage.SymbolConfiguration(pointSize: size, weight: weight)), for: .normal)
    }

    private func applyLayout(forPaused paused: Bool) {
        capsule.isHidden = !paused
        playButton.isHidden = !paused
        NSLayoutConstraint.deactivate(pausedWave)
        timeLeading.isActive = !paused
        timeTrailing.isActive = paused
        waveLeading.isActive = !paused
        waveTrailing.isActive = !paused
        pausedWave = paused
            ? [wave.leadingAnchor.constraint(equalTo: playButton.trailingAnchor, constant: 12),
               wave.trailingAnchor.constraint(equalTo: timeLabel.leadingAnchor, constant: -12)]
            : []
        NSLayoutConstraint.activate(pausedWave)
        showPauseGlyph()
        layoutIfNeeded()
    }

    // MARK: Recording

    public func begin(completion: @escaping (Bool) -> Void) {
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                guard granted, let self = self, self.start() else {
                    completion(false)
                    return
                }
                completion(true)
            }
        }
    }

    @discardableResult
    private func start() -> Bool {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)
        } catch {
            return false
        }
        let name = "VoiceNote_\(Date().currentTimeMillis())_\(segments.count).m4a"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
        ]
        do {
            let made = try AVAudioRecorder(url: url, settings: settings)
            made.delegate = self
            made.isMeteringEnabled = true
            guard made.record() else {
                return false
            }
            recorder = made
        } catch {
            return false
        }
        isPaused = false
        applyLayout(forPaused: false)
        VoiceNoteBar.tap(.medium)
        meter?.invalidate()
        meter = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.tick()
        }
        return true
    }

    private func tick() {
        guard let recorder = recorder, recorder.isRecording else {
            return
        }
        recorder.updateMeters()
        refreshTime(recordedSoFar + recorder.currentTime)
        // Fix: the height came from the average power on a straight line from -55dB to 0, and
        // both halves of that were wrong. An average over the sampling window irons out exactly
        // the peaks that make a voice look like a voice, and decibels are logarithmic - spread
        // evenly they put ordinary speech in a narrow band near the top, which is why every bar
        // came out much the same height. The peak is what is taken now, and it is turned back
        // into plain amplitude, where a loud syllable really is many times a quiet one.
        let peak = recorder.peakPower(forChannel: 0)
        let amplitude = pow(10, peak / 20)
        // Speech rarely reaches full scale, so it is lifted to fill the height; silence keeps a
        // floor, which is the row of small dots the reference shows between words.
        wave.add(level: CGFloat(min(1, max(0.07, amplitude * 2.6))))
    }

    private func refreshTime(_ seconds: TimeInterval) {
        timeLabel.text = String(format: "%d:%02d", Int(seconds) / 60, Int(seconds) % 60)
    }

    /// Stops, keeps the stretch just recorded, and folds every stretch into one file.
    ///
    /// A recording paused and resumed is several files - m4a cannot be appended to - so they are
    /// joined here. Doing it at each pause rather than at the end means there is always exactly
    /// one file to play, and playing is the whole reason a pause has a play button on it.
    private func stopAndGather(completion: @escaping () -> Void) {
        meter?.invalidate()
        meter = nil
        if let recorder = recorder {
            recordedSoFar += recorder.currentTime
            recorder.stop()
            segments.append(recorder.url)
        }
        recorder = nil
        guard segments.count > 1 else {
            fileURL = segments.first
            completion()
            return
        }
        VoiceNoteBar.join(segments) { [weak self] joined in
            guard let self = self else {
                return
            }
            if let joined = joined {
                self.segments.forEach { try? FileManager.default.removeItem(at: $0) }
                self.segments = [joined]
            }
            self.fileURL = self.segments.first
            completion()
        }
    }

    /// Lays the stretches end to end into one file.
    private static func join(_ parts: [URL], completion: @escaping (URL?) -> Void) {
        let composition = AVMutableComposition()
        guard let track = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            completion(nil)
            return
        }
        var at = CMTime.zero
        for part in parts {
            let asset = AVURLAsset(url: part)
            guard let source = asset.tracks(withMediaType: .audio).first else {
                continue
            }
            try? track.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration), of: source, at: at)
            at = CMTimeAdd(at, asset.duration)
        }
        let output = FileManager.default.temporaryDirectory
            .appendingPathComponent("VoiceNote_\(Date().currentTimeMillis()).m4a")
        guard let export = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A) else {
            completion(nil)
            return
        }
        export.outputURL = output
        export.outputFileType = .m4a
        export.exportAsynchronously {
            DispatchQueue.main.async {
                completion(export.status == .completed ? output : nil)
            }
        }
    }

    // MARK: What the buttons do

    @objc private func tapPause() {
        VoiceNoteBar.tap(.rigid)
        guard !isPaused else {
            player?.stop()
            player = nil
            wave.mark(progress: nil)
            wave.showWholeRecording(false)
            start()
            return
        }
        isPaused = true
        applyLayout(forPaused: true)
        wave.showWholeRecording(true)
        stopAndGather { [weak self] in
            self?.refreshTime(self?.recordedSoFar ?? 0)
        }
    }

    @objc private func tapPlay() {
        guard let url = fileURL else {
            return
        }
        if let playing = player, playing.isPlaying {
            playing.pause()
            showPlayGlyph(playing: false)
            return
        }
        do {
            let made = try player ?? AVAudioPlayer(contentsOf: url)
            made.delegate = self
            player = made
            made.play()
        } catch {
            return
        }
        showPlayGlyph(playing: true)
        meter?.invalidate()
        meter = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.player else {
                return
            }
            self.refreshTime(player.currentTime)
            self.wave.mark(progress: CGFloat(player.currentTime / max(player.duration, 0.01)))
        }
    }

    private func showPlayGlyph(playing: Bool) {
        let name = playing ? "pause.fill" : "play.fill"
        playButton.setImage(UIImage(systemName: name, withConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)), for: .normal)
    }

    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        meter?.invalidate()
        meter = nil
        self.player = nil
        wave.mark(progress: nil)
        refreshTime(recordedSoFar)
        showPlayGlyph(playing: false)
    }

    /// A short knock, prepared and fired at once, so every way in and out feels the same.
    static func tap(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    @objc private func tapBin() {
        VoiceNoteBar.tap(.light)
        finish()
        segments.forEach { try? FileManager.default.removeItem(at: $0) }
        segments = []
        fileURL = nil
        onCancel?()
    }

    @objc private func tapSend() {
        VoiceNoteBar.tap(.light)
        player?.stop()
        player = nil
        stopAndGather { [weak self] in
            guard let self = self else {
                return
            }
            let seconds = Int(self.recordedSoFar.rounded())
            self.finish()
            guard let url = self.fileURL, seconds > 0 else {
                self.onCancel?()
                return
            }
            self.onSend?(url, seconds)
        }
    }

    /// Stops everything, so nothing is left running behind a bar that has gone.
    public func finish() {
        meter?.invalidate()
        meter = nil
        player?.stop()
        player = nil
        recorder?.stop()
        recorder = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}

/// The line that moves while somebody is speaking.
public final class VoiceWaveView: UIView {

    /// What is on screen while recording - a rolling window, only as much as fits.
    private var levels: [CGFloat] = []
    /// Every reading taken, kept whole. The preview shown when the recording is paused is the
    /// whole of it, not the last few seconds that happened to still be on screen.
    private var recorded: [CGFloat] = []
    private var showsWhole = false
    private let barWidth: CGFloat = 3
    private let gap: CGFloat = 2

    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
    }

    required init?(coder: NSCoder) {
        return nil
    }

    public func reset() {
        levels.removeAll()
        recorded.removeAll()
        showsWhole = false
        played = nil
        setNeedsDisplay()
    }

    /// Whether to draw the whole recording rather than the tail of it.
    public func showWholeRecording(_ on: Bool) {
        showsWhole = on
        setNeedsDisplay()
    }

    public func add(level: CGFloat) {
        recorded.append(level)
        levels.append(level)
        // Only what fits is kept: the line scrolls rather than squeezing more in.
        let room = Int(bounds.width / (barWidth + gap)) + 1
        if levels.count > room {
            levels.removeFirst(levels.count - room)
        }
        setNeedsDisplay()
    }

    /// How far through the recording has been played, or nothing when it is not being played.
    /// What has been heard is drawn solid, what has not is faded - and the dot sits between them.
    public func mark(progress: CGFloat?) {
        played = progress
        setNeedsDisplay()
    }

    private var played: CGFloat?

    /// The whole recording squeezed into the bars there is room for.
    ///
    /// Each bar takes the loudest reading of the stretch it stands for, not the average of it.
    /// Averaging is what flattens a voice into a straight line - the same mistake the meter itself
    /// used to make - and the peaks are exactly what makes speech look like speech.
    private func fitted(_ all: [CGFloat]) -> [CGFloat] {
        let slots = max(1, Int(bounds.width / (barWidth + gap)))
        guard all.count > slots else {
            return all
        }
        let per = Double(all.count) / Double(slots)
        return (0..<slots).map { slot in
            let from = Int(Double(slot) * per)
            let to = min(all.count, max(from + 1, Int(Double(slot + 1) * per)))
            return all[from..<to].max() ?? 0
        }
    }

    public override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        // While recording the line is drawn from the right, so it runs in as it is spoken. Once
        // the recording is paused the whole of it is on show, from the left.
        let drawn = showsWhole ? fitted(recorded) : levels
        guard !drawn.isEmpty else {
            return
        }
        let span = CGFloat(drawn.count) * (barWidth + gap)
        var x = showsWhole ? 0 : max(0, bounds.width - span)
        let step = barWidth + gap
        let edge = played.map { bounds.width * $0 }
        for level in drawn {
            let height = max(2, level * bounds.height)
            let bar = CGRect(x: x, y: (bounds.height - height) / 2, width: barWidth, height: height)
            let heard = edge.map { x <= $0 } ?? true
            context.setFillColor(UIColor.secondaryLabel.withAlphaComponent(heard ? 0.75 : 0.3).cgColor)
            context.addPath(UIBezierPath(roundedRect: bar, cornerRadius: barWidth / 2).cgPath)
            context.fillPath()
            x += step
        }
        guard let edge = edge else {
            return
        }
        // The dot the reference puts at the point that has been reached.
        context.setFillColor(UIColor.mainColor.cgColor)
        let dot = CGRect(x: edge - 5, y: bounds.midY - 5, width: 10, height: 10)
        context.addEllipse(in: dot)
        context.fillPath()
    }
}

/// The line a voice note is drawn as, once it has been sent.
///
/// Told how loud each stretch of the recording was and how far through it has been played; what
/// has been heard is drawn solid, the rest faded.
public final class AudioWaveformView: UIView {

    public var levels: [CGFloat] = [] {
        didSet { setNeedsDisplay() }
    }
    public var progress: CGFloat = 0 {
        didSet { setNeedsDisplay() }
    }
    public var playedColor: UIColor = .white
    public var restColor: UIColor = UIColor(white: 1, alpha: 0.45)

    private let barWidth: CGFloat = 3
    private let gap: CGFloat = 2

    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
        isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) {
        return nil
    }

    public override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext(), !levels.isEmpty, bounds.width > 0 else {
            return
        }
        let slots = max(1, Int(bounds.width / (barWidth + gap)))
        let drawn = AudioWaveformView.fit(levels, into: slots)
        let edge = bounds.width * max(0, min(1, progress))
        var x: CGFloat = 0
        for level in drawn {
            let height = max(2, level * bounds.height)
            let bar = CGRect(x: x, y: (bounds.height - height) / 2, width: barWidth, height: height)
            context.setFillColor((x <= edge ? playedColor : restColor).cgColor)
            context.addPath(UIBezierPath(roundedRect: bar, cornerRadius: barWidth / 2).cgPath)
            context.fillPath()
            x += barWidth + gap
        }
    }

    /// The loudest reading of each stretch, never the average - averaging is what turns a voice
    /// into a straight line.
    static func fit(_ all: [CGFloat], into slots: Int) -> [CGFloat] {
        guard all.count > slots, slots > 0 else {
            return all
        }
        let per = Double(all.count) / Double(slots)
        return (0..<slots).map { slot in
            let from = Int(Double(slot) * per)
            let to = min(all.count, max(from + 1, Int(Double(slot + 1) * per)))
            return all[from..<to].max() ?? 0
        }
    }
}

/// Works out what a recording looks like, once per file.
///
/// Reading a whole audio file is not something a bubble can do while it is being drawn, and a
/// conversation draws the same bubble many times over as it scrolls - so it is read away from the
/// main thread, and the answer is kept.
/// How long each recording runs, so the conversation list can say so without opening the file
/// again for every row it draws.
public enum AudioDurationStore {

    private static var known: [String: Int] = [:]

    /// The length of a recording in whole seconds, or nil while the file is not on this device -
    /// in which case the list simply says less rather than guessing. Reading the length of a local
    /// m4a only parses its header, and each file is read at most once.
    public static func seconds(forFileNamed name: String) -> Int? {
        guard !name.isEmpty else {
            return nil
        }
        if let already = known[name] {
            return already
        }
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        // The bubble writes a decrypted copy into Caches under the same name, so a file held only
        // in secure storage is still readable here without decrypting it a second time.
        let candidates = [documents.appendingPathComponent(name),
                          caches.appendingPathComponent(name),
                          caches.appendingPathComponent(name.replacingOccurrences(of: ".aac", with: ".m4a"))]
        guard let url = candidates.first(where: { FileManager.default.fileExists(atPath: $0.path) }) else {
            return nil
        }
        let found = Int(CMTimeGetSeconds(AVURLAsset(url: url).duration).rounded())
        guard found > 0 else {
            return nil
        }
        known[name] = found
        return found
    }
}

/// How long each video runs, worked out from the file when the database does not know yet.
///
/// The length never travels with a message, and until now it was only ever written down when
/// somebody opened the video - so a clip that had not been watched had no length under it. That
/// showed up most on anything arriving from the share sheet, which is watched least often, but it
/// was true of every video. Anything with the file on this device can answer the question itself.
public enum VideoDurationStore {

    private static var known: [String: Int] = [:]
    private static var asking: Set<String> = []
    private static var waiting: [String: [(Int) -> Void]] = [:]
    /// Files already looked for and not found - so a video still downloading is not searched for
    /// again on every pass of every row.
    private static var absent: Set<String> = []
    private static let queue = DispatchQueue(label: "nexilis.videolength", qos: .utility)

    public static func seconds(forFileNamed name: String) -> Int? {
        return known[name]
    }

    /// Answers on the main thread, and writes what it finds into the message so the question is
    /// only ever asked once per file.
    public static func read(fileNamed name: String, messageId: String, completion: @escaping (Int) -> Void) {
        guard !name.isEmpty else {
            return
        }
        if let already = known[name] {
            completion(already)
            return
        }
        guard !absent.contains(name) else {
            return
        }
        waiting[name, default: []].append(completion)
        guard !asking.contains(name) else {
            return
        }
        asking.insert(name)
        queue.async {
            let found = measure(fileNamed: name)
            DispatchQueue.main.async {
                asking.remove(name)
                let callers = waiting.removeValue(forKey: name) ?? []
                guard found > 0 else {
                    absent.insert(name)
                    return
                }
                known[name] = found
                MediaViewerViewController.rememberVideoDuration(seconds: found, messageId: messageId)
                callers.forEach { $0(found) }
            }
        }
    }

    /// Only the plain file is read. One kept in the secure store would have to be decrypted whole
    /// to be asked, and that is not work a scrolling conversation should start; it gets its length
    /// the first time it is opened, as before.
    private static func measure(fileNamed name: String) -> Int {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let candidates = [documents.appendingPathComponent(name), caches.appendingPathComponent(name)]
        guard let url = candidates.first(where: { FileManager.default.fileExists(atPath: $0.path) }) else {
            return 0
        }
        let seconds = CMTimeGetSeconds(AVURLAsset(url: url).duration)
        guard seconds.isFinite, seconds > 0 else {
            return 0
        }
        return Int(seconds.rounded())
    }
}

/// The "Preparing 1 of 3..." card, with how far along it is and a way out of it.
///
/// Put in a window of its own rather than presented: what follows it is itself a presentation - the
/// attachment preview - and two modals taking turns is how a screen ends up presenting nothing at
/// all. A window can simply be taken away at the moment the next thing goes up.
public enum PreparingOverlay {

    private static var host: UIWindow?
    private static var titleLabel: UILabel?
    private static var bar: UIProgressView?
    private static var onCancel: (() -> Void)?

    public static var isShowing: Bool {
        return host != nil
    }

    public static func show(title: String, onCancel cancel: @escaping () -> Void) {
        hide()
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive })
            ?? UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first else {
            return
        }
        onCancel = cancel

        let window = UIWindow(windowScene: scene)
        window.windowLevel = .alert + 1
        window.backgroundColor = UIColor(white: 0, alpha: 0.4)
        let root = UIViewController()
        root.view.backgroundColor = .clear
        window.rootViewController = root
        window.isHidden = false
        host = window

        let card = UIView()
        card.backgroundColor = .tertiarySystemBackground
        card.layer.cornerRadius = 14
        card.clipsToBounds = true
        root.view.addSubview(card)
        card.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = title
        label.textColor = .label
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        card.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        titleLabel = label

        let progress = UIProgressView(progressViewStyle: .default)
        progress.progressTintColor = .systemBlue
        progress.trackTintColor = UIColor.systemGray.withAlphaComponent(0.5)
        progress.layer.cornerRadius = 2
        progress.clipsToBounds = true
        progress.setProgress(0, animated: false)
        card.addSubview(progress)
        progress.translatesAutoresizingMaskIntoConstraints = false
        bar = progress

        let separator = UIView()
        separator.backgroundColor = .separator
        card.addSubview(separator)
        separator.translatesAutoresizingMaskIntoConstraints = false

        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle("Cancel".localized(), for: .normal)
        cancelButton.setTitleColor(.systemRed, for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 17)
        cancelButton.addTarget(self, action: #selector(Trampoline.cancelTapped), for: .touchUpInside)
        card.addSubview(cancelButton)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            card.centerXAnchor.constraint(equalTo: root.view.centerXAnchor),
            card.centerYAnchor.constraint(equalTo: root.view.centerYAnchor),
            card.widthAnchor.constraint(equalToConstant: 270),

            label.topAnchor.constraint(equalTo: card.topAnchor, constant: 22),
            label.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),

            progress.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 22),
            progress.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 22),
            progress.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -22),
            progress.heightAnchor.constraint(equalToConstant: 4),

            separator.topAnchor.constraint(equalTo: progress.bottomAnchor, constant: 22),
            separator.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            separator.heightAnchor.constraint(equalToConstant: 0.5),

            cancelButton.topAnchor.constraint(equalTo: separator.bottomAnchor),
            cancelButton.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            cancelButton.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            cancelButton.heightAnchor.constraint(equalToConstant: 48),
            cancelButton.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])
    }

    public static func update(title: String? = nil, fraction: Double) {
        DispatchQueue.main.async {
            if let title = title {
                titleLabel?.text = title
            }
            bar?.setProgress(Float(min(max(fraction, 0), 1)), animated: true)
        }
    }

    public static func hide(completion: (() -> Void)? = nil) {
        let takeDown = {
            host?.isHidden = true
            host?.rootViewController = nil
            host = nil
            titleLabel = nil
            bar = nil
            onCancel = nil
            completion?()
        }
        if Thread.isMainThread {
            takeDown()
        } else {
            DispatchQueue.main.async(execute: takeDown)
        }
    }

    /// A button needs an object to send to, and this is an enum.
    private final class Trampoline: NSObject {
        @objc static func cancelTapped() {
            let cancel = PreparingOverlay.onCancel
            PreparingOverlay.hide()
            cancel?()
        }
    }
}

/// The inside of an audio bubble: the picture or the disc, the microphone in its corner, the speed
/// button that trades places with them, the play button, the line and the length.
///
/// Built once, here, because it is drawn in more than one place - the conversation and the message
/// info screen - and the two had drifted into showing the same voice note as two different things.
/// Whoever puts it in a bubble decides only where its edges go; everything inside is settled here.
public final class AudioBubbleContent: UIView {

    public let avatarBox = UIView()
    public let picture = UIImageView()
    public let micBadge = UIImageView()
    public let speedPill = UIButton(type: .system)
    public let playButton = UIButton(type: .system)
    public let slider = UISlider()
    public let wave = AudioWaveformView()
    public let timeLabel = UILabel()
    public let isVoiceNote: Bool
    /// How long the line under a note runs. Fixed, as the reference has it: a five-second note and
    /// a five-minute one are the same width, and only the drawing inside them differs.
    public static let trackWidth: CGFloat = 132

    public init(incoming: Bool, isVoiceNote: Bool, bubbleColour: UIColor, traits: UITraitCollection, fontOffset: CGFloat) {
        self.isVoiceNote = isVoiceNote
        super.init(frame: .zero)
        backgroundColor = .clear
        // The picture stands 44pt and would otherwise sit hard against the top and bottom of the
        // bubble. A floor under the row gives it somewhere to breathe.
        heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true

        // The sender's own picture rather than a music note - a voice note is somebody talking, and
        // the reference says whose before it says anything else. The picture and the speed button
        // share this one slot, so a box holds the picture and the two are swapped in and out of it;
        // nothing else in the row moves when they change places. A note somebody else sent is laid
        // out the other way round - their picture on the far side, so the two sides of the
        // conversation mirror each other rather than both leading with a face.
        addSubview(avatarBox)
        if incoming {
            avatarBox.anchor(centerY: centerYAnchor, width: 44, height: 44)
        } else {
            avatarBox.anchor(left: leftAnchor, centerY: centerYAnchor, width: 44, height: 44)
        }

        picture.clipsToBounds = true
        picture.layer.cornerRadius = 22
        avatarBox.addSubview(picture)
        picture.anchor(top: avatarBox.topAnchor, left: avatarBox.leftAnchor, bottom: avatarBox.bottomAnchor, right: avatarBox.rightAnchor)
        if isVoiceNote {
            picture.contentMode = .scaleAspectFill
            picture.backgroundColor = .tertiarySystemFill
            picture.image = UIImage(systemName: "person.crop.circle.fill")
            picture.tintColor = .lightGray
        } else {
            // Measured off the reference: the same 44pt circle the picture fills, in a muted red,
            // with the note centred in it rather than stretched to the edges.
            picture.contentMode = .center
            picture.backgroundColor = UIColor(red: 228 / 255, green: 132 / 255, blue: 130 / 255, alpha: 1)
            picture.image = UIImage(systemName: "music.note", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .medium))
            picture.tintColor = .white
        }

        // The little microphone the reference tucks into the corner of the picture. Outlined in the
        // bubble's own colour rather than seated in a disc of it: the shadow is cast from the glyph,
        // so what it draws is a border following the microphone instead of a circle around it -
        // the same sense of belonging to the bubble, without covering the picture.
        micBadge.image = UIImage(systemName: "mic.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .regular))
        micBadge.tintColor = incoming ? .mainColor : .gray
        micBadge.contentMode = .scaleAspectFit
        // Only a voice note has one: a file is not somebody speaking.
        micBadge.isHidden = !isVoiceNote
        micBadge.layer.shadowColor = bubbleColour.cgColor
        micBadge.layer.shadowOpacity = 1
        micBadge.layer.shadowRadius = 2.5
        micBadge.layer.shadowOffset = .zero
        micBadge.layer.masksToBounds = false
        avatarBox.addSubview(micBadge)
        micBadge.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            incoming
                ? micBadge.leadingAnchor.constraint(equalTo: picture.leadingAnchor, constant: -2)
                : micBadge.trailingAnchor.constraint(equalTo: picture.trailingAnchor, constant: 2),
            micBadge.bottomAnchor.constraint(equalTo: picture.bottomAnchor, constant: 2),
            micBadge.widthAnchor.constraint(equalToConstant: 18),
            micBadge.heightAnchor.constraint(equalToConstant: 18)
        ])

        // The speed button that takes the picture's place while the note is being listened to.
        // Measured off the reference: 42x24, fully rounded. Dark on a dark bubble and light on a
        // light one, worked out from the bubble's own brightness, so the figure stays legible
        // whichever side of the conversation the note is on.
        var bubbleWhite: CGFloat = 1
        bubbleColour.resolvedColor(with: traits).getWhite(&bubbleWhite, alpha: nil)
        let onDarkBubble = bubbleWhite < 0.6
        speedPill.backgroundColor = UIColor.black.withAlphaComponent(onDarkBubble ? 0.4 : 0.12)
        speedPill.setTitleColor(onDarkBubble ? .white : .darkGray, for: .normal)
        // Not systemFont(weight: .semibold): the app remaps that weight onto a bold italic face,
        // and the figure would lean.
        speedPill.titleLabel?.font = .boldSystemFont(ofSize: 12 + fontOffset)
        speedPill.layer.cornerRadius = 12
        speedPill.isHidden = true
        addSubview(speedPill)
        if incoming {
            speedPill.anchor(right: rightAnchor, centerY: centerYAnchor, width: 42, height: 24)
        } else {
            speedPill.anchor(left: leftAnchor, centerY: centerYAnchor, width: 42, height: 24)
        }

        playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        playButton.tintColor = .gray
        addSubview(playButton)
        if incoming {
            playButton.anchor(left: leftAnchor, paddingLeft: 12, centerY: centerYAnchor, width: 22, height: 22)
        } else {
            playButton.anchor(left: picture.rightAnchor, paddingLeft: 12, centerY: centerYAnchor, width: 22, height: 22)
        }

        slider.minimumValue = 0
        slider.maximumValue = 1
        slider.setThumbImage(UIImage(systemName: "circle.fill")?.withTintColor(UIColor.mainColor)
            .resize(target: CGSize(width: 15, height: 15)), for: .normal)
        wave.playedColor = .mainColor
        wave.restColor = UIColor(white: 0.55, alpha: 0.55)
        if isVoiceNote {
            // The waveform is the track: the slider keeps the thumb and every bit of the seeking it
            // already did, and simply stops drawing a line of its own.
            addSubview(wave)
            wave.anchor(left: playButton.rightAnchor, paddingLeft: 12, centerY: centerYAnchor, width: AudioBubbleContent.trackWidth, height: 26)
            slider.minimumTrackTintColor = .clear
            slider.maximumTrackTintColor = .clear
        } else {
            // With no line behind it the slider draws its own track again, 6pt and fully rounded
            // off the reference, pitched light or dark against the bubble it is on.
            slider.setMinimumTrackImage(Utils.sliderTrack(colour: onDarkBubble ? UIColor(white: 1, alpha: 0.75) : .mainColor), for: .normal)
            slider.setMaximumTrackImage(Utils.sliderTrack(colour: onDarkBubble ? UIColor(white: 1, alpha: 0.18) : UIColor(white: 0, alpha: 0.15)), for: .normal)
        }
        addSubview(slider)
        slider.anchor(left: playButton.rightAnchor, paddingLeft: 12, centerY: centerYAnchor, width: AudioBubbleContent.trackWidth, height: 26)
        // Fix: the line used to be pinned to both ends of the row, which gave the row no width of
        // its own at all - so how wide the bubble came out was decided by the message label behind
        // it, which is hidden and has nothing to do with the audio. Two screens showing the same
        // note therefore came out at two different widths. The track is a known length, and the row
        // ends where its last piece ends, so the bubble hugs it and only it.
        if incoming {
            avatarBox.leadingAnchor.constraint(equalTo: slider.trailingAnchor, constant: 12).isActive = true
            avatarBox.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        } else {
            trailingAnchor.constraint(equalTo: slider.trailingAnchor).isActive = true
        }

        timeLabel.text = "0:00"
        timeLabel.font = .systemFont(ofSize: 10 + fontOffset)
        timeLabel.textColor = .gray
        addSubview(timeLabel)
        timeLabel.anchor(top: slider.bottomAnchor, left: slider.leftAnchor, paddingTop: 4, width: 100, height: 12)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// The sender's picture, once it is known which sender that is.
    public func setPicture(named thumb: String) {
        guard isVoiceNote, !thumb.isEmpty else {
            return
        }
        picture.setImage(name: thumb)
    }
}

/// The filmstrip with a handle at each end, for choosing which part of a video is sent.
public final class VideoTrimStrip: UIView {

    private let frames = UIStackView()
    private let leftHandle = UIView()
    private let rightHandle = UIView()
    private let leftShade = UIView()
    private let rightShade = UIView()
    private let border = UIView()

    private let playhead = UIView()
    private let playheadBar = UIView()
    private let playheadKnob = UIView()
    public static let playheadGrab: CGFloat = 36
    private static let playheadBarWidth: CGFloat = 5
    private static let playheadKnobSize: CGFloat = 14

    /// The stretch the frames occupy, which is the whole of the video from end to end.
    private var contentSpan: (from: CGFloat, width: CGFloat) {
        let inset = VideoTrimStrip.handleWidth
        return (inset, max(0, bounds.width - inset * 2))
    }

    private func place(_ fraction: CGFloat) -> CGFloat {
        let span = contentSpan
        return span.from + fraction * span.width
    }

    private func fraction(at x: CGFloat) -> CGFloat {
        let span = contentSpan
        guard span.width > 0 else {
            return 0
        }
        return min(max((x - span.from) / span.width, 0), 1)
    }

    /// The marker may stand anywhere within the kept part, ends included - the handles are beside
    /// the frames rather than over them, so there is nothing for it to hide behind.
    private var playBounds: (CGFloat, CGFloat) {
        return (leftFraction, rightFraction)
    }
    private var leftFraction: CGFloat = 0
    private var rightFraction: CGFloat = 1
    private var playFraction: CGFloat = 0
    /// How long the whole video runs, so a shortest-allowed length in seconds can be turned into
    /// the fraction of the strip that it occupies.
    private var duration: Double = 0
    /// Nothing shorter than this may be kept - a video trimmed away to nothing is not something to
    /// send, and a fraction of a second is not something anybody meant to choose.
    public static let shortestKept: Double = 1
    /// Told the new ends whenever a handle is let go, as fractions of the whole.
    public var onChange: ((Double, Double) -> Void)?
    /// Told where the playhead has been dragged to, as it moves.
    public var onScrub: ((Double) -> Void)?
    /// Told once the finger comes off, which is when playing starts from there.
    public var onScrubEnded: ((Double) -> Void)?

    public static let handleWidth: CGFloat = 18

    public override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
        layer.cornerRadius = 4
        backgroundColor = UIColor(white: 0.1, alpha: 1)

        frames.axis = .horizontal
        frames.distribution = .fillEqually
        frames.spacing = 0
        addSubview(frames)
        frames.translatesAutoresizingMaskIntoConstraints = false
        // Fix: the frames ran the whole width while the marker could only reach between the
        // handles - so the marker sat at its right-hand limit while the video still had a stretch
        // to run, and the two read as disagreeing. The handles stand outside the frames now, and
        // the frames occupy exactly the span the marker can travel: where the marker is on the
        // strip is where the video is.
        NSLayoutConstraint.activate([
            frames.topAnchor.constraint(equalTo: topAnchor),
            frames.leadingAnchor.constraint(equalTo: leadingAnchor, constant: VideoTrimStrip.handleWidth),
            frames.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -VideoTrimStrip.handleWidth),
            frames.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        // Everything outside the chosen part is dimmed, which is what says where the cut is.
        for shade in [leftShade, rightShade] {
            shade.backgroundColor = UIColor(white: 0, alpha: 0.55)
            shade.isUserInteractionEnabled = false
            addSubview(shade)
        }

        border.layer.borderColor = UIColor.white.cgColor
        border.layer.borderWidth = 2.5
        border.isUserInteractionEnabled = false
        addSubview(border)

        // Fix: this was a thin white bar, and it starts life sitting exactly under the left
        // handle - which is also white. It was not missing, it was invisible. It is given an
        // outline and a knob of its own so it reads against both the filmstrip and the handles,
        // and the part that takes the drag is made wide enough to actually catch a finger while
        // the bar itself stays thin.
        playhead.backgroundColor = .clear
        addSubview(playhead)
        playhead.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(playheadDragged(_:))))

        playheadBar.backgroundColor = .white
        playheadBar.layer.borderColor = UIColor.black.withAlphaComponent(0.65).cgColor
        playheadBar.layer.borderWidth = 1
        playheadBar.isUserInteractionEnabled = false
        playhead.addSubview(playheadBar)

        playheadKnob.backgroundColor = .white
        playheadKnob.layer.borderColor = UIColor.black.withAlphaComponent(0.65).cgColor
        playheadKnob.layer.borderWidth = 1
        playheadKnob.layer.cornerRadius = VideoTrimStrip.playheadKnobSize / 2
        playheadKnob.isUserInteractionEnabled = false
        playhead.addSubview(playheadKnob)

        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(strippedTapped(_:))))

        for (handle, symbol) in [(leftHandle, "chevron.left"), (rightHandle, "chevron.right")] {
            handle.backgroundColor = .white
            addSubview(handle)
            let chevron = UIImageView(image: UIImage(systemName: symbol, withConfiguration: UIImage.SymbolConfiguration(pointSize: 11, weight: .bold)))
            chevron.tintColor = .black
            chevron.contentMode = .center
            handle.addSubview(chevron)
            chevron.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                chevron.centerXAnchor.constraint(equalTo: handle.centerXAnchor),
                chevron.centerYAnchor.constraint(equalTo: handle.centerYAnchor)
            ])
            handle.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handleDragged(_:))))
        }
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        positionHandles()
    }

    public func show(frames images: [UIImage], start: Double, end: Double, duration: Double) {
        frames.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for image in images {
            let view = UIImageView(image: image)
            view.contentMode = .scaleAspectFill
            view.clipsToBounds = true
            frames.addArrangedSubview(view)
        }
        guard duration > 0 else {
            return
        }
        self.duration = duration
        leftFraction = CGFloat(start / duration)
        rightFraction = CGFloat((end > 0 ? end : duration) / duration)
        playFraction = leftFraction
        positionHandles()
    }

    private func positionHandles() {
        guard bounds.width > 0 else {
            return
        }
        let side = VideoTrimStrip.handleWidth
        let span = contentSpan
        let left = place(leftFraction)
        let right = place(rightFraction)
        // Beside the kept part rather than over it, so neither the frames nor the marker are ever
        // covered by a handle.
        leftHandle.frame = CGRect(x: left - side, y: 0, width: side, height: bounds.height)
        rightHandle.frame = CGRect(x: right, y: 0, width: side, height: bounds.height)
        leftShade.frame = CGRect(x: span.from, y: 0, width: max(0, left - span.from), height: bounds.height)
        rightShade.frame = CGRect(x: right, y: 0, width: max(0, span.from + span.width - right), height: bounds.height)
        border.frame = CGRect(x: left, y: 0, width: max(0, right - left), height: bounds.height)
        let allowed = playBounds
        playFraction = min(max(allowed.0, playFraction), allowed.1)
        let at = place(playFraction)
        playhead.frame = CGRect(x: at - VideoTrimStrip.playheadGrab / 2, y: 0,
                                width: VideoTrimStrip.playheadGrab, height: bounds.height)
        playheadBar.frame = CGRect(x: (VideoTrimStrip.playheadGrab - VideoTrimStrip.playheadBarWidth) / 2, y: 0,
                                   width: VideoTrimStrip.playheadBarWidth, height: bounds.height)
        playheadKnob.frame = CGRect(x: (VideoTrimStrip.playheadGrab - VideoTrimStrip.playheadKnobSize) / 2, y: 1,
                                    width: VideoTrimStrip.playheadKnobSize, height: VideoTrimStrip.playheadKnobSize)
        bringSubviewToFront(playhead)
    }

    /// Follows playing, without telling anybody - this is the picture moving, not the reader.
    ///
    /// Fix: this asked for a layout pass rather than moving the marker, and a pass only comes when
    /// something else makes the strip lay out again. Twenty times a second the marker was told
    /// where to be and stayed where it was. It is put there directly.
    public func movePlayhead(to fraction: Double) {
        playFraction = CGFloat(min(max(fraction, 0), 1))
        positionHandles()
    }

    /// A tap anywhere on the part being kept moves the marker there, and the video with it.
    @objc private func strippedTapped(_ gesture: UITapGestureRecognizer) {
        guard bounds.width > 0 else {
            return
        }
        let at = fraction(at: gesture.location(in: self).x)
        // Outside the trim there is nothing to start from, so a tap out there is left alone.
        let allowed = playBounds
        guard at >= leftFraction, at <= rightFraction else {
            return
        }
        playFraction = min(max(allowed.0, at), allowed.1)
        positionHandles()
        onScrub?(Double(playFraction))
        onScrubEnded?(Double(playFraction))
    }

    @objc private func playheadDragged(_ gesture: UIPanGestureRecognizer) {
        guard bounds.width > 0 else {
            return
        }
        let moved = gesture.translation(in: self).x / max(contentSpan.width, 1)
        gesture.setTranslation(.zero, in: self)
        // It belongs between the two ends: there is no sense in starting outside what is being kept.
        let allowed = playBounds
        playFraction = min(max(allowed.0, playFraction + moved), allowed.1)
        setNeedsLayout()
        onScrub?(Double(playFraction))
        if gesture.state == .ended || gesture.state == .cancelled {
            onScrubEnded?(Double(playFraction))
        }
    }

    @objc private func handleDragged(_ gesture: UIPanGestureRecognizer) {
        guard bounds.width > 0, let handle = gesture.view else {
            return
        }
        let moved = gesture.translation(in: self).x / max(contentSpan.width, 1)
        gesture.setTranslation(.zero, in: self)
        // Fix: the two were only kept a couple of handle widths apart, which is a distance on the
        // screen and says nothing about time - on a long video that is several seconds, and on a
        // short one it is a fraction of one, so a video could be trimmed away to nothing. A second
        // is the floor, in seconds, and the handles are kept that far apart on the strip. Anything
        // shorter than a second to begin with cannot be trimmed at all.
        let handWidth = VideoTrimStrip.handleWidth * 2 / max(contentSpan.width, 1)
        let aSecond = duration > 0 ? CGFloat(VideoTrimStrip.shortestKept / duration) : handWidth
        let closest = min(1, max(handWidth, aSecond))
        if handle === leftHandle {
            leftFraction = min(max(0, leftFraction + moved), rightFraction - closest)
        } else {
            rightFraction = max(min(1, rightFraction + moved), leftFraction + closest)
        }
        positionHandles()
        // Reported as it moves, not only when the finger lifts: the length and the size beside it
        // are what the reader is dragging against, and they have to keep up.
        onChange?(Double(leftFraction), Double(rightFraction))
    }
}

/// Re-encodes a video at a lower bitrate while leaving its size alone.
///
/// AVAssetExportSession only offers presets, and a preset settles the resolution and the bitrate
/// together - which is why asking for a smaller file meant accepting a smaller picture. A reader
/// and a writer let the one be lowered without touching the other: the frames go through at the
/// size they were shot at, and only how many bits describe them changes.
public final class VideoTranscoder {

    private var reader: AVAssetReader?
    private var writer: AVAssetWriter?
    private var cancelled = false
    private let queue = DispatchQueue(label: "nexilis.share.transcode")

    /// Roughly a third of what the source runs at, and never more than two megabits - which is
    /// more than enough for something watched on a phone - with a floor so a already-small video
    /// is not made to look worse for nothing.
    public static func targetBitrate(for track: AVAssetTrack) -> Int {
        let source = Double(track.estimatedDataRate)
        let wanted = source > 0 ? source * 0.35 : 1_500_000
        return Int(min(max(wanted, 600_000), 2_000_000))
    }

    public init() {}

    public func cancel() {
        cancelled = true
        reader?.cancelReading()
        writer?.cancelWriting()
    }

    public func start(source: URL,
               destination: URL,
               timeRange: CMTimeRange?,
               muted: Bool,
               progress: @escaping (Double) -> Void,
               completion: @escaping (Bool) -> Void) {
        let asset = AVURLAsset(url: source)
        guard let videoTrack = asset.tracks(withMediaType: .video).first,
              let reader = try? AVAssetReader(asset: asset),
              let writer = try? AVAssetWriter(outputURL: destination, fileType: .mp4) else {
            completion(false)
            return
        }
        self.reader = reader
        self.writer = writer
        let span = timeRange ?? CMTimeRange(start: .zero, duration: asset.duration)
        reader.timeRange = span

        let videoOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
        ])
        videoOutput.alwaysCopiesSampleData = false
        guard reader.canAdd(videoOutput) else {
            completion(false)
            return
        }
        reader.add(videoOutput)

        // The size the frames actually are, which is not the same as naturalSize once the camera's
        // own rotation is taken into account.
        let carried = videoTrack.naturalSize.applying(videoTrack.preferredTransform)
        let width = abs(carried.width).rounded()
        let height = abs(carried.height).rounded()
        let videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: VideoTranscoder.targetBitrate(for: videoTrack),
                AVVideoMaxKeyFrameIntervalKey: 60,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
            ]
        ])
        videoInput.expectsMediaDataInRealTime = false
        videoInput.transform = videoTrack.preferredTransform
        guard writer.canAdd(videoInput) else {
            completion(false)
            return
        }
        writer.add(videoInput)

        var audioOutput: AVAssetReaderTrackOutput?
        var audioInput: AVAssetWriterInput?
        if !muted, let audioTrack = asset.tracks(withMediaType: .audio).first {
            let output = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: [
                AVFormatIDKey: kAudioFormatLinearPCM
            ])
            let input = AVAssetWriterInput(mediaType: .audio, outputSettings: [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVNumberOfChannelsKey: 1,
                AVSampleRateKey: 44100,
                AVEncoderBitRateKey: 64_000
            ])
            input.expectsMediaDataInRealTime = false
            if reader.canAdd(output), writer.canAdd(input) {
                reader.add(output)
                writer.add(input)
                audioOutput = output
                audioInput = input
            }
        }

        // Puts the moov atom at the front, so the receiver can start playing before the whole file
        // has arrived.
        writer.shouldOptimizeForNetworkUse = true
        guard reader.startReading(), writer.startWriting() else {
            completion(false)
            return
        }
        writer.startSession(atSourceTime: span.start)

        let group = DispatchGroup()
        let total = CMTimeGetSeconds(span.duration)
        let started = CMTimeGetSeconds(span.start)

        group.enter()
        videoInput.requestMediaDataWhenReady(on: queue) { [weak self] in
            guard let self = self else {
                return
            }
            while videoInput.isReadyForMoreMediaData {
                guard !self.cancelled, let buffer = videoOutput.copyNextSampleBuffer() else {
                    videoInput.markAsFinished()
                    group.leave()
                    return
                }
                let at = CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(buffer))
                if total > 0 {
                    DispatchQueue.main.async {
                        progress(min(max((at - started) / total, 0), 1))
                    }
                }
                videoInput.append(buffer)
            }
        }

        if let audioInput = audioInput, let audioOutput = audioOutput {
            group.enter()
            audioInput.requestMediaDataWhenReady(on: queue) { [weak self] in
                guard let self = self else {
                    return
                }
                while audioInput.isReadyForMoreMediaData {
                    guard !self.cancelled, let buffer = audioOutput.copyNextSampleBuffer() else {
                        audioInput.markAsFinished()
                        group.leave()
                        return
                    }
                    audioInput.append(buffer)
                }
            }
        }

        group.notify(queue: queue) { [weak self] in
            guard let self = self, !self.cancelled else {
                completion(false)
                return
            }
            writer.finishWriting {
                let ok = writer.status == .completed
                DispatchQueue.main.async {
                    completion(ok)
                }
            }
        }
    }
}

public enum AudioWaveformStore {

    private static var known: [String: [CGFloat]] = [:]
    private static var asking: Set<String> = []
    /// Everyone still waiting on a read that is already running, by file.
    private static var waiting: [String: [([CGFloat]) -> Void]] = [:]
    private static let queue = DispatchQueue(label: "nexilis.waveform", qos: .utility)

    public static func levels(for key: String) -> [CGFloat]? {
        return known[key]
    }

    /// Reads the file if it has not been read, then hands the answer back on the main thread.
    public static func read(url: URL, key: String, completion: @escaping ([CGFloat]) -> Void) {
        if let already = known[key] {
            completion(already)
            return
        }
        // Fix: a second asker arriving while the first read was still running was turned away with
        // nothing - its completion was dropped, and only the first one was ever answered. A bubble
        // rebuilt during the read, which a checkmark landing on a note just sent is enough to do,
        // was left holding a blank line for a view that no longer existed. They queue up now, and
        // all of them are answered.
        waiting[key, default: []].append(completion)
        guard !asking.contains(key) else {
            return
        }
        asking.insert(key)
        queue.async {
            let found = measure(url: url)
            DispatchQueue.main.async {
                asking.remove(key)
                let callers = waiting.removeValue(forKey: key) ?? []
                guard !found.isEmpty else {
                    return
                }
                known[key] = found
                callers.forEach { $0(found) }
            }
        }
    }

    private static func measure(url: URL) -> [CGFloat] {
        let asset = AVURLAsset(url: url)
        guard let track = asset.tracks(withMediaType: .audio).first,
              let reader = try? AVAssetReader(asset: asset) else {
            return []
        }
        let output = AVAssetReaderTrackOutput(track: track, outputSettings: [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsNonInterleaved: false
        ])
        reader.add(output)
        reader.startReading()

        // Enough for any bar the bubble might draw, and no more - a voice note read at full
        // resolution is hundreds of thousands of numbers to hold for nothing.
        let wanted = 200
        var loudest: [CGFloat] = []
        var peak: Int16 = 0
        var counted = 0
        // Roughly how many samples belong to each bar, at the sample rate the file happens to use.
        let rate = track.naturalTimeScale
        let total = max(1, Int(CMTimeGetSeconds(asset.duration) * Double(rate)))
        let per = max(1, total / wanted)

        while reader.status == .reading, let buffer = output.copyNextSampleBuffer() {
            guard let block = CMSampleBufferGetDataBuffer(buffer) else {
                continue
            }
            var length = 0
            var pointer: UnsafeMutablePointer<Int8>?
            CMBlockBufferGetDataPointer(block, atOffset: 0, lengthAtOffsetOut: nil, totalLengthOut: &length, dataPointerOut: &pointer)
            guard let start = pointer else {
                continue
            }
            start.withMemoryRebound(to: Int16.self, capacity: length / 2) { samples in
                for index in 0..<(length / 2) {
                    let value = samples[index].magnitude
                    if Int16(clamping: Int(value)) > peak {
                        peak = Int16(clamping: Int(value))
                    }
                    counted += 1
                    if counted >= per {
                        loudest.append(CGFloat(peak) / CGFloat(Int16.max))
                        peak = 0
                        counted = 0
                    }
                }
            }
            CMSampleBufferInvalidate(buffer)
        }
        guard !loudest.isEmpty else {
            return []
        }
        // Speech rarely reaches full scale, so the whole line is lifted until its loudest moment
        // fills the height - otherwise every voice note looks like a whisper.
        let top = loudest.max() ?? 1
        let lift = top > 0.01 ? min(4, 0.95 / top) : 1
        return loudest.map { min(1, max(0.07, $0 * lift)) }
    }
}
