//
//  CoreMessage_TMessageCode.swift
//  Runner
//
//  Created by Yayan Dwi on 15/04/20.
//  Copyright © 2020 The Chromium Authors. All rights reserved.
//

import Foundation

public class CoreMessage_TMessageCode {
    
    public static let HEART_BEAT = "H";
    
    public static let PUSH_INCOMING_EMAIL      = "PIM";
    
    public static let WEB_LOGIN_QR = "WLQR";
    
    public static let REQUEST_NPM                        = "B0";
    public static let PUSH_NPM                           = "B1";
    public static let CHANGE_USER_ID                   = "B2";
    public static let REQUEST_BUDDIES                     = "B3";
    public static let REQUEST_GROUPS                   = "B4";
    public static let REQUEST_GROUP                    = "B4A";
    public static let REQUEST_GROUPS_WITHOUT_MEMBER    = "B4B";
    public static let REQUEST_GROUP_MEMBERZ            = "B5";
    public static let SUBMIT_FRESH_REGISTRATION        = "B6";
    public static let SUBMIT_EMAIL_REGISTRATION        = "B7";
    public static let SEND_EMAIL_LOGIN_CODE             = "IH8";
    public static let SEND_LOGIN_CODE_SIGNUP             = "B8A";
    public static let RETRIEVE_LOGIN_SUGGEST             = "B8B";
    public static let REQUEST_BLOGS_AT_PLACE              = "B9";
    public static let SUBMIT_BACKDOR_REGISTRATION      = "Ba";
    public static let SEND_EMAIL_CHANGE_CODE              = "Bb";
    public static let PUSH_COIN                          = "Bc";
    public static let UPDATE_TICKER                    = "Bd";
    public static let DELETE_TICKER                    = "Be";
    public static let DELETE_ALL_TICKER                = "Bf";
    public static let REQUEST_STICKER_SET_LIST         = "Bg";
    public static let REQUEST_STICKER_SET_DETAIL         = "Bh";
    public static let REQUEST_STICKER                     = "Bi";
    public static let PUSH_STICKER_SET_SIMPLE_DETAIL     = "Bj";
    public static let PUSH_STICKER_SET_DETAIL             = "Bk";
    public static let PUSH_STICKER                     = "Bl";
    public static let REQUEST_OFFICIAL_LIST        = "Bm";
    public static let REQUEST_OFFICIAL_DETAIL        = "Bn";
    public static let REQUEST_OFFICIAL_BLOG        = "Bo";
    public static let PUSH_OFFICIAL_SIMPLE_DETAIL    = "Bp";
    public static let PUSH_OFFICIAL_DETAIL            = "Bq";
    public static let PUSH_OFFICIAL_BLOG            = "Br";
    public static let PUSH_TICKER_V2                 = "Bs";
    public static let DELETE_CHATROOM                 = "Bt";
    public static let PROFILE_VOIP                 = "Bu";
    public static let PROFILE_VCALL                 = "Bv";
    public static let SEND_COMMUNITY_MESSAGE        = "Bw";
    public static let REQUEST_N_COMMUNITY_USERS    = "Bx";
    public static let JOIN_APP                      = "By";
    public static let LEAVE_APP                     = "Bz";
    public static let UPDATE_EVENT                   = "BA";
    public static let RESET_EVENT                   = "BB";
    public static let CREATE_CHAT                   = "BC";
    public static let UPDATE_CHAT                   = "BD";
    public static let CHANGE_BATCH_TOPIC_INFO      = "BD01";
    public static let CHANGE_BATCH_TOPIC_MEMBER    = "BD02";
    public static let DELETE_CHAT                   = "BE";
    public static let PUSH_CHAT                       = "BF";
    public static let PUSH_DISCUSSION              = "DFR";
    public static let PUSH_CLIENT_ADDRESS          = "PCA";
    public static let UPLOAD_BLOG_COMMENT_V2        = "BG";
    public static let UPDATE_BLOG_COMMENT_STATUS   = "BH";
    public static let REQUEST_BLOG_COMMENT         = "BI";
    public static let REQUEST_USER_ACHIEVEMENTS       = "BJ";
    public static let PUSH_USER_ACHIEVEMENT           = "BK";
    public static let UPDATE_USER_ACHIEVEMENTS       = "BL";
    public static let UPLOAD_BLOG_LIKE                   = "BM";
    public static let PUSH_BLOG_LIKE                   = "BN";
    public static let REQUEST_SERVER_NOTIFICATION  = "BO";
    public static let PUSH_SERVER_NOTIFICATION     = "BP";
    public static let REQUEST_LIVE_TV              = "BQ";
    public static let PUSH_LIVE_TV                 = "BR";
    public static let REQUEST_LIVE_TV_LIST         = "BS";
    public static let PUSH_CREATE_LIVEVIDEO_NOTIFICATION
        = "BT";
    public static let REQUEST_VOD                  = "BU";
    public static let PUSH_CANCEL_LIVEVIDEO_NOTIFICATION
        = "BV";
    public static let REQUEST_SUGGESTION_LIST      = "BW";
    public static let PUSH_SUGGESTION              = "BX";
    public static let CHANGE_PRIVACY_FLAG          = "BY";
    
    public static let REQUEST_SUGGESTION_BUNDLE_LIST
        = "BZ";
    public static let PUSH_SUGGESTION_BUNDLE       = "C0";
    
