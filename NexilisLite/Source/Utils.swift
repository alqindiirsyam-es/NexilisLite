//
//  Utils.swift
//  Runner
//
//  Created by Rifqy Fakhrul Rijal on 13/08/20.
//  Copyright © 2020 The Chromium Authors. All rights reserved.
//

import Foundation
import AudioToolbox
import UIKit
import FMDB
import NotificationBannerSwift
import nuSDKService
import CoreLocation
import CryptoKit
import LocalAuthentication
import AVFoundation
import AVKit
import PDFKit
import SDWebImage
import NexilisZTA
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
    
    // Sentinel remediation (NX-11/NX-14): certificate trust is never persisted in mutable
    // application preferences. First-party trust comes only from the configured pin floor and
    // signature-verified rotation envelopes in NexilisZTA.PinSetStore.

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
            // A round video note says what it is and how long it runs, the way a voice note does.
            // Nothing on the message marks one out - it travels as an ordinary video - so the name
            // of the file is what tells them apart. See VideoNote.
            if VideoNote.isNote(chat.video) {
                let camera = NSTextAttachment()
                camera.image = UIImage(systemName: "video.fill")?.withTintColor(.gray, renderingMode: .alwaysOriginal)
                camera.bounds = CGRect(x: 0, y: -2, width: 16, height: 12)
                var text = "Video note".localized()
                let length = VideoNote.duration(ofVideoId: chat.video)
                if length > 0 {
                    text += " (" + VideoNote.clockLength(length) + ")"
                }
                let line = NSMutableAttributedString(attachment: camera)
                line.append(NSAttributedString(string: " " + text, attributes: [
                    .font: UIFont.systemFont(ofSize: 12 + String.offset()),
                    .foregroundColor: UIColor.gray
                ]))
                return line
            }
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
            // Fix: read straight off the front of message_text, so a document that arrived
            // without a name in there left the chat list showing a bare page icon and nothing
            // beside it. The same place the bubble asks knows where else to look.
            let nameFile = Utils.documentName(messageText: chat.messageText, file: chat.file)
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
    
    /// Which envelope the server expects for secure-folder payloads: "1" legacy fixed-IV,
    /// "2" NXG1 random-nonce.
    ///
    /// This exists because the obvious signal - "has the server stopped sending an IV?" - is not
    /// available. `secure_folder_encrypt_key_iv` is also half the SQLCipher password (see
    /// Database.setDBInstance, which keys with `key + keyIv`), so clearing it server-side to move
    /// a host onto NXG1 would take its database with it. The two decisions need two switches.
    ///
    /// Defaults to legacy, so a server that never sends this leaves every host exactly where it
    /// is today.
    public static func setSecureFolderEnvelope(value: String) {
        SecureUserDefaults.shared.set(value, forKey: "secure_folder_envelope")
    }

    public static func getSecureFolderEnvelope() -> String {
        if let value: String = SecureUserDefaults.shared.value(forKey: "secure_folder_envelope") {
            return value
        }
        return "1"
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
        guard SentinelSecurityGate.attachAuthorization(to: &request) else {
            completion(nil, nil, NSError(domain: "NexilisSentinel", code: -7201, userInfo: [NSLocalizedDescriptionKey: "Sentinel authorization is not valid"]))
            return
        }
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
        guard SentinelSecurityGate.attachAuthorization(to: &request) else {
            completion(nil, nil, NSError(domain: "NexilisSentinel", code: -7201, userInfo: [NSLocalizedDescriptionKey: "Sentinel authorization is not valid"]))
            return
        }
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

    /// Duress/tamper wipe: remove both persistent ciphertext and already-decrypted process cache.
    public func clearAllStoredValues() {
        cacheLock.lock()
        cache.removeAll(keepingCapacity: false)
        cacheLock.unlock()
        if let bundleID = Bundle.main.bundleIdentifier {
            defaults.removePersistentDomain(forName: bundleID)
        }
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
    /// Called whenever this page is zoomed or panned.
    ///
    /// A video's player is a layer of the viewer's own, held above the pages rather than inside
    /// one - so it hears nothing about a pinch on the page beneath it. This is how it is told:
    /// the poster is what the page zooms, and the player is put wherever the poster goes.
    var onZoomChanged: (() -> Void)?
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
        onZoomChanged = nil
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
        onZoomChanged?()
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Panning a picture that has been zoomed in moves it under the reader's finger, and a
        // video has to travel with it.
        onZoomChanged?()
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
            (cell as? MediaPageCell)?.onZoomChanged = { [weak self] in
                self?.positionVideoHost()
            }
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

        // Double tap to zoom, the way WhatsApp does it: in on the spot that was tapped, and out
        // again on the next one. The single tap waits for this to fail, so a double tap no
        // longer flickers the chrome on its way to zooming.
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTapZoom(_:)))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.cancelsTouchesInView = false
        doubleTap.delegate = self
        view.addGestureRecognizer(doubleTap)
        tap.require(toFail: doubleTap)

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
        // Fix: the player was placed over the whole page and left there, so a pinch zoomed the
        // page underneath it - the poster - while the video itself stayed exactly where it was.
        // What the reader saw growing was the still behind the video. The player is put on the
        // poster's own rectangle now, so the two are one thing: zoom the page and the video
        // zooms, drag it and the video travels with it.
        guard pager != nil, !stripItems.isEmpty else {
            // Opened on a single item, with no pages to turn: the screen's own scroll view is
            // what zooms, and its picture is what the player follows.
            if imageView.superview != nil {
                setVideoHostFrame(scrollView.convert(imageView.frame, to: view))
            }
            return
        }
        guard videoPageIndex >= 0, pager.bounds.width > 0 else {
            return
        }
        if let cell = pager.cellForItem(at: IndexPath(item: videoPageIndex, section: 0)) as? MediaPageCell {
            setVideoHostFrame(cell.zoomView.convert(cell.imageView.frame, to: view))
            return
        }
        // The page is not built yet - off screen, or mid-swipe. Its own rectangle is still known.
        let x = CGFloat(videoPageIndex) * pager.bounds.width - pager.contentOffset.x
        setVideoHostFrame(CGRect(x: x, y: 0, width: view.bounds.width, height: view.bounds.height))
    }

    /// Whether the picture on screen is zoomed in past its resting size.
    private var isCurrentPageZoomed: Bool {
        if pager != nil, !stripItems.isEmpty,
           let cell = pager.cellForItem(at: IndexPath(item: currentStripIndex, section: 0)) as? MediaPageCell {
            return cell.zoomView.zoomScale > cell.zoomView.minimumZoomScale + 0.01
        }
        return scrollView.zoomScale > scrollView.minimumZoomScale + 0.01
    }

    /// Zooms in on what was double tapped, and back out when it is double tapped again.
    ///
    /// The point matters: zooming to the middle of the screen puts whatever the reader was
    /// pointing at somewhere else entirely. What they tapped is what ends up under their finger.
    @objc private func handleDoubleTapZoom(_ gesture: UITapGestureRecognizer) {
        let zoom: UIScrollView
        let content: UIView
        if pager != nil, !stripItems.isEmpty,
           let cell = pager.cellForItem(at: IndexPath(item: currentStripIndex, section: 0)) as? MediaPageCell {
            zoom = cell.zoomView
            content = cell.imageView
        } else {
            zoom = scrollView
            content = imageView
        }
        guard zoom.isUserInteractionEnabled, zoom.maximumZoomScale > zoom.minimumZoomScale else {
            return
        }
        if zoom.zoomScale > zoom.minimumZoomScale + 0.01 {
            zoom.setZoomScale(zoom.minimumZoomScale, animated: true)
            return
        }
        let point = gesture.location(in: content)
        let scale = zoom.maximumZoomScale
        let size = CGSize(width: zoom.bounds.width / scale, height: zoom.bounds.height / scale)
        zoom.zoom(to: CGRect(x: point.x - size.width / 2,
                             y: point.y - size.height / 2,
                             width: size.width,
                             height: size.height),
                  animated: true)
    }

    private func setVideoHostFrame(_ frame: CGRect) {
        guard frame.width > 0, frame.height > 0 else {
            return
        }
        videoHost.frame = frame
        // No implicit animation: a layer resized inside a pinch would arrive a frame behind the
        // fingers doing the pinching.
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        playerLayer?.frame = videoHost.bounds
        CATransaction.commit()
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
        // Not while the picture is zoomed in: the drag is the reader moving around inside it,
        // and taking the viewer away from under them would be the last thing they asked for.
        if isCurrentPageZoomed {
            return false
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
        // Fix: this put the player back across the whole screen on every layout pass, undoing the
        // placement that keeps it on its own page - and, now, on the poster it is zoomed with.
        positionVideoHost()
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
        positionVideoHost()
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
        // Fix: the button used to be held down for the whole call, minimised or not. Minimised,
        // the app is what the reader is looking at and the button is part of it - there is
        // nothing for it to float over any more, and taking it away for the length of a call is
        // taking away the way around the app. It comes back here and is put away again in
        // restore(), where the call takes the screen back.
        FloatingButton.isSuppressed = false

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
        // The call is taking the screen back, and the button has no business over it.
        FloatingButton.isSuppressed = true
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
        // Whatever route the ending took, nothing is holding the button down any more.
        FloatingButton.isSuppressed = false
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
        // Fix: the button used to be held down for the whole call, minimised or not. Minimised,
        // the app is what the reader is looking at and the button is part of it - there is
        // nothing for it to float over any more, and taking it away for the length of a call is
        // taking away the way around the app. It comes back here and is put away again in
        // restore(), where the call takes the screen back.
        FloatingButton.isSuppressed = false
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
        // The call is taking the screen back, and the button has no business over it.
        FloatingButton.isSuppressed = true
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
        // Whatever route the ending took, nothing is holding the button down any more.
        FloatingButton.isSuppressed = false
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
        /// An SF Symbol in front of the words, where a choice reads better with one. Optional, so
        /// every sheet that already exists carries on without one.
        public let icon: String?
        public let isDestructive: Bool
        public let handler: () -> Void

        public init(title: String, icon: String? = nil, isDestructive: Bool = false, handler: @escaping () -> Void) {
            self.title = title
            self.icon = icon
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
            // The words start clear of the icon when there is one, and where they always did when
            // there is not.
            let textInset: CGFloat = option.icon == nil ? 22 : 60
            button.contentEdgeInsets = UIEdgeInsets(top: 0, left: textInset, bottom: 0, right: 22)
            button.backgroundColor = .tertiarySystemBackground
            button.layer.cornerRadius = 27
            button.tag = index
            button.addTarget(self, action: #selector(tapOption(_:)), for: .touchUpInside)
            button.heightAnchor.constraint(equalToConstant: 54).isActive = true

            if let symbol = option.icon {
                let icon = UIImageView(image: UIImage(systemName: symbol,
                                                      withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .regular)))
                icon.tintColor = option.isDestructive ? .systemRed : .label
                icon.contentMode = .center
                icon.isUserInteractionEnabled = false
                button.addSubview(icon)
                icon.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    icon.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 22),
                    icon.centerYAnchor.constraint(equalTo: button.centerYAnchor),
                    icon.widthAnchor.constraint(equalToConstant: 24)
                ])
            }
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

    /// An arrow and how big it is, on a dark chip in the bottom corner of a picture.
    ///
    /// What the reference shows beside a photograph that has not been fetched: not a promise that
    /// something is happening, but the two facts worth knowing before deciding to fetch it. It
    /// goes away the moment a transfer starts - the disc in the middle speaks for that - and comes
    /// back if the transfer is called off.
    ///
    /// The size is asked for in the cheapest order there is: what a transfer already measured,
    /// then what a previous ask found out, and only then the server itself.
    @discardableResult
    public static func addPendingSize(to host: UIView, fileName: String) -> UIView {
        let chip = UIView()
        chip.backgroundColor = .black.withAlphaComponent(0.45)
        chip.layer.cornerRadius = 9
        chip.clipsToBounds = true
        chip.isUserInteractionEnabled = false
        chip.translatesAutoresizingMaskIntoConstraints = false
        host.addSubview(chip)

        let arrow = UIImageView(image: UIImage(systemName: "arrow.down",
                                               withConfiguration: UIImage.SymbolConfiguration(pointSize: 10, weight: .semibold)))
        arrow.tintColor = .white
        arrow.contentMode = .scaleAspectFit
        arrow.translatesAutoresizingMaskIntoConstraints = false
        chip.addSubview(arrow)

        let size = UILabel()
        size.font = .systemFont(ofSize: 11, weight: .semibold)
        size.textColor = .white
        size.translatesAutoresizingMaskIntoConstraints = false
        chip.addSubview(size)

        NSLayoutConstraint.activate([
            chip.leadingAnchor.constraint(equalTo: host.leadingAnchor, constant: 8),
            chip.bottomAnchor.constraint(equalTo: host.bottomAnchor, constant: -8),
            chip.heightAnchor.constraint(equalToConstant: 20),
            arrow.leadingAnchor.constraint(equalTo: chip.leadingAnchor, constant: 6),
            arrow.centerYAnchor.constraint(equalTo: chip.centerYAnchor),
            arrow.widthAnchor.constraint(equalToConstant: 11),
            size.leadingAnchor.constraint(equalTo: arrow.trailingAnchor, constant: 4),
            size.trailingAnchor.constraint(equalTo: chip.trailingAnchor, constant: -7),
            size.centerYAnchor.constraint(equalTo: chip.centerYAnchor)
        ])

        // The sender's figure, then what a transfer measured, then what a previous ask found out -
        // see Facts.expectedSize. The server itself is the last resort, below.
        let bytes = VideoNote.Facts.expectedSize(ofAttachmentNamed: fileName)
        size.text = bytes > 0 ? VideoNote.Facts.humanSize(bytes) : ""
        // Nothing to say yet: the chip waits rather than showing an arrow with a blank beside it.
        chip.isHidden = bytes == 0
        if bytes == 0 {
            Download.remoteSize(forKey: fileName) { [weak chip, weak size] answer in
                guard answer > 0 else { return }
                size?.text = VideoNote.Facts.humanSize(answer)
                chip?.isHidden = false
            }
        }
        return chip
    }

    /// The pale pill in the middle of a collage that has not been fetched.
    ///
    /// A collage stands for several messages at once, so there is no one corner to put a size in
    /// and no one picture to offer. The reference answers that with a single pill over the middle
    /// of the grid: what it would cost altogether, and how many pictures that is.
    @discardableResult
    public static func addCollageOffer(to host: UIView, files names: [String]) -> UIView {
        let count = names.count
        // The same order as everywhere else, added up: what the sender said, what a transfer
        // measured, what a previous ask found out. Anything still unknown after that is asked of
        // the server below, and the line fills itself in as the answers arrive - a collage is
        // several files, so it can be part known and part not.
        let known = Ledger()
        for name in names {
            known.bytes += VideoNote.Facts.expectedSize(ofAttachmentNamed: name)
        }
        let bytes = known.bytes
        return buildCollageOffer(to: host, bytes: bytes, count: count, unknown: names.filter {
            VideoNote.Facts.expectedSize(ofAttachmentNamed: $0) == 0
        }, ledger: known)
    }

    /// A running total the server's answers can be added to as they come back.
    private final class Ledger {
        var bytes: Int64 = 0
    }

    @discardableResult
    private static func buildCollageOffer(to host: UIView, bytes: Int64, count: Int,
                                          unknown: [String], ledger: Ledger) -> UIView {
        let pill = UIView()
        pill.backgroundColor = UIColor(white: 0.96, alpha: 0.94)
        pill.layer.cornerRadius = 23
        // The tap that fetches these belongs to the pictures underneath; this only says what is
        // there to fetch.
        pill.isUserInteractionEnabled = false
        pill.translatesAutoresizingMaskIntoConstraints = false
        host.addSubview(pill)

        let arrow = UIImageView(image: UIImage(systemName: "arrow.down",
                                               withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .medium)))
        arrow.tintColor = UIColor(white: 0.25, alpha: 1)
        arrow.contentMode = .scaleAspectFit
        arrow.translatesAutoresizingMaskIntoConstraints = false
        pill.addSubview(arrow)

        let size = UILabel()
        size.text = VideoNote.Facts.humanSize(bytes)
        size.font = .systemFont(ofSize: 15, weight: .medium)
        size.textColor = UIColor(white: 0.2, alpha: 1)
        // Fix: the pill hid itself when the size was unknown, which is exactly the case it exists
        // for - a collage nobody has fetched has no measured size, and old messages carry no size
        // from the sender either. So it never appeared at all. The count on its own is still an
        // offer; the size joins it once it is known.
        size.isHidden = bytes <= 0
        for name in unknown {
            Download.remoteSize(forKey: name) { [weak size, weak ledger] answer in
                guard answer > 0, let ledger = ledger else { return }
                ledger.bytes += answer
                size?.text = VideoNote.Facts.humanSize(ledger.bytes)
                size?.isHidden = false
            }
        }

        let items = UILabel()
        items.text = count == 1 ? "1 item".localized() : String(format: "%d items".localized(), count)
        items.font = .systemFont(ofSize: 13)
        items.textColor = UIColor(white: 0.35, alpha: 1)

        let lines = UIStackView(arrangedSubviews: [size, items])
        lines.axis = .vertical
        lines.spacing = 0
        lines.alignment = .center
        lines.translatesAutoresizingMaskIntoConstraints = false
        pill.addSubview(lines)

        NSLayoutConstraint.activate([
            pill.centerXAnchor.constraint(equalTo: host.centerXAnchor),
            pill.centerYAnchor.constraint(equalTo: host.centerYAnchor),
            pill.heightAnchor.constraint(equalToConstant: 46),
            arrow.leadingAnchor.constraint(equalTo: pill.leadingAnchor, constant: 16),
            arrow.centerYAnchor.constraint(equalTo: pill.centerYAnchor),
            arrow.widthAnchor.constraint(equalToConstant: 20),
            lines.leadingAnchor.constraint(equalTo: arrow.trailingAnchor, constant: 10),
            lines.trailingAnchor.constraint(equalTo: pill.trailingAnchor, constant: -18),
            lines.centerYAnchor.constraint(equalTo: pill.centerYAnchor)
        ])
        return pill
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

    /// Why a recording could not be started.
    ///
    /// Fix: this used to answer with a plain true or false, and the screens above it reported
    /// every false as "Microphone access is needed to record". Three quite different things
    /// produce a false - a call holding the microphone, permission actually refused, and the
    /// audio session refusing to go active - so the one message the reader got was right by luck
    /// at best, and there is no console on a device to tell them apart with. Each says what it is.
    public enum StartFailure {
        /// Permission refused, or never granted. The only one Settings can fix.
        case denied
        /// Something else holds the microphone - a call, most likely.
        case busy
        /// The microphone is ours to use and iOS still would not start it.
        case audioSessionRefused
        /// Another app is holding the microphone - a call in WhatsApp, or the phone itself.
        /// Nothing in Settings changes this; the other call has to end.
        case heldByAnotherApp
    }

    public func begin(completion: @escaping (StartFailure?) -> Void) {
        // The last word on the microphone, whoever asked and from where: a call has it.
        if APIS.blockedByCallInProgress() {
            completion(.busy)
            return
        }
        VoiceNoteBar.askMicrophone { [weak self] granted in
            // Back on the main thread here, and only here: the answer arrives on a queue of
            // iOS's own, and everything below it is UI and an audio session.
            DispatchQueue.main.async {
            guard granted else {
                completion(.denied)
                return
            }
            guard let self = self else {
                completion(.audioSessionRefused)
                return
            }
            switch self.start() {
            case .started:
                completion(nil)
            case .heldByAnotherApp:
                completion(.heldByAnotherApp)
            case .refused:
                completion(.audioSessionRefused)
            }
            }
        }
    }

    /// Asks for the microphone, through whichever API this system has.
    ///
    /// AVAudioSession's own request is the one that was here, and it is the one Apple replaced in
    /// iOS 17 - AVAudioApplication owns this now. The older call still works, but the newer one is
    /// what the system is built around, so it is the one asked where there is one.
    /// The answer arrives on whichever queue iOS chooses, and it is left there.
    ///
    /// Fix: this used to hand the answer on with DispatchQueue.main.async, which looks harmless
    /// and is not: Nexilis.checkMicPermission waits on a semaphore for this answer, and it is
    /// called from button handlers on the main thread. Dispatching the answer to a main queue
    /// that is blocked waiting for it is a deadlock - the app freezes for good, on the one path
    /// where the microphone had never been asked for. Whoever needs the main thread now says so
    /// where they need it.
    static func askMicrophone(_ answer: @escaping (Bool) -> Void) {
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission(completionHandler: answer)
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission(answer)
        }
    }

    /// Where the microphone permission stands.
    ///
    /// Its own three answers rather than either framework's, because the type that carries them
    /// belongs to iOS 17 and this app runs on 15 - naming it in a signature would drag the whole
    /// call behind an availability check for no reason.
    enum MicrophoneStatus {
        case granted
        case denied
        case notAsked
    }

    static var microphoneStatus: MicrophoneStatus {
        if #available(iOS 17.0, *) {
            switch AVAudioApplication.shared.recordPermission {
            case .granted: return .granted
            case .denied: return .denied
            default: return .notAsked
            }
        }
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted: return .granted
        case .denied: return .denied
        default: return .notAsked
        }
    }

    /// Whether the microphone has already been refused, so the screen can offer Settings rather
    /// than asking again - a refused permission is never asked for a second time by iOS.
    static var microphoneRefused: Bool {
        return microphoneStatus == .denied
    }

    /// What happened when the microphone was asked for.
    enum Started {
        case started
        /// Another app has the microphone. iOS says which of its refusals this is; see
        /// APIS.isMicrophoneHeldElsewhere.
        case heldByAnotherApp
        case refused
    }

    @discardableResult
    private func start() -> Started {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)
        } catch {
            // Fix: every failure here was one failure, and the screen above reported all of them
            // as a permission problem. A call in another app takes the microphone exclusively and
            // iOS refuses this outright - which is not permission, and is not something Settings
            // can put right. iOS says as much in the error; it was being thrown away.
            return APIS.isMicrophoneHeldElsewhere(error) ? .heldByAnotherApp : .refused
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
                return .refused
            }
            recorder = made
        } catch {
            return APIS.isMicrophoneHeldElsewhere(error) ? .heldByAnotherApp : .refused
        }
        isPaused = false
        applyLayout(forPaused: false)
        VoiceNoteBar.tap(.medium)
        meter?.invalidate()
        meter = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.tick()
        }
        return .started
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
        var found = Int(CMTimeGetSeconds(AVURLAsset(url: url).duration).rounded())
        if found <= 0 {
            // A bare AAC stream from Android, which AVURLAsset will not open at all - see
            // RawAudioLevels. Without this the quote said "Voice Message" with no length after it.
            found = RawAudioLevels.seconds(url: url) ?? 0
        }
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

    /// Whether the line runs to the row's own trailing edge instead of keeping the fixed length.
    ///
    /// A bubble wants the fixed length: a five-second note and a five-minute one are the same
    /// width there, and two screens showing the same note come out the same size. A row in a list
    /// wants the opposite - it has a panel's whole width to fill, and the reference fills it, so
    /// the waveform there runs to the right-hand edge.
    private let stretchesTrack: Bool

    public init(incoming: Bool,
                isVoiceNote: Bool,
                bubbleColour: UIColor,
                traits: UITraitCollection,
                fontOffset: CGFloat,
                stretchesTrack: Bool = false) {
        self.isVoiceNote = isVoiceNote
        // Only for a row laid out the reader's way round: a mirrored one gives its trailing edge
        // to the sender's picture, so there is nothing there for a line to run to.
        self.stretchesTrack = stretchesTrack && !incoming
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
            wave.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                wave.leadingAnchor.constraint(equalTo: playButton.trailingAnchor, constant: 12),
                wave.centerYAnchor.constraint(equalTo: centerYAnchor),
                wave.heightAnchor.constraint(equalToConstant: 26)
            ])
            if self.stretchesTrack {
                wave.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
            } else {
                wave.widthAnchor.constraint(equalToConstant: AudioBubbleContent.trackWidth).isActive = true
            }
            slider.minimumTrackTintColor = .clear
            slider.maximumTrackTintColor = .clear
        } else {
            // With no line behind it the slider draws its own track again, 6pt and fully rounded
            // off the reference, pitched light or dark against the bubble it is on.
            slider.setMinimumTrackImage(Utils.sliderTrack(colour: onDarkBubble ? UIColor(white: 1, alpha: 0.75) : .mainColor), for: .normal)
            slider.setMaximumTrackImage(Utils.sliderTrack(colour: onDarkBubble ? UIColor(white: 1, alpha: 0.18) : UIColor(white: 0, alpha: 0.15)), for: .normal)
        }
        addSubview(slider)
        slider.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            slider.leadingAnchor.constraint(equalTo: playButton.trailingAnchor, constant: 12),
            slider.centerYAnchor.constraint(equalTo: centerYAnchor),
            slider.heightAnchor.constraint(equalToConstant: 26)
        ])
        if self.stretchesTrack {
            slider.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        } else {
            slider.widthAnchor.constraint(equalToConstant: AudioBubbleContent.trackWidth).isActive = true
        }
        // Fix: the line used to be pinned to both ends of the row, which gave the row no width of
        // its own at all - so how wide the bubble came out was decided by the message label behind
        // it, which is hidden and has nothing to do with the audio. Two screens showing the same
        // note therefore came out at two different widths. The track is a known length, and the row
        // ends where its last piece ends, so the bubble hugs it and only it.
        if incoming {
            avatarBox.leadingAnchor.constraint(equalTo: slider.trailingAnchor, constant: 12).isActive = true
            avatarBox.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        } else if !self.stretchesTrack {
            // Only when the line is a known length. A stretching one takes its width from whoever
            // put the row on screen, and asking for both is what leaves the picture stretched into
            // a stadium while Auto Layout decides which of the two to break.
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

/// Remembers what a reused cell was last built for, so a redraw that would produce exactly the
/// same row hands back the row already in front of the reader instead of building it again.
///
/// A conversation list tears its cell down to nothing and rebuilds forty-odd views and their
/// constraints on every pass - and cellForRow runs for every visible row of every redraw, not only
/// for rows new to the screen. A message arriving, a counter changing, a picture landing: each of
/// those redraws rows that are already correct. On an older phone that is the scrolling.
///
/// The same idea as EditorPersonal's bubbleSignature, kept here because more than one list needs
/// it.
public enum CellBuildSignature {

    private static var key: UInt8 = 0

    public static func of(_ cell: UITableViewCell) -> String? {
        return objc_getAssociatedObject(cell, &key) as? String
    }

    public static func set(_ signature: String?, on cell: UITableViewCell) {
        objc_setAssociatedObject(cell, &key, signature, .OBJC_ASSOCIATION_COPY_NONATOMIC)
    }

    /// Everything a value holds, in one string.
    ///
    /// Reflected rather than listed by hand: choosing which fields matter is exactly how a row
    /// ends up showing yesterday's state, and a field that is added to the model later would be
    /// left out of a hand-written list without anyone noticing.
    public static func describe(_ value: Any?) -> String {
        guard let value = value else {
            return "nil"
        }
        let mirror = Mirror(reflecting: value)
        guard !mirror.children.isEmpty else {
            return String(describing: value)
        }
        var parts: [String] = []
        parts.reserveCapacity(mirror.children.count)
        for child in mirror.children {
            parts.append("\(child.label ?? "")=\(child.value)")
        }
        return parts.joined(separator: "\u{1F}")
    }
}

/// One line of text that walks itself across when there is more of it than there is room.
///
/// A label would truncate instead, and on a starred row the part that gets cut is the end - which
/// is where the group and the topic are, the very thing the line was widened to say.
public final class MarqueeLabel: UIView {

    private let label = UILabel()
    /// How far the text had to travel last time this was laid out, so a re-layout that changes
    /// nothing does not restart the walk from the beginning.
    private var travelled: CGFloat = -1
    /// Which walk is the current one. A walk schedules its own next step, so a walk that has been
    /// replaced has to be able to recognise that it no longer is.
    private var runToken = 0

    public var text: String? {
        get { return label.text }
        set { label.text = newValue; invalidateIntrinsicContentSize(); restart() }
    }

    public var font: UIFont! {
        get { return label.font }
        set { label.font = newValue; invalidateIntrinsicContentSize(); restart() }
    }

    public var textColor: UIColor! {
        get { return label.textColor }
        set { label.textColor = newValue }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        // Asks to be as wide as its text, but gives way before anything else does: the line shares
        // its row with a date that must not be pushed off, so being squeezed is the normal case
        // and is exactly what starts the text moving.
        setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override var intrinsicContentSize: CGSize {
        return label.intrinsicContentSize
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        let overflow = max(0, label.intrinsicContentSize.width - bounds.width)
        guard overflow != travelled else {
            return
        }
        travelled = overflow
        restart()
    }

    public override func didMoveToWindow() {
        super.didMoveToWindow()
        // Fix: a view taken off screen has its animations removed, and the transform is left
        // wherever the walk had got to - which is how a name ended up permanently shifted with its
        // first letters cut off, never moving again. Coming back on screen starts it over.
        if window != nil {
            restart()
        }
    }

    private func restart() {
        runToken += 1
        label.layer.removeAllAnimations()
        label.transform = .identity
        let overflow = max(0, label.intrinsicContentSize.width - bounds.width)
        guard overflow > 0, bounds.width > 0, window != nil else {
            return
        }
        walk(token: runToken, overflow: overflow)
    }

    /// One pass: waits, walks the text left until its end shows, puts it straight back where it
    /// started, waits again.
    ///
    /// Not an autoreversing animation - that walks back at reading speed, which reads as the text
    /// sliding about. It goes one way and returns at once, the way a marquee does.
    private func walk(token: Int, overflow: CGFloat) {
        // Roughly 30pt a second, so it can be read as it goes, and never quicker than a second.
        let duration = TimeInterval(max(overflow / 30, 1))
        UIView.animate(withDuration: duration,
                       delay: 2,
                       options: [.curveLinear, .allowUserInteraction],
                       animations: { [weak self] in
            self?.label.transform = CGAffineTransform(translationX: -overflow, y: 0)
        }, completion: { [weak self] finished in
            guard let self = self, finished, self.runToken == token else {
                return
            }
            self.label.transform = .identity
            // A pause at the beginning before setting off again, so the start of the name can be
            // read without waiting out a whole pass.
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                guard let self = self, self.runToken == token, self.window != nil else {
                    return
                }
                self.walk(token: token, overflow: overflow)
            }
        })
    }
}

/// A chat bubble that casts a soft shadow, so it still reads as a bubble when the wallpaper
/// behind it happens to be the colour the bubble is.
///
/// A view of its own rather than a shadow set on any plain UIView, for one reason: the shadow is
/// drawn from `shadowPath`, and a path can only be worked out once the bubble has a size. Taking
/// it from the layer's own contents instead would cost an offscreen pass per bubble on every
/// frame of a scroll.
public final class BubbleView: UIView {

    /// Off until `lift()` is called: an unlifted bubble behaves exactly like the UIView it
    /// replaced.
    private var lifted = false

    public override func layoutSubviews() {
        super.layoutSubviews()
        guard lifted else {
            return
        }
        let corners = BubbleView.rectCorners(layer.maskedCorners)
        layer.shadowPath = UIBezierPath(roundedRect: bounds,
                                        byRoundingCorners: corners,
                                        cornerRadii: CGSize(width: layer.cornerRadius,
                                                            height: layer.cornerRadius)).cgPath
    }

    /// Lifts the bubble off the background behind it.
    ///
    /// Call after the colour and the corners are settled: a bubble holding nothing but a sticker
    /// has no colour of its own, and a shadow under one would be a shadow cast by nothing.
    public func lift() {
        guard let ground = backgroundColor, ground.cgColor.alpha > 0 else {
            return
        }
        // A layer that masks to its bounds cannot draw anything outside them, shadow included.
        // Nothing in a bubble reaches its edge - the closest, the audio row, stops 10pt short,
        // and a 10pt corner cuts less than 3pt into the rectangle - so the clipping was not
        // holding anything in.
        clipsToBounds = false
        layer.masksToBounds = false
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 1)
        layer.shadowRadius = 3
        // Black on a dark wallpaper barely registers, and the same weight that reads as a lift in
        // the dark reads as grime in the light.
        layer.shadowOpacity = traitCollection.userInterfaceStyle == .dark ? 0.45 : 0.18
        lifted = true
        setNeedsLayout()
    }

    private static func rectCorners(_ mask: CACornerMask) -> UIRectCorner {
        guard !mask.isEmpty else {
            return .allCorners
        }
        var corners: UIRectCorner = []
        if mask.contains(.layerMinXMinYCorner) { corners.insert(.topLeft) }
        if mask.contains(.layerMaxXMinYCorner) { corners.insert(.topRight) }
        if mask.contains(.layerMinXMaxYCorner) { corners.insert(.bottomLeft) }
        if mask.contains(.layerMaxXMaxYCorner) { corners.insert(.bottomRight) }
        return corners
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

    /// The same, but held to a number of bytes the finished file has to come in under.
    ///
    /// The budget is the server's - see MessageLimits.videoBytes - and the length is what is
    /// actually being written, which is the trimmed length rather than the whole clip. A tenth
    /// is left aside for the container's own bookkeeping and the sound, and there is a floor:
    /// below about a fifth of a megabit the picture stops being worth sending, so a clip too
    /// long for its budget is encoded at the floor and reported as still too big rather than
    /// turned into mud.
    public static func targetBitrate(for track: AVAssetTrack, fittingBytes maxBytes: Int, seconds: Double, muted: Bool) -> Int {
        let heuristic = targetBitrate(for: track)
        guard maxBytes > 0, seconds > 0.1 else {
            return heuristic
        }
        let forSound: Double = muted ? 0 : 64_000
        let fromBudget = (Double(maxBytes) * 8 * 0.9) / seconds - forSound
        return Int(min(Double(heuristic), max(fromBudget, 200_000)))
    }

    public init() {}

    public func cancel() {
        cancelled = true
        reader?.cancelReading()
        writer?.cancelWriting()
    }

    /// `maxBytes` is what the finished file has to fit inside; pass 0 to leave the bitrate to
    /// the heuristic alone.
    public func start(source: URL,
               destination: URL,
               timeRange: CMTimeRange?,
               muted: Bool,
               maxBytes: Int = 0,
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
                AVVideoAverageBitRateKey: VideoTranscoder.targetBitrate(for: videoTrack,
                                                                        fittingBytes: maxBytes,
                                                                        seconds: CMTimeGetSeconds(span.duration),
                                                                        muted: muted),
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
    /// Files on this device that could not be read at all, so they are not read again and again.
    private static var unreadable: Set<String> = []
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
        guard !unreadable.contains(key) else {
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
            let exists = FileManager.default.fileExists(atPath: url.path)
            DispatchQueue.main.async {
                asking.remove(key)
                let callers = waiting.removeValue(forKey: key) ?? []
                guard !found.isEmpty else {
                    // Fix: nothing was remembered about a failure, so a file that cannot be read
                    // was opened and read again on every single pass of the row - and a row is
                    // redrawn for every tick, every download, every reload. Remembered only when
                    // the file is actually there: one that is still arriving deserves another try.
                    if exists {
                        unreadable.insert(key)
                    }
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
            // Fix: a voice note recorded on Android is a bare AAC stream - MediaRecorder's
            // AAC_ADTS, under a name ending .aac - and a bare stream is not a container.
            // AVURLAsset picks its parser from the file's type and has no parser for one, so it
            // finds no audio track at all and the line came back empty; nothing else ever asked
            // again, so those notes drew a blank line for good. AVAudioPlayer sniffs the bytes
            // instead of the name, which is why the same file plays and shows its length. The
            // level of a layer below does the same, given a hint about what it is looking at.
            return RawAudioLevels.measure(url: url)
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

// MARK: - Where each recording was left off

/// The point every audio bubble was last listened up to.
///
/// A conversation tears its players down when it is left, and a player is where the position
/// lived, so coming back used to start every recording again from nothing. The position outlives
/// the player here, and a bubble built afresh picks up where its own listening stopped.
public enum AudioPositionStore {

    /// How far into a recording somebody had got, and when they were last there.
    ///
    /// The date is what makes pruning possible: the list would otherwise grow by one entry for
    /// every voice note ever half-listened to and never shrink.
    private struct Mark: Codable {
        let time: TimeInterval
        let at: Date
    }

    private static let storeKey = "audio_positions_nexilis"
    /// Enough to cover anything anybody will scroll back to; the oldest fall off beyond it.
    private static let maximumKept = 300
    /// Written at most this often. The bubble reports its position ten times a second, and each
    /// write is an encode and an encrypt of the whole list - doing that on every report would
    /// cost far more than the thing it is recording.
    private static let flushInterval: TimeInterval = 2

    private static var marks: [String: Mark] = {
        return SecureUserDefaults.shared.value(forKey: storeKey) ?? [:]
    }()
    private static var lastFlush = Date.distantPast
    private static let lock = NSLock()

    /// Written out when the app is put away, whatever the clock says: there may be no later.
    private static let watches: [NSObjectProtocol] = {
        let flushNow: (Notification) -> Void = { _ in
            AudioPositionStore.flush(force: true)
        }
        return [
            NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification,
                                                   object: nil, queue: .main, using: flushNow),
            NotificationCenter.default.addObserver(forName: UIApplication.willTerminateNotification,
                                                   object: nil, queue: .main, using: flushNow)
        ]
    }()

    public static func remember(_ time: TimeInterval, for messageId: String) {
        guard !messageId.isEmpty else {
            return
        }
        _ = watches
        lock.lock()
        // A recording played to the end is at rest, not part-way through; remembering the end
        // would leave the bubble showing a full line that cannot be played without rewinding.
        if time > 0.25 {
            marks[messageId] = Mark(time: time, at: Date())
        } else {
            marks.removeValue(forKey: messageId)
        }
        lock.unlock()
        flush()
    }

    public static func position(for messageId: String) -> TimeInterval {
        _ = watches
        lock.lock()
        defer { lock.unlock() }
        return marks[messageId]?.time ?? 0
    }

    public static func forget(_ messageId: String) {
        lock.lock()
        marks.removeValue(forKey: messageId)
        lock.unlock()
        // Rare, and worth writing at once: a recording heard to the end that came back at its old
        // position after a restart would be the one thing nobody would think to look for.
        flush(force: true)
    }

    /// Puts the list on disk, no more often than it needs to be.
    private static func flush(force: Bool = false) {
        lock.lock()
        guard force || Date().timeIntervalSince(lastFlush) >= flushInterval else {
            lock.unlock()
            return
        }
        lastFlush = Date()
        if marks.count > maximumKept {
            let keep = marks.sorted { $0.value.at > $1.value.at }.prefix(maximumKept)
            marks = Dictionary(uniqueKeysWithValues: keep.map { ($0.key, $0.value) })
        }
        let snapshot = marks
        lock.unlock()
        SecureUserDefaults.shared.set(snapshot, forKey: storeKey)
    }
}

// MARK: - The strip a recording keeps playing under

/// The window the minimised player floats in.
///
/// Same reasoning as the call banner's: over every page of the app, and every touch outside the
/// strip itself belongs to whatever is underneath.
final class AudioMiniPlayerWindow: UIWindow {

    /// Fix: touching a window makes it the key window, and `visibleViewController` finds the top
    /// screen by looking at whichever window is key. Tapping the strip therefore made this window
    /// the answer to "what is on screen", so the conversation was presented on top of the strip's
    /// own host - and then torn away with it the moment the strip went, which is the bouncing.
    /// This window is a strip, never a place to put a screen, so it never takes the key.
    override var canBecomeKey: Bool {
        return false
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let hit = super.hitTest(point, with: event) else {
            return nil
        }
        return hit === self || hit === rootViewController?.view ? nil : hit
    }
}

/// The strip itself: pause, who it is from, and a line showing how far along it is.
final class AudioMiniPlayerBanner: UIView {

    static let height: CGFloat = 45
    static let progressHeight: CGFloat = 3
    static var totalHeight: CGFloat { height + progressHeight }

    private let playButton = UIButton(type: .system)
    private let avatarView = UIImageView()
    private let glyphView = UIImageView()
    private let nameLabel = UILabel()
    private let closeButton = UIButton(type: .system)
    private let progressTrack = UIView()
    private let progressFill = UIView()
    private var progressWidth: NSLayoutConstraint!

    override init(frame: CGRect) {
        super.init(frame: frame)
        build()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        build()
    }

    private func build() {
        backgroundColor = .secondarySystemBackground

        [playButton, avatarView, nameLabel, closeButton, progressTrack].forEach {
            addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        progressTrack.addSubview(progressFill)
        progressFill.translatesAutoresizingMaskIntoConstraints = false
        avatarView.addSubview(glyphView)
        glyphView.translatesAutoresizingMaskIntoConstraints = false

        playButton.tintColor = .label
        playButton.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 20, weight: .medium), forImageIn: .normal)

        avatarView.contentMode = .scaleAspectFill
        avatarView.clipsToBounds = true
        avatarView.layer.cornerRadius = 15

        glyphView.tintColor = .white
        glyphView.contentMode = .scaleAspectFit

        nameLabel.font = .systemFont(ofSize: 15)
        nameLabel.textColor = .label

        closeButton.tintColor = .secondaryLabel
        closeButton.setImage(UIImage(systemName: "xmark.circle"), for: .normal)
        closeButton.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 20, weight: .regular), forImageIn: .normal)

        progressTrack.backgroundColor = UIColor.label.withAlphaComponent(0.12)
        progressFill.backgroundColor = UIColor.label.withAlphaComponent(0.55)

        progressWidth = progressFill.widthAnchor.constraint(equalToConstant: 0)
        let body = AudioMiniPlayerBanner.height

        // Measured off the reference: the picture and the name sit together in the middle of the
        // strip, with the two buttons out at the edges - not tucked in beside the pause button.
        let middle = UILayoutGuide()
        addLayoutGuide(middle)

        NSLayoutConstraint.activate([
            playButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            playButton.centerYAnchor.constraint(equalTo: topAnchor, constant: body / 2),
            playButton.widthAnchor.constraint(equalToConstant: 28),
            playButton.heightAnchor.constraint(equalToConstant: 28),

            middle.centerXAnchor.constraint(equalTo: centerXAnchor),
            middle.leadingAnchor.constraint(equalTo: avatarView.leadingAnchor),
            middle.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            middle.leadingAnchor.constraint(greaterThanOrEqualTo: playButton.trailingAnchor, constant: 12),
            middle.trailingAnchor.constraint(lessThanOrEqualTo: closeButton.leadingAnchor, constant: -12),

            avatarView.centerYAnchor.constraint(equalTo: playButton.centerYAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: 30),
            avatarView.heightAnchor.constraint(equalToConstant: 30),

            glyphView.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
            glyphView.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),
            glyphView.widthAnchor.constraint(equalToConstant: 15),
            glyphView.heightAnchor.constraint(equalToConstant: 15),

            nameLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 10),
            nameLabel.centerYAnchor.constraint(equalTo: playButton.centerYAnchor),

            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18),
            closeButton.centerYAnchor.constraint(equalTo: playButton.centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 28),
            closeButton.heightAnchor.constraint(equalToConstant: 28),

            progressTrack.leadingAnchor.constraint(equalTo: leadingAnchor),
            progressTrack.trailingAnchor.constraint(equalTo: trailingAnchor),
            progressTrack.topAnchor.constraint(equalTo: topAnchor, constant: body),
            progressTrack.heightAnchor.constraint(equalToConstant: AudioMiniPlayerBanner.progressHeight),

            progressFill.leadingAnchor.constraint(equalTo: progressTrack.leadingAnchor),
            progressFill.topAnchor.constraint(equalTo: progressTrack.topAnchor),
            progressFill.bottomAnchor.constraint(equalTo: progressTrack.bottomAnchor),
            progressWidth
        ])
    }

    func configure(name: String, avatar: UIImage?, isVoiceNote: Bool) {
        nameLabel.text = name
        if let avatar = avatar {
            avatarView.image = avatar
            avatarView.backgroundColor = .clear
            glyphView.isHidden = true
        } else {
            // No picture to show, so the bubble's own stand-in is used: a mic for a voice note,
            // a note on a salmon disc for anything else.
            avatarView.image = nil
            avatarView.backgroundColor = isVoiceNote ? .mainColor : UIColor.renderColor(hex: "#D98878")
            glyphView.image = UIImage(systemName: isVoiceNote ? "mic.fill" : "music.note")
            glyphView.isHidden = false
        }
    }

    func setPlaying(_ playing: Bool) {
        playButton.setImage(UIImage(systemName: playing ? "pause.fill" : "play.fill"), for: .normal)
    }

    func setProgress(_ fraction: CGFloat) {
        progressWidth.constant = max(0, min(1, fraction)) * bounds.width
    }

    func onPlayPause(_ target: Any, action: Selector) {
        playButton.addTarget(target, action: action, for: .touchUpInside)
    }

    func onClose(_ target: Any, action: Selector) {
        closeButton.addTarget(target, action: action, for: .touchUpInside)
    }

    /// The strip itself leads back to the conversation the recording is in.
    func onTap(_ target: Any, action: Selector) {
        isUserInteractionEnabled = true
        addGestureRecognizer(UITapGestureRecognizer(target: target, action: action))
    }
}

