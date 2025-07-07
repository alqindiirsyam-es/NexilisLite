//
//  CoreMessage_TMessageBank.swift
//  Runner
//
//  Created by Yayan Dwi on 15/04/20.
//  Copyright © 2020 The Chromium Authors. All rights reserved.
//

import Foundation
import UIKit

public class CoreMessage_TMessageBank {
    
    public static func checkCallStatus(pin: String) -> TMessage {
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.ASKING_FOR_END_CALL
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = User.getMyPin()!
        tmessage.mBodies[CoreMessage_TMessageKey.F_PIN] = pin
        return tmessage
    }
    
    public static func getSignUpApi(api: String, p_pin: String) -> TMessage {
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.SIGN_UP_API
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mBodies[CoreMessage_TMessageKey.API] = api
        tmessage.mBodies[CoreMessage_TMessageKey.ANDROID_APP_NAME] = APIS.getAppNm()
        tmessage.mBodies[CoreMessage_TMessageKey.CPAAS_VERSION] = Utils.CPAAS_VERSION
        tmessage.mBodies[CoreMessage_TMessageKey.ANDROID_PACKAGE_NAME] = (Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String) ?? ""
        tmessage.mPIN = p_pin
        return tmessage
    }
    
    public static func getSignIn(p_name: String, p_password: String) -> TMessage {
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.SEND_SIGNIN
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mBodies[CoreMessage_TMessageKey.NAME] = p_name
        tmessage.mBodies[CoreMessage_TMessageKey.PSWD] = p_password
        tmessage.mBodies[CoreMessage_TMessageKey.ANDROID_ID] = Utils.M_USER_ANDROID_ID
        tmessage.mBodies[CoreMessage_TMessageKey.ANDROID_APP_NAME] = APIS.getAppNm()
        tmessage.mBodies[CoreMessage_TMessageKey.CPAAS_VERSION] = Utils.CPAAS_VERSION
        tmessage.mBodies[CoreMessage_TMessageKey.ANDROID_PACKAGE_NAME] = (Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String) ?? ""
//        tmessage.mBodies[CoreMessage_TMessageKey.BUSINESS_ENTITY] = "74"
        return tmessage
    }
    
    public static func getChangeConnectionID(p_pin: String) -> TMessage {
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.CHANGE_CONNECTION_ID
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = p_pin
        tmessage.mBodies[CoreMessage_TMessageKey.F_PIN] = p_pin
        return tmessage
    }
    
    public static func getPostRegistration(p_pin: String) -> TMessage {
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.POST_REGISTRATION_IOS
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = p_pin
        return tmessage
    }
    
    public static func getBatchBuddiesInfos(p_f_pin: String, last_update: Int, l_pin: String? = nil) -> TMessage {
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.GET_BATCH_BUDDY_INFO
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = p_f_pin
        tmessage.mBodies[CoreMessage_TMessageKey.LAST_UPDATE] = "\(last_update)"
        if(l_pin != nil){
            tmessage.mBodies[CoreMessage_TMessageKey.L_PIN] = l_pin
        }
        return tmessage
    }
    
    public static func getSendSignup(p_pin: String, p_name: String, p_last_name: String, p_msisdn: String, p_card_type: String, p_card_id: String, p_email: String, p_thumb_id: String, flag: String, imei: String, imsi: String,password:String) -> TMessage {
        // flag 0 = register biasa, 1 = dengan google, 2 = dengan facebook
        let tMessage = TMessage()
        tMessage.mCode = CoreMessage_TMessageCode.SEND_SIGNUP_DATA
        tMessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tMessage.mPIN = p_pin
        tMessage.mBodies[CoreMessage_TMessageKey.FIRST_NAME] =         p_name
        tMessage.mBodies[CoreMessage_TMessageKey.LAST_NAME] = p_last_name
        tMessage.mBodies[CoreMessage_TMessageKey.MSISDN] =     p_msisdn
        tMessage.mBodies[CoreMessage_TMessageKey.CARD_TYPE] =     p_card_type
        tMessage.mBodies[CoreMessage_TMessageKey.CARD_ID] =     p_card_id
        tMessage.mBodies[CoreMessage_TMessageKey.EMAIL] =     p_email
        tMessage.mBodies[CoreMessage_TMessageKey.THUMB_ID] =     p_thumb_id
//        tMessage.mBodies[CoreMessage_TMessageKey.BUSINESS_ENTITY] = "74"
        tMessage.mBodies[CoreMessage_TMessageKey.TYPE_REGISTER] = flag
        tMessage.mBodies[CoreMessage_TMessageKey.IMEI] = imei
        tMessage.mBodies[CoreMessage_TMessageKey.IMSI] = imsi
        tMessage.mBodies[CoreMessage_TMessageKey.PSWD] = password
        return tMessage
    }
    
    public static func getSendSignupOTP(p_pin: String, p_name: String, p_last_name: String, p_msisdn: String, p_card_type: String, p_card_id: String, p_email: String, p_thumb_id: String, flag: String, imei: String, imsi: String,password:String) -> TMessage {
        // flag 0 = register biasa, 1 = dengan google, 2 = dengan facebook
        let tMessage = TMessage()
        tMessage.mCode = CoreMessage_TMessageCode.SEND_SIGNUP_OTP
        tMessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tMessage.mPIN = p_pin
        tMessage.mBodies[CoreMessage_TMessageKey.FIRST_NAME] =         p_name
        tMessage.mBodies[CoreMessage_TMessageKey.LAST_NAME] = p_last_name
        tMessage.mBodies[CoreMessage_TMessageKey.MSISDN] =     p_msisdn
        tMessage.mBodies[CoreMessage_TMessageKey.CARD_TYPE] =     p_card_type
        tMessage.mBodies[CoreMessage_TMessageKey.CARD_ID] =     p_card_id
        tMessage.mBodies[CoreMessage_TMessageKey.EMAIL] =     p_email
        tMessage.mBodies[CoreMessage_TMessageKey.THUMB_ID] =     p_thumb_id
//        tMessage.mBodies[CoreMessage_TMessageKey.BUSINESS_ENTITY] = "74"
        tMessage.mBodies[CoreMessage_TMessageKey.TYPE_REGISTER] = flag
        tMessage.mBodies[CoreMessage_TMessageKey.IMEI] = imei
        tMessage.mBodies[CoreMessage_TMessageKey.IMSI] = imsi
        tMessage.mBodies[CoreMessage_TMessageKey.PSWD] = password
        return tMessage
    }
    
    public static func getAddBuddy(p_f_pin: String, p_l_pin: String) -> TMessage {
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.ADD_BUDDY
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = p_f_pin
        tmessage.mBodies[CoreMessage_TMessageKey.F_PIN] = p_f_pin
        tmessage.mBodies[CoreMessage_TMessageKey.L_PIN] = p_l_pin
        return tmessage
    }
    
    public static func pullChannelList(offset: String, filter_account: String, filter_category: String, search: String, shr: String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.PULL_CHANNEL_LIST
        tmessage.mPIN = me
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mBodies[CoreMessage_TMessageKey.OFFSET] = offset
        tmessage.mBodies[CoreMessage_TMessageKey.FILTER_ACCOUNT] = filter_account
        tmessage.mBodies[CoreMessage_TMessageKey.FILTER_CATEGORY] = filter_category
        tmessage.mBodies[CoreMessage_TMessageKey.MESSAGE_TEXT] = search
        tmessage.mBodies[CoreMessage_TMessageKey.SHARING_FLAG] = shr
        return tmessage
    }
    
    public static func sendMessage(message_id: String = "", l_pin: String, message_scope_id: String, status: String, message_text: String, credential: String, attachment_flag: String, ex_blog_id: String, message_large_text: String, ex_format: String, image_id: String, audio_id: String, video_id: String, file_id: String, thumb_id: String, reff_id: String, read_receipts: String, chat_id: String, is_call_center: String, call_center_id: String, opposite_pin: String, gif_id: String = "", isForwarded: String = "", isSecret: String = "", specFile: String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.SEND_CHAT
        tmessage.mStatus = me + CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mL_PIN = l_pin
        tmessage.mBodies[CoreMessage_TMessageKey.MESSAGE_ID] = message_id.isEmpty ? me + CoreMessage_TMessageUtil.getTID() : message_id
        tmessage.mBodies[CoreMessage_TMessageKey.F_PIN] = me
        tmessage.mBodies[CoreMessage_TMessageKey.L_PIN] = l_pin
        tmessage.mBodies[CoreMessage_TMessageKey.SERVER_DATE] = String(Date().currentTimeMillis())
        tmessage.mBodies[CoreMessage_TMessageKey.LOCAL_TIMESTAMP] = String(Date().currentTimeMillis())
        tmessage.mBodies[CoreMessage_TMessageKey.MESSAGE_SCOPE_ID] = message_scope_id
        tmessage.mBodies[CoreMessage_TMessageKey.STATUS] = status
        tmessage.mBodies[CoreMessage_TMessageKey.MESSAGE_TEXT] = message_text.toStupidString()
        tmessage.mBodies[CoreMessage_TMessageKey.CREDENTIAL] = credential
        tmessage.mBodies[CoreMessage_TMessageKey.ATTACHMENT_FLAG] = attachment_flag
        tmessage.mBodies[CoreMessage_TMessageKey.BLOG_ID] = ex_blog_id
        tmessage.mBodies[CoreMessage_TMessageKey.BODY] = message_large_text
        tmessage.mBodies[CoreMessage_TMessageKey.CONNECTED] = "1"
        tmessage.mBodies[CoreMessage_TMessageKey.FORMAT] = ex_format
        tmessage.mBodies[CoreMessage_TMessageKey.IS_CALL_CENTER] = is_call_center
        tmessage.mBodies[CoreMessage_TMessageKey.CALL_CENTER_ID] = call_center_id
        tmessage.mBodies[CoreMessage_TMessageKey.F_USER_ID] = me
        tmessage.mBodies[CoreMessage_TMessageKey.QUANTITY] = "1"
        if !opposite_pin.isEmpty {
            tmessage.mBodies[CoreMessage_TMessageKey.OPPOSITE_PIN] = opposite_pin
        }
        
        if !image_id.isEmpty {
            tmessage.mBodies[CoreMessage_TMessageKey.IMAGE_ID] = image_id
        }
        if !audio_id.isEmpty {
            tmessage.mBodies[CoreMessage_TMessageKey.AUDIO_ID] = audio_id
        }
        if !video_id.isEmpty {
            tmessage.mBodies[CoreMessage_TMessageKey.VIDEO_ID] = video_id
        }
        if !file_id.isEmpty {
            tmessage.mBodies[CoreMessage_TMessageKey.FILE_ID] = file_id
        }
        if !thumb_id.isEmpty {
            tmessage.mBodies[CoreMessage_TMessageKey.THUMB_ID] = thumb_id
        }
        if !reff_id.isEmpty {
            tmessage.mBodies[CoreMessage_TMessageKey.REF_ID] = reff_id
        }
        tmessage.mBodies[CoreMessage_TMessageKey.READ_RECEIPTS] = read_receipts
        if !chat_id.isEmpty {
            tmessage.mBodies[CoreMessage_TMessageKey.CHAT_ID] = chat_id
        }
        if !gif_id.isEmpty {
            tmessage.mBodies[CoreMessage_TMessageKey.GIF_ID] = gif_id
        }
        tmessage.mBodies[CoreMessage_TMessageKey.IS_FORWARDED_MESSAGE] = isForwarded
        tmessage.mBodies[CoreMessage_TMessageKey.IS_SECRET] = isSecret
        tmessage.mBodies[CoreMessage_TMessageKey.ATTACHMENT_SPECIALITY] = specFile
        return tmessage
    }
    
    public static func editMessage(message_id: String = "", l_pin: String, message_scope_id: String, status: String, message_text: String, credential: String, attachment_flag: String, ex_blog_id: String, message_large_text: String, ex_format: String, image_id: String, audio_id: String, video_id: String, file_id: String, thumb_id: String, reff_id: String, read_receipts: String, chat_id: String, is_call_center: String, call_center_id: String, opposite_pin: String, server_date: String, local_time_stamp: String, last_edit: Int64 = 0) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.EDIT_MESSAGE
        tmessage.mStatus = me + CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mL_PIN = l_pin
        tmessage.mBodies[CoreMessage_TMessageKey.MESSAGE_ID] = message_id.isEmpty ? me + CoreMessage_TMessageUtil.getTID() : message_id
        tmessage.mBodies[CoreMessage_TMessageKey.F_PIN] = me
        tmessage.mBodies[CoreMessage_TMessageKey.L_PIN] = l_pin
        tmessage.mBodies[CoreMessage_TMessageKey.SERVER_DATE] = server_date
        tmessage.mBodies[CoreMessage_TMessageKey.LOCAL_TIMESTAMP] = local_time_stamp
        tmessage.mBodies[CoreMessage_TMessageKey.MESSAGE_SCOPE_ID] = message_scope_id
        tmessage.mBodies[CoreMessage_TMessageKey.STATUS] = status
        tmessage.mBodies[CoreMessage_TMessageKey.MESSAGE_TEXT] = message_text.toStupidString()
        tmessage.mBodies[CoreMessage_TMessageKey.CREDENTIAL] = credential
        tmessage.mBodies[CoreMessage_TMessageKey.ATTACHMENT_FLAG] = attachment_flag
        tmessage.mBodies[CoreMessage_TMessageKey.BLOG_ID] = ex_blog_id
        tmessage.mBodies[CoreMessage_TMessageKey.BODY] = message_large_text
        tmessage.mBodies[CoreMessage_TMessageKey.CONNECTED] = "1"
        tmessage.mBodies[CoreMessage_TMessageKey.FORMAT] = ex_format
        tmessage.mBodies[CoreMessage_TMessageKey.IS_CALL_CENTER] = is_call_center
        tmessage.mBodies[CoreMessage_TMessageKey.CALL_CENTER_ID] = call_center_id
        tmessage.mBodies[CoreMessage_TMessageKey.F_USER_ID] = me
        tmessage.mBodies[CoreMessage_TMessageKey.QUANTITY] = "1"
        if !opposite_pin.isEmpty {
            tmessage.mBodies[CoreMessage_TMessageKey.OPPOSITE_PIN] = opposite_pin
        }
        