    public static let SEND_UPDATE_TYPING           = "C1";
    public static let OPEN_CLOSE_EDITOR           = "C1X";
    public static let REQUEST_PERSON_BY_NAME       = "C11";
    public static let SUBMIT_NAME_REGISTRATION     = "C12";
    public static let SUBMIT_LOGIN_PIN             = "IH13";
    public static let CHANGE_CONNECTION_ID         = "CCI";
    public static let SUBMIT_MEMBER_REGISTRATION   = "C14";
    public static let REQUEST_GROUPS_BY_AREA       = "C15";
    public static let REQUEST_JOIN_GROUP             = "C16";
    public static let SUBMIT_WISHLIST              = "C17";
    public static let RETRIEVE_WISHLIST            = "C18";
    public static let WALLET_TRANSFER              = "C19";
    public static let WALLET_PUSH                  = "C20";
    public static let JOIN_CHAT                    = "C21";
    public static let GET_TRENDING_TOPIK           = "C22";
    public static let DELETE_WISHLIST              = "C25";
    public static let RETRIEVE_WISHLIST_SELF       = "C26";
    public static let SEND_EXCEPTION = "C28";
    public static let SEND_UPDATE_READ = "C29";
    public static let SEND_UPDATE_READ_SINGLE = "SURS";
    public static let PUSH_GROUP_MEMBER_BATCH = "A009A";
    
    
    public static let CONNECTION_CHECK     = "A";
    public static let CONNECTED            = "A00";
    public static let ENTER_CELL           = "A01";
    public static let ACKNOWLEDGMENT        = "A02";
    public static let DISABLE_LOCATION     = "A03";
    public static let ENABLE_LOCATION      = "A03A";
    public static let INVALID_PIN          = "A04";
    public static let DISCONNECTED         = "A05";
    public static let PROCESS_NOK          = "A06";
    public static let SEND_IPC_MESSAGE        = "A07";
    public static let MOVED                   = "A08";
    public static let NCKNOWLEDGMENT          = "A09";
    public static let ONLINE                  = "A000";
    public static let OFFLINE                 = "A999";
    public static let AWAKE                  = "A0000";
    public static let SLEEP                 = "A9999";
    
    public static let UPDATE_CTEXT              = "A002";
    public static let DELETE_CTEXT              = "S0D";
    public static let DELETE_CONVERSATION      = "A0021A";
    public static let UPDATE_MESSAGE              = "A0022";
    public static let CHANGE_PERSON_INFO       = "A003";
    public static let ADD_BUDDY                = "A005";
    public static let REQUEST_BUDDY               = "A0051";
    public static let PUSH_BUDDY               = "A0052";
    public static let REQUEST_ONLINE_BUDDIES     = "A0053";
    public static let PUSH_ONLINE_BUDDIES         = "A0054";
    public static let ACCEPT_BUDDY             = "A0055";
    public static let DELETE_BUDDY                = "A006";
    public static let CREATE_GROUP                = "A007";
    public static let EXIT_GROUP                = "A008";
    public static let PUSH_GROUP_MEMBER         = "A009";
    public static let CHANGE_GROUP_INFO        = "A010";
    public static let LOAD_MESSAGE_CACHE        = "LMC";
    
    public static let ADD_MEMBER             = "A011";
    public static let PUSH_GROUP           = "A012";
    public static let PUSH_GROUP_A         = "A012A";
    public static let CHANGE_LOCATION      = "A013";
    public static let SUBMIT_REGISTRATION  = "A014";
    public static let UPLOAD_TICKER        = "A015";
    public static let PUSH_TICKER          = "A016";
    public static let INIT_PAYMENT         = "A017";
    public static let PUSH_PAYMENT         = "A018";
    public static let CHOOSE_PAYMENT       = "A019";
    public static let UPLOAD_SVIDEO        = "A020";
    
    //    public static let FOLLOW_BUDDY         = "A021";
    //    public static let UNFOLLOW_BUDDY       = "A022";
    public static let UPLOAD_IMAGE_TICKER  = "A023";
    public static let CHANGE_TIMEZONE      = "A024";
    public static let UPLOAD_BLOG              = "A025";
    public static let ADD_INVITATION          = "A026";
    public static let REQUEST_REFERRERS    = "A027";
    public static let PUSH_REFERRER          = "A028";
    public static let CHOOSE_REFERRER      = "A029";
    
    public static let CHANGE_OFFMP            = "A030";
    public static let UPLOAD_NETWORK_TYPE     = "A031";
    public static let PUSH_CHATROOM        = "A032";
    public static let EXIT_CHATROOM        = "A033";
    public static let ENTER_CHATROOM        = "A034";
    public static let UPLOAD_FILE          = "A035";
    public static let UPLOAD_FILE_PROGRESS = "A0351";
    public static let PUSH_IMAGE           = "A036";
    public static let PUSH_MYSELF            = "A037";
    public static let PUSH_MYSELF_ACK       = "A037A";
    public static let CREATE_PLACE            = "A038";
    public static let PUSH_PLACE            = "A039";
    
    public static let CREATE_CHATROOM        = "A040";
    public static let REQUEST_PLACE        = "A041";
    public static let REQUEST_CHATROOM     = "A042";
    public static let PUSH_TICKER_QUEUE    = "A043";
    public static let INIT_TICKER_ON_PLACE = "A044";
    public static let SHUTDOWN             = "A045";
    public static let TRIAL_VERSION        = "A046";
    public static let INIT_BLOG_COMMENT    = "A047";
    public static let PUSH_BLOG_COMMENT    = "A048";
    public static let UPLOAD_BLOG_COMMENT    = "A049";
    