/// Keeps a recording playing after the conversation it belongs to has been left.
///
/// Leaving a chat used to stop whatever was playing, which is not what anybody means by leaving a
/// chat. The player is handed over here instead and carries on, with a strip at the top of the
/// screen to pause it or put it away. Walking back into the conversation takes the player back,
/// so the bubble picks the recording up live rather than starting a second one over the top.
public final class AudioMiniPlayer: NSObject, AVAudioPlayerDelegate {

    public static let shared = AudioMiniPlayer()

    /// Every recording that has been opened, held here rather than by whichever screen happened
    /// to open it.
    ///
    /// This is the whole point of the class now. Screens used to open their own players and hand
    /// them back and forth as conversations came and went, and handing an object between two
    /// screens whose lifetimes overlap - UIKit builds the incoming one before tearing down the
    /// outgoing one - meant a bubble could open a second player for a recording the first one was
    /// still playing. Two players, one recording: the one making the sound somewhere else, the
    /// silent one answering every question the bubble asked. No amount of reordering the handover
    /// fixes that; there simply has to be one player per recording, and one place that keeps it.
    private var players: [String: AVAudioPlayer] = [:]
    /// The recording the strip is showing, if the strip is up.
    private var messageId: String = ""

    /// The player the strip is showing, if any.
    private var player: AVAudioPlayer? {
        return messageId.isEmpty ? nil : players[messageId]
    }
    private var banner: AudioMiniPlayerBanner?
    private var window: AudioMiniPlayerWindow?
    private var ticker: Timer?
    /// The screens that have been moved down to make room, held weakly - a screen that goes away
    /// while the strip is up takes its own inset with it.
    private let insetControllers = NSHashTable<UIViewController>.weakObjects()
    private var insetTimer: Timer?