        if !image_id.isEmpty {
            tmessage.mBodies[CoreMessage_TMessageKey.IMAGE_ID] = image_id
        }
        if !audio_id.isEmpty {
            tmessage.mBodies[CoreMessage_TMessageKey.AUDIO_ID] = audio_id
        }
        if !video_id.isEmpty {
            tmessage.mBodies[CoreMessage_TMessageKey.VIDEO_ID] = video_id
        }
        if !file_id.isEmpty {
            tmessage.mBodies[CoreMessage_TMessageKey.FILE_ID] = file_id
        }
        if !thumb_id.isEmpty {
            tmessage.mBodies[CoreMessage_TMessageKey.THUMB_ID] = thumb_id
        }
        if !reff_id.isEmpty {
            tmessage.mBodies[CoreMessage_TMessageKey.REF_ID] = reff_id
        }
        tmessage.mBodies[CoreMessage_TMessageKey.READ_RECEIPTS] = read_receipts
        if !chat_id.isEmpty {
            tmessage.mBodies[CoreMessage_TMessageKey.CHAT_ID] = chat_id
        }
        tmessage.mBodies[CoreMessage_TMessageKey.LAST_EDIT] = "\(last_edit)"
        return tmessage
    }
    
    public static func getUpdateRead(p_chat_id: String, p_f_pin: String, p_scope_id: String, qty: Int) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.SEND_UPDATE_READ
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey.CHAT_ID] = p_chat_id
        tmessage.mBodies[CoreMessage_TMessageKey.F_PIN] = p_f_pin
        tmessage.mBodies[CoreMessage_TMessageKey.MESSAGE_SCOPE_ID] = p_scope_id
        tmessage.mBodies[CoreMessage_TMessageKey.QUANTITY] = "\(qty)"
        return tmessage
    }
    
    public static func getUploadFile(p_image_id: String, file_size: String, part_of: String, part_size: String, p_file: [UInt8] ) -> TMessage {
        var me: String = ""
        if User.getMyPin() != nil {
            me = User.getMyPin()!
        }
        //        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.UPLOAD_FILE
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey.FILE_UPLOAD] = p_image_id
        tmessage.mBodies[CoreMessage_TMessageKey.FILE_SIZE] = file_size
        tmessage.mBodies[CoreMessage_TMessageKey.PART_OF] = part_of
        tmessage.mBodies[CoreMessage_TMessageKey.PART_SIZE] = part_size
        tmessage.setMedia(media: p_file)
        return tmessage
    }
    
    public static func getAcknowledgment(p_id: String) -> TMessage {
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.ACKNOWLEDGMENT
        tmessage.mStatus = p_id
        tmessage.mPIN = "-1"
        tmessage.mBodies[CoreMessage_TMessageKey._ID] = CoreMessage_TMessageUtil.getTID()
        tmessage.mBodies[CoreMessage_TMessageKey.MESSAGE_ID] = p_id
        return tmessage
    }
    
    public static func getCreateGroup(p_group_id: String, p_group_name: String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.CREATE_GROUP
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey.GROUP_ID] = p_group_id
        tmessage.mBodies[CoreMessage_TMessageKey.GROUP_NAME] = p_group_name
        return tmessage
    }
    
    public static func getCreateChat(chat_id: String, title: String, group_id: String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.CREATE_CHAT
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey.CHAT_ID] = chat_id
        tmessage.mBodies[CoreMessage_TMessageKey.TITLE] = title
        tmessage.mBodies[CoreMessage_TMessageKey.F_PIN] = group_id
        tmessage.mBodies[CoreMessage_TMessageKey.L_PIN] = ""
        tmessage.mBodies[CoreMessage_TMessageKey.SCOPE_ID] = "4"
        return tmessage
    }
    
    public static func getDeleteChat(chat_id: String, f_pin: String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.DELETE_CHAT
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey.CHAT_ID] = chat_id
        tmessage.mBodies[CoreMessage_TMessageKey.F_PIN] = f_pin
        tmessage.mBodies[CoreMessage_TMessageKey.SCOPE_ID] = "4"
        return tmessage
    }
    
    public static func getUpdateChat(p_chat_id: String, p_f_pin: String, p_title: String, p_anonym: String, p_image: String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.UPDATE_CHAT
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey.CHAT_ID] = p_chat_id
        tmessage.mBodies[CoreMessage_TMessageKey.F_PIN] = p_f_pin
        tmessage.mBodies[CoreMessage_TMessageKey.SCOPE_ID] = "4"
        tmessage.mBodies[CoreMessage_TMessageKey.TITLE] = p_title
        tmessage.mBodies[CoreMessage_TMessageKey.ANONYMOUS] = p_anonym
        tmessage.mBodies[CoreMessage_TMessageKey.IMAGE] = p_image
        return tmessage
    }
    
    public static func getAddGroupMember(p_group_id: String, p_member_pin: String, p_position: String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.ADD_MEMBER
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey.GROUP_ID] = p_group_id
        tmessage.mBodies[CoreMessage_TMessageKey.F_PIN] = p_member_pin
        tmessage.mBodies[CoreMessage_TMessageKey.POSITION] = p_position
        return tmessage
    }
    
    public static func getAddChatMember(groupId: String, chatId: String, pin: String, status: String = "1") -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.JOIN_CHAT
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey.GROUP_ID] = groupId
        tmessage.mBodies[CoreMessage_TMessageKey.CHAT_ID] = chatId
        tmessage.mBodies[CoreMessage_TMessageKey.F_PIN] = pin
        tmessage.mBodies[CoreMessage_TMessageKey.STATUS] = status
        return tmessage
    }
    
    public static func getChangeGroupMemberPosition(p_group_id: String, p_pin: String, p_position: String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.CHANGE_GROUP_MEMBER_POSITION
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey.GROUP_ID] = p_group_id
        tmessage.mBodies[CoreMessage_TMessageKey.F_PIN] = p_pin
        tmessage.mBodies[CoreMessage_TMessageKey.POSITION] = p_position
        return tmessage
    }
    
    public static func getExitGroup(p_group_id: String, p_pin: String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.EXIT_GROUP
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey.GROUP_ID] = p_group_id
        tmessage.mBodies[CoreMessage_TMessageKey.F_PIN] = p_pin
        return tmessage
    }
    
    public static func getChangeGroupInfo(p_group_id: String, p_name: String = "", p_open: String? = nil, p_thumb_id: String = "", p_quote: String = "") -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.CHANGE_GROUP_INFO
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey.GROUP_ID] = p_group_id
        if !p_name.isEmpty { tmessage.mBodies[CoreMessage_TMessageKey.GROUP_NAME] = p_name }
        if p_open != nil { tmessage.mBodies[CoreMessage_TMessageKey.IS_OPEN] = p_open }
        if !p_thumb_id.isEmpty { tmessage.mBodies[CoreMessage_TMessageKey.THUMB_ID] = p_thumb_id }
        if !p_quote.isEmpty { tmessage.mBodies[CoreMessage_TMessageKey.QUOTE] = p_quote }
        return tmessage
    }
    
    public static func getImageDownload(p_image_id: String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.IMAGE_DOWNLOAD
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey.IMAGE_ID] = p_image_id
        return tmessage
    }
    
    public static func retrievePostTimeline(score: String, last_last_update: String, filter_account: String, filter_category: String, search: String, type: String = "", shr: String) -> TMessage {
        let me = User.getMyPin()!
        let tMessage = TMessage()
        tMessage.mCode = CoreMessage_TMessageCode.POST_RETRIEVE_TIMELINE
        tMessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tMessage.mPIN = me
        tMessage.mBodies[CoreMessage_TMessageKey.SCORE] = score
        tMessage.mBodies[CoreMessage_TMessageKey.LAST_UPDATE] = last_last_update
        tMessage.mBodies[CoreMessage_TMessageKey.FILTER_ACCOUNT] = filter_account
        tMessage.mBodies[CoreMessage_TMessageKey.FILTER_CATEGORY] = filter_category
        tMessage.mBodies[CoreMessage_TMessageKey.MESSAGE_TEXT] = "%" + search.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: " ", with: "%") + "%"
        tMessage.mBodies[CoreMessage_TMessageKey.SHARING_FLAG] = shr
        if !type.isEmpty { tMessage.mBodies[CoreMessage_TMessageKey.TYPE] = type }
        return tMessage
    }
    
    public static func retrievePostProfile(f_pin: String, merchant_id: String, last_created_date: String, type: String, storyId: String) -> TMessage {
        let me = User.getMyPin()!
        let tMessage = TMessage()
        tMessage.mCode = CoreMessage_TMessageCode.POST_RETRIEVE_PROFILE
        tMessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tMessage.mPIN = me
        tMessage.mBodies[CoreMessage_TMessageKey.F_PIN] = f_pin
        tMessage.mBodies[CoreMessage_TMessageKey.MERCHANT_ID] = merchant_id
        tMessage.mBodies[CoreMessage_TMessageKey.CREATED_DATE] = last_created_date
        tMessage.mBodies[CoreMessage_TMessageKey.TYPE] = type
        tMessage.mBodies[CoreMessage_TMessageKey.STORY_ID] = storyId
        return tMessage
    }
    
    public static func getReport(post_id: String, report_date: String, reason: String) -> TMessage {
        let me = User.getMyPin()!
        let tMessage = TMessage()
        tMessage.mCode = CoreMessage_TMessageCode.POST_REPORT
        tMessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tMessage.mPIN = me
        tMessage.mBodies[CoreMessage_TMessageKey.POST_ID] = post_id
        tMessage.mBodies[CoreMessage_TMessageKey.F_PIN] = me
        tMessage.mBodies[CoreMessage_TMessageKey.REPORT_DATE] = report_date
        tMessage.mBodies[CoreMessage_TMessageKey.REASON] = reason
        return tMessage
    }
    
    public static func getReaction(post_id: String, flag_reaction: String, last_update: String, beforeFlagChanged: String, lac: String, cid: String, mcc: String, mnc: String, pci: String) -> TMessage {
        let me = User.getMyPin()!
        let tMessage = TMessage()
        tMessage.mCode = CoreMessage_TMessageCode.POST_REACTION
        tMessage.mStatus  = CoreMessage_TMessageUtil.getTID()
        tMessage.mPIN = me
        tMessage.mBodies[CoreMessage_TMessageKey.F_PIN] = me
        tMessage.mBodies[CoreMessage_TMessageKey.POST_ID] = post_id
        tMessage.mBodies[CoreMessage_TMessageKey.FLAG_REACTION] = flag_reaction
        tMessage.mBodies[CoreMessage_TMessageKey.LAST_UPDATE] = last_update
        tMessage.mBodies[CoreMessage_TMessageKey.BEFORE_FLAG_CHANGED] = beforeFlagChanged
        tMessage.mBodies[CoreMessage_TMessageKey.LAC_ID] = lac
        tMessage.mBodies[CoreMessage_TMessageKey.CELL_ID] = cid
        tMessage.mBodies[CoreMessage_TMessageKey.MCC_ID] = mcc
        tMessage.mBodies[CoreMessage_TMessageKey.MNC_ID] = mnc
        tMessage.mBodies[CoreMessage_TMessageKey.PCI_ID] = pci
        return tMessage
    }
    
    public static func getComment(post_id: String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.GET_COMMENTS
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey.F_PIN] = tmessage.mPIN
        tmessage.mBodies["post_id"] = post_id
        return tmessage
    }
    
    public static func sendComment(image: String, name: String, comment_id: String, post_id: String, ref_comment_id: String, comment: String, commentDate: String, lac: String, cid: String, mcc: String, mnc: String, pci: String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.SEND_COMMENTS
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies["name"] = name
        tmessage.mBodies["image"] = image
        tmessage.mBodies[CoreMessage_TMessageKey.COMMENT_ID] = comment_id
        tmessage.mBodies[CoreMessage_TMessageKey.COMMENT] = comment
        tmessage.mBodies[CoreMessage_TMessageKey.COMMENT_DATE] = commentDate
        tmessage.mBodies[CoreMessage_TMessageKey.REF_COMMENT_ID] = ref_comment_id
        tmessage.mBodies[CoreMessage_TMessageKey.LAC_ID] = lac
        tmessage.mBodies[CoreMessage_TMessageKey.CELL_ID] = cid
        tmessage.mBodies[CoreMessage_TMessageKey.MCC_ID] = mcc
        tmessage.mBodies[CoreMessage_TMessageKey.MNC_ID] = mnc
        tmessage.mBodies[CoreMessage_TMessageKey.PCI_ID] = pci
        tmessage.mBodies["post_id"] = post_id
        return tmessage
    }
    
    public static func getFollow(post_id: String, l_pin: String, followDate: String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.GET_FOLLOW
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey.POST_ID] = post_id
        tmessage.mBodies[CoreMessage_TMessageKey.F_PIN] = me
        tmessage.mBodies[CoreMessage_TMessageKey.L_PIN] = l_pin
        tmessage.mBodies[CoreMessage_TMessageKey.FOLLOW_DATE] = followDate
        tmessage.mBodies[CoreMessage_TMessageKey.UNFOLLOW_DATE] = "253402102800000"
        return tmessage
    }
    
    public static func getUnFollow(post_id: String, l_pin: String) -> TMessage{
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.GET_UNFOLLOW
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey.POST_ID] = post_id
        tmessage.mBodies[CoreMessage_TMessageKey.F_PIN] = me
        tmessage.mBodies[CoreMessage_TMessageKey.L_PIN] = l_pin
        tmessage.mBodies[CoreMessage_TMessageKey.UNFOLLOW_DATE] = String(Date().currentTimeMillis())
        return tmessage
    }
    
    public static func deleteComment(comment_id: String, post_id: String, ref_comment_id: String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.DELETE_COMMENTS
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey.COMMENT_ID] = comment_id
        tmessage.mBodies[CoreMessage_TMessageKey.REF_COMMENT_ID] = ref_comment_id
        tmessage.mBodies["post_id"] = post_id
        return tmessage
    }
    
    public static func getUpadateComment(post_id: String, status: String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.ON_EDITOR_COMMENT
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey.F_PIN] = me
        tmessage.mBodies["post_id"] = post_id
        tmessage.mBodies[CoreMessage_TMessageKey.STATUS] = status
        return tmessage
    }
    
    public static func startScreenSharing(device_id: String, title: String?) -> TMessage{
        let me = User.getMyPin()!
        let tMessage = TMessage()
        tMessage.mCode = CoreMessage_TMessageCode.SCREEN_SHARING
        tMessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tMessage.mPIN = me
        tMessage.mBodies[CoreMessage_TMessageKey.TITLE] = title ?? device_id
        tMessage.mBodies[CoreMessage_TMessageKey.L_PIN] = device_id
        return tMessage
    }
    
    public static func terminateScreenSharing(device_id: String) -> TMessage {
        let me = User.getMyPin()!
        let tMessage = TMessage()
        tMessage.mCode = CoreMessage_TMessageCode.SCREEN_SHARING_STOP
        tMessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tMessage.mPIN = me
        tMessage.mBodies[CoreMessage_TMessageKey.L_PIN] = device_id
        return tMessage
    }
    
    public static func getAddFriendQRCode(fpin: String) -> TMessage {
        let tMessage = TMessage()
        tMessage.mCode = CoreMessage_TMessageCode.ADD_FRIEND_QR
        tMessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tMessage.mBodies[CoreMessage_TMessageKey.FRIEND_FPIN] = fpin
        return tMessage
    }
    
    public static func getAddFriendQRCodeSilent(fpin: String) -> TMessage {
        let tMessage = TMessage()
        tMessage.mCode = CoreMessage_TMessageCode.ADD_FRIEND_QR
        tMessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tMessage.mBodies[CoreMessage_TMessageKey.FRIEND_FPIN] = fpin
        tMessage.mBodies["is_silent"] = "1"
        return tMessage
    }
    
    public static func removeFriend(lpin: String) -> TMessage {
        let tMessage = TMessage()
        tMessage.mCode = CoreMessage_TMessageCode.REMOVE_FRIEND
        tMessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tMessage.mBodies[CoreMessage_TMessageKey.L_PIN] = lpin
        return tMessage;
    }
    
    public static func requestNearbyPerson(latitude: String, longitude: String, radius: String = "1000") -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.GET_PERSON_NEARBY
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey.LATITUDE] = latitude
        tmessage.mBodies[CoreMessage_TMessageKey.LONGITUDE] = longitude
        tmessage.mBodies[CoreMessage_TMessageKey.RADIUS] = radius
        return tmessage
    }
    
    public static func searchPerson(name: String) -> TMessage {
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.GET_PERSON_BY_NAME
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = User.getMyPin()!
        tmessage.mBodies[CoreMessage_TMessageKey.NAME] = name
        return tmessage
    }
    
    public static func trackPerson(pin: String) -> TMessage {
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.GET_PERSON_BY_PIN
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = User.getMyPin()!
        tmessage.mBodies[CoreMessage_TMessageKey.L_PIN] = pin
        return tmessage
    }
    
    public static func getSituasiCovid() -> TMessage {
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.GET_SITUASI_COVID
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = User.getMyPin()!
        return tmessage
    }
    
    public static func getDoctorNearby(latitude: String, longitude: String) -> TMessage {
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.GET_DOCTOR_NEARBY
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = User.getMyPin()!
        tmessage.mBodies[CoreMessage_TMessageKey.LONGITUDE] = longitude
        tmessage.mBodies[CoreMessage_TMessageKey.LATITUDE] = latitude
        return tmessage
    }
    
    public static func getPersonSuggestion(p_last_seq: String) -> TMessage {
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.RETRIEVE_PERSON_SUGGESTION
        tmessage.mPIN = User.getMyPin()!
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mBodies[CoreMessage_TMessageKey.LAST_SEQUENCE] = p_last_seq
        return tmessage
    }
    
    public static func getSearchFriend(search_keyword: String, limit: String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.RETRIEVE_PERSON_BY_NAME
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey.F_PIN] = me
        tmessage.mBodies[CoreMessage_TMessageKey.NAME] = search_keyword
        tmessage.mBodies[CoreMessage_TMessageKey.N_LIMIT] = limit
        return tmessage
    }
    
    public static func pullStoryList(offset: String, filter: String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.PULL_STORY_LIST
        tmessage.mPIN = me
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mBodies[CoreMessage_TMessageKey.OFFSET] = offset
        tmessage.mBodies[CoreMessage_TMessageKey.FILTER_ACCOUNT] = filter
        return tmessage
    }
    
    public static func pullMainContent() -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.PULL_MAIN_CONTENT
        tmessage.mPIN = me
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        return tmessage
    }
    
    public static func pullStoryListPersonal(offset: String, filter: String, l_pin:String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.PULL_STORY_LIST_PERSONAL
        tmessage.mPIN = me
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mBodies[CoreMessage_TMessageKey.OFFSET] = offset
        tmessage.mBodies[CoreMessage_TMessageKey.FILTER_ACCOUNT] = filter
        tmessage.mBodies[CoreMessage_TMessageKey.L_PIN] = l_pin
        return tmessage
    }
    
    public static func postCreateStory(post_id: String, title: String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.POST_UPDATE_STORY
        tmessage.mPIN = me
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mBodies[CoreMessage_TMessageKey.POST_ID] = post_id
        tmessage.mBodies[CoreMessage_TMessageKey.TITLE] = title
        tmessage.mBodies[CoreMessage_TMessageKey.TYPE] = "1"
        return tmessage
    }
    
    public static func postUpdateStory(story_id: String, post_id: String, title: String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.POST_UPDATE_STORY
        tmessage.mPIN = me
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mBodies[CoreMessage_TMessageKey.STORY_ID] = story_id
        tmessage.mBodies[CoreMessage_TMessageKey.POST_ID] = post_id
        tmessage.mBodies[CoreMessage_TMessageKey.TITLE] = title
        tmessage.mBodies[CoreMessage_TMessageKey.TYPE] = "2"
        return tmessage
    }
    
    public static func submitKuisioner(data: String, latitude: String, longitude: String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.SUBMIT_SURVEY_COVID
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey.LONGITUDE] = longitude
        tmessage.mBodies[CoreMessage_TMessageKey.LATITUDE] = latitude
        tmessage.mBodies[CoreMessage_TMessageKey.DATA] = data
        return tmessage
    }
    
    public static func submitKuisionerAdditional(data: String, survey_id: String) -> TMessage {
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.SUBMIT_SURVEY_COVID_ADDITIONAL
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID();
        tmessage.mPIN = User.getMyPin()!
        tmessage.mBodies[CoreMessage_TMessageKey.SURVEY_ID] = survey_id
        return tmessage
    }
    
    public static func sendLSBroadcast(title: String, type:String, typeValue: String, category: String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.CREATE_LIVE_VIDEO
        tmessage.mPIN = me
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mBodies[CoreMessage_TMessageKey.TITLE] = title
        tmessage.mBodies[CoreMessage_TMessageKey.BROADCAST_FLAG] = type
        tmessage.mBodies[CoreMessage_TMessageKey.F_PIN] = me
        tmessage.mBodies[CoreMessage_TMessageKey.VALUE] = typeValue
        tmessage.mBodies[CoreMessage_TMessageKey.CATEGORY_ID] = category
        return tmessage
    }
    
    public static func createLS(title: String, type:String, typeValue: String = "", category: String, tagline: String, notifType: String, blogId: String, data: String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.CREATE_LS
        tmessage.mPIN = me
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mBodies[CoreMessage_TMessageKey.TITLE] = title
        tmessage.mBodies[CoreMessage_TMessageKey.BROADCAST_FLAG] = type
        tmessage.mBodies[CoreMessage_TMessageKey.F_PIN] = me
        tmessage.mBodies[CoreMessage_TMessageKey.VALUE] = typeValue
        tmessage.mBodies[CoreMessage_TMessageKey.CATEGORY_ID] = category
        tmessage.mBodies[CoreMessage_TMessageKey.BLOG_ID] = blogId
        tmessage.mBodies[CoreMessage_TMessageKey.TAGLINE] = tagline
        tmessage.mBodies[CoreMessage_TMessageKey.TYPE] = notifType
        tmessage.mBodies[CoreMessage_TMessageKey.DATA] = data
        tmessage.mBodies[CoreMessage_TMessageKey.BUSINESS_ENTITY] = ""
        return tmessage
    }
    
    public static func createSeminar(title: String, type:String, typeValue: String = "", category: String, notifType: String, blogId: String, data: String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.SEMINAR_CREATE
        tmessage.mPIN = me
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mBodies[CoreMessage_TMessageKey.TITLE] = title
        tmessage.mBodies[CoreMessage_TMessageKey.BROADCAST_FLAG] = type
        tmessage.mBodies[CoreMessage_TMessageKey.F_PIN] = me
        tmessage.mBodies[CoreMessage_TMessageKey.VALUE] = typeValue
        tmessage.mBodies[CoreMessage_TMessageKey.CATEGORY_ID] = category
        tmessage.mBodies[CoreMessage_TMessageKey.BLOG_ID] = blogId
        tmessage.mBodies[CoreMessage_TMessageKey.TYPE] = notifType
        tmessage.mBodies[CoreMessage_TMessageKey.DATA] = data
        tmessage.mBodies[CoreMessage_TMessageKey.BUSINESS_ENTITY] = ""
        return tmessage
    }
    
    public static func getUploadTimeline(post_id: String, title: String, description: String, link: String, type: String, created_date: String, audition_date: String, thumb_id: String, privacy: String, file_id: String, video_duration: String, category: String, file_type: String, ads_type: String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.UPLOAD_TIMELINE
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey.POST_ID] = post_id
        tmessage.mBodies[CoreMessage_TMessageKey.TITLE] = title
        tmessage.mBodies[CoreMessage_TMessageKey.DESCRIPTION] = description
        tmessage.mBodies[CoreMessage_TMessageKey.LINK] = link
        tmessage.mBodies[CoreMessage_TMessageKey.TYPE] = type
        tmessage.mBodies[CoreMessage_TMessageKey.CREATED_DATE] = created_date
        tmessage.mBodies[CoreMessage_TMessageKey.AUDITION_DATE] = audition_date
        tmessage.mBodies[CoreMessage_TMessageKey.THUMB_ID] = thumb_id
        tmessage.mBodies[CoreMessage_TMessageKey.PRIVACY_FLAG] = privacy
        tmessage.mBodies[CoreMessage_TMessageKey.FILE_ID] = file_id
        tmessage.mBodies[CoreMessage_TMessageKey.DURATION] = video_duration
        tmessage.mBodies[CoreMessage_TMessageKey.CATEGORY_ID] = category
        tmessage.mBodies[CoreMessage_TMessageKey.MEDIA_TYPE] = file_type
        tmessage.mBodies[CoreMessage_TMessageKey.TYPE_ADS] = ads_type
        return tmessage
    }
    
    public static func getUploadTimelineInvitation(post_id: String, title: String, description: String, link: String, type: String, created_date: String, audition_date: String, thumb_id: String, privacy: String, file_id: String, video_duration: String, category: String, file_type: String, ads_type: String,target: String, members: String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.UPLOAD_TIMELINE
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey.POST_ID] = post_id
        tmessage.mBodies[CoreMessage_TMessageKey.TITLE] = title
        tmessage.mBodies[CoreMessage_TMessageKey.DESCRIPTION] = description
        tmessage.mBodies[CoreMessage_TMessageKey.LINK] = link
        tmessage.mBodies[CoreMessage_TMessageKey.TYPE] = type
        tmessage.mBodies[CoreMessage_TMessageKey.CREATED_DATE] = created_date
        tmessage.mBodies[CoreMessage_TMessageKey.AUDITION_DATE] = audition_date
        tmessage.mBodies[CoreMessage_TMessageKey.THUMB_ID] = thumb_id
        tmessage.mBodies[CoreMessage_TMessageKey.PRIVACY_FLAG] = privacy
        tmessage.mBodies[CoreMessage_TMessageKey.FILE_ID] = file_id
        tmessage.mBodies[CoreMessage_TMessageKey.DURATION] = video_duration
        tmessage.mBodies[CoreMessage_TMessageKey.CATEGORY_ID] = category
        tmessage.mBodies[CoreMessage_TMessageKey.MEDIA_TYPE] = file_type
        tmessage.mBodies[CoreMessage_TMessageKey.TYPE_ADS] = ads_type
        tmessage.mBodies[CoreMessage_TMessageKey.TARGET_CONTENT] = target
        tmessage.mBodies["members"] = members
        return tmessage
    }
    
    public static func getUploadTimelineGroup(post_id: String, title: String, description: String, link: String, type: String, created_date: String, audition_date: String, thumb_id: String, privacy: String, file_id: String, video_duration: String, category: String, file_type: String, ads_type: String,target: String, groups: String, topics: String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.UPLOAD_TIMELINE
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey.POST_ID] = post_id
        tmessage.mBodies[CoreMessage_TMessageKey.TITLE] = title
        tmessage.mBodies[CoreMessage_TMessageKey.DESCRIPTION] = description
        tmessage.mBodies[CoreMessage_TMessageKey.LINK] = link
        tmessage.mBodies[CoreMessage_TMessageKey.TYPE] = type
        tmessage.mBodies[CoreMessage_TMessageKey.CREATED_DATE] = created_date
        tmessage.mBodies[CoreMessage_TMessageKey.AUDITION_DATE] = audition_date
        tmessage.mBodies[CoreMessage_TMessageKey.THUMB_ID] = thumb_id
        tmessage.mBodies[CoreMessage_TMessageKey.PRIVACY_FLAG] = privacy
        tmessage.mBodies[CoreMessage_TMessageKey.FILE_ID] = file_id
        tmessage.mBodies[CoreMessage_TMessageKey.DURATION] = video_duration
        tmessage.mBodies[CoreMessage_TMessageKey.CATEGORY_ID] = category
        tmessage.mBodies[CoreMessage_TMessageKey.MEDIA_TYPE] = file_type
        tmessage.mBodies[CoreMessage_TMessageKey.TYPE_ADS] = ads_type
        tmessage.mBodies[CoreMessage_TMessageKey.TARGET_CONTENT] = target
        tmessage.mBodies["groups"] = groups
        tmessage.mBodies["topics"] = topics
        return tmessage
    }
    
    public static func getUploadTimelineEdu(post_id: String, title: String, description: String, link: String, type: String, created_date: String, audition_date: String, thumb_id: String, privacy: String, file_id: String, video_duration: String, category: String, file_type: String, ads_type: String, level_edu: String, materi_edu: String, finaltest_edu: String, target: String, pricing:String, pricing_money:String, question:String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.UPLOAD_TIMELINE
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey.POST_ID] = post_id
        tmessage.mBodies[CoreMessage_TMessageKey.TITLE] = title
        tmessage.mBodies[CoreMessage_TMessageKey.DESCRIPTION] = description
        tmessage.mBodies[CoreMessage_TMessageKey.LINK] = link
        tmessage.mBodies[CoreMessage_TMessageKey.TYPE] = type
        tmessage.mBodies[CoreMessage_TMessageKey.CREATED_DATE] = created_date
        tmessage.mBodies[CoreMessage_TMessageKey.AUDITION_DATE] = audition_date
        tmessage.mBodies[CoreMessage_TMessageKey.THUMB_ID] = thumb_id
        tmessage.mBodies[CoreMessage_TMessageKey.PRIVACY_FLAG] = privacy
        tmessage.mBodies[CoreMessage_TMessageKey.FILE_ID] = file_id
        tmessage.mBodies[CoreMessage_TMessageKey.DURATION] = video_duration
        tmessage.mBodies[CoreMessage_TMessageKey.CATEGORY_ID] = category
        tmessage.mBodies[CoreMessage_TMessageKey.MEDIA_TYPE] = file_type
        tmessage.mBodies[CoreMessage_TMessageKey.TYPE_ADS] = ads_type
        tmessage.mBodies[CoreMessage_TMessageKey.LEVEL_EDU] = level_edu
        tmessage.mBodies[CoreMessage_TMessageKey.MATERI_EDU] = materi_edu
        tmessage.mBodies[CoreMessage_TMessageKey.FINALTEST_EDU] = finaltest_edu
        tmessage.mBodies[CoreMessage_TMessageKey.TARGET_CONTENT] = target
        tmessage.mBodies[CoreMessage_TMessageKey.PRICING] = pricing
        tmessage.mBodies[CoreMessage_TMessageKey.PRICING_MONEY] = pricing_money
        tmessage.mBodies[CoreMessage_TMessageKey.QUESTION_QUIZ] = question
        return tmessage
    }
    
    public static func getUploadTimelineEduInvitation(post_id: String, title: String, description: String, link: String, type: String, created_date: String, audition_date: String, thumb_id: String, privacy: String, file_id: String, video_duration: String, category: String, file_type: String, ads_type: String, level_edu: String, materi_edu: String, finaltest_edu: String, target: String, pricing:String, pricing_money:String, members: String, question:String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.UPLOAD_TIMELINE
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey.POST_ID] = post_id
        tmessage.mBodies[CoreMessage_TMessageKey.TITLE] = title
        tmessage.mBodies[CoreMessage_TMessageKey.DESCRIPTION] = description
        tmessage.mBodies[CoreMessage_TMessageKey.LINK] = link
        tmessage.mBodies[CoreMessage_TMessageKey.TYPE] = type
        tmessage.mBodies[CoreMessage_TMessageKey.CREATED_DATE] = created_date
        tmessage.mBodies[CoreMessage_TMessageKey.AUDITION_DATE] = audition_date
        tmessage.mBodies[CoreMessage_TMessageKey.THUMB_ID] = thumb_id
        tmessage.mBodies[CoreMessage_TMessageKey.PRIVACY_FLAG] = privacy
        tmessage.mBodies[CoreMessage_TMessageKey.FILE_ID] = file_id
        tmessage.mBodies[CoreMessage_TMessageKey.DURATION] = video_duration
        tmessage.mBodies[CoreMessage_TMessageKey.CATEGORY_ID] = category
        tmessage.mBodies[CoreMessage_TMessageKey.MEDIA_TYPE] = file_type
        tmessage.mBodies[CoreMessage_TMessageKey.TYPE_ADS] = ads_type
        tmessage.mBodies[CoreMessage_TMessageKey.LEVEL_EDU] = level_edu
        tmessage.mBodies[CoreMessage_TMessageKey.MATERI_EDU] = materi_edu
        tmessage.mBodies[CoreMessage_TMessageKey.FINALTEST_EDU] = finaltest_edu
        tmessage.mBodies[CoreMessage_TMessageKey.TARGET_CONTENT] = target
        tmessage.mBodies[CoreMessage_TMessageKey.PRICING] = pricing
        tmessage.mBodies[CoreMessage_TMessageKey.PRICING_MONEY] = pricing_money
        tmessage.mBodies[CoreMessage_TMessageKey.QUESTION_QUIZ] = question
        tmessage.mBodies["members"] = members
        return tmessage
    }
    
    public static func getUploadTimelineEduClass(post_id: String, title: String, description: String, link: String, type: String, created_date: String, audition_date: String, thumb_id: String, privacy: String, file_id: String, video_duration: String, category: String, file_type: String, ads_type: String, level_edu: String, materi_edu: String, finaltest_edu: String, target: String, pricing:String, pricing_money:String, groups: String, topics: String, question:String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.UPLOAD_TIMELINE
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey.POST_ID] = post_id
        tmessage.mBodies[CoreMessage_TMessageKey.TITLE] = title
        tmessage.mBodies[CoreMessage_TMessageKey.DESCRIPTION] = description
        tmessage.mBodies[CoreMessage_TMessageKey.LINK] = link
        tmessage.mBodies[CoreMessage_TMessageKey.TYPE] = type
        tmessage.mBodies[CoreMessage_TMessageKey.CREATED_DATE] = created_date
        tmessage.mBodies[CoreMessage_TMessageKey.AUDITION_DATE] = audition_date
        tmessage.mBodies[CoreMessage_TMessageKey.THUMB_ID] = thumb_id
        tmessage.mBodies[CoreMessage_TMessageKey.PRIVACY_FLAG] = privacy
        tmessage.mBodies[CoreMessage_TMessageKey.FILE_ID] = file_id
        tmessage.mBodies[CoreMessage_TMessageKey.DURATION] = video_duration
        tmessage.mBodies[CoreMessage_TMessageKey.CATEGORY_ID] = category
        tmessage.mBodies[CoreMessage_TMessageKey.MEDIA_TYPE] = file_type
        tmessage.mBodies[CoreMessage_TMessageKey.TYPE_ADS] = ads_type
        tmessage.mBodies[CoreMessage_TMessageKey.LEVEL_EDU] = level_edu
        tmessage.mBodies[CoreMessage_TMessageKey.MATERI_EDU] = materi_edu
        tmessage.mBodies[CoreMessage_TMessageKey.FINALTEST_EDU] = finaltest_edu
        tmessage.mBodies[CoreMessage_TMessageKey.TARGET_CONTENT] = target
        tmessage.mBodies[CoreMessage_TMessageKey.PRICING] = pricing
        tmessage.mBodies[CoreMessage_TMessageKey.PRICING_MONEY] = pricing_money
        tmessage.mBodies[CoreMessage_TMessageKey.QUESTION_QUIZ] = question
        tmessage.mBodies["groups"] = groups
        tmessage.mBodies["topics"] = topics
        return tmessage
    }
    
    public static func joinLiveVideo(broadcast_id: String, request_id:String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.JOIN_LIVE_VIDEO
        tmessage.mPIN = me
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mBodies[CoreMessage_TMessageKey.BROADCAST_ID] = broadcast_id
        tmessage.mBodies[CoreMessage_TMessageKey.REQUEST_ID] = request_id
        return tmessage
    }
    public static func removeLiveVideo(broadcast_id: String, request_id:String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.REMOVE_LIVE_VIDEO
        tmessage.mPIN = me
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mBodies[CoreMessage_TMessageKey.BROADCAST_ID] = broadcast_id
        tmessage.mBodies[CoreMessage_TMessageKey.REQUEST_ID] = request_id
        return tmessage
    }
    public static func leftLiveVideo(broadcast_id: String, request_id:String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.LEFT_LIVE_VIDEO
        tmessage.mPIN = me
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mBodies[CoreMessage_TMessageKey.BROADCAST_ID] = broadcast_id
        tmessage.mBodies[CoreMessage_TMessageKey.REQUEST_ID] = request_id
        return tmessage
    }
    public static func joinSeminar(broadcast_id: String, request_id:String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.SEMINAR_JOIN
        tmessage.mPIN = me
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mBodies[CoreMessage_TMessageKey.BROADCAST_ID] = broadcast_id
        tmessage.mBodies[CoreMessage_TMessageKey.REQUEST_ID] = request_id
        return tmessage
    }
    public static func removeSeminar(broadcast_id: String, request_id:String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.SEMINAR_REMOVE
        tmessage.mPIN = me
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mBodies[CoreMessage_TMessageKey.BROADCAST_ID] = broadcast_id
        tmessage.mBodies[CoreMessage_TMessageKey.REQUEST_ID] = request_id
        return tmessage
    }
    public static func leftSeminar(broadcast_id: String, request_id:String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.SEMINAR_LEFT
        tmessage.mPIN = me
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mBodies[CoreMessage_TMessageKey.BROADCAST_ID] = broadcast_id
        tmessage.mBodies[CoreMessage_TMessageKey.REQUEST_ID] = request_id
        return tmessage
    }
    
    public static func getSeminarRaiseHand(p_pin: String, l_pin: String, status: String) -> TMessage {
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.SEMINAR_PUSH_RAISE_HAND
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = p_pin
        tmessage.mBodies[CoreMessage_TMessageKey.F_PIN] =  p_pin
        tmessage.mBodies[CoreMessage_TMessageKey.L_PIN] = l_pin
        tmessage.mBodies[CoreMessage_TMessageKey.STATUS] = status
        return tmessage
    }
    
    public static func getSeminarDraw(broadcaster: String, flag: String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.SEMINAR_DRAW
        tmessage.mPIN = me
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mBodies[CoreMessage_TMessageKey.F_PIN] = tmessage.mPIN
        tmessage.mBodies[CoreMessage_TMessageKey.L_PIN] = broadcaster
        tmessage.mBodies[CoreMessage_TMessageKey.INDEX] = flag
        return tmessage
    }
    
    public static func getSeminarFaceDetection(p_pin: String, l_pin: String, flag: String) -> TMessage {
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.SEMINAR_FACE_DETECTION
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = p_pin
        tmessage.mBodies[CoreMessage_TMessageKey.F_PIN] = p_pin
        tmessage.mBodies[CoreMessage_TMessageKey.L_PIN] = l_pin
        tmessage.mBodies[CoreMessage_TMessageKey.STATUS] = flag
        return tmessage
    }
    
    public static func getSendLSChat(l_pin: String, message_text:String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.LIVE_PROFILE_PUSH_CHAT
        tmessage.mPIN = me
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mBodies[CoreMessage_TMessageKey.F_PIN] = me
        tmessage.mBodies[CoreMessage_TMessageKey.L_PIN] = l_pin
        tmessage.mBodies[CoreMessage_TMessageKey.MESSAGE_TEXT] = message_text
        return tmessage
    }
    public static func getSendSeminarChat(l_pin: String, message_text:String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.SEMINAR_PUSH_CHAT
        tmessage.mPIN = me
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mBodies[CoreMessage_TMessageKey.F_PIN] = me
        tmessage.mBodies[CoreMessage_TMessageKey.L_PIN] = l_pin
        tmessage.mBodies[CoreMessage_TMessageKey.MESSAGE_TEXT] = message_text
        return tmessage
    }
    public static func getSendLSEmotion(l_pin: String, emotion_type:String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.LIVE_PROFILE_EMOTION_SEND
        tmessage.mPIN = me
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mBodies[CoreMessage_TMessageKey.F_PIN] = me
        tmessage.mBodies[CoreMessage_TMessageKey.L_PIN] = l_pin
        tmessage.mBodies[CoreMessage_TMessageKey.TYPE] = emotion_type
        return tmessage
    }
    public static func getUpdateLSTitle(title:String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.UPDATE_LIVE_VIDEO
        tmessage.mPIN = me
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mBodies[CoreMessage_TMessageKey.F_PIN] = me
        tmessage.mBodies[CoreMessage_TMessageKey.TITLE] = title
        return tmessage
    }
    public static func getChangePersonInfoName(firstname:String,lastname:String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.CHANGE_PERSON_INFO
        tmessage.mPIN = me
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mBodies[CoreMessage_TMessageKey.FIRST_NAME] = firstname
        tmessage.mBodies[CoreMessage_TMessageKey.LAST_NAME] = lastname
        return tmessage
    }
    public static func getChangePersonInfoAutoQuote(f_pin: String, autoQuoteType: String, autoQuote: String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.SET_AUTO_QUOTE
        tmessage.mPIN = f_pin
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mBodies[CoreMessage_TMessageKey.AUTO_QUOTE] = autoQuote
        tmessage.mBodies[CoreMessage_TMessageKey.AUTO_QUOTE_TYPE] = autoQuoteType
        tmessage.mBodies[CoreMessage_TMessageKey.CREATED_DATE] = "\(Date().currentTimeMillis())"
        return tmessage
    }
    public static func getChangePersonInfoEmail(email:String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.CHANGE_PERSON_INFO
        tmessage.mPIN = me
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mBodies[CoreMessage_TMessageKey.EMAIL] = email
        return tmessage
    }
    public static func getChangePersonInfoPassword(password:String,oldpassword:String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.CHANGE_PERSON_INFO
        tmessage.mPIN = me
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mBodies[CoreMessage_TMessageKey.PSWD] = password
        tmessage.mBodies[CoreMessage_TMessageKey.PSWD_OLD] = oldpassword
        return tmessage
    }
    
    public static func getChangePersonInfoQuote(quote: String) -> TMessage {
        let me = User.getMyPin()!
        let tMessage = TMessage()
        tMessage.mCode = CoreMessage_TMessageCode.CHANGE_PERSON_INFO
        tMessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tMessage.mPIN = me
        tMessage.mBodies[CoreMessage_TMessageKey.QUOTE] = quote
        return tMessage
    }
    
    public static func getChangePersonPrivacy(privacy: Bool) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.CHANGE_PERSON_INFO
        tmessage.mPIN = me
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mBodies[CoreMessage_TMessageKey.PRIVACY_FLAG] = privacy ? "1" : "0"
        return tmessage
    }
    
    public static func getChangePersonOfflineMode(offline: Bool) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.CHANGE_PERSON_INFO
        tmessage.mPIN = me
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mBodies[CoreMessage_TMessageKey.OFFLINE_MODE] = offline ? "1" : "0"
        return tmessage
    }
    
    public static func getChangePersonImage(thumb_id: String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.CHANGE_PERSON_INFO
        tmessage.mPIN = me
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mBodies[CoreMessage_TMessageKey.THUMB_ID] = thumb_id
        return tmessage
    }
    
    public static func getLSData(l_pin:String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.LIVE_PROFILE_EMOTION_GET
        tmessage.mPIN = me
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mBodies[CoreMessage_TMessageKey.L_PIN] = l_pin
        return tmessage
    }
    
    public static func deleteMessage(l_pin: String, messageId: String, scope: String, type: String, chat: String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.DELETE_CTEXT
        tmessage.mPIN = me
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mBodies[CoreMessage_TMessageKey.F_PIN] = me
        tmessage.mBodies[CoreMessage_TMessageKey.L_PIN] = l_pin
        tmessage.mBodies[CoreMessage_TMessageKey.MESSAGE_ID] = messageId
        tmessage.mBodies["message_id"] = "'\(messageId)'" // message_id separated with coma
        tmessage.mBodies[CoreMessage_TMessageKey.CHAT_ID] = chat
        tmessage.mBodies[CoreMessage_TMessageKey.MESSAGE_SCOPE_ID] = scope
        tmessage.mBodies["delete_all"] = "1"
//        tmessage.mBodies["delete_local"] = "1"
        if type == "2" { // delete for everyone
            tmessage.mBodies[CoreMessage_TMessageKey.DELETE_MESSAGE_FLAG] = "1"
        }
        return tmessage
    }
    public static func getRequestLiveVideo(f_pin:String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.REQUEST_LIVE_VIDEO
        tmessage.mPIN = me
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mBodies[CoreMessage_TMessageKey.F_PIN] = f_pin
        return tmessage
    }
    public static func createVCallConference(blog_id:String, data:String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.VC_ROOM_CREATE
        tmessage.mPIN = me
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mBodies[CoreMessage_TMessageKey.BLOG_ID] = blog_id
        tmessage.mBodies[CoreMessage_TMessageKey.DATA] = data
        return tmessage
    }
    public static func startVCallConference(blog_id:String,time:String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.VC_ROOM_START
        tmessage.mPIN = me
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mBodies[CoreMessage_TMessageKey.F_PIN] = me
        tmessage.mBodies[CoreMessage_TMessageKey.BROADCAST_ID] = me +  CoreMessage_TMessageUtil.getTID()
        tmessage.mBodies[CoreMessage_TMessageKey.START_DATE] = time
        return tmessage
    }
    public static func joinVCallConference(blog_id:String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.VC_ROOM_JOIN;
        tmessage.mPIN = me
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mBodies[CoreMessage_TMessageKey.F_PIN] = me
        tmessage.mBodies[CoreMessage_TMessageKey.BROADCAST_ID] = blog_id
        return tmessage
    }
    public static func endVCallConference(blog_id:String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.VC_ROOM_END;
        tmessage.mPIN = me
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mBodies[CoreMessage_TMessageKey.F_PIN] = me
        tmessage.mBodies[CoreMessage_TMessageKey.BROADCAST_ID] = blog_id
        return tmessage
    }
    public static func inviteVCallConference(f_pin: String, blog_id:String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.VC_ROOM_INVITE;
        tmessage.mPIN = me
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mBodies[CoreMessage_TMessageKey.L_PIN] = f_pin
        tmessage.mBodies[CoreMessage_TMessageKey.BLOG_ID] = blog_id
        return tmessage
    }
    public static func getVersionCheck() -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.VERSION_CHECK;
        tmessage.mPIN = me
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        return tmessage
    }
    
    public static func getUpdateTypingStatus(p_opposite: String, p_scope: String, p_status: String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.SEND_UPDATE_TYPING;
        tmessage.mPIN = me
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mBodies[CoreMessage_TMessageKey.F_PIN] = me
        tmessage.mBodies[CoreMessage_TMessageKey.L_PIN] = p_opposite
        tmessage.mBodies[CoreMessage_TMessageKey.STATUS] = p_status
        tmessage.mBodies[CoreMessage_TMessageKey.SCOPE_ID] = p_scope
        return tmessage
    }
    
    public static func getBuddyInfo(l_pin: String, last_update: Int) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.GET_BUDDY_INFO;
        tmessage.mPIN = me
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mBodies[CoreMessage_TMessageKey.LAST_UPDATE] = "\(last_update)"
        tmessage.mBodies[CoreMessage_TMessageKey.L_PIN] = l_pin
        return tmessage
    }
    
    public static func getAckLocationMessage(f_pin: String, message_id: String, l_pin: String, server_date: String, message_scope_id: String, longitude: String, latitude: String, description: String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.UPDATE_CTEXT;
        tmessage.mPIN = me
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mBodies[CoreMessage_TMessageKey.MESSAGE_ID] = message_id
        tmessage.mBodies[CoreMessage_TMessageKey.F_PIN] = f_pin
        tmessage.mBodies[CoreMessage_TMessageKey.L_PIN] = l_pin
        tmessage.mBodies[CoreMessage_TMessageKey.SERVER_DATE] = server_date
        tmessage.mBodies[CoreMessage_TMessageKey.MESSAGE_SCOPE_ID] = message_scope_id
        tmessage.mBodies[CoreMessage_TMessageKey.STATUS] = "8"
        tmessage.mBodies[CoreMessage_TMessageKey.LATITUDE] = latitude
        tmessage.mBodies[CoreMessage_TMessageKey.LONGITUDE] = longitude
        tmessage.mBodies[CoreMessage_TMessageKey.DESCRIPTION] = description
        return tmessage
    }
    
    public static func getListFollowing(l_pin: String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.GET_LIST_FOLLOWING
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey.F_PIN] = me
        tmessage.mBodies[CoreMessage_TMessageKey.L_PIN] = l_pin
        return tmessage
    }
    
    public static func getBlock(l_pin: String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.GET_BLOCK
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey.F_PIN] = me
        tmessage.mBodies[CoreMessage_TMessageKey.L_PIN] = l_pin
        return tmessage
    }
    
    public static func getUnBlock(l_pin: String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.GET_UNBLOCK
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey.F_PIN] = me
        tmessage.mBodies[CoreMessage_TMessageKey.L_PIN] = l_pin
        return tmessage
    }
    
    public static func getOpenGroups(p_account: String, offset:String, search:String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.GET_OPEN_GROUPS
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey.FILTER_ACCOUNT] = p_account
        tmessage.mBodies[CoreMessage_TMessageKey.OFFSET] = offset
        tmessage.mBodies[CoreMessage_TMessageKey.MESSAGE_TEXT] = search
        return tmessage
    }
    
    public static func sendOTPMSISDN(p_pin: String, msisdn: String) -> TMessage {
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.SEND_SIGNUP_MSISDN
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = p_pin
        tmessage.mBodies[CoreMessage_TMessageKey.MSISDN] = msisdn
        return tmessage
    }
    
    public static func verifyOTP(p_pin: String, msisdn: String, otp: String) -> TMessage {
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.VERIFY_OTP
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = p_pin
        tmessage.mBodies[CoreMessage_TMessageKey.MSISDN] = msisdn
        tmessage.mBodies[CoreMessage_TMessageKey.OTP] = otp
        return tmessage
    }
    
    public static func signInOTP(p_pin: String, f_name: String, l_name: String, thumb_id: String) -> TMessage {
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.SEND_SIGNIN_OTP
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = p_pin
        tmessage.mBodies[CoreMessage_TMessageKey.F_PIN] = p_pin
        tmessage.mBodies[CoreMessage_TMessageKey.FIRST_NAME] = f_name
        tmessage.mBodies[CoreMessage_TMessageKey.LAST_NAME] = l_name
        tmessage.mBodies[CoreMessage_TMessageKey.THUMB_ID] = thumb_id
        return tmessage
    }
    
    public static func getSendOTPLogin(p_email: String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.SEND_OTP_LOGIN
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey.EMAIL] = p_email
        tmessage.mBodies[CoreMessage_TMessageKey.ANDROID_APP_NAME] = APIS.getAppNm()
        tmessage.mBodies[CoreMessage_TMessageKey.CPAAS_VERSION] = Utils.CPAAS_VERSION
        tmessage.mBodies[CoreMessage_TMessageKey.ANDROID_PACKAGE_NAME] = (Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String) ?? ""
        return tmessage
    }

    public static func getSendVerifyChangeDevice(p_email: String, p_vercode: String, number: String = "", deviceFingerprint: String = "", publicKey: String = "", signature: String = "") -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.SEND_VERIFY_LOGIN
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey.EMAIL] = p_email
        tmessage.mBodies[CoreMessage_TMessageKey.OTP] = p_vercode
        tmessage.mBodies[CoreMessage_TMessageKey.PHONE_NUMBER] = number
        tmessage.mBodies[CoreMessage_TMessageKey.ANDROID_ID] = Utils.M_USER_ANDROID_ID
        tmessage.mBodies[CoreMessage_TMessageKey.ANDROID_APP_NAME] = APIS.getAppNm()
        tmessage.mBodies[CoreMessage_TMessageKey.CPAAS_VERSION] = Utils.CPAAS_VERSION
        tmessage.mBodies[CoreMessage_TMessageKey.ANDROID_PACKAGE_NAME] = (Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String) ?? ""
        if !deviceFingerprint.isEmpty {
            tmessage.mBodies[CoreMessage_TMessageKey.FINGERPRINT] = deviceFingerprint
        }
        if !publicKey.isEmpty{
            tmessage.mBodies[CoreMessage_TMessageKey.PUBLIC_KEY] = publicKey
        }
        if !signature.isEmpty {
            tmessage.mBodies[CoreMessage_TMessageKey.SIGNATURE] = signature
        }
        return tmessage;
    }
    
    public static func getChangePersonMSISDN(msisdn: String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.CHANGE_PERSON_INFO
        tmessage.mPIN = me
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mBodies[CoreMessage_TMessageKey.MSISDN] = msisdn
        return tmessage
    }
    
    public static func sendOTPChangeMSISDN(msisdn: String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.SEND_CHANGE_MSISDN
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey.MSISDN] = msisdn
        return tmessage
    }
    
    public static func drawWhiteboard(l_pin: String, x: String, y: String, w: String, h: String, fc: String, sw: String, xo: String, yo: String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.DRAW_WHITEBOARD
        tmessage.mPIN = me
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mBodies[CoreMessage_TMessageKey.L_PIN] = l_pin
        tmessage.mBodies["x"] = x
        tmessage.mBodies["y"] = y
        tmessage.mBodies["w"] = w
        tmessage.mBodies["h"] = h
        tmessage.mBodies["fc"] = fc
        tmessage.mBodies["sw"] = sw
        tmessage.mBodies["xo"] = xo
        tmessage.mBodies["yo"] = yo
        return tmessage
    }
    
    public static func getApnToken(token: String, callToken: String, fPin: String) -> TMessage {
        let tmessage = TMessage();
        tmessage.mCode = CoreMessage_TMessageCode.APN_TOKEN;
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID();
        tmessage.mPIN = fPin
        tmessage.mBodies[CoreMessage_TMessageKey.APN_TOKEN] = token;
        tmessage.mBodies[CoreMessage_TMessageKey.CALL_TOKEN] = callToken;
        return tmessage;
    }
    
    public static func getCreateSubGroup(group_id: String, group_name: String, parent_id: String, level: String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.CREATE_SUB_GROUP
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey.GROUP_ID] = group_id
        tmessage.mBodies[CoreMessage_TMessageKey.GROUP_NAME] = group_name
        tmessage.mBodies[CoreMessage_TMessageKey.PARENT_ID] = parent_id
        tmessage.mBodies[CoreMessage_TMessageKey.LEVEL] = level
        return tmessage
    }
    
    public static func checkPassword(password: String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.CHECK_PSWD
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey.PSWD] = password
        return tmessage
    }
    
    public static func getSendLoginEmail(email: String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.SEND_LOGIN_EMAIL
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey.EMAIL] = email
        return tmessage
    }
    
    public static func getVerificationEmail(email: String, token:String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.SEND_VERIFICATION
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey.EMAIL] = email
        tmessage.mBodies[CoreMessage_TMessageKey.TOKEN] = token
        return tmessage
    }
    
    public static func getListSchool(keyword: String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.GET_LIST_SCHOOL
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey.NAME] = keyword
        return tmessage
    }
    public static func getUpdateUser(msisdn: String,email: String,name: String, image:String, role: String,password:String,data:String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.UPDATE_USER
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey.MSISDN] = msisdn
        tmessage.mBodies[CoreMessage_TMessageKey.EMAIL] = email
        tmessage.mBodies[CoreMessage_TMessageKey.FIRST_NAME] = name
        tmessage.mBodies[CoreMessage_TMessageKey.THUMB_ID] = image
        tmessage.mBodies[CoreMessage_TMessageKey.CATEGORY_FLAG] = role
        tmessage.mBodies[CoreMessage_TMessageKey.PSWD] = password
        if (role != "1"){
            tmessage.mBodies[CoreMessage_TMessageKey.DATA] = data
        }
        return tmessage
    }
    public static func getRequestStudent(form_id: String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.GET_REQUEST_STUDENT
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey.FORM_ID] = form_id
        return tmessage
    }
    public static func getRequestTeacher(form_id: String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.GET_REQUEST_TEACHER
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey.FORM_ID] = form_id
        return tmessage
    }
    public static func getApproveRequestStudent(form_id: String, l_pin:String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.APPROVE_REQUEST_STUDENT
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey.FORM_ID] = form_id
        tmessage.mBodies[CoreMessage_TMessageKey.L_PIN] = l_pin
        return tmessage
    }
    public static func getApproveRequestTeacher(form_id: String, l_pin:String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.APPROVE_REQUEST_TEACHER
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey.FORM_ID] = form_id
        tmessage.mBodies[CoreMessage_TMessageKey.L_PIN] = l_pin
        return tmessage
    }
    
    public static func requestStudent(f_pin:String,school_id: String,group_id:String,email: String,name: String, l_pin:String, msisdn: String) -> TMessage {
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.REQUEST_STUDENT
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = f_pin
        tmessage.mBodies[CoreMessage_TMessageKey.SCHOOL_ID] = school_id
        tmessage.mBodies[CoreMessage_TMessageKey.GROUP_ID] = group_id
        tmessage.mBodies[CoreMessage_TMessageKey.L_PIN] = l_pin
        tmessage.mBodies[CoreMessage_TMessageKey.REAL_NAME] = name
        tmessage.mBodies[CoreMessage_TMessageKey.EMAIL] = email
        tmessage.mBodies[CoreMessage_TMessageKey.MSISDN] = msisdn
        return tmessage
    }
    
    public static func requestApprovalTeacher(f_pin: String,l_pin: String, school_id:String, level: String,stage:String,major:String, type:String, className:String,email:String,name:String, msisdn: String) -> TMessage {
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.REQUEST_TEACHER_SCHOOL
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = f_pin
        tmessage.mBodies[CoreMessage_TMessageKey.MSISDN] = msisdn
        tmessage.mBodies[CoreMessage_TMessageKey.EMAIL] = email
        tmessage.mBodies[CoreMessage_TMessageKey.REAL_NAME] = name
        tmessage.mBodies[CoreMessage_TMessageKey.L_PIN] = l_pin
        tmessage.mBodies[CoreMessage_TMessageKey.SCHOOL_ID] = school_id
        tmessage.mBodies[CoreMessage_TMessageKey.LEVEL] = level
        tmessage.mBodies[CoreMessage_TMessageKey.EDU_STAGE] = stage
        tmessage.mBodies[CoreMessage_TMessageKey.MAJOR_EDU] = major
        tmessage.mBodies[CoreMessage_TMessageKey.TYPE] = type
        tmessage.mBodies[CoreMessage_TMessageKey.ANDROID_CLASS_NAME] = className
        return tmessage
    }
    public static func getListSchool() -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.GET_LIST_SCHOOL
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        return tmessage
    }
    public static func getListClassName(school_id: String,level: String, major:String, class_type: String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.GET_LIST_CLASS_NAME
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey.SCHOOL_ID] = school_id
        tmessage.mBodies[CoreMessage_TMessageKey.LEVEL] = level
        tmessage.mBodies[CoreMessage_TMessageKey.MAJOR_EDU] = major
        tmessage.mBodies[CoreMessage_TMessageKey.TYPE] = class_type
        return tmessage
    }
    
    public static func updateUser(msisdn: String,email: String,name: String, image:String, role: Int, password: String, data: String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.UPDATE_USER
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey.MSISDN] = msisdn
        tmessage.mBodies[CoreMessage_TMessageKey.EMAIL] = email
        tmessage.mBodies[CoreMessage_TMessageKey.FIRST_NAME] = name
        tmessage.mBodies[CoreMessage_TMessageKey.THUMB_ID] = image
        tmessage.mBodies[CoreMessage_TMessageKey.CATEGORY_FLAG] = "\(role)"
        tmessage.mBodies[CoreMessage_TMessageKey.PSWD] = password
        if(role != 1){
            tmessage.mBodies[CoreMessage_TMessageKey.DATA] = data
        }
        return tmessage
    }
    
    public static func submitSchool(f_pin: String,schoolId: String, schoolName:String, level: String, eduStage: String, p_class_type: String, major: String, p_class_name: String) -> TMessage {
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.SUBMIT_SCHOOL
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = f_pin
        tmessage.mBodies[CoreMessage_TMessageKey.F_PIN] = f_pin
        tmessage.mBodies[CoreMessage_TMessageKey.SCHOOL_ID] = schoolId
        tmessage.mBodies[CoreMessage_TMessageKey.SCHOOL_DESC] = schoolName
        tmessage.mBodies[CoreMessage_TMessageKey.LEVEL] = level
        tmessage.mBodies[CoreMessage_TMessageKey.EDU_STAGE] = eduStage
        tmessage.mBodies[CoreMessage_TMessageKey.MAJOR_EDU] = major
        tmessage.mBodies[CoreMessage_TMessageKey.TYPE] = p_class_type
        tmessage.mBodies[CoreMessage_TMessageKey.ANDROID_CLASS_NAME] = p_class_name
        return tmessage
    }
    
    public static func deletePost(post_id:String, last_update:String, ec_date:String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.DELETE_POST
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey.LAST_UPDATE] = last_update
        tmessage.mBodies[CoreMessage_TMessageKey.EC_DATE] = ec_date
        tmessage.mBodies[CoreMessage_TMessageKey.POST_ID] = post_id
        return tmessage
    }
    
    public static func getIsInitiatorJoin(p_broadcaster:String, p_category:String, blog_id:String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.IS_INITIATOR_JOIN
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey.BROADCAST_ID] = p_broadcaster
        tmessage.mBodies[CoreMessage_TMessageKey.CATEGORY_ID] = p_category
        tmessage.mBodies[CoreMessage_TMessageKey.BLOG_ID] = blog_id
        return tmessage
    }
    
    public static func getStartLPInvited(title:String, type:String,typeValue:String,category:String,blog_id:String, tagline: String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.START_LP_INVITED
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey.F_PIN] = me
        tmessage.mBodies[CoreMessage_TMessageKey.TITLE] = title
        tmessage.mBodies[CoreMessage_TMessageKey.BROADCAST_FLAG] = type
        tmessage.mBodies[CoreMessage_TMessageKey.VALUE] = type
        tmessage.mBodies[CoreMessage_TMessageKey.CATEGORY_ID] = category
        tmessage.mBodies[CoreMessage_TMessageKey.BLOG_ID] = blog_id
        tmessage.mBodies[CoreMessage_TMessageKey.TAGLINE] = tagline
        return tmessage
    }
    
    public static func getStartSeminarInvited(title:String, type:String,typeValue:String,category:String,blog_id:String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.SEMINAR_START_INVITED
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey.F_PIN] = me
        tmessage.mBodies[CoreMessage_TMessageKey.TITLE] = title
        tmessage.mBodies[CoreMessage_TMessageKey.BROADCAST_FLAG] = type
        tmessage.mBodies[CoreMessage_TMessageKey.VALUE] = type
        tmessage.mBodies[CoreMessage_TMessageKey.CATEGORY_ID] = category
        tmessage.mBodies[CoreMessage_TMessageKey.BLOG_ID] = blog_id
        return tmessage
    }
    
    public static func getListSubAccount() -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.SUB_ACCOUNT_LIST
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        return tmessage
    }
    public static func getQuizDetail(post_id:String,lpin:String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.QUIZ_DETAIL
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey.L_PIN] = lpin
        tmessage.mBodies[CoreMessage_TMessageKey.POST_ID] = post_id
        return tmessage
    }
    
    public static func getQuizAnswer(post_id:String,data:String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.QUIZ_ANSWER
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey.DATA] = data
        tmessage.mBodies[CoreMessage_TMessageKey.POST_ID] = post_id
        return tmessage
    }
    
    public static func getQuizScoring(score:String,post_id:String,lpin:String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.QUIZ_SCORING
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey.L_PIN] = lpin
        tmessage.mBodies[CoreMessage_TMessageKey.POST_ID] = post_id
        tmessage.mBodies[CoreMessage_TMessageKey.SCORE] = score
        return tmessage
    }
    
    public static func getRequestCallCenter(p_channel:Int, category_id: String = "") -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.REQUEST_CALL_CENTER
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey.CHANNEL] = "\(p_channel)"
        tmessage.mBodies[CoreMessage_TMessageKey.BUSINESS_ENTITY] = ""
        if !category_id.isEmpty{
            tmessage.mBodies[CoreMessage_TMessageKey.CATEGORY_ID] = category_id
        }
        return tmessage
    }
    
    public static func getRequestEmailCallCenter(p_channel:Int) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.EMAIL_CONTACT_CENTER
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey.CHANNEL] = "\(p_channel)"
        return tmessage
    }
    
    public static func acceptRequestCallCenter(channel:String, l_pin: String, complaint_id: String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.ACCEPT_CALL_CENTER
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey.F_PIN] = me
        tmessage.mBodies[CoreMessage_TMessageKey.L_PIN] = l_pin
        tmessage.mBodies[CoreMessage_TMessageKey.CHANNEL] = channel
        tmessage.mBodies[CoreMessage_TMessageKey.CALL_CENTER_ID] = complaint_id
        return tmessage
    }
    
    public static func endCallCenter(complaint_id:String, l_pin: String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.END_CALL_CENTER
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey.F_PIN] = me
        tmessage.mBodies[CoreMessage_TMessageKey.L_PIN] = l_pin
        tmessage.mBodies[CoreMessage_TMessageKey.DATA] = complaint_id
        return tmessage
    }
    
    public static func getFeatureAccess(key: String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.FEATURE_ACCESS
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey.KEY] = key
        return tmessage
    }
    
    public static func getListLS() -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageKey.GET_LIST_LS
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        return tmessage
    }
    
    public static func broadcastMessage(title:String, broadcast_flag: String, message:String, starting_date: Int64, ending_date: Int64, destination:String, data: String, category_flag:String, notification_type: String, link:String, thumb_id: String, file_id:String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.BROADCAST_MESSAGE
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey.TITLE] = title
        tmessage.mBodies[CoreMessage_TMessageKey.BROADCAST_FLAG] = broadcast_flag
        tmessage.mBodies[CoreMessage_TMessageKey.MESSAGE_TEXT_ENG] = message
        tmessage.mBodies[CoreMessage_TMessageKey.MESSAGE_TEXT] = message
        tmessage.mBodies[CoreMessage_TMessageKey.START_DATE] = "\(starting_date)"
        tmessage.mBodies[CoreMessage_TMessageKey.END_DATE] = "\(ending_date)"
        tmessage.mBodies[CoreMessage_TMessageKey.TARGET_CONTENT] = destination
        tmessage.mBodies[CoreMessage_TMessageKey.DATA] = data
        tmessage.mBodies[CoreMessage_TMessageKey.CATEGORY_FLAG] = category_flag
        tmessage.mBodies[CoreMessage_TMessageKey.TYPE] = notification_type
        tmessage.mBodies[CoreMessage_TMessageKey.LINK] = link
        if (!thumb_id.isEmpty) {
            tmessage.mBodies[CoreMessage_TMessageKey.THUMB_ID] = thumb_id
        }
        if (!file_id.isEmpty) {
            tmessage.mBodies[CoreMessage_TMessageKey.FILE_ID] = file_id
        }
        return tmessage
    }
    
    public static func timeOutRequestCallCenter(channel:String, l_pin: String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.TIMEOUT_CONTACT_CENTER
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey.F_PIN] = me
        tmessage.mBodies[CoreMessage_TMessageKey.L_PIN] = l_pin
        tmessage.mBodies[CoreMessage_TMessageKey.CHANNEL] = channel
        return tmessage
    }
    
    public static func getManagementContactCenter(user_type:String, l_pin: String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.MANAGEMENT_CONTACT_CENTER
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey.F_PIN] = me
        tmessage.mBodies[CoreMessage_TMessageKey.L_PIN] = l_pin
        tmessage.mBodies[CoreMessage_TMessageKey.TYPE] = user_type
        return tmessage
    }
    
    public static func getManagementContactCenterBNI(l_pin: String, type: String, category_id: String, area_id: String, is_second_layer: String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.MANAGEMENT_CONTACT_CENTER
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey.F_PIN] = tmessage.mPIN
        tmessage.mBodies[CoreMessage_TMessageKey.L_PIN] = l_pin
        tmessage.mBodies[CoreMessage_TMessageKey.TYPE] = type
        tmessage.mBodies[CoreMessage_TMessageKey.CATEGORY_ID] = category_id
        tmessage.mBodies[CoreMessage_TMessageKey.WORKING_AREA] = area_id
        tmessage.mBodies[CoreMessage_TMessageKey.IS_SECOND_LAYER] = is_second_layer
        return tmessage
    }
    
    public static func getSignInApiCreator(p_name:String, p_password: String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.SIGN_IN_API_CREATOR
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey.NAME] = p_name
        tmessage.mBodies[CoreMessage_TMessageKey.PSWD] = p_password
        tmessage.mBodies[CoreMessage_TMessageKey.ANDROID_ID] = Utils.M_USER_ANDROID_ID
        return tmessage
    }
    
    public static func getSignInApiAdmin(p_name:String, p_password: String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.SIGN_IN_API_ADMIN
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey.NAME] = p_name
        tmessage.mBodies[CoreMessage_TMessageKey.PSWD] = p_password
        tmessage.mBodies[CoreMessage_TMessageKey.ANDROID_ID] = Utils.M_USER_ANDROID_ID
        return tmessage
    }
    
    public static func getSignInApiInternal(p_name:String, p_password: String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.SIGN_IN_API_INTERNAL
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey.NAME] = p_name
        tmessage.mBodies[CoreMessage_TMessageKey.PSWD] = p_password
        tmessage.mBodies[CoreMessage_TMessageKey.ANDROID_ID] = Utils.M_USER_ANDROID_ID
        return tmessage
    }
    
    public static func getChangePasswordAdmin(p_f_pin:String, pwd_en: String, pwd_old: String) -> TMessage {
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.CHANGE_PSWD_ADMIN
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = p_f_pin
        tmessage.mBodies[CoreMessage_TMessageKey.PSWD] = pwd_en
        tmessage.mBodies[CoreMessage_TMessageKey.PSWD_OLD] = pwd_old
        return tmessage
    }
    
    public static func getChangePasswordInternal(p_f_pin:String, pwd_en: String, pwd_old: String) -> TMessage {
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.CHANGE_PSWD_INTERNAL
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = p_f_pin
        tmessage.mBodies[CoreMessage_TMessageKey.PSWD] = pwd_en
        tmessage.mBodies[CoreMessage_TMessageKey.PSWD_OLD] = pwd_old
        return tmessage
    }
    
    public static func getQueuingCallCenter(p_channel:Int) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.QUEUING_CONTACT_CENTER
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey.CHANNEL] = "\(p_channel)"
        return tmessage
    }
    
    public static func getStatusContactCenter(p_complaint_id:String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.STATUS_CONTACT_CENTER
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey.DATA] = p_complaint_id
        return tmessage
    }
    
    public static func getListDiscussion(p_last_seq: String, keyword: String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.GET_LIST_DISCUSSION
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey.LAST_SEQUENCE] = p_last_seq
        tmessage.mBodies[CoreMessage_TMessageKey.DESCRIPTION] = keyword
        return tmessage
    }
    
    public static func getDiscussionComment(p_discussion_id: String) -> TMessage {
        let me = User.getMyPin()!
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.GET_DISCUSSION_COMMENT
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey._ID] = p_discussion_id
        return tmessage
    }
    
    public static func getSendDiscussionComment(p_pin: String, discussion_id: String, comment: String, comment_id: String) -> TMessage {
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.SEND_DISCUSSION_COMMENT
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = p_pin
        tmessage.mBodies[CoreMessage_TMessageKey.F_PIN] = p_pin
        tmessage.mBodies[CoreMessage_TMessageKey._ID] = discussion_id
        tmessage.mBodies[CoreMessage_TMessageKey.COMMENT] = comment
        tmessage.mBodies[CoreMessage_TMessageKey.COMMENT_ID] = comment_id
        return tmessage
    }
    
    public static func getSendLeaveComment(discussion_id: String) -> TMessage {
        let tmessage = TMessage()
        let me = User.getMyPin()!
        tmessage.mCode = CoreMessage_TMessageCode.LEAVE_DISCUSSION_COMMENT
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey._ID] = discussion_id
        return tmessage
    }
    
    // FORM
    
    public static func getFormList(p_pin: String, p_last_id: String) -> TMessage {
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.REQUEST_FORM_LIST
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = p_pin
        tmessage.mBodies[CoreMessage_TMessageKey.FORM_ID] = p_last_id
        tmessage.mBodies[CoreMessage_TMessageKey.ACTVITY_SUB] = "0"
//        tmessage.mBodies[CoreMessage_TMessageKey.BUSINESS_ENTITY] = "74"
        return tmessage
    }
    