    public static let POST_REGISTRATION     = "A050";
    public static let POST_REGISTRATION_IOS     = "A050S";
    public static let ACTIVATE_TAXI           = "A051";
    public static let DEACTIVATE_TAXI         = "A052";
    public static let START_TAXI              = "A053";
    public static let STOP_TAXI             = "A054";
    public static let FIND_TAXI               = "A055";
    public static let PUSH_TAXI               = "A056";
    public static let PUSH_PASSENGER          = "A057";
    public static let UPDATE_TAXI           = "A059";
    
    public static let PUSH_BLOG     = "A060";
    public static let INIT_BLOG     = "A061";
    public static let ENTER_BLOG     = "A062";
    public static let SHARE_VIDEO     = "A063";
    public static let BLOCK_BUDDY   = "A064";
    public static let UNBLOCK_BUDDY = "A065";
    public static let PUSH_SVIDEO   = "A066";
    public static let UPLOAD_VIDEO     = "A067";
    public static let NOTIFY_BLOG     = "A068";
    public static let NOTIFY_SVIDEO = "A069";
    
    public static let INIT_SVIDEO                = "A070";
    public static let BLOCK_GROUP                = "A071";
    public static let UNBLOCK_GROUP            = "A072";
    public static let UPLOAD_AUDIO                = "A073";
    public static let PUSH_VIDEO               = "A074";
    public static let PUSH_AUDIO               = "A075";
    public static let PUSH_PLACE_ON_CELL     = "A076";
    public static let ENTER_PLACE              = "A077";
    public static let RETRIEVE_PLACE_ON_CELL = "Aa";
    public static let EXIT_PLACE               = "A078";
    public static let PUSH_CHATROOM_ON_PLACE = "A079";
    
    //  public static let REQUEST_CHATROOM             = "A080";
    public static let INIT_SIMAGE                 = "A081";
    public static let UPLOAD_MYIMAGE               = "A082";
    public static let PUSH_MYIMAGE                 = "A083";
    public static let NOTIFY_SIMAGE               = "A084";
    public static let CHANGE_HLOCATION_STATUS     = "A085";
    public static let CHANGE_OFFLINE_MODE         = "A086";
    public static let UPLOAD_THUMB                 = "A087";
    public static let PUSH_THUMB                = "A088";
    public static let UPDATE_BLOG_STATUS         = "A089";
    
    public static let UPDATE_MYIMAGE_STATUS         = "A090";
    public static let CHANGE_GROUP_MEMBER_POSITION = "A091";
    public static let CHANGE_PLACE_INFO            = "A092";
    public static let DELETE_PLACE                 = "A093";
    public static let ADD_MULTIPLE_BUDDIES            = "A094";
    public static let CANCEL_INVITATION            = "A095";
    public static let REMOVE_REFERRER                  = "A096";
    public static let DECLINE_DOWNLINE                  = "A097";
    public static let REFRESH_GROUP                = "A098";
    public static let ADD_FRIEND                   = "A099";
    public static let ADD_FRIEND_QR                = "A100";
    public static let ADD_FRIEND_IMEI              = "A100A";
    public static let REMOVE_FRIEND                = "A100B";
    public static let CHECK_FRIEND                 = "A100C";
    public static let CONTACT_LIST                 = "CL";
    
    //    public static let REQUEST_APPS          = "A100";
    //    public static let PUSH_APP_PREVIEW      = "A101";
    //    public static let PUSH_APP_DETAIL       = "A102";
    //    public static let JOIN_APP              = "A103";
    //    public static let LEAVE_APP               = "A104";
    //    public static let PUSH_APP              = "A105";
    //    public static let REQUEST_APP_DETAIL    = "A106";
    public static let ADD_MULTIPLE_BUDDIES_BY_EMAIL = "A108";
    public static let IMAGE_DOWNLOAD = "A109";
    
    public static let REQUEST_FORM_LIST = "A112";
    public static let FORM_PUSH = "A113";
    public static let FORM_PUSH_UPDATE = "A113A";
    public static let FORM_PIC_SUBMIT = "A114";
    public static let SUBMIT_FORM    = "A115";
    public static let APPROVE_FORM   = "A115A";
    public static let FOLLOW_FORM = "A115B";
    public static let SUB_ACTIVITY_UPDATE = "A115C";
    public static let APPROVE_SUBMIT_STATUS   = "A115D";
    
    public static let FOLLOW_PERSON         = "B01";
    public static let UNFOLLOW_PERSON       = "B02";
    public static let PUSH_FOLLOW           = "B03";
    public static let REQUEST_FOLLOWER_SIZE = "B04";
    public static let PUSH_FOLLOWER_SIZE     = "B05";
    
    public static let INIT_SCREEN_DRAW      = "B06";
    public static let START_DRAW            = "B07";
    public static let ON_DRAW               = "B08";
    public static let END_DRAW              = "B09";
    public static let CLOSE_SCREEN_DRAW     = "B10";
    public static let CLEAR_SCREEN_DRAW     = "B11";
    