    public var isShowing: Bool {
        return banner != nil
    }

    /// The recording on the strip, if there is one.
    public var currentMessageId: String? {
        return player == nil ? nil : messageId
    }

    /// The player behind a given recording, while the strip still holds it.
    ///
    /// A bubble can read its button, its reading and its line straight off this without taking
    /// ownership. Ownership moving is a separate thing that can be early, late, or - if the row
    /// was never built while the strip held it - not happen at all; what the bubble shows should
    /// not wait on any of that.
    public func player(for messageId: String) -> AVAudioPlayer? {
        return players[messageId]
    }

    /// The player for a recording, opened once and kept.
    ///
    /// Every bubble asks here instead of opening the file itself, so a recording can only ever
    /// have one player however many screens draw it.
    ///
    /// - Parameters:
    ///   - messageId: the message the recording belongs to.
    ///   - url: where the file is, used only if it has not been opened yet.
    ///   - rate: the reading speed chosen for this bubble.
    public func player(for messageId: String, openingFrom url: URL, rate: Float = 1) -> AVAudioPlayer? {
        if let existing = players[messageId] {
            return existing
        }
        guard let made = try? AVAudioPlayer(contentsOf: url) else {
            return nil
        }
        // Set before the first play or the rate is ignored.
        made.enableRate = true
        made.rate = rate
        // Picked up where this bubble was last listened to.
        let left = AudioPositionStore.position(for: messageId)
        if left > 0, left < made.duration - 0.05 {
            made.currentTime = left
        }
        players[messageId] = made
        return made
    }

    /// Pauses every recording except the one named, so only one is ever running.
    ///
    /// One recording at a time is a rule about the app, not about a screen: the other one may be
    /// another bubble in this conversation, or one still playing on the strip from a conversation
    /// that was left. Only this object can see both, so the rule lives here.
    ///
    /// - Returns: the recordings it paused, so a screen showing any of them can put those bubbles
    ///   back to rest.
    @discardableResult
    public func pauseAllExcept(_ messageId: String) -> [String] {
        var paused: [String] = []
        for (id, player) in players where id != messageId && player.isPlaying {
            player.pause()
            AudioPositionStore.remember(player.currentTime, for: id)
            paused.append(id)
        }
        // The strip stands for something that is playing. If that is what just stopped, it goes.
        if paused.contains(self.messageId) {
            stop()
        }
        return paused
    }

    /// Forgets a recording that has been played to the end, so the next listen opens it afresh.
    public func release(_ messageId: String) {
        if self.messageId == messageId {
            stop()
        }
        players[messageId]?.stop()
        players.removeValue(forKey: messageId)
    }

    private override init() {
        super.init()
    }

    // MARK: - Handing over and taking back

    /// Takes a playing recording off a conversation that is being left.
    ///
    /// Nothing happens for a player that is not actually playing - a paused bubble has no reason
    /// to follow the reader around.
    public func takeOver(player: AVAudioPlayer,
                         messageId: String,
                         name: String,
                         avatar: UIImage?,
                         isVoiceNote: Bool) {
        guard player.isPlaying else {
            return
        }
        // Nothing changes hands: the player was already this object's. All that happens is that
        // the strip goes up, because there is no longer a bubble on screen showing it.
        players[messageId] = player
        // Fix: this used to refuse a handover that arrived just after the recording had been
        // given back, on the grounds that it could only be the screen being left tearing down
        // late. It could also be somebody pressing back a second after walking in - and refusing
        // that left the player with nobody holding it at all, so it was released and the sound
        // stopped. Always accepted now; a conversation that already has the recording takes it
        // straight back in reclaimPlayingAudioIfMine, and the strip goes with it.
        self.messageId = messageId
        player.delegate = self
        show(name: name, avatar: avatar, isVoiceNote: isVoiceNote)
        startTicking()
    }

    /// Gives the player back to the conversation the recording belongs to.
    public func reclaim(messageId: String) -> AVAudioPlayer? {
        guard let player = players[messageId] else {
            return nil
        }
        // The player stays exactly where it is; only the strip goes, because a bubble is showing
        // the recording again and two things showing the same recording is one too many.
        if self.messageId == messageId {
            self.messageId = ""
            player.delegate = nil
            dismiss()
        }
        return player
    }

    /// Stops whatever is on the strip and takes it away.
    public func stop() {
        stopPlayback(keepPosition: true)
        dismiss()
    }

    private func stopPlayback(keepPosition: Bool) {
        if let player = player {
            if keepPosition {
                AudioPositionStore.remember(player.currentTime, for: messageId)
            }
            player.pause()
        }
        messageId = ""
    }

    // MARK: - The strip

    private func show(name: String, avatar: UIImage?, isVoiceNote: Bool) {
        if let banner = banner {
            banner.configure(name: name, avatar: avatar, isVoiceNote: isVoiceNote)
            banner.setPlaying(true)
            return
        }
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive })
            ?? UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first else {
            return
        }
        let banner = AudioMiniPlayerBanner()
        banner.configure(name: name, avatar: avatar, isVoiceNote: isVoiceNote)
        banner.setPlaying(true)
        banner.onPlayPause(self, action: #selector(playPauseTapped))
        banner.onClose(self, action: #selector(closeTapped))
        banner.onTap(self, action: #selector(bannerTapped))

        let host = UIViewController()
        host.view.backgroundColor = .clear
        host.view.addSubview(banner)
        banner.translatesAutoresizingMaskIntoConstraints = false

        let window = AudioMiniPlayerWindow(windowScene: scene)
        window.backgroundColor = .clear
        window.windowLevel = .statusBar + 1
        window.rootViewController = host
        window.isHidden = false

        let total = AudioMiniPlayerBanner.height + AudioMiniPlayerBanner.progressHeight
        NSLayoutConstraint.activate([
            banner.leadingAnchor.constraint(equalTo: host.view.leadingAnchor),
            banner.trailingAnchor.constraint(equalTo: host.view.trailingAnchor),
            banner.topAnchor.constraint(equalTo: host.view.safeAreaLayoutGuide.topAnchor),
            banner.heightAnchor.constraint(equalToConstant: total)
        ])
        window.layoutIfNeeded()

        self.window = window
        self.banner = banner

        banner.transform = CGAffineTransform(translationX: 0, y: -(total + window.safeAreaInsets.top))
        UIView.animate(withDuration: 0.28, delay: 0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0.4) {
            banner.transform = .identity
        }
        // Fix: the strip was laid over the top of whatever was on screen, so it sat on the
        // navigation bar and hid it. Everything underneath is moved down by exactly its height
        // instead - the same thing the minimised call does.
        refreshInsetsIfShowing()
        startInsetWatch()
    }

    // MARK: - Making room rather than covering

    /// Moves down anything on screen that has not been moved down yet: the window's root, and
    /// every screen presented on top of it. Their own children - tabs, navigation stacks, the
    /// screens inside them - inherit it, so only the outermost of each is touched.
    private func refreshInsetsIfShowing() {
        guard isShowing, let root = appWindow()?.rootViewController else {
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
        for controller in chain where !(controller is UIAlertController)
            && !insetControllers.contains(controller) {
            insetControllers.add(controller)
            UIView.animate(withDuration: 0.25) {
                controller.additionalSafeAreaInsets.top += AudioMiniPlayerBanner.totalHeight
                controller.view.layoutIfNeeded()
            }
        }
    }

    private func clearInsets() {
        for controller in insetControllers.allObjects {
            let restored = max(0, controller.additionalSafeAreaInsets.top - AudioMiniPlayerBanner.totalHeight)
            UIView.animate(withDuration: 0.25) {
                controller.additionalSafeAreaInsets.top = restored
                controller.view.layoutIfNeeded()
            }
        }
        insetControllers.removeAllObjects()
    }

    /// Screens come and go while a recording plays, and most of the ones in this project never
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

    /// The app's own window, never one of the strips'.
    private func appWindow() -> UIWindow? {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: { !($0 is AudioMiniPlayerWindow) && !($0 is MiniCallBannerWindow)
                && !$0.isHidden && $0.rootViewController != nil })
    }

    private func dismiss() {
        ticker?.invalidate()
        ticker = nil
        stopInsetWatch()
        clearInsets()
        guard let banner = banner, let window = window else {
            return
        }
        self.banner = nil
        self.window = nil
        let total = AudioMiniPlayerBanner.height + AudioMiniPlayerBanner.progressHeight
        UIView.animate(withDuration: 0.22, animations: {
            banner.transform = CGAffineTransform(translationX: 0, y: -(total + window.safeAreaInsets.top))
        }, completion: { _ in
            window.isHidden = true
            window.rootViewController = nil
        })
    }

    private func startTicking() {
        ticker?.invalidate()
        let ticker = Timer(timeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.player else {
                return
            }
            AudioPositionStore.remember(player.currentTime, for: self.messageId)
            let fraction = player.duration > 0 ? CGFloat(player.currentTime / player.duration) : 0
            self.banner?.setProgress(fraction)
            self.banner?.setPlaying(player.isPlaying)
        }
        RunLoop.main.add(ticker, forMode: .common)
        self.ticker = ticker
    }

    // MARK: - Buttons

    @objc private func playPauseTapped() {
        guard let player = player else {
            return
        }
        if player.isPlaying {
            player.pause()
            AudioPositionStore.remember(player.currentTime, for: messageId)
        } else {
            // Same rule from here as from a bubble: starting one stops the rest.
            pauseAllExcept(messageId)
            player.play()
        }
        banner?.setPlaying(player.isPlaying)
    }

    @objc private func closeTapped() {
        stop()
    }

    /// Back to the conversation the recording is in. The bubble takes its player back as it is
    /// built, so the reader lands on it still playing rather than on a recording started afresh.
    @objc private func bannerTapped() {
        guard !messageId.isEmpty else {
            return
        }
        let id = messageId
        // Opened on the next turn of the run loop, once the tap - and whatever the system does
        // about windows because of it - is finished with.
        DispatchQueue.main.async {
            APIS.openChatForLocalMessage(id)
        }
    }

    // MARK: - AVAudioPlayerDelegate

    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        let finished = messageId
        AudioPositionStore.forget(finished)
        messageId = ""
        dismiss()
        players[finished]?.currentTime = 0
    }
}


/// A tap that remembers which message it belongs to.
///
/// The label it sits on is handed to a different message the moment its row scrolls away, so the
/// message cannot be looked up from the view when the tap arrives - it is carried here instead.
/// Whether a list has just moved, and so should not be answering a long press.
///
/// Fix: a long press on a conversation that was still gliding opened the bubble menu, or the
/// link sheet, under a finger that had been put down to stop the list. Asking the scroll view
/// is not enough on its own: a UIScrollView stops its own deceleration the instant it is
/// touched, so by the time a press is recognised the list already reports itself still. The
/// moment of the last movement is remembered instead, and a press that close behind it belongs
/// to the scroll.
final class ListMotion {

    /// How long after the last movement a press is still part of the scroll rather than a press
    /// on what happens to be under the finger.
    static let quietFor: TimeInterval = 0.25

    private var lastMovement = Date.distantPast

    /// Called from scrollViewDidScroll.
    func didMove() {
        lastMovement = Date()
    }

    func isMoving(_ scrollView: UIScrollView?) -> Bool {
        if let scrollView = scrollView, scrollView.isDragging || scrollView.isDecelerating {
            return true
        }
        return Date().timeIntervalSince(lastMovement) < ListMotion.quietFor
    }
}

/// How many messages a conversation may keep pinned, and which ones they are.
///
/// Fix: three was a bare number in the one place that checked it, and it was checked with `==`.
/// A conversation can hold more than three pins already - a pin travels between devices and
/// between participants, and nothing on the way in caps it - and against `== 3` a fourth pin was
/// simply added, then a fifth, with the banner growing a segment for each. The rule lives here
/// now, is asked rather than assumed, and repairs what it finds.
enum PinnedMessages {

    static let maximum = 3

    /// When a message was pinned. Unpinned reads as 0, and so does anything unreadable.
    static func pinTime(_ message: [String: Any?]) -> Int64 {
        return Int64(message[TypeDataMessage.is_pinned] as? String ?? "0") ?? 0
    }

    /// The pins a conversation shows: the newest `maximum`, oldest first - which is the order
    /// the banner steps through them in.
    static func newest(_ pinned: [[String: Any?]]) -> [[String: Any?]] {
        let sorted = pinned.sorted { pinTime($0) < pinTime($1) }
        guard sorted.count > maximum else {
            return sorted
        }
        return Array(sorted.suffix(maximum))
    }

