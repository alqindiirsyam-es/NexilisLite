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
            let textAfterName = chat.messageText.components(separatedBy: "~")[1]
            return (textName + " " + textAfterName.localized()).richText(group_id: chat.pin)
        } else if chat.attachmentFlag == "26" {
            return showNSMutableAttributedString(("📄 " + "Seminar".localized()))
        } else if chat.attachmentFlag == "25" {
            return showNSMutableAttributedString("📄 " + "Video Conference Room".localized())
        } else if !chat.audio.isEmpty {
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
            let dataText = chat.messageText.components(separatedBy: "|")[1]
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
                finalTitleButton = "Call " + title.components(separatedBy: "_")[1]
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

public class SecureUserDefaults {
    public static let shared = SecureUserDefaults()
    private let defaults: UserDefaults

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
    }

    // Retrieve a value
    public func value<T: Codable>(forKey key: String) -> T? {
        guard let encryptedData = defaults.data(forKey: key),
              let decryptedData = try? MasterKeyUtil.shared.decryptP(data: encryptedData) else {
//            print("Failed to decrypt data \(key)")
            return nil
        }
        let decoder = JSONDecoder()
        return try? decoder.decode(T.self, from: decryptedData)
    }

    // Remove a value
    public func removeValue(forKey key: String) {
        defaults.removeObject(forKey: key)
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

class MediaViewerViewController: UIViewController, UIGestureRecognizerDelegate, UIScrollViewDelegate {
    
    enum MediaType {
        case image(UIImage)
        case gif(Data)
        case video(URL)
    }

    var media: MediaType!

    public let backgroundView = UIView()
    public var titleCustom = ""
    public var subtitleCustom = ""
    private let scrollView = UIScrollView()
    private let imageView = SDAnimatedImageView()
    private var statusBarBackgroundView: UIView!
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private let playPauseButton = UIButton(type: .custom)
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
        backgroundView.backgroundColor = .white
        backgroundView.alpha = 0
        backgroundView.frame = view.bounds
        if isSecure {
            secureView.addSubview(backgroundView)
        } else {
            view.addSubview(backgroundView)
        }

        // ScrollView for zooming
        scrollView.frame = view.bounds
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 3.0
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.bouncesZoom = true
        if isSecure {
            secureView.addSubview(scrollView)
        } else {
            view.addSubview(scrollView)
        }

        // Add imageView to scrollView
        imageView.frame = scrollView.bounds
        imageView.contentMode = .scaleAspectFit
        scrollView.addSubview(imageView)

        configureMedia()

        // Tap gesture to toggle navigation bar
        let tap = UITapGestureRecognizer(target: self, action: #selector(toggleNavigationBar))
        tap.numberOfTapsRequired = 1
        view.addGestureRecognizer(tap)

        // Pan gesture for swipe-to-dismiss
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.delegate = self
        view.addGestureRecognizer(panGesture)

        // Status bar background view
        let window = UIApplication.shared.windows.first
        let statusBarHeight = window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 44

        statusBarBackgroundView = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: statusBarHeight))
        statusBarBackgroundView.backgroundColor = .mainColor
        statusBarBackgroundView.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
        view.addSubview(statusBarBackgroundView)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutVideoControls()
        playerLayer?.frame = view.bounds
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
    
    func setNavigationTitle(title: String, subtitle: String) {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 15)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center

        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = UIFont.systemFont(ofSize: 12)
        subtitleLabel.textColor = .secondaryLabel
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

    private func setupVideo(url: URL) {
        player = AVPlayer(url: url)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.frame = scrollView.bounds
        playerLayer?.videoGravity = .resizeAspect
        scrollView.layer.addSublayer(playerLayer!)
        
        // Observe when video finished playing
        NotificationCenter.default.addObserver(self, selector: #selector(videoDidFinish), name: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem)

        // Add play/pause button
        playPauseButton.setImage(UIImage(systemName: "play.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .bold, scale: .default)), for: .normal)
        playPauseButton.tintColor = .white
        playPauseButton.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        playPauseButton.backgroundColor = .black.withAlphaComponent(0.3)
        playPauseButton.center = view.center
        playPauseButton.addTarget(self, action: #selector(togglePlayPause), for: .touchUpInside)
        view.addSubview(playPauseButton)
        playPauseButton.circle()
        
        setupVideoControls()
        
        togglePlayPause()
    }
    
    private func setupVideoControls() {
        
        view.addSubview(blurBackground)

        // Current time
        timeCurrentLabel.text = "0:00"
        timeCurrentLabel.textColor = .white
        timeCurrentLabel.font = .systemFont(ofSize: 13)
        view.addSubview(timeCurrentLabel)

        // Remaining time
        timeRemainingLabel.text = "-0:00"
        timeRemainingLabel.textColor = .white
        timeRemainingLabel.font = .systemFont(ofSize: 13)
        timeRemainingLabel.textAlignment = .right
        view.addSubview(timeRemainingLabel)

        // Playback speed button
        speedButton.setTitle("1×", for: .normal)
        speedButton.tintColor = .white
        speedButton.titleLabel?.font = .boldSystemFont(ofSize: 15)
        speedButton.addTarget(self, action: #selector(toggleSpeed), for: .touchUpInside)
        view.addSubview(speedButton)

        // Slider
        let thumbImg = makeThumb(size: 20)
        slider.setThumbImage(thumbImg, for: .normal)
        slider.setThumbImage(thumbImg, for: .highlighted)
        slider.minimumValue = 0
        slider.maximumValue = 1
        slider.tintColor = .white
        slider.addTarget(self, action: #selector(sliderChanged(_:)), for: .valueChanged)
        view.addSubview(slider)

        layoutVideoControls()

        // Update every 0.2 sec
        addPeriodicTimeObserver()
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

        player.addPeriodicTimeObserver(
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
        let padding: CGFloat = 16
        let labelWidth: CGFloat = 45

        timeCurrentLabel.frame = CGRect(
            x: padding,
            y: view.bounds.height - 50,
            width: labelWidth,
            height: 20
        )

        speedButton.frame = CGRect(
            x: view.bounds.width - padding - 35,
            y: view.bounds.height - 50,
            width: 35,
            height: 20
        )

        timeRemainingLabel.frame = CGRect(
            x: speedButton.frame.minX - labelWidth - 8,
            y: view.bounds.height - 50,
            width: labelWidth,
            height: 20
        )

        slider.frame = CGRect(
            x: timeCurrentLabel.frame.maxX + 8,
            y: view.bounds.height - 50,
            width: timeRemainingLabel.frame.minX - timeCurrentLabel.frame.maxX - 16,
            height: 20
        )
        
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
        guard let player = player else { return }

        if isVideoPlaying {
            player.pause()
            playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        } else {
            prepareForVideoPlayback()
            if let currentItem = player.currentItem,
               currentItem.currentTime() >= currentItem.duration {
                player.seek(to: .zero)
            }
            player.play()
            playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
            DispatchQueue.global().async {
                while self.statusBarBackgroundView == nil {
                    Thread.sleep(forTimeInterval: 0.25)
                }
            }
        }
        isVideoPlaying.toggle()
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
            self.playPauseButton.alpha = self.isNavigationBarHidden ? 0 : 1
            self.timeCurrentLabel.alpha = self.isNavigationBarHidden ? 0 : 1
            self.timeRemainingLabel.alpha = self.isNavigationBarHidden ? 0 : 1
            self.speedButton.alpha = self.isNavigationBarHidden ? 0 : 1
            self.slider.alpha = self.isNavigationBarHidden ? 0 : 1
            self.blurBackground.alpha = self.isNavigationBarHidden ? 0 : 1
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        self.stopVideo()
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard scrollView.zoomScale == 1.0 else { return }

        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view)

        switch gesture.state {
        case .changed:
            let transform = CGAffineTransform(translationX: translation.x, y: translation.y)
            scrollView.transform = transform
            
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
            let distance = hypot(translation.x, translation.y)
            let threshold: CGFloat = 120

            if distance > threshold || abs(velocity.y) > 500 || abs(velocity.x) > 500 {
                // Dismiss if far enough or fast swipe
                self.stopVideo()
                NotificationCenter.default.removeObserver(self)
                dismiss(animated: true, completion: nil)
            } else {
                // Return to center if not far enough
                if isSecure {
                    self.privacyOverlay.isHidden = false
                }
                if isVideoPlaying {
                    isVideoPlaying = false
                    togglePlayPause()
                }
                UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.8, options: [], animations: {
                    self.scrollView.transform = .identity
                    self.backgroundView.alpha = 1.0
                }, completion: nil)
            }
        default:
            break
        }
    }

    // MARK: - UIScrollViewDelegate

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let imageViewSize = imageView.frame.size
        let scrollViewSize = scrollView.bounds.size
        let verticalPadding = imageViewSize.height < scrollViewSize.height ? (scrollViewSize.height - imageViewSize.height) / 2 : 0
        let horizontalPadding = imageViewSize.width < scrollViewSize.width ? (scrollViewSize.width - imageViewSize.width) / 2 : 0
        scrollView.contentInset = UIEdgeInsets(top: verticalPadding, left: horizontalPadding, bottom: verticalPadding, right: horizontalPadding)
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
              let toVC = transitionContext.viewController(forKey: .to),
              let originImageView = originImageView else {
            transitionContext.completeTransition(false)
            return
        }

        let container = transitionContext.containerView
        let imageViewSnapshot = UIImageView(image: originImageView.image)
        imageViewSnapshot.contentMode = .scaleAspectFit
        imageViewSnapshot.clipsToBounds = true
        imageViewSnapshot.frame = container.convert(originImageView.bounds, from: originImageView)

        if isPresenting {
            toVC.view.alpha = 0
            container.addSubview(toVC.view)
            container.addSubview(imageViewSnapshot)

            let finalFrame = toVC.view.frame

            UIView.animate(withDuration: transitionDuration(using: transitionContext),
                           delay: 0,
                           usingSpringWithDamping: 0.85,
                           initialSpringVelocity: 0.6,
                           options: .curveEaseOut, animations: {

                imageViewSnapshot.frame = finalFrame
                toVC.view.alpha = 1

            }) { _ in
                imageViewSnapshot.removeFromSuperview()
                transitionContext.completeTransition(true)
            }

        } else {
            let navVC = fromVC as! UINavigationController
            let fromImageVC = navVC.viewControllers.first as! MediaViewerViewController
            let finalFrame = container.convert(originImageView.bounds, from: originImageView)

            container.addSubview(imageViewSnapshot)
            fromImageVC.view.alpha = 0
            fromImageVC.backgroundView.alpha = 0 // fade background

            UIView.animate(withDuration: transitionDuration(using: transitionContext),
                           delay: 0,
                           usingSpringWithDamping: 0.85,
                           initialSpringVelocity: 0.6,
                           options: .curveEaseOut, animations: {

                imageViewSnapshot.frame = finalFrame

            }) { _ in
                imageViewSnapshot.removeFromSuperview()
                transitionContext.completeTransition(true)
            }
        }
    }
}

class ZoomTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
    var originImageView: UIImageView?

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
            animator.originImageView = originImageView
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