    public static let REQUEST_FAMILY        = "B12";
    public static let PUSH_FAMILY           = "B13";
    public static let PUSH_FAMILY_MEMBER    = "B14";
    public static let CREATE_FAMILY         = "B15";
    public static let ADD_FAMILY_MEMBER     = "B16";
    public static let PUSH_PARENT           = "B17";
    public static let REQUEST_PARENT        = "B18";
    public static let CHANGE_FAMILY_INFO    = "B19";
    public static let REQUEST_CHILD         = "B20";
    public static let PUSH_CHILD            = "B21";
    public static let PUSH_EMAIL_USED       = "B22";
    
    public static let PUSH_ITEM             = "B23";
    public static let SEND_ITEM             = "B24";
    
    public static let REQUEST_VOD_LIST         = "B25";
    public static let REQUEST_VOD_LIST_BY_LAST_UPDATE = "B251";
    public static let PUSH_VOD                 = "B26";
    public static let UPDATE_VIDEO_VIEWS       = "B27";
    
    public static let CREATE_LIVE_VIDEO    = "B28";
    public static let CREATE_LS = "B28a";
    public static let START_LP_INVITED = "B28b";
    public static let UPDATE_LIVE_VIDEO    = "ULV";
    public static let REMOVE_LIVE_VIDEO    = "B29";
    public static let JOIN_LIVE_VIDEO      = "B30";
    public static let REQUEST_N_LIVE_VIDEO = "B31";
    public static let REQUEST_LIVE_VIDEO   = "B32";
    public static let REQUEST_LIVE_VIDEO_PUBLIC   = "B32B";
    public static let PUSH_LIVE_VIDEO      = "B33";
    public static let PUSH_LIVE_VIDEO_LIST = "B33A";
    public static let PUSH_LIVE_VIDEO_LIST_PUBLIC = "B33B";
    public static let PULL_FRIEND_LIST_INFO = "B33C";
    public static let LEFT_LIVE_VIDEO      = "B34";
    public static let START_LIVE_VIDEO      = "SLV";
    public static let REQUEST_START_LIVE_VIDEO = "RLV";
    public static let OUT_FROM_STREAMING_TAB   = "OLS";
    
    public static let SEMINAR_START_INVITED = "CSR0";
    public static let SEMINAR_CREATE = "CSR1";
    public static let SEMINAR_PUSH_CHAT = "CSR2";
    public static let SEMINAR_PUSH_JOIN = "CSR3";
    public static let SEMINAR_JOIN = "CSR4";
    public static let SEMINAR_REMOVE = "CSR5";
    public static let SEMINAR_LEFT = "CSR6";
    public static let SEMINAR_PUSH_LEFT = "CSR7";
    public static let SEMINAR_PUSH_RAISE_HAND = "CSR8";
    public static let SEMINAR_DRAW = "CSR10";
    public static let SEMINAR_FACE_DETECTION = "CSR11";
    
    public static let GET_BATCH_BUDDIES_BASED_SCROLL     = "C70";
    public static let CHANGE_BATCH_PERSON_INFO_BASED_SCROLL = "A00X4";
    
    
    public static let REQUEST_BUDDY_INFO     = "B35";
    
    public static let REQUEST_GROUP_MEMBER = "A107";
    public static let REQUEST_OFFLINE_BUDDIES = "A108";
    
    public static let REQUEST_RSS = "C4";
    public static let NEARBY_VISIBLE = "C5";
    public static let NEARBY_INVISIBLE = "C6";
    public static let TENDER = "C7";
    public static let NOTIFICATION = "C8";
    public static let LAUNCH_APP = "C9";
    
    public static let GET_QUOTES = "C32";
    public static let SET_AUTO_QUOTE = "C33";
    
    public static let SEND_CHAT = "S0";
    public static let SEND_CHAT_WEB = "Z10";
    public static let NOTIFICATION_UPDATE = "NTF"; //S
    public static let REQUEST_PERSON_BY_USERID     = "C27";
    public static let REQUEST_PERSON_BY_DEVICEID       = "C44";
    public static let UPDATE_PENDING_SID       = "C45";
    public static let CHECKIN       = "C46";
    public static let SEND_VERSION_STATE = "VRS"; //S
    public static let EDIT_MESSAGE = "EM01";
    
    
    public static let GET_BALANCE   = "C35";
    public static let GET_TOPUP     = "TPU";
    public static let WALLET_GET   = "";
    public static let WALLET_LOCK_UPDATE  = "C36";
    public static let WALLET_LOCK_GET  = "C37";
    public static let PUSH_PRODUCT                 = "C40";
    public static let PUSH_STOCK       = "C41";
    public static let WALLET_BUY       = "C42";
    public static let QUERY_GET        = "C43";
    public static let WALLET_BALANCE   = "C47";
    
    public static let CHANGE_BATCH_PERSON_INFO = "A004"; //S
    public static let GET_BATCH_BUDDY_INFO     = "C48";
    public static let PUSH_OFFICE     = "C49";
    public static let GET_BUDDY_INFO = "C34";
    public static let CHECKIN_POS = "C50";
    public static let CHECKOUT_POS = "C51";
    public static let REPLACE_OFFICE     = "RPO";
    public static let REPLACE_BUDDIES = "RPP";
    
    public static let INIT_BATCH_BUDDY = "IBB";
    public static let INIT_FOLLOW = "IBF";
    public static let INIT_BATCH_GROUP = "IBG";
    public static let INIT_BATCH_GROUP_NO_MEMBERS = "GNM";
    public static let INIT_BATCH_TOPIC = "IBT";
    public static let INIT_PREFS = "ITT";
    public static let PULL_PREFS = "PPR";
    public static let INIT_FLAG_FINISH = "IFF";
    public static let INIT_FLAG_RESET  = "IFR";
    