    /// Brings a conversation in the database back to `maximum` pins, keeping the newest ones,
    /// and says which messages it unpinned.
    ///
    /// The server keeps no list of what a conversation has pinned and no count of them, so this
    /// database is where the rule has to hold. A pin from another participant or another device
    /// is written straight in with nothing counting what is already there, which is how a
    /// conversation ends up holding four.
    ///
    /// Ties are broken by message id so that "the newest three" is the same three every time
    /// this is asked - two pins made in the same millisecond, on two devices, are possible.
    @discardableResult
    static func trim(conversation whereClause: String, fmdb: FMDatabase) -> [String] {
        let pinnedRows = "\(whereClause) AND is_pinned <> '0' AND is_pinned IS NOT NULL"
        let keep = "SELECT message_id FROM MESSAGE WHERE \(pinnedRows) ORDER BY CAST(is_pinned AS INTEGER) DESC, message_id DESC LIMIT \(maximum)"
        var extra: [String] = []
        if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "SELECT message_id FROM MESSAGE WHERE \(pinnedRows) AND message_id NOT IN (\(keep))") {
            while cursor.next() {
                if let id = cursor.string(forColumnIndex: 0), !id.isEmpty {
                    extra.append(id)
                }
            }
            cursor.close()
        }
        guard !extra.isEmpty else {
            return []
        }
        let list = extra.map { "'\($0)'" }.joined(separator: ",")
        _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE", cvalues: ["is_pinned": "0"], _where: "message_id IN (\(list))")
        return extra
    }

    /// The same, on a transaction of its own.
    @discardableResult
    static func trim(conversation whereClause: String) -> [String] {
        var removed: [String] = []
        Database.shared.database?.inTransaction({ (fmdb, _) in
            removed = trim(conversation: whereClause, fmdb: fmdb)
        })
        return removed
    }

    /// The conversation a message belongs to, written as a condition over MESSAGE - the same
    /// shape the editors use to read their own conversation, so a trim covers exactly the
    /// messages that editor would show.
    ///
    /// Nil when the message is not in the database, or belongs to nothing that can be trimmed.
    static func conversationClause(forMessageId messageId: String, fmdb: FMDatabase) -> String? {
        guard !messageId.isEmpty else {
            return nil
        }
        var clause: String?
        let query = "SELECT chat_id, l_pin, f_pin, message_scope_id, is_call_center, call_center_id FROM MESSAGE WHERE message_id = '\(messageId)'"
        if let cursor = Database.shared.getRecords(fmdb: fmdb, query: query), cursor.next() {
            let chatId = cursor.string(forColumnIndex: 0) ?? ""
            let lPin = cursor.string(forColumnIndex: 1) ?? ""
            let fPin = cursor.string(forColumnIndex: 2) ?? ""
            let scope = cursor.string(forColumnIndex: 3) ?? ""
            let isCallCenter = cursor.string(forColumnIndex: 4) ?? "0"
            let complaintId = cursor.string(forColumnIndex: 5) ?? ""
            cursor.close()

            if isCallCenter == "1", !complaintId.isEmpty {
                clause = "call_center_id='\(complaintId)'"
            } else if !chatId.isEmpty {
                // A topic inside a group: every message in it carries the topic's chat id.
                clause = "chat_id='\(chatId)'"
            } else if scope == MessageScope.GROUP {
                clause = "chat_id='' AND l_pin='\(lPin)'"
            } else {
                // A one-to-one chat is the pair, in whichever direction each message went.
                let me = User.getMyPin() ?? ""
                let other = fPin == me ? lPin : fPin
                if !other.isEmpty {
                    clause = "(f_pin='\(other)' or l_pin='\(other)') AND (message_scope_id = '\(MessageScope.WHISPER)' OR message_scope_id = '\(MessageScope.FORM)' OR message_scope_id = '\(MessageScope.CALL)' OR message_scope_id = '\(MessageScope.MISSED_CALL)') AND is_call_center = 0"
                }
            }
        }
        return clause
    }

    /// What has to be unpinned before one more can be added, oldest first.
    ///
    /// Usually the single oldest pin. More than one only when the conversation arrived holding
    /// more than it should, and this is what puts it back to `maximum`.
    static func toReplace(_ pinned: [[String: Any?]]) -> [[String: Any?]] {
        let sorted = pinned.sorted { pinTime($0) < pinTime($1) }
        let over = sorted.count - (maximum - 1)
        guard over > 0 else {
            return []
        }
        return Array(sorted.prefix(over))
    }
}

/// The floating date over a conversation: there while the list is moving, gone once it settles.
///
/// Fix: the date was an orange tab pinned to the top of the list for as long as its day was on
/// screen, sitting over the messages behind it whether anybody was scrolling or not. It is a
/// white pill now, faintly showing what is behind it, and the one that floats keeps out of the
/// way when the reader has stopped moving - the same rule WhatsApp uses.
///
/// Only the floating one. A date sitting in its own place between two days is part of the
/// conversation and stays put; the one that has left its place to hang at the top of the screen
/// is the one that goes. Which is which is asked of the geometry: a header held back at the top
/// ends up below where its own first row says it belongs.
///
/// The timings are taken from the recording this follows: the date stays about a third of a
/// second after the list stops, then fades over about a quarter of a second, and comes back the
/// instant the list moves again.
/// What changed between two versions of a conversation list, as rows a UITableView can be told
/// about one at a time.
///
/// Fix: a message arriving used to end in `reloadData()`, which throws every row away and builds
/// them all again - the whole list flickers, whatever was under the reader's finger is rebuilt,
/// and a row that only moved from third place to first is indistinguishable from a list that
/// changed completely. What actually happens when a message arrives is one row moving to the top
/// with its own preview and badge redrawn, and that is what this describes.
public enum ChatRowDiff {

    public struct Plan {
        /// Rows to delete, as positions in the list the table is currently showing.
        public let deletes: [Int]
        /// Rows to insert, as positions in the new list.
        public let inserts: [Int]
        /// Rows that changed places: `from` in the old list, `to` in the new one.
        public let moves: [(from: Int, to: Int)]
        /// Rows that stayed put but no longer draw the same thing, as positions in the new list.
        public let reloads: [Int]
        /// What the table must already be showing for this plan to be applied to it.
        public let oldCount: Int
        public let newCount: Int

        public var isEmpty: Bool {
            return deletes.isEmpty && inserts.isEmpty && moves.isEmpty && reloads.isEmpty
        }

        /// Rows to rebuild once the batch has settled.
        ///
        /// The ones whose content changed, plus every row a structural change shifted. A cell is
        /// kept by a move rather than built again, and these rows draw from where they sit - the
        /// avatar a row asks the network for is delivered back to an index path, so a row that
        /// has quietly slid down one place would take delivery of its neighbour's picture.
        /// Rebuilding a row that is off screen costs nothing.
        public var rowsToRefresh: [Int] {
            var rows = Set(reloads)
            var lowestShifted: Int?
            func shift(_ index: Int) {
                lowestShifted = min(lowestShifted ?? index, index)
            }
            deletes.forEach(shift)
            inserts.forEach(shift)
            var highestMoved = -1
            for move in moves {
                shift(min(move.from, move.to))
                highestMoved = max(highestMoved, max(move.from, move.to))
            }
            if let lowest = lowestShifted {
                // A row added or taken away pushes everything below it along; a move only
                // disturbs the rows between where it left and where it landed.
                let highest = (deletes.isEmpty && inserts.isEmpty) ? highestMoved : newCount - 1
                if highest >= lowest {
                    for row in lowest...highest {
                        rows.insert(row)
                    }
                }
            }
            return rows.sorted()
        }
    }

    /// What a row is, as opposed to what it currently says. Two readings of the same conversation
    /// share this; two different conversations never do.
    public static func identity(_ chat: Chat) -> String {
        if chat.isParent {
            return "folder\u{1F}" + chat.groupId
        }
        return "chat\u{1F}" + chat.pin + "\u{1F}" + chat.groupId
    }

    /// The work needed to turn `old` into `new`, or nil when the two cannot be lined up row by
    /// row - a repeated identity, which the caller answers with a plain reload.
    public static func plan(from old: [Chat], to new: [Chat]) -> Plan? {
        var oldIndexById: [String: Int] = [:]
        for (index, chat) in old.enumerated() {
            let id = identity(chat)
            guard oldIndexById[id] == nil else {
                return nil
            }
            oldIndexById[id] = index
        }
        var newIndexById: [String: Int] = [:]
        for (index, chat) in new.enumerated() {
            let id = identity(chat)
            guard newIndexById[id] == nil else {
                return nil
            }
            newIndexById[id] = index
        }

        var deletes: [Int] = []
        var survivors: [(from: Int, to: Int)] = []
        for (index, chat) in old.enumerated() {
            if let destination = newIndexById[identity(chat)] {
                survivors.append((from: index, to: destination))
            } else {
                deletes.append(index)
            }
        }
        var inserts: [Int] = []
        for (index, chat) in new.enumerated() where oldIndexById[identity(chat)] == nil {
            inserts.append(index)
        }

        // The rows that can stay where they are: the longest run of survivors already in the
        // right order relative to each other. Everything else is a move, which is what keeps a
        // message arriving at the top to a single travelling row rather than a list-wide shuffle.
        let settled = longestRunInOrder(survivors.map { $0.to })
        var moves: [(from: Int, to: Int)] = []
        let structural = !deletes.isEmpty || !inserts.isEmpty
        for (position, survivor) in survivors.enumerated() where !settled.contains(position) {
            // With nothing added or taken away, a row whose place is unchanged has not moved,
            // whichever side of the longest settled run it fell on.
            if !structural && survivor.from == survivor.to {
                continue
            }
            moves.append((from: survivor.from, to: survivor.to))
        }

        var reloads: [Int] = []
        for survivor in survivors {
            let before = CellBuildSignature.describe(old[survivor.from])
            let after = CellBuildSignature.describe(new[survivor.to])
            if before != after {
                reloads.append(survivor.to)
            }
        }

        return Plan(deletes: deletes, inserts: inserts, moves: moves, reloads: reloads,
                    oldCount: old.count, newCount: new.count)
    }

    /// Positions of a longest strictly increasing subsequence of `values` - the rows that need no
    /// move. Patience sorting, so a list of any length costs next to nothing.
    private static func longestRunInOrder(_ values: [Int]) -> Set<Int> {
        guard !values.isEmpty else {
            return []
        }
        var tailPosition: [Int] = []
        var previous = [Int](repeating: -1, count: values.count)
        for (position, value) in values.enumerated() {
            var low = 0
            var high = tailPosition.count
            while low < high {
                let middle = (low + high) / 2
                if values[tailPosition[middle]] < value {
                    low = middle + 1
                } else {
                    high = middle
                }
            }
            if low > 0 {
                previous[position] = tailPosition[low - 1]
            }
            if low == tailPosition.count {
                tailPosition.append(position)
            } else {
                tailPosition[low] = position
            }
        }
        var result: Set<Int> = []
        var walk = tailPosition.last ?? -1
        while walk >= 0 {
            result.insert(walk)
            walk = previous[walk]
        }
        return result
    }
}

public extension UITableView {

    /// Redraws rows without moving what the reader is looking at.
    ///
    /// Fix: reloading a row throws away the height the table was holding for it, and with rows
    /// that size themselves that height is re-worked from scratch. A tick arriving on a message
    /// far up the conversation would then grow or shrink the content by the difference, and the
    /// list slid under the reader for a change to something they could not even see. The place
    /// they are looking at is put back afterwards: the foot of the conversation if that is where
    /// they were, otherwise the row at the top of the screen, kept exactly where it was.
    ///
    /// A finger on the list outranks all of this - restoring an offset mid-flick would stop the
    /// scroll dead - so while the list is moving under its own or the reader's power this is an
    /// ordinary reload.
    func reloadRowsKeepingPlace(at indexPaths: [IndexPath]) {
        guard !indexPaths.isEmpty else {
            return
        }
        guard !isDragging, !isDecelerating, window != nil else {
            reloadRows(at: indexPaths, with: .none)
            return
        }
        let lowest = -adjustedContentInset.top
        let bottomOffset = max(lowest, contentSize.height + adjustedContentInset.bottom - bounds.height)
        let wasAtBottom = bottomOffset - contentOffset.y <= 8
        let anchor = indexPathsForVisibleRows?.first
        let anchorDistanceFromTop = anchor.map { rectForRow(at: $0).minY - contentOffset.y }

        UIView.performWithoutAnimation {
            reloadRows(at: indexPaths, with: .none)
            layoutIfNeeded()
        }

        var target: CGFloat?
        if wasAtBottom {
            target = max(lowest, contentSize.height + adjustedContentInset.bottom - bounds.height)
        } else if let anchor = anchor, let distance = anchorDistanceFromTop,
                  anchor.section < numberOfSections,
                  anchor.row < numberOfRows(inSection: anchor.section) {
            target = max(lowest, rectForRow(at: anchor).minY - distance)
        }
        if let target = target, abs(target - contentOffset.y) > 0.5 {
            setContentOffset(CGPoint(x: contentOffset.x, y: target), animated: false)
        }
    }
}

/// The "unread from here" band, drawn above the first message the reader has not seen.
///
/// Fix: this used to be a small green pill with white text floating in the middle of the row,
/// which said only "Unread Messages". WhatsApp's is the reference: a band the full width of the
/// list, sheer white so the conversation shows through it, black text, and it says how many
/// messages are waiting below it. The three chat screens each drew their own copy of the old
/// pill; they all call this now, so the band and the room a row leaves for it can only be
/// described once.
/// How a day is written on the divider between messages, once it is too old to be named
/// ("Today", "Yesterday", a weekday).
///
/// Fix: that divider always read "Tue, 24 Aug", with no year on it, so a conversation scrolled
/// back far enough showed an August from any year as if it were this one. Past the turn of the
/// year the day is written as a full date instead, the same "dd/MM/yy" the chat list already
/// uses for its older rows.
enum ChatDayLabel {

    static let sameYear = "EE, dd MMM"
    static let otherYear = "dd/MM/yy"

    /// The format to write `date` in, judged against the year running now.
    static func format(for date: Date, calendar: Calendar = Calendar.current) -> String {
        let year = calendar.component(.year, from: date)
        let thisYear = calendar.component(.year, from: Date())
        return year == thisYear ? sameYear : otherYear
    }
}

enum UnreadMarker {

    /// Sheer white with black on it, the same family as the floating date pill above it - see
    /// DateHeaderVisibility.
    static var background: UIColor { return UIColor.white.withAlphaComponent(0.75) }
    static var text: UIColor { return .black }

    /// The band's own height, the gap above it (below the day's date) and the gap below it
    /// (above the first unread bubble).
    static let height: CGFloat = 32
    static let gapAbove: CGFloat = 10
    static let gapBelow: CGFloat = 14
    /// What a row carrying the band has to leave above its bubble: all three together. The band
    /// and the bubble are both placed from the top of the row, so they cannot drift apart.
    static var totalTopInset: CGFloat { return gapAbove + height + gapBelow }

    /// "1 unread message", "3 unread messages", or the plain wording when the count is unknown.
    static func title(count: Int) -> String {
        guard count > 0 else {
            return "Unread Messages".localized()
        }
        let wording = count == 1 ? "%d unread message" : "%d unread messages"
        return String(format: wording.localized(), count)
    }

    /// Draws the band across the top of a row.
    @discardableResult
    static func install(in contentView: UIView, count: Int, fontSize: CGFloat) -> UIView {
        let band = UIView()
        band.backgroundColor = background
        band.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(band)
        NSLayoutConstraint.activate([
            band.topAnchor.constraint(equalTo: contentView.topAnchor, constant: gapAbove),
            band.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            band.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            band.heightAnchor.constraint(equalToConstant: height)
        ])

        let label = UILabel()
        label.text = title(count: count)
        label.textAlignment = .center
        label.textColor = text
        label.font = UIFont.systemFont(ofSize: fontSize, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        band.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerYAnchor.constraint(equalTo: band.centerYAnchor),
            label.centerXAnchor.constraint(equalTo: band.centerXAnchor),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: band.leadingAnchor, constant: 12),
            label.trailingAnchor.constraint(lessThanOrEqualTo: band.trailingAnchor, constant: -12)
        ])
        return band
    }
}

final class DateHeaderVisibility {

    /// How the pill looks: white enough to read black text on, sheer enough to see the
    /// conversation through.
    static var pillBackground: UIColor { return UIColor.white.withAlphaComponent(0.85) }
    static var pillText: UIColor { return .black }

    static let lingerAfterScroll: TimeInterval = 0.35
    static let fadeOut: TimeInterval = 0.25
    static let fadeIn: TimeInterval = 0.1

    /// A header the table has built, and the day it stands for. Held weakly - the table makes a
    /// fresh one whenever a day comes back on screen, and the old ones must be free to go.
    private struct Tracked {
        weak var view: UIView?
        let section: Int
    }

    private var tracked: [Tracked] = []
    /// Whether the floating date is currently out of the way.
    private var isPinnedHeaderHidden = false
    private var hideWork: DispatchWorkItem?

    /// Follow a header the table has just built.
    func track(_ header: UIView, section: Int, in tableView: UITableView) {
        tracked.removeAll { $0.view == nil }
        tracked.append(Tracked(view: header, section: section))
        // Whether this one is the floating date cannot be answered before it has been laid out,
        // so it starts visible - which is right for every header that is not floating, and right
        // for the floating one too while the list is moving, which is when headers are built.
        header.alpha = 1
        // And once the layout has happened, ask properly. This catches the one case the line
        // above gets wrong: a message arriving while the reader sits still, which rebuilds the
        // headers with nothing scrolling afterwards to correct them.
        DispatchQueue.main.async { [weak self, weak tableView] in
            guard let self = self, let tableView = tableView else {
                return
            }
            self.refresh(in: tableView, animated: false)
        }
    }

    /// The list moved. `isDragging` is the finger: while it is down the date stays up, however
    /// long the reader holds still.
    ///
    /// Every movement re-arms the countdown, so this one call covers a fling's deceleration and
    /// a programmatic scroll as well - both of which move the list without ever telling anybody
    /// they have finished.
    func listDidMove(isDragging: Bool, in tableView: UITableView) {
        show(in: tableView)
        if isDragging {
            hideWork?.cancel()
            hideWork = nil
        } else {
            scheduleHide(in: tableView)
        }
    }

    /// The finger left the screen and nothing is still moving.
    func listDidSettle(in tableView: UITableView) {
        scheduleHide(in: tableView)
    }

    private func show(in tableView: UITableView) {
        hideWork?.cancel()
        hideWork = nil
        guard isPinnedHeaderHidden else {
            // Still worth a pass with no animation: which header floats changes as the list
            // moves, and one that has just stopped floating has to be given its place back.
            refresh(in: tableView, animated: false)
            return
        }
        isPinnedHeaderHidden = false
        refresh(in: tableView, animated: true, duration: DateHeaderVisibility.fadeIn)
    }