//    public static TMessage getFormList(String p_pin, String p_last_id) {
//            TMessage tmessage = new TMessage();
//            tmessage.mCode = CoreMessage_TMessageCode.REQUEST_FORM_LIST;
//            tmessage.mStatus = CoreMessage_TMessageUtil.getTID();
//            tmessage.mPIN = p_pin;
//            tmessage.mBodies.put(CoreMessage_TMessageKey.FORM_ID, p_last_id);
//            tmessage.mBodies.put(CoreMessage_TMessageKey.ACTVITY_SUB, CoreDataSqlite_PullDB.getLastPull(CoreDataSqlite_PullDB.PULL_TYPE_SUB_ACTIVITY));
//            tmessage.mBodies.put(CoreMessage_TMessageKey.BUSINESS_ENTITY, SharedObj.getCurrentlyMerchant(Qmera.getContext()));
//            return tmessage;
//        }
    
    public static func getSendOTPChangeProfile(name: String, type: String) -> TMessage {
        let tmessage = TMessage()
        let me = User.getMyPin()!
        tmessage.mCode = CoreMessage_TMessageCode.SEND_OTP_CHANGE_PROFILE
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey.OTP] = "99"
        tmessage.mBodies[CoreMessage_TMessageKey.EMAIL] = "nexiilis_email"
        tmessage.mBodies[CoreMessage_TMessageKey.NAME] = name
        tmessage.mBodies[CoreMessage_TMessageKey.TYPE] = type
        return tmessage
    }
    
    public static func getSendOTPChangeDeviceGaspol(p_email: String, p_idnumber: String, p_vercode: String) -> TMessage {
        let tmessage = TMessage()
        let me = User.getMyPin()!
        tmessage.mCode = CoreMessage_TMessageCode.SEND_OTP_CHANGE_DEVICE_GASPOL
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey.OTP] = p_vercode
        tmessage.mBodies[CoreMessage_TMessageKey.EMAIL] = p_email
        tmessage.mBodies[CoreMessage_TMessageKey.USER_ID] = p_idnumber
        return tmessage
    }
    
    public static func getSendVerifyChangeDevice(p_pin: String) -> TMessage {
        let tmessage = TMessage()
        let me = User.getMyPin()!
        tmessage.mCode = CoreMessage_TMessageCode.SEND_VERIFY_CHANGE_DEVICE
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey.F_PIN] = p_pin
        return tmessage
    }
    
    public static func getChangePersonInfo_New(p_f_pin: String) -> TMessage {
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.CHANGE_PERSON_INFO
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = p_f_pin
        return tmessage
    }
    
    public static func getSendEmotionLP(p_pin: String, l_pin: String, emotion_type: String) -> TMessage {
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.LIVE_PROFILE_EMOTION_SEND
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = p_pin
        tmessage.mBodies[CoreMessage_TMessageKey.F_PIN] = p_pin
        tmessage.mBodies[CoreMessage_TMessageKey.L_PIN] = l_pin
        tmessage.mBodies[CoreMessage_TMessageKey.TYPE] = emotion_type
        return tmessage;
    }
    
    public static func getCCRoomIsActive(ticket_id: String) -> TMessage {
        let tmessage = TMessage()
        let me = User.getMyPin()!
        tmessage.mCode = CoreMessage_TMessageCode.IS_ACTIVE_CALL_CONTACT_CENTER
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey.CALL_CENTER_ID] = ticket_id
        return tmessage
    }

    public static func getCCRoomInvite(l_pin: String, ticket_id: String, channel: String) -> TMessage {
        let tmessage = TMessage()
        let me = User.getMyPin()!
        tmessage.mCode = CoreMessage_TMessageCode.INVITE_TO_ROOM_CONTACT_CENTER
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey.L_PIN] = l_pin
        tmessage.mBodies[CoreMessage_TMessageKey.CALL_CENTER_ID] = ticket_id
        tmessage.mBodies[CoreMessage_TMessageKey.CHANNEL] = channel
        return tmessage
    }

    public static func acceptCCRoomInvite(l_pin: String, type: Int, ticket_id: String) -> TMessage {
        let tmessage = TMessage()
        let me = User.getMyPin()!
        tmessage.mCode = CoreMessage_TMessageCode.ACCEPT_CONTACT_CENTER
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey.L_PIN] = l_pin
        tmessage.mBodies[CoreMessage_TMessageKey.TYPE] = "\(type)"
        tmessage.mBodies[CoreMessage_TMessageKey.CALL_CENTER_ID] = ticket_id
        return tmessage
    }

    public static func leaveCCRoomInvite(ticket_id: String) -> TMessage {
        let tmessage = TMessage()
        let me = User.getMyPin()!
        tmessage.mCode = CoreMessage_TMessageCode.INVITE_EXIT_CONTACT_CENTER
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey.CALL_CENTER_ID] = ticket_id
        return tmessage
    }

    public static func getCallCenterDraw(ticket_id: String) -> TMessage {
        let tmessage = TMessage()
        let me = User.getMyPin()!
        tmessage.mCode = CoreMessage_TMessageCode.DRAW_CONTACT_CENTER
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey.F_PIN] = tmessage.mPIN
        tmessage.mBodies[CoreMessage_TMessageKey.CALL_CENTER_ID] = ticket_id
        return tmessage
    }
    
    public static func getWebLoginQRCode(f_qrcode: String) -> TMessage {
        let tmessage = TMessage()
        let me = User.getMyPin()!
        tmessage.mCode = CoreMessage_TMessageCode.WEB_LOGIN_QR
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mBodies[CoreMessage_TMessageKey.F_PIN] = me
        tmessage.mBodies[CoreMessage_TMessageKey.KEY] = f_qrcode
        return tmessage
    }
    
    public static func getFormApproval(p_f_pin: String, p_ref_id: String, p_approve: String, p_note: String, p_sign: String) -> TMessage {
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.APPROVE_FORM
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID();
        tmessage.mPIN = p_f_pin;
        tmessage.mBodies[CoreMessage_TMessageKey.REF_ID] = p_ref_id
        tmessage.mBodies[CoreMessage_TMessageKey.STATUS] = p_approve
        tmessage.mBodies[CoreMessage_TMessageKey.NOTE] = p_note
        tmessage.mBodies[CoreMessage_TMessageKey.SIGN] = p_sign
        return tmessage
    }
    
    public static func pullGroupCategory() -> TMessage {
        let tmessage = TMessage()
        let me = User.getMyPin()!
        tmessage.mCode = CoreMessage_TMessageCode.PULL_GROUP_CATEGORY
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        return tmessage
    }
    
    public static func pullFloatingButton() -> TMessage {
        let tmessage = TMessage()
        let me = User.getMyPin()!
        tmessage.mCode = CoreMessage_TMessageCode.PULL_FLOATING_BUTTON
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        return tmessage
    }
    
    public static func getServiceBNI(p_pin: String) -> TMessage {
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.GET_SERVICE_BNI
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = p_pin
        return tmessage
    }

    public static func queueBNI(service_id: String) -> TMessage {
        let tmessage = TMessage()
        let me = User.getMyPin()!
        tmessage.mCode = CoreMessage_TMessageCode.REQUEST_TICKET_BNI
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey.CATEGORY_ID] = service_id
        return tmessage
    }

    public static func isiPulsaBNI(value: String) -> TMessage {
        let tmessage = TMessage()
        let me = User.getMyPin()!
        tmessage.mCode = CoreMessage_TMessageCode.REQUEST_TOP_UP_BNI
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey.VALUE] = value
        return tmessage
    }
    
    public static func getCustomerInfo(rek: String) -> TMessage {
        let tmessage = TMessage()
        let me = User.getMyPin()!
        tmessage.mCode = CoreMessage_TMessageCode.GET_CUSTOMER_INFO
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey.CARD_ID] = rek
        return tmessage
    }
    
    public static func getRequestSecondContactCenter(p_channel: String, category_id: String, area_id: String) -> TMessage {
        let tmessage = TMessage()
        let me = User.getMyPin()!
        tmessage.mCode = CoreMessage_TMessageCode.REQUEST_SECOND_CONTACT_CENTER
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey.CHANNEL] = p_channel
        tmessage.mBodies[CoreMessage_TMessageKey.BUSINESS_ENTITY] = ""
        tmessage.mBodies[CoreMessage_TMessageKey.CATEGORY_ID] = category_id
        tmessage.mBodies[CoreMessage_TMessageKey.WORKING_AREA] = area_id
        return tmessage;
    }

    public static func respondSecondContactCenter(l_pin: String, type: String, ticket_id: String) -> TMessage {
        let tmessage = TMessage()
        let me = User.getMyPin()!
        tmessage.mCode = CoreMessage_TMessageCode.RESPOND_SECOND_CONTACT_CENTER
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        tmessage.mBodies[CoreMessage_TMessageKey.L_PIN] = l_pin
        tmessage.mBodies[CoreMessage_TMessageKey.TYPE] = type
        tmessage.mBodies[CoreMessage_TMessageKey.CALL_CENTER_ID] = ticket_id
        return tmessage;
    }

    public static func getWorkingAreaContactCenter() -> TMessage {
        let tmessage = TMessage()
        let me = User.getMyPin()!
        tmessage.mCode = CoreMessage_TMessageCode.GET_WORKING_AREA_CONTACT_CENTER
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = me
        return tmessage
    }
    
    public static func getInquiry(message_id: String, error_code: String, data: String) -> TMessage {
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.INQUIRY
        tmessage.mStatus = message_id
        tmessage.mPIN = "-1"
        tmessage.mBodies[CoreMessage_TMessageKey._ID] = CoreMessage_TMessageUtil.getTID()
        tmessage.mBodies[CoreMessage_TMessageKey.MESSAGE_ID] = message_id
        tmessage.mBodies[CoreMessage_TMessageKey.ERRCOD] = error_code
        tmessage.mBodies[CoreMessage_TMessageKey.DATA] = data
        return tmessage
    }

    public static func getMobileInquiry(message_id: String) -> TMessage {
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.MOBILE_INQUIRY;
        tmessage.mStatus = message_id
        tmessage.mPIN = "-1";
        tmessage.mBodies[CoreMessage_TMessageKey._ID] = CoreMessage_TMessageUtil.getTID()
        tmessage.mBodies[CoreMessage_TMessageKey.MESSAGE_ID] = message_id
        return tmessage
    }
    
    public static func getSignUpSignInAPI(p_name: String, p_password: String, deviceFingerprint: String = "", publicKey: String = "", signature: String = "") -> TMessage {
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.SIGN_UP_AND_SIGN_IN_API
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = User.getMyPin()!
        tmessage.mBodies[CoreMessage_TMessageKey.NAME] = p_name
        tmessage.mBodies[CoreMessage_TMessageKey.PSWD] = p_password
        tmessage.mBodies[CoreMessage_TMessageKey.ANDROID_ID] = Utils.M_USER_ANDROID_ID
        tmessage.mBodies[CoreMessage_TMessageKey.ANDROID_APP_NAME] = APIS.getAppNm()
        tmessage.mBodies[CoreMessage_TMessageKey.CPAAS_VERSION] = Utils.CPAAS_VERSION
        tmessage.mBodies[CoreMessage_TMessageKey.ANDROID_PACKAGE_NAME] = (Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String) ?? ""
        if !deviceFingerprint.isEmpty {
            tmessage.mBodies[CoreMessage_TMessageKey.FINGERPRINT] = deviceFingerprint
        }
        if !publicKey.isEmpty{
            tmessage.mBodies[CoreMessage_TMessageKey.PUBLIC_KEY] = publicKey
        }
        if !signature.isEmpty {
            tmessage.mBodies[CoreMessage_TMessageKey.SIGNATURE] = signature
        }
        return tmessage
    }
    
    public static func getBackupAvailability() -> TMessage {
        let tmessage = TMessage()
        tmessage.mCode    = CoreMessage_TMessageCode.BACKUP_AVAILABILITY
        tmessage.mStatus  = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN     = User.getMyPin()!
        return tmessage
    }
    
    public static func getBackupUploaded(option: String, fileid: String, filesize: String, recordSize: String) -> TMessage {
        let tmessage = TMessage()
        tmessage.mCode    = CoreMessage_TMessageCode.BACKUP_UPLOADED
        tmessage.mStatus  = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN     = User.getMyPin()!
        tmessage.mBodies[CoreMessage_TMessageKey.TYPE] =  option
        tmessage.mBodies[CoreMessage_TMessageKey.FILE_ID] = fileid
        tmessage.mBodies[CoreMessage_TMessageKey.FILE_SIZE] = filesize
        tmessage.mBodies[CoreMessage_TMessageKey.CREATED_DATE] = "\(Date().currentTimeMillis())"
        tmessage.mBodies[CoreMessage_TMessageKey.RECORD_SIZE] = recordSize
        return tmessage
    }
    
    public static func getBackupRestored(option: String , fileid: String) -> TMessage {
        let tmessage = TMessage()
        tmessage.mCode    = CoreMessage_TMessageCode.BACKUP_RESTORED
        tmessage.mStatus  = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN     = User.getMyPin()!
        tmessage.mBodies[CoreMessage_TMessageKey.TYPE] = option
        tmessage.mBodies[CoreMessage_TMessageKey.FILE_ID] = fileid
        return tmessage
    }
    
    public static func wbCreate(l_pin: String) -> TMessage {
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.FORWARD_MESSAGE
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = User.getMyPin()!
        tmessage.mBodies[CoreMessage_TMessageKey.L_PIN] = l_pin
        tmessage.mBodies[CoreMessage_TMessageKey.TYPE] = "wb"
        tmessage.mBodies[CoreMessage_TMessageKey.STATUS] = "\(CoreMessage_TMessageCode.WB_INCOMING)"
        return tmessage;
    }
    
    public static func wbAccept(l_pin: String) -> TMessage {
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.FORWARD_MESSAGE
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = User.getMyPin()!
        tmessage.mBodies[CoreMessage_TMessageKey.L_PIN] = l_pin
        tmessage.mBodies[CoreMessage_TMessageKey.TYPE] = "wb"
        tmessage.mBodies[CoreMessage_TMessageKey.STATUS] = "\(CoreMessage_TMessageCode.WB_ACCEPT_INCOMING)"
        return tmessage;
    }
    
    public static func wbReject(l_pin: String) -> TMessage {
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.FORWARD_MESSAGE
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = User.getMyPin()!
        tmessage.mBodies[CoreMessage_TMessageKey.L_PIN] = l_pin
        tmessage.mBodies[CoreMessage_TMessageKey.TYPE] = "wb"
        tmessage.mBodies[CoreMessage_TMessageKey.STATUS] = "\(CoreMessage_TMessageCode.WB_REJECT_INCOMING)"
        return tmessage;
    }
    
    public static func wbOffhook(l_pin: String) -> TMessage {
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.FORWARD_MESSAGE
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = User.getMyPin()!
        tmessage.mBodies[CoreMessage_TMessageKey.L_PIN] = l_pin
        tmessage.mBodies[CoreMessage_TMessageKey.TYPE] = "wb"
        tmessage.mBodies[CoreMessage_TMessageKey.STATUS] = "\(CoreMessage_TMessageCode.WB_OFFHOOK)"
        return tmessage;
    }
    
    public static func wbEnded(l_pin: String) -> TMessage {
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.FORWARD_MESSAGE
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = User.getMyPin()!
        tmessage.mBodies[CoreMessage_TMessageKey.L_PIN] = l_pin
        tmessage.mBodies[CoreMessage_TMessageKey.TYPE] = "wb"
        tmessage.mBodies[CoreMessage_TMessageKey.STATUS] = "\(CoreMessage_TMessageCode.WB_END)"
        return tmessage;
    }
    
    public static func ssCreate(l_pin: String) -> TMessage {
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.FORWARD_MESSAGE
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = User.getMyPin()!
        tmessage.mBodies[CoreMessage_TMessageKey.L_PIN] = l_pin
        tmessage.mBodies[CoreMessage_TMessageKey.TYPE] = "ss"
        tmessage.mBodies[CoreMessage_TMessageKey.STATUS] = "\(CoreMessage_TMessageCode.SS_INCOMING)"
        return tmessage;
    }
    
    public static func ssAccept(l_pin: String) -> TMessage {
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.FORWARD_MESSAGE
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = User.getMyPin()!
        tmessage.mBodies[CoreMessage_TMessageKey.L_PIN] = l_pin
        tmessage.mBodies[CoreMessage_TMessageKey.TYPE] = "ss"
        tmessage.mBodies[CoreMessage_TMessageKey.STATUS] = "\(CoreMessage_TMessageCode.SS_ACCEPT_INCOMING)"
        return tmessage;
    }
    
    public static func ssReject(l_pin: String) -> TMessage {
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.FORWARD_MESSAGE
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = User.getMyPin()!
        tmessage.mBodies[CoreMessage_TMessageKey.L_PIN] = l_pin
        tmessage.mBodies[CoreMessage_TMessageKey.TYPE] = "ss"
        tmessage.mBodies[CoreMessage_TMessageKey.STATUS] = "\(CoreMessage_TMessageCode.SS_REJECT_INCOMING)"
        return tmessage;
    }
    
    public static func ssOffhook(l_pin: String) -> TMessage {
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.FORWARD_MESSAGE
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = User.getMyPin()!
        tmessage.mBodies[CoreMessage_TMessageKey.L_PIN] = l_pin
        tmessage.mBodies[CoreMessage_TMessageKey.TYPE] = "ss"
        tmessage.mBodies[CoreMessage_TMessageKey.STATUS] = "\(CoreMessage_TMessageCode.SS_OFFHOOK)"
        return tmessage;
    }
    
    public static func ssEnded(l_pin: String) -> TMessage {
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.FORWARD_MESSAGE
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = User.getMyPin()!
        tmessage.mBodies[CoreMessage_TMessageKey.L_PIN] = l_pin
        tmessage.mBodies[CoreMessage_TMessageKey.TYPE] = "ss"
        tmessage.mBodies[CoreMessage_TMessageKey.STATUS] = "\(CoreMessage_TMessageCode.SS_END)"
        return tmessage;
    }
    
    public static func getSimplePersonInfoWA(f_pin: String) -> TMessage{
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.GET_SIMPLE_PERSON_INFO
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = User.getMyPin()!
        tmessage.mBodies[CoreMessage_TMessageKey.L_PIN] = f_pin
        tmessage.mBodies[CoreMessage_TMessageKey.STATUS] = "1"
        return tmessage
    }
    
    public static func getServiceBank() -> TMessage {
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.GET_SERVICE_BNI
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = User.getMyPin()!
        tmessage.mBodies[CoreMessage_TMessageKey.PLATFORM] = "0"
        return tmessage
    }
    
    public static func getIncomingCallCS(f_pin_opposite: String) -> TMessage {
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.INCOMING_CALL_CC
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = User.getMyPin()!
        tmessage.mBodies[CoreMessage_TMessageKey.F_PIN] = f_pin_opposite
        return tmessage
    }

    public static func getEndCall(f_pin_opposite: String) -> TMessage {
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.END_CALL
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = User.getMyPin()!
        tmessage.mBodies[CoreMessage_TMessageKey.F_PIN] = f_pin_opposite
        return tmessage;
    }
    
    public static func pullGroupNoMember() -> TMessage {
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.GET_BATCH_GROUP_NO_MEMBERS
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = User.getMyPin()!
        return tmessage
    }
    
    public static func getCalling(fPin: String, type: String) -> TMessage {
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.CALLING
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = User.getMyPin() ?? ""
        tmessage.mBodies[CoreMessage_TMessageKey.F_PIN] = fPin
        tmessage.mBodies[CoreMessage_TMessageKey.TYPE] = type
        return tmessage
    }

    public static func getNotifyCalling(fPin: String, lPin: String, type: String) -> TMessage {
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.NOTIFY_TO_CALLING
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = User.getMyPin() ?? ""
        tmessage.mBodies[CoreMessage_TMessageKey.F_PIN] = fPin
        tmessage.mBodies[CoreMessage_TMessageKey.TYPE] = type
        tmessage.mBodies[CoreMessage_TMessageKey.L_PIN] = lPin
        return tmessage
    }

    public static func getCancelCall(fPin: String, type: String) -> TMessage {
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.CANCEL_CALL_NOTIFICATION
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = User.getMyPin() ?? ""
        tmessage.mBodies[CoreMessage_TMessageKey.F_PIN] = fPin
        tmessage.mBodies[CoreMessage_TMessageKey.TYPE] = type
        return tmessage
    }
    
    public static func getFeatureAccessAll() -> TMessage {
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.FEATURE_ACCESS_ALL
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = User.getMyPin() ?? ""
        tmessage.mBodies[CoreMessage_TMessageKey.API] = Nexilis.sAPIKey
        tmessage.mBodies[CoreMessage_TMessageKey.TYPE] = "1"
        tmessage.mBodies[CoreMessage_TMessageKey.ANDROID_APP_NAME] = APIS.getAppNm()
        return tmessage
    }
    
    public static func getFeatureAccessWithKey(key: [String]) -> TMessage {
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.FEATURE_ACCESS_KEY
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = User.getMyPin() ?? ""
        tmessage.mBodies[CoreMessage_TMessageKey.API] = Nexilis.sAPIKey
        tmessage.mBodies[CoreMessage_TMessageKey.ANDROID_APP_NAME] = APIS.getAppNm()
        tmessage.mBodies[CoreMessage_TMessageKey.KEY] = "\(key)"
        return tmessage
    }
    
    public static func getAlertNewSignIn(brand: String, latitude: String, longitude: String ) -> TMessage {
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.ALERT_NEW_SIGN_IN
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = User.getMyPin() ?? ""
        tmessage.mBodies[CoreMessage_TMessageKey.F_PIN] = Utils.getLoginMultipleFPin()
        tmessage.mBodies[CoreMessage_TMessageKey.DEVICE_BRAND] = brand
        tmessage.mBodies[CoreMessage_TMessageKey.LATITUDE] = latitude
        tmessage.mBodies[CoreMessage_TMessageKey.LONGITUDE] = longitude
        tmessage.mBodies[CoreMessage_TMessageKey.LOCAL_TIMESTAMP] = "\(Date().currentTimeMillis())"
        return tmessage
    }
    
    public static func getBlockAccess(userId: String) -> TMessage {
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.BLOCK_ACCESS
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = User.getMyPin() ?? ""
        tmessage.mBodies[CoreMessage_TMessageKey.F_PIN] = userId
        return tmessage
    }
    
    public static func getShieldSecurityValidateToken(token: String) -> TMessage {
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.SHIELD_SECURITY_VALIDATE_TOKEN
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = User.getMyPin() ?? ""
        tmessage.mBodies[CoreMessage_TMessageKey.F_PIN] = Utils.getLoginMultipleFPin()
        tmessage.mBodies[CoreMessage_TMessageKey.TOKEN] = token
        return tmessage
    }
    
    public static func getUpdateLiveVideo(pTitle: String, pTagline: String) -> TMessage {
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.UPDATE_LIVE_VIDEO
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = User.getMyPin() ?? ""
        tmessage.mBodies[CoreMessage_TMessageKey.TITLE] = pTitle
        tmessage.mBodies[CoreMessage_TMessageKey.TAGLINE] = pTagline
        return tmessage
    }
    
    public static func backToSuperApp() -> TMessage {
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.RESET_SUPER_APP
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = User.getMyPin() ?? ""
        return tmessage
    }
    
    public static func requestGPTBot(message: String) -> TMessage {
        let tmessage = TMessage()
        tmessage.mCode = CoreMessage_TMessageCode.GPT
        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tmessage.mPIN = User.getMyPin() ?? ""
        tmessage.mBodies[CoreMessage_TMessageKey.MESSAGE_TEXT] = message
        return tmessage
    }
    
    public static func getPrefs(key: String = "") -> TMessage {
        let tMessage = NexilisLite.TMessage()
        let me = User.getMyPin()
        tMessage.mCode = CoreMessage_TMessageCode.PULL_PREFS
        tMessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tMessage.mBodies[CoreMessage_TMessageKey.F_PIN] = me
        tMessage.mBodies[CoreMessage_TMessageKey.ANDROID_APP_NAME] = APIS.getAppNm()
        if !key.isEmpty {
            tMessage.mBodies[CoreMessage_TMessageKey.KEY] = key
        }
        return tMessage
    }
    
    public static func getToken(token: String, tokenCall: String) -> TMessage {
        let tMessage = NexilisLite.TMessage()
        let me = User.getMyPin() ?? ""
        tMessage.mPIN = me
        tMessage.mCode = CoreMessage_TMessageCode.APN_TOKEN
        tMessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tMessage.mBodies[CoreMessage_TMessageKey.TOKEN] = token
        tMessage.mBodies[CoreMessage_TMessageKey.CALL_TOKEN] = tokenCall
        tMessage.mBodies[CoreMessage_TMessageKey.DEVICE_BRAND] = "iOS"
        tMessage.mBodies[CoreMessage_TMessageKey.ANDROID_ID] = Utils.M_USER_ANDROID_ID
        return tMessage
    }
    
    public static func getMessageById(messageId: String) -> TMessage {
        let tMessage = NexilisLite.TMessage()
        let me = User.getMyPin() ?? ""
        tMessage.mPIN = me
        tMessage.mCode = CoreMessage_TMessageCode.GET_MESSAGE_BY_ID
        tMessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tMessage.mBodies[CoreMessage_TMessageKey.MESSAGE_ID] = messageId
        return tMessage
    }
    
    public static func getAckMessage(messageId: String) -> TMessage {
        let tMessage = NexilisLite.TMessage()
        let me = User.getMyPin() ?? ""
        tMessage.mPIN = me
        tMessage.mCode = CoreMessage_TMessageCode.ACK_MESSAGE_BY_ID
        tMessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tMessage.mBodies[CoreMessage_TMessageKey.MESSAGE_ID] = messageId
        return tMessage
    }
    
    public static func getCallStatus(lPin: String) -> TMessage {
        let tMessage = NexilisLite.TMessage()
        let me = User.getMyPin() ?? ""
        tMessage.mPIN = me
        tMessage.mCode = CoreMessage_TMessageCode.IS_CALLING
        tMessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tMessage.mBodies[CoreMessage_TMessageKey.L_PIN] = lPin
        return tMessage
    }
    
    public static func getPref(key: String) -> TMessage {
        let tMessage = NexilisLite.TMessage()
        let me = User.getMyPin() ?? ""
        tMessage.mPIN = me
        tMessage.mCode = CoreMessage_TMessageCode.GET_PUSH_PREFS
        tMessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tMessage.mBodies[CoreMessage_TMessageKey.F_PIN] = me
        tMessage.mBodies[CoreMessage_TMessageKey.KEY] = key
        return tMessage
    }
    
    public static func getAddFriendRequest(fPin: String) -> TMessage {
        let tMessage = NexilisLite.TMessage()
        let me = User.getMyPin() ?? ""
        tMessage.mPIN = me
        tMessage.mCode = CoreMessage_TMessageCode.FRIEND_REQUEST
        tMessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tMessage.mBodies[CoreMessage_TMessageKey.L_PIN] = fPin
        return tMessage
    }
    
    public static func getAddFriendApproval(lPin: String, isAccept: Bool) -> TMessage {
        let tMessage = NexilisLite.TMessage()
        let me = User.getMyPin() ?? ""
        tMessage.mPIN = me
        tMessage.mCode = CoreMessage_TMessageCode.APPROVAL_FRIEND_REQUEST
        tMessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tMessage.mBodies[CoreMessage_TMessageKey.F_PIN] = lPin
        tMessage.mBodies[CoreMessage_TMessageKey.DATA] = isAccept ? "1" : "2"
        return tMessage
    }
    
    public static func updateVersion() -> TMessage {
        let tMessage = NexilisLite.TMessage()
        let me = User.getMyPin() ?? ""
        tMessage.mPIN = me
        tMessage.mCode = CoreMessage_TMessageCode.UPDATE_VERSION
        tMessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tMessage.mBodies[CoreMessage_TMessageKey.VERSION] = UIApplication.appVersion
        return tMessage
    }
    
    public static func checkVersion() -> TMessage {
        let tMessage = NexilisLite.TMessage()
        let me = User.getMyPin() ?? ""
        tMessage.mPIN = me
        tMessage.mCode = CoreMessage_TMessageCode.VERSION_CHECK
        tMessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tMessage.mBodies[CoreMessage_TMessageKey.VERSION] = UIApplication.appVersion
        tMessage.mBodies[CoreMessage_TMessageKey.CPAAS_VERSION] = Nexilis.cpaasVersion
        return tMessage
    }
    
    public static func getWhitelistFileExt() -> TMessage {
        let tMessage = NexilisLite.TMessage()
        let me = User.getMyPin() ?? ""
        tMessage.mPIN = me
        tMessage.mCode = CoreMessage_TMessageCode.GET_WHITELIST
        tMessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tMessage.mBodies[CoreMessage_TMessageKey.API] = Nexilis.sAPIKey
        tMessage.mBodies[CoreMessage_TMessageKey.ANDROID_APP_NAME] = APIS.getAppNm()
        return tMessage
    }
    
    public static func getChalanger() -> TMessage {
        let tMessage = NexilisLite.TMessage()
        let me = User.getMyPin() ?? ""
        tMessage.mPIN = me
        tMessage.mCode = CoreMessage_TMessageCode.AUTH_REQUEST
        tMessage.mStatus = CoreMessage_TMessageUtil.getTID()
        return tMessage
    }
    
    public static func getCheckMSISDN(number: String) -> TMessage {
        let tMessage = NexilisLite.TMessage()
        let me = User.getMyPin() ?? ""
        tMessage.mPIN = me
        tMessage.mCode = CoreMessage_TMessageCode.CHECK_USER_MSISDN
        tMessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tMessage.mBodies[CoreMessage_TMessageKey.PHONE_NUMBER] = number
        return tMessage
    }
    
    public static func getPinMessage(f_pin: String, data: String, oppositePin: String, chatId: String, scopeId: String) -> TMessage {
        let tMessage = NexilisLite.TMessage()
        let me = User.getMyPin() ?? ""
        tMessage.mPIN = me
        tMessage.mCode = CoreMessage_TMessageCode.UPDATE_MESSAGE
        tMessage.mStatus = CoreMessage_TMessageUtil.getTID()
        tMessage.mBodies[CoreMessage_TMessageKey.F_PIN] = f_pin
        tMessage.mBodies[CoreMessage_TMessageKey.DATA] = data
        tMessage.mBodies[CoreMessage_TMessageKey.OPPOSITE_PIN] = oppositePin
        tMessage.mBodies[CoreMessage_TMessageKey.CHAT_ID] = chatId
        tMessage.mBodies[CoreMessage_TMessageKey.SCOPE_ID] = scopeId
        tMessage.mBodies[CoreMessage_TMessageKey.ITEM_CODE] = "pinorunpin"
        return tMessage
    }
    
}