    public static let GET_POS_TRANS_HISTORY = "C52";
    public static let GET_POS_TRANS_HISTORY_DETAIL = "C53";
    public static let CANCEL_TRANSACTION             = "C54";
    public static let GET_COMMENTS             = "C55";
    public static let SEND_COMMENTS             = "C56";
    public static let ON_EDITOR_COMMENT         = "C57";
    public static let DELETE_COMMENTS          = "C58";
    public static let DELETE_POST          = "C59";
    public static let GET_FOLLOW               = "A101";
    public static let GET_UNFOLLOW               = "A102";
    
    public static let UPDATE_RUNNING_TEXT      = "URR";
    public static let INCOMING_EMAIL      = "IE";
    public static let INCOMING_SMS        = "ISMS";
    public static let INCOMING_LOCATION      = "IL";
    public static let INCOMING_GPS_STATE      = "IG";
    public static let SHARE_FORUM      = "SFR";
    public static let FOLLOW_FORUM      = "FLF";
    public static let TASK_PROGRESS_DASHBOARD      = "DBD";
    public static let TASK_PROGRESS_RETRIEVE      = "A117";
    public static let TASK_PROGRESS_RETRIEVE_SUB_ACTIVITY      = "RPT_LV1";
    public static let TASK_PROGRESS_RETRIEVE_TASK_TITLE      = "RPT_LV2";
    public static let INCOMING_AUTO_MESSAGE  = "IAM";
    public static let SCREEN_SHARING              = "SS";
    public static let SCREEN_SHARING_STOP              = "SS1";
    
    public static let GET_FROM_SERVER = "GFS";
    public static let CALL_SUGGESTION = "CSG";
    
    public static let LIVE_CONFERENCE_START = "LC01";
    public static let LIVE_CONFERENCE_JOIN = "LC02";
    public static let LIVE_CONFERENCE_TOA = "LC03";
    public static let LIVE_CONFERENCE_ZOOM = "LC04";
    public static let LIVE_CONFERENCE_MESSAGE_END = "LC05";
    public static let LIVE_CONFERENCE_END = "LC99";
    
    public static let RESET_1 = "RST1";
    public static let RESET_2 = "RST2";
    public static let RESET_3 = "RST3";
    
    public static let SUBMIT_LOGIN_PAY = "BAA";
    public static let SUBMIT_REGISTER_PAY = "BAB";
    public static let SEND_EMAIL_LOGIN_CODE_PAY = "BAC";
    public static let GET_PRODUCT_INFO = "BAD";
    public static let VALIDATE_PAY = "BAE";
    public static let CONFIRM_PAY = "BAF";
    public static let CONFIRM_PAY_RESPONSE = "BAG";
    
    public static let SEND_SIGNUP_DATA = "SSU01";
    public static let SEND_SIGNIN = "SSI01";
    public static let RETRIEVE_TPS = "SSU02";
    public static let RETRIEVE_REAL_COUNT = "SSU23";
    public static let RETRIEVE_PERSON_BY_NAME = "SSU24";
    public static let RETRIEVE_PERSON_SUGGESTION = "SSS24";
    public static let RETRIEVE_PERSON_BY_PHOTO = "SSU27";
    public static let UPLOAD_TIMELINE = "SSU03";
    public static let PUSH_VGT = "SSU04";
    public static let UPDATE_VGT_VIEWS       = "SSU05";
    public static let CHANGE_PRIVACY = "SSU07";
    public static let CHANGE_PUBLISH = "SSU08";
    public static let PULL_MYSELF = "SSU09";
    public static let EDIT_TIMELINE       = "SSU10";
    public static let PARTICIPATE_TIMELINE       = "SSU11";
    public static let GET_LIST_PARTICIPANT        = "SSU13";
    public static let GET_CONTENT_PARTICIPATE        = "SSU14";
    
    public static let SEND_POST_SHARE="SSU12";
    
    public static let BILLING_TRANS_WARUNG             = "SSU20";
    public static let BILLING_TRANS_WARUNG_CANCEL      = "SSU30";
    public static let SCAN_PAY_TRANS_WARUNG        = "SSU21";
    public static let PUSH_DATA_TRANS_WARUNG       = "SSU22";
    
    public static let GET_ADS = "GAD";
    public static let TYPE_ADS = "A30";
    
    public static let GET_COUNT_POST_FOLLOWERS_FOLLOWING = "C60";
    
    
    /**
     * Web
     */
    public static let CONNECTED_FROM_WEB = "CFW";
    public static let DISCONNECTED_FROM_WEB = "DFW";
    public static let GET_INFO_MESSAGE_FROM_WEB = "Z07";
    public static let RETRIEVE_UC_LIST = "Z08";
    public static let LOAD_MORE_MESSAGE_FROM_WEB = "Z09";
    
    public static let SEND_CHAT_FROM_WEB = "Z10";
    public static let SEND_UPDATE_READ_FROM_WEB = "Z11";
    public static let DELETE_CHAT_FROM_WEB = "Z12";
    public static let SEARCH_CHAT_FROM_WEB = "Z13";
    public static let ADD_TAG_MESSAGE_FROM_WEB = "Z14";
    public static let DELETE_CONVERSATION_FROM_WEB = "Z15";
    public static let SEND_UPDATE_READ_SINGLE_FROM_WEB = "Z16";
    public static let CONFIRMATION_IM_FROM_WEB = "Z18";
    