    private func scheduleHide(in tableView: UITableView) {
        hideWork?.cancel()
        let work = DispatchWorkItem { [weak self, weak tableView] in
            guard let self = self, let tableView = tableView, !self.isPinnedHeaderHidden else {
                return
            }
            self.isPinnedHeaderHidden = true
            self.refresh(in: tableView, animated: true, duration: DateHeaderVisibility.fadeOut)
        }
        hideWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + DateHeaderVisibility.lingerAfterScroll, execute: work)
    }

    /// Gives every header the alpha its own position asks for.
    private func refresh(in tableView: UITableView, animated: Bool, duration: TimeInterval = 0) {
        tracked.removeAll { $0.view == nil }
        var changes: [(UIView, CGFloat)] = []
        for item in tracked {
            guard let view = item.view, view.superview != nil else {
                continue
            }
            let wanted: CGFloat = (isPinnedHeaderHidden && isFloating(view, in: tableView)) ? 0 : 1
            if view.alpha != wanted {
                changes.append((view, wanted))
            }
        }
        guard !changes.isEmpty else {
            return
        }
        guard animated else {
            for (view, alpha) in changes {
                view.alpha = alpha
            }
            return
        }
        UIView.animate(withDuration: duration, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction]) {
            for (view, alpha) in changes {
                view.alpha = alpha
            }
        }
    }

    /// Whether a header has left its own place to hang at the top of the list.
    ///
    /// Fix: this used to ask the table where the section's first row is drawn. Asking a table
    /// whose rows size themselves for exact geometry makes it work that geometry out there and
    /// then: the guessed heights it is carrying are replaced by measured ones, the content
    /// height changes, and the list moves under whoever is reading it. And the question was
    /// asked from the scroll callback and again for every header the table built, so a chat
    /// being opened asked it dozens of times while its heights were still guesses - which is
    /// what made a freshly opened chat drop by a row and then recover.
    ///
    /// The same question is answered from what the table has already drawn. A header the table
    /// is holding at the top sits exactly on the line where the visible area begins; one that is
    /// where it belongs does not. Nothing has to be computed to see that.
    private func isFloating(_ header: UIView, in tableView: UITableView) -> Bool {
        let pinLine = tableView.contentOffset.y + tableView.adjustedContentInset.top
        return abs(header.frame.minY - pinLine) < 1
    }
}

final class ReadMoreTap: UITapGestureRecognizer {

    let messageId: String

    init(messageId: String, target: Any?, action: Selector?) {
        self.messageId = messageId
        super.init(target: target, action: action)
    }
}

// MARK: - Folding a very long message

/// The rule for folding a long message behind "Read more", in one place.
///
/// Four screens draw a message bubble - the two conversations, starred messages and message info -
/// and the rule has to be the same in all of them. It was written twice before this and the two
/// copies would have drifted at the first change to the limit.
public enum LongMessage {

    /// How many lines of a long message are shown before the rest is folded away.
    ///
    /// WhatsApp folds a long message rather than letting it run down the screen. The figure they
    /// publish is five lines, but that is for marketing messages, where cutting a stranger's
    /// advert short is the point of it; in a conversation it would fold perfectly ordinary
    /// messages. Fifty is about four screens of text - long enough that nothing anybody actually
    /// types gets folded, and short enough that a pasted document does.
    public static let lineLimit = 50
    /// Roughly what one line of a bubble holds. Only used to tell, without measuring anything,
    /// whether a message is certainly longer than the limit.
    private static let charactersPerLine = 34

    /// Messages the reader has asked to see in full. Kept here rather than on a screen so that
    /// opening a message on one screen leaves it open on the others.
    private static var expandedIds = Set<String>()
    private static let lock = NSLock()

    public static func expand(_ messageId: String) {
        lock.lock()
        expandedIds.insert(messageId)
        lock.unlock()
    }

    public static func isExpanded(_ messageId: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return expandedIds.contains(messageId)
    }

    /// Whether this message is long enough to be worth folding.
    ///
    /// Either it holds more characters than the limit could possibly show, or it already has that
    /// many line breaks in it - a short message written as fifty one-word lines is long on the
    /// screen even though it is nothing on the character count.
    public static func needsFolding(_ text: String) -> Bool {
        if text.count > lineLimit * charactersPerLine {
            return true
        }
        return text.filter({ $0 == "\n" }).count >= lineLimit
    }

    /// Whether this message is being shown folded at the moment.
    public static func isFolded(_ messageId: String, text: String) -> Bool {
        return !messageId.isEmpty && !isExpanded(messageId) && needsFolding(text)
    }

    /// The part of a long message that is shown while it is folded, cut at a word.
    public static func folded(_ text: String) -> String {
        let budget = lineLimit * charactersPerLine
        var cut = String(text.prefix(budget))
        // A cut in the middle of a word reads as a typo; back up to the last space or line break.
        if let breakPoint = cut.lastIndex(where: { $0 == " " || $0 == "\n" }),
           cut.distance(from: cut.startIndex, to: breakPoint) > budget / 2 {
            cut = String(cut[cut.startIndex..<breakPoint])
        }
        // Folding at a line break would otherwise leave a blank line under the text.
        return cut.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// The text to put in the bubble: the whole of it, or as much as the fold allows.
    public static func visibleText(_ text: String, messageId: String) -> String {
        return isFolded(messageId, text: text) ? folded(text) : text
    }

    /// The "Read more" that closes a folded message.
    public static func suffix(fontSize: CGFloat) -> NSAttributedString {
        return NSAttributedString(string: "\u{2026} " + "Read more".localized(),
                                  attributes: [.foregroundColor: UIColor.mainColor,
                                               .font: UIFont.systemFont(ofSize: fontSize, weight: .medium)])
    }
}

/// What the server allows a message to carry: how long the text may be, and how big a picture,
/// a video or a document may be.
///
/// Pulled from the server rather than decided here - see Nexilis.pullInstantMessaging - and kept
/// on the device so a send never has to wait for the network to find out. Every value falls back
/// to the same default the Android build uses, so the two behave alike when the server says
/// nothing: a thousand characters, 250 KB for a picture, two and a half megabytes for a video,
/// 250 KB for a document.
///
/// The numbers from the server are plain bytes for the three attachment kinds and a count of
/// characters for the text, which is how the server sends them.
public struct MessageLimits {

    /// What WhatsApp allows, which is what these fall back to when the server says nothing.
    ///
    /// A message runs to 65,536 characters there - effectively no limit for anything a person
    /// types. A picture or a video attached as media is capped at sixteen megabytes, and a file
    /// attached as a document at two gigabytes, because a document is sent whole while media is
    /// compressed on the way. The compressing is why a photo sent through WhatsApp lands at a
    /// few hundred kilobytes and not at the sixteen megabytes it is allowed: the ceiling is a
    /// ceiling, and the 1280-pixel pass below is what actually does the work.
    public static let defaultTextCharacters = 65_536
    public static let defaultImageBytes = 16 * 1024 * 1024
    public static let defaultVideoBytes = 16 * 1024 * 1024
    public static let defaultDocumentBytes = 2 * 1024 * 1024 * 1024

    /// How long the text of one message may be, in characters.
    public static var textCharacters: Int {
        return stored("subscription_text") ?? defaultTextCharacters
    }

    /// How big a picture may be once it has been compressed, in bytes.
    public static var imageBytes: Int {
        return stored("subscription_image") ?? defaultImageBytes
    }

    /// How big a video may be once it has been compressed, in bytes.
    public static var videoBytes: Int {
        return stored("subscription_video") ?? defaultVideoBytes
    }

    /// How big a document may be, in bytes. Documents are sent as they are, so this one is a
    /// limit rather than a target.
    public static var documentBytes: Int {
        return stored("subscription_document") ?? defaultDocumentBytes
    }

    /// A value the server sent, or nothing. Zero means "no limit set", the way it does on the
    /// Android side, and is treated as nothing.
    private static func stored(_ key: String) -> Int? {
        guard let raw: String = SecureUserDefaults.shared.value(forKey: key) else {
            return nil
        }
        guard let value = Double(raw.trimmingCharacters(in: .whitespaces)), value > 0 else {
            return nil
        }
        return Int(value)
    }

    static func store(_ raw: String, forKey key: String) {
        SecureUserDefaults.shared.set(raw, forKey: key)
    }

    /// "250 KB", "16 MB", "2 GB" - what an alert says the limit is.
    public static func readable(bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .binary
        formatter.isAdaptive = false
        return formatter.string(fromByteCount: Int64(bytes))
    }

    /// How big a file on disk is, or nothing if it cannot be measured.
    public static func fileSize(of url: URL) -> Int? {
        return (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize
    }

    /// Compresses a picture down to what the server allows a message to carry.
    ///
    /// The one implementation of this in the app - the conversation's attachment screen and the
    /// share sheet's hand-over both come here, so a picture sent from inside the app and one
    /// sent from another app come out the same.
    ///
    /// Fix: what was here aimed at a megabyte written into the code, and it went about it by
    /// re-encoding its own output at a fixed quality over and over. Re-encoding a JPEG that has
    /// already been through the encoder gives back a file of much the same size, so the loop
    /// either stopped making progress or ran until UIImage refused the data. Each attempt starts
    /// from the original picture now: quality first, because that costs the least to look at,
    /// then the size of the picture itself once quality alone cannot get there.
    public static func compressedImageData(_ image: UIImage, maxBytes: Int? = nil, maxDimension: CGFloat = 1280) -> Data? {
        let budget = maxBytes ?? imageBytes
        var dimension = maxDimension
        var best: Data?
        // Four rounds of taking a third off the longest edge is enough to bring anything a phone
        // can take under a quarter of a megabyte.
        for _ in 0..<4 {
            let resized = downscaled(image, maxDimension: dimension)
            for quality in [0.7, 0.55, 0.4, 0.28, 0.18] as [CGFloat] {
                guard let data = resized.jpegData(compressionQuality: quality) else {
                    continue
                }
                best = data
                if budget <= 0 || data.count <= budget {
                    return data
                }
            }
            dimension = (dimension * 0.7).rounded()
            if dimension < 240 {
                break
            }
        }
        // Nothing fitted. The smallest thing tried is still better than the original, and the
        // caller decides whether that is good enough to send.
        return best
    }

    /// The picture at no more than `maxDimension` on its longest edge, keeping its proportions.
    public static func downscaled(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        guard size.width > 0, size.height > 0,
              max(size.width, size.height) > maxDimension else {
            return image
        }
        let ratio = size.width / size.height
        let target = ratio > 1
            ? CGSize(width: maxDimension, height: (maxDimension / ratio).rounded())
            : CGSize(width: (maxDimension * ratio).rounded(), height: maxDimension)
        return UIGraphicsImageRenderer(size: target).image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
    }

    /// Whether a document on disk is bigger than the server allows.
    public static func exceedsDocumentLimit(_ url: URL) -> Bool {
        let limit = documentBytes
        guard limit > 0 else {
            return false
        }
        guard let size = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize else {
            // Nothing readable to measure - let the send itself deal with it.
            return false
        }
        return size > limit
    }

    /// Whether an edit to a text field keeps it inside the limit.
    ///
    /// Answered from what the field would hold afterwards, so a deletion is always allowed and a
    /// paste that would carry it over the line is refused whole - the way it reads better than
    /// silently keeping the first thousand characters of what someone pasted.
    public static func textFits(current: String, range: NSRange, replacement: String) -> Bool {
        let limit = textCharacters
        guard limit > 0 else {
            return true
        }
        let after = (current as NSString).length - range.length + (replacement as NSString).length
        return after <= limit
    }
}

/// The look of the list of names that drops in above the text field when a message is being
/// written with an "@" in it.
///
/// One place for what the two editors both have to agree on: how tall a row is, because the
/// height of the whole list is worked out from it, and the bot's picture, which used to be read
/// off disk and decoded again for every row of every redraw - and the list redraws on every
/// keystroke.
public struct ChatMentionList {

    /// The height of one row, and the unit the list's own height is counted in.
    public static let rowHeight: CGFloat = 44
    /// How wide the picture is drawn, in points.
    public static let avatarSize: CGFloat = 32

    /// The bot's picture, decoded once.
    ///
    /// Fix: this was a gif read with Data(contentsOf:) and decoded through CGImageSource inside
    /// cellForRow - on the main thread, for every row, on every reload, and the list reloads on
    /// every keystroke.
    public static let botAvatar: UIImage? = {
        let bundles = [Bundle.resourceBundle(for: Nexilis.self), Bundle.resourcesMediaBundle(for: Nexilis.self)]
        for bundle in bundles {
            guard let url = bundle.url(forResource: "pb_gpt_bot", withExtension: "gif"),
                  let data = try? Data(contentsOf: url),
                  let source = CGImageSourceCreateWithData(data as CFData, nil),
                  let frame = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
                continue
            }
            return UIImage(cgImage: frame).circleMasked
        }
        return nil
    }()
}

/// Reads audio that AVFoundation will not open, one layer down.
///
/// A voice note recorded on Android arrives as a bare AAC stream - MediaRecorder's `AAC_ADTS`,
/// written to a name ending `.aac` - and a bare stream carries no container. AVURLAsset chooses
/// its parser from the file's type, has none for a raw stream, and reports no audio track at all.
/// AudioFile will open the same bytes when it is told what they are, which is what the type hint
/// below is for; ExtAudioFile then hands back plain samples, converting as it goes.
///
/// Used as the fallback for the waveform and for the length. Playback never needed it:
/// AVAudioPlayer sniffs the bytes rather than the name, which is why these notes have always
/// played and shown their length while drawing an empty line.
enum RawAudioLevels {

    /// The formats worth guessing at, in order. Nothing is guessed until AVFoundation has already
    /// failed, so the cost of a wrong guess is one refused open.
    private static let hints: [AudioFileTypeID] = [
        kAudioFileAAC_ADTSType,
        kAudioFileM4AType,
        kAudioFileMPEG4Type,
        kAudioFileAMRType,
        kAudioFileMP3Type,
        0
    ]

    /// How many bars are worth reading. The view resamples whatever it is given, so this only has
    /// to be more than any bubble will draw.
    private static let wanted = 200
    /// What the samples are converted to on the way out: one channel, 16-bit, at a rate that
    /// every encoder can be resampled to.
    private static let clientRate: Double = 44_100

    /// The loudest point of each slice of the recording, from 0 to 1, or nothing if the file
    /// cannot be read this way either.
    static func measure(url: URL) -> [CGFloat] {
        guard let file = open(url) else {
            return []
        }
        defer {
            AudioFileClose(file)
        }
        var wrapped: ExtAudioFileRef?
        guard ExtAudioFileWrapAudioFileID(file, false, &wrapped) == noErr,
              let reader = wrapped else {
            return []
        }
        defer {
            ExtAudioFileDispose(reader)
        }
        var client = AudioStreamBasicDescription(
            mSampleRate: clientRate,
            mFormatID: kAudioFormatLinearPCM,
            mFormatFlags: kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked,
            mBytesPerPacket: 2,
            mFramesPerPacket: 1,
            mBytesPerFrame: 2,
            mChannelsPerFrame: 1,
            mBitsPerChannel: 16,
            mReserved: 0)
        guard ExtAudioFileSetProperty(reader,
                                      kExtAudioFileProperty_ClientDataFormat,
                                      UInt32(MemoryLayout<AudioStreamBasicDescription>.size),
                                      &client) == noErr else {
            return []
        }

        // How many samples belong to one bar. Worked out from the length the file reports, and
        // falling back to a fixed slice when it will not say - a stream with no header count is
        // exactly the case being handled here.
        let per = max(1, framesPerBar(reader))

        var loudest: [CGFloat] = []
        var peak: Int16 = 0
        var counted = 0
        let chunk = 4096
        var samples = [Int16](repeating: 0, count: chunk)
        while true {
            var frames = UInt32(chunk)
            var status = noErr
            samples.withUnsafeMutableBytes { raw in
                var list = AudioBufferList(
                    mNumberBuffers: 1,
                    mBuffers: AudioBuffer(mNumberChannels: 1,
                                          mDataByteSize: UInt32(raw.count),
                                          mData: raw.baseAddress))
                status = ExtAudioFileRead(reader, &frames, &list)
                guard status == noErr, frames > 0 else {
                    return
                }
                // Read here, inside the borrow, rather than off the array afterwards.
                let values = raw.bindMemory(to: Int16.self)
                for index in 0..<Int(frames) {
                    let level = Int16(clamping: Int(values[index].magnitude))
                    if level > peak {
                        peak = level
                    }
                    counted += 1
                    if counted >= per {
                        loudest.append(CGFloat(peak) / CGFloat(Int16.max))
                        peak = 0
                        counted = 0
                    }
                }
            }
            guard status == noErr, frames > 0 else {
                break
            }
        }
        // Whatever is left of the last, part-filled slice still belongs to the line.
        if counted > 0 {
            loudest.append(CGFloat(peak) / CGFloat(Int16.max))
        }
        guard !loudest.isEmpty else {
            return []
        }
        // Lifted the same way the AVFoundation path lifts it: speech rarely reaches full scale,
        // and without this every voice note looks like a whisper.
        let top = loudest.max() ?? 1
        let lift = top > 0.01 ? min(4, 0.95 / top) : 1
        return loudest.map { min(1, max(0.07, $0 * lift)) }
    }

    /// How long the recording runs, in seconds, or nothing if it cannot be read.
    static func seconds(url: URL) -> Int? {
        guard let file = open(url) else {
            return nil
        }
        defer {
            AudioFileClose(file)
        }
        var format = AudioStreamBasicDescription()
        var formatSize = UInt32(MemoryLayout<AudioStreamBasicDescription>.size)
        guard AudioFileGetProperty(file, kAudioFilePropertyDataFormat, &formatSize, &format) == noErr,
              format.mSampleRate > 0 else {
            return nil
        }
        var frames: Int64 = 0
        var framesSize = UInt32(MemoryLayout<Int64>.size)
        guard AudioFileGetProperty(file, kAudioFilePropertyAudioDataPacketCount, &framesSize, &frames) == noErr else {
            return nil
        }
        let perPacket = format.mFramesPerPacket > 0 ? Double(format.mFramesPerPacket) : 1024
        let length = Int((Double(frames) * perPacket / format.mSampleRate).rounded())
        return length > 0 ? length : nil
    }

    private static func open(_ url: URL) -> AudioFileID? {
        for hint in hints {
            var file: AudioFileID?
            if AudioFileOpenURL(url as CFURL, .readPermission, hint, &file) == noErr, let file = file {
                return file
            }
        }
        return nil
    }

    /// The number of converted samples one bar of the line stands for.
    private static func framesPerBar(_ reader: ExtAudioFileRef) -> Int {
        var frames: Int64 = 0
        var framesSize = UInt32(MemoryLayout<Int64>.size)
        guard ExtAudioFileGetProperty(reader, kExtAudioFileProperty_FileLengthFrames, &framesSize, &frames) == noErr,
              frames > 0 else {
            // A quarter of a second a bar: for anything up to about a minute that lands near
            // enough, and the view resamples what it is handed anyway.
            return Int(clientRate / 4)
        }
        var source = AudioStreamBasicDescription()
        var sourceSize = UInt32(MemoryLayout<AudioStreamBasicDescription>.size)
        guard ExtAudioFileGetProperty(reader, kExtAudioFileProperty_FileDataFormat, &sourceSize, &source) == noErr,
              source.mSampleRate > 0 else {
            return max(1, Int(frames) / wanted)
        }
        // The count the file reports is in its own samples; the bars are counted in converted ones.
        let converted = Double(frames) * clientRate / source.mSampleRate
        return max(1, Int(converted) / wanted)
    }
}

extension Utils {