    public static let CHANGE_PERSON_INFO_FROM_WEB = "Z25";
    public static let MARK_ALL_AS_READ_FROM_WEB = "Z26";
    public static let UPDATE_MESSAGES_FROM_WEB = "Z27";
    public static let LOAD_FAVORITE_MESSAGES_FROM_WEB = "Z28";
    public static let GET_MESSAGE_OBJECT_FROM_WEB = "Z29";
    public static let CREATE_GROUP_FROM_WEB = "Z30";
    public static let DELETE_GROUP_FROM_WEB = "Z31";
    public static let LEAVE_GROUP_FROM_WEB = "Z32";
    public static let CHANGE_GROUP_INFO_FROM_WEB = "Z33";
    public static let ADD_TOPIC_FROM_WEB = "Z36";
    public static let REMOVE_TOPIC_FROM_WEB = "Z37";
    public static let UPDATE_TOPIC_FROM_WEB = "Z38";
    public static let CHANGE_GROUP_MEMBER_POSITION_FROM_WEB = "Z41";
    public static let ADD_MEMBER_FROM_WEB = "Z39";
    public static let REMOVE_MEMBER_FROM_WEB = "Z40";
    public static let LOAD_EMAIL_FROM_WEB = "Z51";
    public static let ADD_EMAIL_FROM_WEB = "Z52";
    public static let CONNECT_DISCONNECT_EMAIL_FROM_WEB = "Z53";
    public static let REMOVE_EMAIL_FROM_WEB = "Z54";
    
    public static let GET_DATA_CALENDAR_FROM_WEB = "Z58";
    public static let VIEW_MEDIA_FROM_WEB = "Z59";
    public static let POST_REACTION = "Z60";
    public static let POST_RETRIEVE = "PSR";
    public static let POST_INCOMING = "PSI";
    
    public static let POST_RETRIEVE_STRUCTURE = "PRS";
    public static let POST_RETRIEVE_CONTENT = "PRC";
    
    public static let POST_RETRIEVE_STRUCTURE_NEWEST = "PRSa";
    public static let POST_RETRIEVE_STRUCTURE_PREVIOUS = "PRSz";
    
    public static let POST_INCOMING_STRUCTURE = "PIS";
    public static let POST_INCOMING_CONTENT = "PIC";
    public static let POST_REMOVE_CONTENT = "PRC";
    
    public static let FACE_RECOGNITION = "FAE";
    public static let FACE_RECOGNITION_KTP = "FAEQ";
    public static let FACE_RECOGNITION_TWOFACE = "FAET";
    public static let FACE_RECOGNITION_COMPARE = "FRC";
    
    public static let LIVE_PROFILE_PUSH_JOIN = "LPJ";
    public static let LIVE_PROFILE_PUSH_LEAVE = "LPL";
    public static let LIVE_PROFILE_PUSH_CHAT = "LPC";
    public static let LIVE_PROFILE_EMOTION_SEND = "LPES";
    public static let LIVE_PROFILE_EMOTION_GET = "LPEG";
    
    public static let POST_REPORT = "Z61";
    public static let SAVE_CALL_HISTORY = "CH";
    public static let CONCALL_INVITATING = "IV";
    
    public static let POST_INCREASE_VIEWER = "PIV";
    
    public static let GET_LIST_FOLLOWER = "GLF";
    public static let GET_LIST_LIKE = "GLL";
    public static let GET_LIST_FOLLOWING = "GLG";
    
    public static let GET_OFFLINE_MESSAGES = "GOM";
    public static let GET_OFFLINE_MESSAGES_COUNTER = "GOC";
    public static let LOGIN_FILE = "LF";
    public static let INIT_BATCH_NEW_DF = "IDF";
    public static let INIT_BATCH_NEW_DF_FORM = "IDO";
    public static let RESET_UPGRADE = "RSU";
    public static let RESET_FORCE   = "RSF";
    public static let VERSION_CHECK   = "VC";
    
    public static let GET_LOGIN_BY_SMS_ENABLED = "SMSE";
    public static let UPDATE_IP_ADDRESS = "UIP";
    public static let UNKNOWN_MESSAGE = "UNKM";
    public static let DIF_OPEN   = "DFO";
    public static let SEND_UPDATE_UNREAD = "C30";
    public static let SEND_UPDATE_READ_WEB = "Z11";
    public static let SEND_UPDATE_READ_SINGLE_WEB = "Z16";
    public static let DELETE_IM_WEB = "Z12";
    public static let UPDATE_MESSAGES_WEB = "Z27";
    public static let CONFIRMATION_IM_WEB = "Z18";
    public static let ADD_TAG_IM_WEB = "Z14";
    public static let SEND_UPDATE_READ_BY_TIME = "C29T";
    
    public static let GET_TRANS_HISTORY   = "SSU25";
    public static let GET_TRANS_DETAIL   = "SSU26";
    
    public static let GET_BLOCK = "A120";
    public static let GET_UNBLOCK = "A121";
    
    public static let VIDEO_CALL_PUSH_CHAT = "VCC";
    
    public static let ASKING_FOR_END_CALL = "ASKE";
    
    public static let END_CALL = "ENCL";
    public static let INCOMING_CALL_CC = "ICS";
    
    public static let POST_RETRIEVE_PROFILE = "PIP";
    public static let POST_RETRIEVE_TIMELINE = "PIT";
    public static let POST_RETRIEVE_BY_ID = "PID";
    public static let POST_UPDATE_STORY      = "PUS";
    
    public static let GET_SIMPLE_PERSON_INFO = "CP5";
    
    public static let PULL_MESSAGE = "PMS";
    public static let PULL_MESSAGE_PREVIEW = "PMP";
    public static let PULL_STORY_LIST      = "PSL";
    public static let PULL_STORY_LIST_PERSONAL = "PSLP";
    public static let PULL_MAIN_CONTENT    = "PMC";
    public static let PULL_CHANNEL_LIST    = "PCL";
    public static let SUSPEND_USER    = "SPU";
    public static let GET_OPEN_GROUPS = "GOG";
    public static let CHAT_FILTER     = "CFL";
    
    public static let ASKING_RESPONSE = "AKR";
    public static let TRX = "TRX";
    public static let FETCH_LINK = "FLI";
    public static let GET_PERSON_NEARBY = "NRB";
    
    public static let SUBMIT_SURVEY_COVID = "SCV";
    public static let SUBMIT_SURVEY_COVID_ADDITIONAL = "SCVA";
    public static let NOTIFICATION_COVID = "NTFC";
    public static let GET_FRM_DATA_COVID = "GFRM1";
    public static let SUBMIT_FRM_DATA_COVID = "SFRM1";
    public static let GET_FRM_PENERIMAAN_APD_COVID = "GFRM2";
    public static let SUBMIT_FRM_PENERIMAAN_APD_COVID = "SFRM2";
    public static let GET_FRM_USAGE_COVID = "GFRM3";
    public static let SUBMIT_FRM_USAGE_COVID = "SFRM3";
    public static let GET_FRM_RESEP = "GFRM4";
    public static let SUBMIT_FRM_RESEP = "SFRM4";
    
    
    public static let GET_PERSON_BY_NAME = "USR";
    public static let GET_PERSON_BY_PIN  = "TRC";
    public static let GET_SITUASI_COVID  = "CVS";
    public static let GET_DOCTOR_NEARBY  = "GDN";
    
    public static let GET_BLE_NEARBY  = "BLN";
    public static let CHANGE_USER_TYPE  = "CUT";
    
    public static let GET_LS_INFO = "LS01";
    public static let VC_ROOM_CREATE = "VCR";
    public static let VC_ROOM_START = "VCR1";
    public static let VC_ROOM_JOIN = "VCR2";
    public static let VC_ROOM_END = "VCR2";
    public static let VC_ROOM_WHITEBOARD_IMAGE = "VCR3";
    public static let VC_ROOM_DRAW = "VCR4";
    
    //Signup-Signin MSISDN dan OTP
    public static let VERIFY_OTP = "VOTP";
    public static let SEND_SIGNUP_MSISDN = "B8C";
    public static let SEND_CHANGE_MSISDN = "B8D";
    public static let SEND_SIGNIN_OTP = "SSI01A";
    public static let SEND_SIGNUP_OTP = "SSU01O";
    public static let SEND_VERIFY_LOGIN = "SVL";
    public static let SEND_OTP_LOGIN = "SOTL";
    
    //Whiteboard
    public static let DRAW_WHITEBOARD = "DWB";
    
    //APN
    public static let APN_TOKEN   = "ATO";
    
    //sub group
    public static let CREATE_SUB_GROUP   = "A007A";
    
    
    //REGISTER VS
    public static let SEND_LOGIN_EMAIL = "SLE";
    public static let SEND_VERIFICATION = "SVE";
    
    public static let GET_LIST_SCHOOL = "GLS";
    
    public static let UPDATE_USER = "RQJU";
    public static let REQUEST_TEACHER_SCHOOL = "GLS8";
    public static let REQUEST_STUDENT = "GLS7";
    public static let APPROVE_REQUEST_STUDENT = "GLS4";
    public static let GET_REQUEST_TEACHER = "GLS5";
    public static let APPROVE_REQUEST_TEACHER = "GLS6";
    public static let GET_REQUEST_STUDENT = "GLS3";
    public static let GET_LIST_CLASS_NAME = "GLC";
    public static let SUBMIT_SCHOOL = "GLS2";
    
    public static let SUB_ACCOUNT_DETAIL = "SAD";
    public static let SUB_ACCOUNT_LIST = "SAL";
    public static let SUB_ACCOUNT_SUBMIT = "SAS";
    public static let SUB_ACCOUNT_CHANGE = "SAC";
    public static let SUB_ACCOUNT_PUSH_FILTERING = "SAF";
    
    public static let IS_INITIATOR_JOIN = "CSR9";
    public static let QUIZ_DETAIL = "QZD";
    public static let QUIZ_ANSWER = "QZA";
    public static let QUIZ_SCORING = "QZS";
    
    public static let REQUEST_CALL_CENTER = "CC01"; // sync
    public static let PUSH_CALL_CENTER = "CC02"; // async
    public static let ACCEPT_CALL_CENTER = "CC03"; // sync
    public static let END_CALL_CENTER = "CC04"; // sync
    public static let MANAGEMENT_CONTACT_CENTER = "CC05";
    public static let FEATURE_ACCESS = "FA01";
    public static let BROADCAST_MESSAGE = "BM01";