    /// The line a quote shows for whatever a message was carrying.
    ///
    /// Fix: each of the six places that draw a quote worked its own way through the same chain of
    /// tests, and the chain began with "no attachment flag and no thumbnail, so this is plain
    /// text". That test is far looser than it reads: a message whose flag happens to be 0 or blank
    /// - which is every attachment saved by a path that did not set one - was answered with its
    /// own message text, and a document's message text is a filename and a caption joined by a
    /// bar, or nothing at all. So a reply to a document drew a quote with nothing in it. The same
    /// shape of gap has now been found three times, once for voice notes, once for animated
    /// pictures and once for documents, because the chain is written out six times over.
    ///
    /// What a message carries is decided here, once, from the slots rather than from the flag -
    /// the slots are filled by whoever sent it and the flag is not. Returns nil only when the
    /// message really is plain text, which is the caller's own business to render, because each of
    /// the six draws mentions and links its own way.
    public static func quotedAttachmentLine(attachmentFlag: String,
                                            thumb: String,
                                            image: String,
                                            video: String,
                                            file: String,
                                            audio: String,
                                            gif: String,
                                            messageText: String,
                                            font: UIFont,
                                            colour: UIColor) -> NSAttributedString? {
        let caption = messageText.trimmingCharacters(in: .whitespacesAndNewlines)

        if !audio.isEmpty || attachmentFlag == "60" {
            return audioPreviewLine(attachmentFlag: attachmentFlag,
                                    audioName: audio,
                                    font: font,
                                    colour: colour)
        }
        if !gif.isEmpty {
            return plain(caption.isEmpty ? "🎬 GIF" : caption, font: font, colour: colour)
        }
        if !image.isEmpty || attachmentFlag == "1" {
            return caption.isEmpty ? plain("📷 " + "Photo".localized(), font: font, colour: colour) : nil
        }
        if !video.isEmpty || attachmentFlag == "2" {
            if caption.isEmpty {
                if let note = VideoNote.quotedLine(videoId: video, font: font, colour: colour) {
                    return note
                }
                return plain("📹 " + "Video".localized(), font: font, colour: colour)
            }
            return nil
        }
        if !file.isEmpty || attachmentFlag == "6" {
            // The document, and then whatever was written with it. The label above this is capped
            // at three lines, so a long name takes two of them and the caption what is left -
            // which is the shape asked for: the sender, the document, and what they said about it.
            var line = "📄 " + documentName(messageText: messageText, file: file)
            let written = messageText.component(1, separatedBy: "|")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !written.isEmpty {
                line += "\n" + written
            }
            return plain(line, font: font, colour: colour)
        }
        switch attachmentFlag {
        case "11":
            return plain("❤️ " + "Sticker".localized(), font: font, colour: colour)
        case "27":
            return plain("📄 " + "Live Streaming".localized(), font: font, colour: colour)
        case "26":
            return plain("📄 " + "Seminar".localized(), font: font, colour: colour)
        case "25":
            return plain("📄 " + "Video Conference Room".localized(), font: font, colour: colour)
        default:
            break
        }
        // Nothing carried and nothing written: a quote with nothing in it is what the reader was
        // shown, and saying so is better than a blank box.
        if caption.isEmpty, !thumb.isEmpty {
            return plain("📷 " + "Photo".localized(), font: font, colour: colour)
        }
        return caption.isEmpty ? plain("Message".localized(), font: font, colour: colour) : nil
    }

    /// What to call a document in a quote.
    ///
    /// The text of a document message is its filename and its caption joined by a bar, which is
    /// this app's own convention - a document from elsewhere may carry only a caption, or nothing.
    /// The name it was saved under is the last resort, with the prefix this app adds to every
    /// attachment taken off.
    /// What a document message is called.
    ///
    /// The name lives at the front of message_text, as "name|caption" - that is how iOS sends a
    /// document and how Android used to send one. When it is not there, the stored file id is the
    /// next best thing, and it usually carries the original name inside it.
    public static func documentName(messageText: String, file: String) -> String {
        // Fix: the part before the bar was taken as the name whether or not there *was* a bar - and
        // with no bar, that part is the whole message text, which is the caption. So a document sent
        // with a few paragraphs written alongside it was named after those paragraphs: the card
        // showed the first line and a half of a release note where the file name belongs, the badge
        // printed four letters of a word from the middle of it, and the type read TXT because the
        // text happened to end in a sentence rather than an extension. The bar is what makes the
        // front half a name; without one there is no name in the message text at all, and the file
        // itself is what to ask.
        if messageText.contains("|") {
            let written = messageText.components(separatedBy: "|")[0]
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !written.isEmpty {
                return written
            }
        }
        guard !file.isEmpty else {
            // Nothing to go on: not the message, not a file. Whatever was written is better than
            // nothing at all.
            let written = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
            return written.isEmpty ? "Document".localized() : written
        }
        // "Nexilis_1757000000000_report.xlsx" is stored; "report.xlsx" is what it is called.
        var name = file
        let parts = file.components(separatedBy: "_")
        if parts.count > 2, parts[0] == "Nexilis" {
            name = parts.dropFirst(2).joined(separator: "_")
        }
        return withoutStoredSuffix(name)
    }

    /// A stored name carries an id the server hung on the end of it - "report-1A06B520A5D.xlsx" -
    /// and that is machine bookkeeping rather than part of what anybody called the file.
    ///
    /// Taken off only when it is unmistakably that: a dash, then eight to sixteen upper-case
    /// hexadecimal digits, then the extension and nothing else. A name that genuinely ends that way
    /// is not something anybody types.
    private static func withoutStoredSuffix(_ name: String) -> String {
        let parts = name.split(separator: ".")
        guard parts.count > 1, let extensionPart = parts.last else {
            return name
        }
        let stem = parts.dropLast().joined(separator: ".")
        guard let dash = stem.lastIndex(of: "-") else {
            return name
        }
        let suffix = stem[stem.index(after: dash)...]
        // At least one of A to F in it, so a run of digits alone is left alone: "report-20260904"
        // is a date somebody wrote, and eight digits are perfectly good hexadecimal.
        guard suffix.count >= 8, suffix.count <= 16,
              suffix.allSatisfy({ $0.isHexDigit && !$0.isLowercase }),
              suffix.contains(where: { $0.isLetter }) else {
            return name
        }
        let kept = String(stem[stem.startIndex..<dash]).trimmingCharacters(in: .whitespaces)
        return kept.isEmpty ? name : "\(kept).\(extensionPart)"
    }

    /// A document's own extension, lower case, or nothing when its name has none.
    ///
    /// Kept apart from documentType(named:), which answers what to *write* beside the size and so
    /// has opinions - a long tail becomes TXT, no dot at all becomes FILE. The badge needs the
    /// extension itself, to know what colour the thing is.
    public static func documentExtension(of name: String) -> String {
        let parts = name.split(separator: ".")
        guard parts.count > 1, let last = parts.last else {
            return ""
        }
        let tail = last.lowercased()
        // Fix: whatever followed the last dot was taken as the extension. A document's name is
        // often a sentence with dots in it - a release note, a date, a numbered list - so the tail
        // was a word, and four letters of that word were printed on the badge. A name that carries
        // no extension has to be allowed to say so, and an extension is short and has no spaces or
        // punctuation in it.
        guard tail.count <= 5, tail.allSatisfy({ $0.isLetter || $0.isNumber }) else {
            return ""
        }
        return tail
    }

    /// What a document is, from its name where the name says and from the file's own first bytes
    /// where it does not.
    public static func documentKind(named name: String, file: String) -> String {
        let fromName = documentExtension(of: name)
        if !fromName.isEmpty {
            return fromName
        }
        return DocumentBadge.sniffedKind(ofFileNamed: file)
    }

    /// What the line under a document's name calls its type.
    public static func documentType(of kind: String) -> String {
        return kind.isEmpty ? "FILE" : kind.uppercased()
    }

    /// The type shown beside a document's size: its own extension, in capitals.
    ///
    /// Fix: every screen worked this out as "split the name on a dot and take the last piece",
    /// which answers with the whole name when there is no dot in it - so a document that arrived
    /// without a name was labelled with whatever scrap of text was in its place. Worse, the same
    /// line indexed that split at count - 1 without looking, and splitting an empty name gives an
    /// empty list: a document with no name at all took the app down rather than drawing plainly.
    public static func documentType(named name: String) -> String {
        // Fix: anything longer than four characters was called TXT. That rule was inherited, and it
        // manufactures a fact: a spreadsheet whose name ends in a word was labelled a text file, in
        // a line that reads as though the app knows. Saying FILE says the truth - that the name
        // does not say - and where the file itself is at hand, documentKind(named:file:) asks it.
        return documentType(of: documentExtension(of: name))
    }

    private static func plain(_ text: String, font: UIFont, colour: UIColor) -> NSAttributedString {
        return NSAttributedString(string: text, attributes: [.font: font, .foregroundColor: colour])
    }
}

/// The panel a quote sits on inside a bubble, and the colours to write on it.
///
/// The document card is that same panel by design - the reader should read them as one kind of
/// thing tucked inside a bubble - so both ask here rather than each carrying its own literal.
public enum BubblePanel {

    /// Dark mode turns the overlay over. WhatsApp's dark bubble is a deep green, so lifting it
    /// still leaves somewhere dark to write on; ours is a bright blue (#367dd9), and lifting that
    /// leaves white text at 2.2:1 - unreadable. Darkening instead moves the panel away from the
    /// bubble the same way, and the text goes to 87% for the same reason WhatsApp can afford 60%
    /// and we cannot.
    public static func ground(dark: Bool) -> UIColor {
        return dark ? .black.withAlphaComponent(0.22) : UIColor(white: 0.784, alpha: 0.22)
    }

    public static func text(dark: Bool) -> UIColor {
        return dark ? .white.withAlphaComponent(0.87) : .black.withAlphaComponent(0.77)
    }

    /// What is written under the name - the size and the type - which is the same text one step
    /// quieter.
    public static func secondaryText(dark: Bool) -> UIColor {
        return dark ? .white.withAlphaComponent(0.62) : .black.withAlphaComponent(0.55)
    }
}

/// The little page a document wears, in the colour of its own kind with its extension written on
/// it.
///
/// Fix: every document, whatever it was, wore the same grey page glyph. A folder of attachments
/// was a column of identical grey marks, and the only way to tell a spreadsheet from a slide deck
/// was to read the file name. WhatsApp gives each kind its own colour and writes the extension on
/// the page, and that is what is drawn here.
///
/// The colours are the ones every platform shares for these types - the red of a PDF, the blue of
/// a Word file, the green of a spreadsheet, the orange of a deck. A web search turned up no
/// published values for WhatsApp's own set, so these are matched to the conventions rather than
/// sampled from it.
public enum DocumentBadge {

    private static let palette: [String: UInt32] = [
        "pdf": 0xD7373F,
        "doc": 0x2B579A, "docx": 0x2B579A, "rtf": 0x2B579A, "odt": 0x2B579A, "pages": 0x2B579A,
        "xls": 0x217346, "xlsx": 0x217346, "xlsm": 0x217346, "csv": 0x217346, "ods": 0x217346,
        "numbers": 0x217346,
        "ppt": 0xC43E1C, "pptx": 0xC43E1C, "odp": 0xC43E1C, "key": 0xC43E1C,
        "txt": 0x6B7A85, "log": 0x6B7A85, "md": 0x6B7A85,
        "zip": 0x8A6D3B, "rar": 0x8A6D3B, "7z": 0x8A6D3B, "tar": 0x8A6D3B, "gz": 0x8A6D3B,
        "mp3": 0x8250A8, "wav": 0x8250A8, "m4a": 0x8250A8, "aac": 0x8250A8, "ogg": 0x8250A8,
        "mp4": 0x2A7B9B, "mov": 0x2A7B9B, "avi": 0x2A7B9B, "mkv": 0x2A7B9B, "3gp": 0x2A7B9B,
        "html": 0xE44D26, "htm": 0xE44D26,
        "json": 0x565F89, "xml": 0x565F89, "yml": 0x565F89, "yaml": 0x565F89,
        "apk": 0x3B8F52, "ipa": 0x555B63, "exe": 0x555B63, "dmg": 0x555B63
    ]

    /// The grey this screen drew every document in, kept for the kinds that have no colour of
    /// their own.
    private static let unknown: UInt32 = 0x798F9A

    private static var drawn: [String: UIImage] = [:]
    private static let lock = NSLock()

    private static var sniffed: [String: String] = [:]

    /// What a file itself says it is, read from its first few thousand bytes and remembered.
    ///
    /// Asked only when the name does not say. A name is the cheap answer and usually the right
    /// one; this is for the documents that arrive named after their contents rather than their
    /// format - which is most of the ones people write by hand.
    ///
    /// Only a plain copy on disk is read. Reading one out of the secure store means decrypting the
    /// whole file, which is not a price a row being drawn should pay; those keep to what the name
    /// says.
    public static func sniffedKind(ofFileNamed file: String) -> String {
        guard !file.isEmpty else {
            return ""
        }
        lock.lock()
        let known = sniffed[file]
        lock.unlock()
        if let known = known {
            return known
        }
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(file)
        var kind = ""
        if let handle = try? FileHandle(forReadingFrom: url) {
            let head = (try? handle.read(upToCount: 4096)) ?? Data()
            try? handle.close()
            kind = kindOf(head)
        }
        lock.lock()
        sniffed[file] = kind
        lock.unlock()
        return kind
    }

    private static func kindOf(_ head: Data) -> String {
        let bytes = [UInt8](head.prefix(8))
        guard bytes.count >= 4 else {
            return ""
        }
        if bytes.starts(with: [0x25, 0x50, 0x44, 0x46]) { return "pdf" }
        if bytes.starts(with: [0x89, 0x50, 0x4E, 0x47]) { return "png" }
        if bytes.starts(with: [0xFF, 0xD8, 0xFF]) { return "jpg" }
        if bytes.starts(with: [0x47, 0x49, 0x46]) { return "gif" }
        if bytes.starts(with: [0x52, 0x61, 0x72, 0x21]) { return "rar" }
        if bytes.starts(with: [0x37, 0x7A, 0xBC, 0xAF]) { return "7z" }
        if bytes.starts(with: [0x49, 0x44, 0x33]) { return "mp3" }
        if head.count >= 8, Array(head[4..<8]) == Array("ftyp".utf8) { return "mp4" }
        if bytes.starts(with: [0x50, 0x4B, 0x03, 0x04]) {
            // A spreadsheet, a document and a deck are all zips, and what tells them apart is the
            // name of the folder their first entries sit in - which is right at the front of the
            // file, in with the header this has already read.
            let text = String(decoding: head, as: UTF8.self)
            if text.contains("xl/") { return "xlsx" }
            if text.contains("word/") { return "docx" }
            if text.contains("ppt/") { return "pptx" }
            return "zip"
        }
        return ""
    }

    public static func colour(of extensionText: String) -> UIColor {
        let key = extensionText.lowercased()
        let hex = palette[key] ?? unknown
        return UIColor(red: CGFloat((hex >> 16) & 0xFF) / 255,
                       green: CGFloat((hex >> 8) & 0xFF) / 255,
                       blue: CGFloat(hex & 0xFF) / 255,
                       alpha: 1)
    }

    /// What is written on the page. Four characters is what fits, and every extension worth
    /// naming fits in four.
    public static func label(of extensionText: String) -> String {
        let trimmed = extensionText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return "FILE"
        }
        return String(trimmed.prefix(4)).uppercased()
    }

    /// The page itself: a rounded leaf in the kind's colour with a corner turned down and the
    /// extension across the foot. Drawn once per kind and size, and kept.
    public static func image(of extensionText: String, size: CGSize) -> UIImage {
        let key = "\(label(of: extensionText))-\(Int(size.width))x\(Int(size.height))"
        lock.lock()
        let known = drawn[key]
        lock.unlock()
        if let known = known {
            return known
        }
        let colour = colour(of: extensionText)
        let text = label(of: extensionText)
        let image = UIGraphicsImageRenderer(size: size).image { context in
            let fold = min(size.width, size.height) * 0.34
            let radius: CGFloat = 3
            // The leaf, with the top-right corner cut away where it is turned down.
            let page = UIBezierPath()
            page.move(to: CGPoint(x: radius, y: 0))
            page.addLine(to: CGPoint(x: size.width - fold, y: 0))
            page.addLine(to: CGPoint(x: size.width, y: fold))
            page.addLine(to: CGPoint(x: size.width, y: size.height - radius))
            page.addQuadCurve(to: CGPoint(x: size.width - radius, y: size.height),
                              controlPoint: CGPoint(x: size.width, y: size.height))
            page.addLine(to: CGPoint(x: radius, y: size.height))
            page.addQuadCurve(to: CGPoint(x: 0, y: size.height - radius),
                              controlPoint: CGPoint(x: 0, y: size.height))
            page.addLine(to: CGPoint(x: 0, y: radius))
            page.addQuadCurve(to: CGPoint(x: radius, y: 0), controlPoint: .zero)
            page.close()
            colour.setFill()
            page.fill()
            // The corner, turned down: the same colour lightened, the way a folded sheet catches
            // more light than the face of it.
            let turned = UIBezierPath()
            turned.move(to: CGPoint(x: size.width - fold, y: 0))
            turned.addLine(to: CGPoint(x: size.width - fold, y: fold))
            turned.addLine(to: CGPoint(x: size.width, y: fold))
            turned.close()
            UIColor.white.withAlphaComponent(0.38).setFill()
            turned.fill()
            // And the extension across the foot of it.
            let font = UIFont.systemFont(ofSize: max(7, size.height * 0.27), weight: .heavy)
            let written = NSAttributedString(string: text, attributes: [
                .font: font,
                .foregroundColor: UIColor.white,
                .kern: -0.3
            ])
            var bounds = written.boundingRect(with: size, options: [.usesLineFragmentOrigin], context: nil)
            // Squeezed to fit rather than clipped: a four-letter extension on a small page is
            // wider than the page, and half a word is worse than a small one.
            if bounds.width > size.width - 4 {
                let squeezed = UIFont.systemFont(ofSize: font.pointSize * (size.width - 4) / bounds.width,
                                                 weight: .heavy)
                let refitted = NSAttributedString(string: text, attributes: [
                    .font: squeezed, .foregroundColor: UIColor.white, .kern: -0.3
                ])
                bounds = refitted.boundingRect(with: size, options: [.usesLineFragmentOrigin], context: nil)
                refitted.draw(at: CGPoint(x: (size.width - bounds.width) / 2,
                                          y: size.height - bounds.height - size.height * 0.13))
                return
            }
            written.draw(at: CGPoint(x: (size.width - bounds.width) / 2,
                                     y: size.height - bounds.height - size.height * 0.13))
        }
        lock.lock()
        drawn[key] = image
        lock.unlock()
        return image
    }
}

// MARK: - Link previews

/// Which hosts this app pins, and which are simply the public web.
///
/// Fix: the one session delegate this app had refuses any host it holds no pin for, and the pin
/// map holds the app's own servers. That is right for the app's own servers and impossible
/// anywhere else - nobody can pin techcrunch.com - so a link preview asked for a page and had the
/// connection cancelled before a byte of it arrived, and the picture the card wanted was
/// cancelled the same way. Pinning is kept exactly where a pin exists; everywhere else the
/// system's own trust store answers, which is what it is for.
final class PublicWebTrustDelegate: NSObject, URLSessionTaskDelegate, URLSessionDataDelegate {

    private let pinned = PinnedURLSessionNexilisDelegate()

    static func isPinned(host: String) -> Bool {
        // Sentinel remediation (NX-14): the mutable preference map this used to read is gone.
        // RASPGuard holds the same answer and is the one nobody can edit from the device.
        guard !host.isEmpty else { return false }
        return RASPGuard.shared().isPinnedHost(host.lowercased())
    }

    /// A session for reading public pages and pictures: pinned where the app has a pin, the
    /// system's own trust everywhere else.
    static func session(timeout: TimeInterval = 15) -> URLSession {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeout
        config.requestCachePolicy = .returnCacheDataElseLoad
        return URLSession(configuration: config,
                          delegate: PublicWebTrustDelegate(),
                          delegateQueue: nil)
    }

    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition,
                                                  URLCredential?) -> Void) {
        if PublicWebTrustDelegate.isPinned(host: challenge.protectionSpace.host) {
            pinned.urlSession(session, didReceive: challenge, completionHandler: completionHandler)
            return
        }
        completionHandler(.performDefaultHandling, nil)
    }
}