    public static let SIGN_IN_API_CREATOR = "SIA02";
    public static let SIGN_IN_API_ADMIN = "SIA03";
    public static let SIGN_IN_API_INTERNAL = "SIA04";
    public static let TIMEOUT_CONTACT_CENTER = "CC06";

    public static let CHANGE_PSWD_ADMIN = "CP01";
    public static let CHANGE_PSWD_INTERNAL = "CP02";
    public static let EMAIL_CONTACT_CENTER = "CC07";
    public static let QUEUING_CONTACT_CENTER = "CC08";
    public static let STATUS_CONTACT_CENTER = "CC09";
    public static let DRAW_CONTACT_CENTER = "CC10";
    public static let ADD_CALL_CONTACT_CENTER = "CC11";
    public static let END_CALL_CONTACT_CENTER = "CC12";
    public static let IS_ACTIVE_CALL_CONTACT_CENTER = "CC13";
    public static let INVITE_TO_ROOM_CONTACT_CENTER = "CC14";
    public static let ACCEPT_CONTACT_CENTER = "CC15";
    public static let PUSH_MEMBER_ROOM_CONTACT_CENTER = "CC16";
    public static let INVITE_END_CONTACT_CENTER = "CC17";
    public static let INVITE_EXIT_CONTACT_CENTER = "CC18";
    public static let REQUEST_SECOND_CONTACT_CENTER = "CC19"; // sync
    public static let PUSH_SECOND_CONTACT_CENTER = "CC20";
    public static let RESPOND_SECOND_CONTACT_CENTER = "CC21"; // sync
    public static let GET_WORKING_AREA_CONTACT_CENTER = "CC22"; // sync
    public static let PUSH_SUBSCRIPTION_SIZE = "PS01";
    
    public static let SIGN_UP_API = "SUA01";
    public static let CHECK_PSWD = "CPW";
    
    public static let GET_LIST_DISCUSSION = "GLD";
    public static let GET_DISCUSSION_COMMENT = "GDC";
    public static let LEAVE_DISCUSSION_COMMENT = "LDC";
    public static let SEND_DISCUSSION_COMMENT = "SDC";
    public static let PUSH_DISCUSSION_COMMENT = "PDC";
    
    public static let SEND_OTP_CHANGE_DEVICE = "SOTD";
    public static let SEND_OTP_CHANGE_DEVICE_GASPOL = "SOTG";
    public static let SEND_OTP_CHANGE_PROFILE = "SOTP";
    public static let SEND_VERIFY_CHANGE_DEVICE = "SVTD";
    
    public static let PULL_GROUP_CATEGORY = "PGC";
    public static let GET_SERVICE_BNI = "GBNI";
    public static let PUSH_SERVICE_BNI = "PBNI";
    public static let REQUEST_TICKET_BNI = "RTB";
    public static let REQUEST_TOP_UP_BNI = "RTP";
    public static let PULL_FLOATING_BUTTON = "PFB";
    
    public static let GET_CUSTOMER_INFO = "GCI"; // sync
    public static let INQUIRY = "INQ";
    public static let MOBILE_INQUIRY = "MINQ";
    
    public static let SIGN_UP_AND_SIGN_IN_API = "SUAI01";
    public static let BACKUP_AVAILABILITY = "BUA2";
    public static let BACKUP_UPLOADED = "BUU2";
    public static let BACKUP_RESTORED = "BUR2";
    
    public static let LOGOUT = "LGT";
    
    public static let FORWARD_MESSAGE = "C2";
    public static let WB_INCOMING = 101;
    public static let WB_OFFHOOK = 102;
    public static let WB_RINGING = 103;
    public static let WB_ACCEPT_INCOMING = 104;
    public static let WB_REJECT_INCOMING = 105;
    public static let WB_END = 108;

    public static let SS_INCOMING = 121;
    public static let SS_OFFHOOK = 122;
    public static let SS_RINGING = 123;
    public static let SS_ACCEPT_INCOMING = 124;
    public static let SS_REJECT_INCOMING = 125;
    public static let SS_END = 128;
    
    public static let GET_BATCH_GROUP_NO_MEMBERS = "GGNM";
    
    public static let CALLING = "CALL";
    public static let NOTIFY_TO_CALLING = "NTC";
    public static let CANCEL_CALL_NOTIFICATION = "CCN";
    
    public static let FEATURE_ACCESS_ALL = "FA02";
    
    public static let PAYMENT_NOTIFICATION = "PAY";
    
    public static let ALERT_NEW_SIGN_IN = "ANSI";

    public static let SHIELD_SECURITY_VALIDATE_TOKEN = "SSVT";
    public static let BLOCK_ACCESS = "BLK";
    
    public static let RESET_SUPER_APP = "RSA";
    public static let GPT = "GPT";
    
    public static let MUTE_AC_VC = "MAV";
    public static let LS_TARGET = "LST";
    public static let GET_MESSAGE_BY_ID = "GMID";
    public static let SECURITY_SHIELD_LOGGING = "SSG";

    public static let IS_CALLING = "ICA";
    public static let ACK_PUSH_CC = "ACC";
    public static let ACK_MESSAGE_BY_ID = "AMID";
    public static let MOBILE_ACTIVITY_REPORT = "MAR";
    public static let CHECK_OFFLINE = "COF";
    public static let GET_SS_CONTENT = "SS02";
    public static let ACCEPT_REJECT_MEETING = "MTG";
    public static let GET_CHATBOT_SCHEDULE = "CHS";
    public static let GPT_SERVICE = "GPTS";
}