/// What a link turns out to be, once the page behind it has been read.
///
/// Fix: a link in a message was drawn as an eighty-point strip with a small square picture at its
/// left, whatever the link was, and most of the time there was no picture in it at all. Why there
/// is always one in WhatsApp's card is worth writing down, because it is the whole of this: a site
/// does not hand its title and its picture to whoever asks, it publishes them as Open Graph tags -
/// og:title, og:description, og:image - in a page it serves to link-unfurling crawlers. Instagram,
/// Facebook and their like serve a bare application shell to anything that looks like a browser
/// and the tags only to a crawler; the framework this app asked with sent the default URLSession
/// user agent, which looks like neither, so nothing came back. Asked as a crawler, the same page
/// comes back with the tags on it - and for a video, with og:video and its duration, which is how
/// a card can say "Reels 2:23" without playing anything.
public struct LinkPreviewFacts {

    public var link = ""
    public var title = ""
    public var blurb = ""
    public var imageUrl = ""
    public var imageSize = CGSize.zero
    public var iconUrl = ""
    public var siteName = ""
    /// "Reels", "Shorts", "TikTok", "Video" - empty when the link is not a video at all.
    public var videoLabel = ""
    public var seconds = 0

    public init() {}

    public var isVideo: Bool {
        return !videoLabel.isEmpty
    }

    /// What is written on the last line of the card: the site, as short as it can be said.
    public var domain: String {
        var host = URL(string: link)?.host ?? ""
        if host.isEmpty {
            host = link.components(separatedBy: "/").first ?? link
        }
        if host.lowercased().hasPrefix("www.") {
            host = String(host.dropFirst(4))
        }
        return host.lowercased()
    }

    /// Nothing came back that is worth drawing a card for.
    public var isEmpty: Bool {
        return title.isEmpty && imageUrl.isEmpty
    }

    /// The picture is big enough to be the card rather than a thumbnail beside it. A site icon or
    /// a small logo is not, and WhatsApp keeps those to the left of the title; so does this. A
    /// picture whose size never came back is treated as small, because a card built around a
    /// picture that turns out to be a favicon is worse than a row with a favicon in it.
    public var hasLargePicture: Bool {
        guard !imageUrl.isEmpty else {
            return false
        }
        return min(imageSize.width, imageSize.height) >= 200
    }

    /// How tall the picture is against its width, as the card will draw it.
    public var pictureRatio: CGFloat {
        guard imageSize.width > 0, imageSize.height > 0 else {
            return 0.524
        }
        return imageSize.height / imageSize.width
    }

    /// The duration as a card writes it: 2:23, or 1:02:23 for the long ones.
    public var spokenDuration: String {
        guard seconds > 0 else {
            return ""
        }
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%d:%02d", m, s)
    }
}

/// The LINK_PREVIEW table, read and written in one place.
///
/// The three keys the rest of the app already reads - title, description, imageUrl - are written
/// exactly as they were, so the starred list, the search results and the chat list preview keep
/// working off the same row. What is new sits alongside them under a version, and a row without
/// that version is read as absent so it is fetched again: the rows already on a device were
/// written without a crawler's user agent and are mostly a title and nothing else.
public enum LinkPreviewStore {

    static let version = 2

    private static func quoted(_ text: String) -> String {
        return text.replacingOccurrences(of: "'", with: "''")
    }

    public static func json(of facts: LinkPreviewFacts) -> String? {
        var body: [String: Any] = [:]
        body["v"] = version
        body["title"] = facts.title
        body["description"] = facts.blurb
        body["imageUrl"] = facts.imageUrl
        body["link"] = facts.link
        body["imageWidth"] = Int(facts.imageSize.width)
        body["imageHeight"] = Int(facts.imageSize.height)
        body["iconUrl"] = facts.iconUrl
        body["siteName"] = facts.siteName
        body["videoLabel"] = facts.videoLabel
        body["seconds"] = facts.seconds
        guard let data = try? JSONSerialization.data(withJSONObject: body, options: []) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    /// What the table has to say about a link. "Nothing on it" has to be told apart from "not
    /// asked yet", or a page that turns out to have no title and no picture would be asked for
    /// again every time a row carrying it is built.
    public enum Answer {
        case notAsked
        case nothingOnIt
        case read(LinkPreviewFacts)
    }

    public static func answer(link: String) -> Answer {
        return answer(fromJSON: readRow(link: link))
    }

    public static func answer(fromJSON text: String) -> Answer {
        guard !text.isEmpty,
              let data = text.data(using: .utf8),
              let body = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any],
              (body["v"] as? Int) == version else {
            return .notAsked
        }
        guard let facts = facts(fromBody: body) else {
            return .nothingOnIt
        }
        return .read(facts)
    }

    /// The facts held in a stored row, or nil when there is nothing usable in it - which covers a
    /// row from before this version, a row that says the page had nothing on it, and a row whose
    /// picture the old code would have thrown away.
    public static func facts(fromJSON text: String) -> LinkPreviewFacts? {
        guard !text.isEmpty,
              let data = text.data(using: .utf8),
              let body = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any],
              (body["v"] as? Int) == version else {
            return nil
        }
        return facts(fromBody: body)
    }

    private static func facts(fromBody body: [String: Any]) -> LinkPreviewFacts? {
        if (body["none"] as? Bool) == true {
            return nil
        }
        var facts = LinkPreviewFacts()
        facts.link = body["link"] as? String ?? ""
        facts.title = body["title"] as? String ?? ""
        facts.blurb = body["description"] as? String ?? ""
        facts.imageUrl = body["imageUrl"] as? String ?? ""
        facts.iconUrl = body["iconUrl"] as? String ?? ""
        facts.siteName = body["siteName"] as? String ?? ""
        facts.videoLabel = body["videoLabel"] as? String ?? ""
        facts.seconds = body["seconds"] as? Int ?? 0
        let w = CGFloat(body["imageWidth"] as? Int ?? 0)
        let h = CGFloat(body["imageHeight"] as? Int ?? 0)
        facts.imageSize = CGSize(width: w, height: h)
        return facts.isEmpty ? nil : facts
    }

    /// The row for a link as it stands, without touching the network.
    public static func stored(link: String) -> LinkPreviewFacts? {
        return facts(fromJSON: readRow(link: link))
    }

    private static func readRow(link: String) -> String {
        var text = ""
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            if let cursor = Database.shared.getRecords(
                fmdb: fmdb,
                query: "select data_link from LINK_PREVIEW where link='\(quoted(link))'"), cursor.next() {
                text = cursor.string(forColumnIndex: 0) ?? ""
                cursor.close()
            }
        })
        return text
    }

    static func write(_ facts: LinkPreviewFacts) {
        guard let json = json(of: facts) else {
            return
        }
        keep(link: facts.link, json: json)
    }

    /// A page that had nothing on it is remembered as such, so twenty cells asking about the same
    /// link do not each go and ask the internet again.
    static func writeNothing(link: String) {
        var body: [String: Any] = ["v": version, "none": true, "link": link]
        body["title"] = ""
        body["description"] = ""
        guard let data = try? JSONSerialization.data(withJSONObject: body, options: []),
              let json = String(data: data, encoding: .utf8) else {
            return
        }
        keep(link: link, json: json)
    }

    private static func keep(link: String, json: String) {
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            do {
                _ = try Database.shared.insertRecord(fmdb: fmdb, table: "LINK_PREVIEW", cvalues: [
                    "id": "\(Date().currentTimeMillis().toHex())",
                    "link": link,
                    "data_link": json,
                    "retry": 0
                ], replace: true)
            } catch {
                rollback.pointee = true
            }
        })
    }
}

/// Reads the page behind a link the way a link-unfurling crawler reads it.
public enum LinkPreviewFetcher {

    /// The one thing that decides whether a card has a picture on it. See LinkPreviewFacts: a
    /// browser's user agent gets the application shell, an app's gets the same, and a crawler's
    /// gets the Open Graph tags. This one says plainly what it is and where it comes from.
    private static let crawler = "Mozilla/5.0 (compatible; OneAppBot/1.0; +https://nexilis.io)"

    /// The second way of asking, for the sites that refuse the first. See fetch(link:then:).
    private static let browser = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) "
        + "AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"

    private static var inFlight = Set<String>()
    private static let lock = NSLock()

    /// Asks once per link, however many rows want it, and calls back on the main queue. The flag
    /// says whether there is anything new to draw.
    ///
    /// Fix: it used to call back either way, and a screen that rebuilt its row on being called
    /// rebuilt it for nothing whenever a page turned out to have nothing on it - which for a
    /// restricted Google Drive link is every time. Rebuilding a row in a self-sizing list
    /// re-measures it, and re-measuring rows moves the content under the reader: a conversation
    /// full of Drive links jumped a second or two after it opened, with no card to show for it.
    public static func fetch(link: String, then: @escaping (Bool) -> Void) {
        lock.lock()
        if inFlight.contains(link) {
            lock.unlock()
            return
        }
        inFlight.insert(link)
        lock.unlock()

        func finish(_ gained: Bool) {
            lock.lock()
            inFlight.remove(link)
            lock.unlock()
            DispatchQueue.main.async {
                then(gained)
            }
        }

        guard let url = address(of: link) else {
            LinkPreviewStore.writeNothing(link: link)
            finish(false)
            return
        }

        // The card's shape follows the picture's shape, so the picture is measured before the
        // card is ever drawn - a card built at one size and then filled with a picture of another
        // shape is a card that jumps. Sites that publish og:image:width have already answered
        // this and are taken at their word.
        func keep(_ facts: LinkPreviewFacts) {
            guard facts.imageSize == .zero, !facts.imageUrl.isEmpty else {
                LinkPreviewStore.write(facts)
                finish(true)
                return
            }
            var measured = facts
            LinkPreviewImage.fetch(facts.imageUrl) { image in
                if let image = image, image.size.width > 0 {
                    measured.imageSize = image.size
                }
                // The picture is answered on the main queue; writing a row is not something to do
                // there.
                DispatchQueue.global(qos: .utility).async {
                    LinkPreviewStore.write(measured)
                    finish(true)
                }
            }
        }

        // Fix: there are two families of site and they want opposite things. Instagram, Facebook
        // and Threads hand the Open Graph tags to a crawler and a bare application shell to
        // anything that looks like a browser; LinkedIn and everything behind a scraping defence
        // do the reverse and answer a crawler with a refusal - LinkedIn answers 999 - while a
        // browser gets the public page with the tags on it. So the page is asked for plainly
        // first, as what this is; only when that comes back with nothing at all is it asked for
        // again the way a browser would ask, which is the one thing those sites will answer.
        ask(url, as: crawler) { html, landed in
            if let html = html, let landed = landed {
                let facts = read(html: html, link: link, landedOn: landed)
                if !facts.isEmpty {
                    keep(facts)
                    return
                }
            }
            ask(url, as: browser) { second, landedAgain in
                // A page that could not be reached is not a page with nothing on it: nothing is
                // written down, so the next row carrying this link asks again.
                guard let second = second, let landedAgain = landedAgain else {
                    finish(false)
                    return
                }
                let facts = read(html: second, link: link, landedOn: landedAgain)
                guard !facts.isEmpty else {
                    LinkPreviewStore.writeNothing(link: link)
                    finish(false)
                    return
                }
                keep(facts)
            }
        }
    }

    private static func ask(_ url: URL, as agent: String, then: @escaping (String?, URL?) -> Void) {
        var request = URLRequest(url: url)
        request.setValue(agent, forHTTPHeaderField: "User-Agent")
        request.setValue("text/html,application/xhtml+xml,*/*;q=0.8", forHTTPHeaderField: "Accept")
        request.setValue(Locale.preferredLanguages.first ?? "en", forHTTPHeaderField: "Accept-Language")
        let session = PublicWebTrustDelegate.session()
        let task = session.dataTask(with: request) { data, response, _ in
            session.finishTasksAndInvalidate()
            guard let data = data, !data.isEmpty else {
                then(nil, nil)
                return
            }
            let html = String(data: data, encoding: .utf8)
                ?? String(data: data, encoding: .isoLatin1)
                ?? ""
            then(html, (response as? HTTPURLResponse)?.url ?? url)
        }
        task.resume()
    }

    /// The first link in a message, as the screens that draw one look for it: the first line
    /// with something link-shaped on it, and the first word of that line that is a link.
    public static func firstLink(in message: String) -> String {
        // Asked of every text bubble as it is built, and almost none of them carry a link: the
        // cheap test comes before the two passes over the message.
        guard message.contains("http") || message.contains("www.") else {
            return ""
        }
        var written = message
        // Some messages carry the app's own business after a black square.
        if written.contains("\u{25A0}") {
            written = written.components(separatedBy: "\u{25A0}")[0]
        }
        let lines = written.components(separatedBy: "\n")
        guard let line = lines.first(where: {
            $0.contains("www.") || $0.contains("http://") || $0.contains("https://")
        }) else {
            return ""
        }
        let words = line.components(separatedBy: " ")
        guard let word = words.first(where: {
            ($0.starts(with: "www.") && $0.components(separatedBy: ".").count > 2)
                || ($0.starts(with: "http://") && $0.components(separatedBy: ".").count > 1)
                || ($0.starts(with: "https://") && $0.components(separatedBy: ".").count > 1)
        }) else {
            return ""
        }
        return word.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// What was written in the message, as something that can be asked for.
    static func address(of link: String) -> URL? {
        var text = link.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.lowercased().hasPrefix("www.") {
            text = "https://" + text
        }
        guard text.lowercased().hasPrefix("http://") || text.lowercased().hasPrefix("https://") else {
            return nil
        }
        if let url = URL(string: text) {
            return url
        }
        // A link with a space or a stray character in it still has a page behind it.
        return URL(string: text.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed) ?? text)
    }

    // MARK: reading the page

    static func read(html: String, link: String, landedOn: URL) -> LinkPreviewFacts {
        let tags = metaTags(in: html)
        var facts = LinkPreviewFacts()
        facts.link = link
        facts.title = first(of: ["og:title", "twitter:title"], in: tags)
            ?? unescape(match(html, pattern: "<title[^>]*>([\\s\\S]*?)</title>", group: 1) ?? "")
        facts.title = facts.title.trimmingCharacters(in: .whitespacesAndNewlines)
        // A search page's description is the whole of its front page and says nothing about the
        // link - the rule was already here for Google and it is kept. Instagram's is a tally of
        // likes and comments rather than anything the page says, which is why WhatsApp's card for
        // a reel has a title and no second paragraph.
        let host = (landedOn.host ?? "").lowercased()
        if !host.contains("google."), !host.contains("instagram.com") {
            facts.blurb = (first(of: ["og:description", "twitter:description", "description"], in: tags) ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        facts.siteName = (first(of: ["og:site_name", "application-name"], in: tags) ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // The page's own picture where there is one, and the still of the video off the address
        // for the one site that puts the video's name in its address - a link that arrives
        // shortened, or with the tags withheld, still has a picture that way.
        let published = first(of: ["og:image:secure_url", "og:image:url", "og:image", "twitter:image",
                                   "twitter:image:src"], in: tags)
        facts.imageUrl = absolute(published ?? youtubeThumbnail(of: landedOn) ?? "", against: landedOn)
        if published != nil {
            let width = CGFloat(Int(first(of: ["og:image:width", "twitter:image:width"], in: tags) ?? "") ?? 0)
            let height = CGFloat(Int(first(of: ["og:image:height", "twitter:image:height"], in: tags) ?? "") ?? 0)
            if width > 0, height > 0 {
                facts.imageSize = CGSize(width: width, height: height)
            }
        }
        facts.iconUrl = absolute(iconAddress(in: html) ?? "", against: landedOn)

        facts.videoLabel = videoLabel(of: landedOn, tags: tags)
        if facts.isVideo {
            facts.seconds = duration(html: html, tags: tags)
        }
        return facts
    }

    /// Every meta tag on the page, by the name it goes under. The first of a repeated name wins:
    /// a page that lists several og:image tags lists the one it means first.
    private static func metaTags(in html: String) -> [String: String] {
        var found: [String: String] = [:]
        guard let tag = try? NSRegularExpression(pattern: "<meta\\s[^>]*>", options: [.caseInsensitive]) else {
            return found
        }
        let text = html as NSString
        // Fix: this stopped after the first six hundred thousand characters, on the reasoning
        // that a page's head comes first. YouTube's does not - its og:title sits at character
        // seven hundred thousand, behind the script that carries the player - so every YouTube
        // link came back with nothing on it. The whole page is read; it is read once per link,
        // off the main thread.
        tag.enumerateMatches(in: html, options: [],
                             range: NSRange(location: 0, length: text.length)) { result, _, _ in
            guard let range = result?.range else {
                return
            }
            let one = text.substring(with: range)
            guard let name = match(one, pattern: "(?:property|name|itemprop)\\s*=\\s*[\"']([^\"']+)[\"']", group: 1),
                  let value = match(one, pattern: "content\\s*=\\s*[\"']([^\"']*)[\"']", group: 1) else {
                return
            }
            let key = name.lowercased().trimmingCharacters(in: .whitespaces)
            if found[key] == nil, !value.isEmpty {
                found[key] = unescape(value)
            }
        }
        return found
    }

    private static func first(of names: [String], in tags: [String: String]) -> String? {
        for name in names {
            if let value = tags[name], !value.isEmpty {
                return value
            }
        }
        return nil
    }

    private static func iconAddress(in html: String) -> String? {
        guard let tag = try? NSRegularExpression(pattern: "<link\\s[^>]*>", options: [.caseInsensitive]) else {
            return nil
        }
        let text = html as NSString
        var best: String?
        tag.enumerateMatches(in: html, options: [],
                             range: NSRange(location: 0, length: text.length)) { result, _, stop in
            guard let range = result?.range else {
                return
            }
            let one = text.substring(with: range)
            guard let rel = match(one, pattern: "rel\\s*=\\s*[\"']([^\"']+)[\"']", group: 1)?.lowercased(),
                  rel.contains("icon"),
                  let href = match(one, pattern: "href\\s*=\\s*[\"']([^\"']+)[\"']", group: 1) else {
                return
            }
            if best == nil || rel.contains("apple-touch") {
                best = unescape(href)
            }
            if rel.contains("apple-touch") {
                stop.pointee = true
            }
        }
        return best
    }

    /// What kind of video a link is, when it is one at all.
    private static func videoLabel(of url: URL, tags: [String: String]) -> String {
        let host = (url.host ?? "").lowercased()
        let path = url.path.lowercased()
        let kind = (tags["og:type"] ?? "").lowercased()
        let saysVideo = kind.hasPrefix("video")
            || tags["og:video"] != nil
            || tags["og:video:url"] != nil
            || tags["og:video:secure_url"] != nil
            || (tags["twitter:card"] ?? "") == "player"
        if host.contains("instagram.com") || host.contains("facebook.com") || host.contains("fb.watch") {
            if path.hasPrefix("/reel") || path.contains("/reel/") || path.contains("/reels/") {
                return "Reels"
            }
            return saysVideo ? "Video".localized() : ""
        }
        if host.contains("youtube.com") || host.contains("youtu.be") {
            if path.hasPrefix("/shorts") {
                return "Shorts"
            }
            return saysVideo || path.hasPrefix("/watch") || host.contains("youtu.be") ? "Video".localized() : ""
        }
        if host.contains("tiktok.com") {
            return "TikTok"
        }
        if host.contains("vimeo.com") || host.contains("dailymotion.com") || host.contains("twitch.tv") {
            return saysVideo ? "Video".localized() : ""
        }
        return saysVideo ? "Video".localized() : ""
    }

    /// How long the video is, from whichever of the several places a site writes it.
    private static func duration(html: String, tags: [String: String]) -> Int {
        for name in ["og:video:duration", "video:duration", "duration"] {
            if let written = tags[name] {
                if let plain = Int(written.prefix(while: { $0.isNumber })), plain > 0 {
                    return plain
                }
                if let spelled = isoSeconds(written), spelled > 0 {
                    return spelled
                }
            }
        }
        if let written = match(html, pattern: "itemprop=\"duration\"[^>]*content=\"([^\"]+)\"", group: 1),
           let spelled = isoSeconds(written), spelled > 0 {
            return spelled
        }
        if let written = match(html, pattern: "\"lengthSeconds\"\\s*:\\s*\"?(\\d+)\"?", group: 1),
           let plain = Int(written), plain > 0 {
            return plain
        }
        if let written = match(html, pattern: "\"video_duration\"\\s*:\\s*([0-9.]+)", group: 1),
           let plain = Double(written), plain > 0 {
            return Int(plain.rounded())
        }
        return 0
    }

    /// PT3M34S, which is how a page spells three and a half minutes.
    private static func isoSeconds(_ text: String) -> Int? {
        guard text.uppercased().hasPrefix("PT") else {
            return nil
        }
        var total = 0
        var number = ""
        for character in text.uppercased().dropFirst(2) {
            if character.isNumber {
                number.append(character)
                continue
            }
            let value = Int(number) ?? 0
            number = ""
            switch character {
            case "H": total += value * 3600
            case "M": total += value * 60
            case "S": total += value
            default: break
            }
        }
        return total > 0 ? total : nil
    }

    /// The still of a video, straight from the address, for the one site that puts the video's
    /// name in its address.
    static func youtubeThumbnail(of url: URL) -> String? {
        let host = (url.host ?? "").lowercased()
        var code = ""
        if host.contains("youtube.com") {
            if url.path.lowercased().hasPrefix("/shorts") {
                code = url.lastPathComponent
            } else if let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
                      let value = items.first(where: { $0.name == "v" })?.value {
                code = value
            }
        } else if host.contains("youtu.be") {
            code = url.lastPathComponent
        }
        guard !code.isEmpty, code.count > 5 else {
            return nil
        }
        return "https://img.youtube.com/vi/\(code)/hqdefault.jpg"
    }

    private static func absolute(_ address: String, against page: URL) -> String {
        guard !address.isEmpty else {
            return ""
        }
        if address.lowercased().hasPrefix("http://") || address.lowercased().hasPrefix("https://") {
            return address
        }
        if address.hasPrefix("//") {
            return (page.scheme ?? "https") + ":" + address
        }
        return URL(string: address, relativeTo: page)?.absoluteString ?? ""
    }

    private static func match(_ text: String, pattern: String, group: Int) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }
        let whole = text as NSString
        guard let found = regex.firstMatch(in: text, options: [],
                                           range: NSRange(location: 0, length: whole.length)),
              found.numberOfRanges > group,
              found.range(at: group).location != NSNotFound else {
            return nil
        }
        return whole.substring(with: found.range(at: group))
    }

    /// A page writes its title with entities in it - &amp;, &#064;, &#x2022; - and a card that
    /// draws them as written reads like source code.
    static func unescape(_ text: String) -> String {
        guard text.contains("&") else {
            return text
        }
        var out = text
        let plain = ["&amp;": "&", "&lt;": "<", "&gt;": ">", "&quot;": "\"", "&apos;": "'",
                     "&#39;": "'", "&#039;": "'", "&nbsp;": " ", "&hellip;": "\u{2026}",
                     "&mdash;": "\u{2014}", "&ndash;": "\u{2013}", "&rsquo;": "\u{2019}",
                     "&lsquo;": "\u{2018}", "&ldquo;": "\u{201C}", "&rdquo;": "\u{201D}"]
        for (from, to) in plain {
            out = out.replacingOccurrences(of: from, with: to, options: [.caseInsensitive])
        }
        guard out.contains("&#"), let regex = try? NSRegularExpression(pattern: "&#(x?)([0-9A-Fa-f]+);") else {
            return out
        }
        let whole = out as NSString
        var built = ""
        var read = 0
        for found in regex.matches(in: out, options: [], range: NSRange(location: 0, length: whole.length)) {
            built += whole.substring(with: NSRange(location: read, length: found.range.location - read))
            read = found.range.location + found.range.length
            let hex = whole.substring(with: found.range(at: 1)).lowercased() == "x"
            let digits = whole.substring(with: found.range(at: 2))
            if let value = UInt32(digits, radix: hex ? 16 : 10), let scalar = Unicode.Scalar(value) {
                built.append(Character(scalar))
            }
        }
        built += whole.substring(from: read)
        return built
    }
}

/// The pictures a card draws.
///
/// Fix: these went straight to the app's shared image cache, and that cache reads and decrypts
/// from disk whenever what is asked for is not in memory - `isSecureExists`, `readSecure`,
/// `decryptFileFromServer`, `UIImage(data:)`, all of it on whichever thread asked. A list asks
/// once per row as the rows come into view, which put an encrypted read and an image decode
/// between two frames of a scroll. Nothing here touches the disk or the network on the calling
/// thread any more: what is in memory is answered at once, and everything else is answered later
/// from a queue of its own. The same address asked for twice is fetched once, and an address that
/// answers with something that is not a picture is not asked for again.
public enum LinkPreviewImage {

    private static let held: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 60
        return cache
    }()
    private static var waiting: [String: [(UIImage?) -> Void]] = [:]
    private static var refused = Set<String>()
    /// Pictures this device does not hold, so a list does not go back to the disk for them.
    private static var absent = Set<String>()
    private static let lock = NSLock()
    // Serial on purpose: what it reads it decrypts, and one file at a time off the main thread is
    // what a scrolling list needs - not many at once competing for the same store.
    private static let readers = DispatchQueue(label: "io.nexilis.linkpreview.pictures",
                                               qos: .utility)

    /// What is in memory, and only that. Safe to call from a row being built mid-scroll.
    static func cached(_ address: String) -> UIImage? {
        guard !address.isEmpty else {
            return nil
        }
        return held.object(forKey: address as NSString)
    }

    /// What this device already has, without asking the network for anything - which is what a
    /// list that must not fetch can still show. Answers on the main queue, and remembers what it
    /// did not find so a scroll back and forth does not read the disk again for it.
    static func onDisk(_ address: String, then: @escaping (UIImage?) -> Void) {
        guard !address.isEmpty else {
            then(nil)
            return
        }
        if let ready = cached(address) {
            then(ready)
            return
        }
        lock.lock()
        let known = absent.contains(address)
        lock.unlock()
        guard !known else {
            then(nil)
            return
        }
        readers.async {
            let image = ImageCache.shared.image(forKey: address)
            lock.lock()
            if let image = image {
                held.setObject(image, forKey: address as NSString)
            } else {
                absent.insert(address)
            }
            lock.unlock()
            DispatchQueue.main.async {
                then(image)
            }
        }
    }

    /// Answers on the main queue. Reads from disk, and asks the network, from a queue of its own.
    static func fetch(_ address: String, then: @escaping (UIImage?) -> Void) {
        guard !address.isEmpty else {
            then(nil)
            return
        }
        if let ready = cached(address) {
            then(ready)
            return
        }
        lock.lock()
        if refused.contains(address) {
            lock.unlock()
            then(nil)
            return
        }
        if waiting[address] != nil {
            waiting[address]?.append(then)
            lock.unlock()
            return
        }
        waiting[address] = [then]
        lock.unlock()

        /// `answered` tells a picture that is not there from one that could not be reached: the
        /// first is settled for good, the second is worth asking about again later.
        func settle(_ image: UIImage?, answered: Bool) {
            lock.lock()
            let callers = waiting.removeValue(forKey: address) ?? []
            if let image = image {
                held.setObject(image, forKey: address as NSString)
                absent.remove(address)
            } else if answered {
                refused.insert(address)
            }
            lock.unlock()
            DispatchQueue.main.async {
                for caller in callers {
                    caller(image)
                }
            }
        }

        readers.async {
            // What this device already has, read where reading is allowed to take its time.
            if let onDisk = ImageCache.shared.image(forKey: address) {
                settle(onDisk, answered: true)
                return
            }
            guard let url = URL(string: address) else {
                settle(nil, answered: true)
                return
            }
            var request = URLRequest(url: url)
            request.setValue("image/*,*/*;q=0.8", forHTTPHeaderField: "Accept")
            let session = PublicWebTrustDelegate.session()
            let task = session.dataTask(with: request) { data, _, _ in
                session.finishTasksAndInvalidate()
                guard let data = data else {
                    settle(nil, answered: false)
                    return
                }
                guard let image = UIImage(data: data) else {
                    settle(nil, answered: true)
                    return
                }
                ImageCache.shared.save(image: image, forKey: address)
                settle(image, answered: true)
            }
            task.resume()
        }
    }

    static func load(_ address: String, into view: UIImageView, stillWanted: @escaping () -> Bool) {
        guard !address.isEmpty else {
            view.image = nil
            return
        }
        if let ready = cached(address) {
            view.image = ready
            return
        }
        view.image = nil
        fetch(address) { image in
            guard let image = image, stillWanted() else {
                return
            }
            view.image = image
        }
    }
}

/// A link, drawn the way WhatsApp draws one: the page's own picture across the top at the shape
/// the picture is, its title under that, a line of what the page says about itself, and the site
/// it came from on the last line. A video says so with a play mark, and says which kind of video
/// and how long it runs.
///
/// The card measures itself - `height(for:width:)` answers before anything is built - because the
/// bubble around it has to know how tall it will be to place the message text under it, and a row
/// that guesses is a row that jumps when the guess turns out wrong.
public final class LinkPreviewCard: UIView {

    private let picture = UIImageView()
    private let badge = UIView()
    private let badgeGlyph = UIImageView()
    private let badgeText = UILabel()
    private let heading = UILabel()
    private let blurb = UILabel()
    private let footGlyph = UIImageView()
    private let foot = UILabel()
    private let favicon = UIImageView()

    private var facts = LinkPreviewFacts()
    private var compact = false

    private static let pad: CGFloat = 10
    private static let thumb: CGFloat = 56

    private static var headingFont: UIFont {
        return .systemFont(ofSize: 14 + String.offset(), weight: .semibold)
    }
    /// A card with nothing to say about the page under the title gives the title the line it
    /// would have taken - which is how a reel's card reads, three lines of the caption and the
    /// site under it.
    private static func headingLines(_ facts: LinkPreviewFacts, compact: Bool) -> Int {
        if compact {
            return 2
        }
        return facts.blurb.isEmpty ? 3 : 2
    }
    private static var blurbFont: UIFont {
        return .systemFont(ofSize: 13 + String.offset())
    }
    private static var footFont: UIFont {
        return .systemFont(ofSize: 12 + String.offset())
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        build()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        build()
    }

    private func build() {
        layer.cornerRadius = 6
        clipsToBounds = true
        // The card is read, not touched: what a tap on it does belongs to the bubble around it,
        // which already knows how to open the link.
        isUserInteractionEnabled = false

        picture.contentMode = .scaleAspectFill
        picture.clipsToBounds = true
        picture.backgroundColor = UIColor(white: 0.5, alpha: 0.15)
        addSubview(picture)

        // Fix: a play circle was drawn over the middle of the picture as well as the mark on the
        // badge below it, so a video card carried the same sign twice - two play triangles on one
        // still. The badge is the one that says something the picture does not: which kind of
        // video it is and how long it runs.
        badge.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        badge.layer.cornerRadius = 4
        badge.isHidden = true
        addSubview(badge)
        badgeGlyph.contentMode = .scaleAspectFit
        badge.addSubview(badgeGlyph)
        badgeText.font = .systemFont(ofSize: 12, weight: .semibold)
        badgeText.textColor = .white
        badge.addSubview(badgeText)

        heading.numberOfLines = 2
        heading.font = LinkPreviewCard.headingFont
        addSubview(heading)

        blurb.numberOfLines = 2
        blurb.font = LinkPreviewCard.blurbFont
        addSubview(blurb)

        footGlyph.contentMode = .scaleAspectFit
        addSubview(footGlyph)
        foot.numberOfLines = 1
        foot.font = LinkPreviewCard.footFont
        addSubview(foot)

        favicon.contentMode = .scaleAspectFit
        favicon.layer.cornerRadius = 3
        favicon.clipsToBounds = true
        addSubview(favicon)
    }

    /// Fills the card in. The panel it sits on is the one the quote and the document card sit on,
    /// so the three cannot drift apart.
    public func show(_ facts: LinkPreviewFacts, dark: Bool) {
        self.facts = facts
        compact = !facts.hasLargePicture
        backgroundColor = BubblePanel.ground(dark: dark)

        heading.text = facts.title
        heading.numberOfLines = LinkPreviewCard.headingLines(facts, compact: compact)
        heading.textColor = BubblePanel.text(dark: dark)
        blurb.text = facts.blurb
        blurb.textColor = BubblePanel.secondaryText(dark: dark)
        blurb.isHidden = compact || facts.blurb.isEmpty
        // A card too small to carry a picture cannot carry a play mark over one either, so what
        // kind of video it is is said on the last line instead - the reader still learns it is a
        // reel and how long it runs.
        var written = facts.domain
        if compact, facts.isVideo {
            let spoken = facts.spokenDuration
            written += " · " + (spoken.isEmpty ? facts.videoLabel : "\(facts.videoLabel) \(spoken)")
        }
        foot.text = written
        foot.textColor = BubblePanel.secondaryText(dark: dark)
        footGlyph.image = UIImage(systemName: "link")?
            .withTintColor(BubblePanel.secondaryText(dark: dark), renderingMode: .alwaysOriginal)

        picture.isHidden = facts.imageUrl.isEmpty
        let wanted = facts.imageUrl
        if !wanted.isEmpty {
            LinkPreviewImage.load(wanted, into: picture, stillWanted: { [weak self] in
                return self?.facts.imageUrl == wanted
            })
        } else {
            picture.image = nil
        }

        let icon = facts.iconUrl
        favicon.isHidden = icon.isEmpty || compact
        if !favicon.isHidden {
            LinkPreviewImage.load(icon, into: favicon, stillWanted: { [weak self] in
                return self?.facts.iconUrl == icon
            })
        } else {
            favicon.image = nil
        }

        let showsVideo = facts.isVideo && !compact && !facts.imageUrl.isEmpty
        badge.isHidden = !showsVideo
        if showsVideo {
            badgeGlyph.image = UIImage(systemName: facts.videoLabel == "Reels" || facts.videoLabel == "Shorts"
                                       ? "play.rectangle.fill" : "play.circle.fill")?
                .withTintColor(.white, renderingMode: .alwaysOriginal)
            let spoken = facts.spokenDuration
            if spoken.isEmpty {
                badgeText.text = facts.videoLabel
            } else if facts.videoLabel == "Video".localized() {
                badgeText.text = spoken
            } else {
                badgeText.text = "\(facts.videoLabel) · \(spoken)"
            }
        }
        setNeedsLayout()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        let width = bounds.width
        let pad = LinkPreviewCard.pad
        if compact {
            let thumb = facts.imageUrl.isEmpty ? 0 : LinkPreviewCard.thumb
            picture.frame = CGRect(x: 0, y: (bounds.height - thumb) / 2, width: thumb, height: thumb)
            picture.layer.cornerRadius = 0
            let left = thumb > 0 ? thumb + pad : pad
            let textWidth = max(width - left - pad, 30)
            let headingHeight = LinkPreviewCard.measure(facts.title, font: LinkPreviewCard.headingFont,
                                                        width: textWidth,
                                                        lines: LinkPreviewCard.headingLines(facts, compact: true))
            let footHeight = ceil(LinkPreviewCard.footFont.lineHeight)
            let block = headingHeight + 3 + footHeight
            var y = max((bounds.height - block) / 2, pad)
            heading.frame = CGRect(x: left, y: y, width: textWidth, height: headingHeight)
            y += headingHeight + 3
            layoutFoot(left: left, y: y, width: textWidth, height: footHeight, room: width - pad)
            return
        }

        let pictureHeight = LinkPreviewCard.pictureHeight(for: facts, width: width)
        picture.frame = CGRect(x: 0, y: 0, width: width, height: pictureHeight)

        if !badge.isHidden {
            let text = badgeText.text ?? ""
            let textWidth = ceil((text as NSString).size(withAttributes: [.font: badgeText.font!]).width)
            let badgeWidth = 6 + 14 + 4 + textWidth + 6
            badge.frame = CGRect(x: 8, y: pictureHeight - 8 - 22, width: badgeWidth, height: 22)
            badgeGlyph.frame = CGRect(x: 6, y: 4, width: 14, height: 14)
            badgeText.frame = CGRect(x: 24, y: 0, width: textWidth, height: 22)
        }

        let textWidth = max(width - pad * 2, 30)
        var y = pictureHeight + 8
        let headingHeight = LinkPreviewCard.measure(facts.title, font: LinkPreviewCard.headingFont,
                                                    width: textWidth,
                                                    lines: LinkPreviewCard.headingLines(facts, compact: false))
        heading.frame = CGRect(x: pad, y: y, width: textWidth, height: headingHeight)
        y += headingHeight
        if !blurb.isHidden {
            let blurbHeight = LinkPreviewCard.measure(facts.blurb, font: LinkPreviewCard.blurbFont,
                                                      width: textWidth, lines: 2)
            y += 3
            blurb.frame = CGRect(x: pad, y: y, width: textWidth, height: blurbHeight)
            y += blurbHeight
        }
        y += 5
        layoutFoot(left: pad, y: y, width: textWidth, height: ceil(LinkPreviewCard.footFont.lineHeight),
                   room: width - pad)
    }

    private func layoutFoot(left: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, room: CGFloat) {
        let glyph: CGFloat = min(height, 14)
        footGlyph.frame = CGRect(x: left, y: y + (height - glyph) / 2, width: glyph, height: glyph)
        var textWidth = width - glyph - 5
        if !favicon.isHidden {
            let side: CGFloat = 18
            favicon.frame = CGRect(x: room - side, y: y + (height - side) / 2, width: side, height: side)
            textWidth -= side + 6
        }
        foot.frame = CGRect(x: left + glyph + 5, y: y, width: max(textWidth, 20), height: height)
    }

    /// How tall the picture is drawn. A page's picture can be any shape at all, and a card that
    /// followed it exactly would be a strip for a banner and a whole screen for a reel; so the
    /// shape is kept between a wide still and a tall one, and the picture fills what it is given.
    static func pictureHeight(for facts: LinkPreviewFacts, width: CGFloat) -> CGFloat {
        guard !facts.imageUrl.isEmpty else {
            return 0
        }
        let ratio = min(max(facts.pictureRatio, 0.5), 1.34)
        return (width * ratio).rounded()
    }

    /// The width a card is drawn at inside a bubble: wide enough for a picture to be worth
    /// looking at, and narrow enough that the bubble holding it still fits where a bubble goes.
    public static func width(inViewOfWidth width: CGFloat) -> CGFloat {
        return max(180, min((width * 0.68).rounded(), width - 140))
    }

    public static func height(for facts: LinkPreviewFacts, width: CGFloat) -> CGFloat {
        let pad = LinkPreviewCard.pad
        let footHeight = ceil(footFont.lineHeight)
        if facts.hasLargePicture {
            var height = pictureHeight(for: facts, width: width)
            let textWidth = max(width - pad * 2, 30)
            height += 8
            height += measure(facts.title, font: headingFont, width: textWidth,
                              lines: headingLines(facts, compact: false))
            let blurbHeight = measure(facts.blurb, font: blurbFont, width: textWidth, lines: 2)
            if blurbHeight > 0 {
                height += 3 + blurbHeight
            }
            height += 5 + footHeight + pad
            return ceil(height)
        }
        let thumb = facts.imageUrl.isEmpty ? 0 : LinkPreviewCard.thumb
        let left = thumb > 0 ? thumb + pad : pad
        let textWidth = max(width - left - pad, 30)
        let block = pad + measure(facts.title, font: headingFont, width: textWidth,
                                  lines: headingLines(facts, compact: true))
            + 3 + footHeight + pad
        return ceil(max(block, thumb))
    }

    static func measure(_ text: String, font: UIFont, width: CGFloat, lines: Int) -> CGFloat {
        guard !text.isEmpty else {
            return 0
        }
        let box = (text as NSString).boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil)
        return min(ceil(box.height), ceil(font.lineHeight * CGFloat(lines)))
    }
}
