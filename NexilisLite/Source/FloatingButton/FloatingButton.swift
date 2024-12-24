//
//  FloatingButton.swift
//  Qmera
//
//  Created by Yayan Dwi on 03/09/21.
//

import UIKit
import nuSDKService
import NotificationBannerSwift


public class FloatingButton: UIView {
    
    var groupView: UIStackView!
    var scrollView: UIScrollView!
    var imageScrollView: UIImageView!
    var button_fb1: UIButton!
    var button_fb2: UIButton!
    var button_fb3: UIButton!
    var button_fb4: UIButton!
    var nexilis_button: UIImageView!
    var nexilis_pin: UIImageView!
    var leadingConstraintPin: NSLayoutConstraint!
    var bottomConstraintPin: NSLayoutConstraint!
    var trailingConstraintPin: NSLayoutConstraint!
    var topConstraintPin: NSLayoutConstraint!
    var lastPosY: CGFloat?
    var lastImageButton = ""
    var iconCC = ""
    
    let indicatorCounterFB = UIView()
    let labelCounterFB = UILabel()
    let indicatorCounterFBBig = UIImageView()
    
    var datePull: Date?
    var animationTimer = Timer()
    var configAnim: Int = Int(Utils.getFloatingAnim().components(separatedBy: "~")[0]) ?? 1
    var isLoopingAnim = (Int(Utils.getFloatingAnim().components(separatedBy: "~")[1]) ?? 1) == 1 ? true : false
    var lastRunAnimationHrz = -1
    var lastRunAnimationVrt = -1
    
    var panGesture: UIPanGestureRecognizer?
    var defaultWidthFB = (UIScreen.main.bounds.height * 0.5) / 7.5
    var defaultHeightFB = (UIScreen.main.bounds.height * 0.5) / 7.5
    let defaultWidthHeightMenuFB = (UIScreen.main.bounds.height * 0.45) / 7.5
    let widthFBAnim = (UIScreen.main.bounds.height * 0.8) / 7.5
    let heightFBAnim = (UIScreen.main.bounds.height * 1) / 7.5
    let heightFBSideTab = (UIScreen.main.bounds.height * 1.05) / 7.5
    let widthFBSideTab: CGFloat = 18
    let widthVerticalSideTab: CGFloat = 50
    let heightVerticalSideTab: CGFloat = 220
    
    final let MODE_VERTICAL_FLOATING_BUTTON = "1"
    final let MODE_VERTICAL_ANIMATION = "2"
    final let MODE_HORIZONTAL_ANIMATION = "3"
    final let MODE_HORIZONTAL_SIDE_TAB = "4"
    final let MODE_VERTICAL_SIDE_TAB = "5"
    
    var configModeFB = "1"
    
    var countMenuFB: CGFloat = 6 {
        didSet {
            if isShow {
                show(isShow: isShow)
            }
        }
    }
    
    public weak var mySettingDelegate: SettingMABDelegate?
    
    public var isShow: Bool = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(draggedView(_:)))
        addGestureRecognizer(panGesture!)
        
        configModeFB = Utils.getConfigModeFB()
        
        nexilis_button = UIImageView()
        nexilis_button.translatesAutoresizingMaskIntoConstraints = false
        nexilis_button.isUserInteractionEnabled = true
        if configModeFB == MODE_VERTICAL_ANIMATION || configModeFB == MODE_HORIZONTAL_ANIMATION {
            defaultWidthFB = widthFBAnim
            if configModeFB == MODE_HORIZONTAL_ANIMATION {
                defaultHeightFB = heightFBAnim + 30
            } else {
                defaultHeightFB = heightFBAnim
            }
            var urlGif = URL(string: configModeFB == MODE_VERTICAL_ANIMATION ? Utils.getIconCenterAnim2() : Utils.getIconCenterAnim4())
            if (urlGif == nil) {
                urlGif = Bundle.resourceBundle(for: Nexilis.self).url(forResource: configModeFB == MODE_VERTICAL_ANIMATION ? "pb_def_icon_mode2" : "pb_def_icon_mode4", withExtension: "gif")! //resourcesMediaBundle
            }
            nexilis_button.sd_setImage(with: urlGif) { [self] (image, error, cacheType, imageURL) in
                if error == nil {
                    nexilis_button.animationImages = image?.images
                    nexilis_button.animationDuration = image?.duration ?? 0.0
                    nexilis_button.animationRepeatCount = 0
                    nexilis_button.startAnimating()
                }
            }
        } else {
            if !Utils.getIconDock().isEmpty && configModeFB == MODE_VERTICAL_FLOATING_BUTTON && Nexilis.fromMAB {
                setImageWithURL(true)
            } else {
                if configModeFB == MODE_HORIZONTAL_SIDE_TAB || configModeFB == MODE_VERTICAL_SIDE_TAB {
                    defaultWidthFB = widthFBSideTab
                    defaultHeightFB = heightFBSideTab
                }
                if !Utils.getIconCenter().isEmpty && configModeFB == MODE_VERTICAL_FLOATING_BUTTON {
                    setImageWithURL(false)
                } else {
                    nexilis_button.image = UIImage(named: configModeFB == MODE_VERTICAL_SIDE_TAB ? "pb_side_tab_vtc" : configModeFB == MODE_HORIZONTAL_SIDE_TAB ? "pb_side_tab" : "pb_button", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)
                }
            }
        }
        
        backgroundColor = .clear
        frame = CGRect(x: UIScreen.main.bounds.width - defaultWidthFB, y: (UIScreen.main.bounds.height / 2) - defaultHeightFB, width: configModeFB == MODE_VERTICAL_SIDE_TAB ? 50 + defaultWidthFB : configModeFB == MODE_HORIZONTAL_SIDE_TAB ? UIScreen.main.bounds.width - defaultWidthFB : defaultWidthFB, height: configModeFB == MODE_VERTICAL_SIDE_TAB ? heightVerticalSideTab : defaultHeightFB)
        
        if configModeFB == MODE_VERTICAL_ANIMATION || configModeFB == MODE_HORIZONTAL_ANIMATION {
            if configAnim == 0 { //left to right
                lastRunAnimationHrz = 1
            } else if configAnim == 1 { //right to left
                lastRunAnimationHrz = -1
            } else if configAnim == 2 { //top to bottom
                lastRunAnimationVrt = 1
            } else if configAnim == 3 { //top to bottom
                lastRunAnimationVrt = -1
            }
            if configAnim >= 0 && configAnim <= 3 {
                checkDelayAnimation()
            }
        }
        
        let qmeraTap = UITapGestureRecognizer(target: self, action: #selector(qmeraTap))
        qmeraTap.numberOfTouchesRequired = 1
        nexilis_button.addGestureRecognizer(qmeraTap)
        
        let qmeraLongPress = UILongPressGestureRecognizer(target: self, action: #selector(qmeraLongPress(gestureRecognizer:)))
        nexilis_button.addGestureRecognizer(qmeraLongPress)
        
        addSubview(nexilis_button)
        
        nexilis_button.widthAnchor.constraint(equalToConstant: defaultWidthFB).isActive = true
        nexilis_button.heightAnchor.constraint(equalToConstant: defaultHeightFB).isActive = true
        nexilis_button.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        if configModeFB == MODE_VERTICAL_SIDE_TAB {
            nexilis_button.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        } else {
            nexilis_button.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        }
        
        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        if Utils.getFBItemBg() == "1" && configModeFB == MODE_VERTICAL_FLOATING_BUTTON {
            scrollView.layer.borderWidth = 1.0
            scrollView.layer.borderColor = UIColor.white.cgColor
            scrollView.layer.cornerRadius = 8.0
            scrollView.layer.masksToBounds = true
            scrollView.backgroundColor = .black.withAlphaComponent(0.25)
        }
        addSubview(scrollView)
        
        if configModeFB == MODE_VERTICAL_SIDE_TAB {
            let bgImage = resizeImage(image: UIImage(named: "pb_button_background_vtcst", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, targetSize: CGSize(width: widthVerticalSideTab, height: heightVerticalSideTab))
            scrollView.backgroundColor = UIColor.init(patternImage: bgImage)
            
            scrollView.leftAnchor.constraint(equalTo: nexilis_button.rightAnchor).isActive = true
            scrollView.centerYAnchor.constraint(equalTo: nexilis_button.centerYAnchor).isActive = true
            scrollView.widthAnchor.constraint(equalToConstant: widthVerticalSideTab).isActive = true
            scrollView.heightAnchor.constraint(equalToConstant: heightVerticalSideTab).isActive = true
        } else if configModeFB != MODE_HORIZONTAL_SIDE_TAB {
            scrollView.topAnchor.constraint(equalTo: topAnchor).isActive = true
            if configModeFB == MODE_VERTICAL_ANIMATION {
                scrollView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
                scrollView.leftAnchor.constraint(equalTo: nexilis_button.rightAnchor, constant: -20).isActive = true
                scrollView.widthAnchor.constraint(equalToConstant: defaultWidthHeightMenuFB + 10).isActive = true
                scrollView.isHidden = true
            } else if configModeFB == MODE_HORIZONTAL_ANIMATION {
                scrollView.bottomAnchor.constraint(equalTo: nexilis_button.topAnchor).isActive = true
                scrollView.leftAnchor.constraint(equalTo: nexilis_button.leftAnchor).isActive = true
                scrollView.widthAnchor.constraint(equalToConstant: defaultWidthHeightMenuFB * (countMenuFB - 1)).isActive = true
            } else {
                scrollView.widthAnchor.constraint(equalToConstant: defaultWidthHeightMenuFB + 10).isActive = true
                scrollView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
                scrollView.bottomAnchor.constraint(equalTo: nexilis_button.topAnchor).isActive = true
            }
        } else {
            scrollView.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width - defaultWidthFB).isActive = true
            scrollView.heightAnchor.constraint(equalToConstant: defaultHeightFB).isActive = true
            scrollView.leftAnchor.constraint(equalTo: nexilis_button.rightAnchor).isActive = true
            scrollView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
            scrollView.backgroundColor = .black.withAlphaComponent(0.25)
        }
        
        groupView = UIStackView()
        groupView.translatesAutoresizingMaskIntoConstraints = false
        groupView.axis = (configModeFB == MODE_HORIZONTAL_SIDE_TAB || configModeFB == MODE_HORIZONTAL_ANIMATION) ? .horizontal : .vertical
        if configModeFB != MODE_HORIZONTAL_SIDE_TAB && configModeFB != MODE_HORIZONTAL_ANIMATION {
            groupView.distribution = .fillEqually
        }

        scrollView.addSubview(groupView)

        if configModeFB == MODE_VERTICAL_SIDE_TAB {
            groupView.spacing = 10.0
            groupView.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor).isActive = true
            groupView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
            groupView.heightAnchor.constraint(equalToConstant: heightVerticalSideTab - 20).isActive = true
            groupView.widthAnchor.constraint(equalToConstant: 30).isActive = true
        } else if configModeFB == MODE_HORIZONTAL_SIDE_TAB {
            groupView.leftAnchor.constraint(equalTo: scrollView.leftAnchor).isActive = true
            groupView.rightAnchor.constraint(equalTo: scrollView.rightAnchor).isActive = true
            groupView.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor).isActive = true
            groupView.heightAnchor.constraint(equalToConstant: defaultHeightFB - 10).isActive = true
        } else {
            groupView.widthAnchor.constraint(equalToConstant: configModeFB == MODE_HORIZONTAL_ANIMATION ? defaultWidthHeightMenuFB * (countMenuFB - 1) : defaultWidthHeightMenuFB).isActive = true
            groupView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: configModeFB == MODE_HORIZONTAL_ANIMATION ? 0 : 5).isActive = true
            groupView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: configModeFB == MODE_HORIZONTAL_ANIMATION ? 0 : -5).isActive = true
            groupView.leftAnchor.constraint(equalTo: scrollView.leftAnchor, constant: configModeFB == MODE_HORIZONTAL_ANIMATION ? 0 : 6).isActive = true
        }
        
        pullButton()
        
        let center: NotificationCenter = NotificationCenter.default
        center.addObserver(self, selector: #selector(imageFBUpdate(notification:)), name: NSNotification.Name(rawValue: "imageFBUpdate"), object: nil)
        center.addObserver(self, selector: #selector(checkCounter), name: NSNotification.Name(rawValue: Nexilis.listenerReceiveChat), object: nil)
        center.addObserver(self, selector: #selector(checkCounter), name: NSNotification.Name(rawValue: "reloadTabChats"), object: nil)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideButton))
        tapGesture.cancelsTouchesInView = false
        UIApplication.shared.windows.first?.rootViewController?.view.addGestureRecognizer(tapGesture)
    }
    
    public func setImageWithURL(_ isDocked: Bool) {
        if configModeFB != MODE_VERTICAL_FLOATING_BUTTON {
            return
        }
        let task = URLSession.shared.dataTask(with: URL(string: (isDocked ? Utils.getUrlDock() : Utils.getIconCenter())!)!) { dataImage, response, error in
            if let error = error {
                print("Failed to load data: \(error)")
                return
            }
            DispatchQueue.main.async { [self] in
                if dataImage != nil && UIImage(data: dataImage!) != nil {
                    if let image = UIImage(data: dataImage!) {
                        nexilis_button.image = image
                    } else {
                        nexilis_button.image = UIImage(named: Utils.getFBIconBg() == "1" ? "pb_button" : "pb_ball", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)
                    }
                } else {
                    nexilis_button.image = UIImage(named: Utils.getFBIconBg() == "1" ? "pb_button" : "pb_ball", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)
                }
            }
        }
        task.resume()
    }
    
    private func checkDelayAnimation() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: { [self] in
            if !isShow {
                animationTimer.invalidate()
                animationTimer = Timer.scheduledTimer(timeInterval: 0.001, target: self, selector: #selector(runAnimation), userInfo: nil, repeats: true)
            }
        })
    }
    
    @objc func runAnimation(){
        DispatchQueue.main.async { [self] in
            if configAnim == 0 || configAnim == 1 {
                if (lastRunAnimationHrz == -1 && frame.origin.x >= 0) || lastRunAnimationHrz == 1 && frame.origin.x <= UIScreen.main.bounds.width - defaultWidthFB {
                    if lastRunAnimationHrz == -1 {
                        frame.origin.x-=0.1
                    } else {
                        frame.origin.x+=0.1
                    }
                } else {
                    lastRunAnimationHrz = lastRunAnimationHrz == 1 ? -1 : 1
                    if (lastRunAnimationHrz == -1 && configAnim == 1) || (lastRunAnimationHrz == 1 && configAnim == 0) {
                        animationTimer.invalidate()
                        if isLoopingAnim {
                            checkDelayAnimation()
                        }
                    }
                }
            } else {
                if (lastRunAnimationVrt == -1 && frame.origin.y >= 0) || lastRunAnimationVrt == 1 && frame.origin.y <= UIScreen.main.bounds.height - defaultHeightFB {
                    if lastRunAnimationVrt == -1 {
                        frame.origin.y-=0.1
                    } else {
                        frame.origin.y+=0.1
                    }
                } else {
                    lastRunAnimationVrt = lastRunAnimationVrt == 1 ? -1 : 1
                    if (lastRunAnimationVrt == -1 && configAnim == 3) || (lastRunAnimationVrt == 1 && configAnim == 2) {
                        animationTimer.invalidate()
                        if isLoopingAnim {
                            checkDelayAnimation()
                        }
                    }
                }
            }
        }
    }
    
    private func pullButton() {
        if datePull == nil || Int(Date().timeIntervalSince(datePull!)) >= 60 {
            datePull = Date()
        } else if Int(Date().timeIntervalSince(datePull!)) < 60 {
            return
        }
        if !CheckConnection.isConnectedToNetwork()  || API.nGetCLXConnState() == 0 {
            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
            imageView.tintColor = .white
            let banner = FloatingNotificationBanner(title: "Check your connection".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
            banner.show()
            return
        }
        if groupView.subviews.count == 0 {
            if !Utils.getHistoryPullFB().isEmpty {
                setFBFromPull()
            } else {
                getDefaultButton()
            }
        }
        DispatchQueue.global().async { [self] in
            if !Utils.getCustomButtons().isEmpty && configModeFB != MODE_HORIZONTAL_SIDE_TAB && configModeFB != MODE_HORIZONTAL_ANIMATION && configModeFB != MODE_VERTICAL_SIDE_TAB && Nexilis.fromMAB {
                DispatchQueue.main.async { [self] in
                    groupView.subviews.forEach({ $0.removeFromSuperview() })
                    let customButtons = Utils.getCustomButtons().components(separatedBy: ",")
                    let customIcons = Utils.getCustomFBIcon().components(separatedBy: ",")
                    countMenuFB = CGFloat(customButtons.count > 5 ? 5 : customButtons.count)
                    for i in 0..<customButtons.count {
                        let package_id = customButtons[i]
                        let app_id = ""
                        let icon = customIcons[i]
                        let newButton = UIButton()
                        newButton.heightAnchor.constraint(equalToConstant: defaultWidthHeightMenuFB).isActive = true
                        newButton.translatesAutoresizingMaskIntoConstraints = false
                        DispatchQueue.global().async {[self] in
                            getDataImageFromUrl(from: URL(string: Utils.getURLBase() + "get_file_from_path?img=" + icon)!) { data, response, error in
                                guard let data = data, error == nil else { return }
                                DispatchQueue.main.async {
                                    if let image = UIImage(data: data) {
                                        newButton.setImage(image, for: .normal)
                                    }
                                }
                            }
                        }
                        groupView.addArrangedSubview(newButton)
                        newButton.restorationIdentifier = package_id
                        newButton.accessibilityIdentifier = app_id
                        newButton.addTarget(self, action: #selector(fbTap), for: .touchUpInside)
                    }
                }
                return
            }
            if let response = Nexilis.writeSync(message: CoreMessage_TMessageBank.pullFloatingButton(), timeout: 30 * 1000){
                if response.isOk() {
                    Utils.setHistoryPullFB(value: response.getBody(key: CoreMessage_TMessageKey.DATA, default_value: ""))
                    setFBFromPull()
                }
            }
        }
    }
    
    private func setFBFromPull() {
        DispatchQueue.main.async {
            let data = Utils.getHistoryPullFB()
            if !data.isEmpty {
                if let jsonArray = try! JSONSerialization.jsonObject(with: data.data(using: String.Encoding.utf8)!, options: JSONSerialization.ReadingOptions()) as? [AnyObject] {
                    DispatchQueue.main.async { [self] in
                        let filteredData = jsonArray.filter({ $0["mode"] as? Int == Int(configModeFB) })
                        if filteredData.count != 0 {
                            groupView.subviews.forEach({ $0.removeFromSuperview() })
                            countMenuFB = CGFloat(filteredData.count > 5 ? 5 : filteredData.count)
                            for json in filteredData {
                                let package_id = json["package_id"] as! String
                                let app_id = (json["app_id"] as? String) ?? ""
                                let icon = (json["icon"] as? String) ?? ""
                                let mode = "\((json["mode"] as? Int) ?? 1)"
                                let newButton = UIButton()
                                if mode != configModeFB {
                                    continue
                                }
                                if mode == MODE_HORIZONTAL_SIDE_TAB {
                                    newButton.widthAnchor.constraint(equalToConstant: defaultHeightFB - 10).isActive = true
                                    newButton.heightAnchor.constraint(equalToConstant: defaultHeightFB - 10).isActive = true
                                } else if mode == MODE_HORIZONTAL_ANIMATION {
                                    newButton.widthAnchor.constraint(equalToConstant: defaultWidthHeightMenuFB).isActive = true
                                    newButton.heightAnchor.constraint(equalToConstant: defaultWidthHeightMenuFB).isActive = true
                                } else if mode == MODE_VERTICAL_SIDE_TAB {
                                    newButton.imageView?.contentMode = .scaleAspectFit
                                } else {
                                    newButton.heightAnchor.constraint(equalToConstant: defaultWidthHeightMenuFB).isActive = true
                                }
                                newButton.translatesAutoresizingMaskIntoConstraints = false
                                var indexTap = 0
                                if package_id.contains("_fb"){
                                    let listSplit = package_id.split(separator: "_", maxSplits: 1)
                                    let idxFB = listSplit.firstIndex(where: { $0.contains("fb") }) ?? 0
                                    let numIdx = listSplit[idxFB]
                                    indexTap = Int(String(numIdx).substring(from: 2, to: numIdx.count)) ?? 0
                                }
                                if indexTap == Nexilis.IDX_CHAT {
                                    newButton.setImage(UIImage(named: mode == MODE_HORIZONTAL_SIDE_TAB ? "pb_button_hrz_chat" : mode == MODE_HORIZONTAL_SIDE_TAB ? "pb_button_hrz_chat" : mode == MODE_HORIZONTAL_ANIMATION ? "pb_button_hrz_anim_chat" : "pb_button_chat", in: Bundle.resourceBundle(for: Nexilis.self), with: nil), for: .normal)
                                } else if indexTap == Nexilis.IDX_CONVERSATION {
                                    newButton.setImage(UIImage(named: mode == MODE_VERTICAL_SIDE_TAB ? "pb_button_vtcst_chat" : mode == MODE_HORIZONTAL_SIDE_TAB ? "pb_button_hrz_conversation" : mode == MODE_HORIZONTAL_ANIMATION ? "pb_button_hrz_anim_conversation" : "pb_button_chat", in: Bundle.resourceBundle(for: Nexilis.self), with: nil), for: .normal)
                                } else if indexTap == Nexilis.IDX_CALL {
                                    newButton.setImage(UIImage(named: mode == MODE_HORIZONTAL_SIDE_TAB ? "pb_button_hrz_call" : mode == MODE_HORIZONTAL_ANIMATION ? "pb_button_hrz_anim_call" : "pb_button_call", in: Bundle.resourceBundle(for: Nexilis.self), with: nil), for: .normal)
                                } else if indexTap == Nexilis.IDX_CC {
                                    newButton.setImage(UIImage(named: mode == MODE_VERTICAL_SIDE_TAB ? "pb_button_vtcst_cc" : mode == MODE_HORIZONTAL_SIDE_TAB ? "pb_button_hrz_cc" : mode == MODE_HORIZONTAL_ANIMATION ? "pb_button_hrz_anim_cc" : "pb_button_cc", in: Bundle.resourceBundle(for: Nexilis.self), with: nil), for: .normal)
                                } else if indexTap == Nexilis.IDX_STREAM {
                                    newButton.setImage(UIImage(named: mode == MODE_VERTICAL_SIDE_TAB ? "pb_button_vtcst_stream" : mode == MODE_HORIZONTAL_SIDE_TAB ? "pb_button_hrz_stream" : mode == MODE_HORIZONTAL_ANIMATION ? "pb_button_hrz_anim_stream" : "pb_button_stream", in: Bundle.resourceBundle(for: Nexilis.self), with: nil), for: .normal)
                                } else if indexTap == Nexilis.IDX_SOCIAL_COMMERCE {
                                    newButton.setImage(UIImage(named: mode == MODE_VERTICAL_SIDE_TAB ? "pb_button_vtcst_commerce" : mode == MODE_HORIZONTAL_SIDE_TAB ? "pb_button_hrz_social_commerce" : mode == MODE_HORIZONTAL_ANIMATION ? "pb_button_hrz_anim_commerce" : "pb_button_commerce", in: Bundle.resourceBundle(for: Nexilis.self), with: nil), for: .normal)
                                } else if indexTap == Nexilis.IDX_NEWS {
                                    newButton.setImage(UIImage(named: mode == MODE_HORIZONTAL_SIDE_TAB ? "pb_button_hrz_news" : mode == MODE_HORIZONTAL_ANIMATION ? "pb_button_hrz_anim_news" : "pb_button_news", in: Bundle.resourceBundle(for: Nexilis.self), with: nil), for: .normal)
                                } else if indexTap == Nexilis.IDX_POST {
                                    newButton.setImage(UIImage(named: mode == MODE_HORIZONTAL_SIDE_TAB ? "pb_button_hrz_post" : mode == MODE_HORIZONTAL_ANIMATION ? "pb_button_hrz_anim_post" : "pb_button_post", in: Bundle.resourceBundle(for: Nexilis.self), with: nil), for: .normal)
                                } else if indexTap == Nexilis.IDX_NOTIF_CENTER {
                                    newButton.setImage(UIImage(named: mode == MODE_VERTICAL_SIDE_TAB ? "pb_button_vtcst_notif_center" : mode == MODE_HORIZONTAL_SIDE_TAB ? "pb_button_hrz_notif_center" : mode == MODE_HORIZONTAL_ANIMATION ? "pb_button_hrz_anim_notif_center" : "pb_button_notification", in: Bundle.resourceBundle(for: Nexilis.self), with: nil), for: .normal)
                                } else {
                                    newButton.setImage(UIImage(named: mode == MODE_HORIZONTAL_SIDE_TAB ? "pb_button_hrz_more" : mode == MODE_HORIZONTAL_ANIMATION ? "pb_button_hrz_anim_more" : "pb_button_others", in: Bundle.resourceBundle(for: Nexilis.self), with: nil), for: .normal)
                                }
                                if !icon.isEmpty {
                                    DispatchQueue.global().async { [self] in
                                        getDataImageFromUrl(from: URL(string: Utils.getURLBase() + "get_file_from_path?img=" + icon)!) { data, response, error in
                                            guard let data = data, error == nil else { return }
                                            DispatchQueue.main.async {
                                                newButton.setImage(UIImage(data: data), for: .normal)
                                            }
                                        }
                                    }
                                }
                                groupView.addArrangedSubview(newButton)
                                newButton.restorationIdentifier = package_id
                                newButton.accessibilityIdentifier = app_id
                                newButton.addTarget(self, action: #selector(fbTap), for: .touchUpInside)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func getDataImageFromUrl(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        let urlConfig = URLSessionConfiguration.default
        let sessionDelegate = SelfSignedURLSessionDelegate()
        let session = URLSession(configuration: urlConfig, delegate: sessionDelegate, delegateQueue: nil)
        session.dataTask(with: url, completionHandler: completion).resume()
    }
    
    func getDefaultButton() {
        let mode = configModeFB
        var data = [Nexilis.IDX_NOTIF_CENTER, Nexilis.IDX_CC, Nexilis.IDX_CONVERSATION, Nexilis.IDX_CALL, Nexilis.IDX_STREAM]
        if Nexilis.defaultFloatingButton.count > 0 {
            data = Nexilis.defaultFloatingButton
        }
        if mode == MODE_VERTICAL_SIDE_TAB {
            data = [Nexilis.IDX_NOTIF_CENTER, Nexilis.IDX_CC, Nexilis.IDX_CONVERSATION, Nexilis.IDX_STREAM, Nexilis.IDX_SOCIAL_COMMERCE]
        } else if mode == MODE_HORIZONTAL_ANIMATION {
            data = [Nexilis.IDX_NOTIF_CENTER, Nexilis.IDX_CC, Nexilis.IDX_CONVERSATION, Nexilis.IDX_SOCIAL_COMMERCE, Nexilis.IDX_STREAM]
        }
        countMenuFB = CGFloat(data.count > 5 ? 5 : data.count)
        for i in 0..<data.count {
            let newButton = UIButton()
            if mode == MODE_HORIZONTAL_SIDE_TAB {
                newButton.widthAnchor.constraint(equalToConstant: defaultHeightFB - 10).isActive = true
                newButton.heightAnchor.constraint(equalToConstant: defaultHeightFB - 10).isActive = true
            } else if mode == MODE_HORIZONTAL_ANIMATION {
                newButton.widthAnchor.constraint(equalToConstant: defaultWidthHeightMenuFB).isActive = true
                newButton.heightAnchor.constraint(equalToConstant: defaultWidthHeightMenuFB).isActive = true
            } else if mode == MODE_VERTICAL_SIDE_TAB {
                newButton.imageView?.contentMode = .scaleAspectFit
            } else {
                newButton.heightAnchor.constraint(equalToConstant: defaultWidthHeightMenuFB).isActive = true
            }
            newButton.translatesAutoresizingMaskIntoConstraints = false
            let indexTap = data[i]
            if indexTap == Nexilis.IDX_CHAT {
                newButton.setImage(UIImage(named: mode == MODE_HORIZONTAL_SIDE_TAB ? "pb_button_hrz_chat" : mode == MODE_HORIZONTAL_ANIMATION ? "pb_button_hrz_anim_chat" : "pb_button_chat", in: Bundle.resourceBundle(for: Nexilis.self), with: nil), for: .normal)
            } else if indexTap == Nexilis.IDX_CONVERSATION {
                newButton.setImage(UIImage(named: mode == MODE_VERTICAL_SIDE_TAB ? "pb_button_vtcst_chat" : mode == MODE_HORIZONTAL_SIDE_TAB ? "pb_button_hrz_conversation" : mode == MODE_HORIZONTAL_ANIMATION ? "pb_button_hrz_anim_conversation" : "pb_button_chat", in: Bundle.resourceBundle(for: Nexilis.self), with: nil), for: .normal)
            } else if indexTap == Nexilis.IDX_CALL {
                newButton.setImage(UIImage(named: mode == MODE_HORIZONTAL_SIDE_TAB ? "pb_button_hrz_call" : mode == MODE_HORIZONTAL_ANIMATION ? "pb_button_hrz_anim_call" : "pb_button_call", in: Bundle.resourceBundle(for: Nexilis.self), with: nil), for: .normal)
            } else if indexTap == Nexilis.IDX_CC {
                newButton.setImage(UIImage(named: mode == MODE_VERTICAL_SIDE_TAB ? "pb_button_vtcst_cc" : mode == MODE_HORIZONTAL_SIDE_TAB ? "pb_button_hrz_cc" : mode == MODE_HORIZONTAL_ANIMATION ? "pb_button_hrz_anim_cc" : "pb_button_cc", in: Bundle.resourceBundle(for: Nexilis.self), with: nil), for: .normal)
            } else if indexTap == Nexilis.IDX_STREAM {
                newButton.setImage(UIImage(named: mode == MODE_VERTICAL_SIDE_TAB ? "pb_button_vtcst_stream" : mode == MODE_HORIZONTAL_SIDE_TAB ? "pb_button_hrz_stream" : mode == MODE_HORIZONTAL_ANIMATION ? "pb_button_hrz_anim_stream" : "pb_button_stream", in: Bundle.resourceBundle(for: Nexilis.self), with: nil), for: .normal)
            } else if indexTap == Nexilis.IDX_SOCIAL_COMMERCE {
                newButton.setImage(UIImage(named: mode == MODE_VERTICAL_SIDE_TAB ? "pb_button_vtcst_commerce" : mode == MODE_HORIZONTAL_SIDE_TAB ? "pb_button_hrz_social_commerce" : mode == MODE_HORIZONTAL_ANIMATION ? "pb_button_hrz_anim_commerce" : "pb_button_commerce", in: Bundle.resourceBundle(for: Nexilis.self), with: nil), for: .normal)
            } else if indexTap == Nexilis.IDX_NEWS {
                newButton.setImage(UIImage(named: mode == MODE_HORIZONTAL_SIDE_TAB ? "pb_button_hrz_news" : mode == MODE_HORIZONTAL_ANIMATION ? "pb_button_hrz_anim_news" : "pb_button_news", in: Bundle.resourceBundle(for: Nexilis.self), with: nil), for: .normal)
            } else if indexTap == Nexilis.IDX_POST {
                newButton.setImage(UIImage(named: mode == MODE_HORIZONTAL_SIDE_TAB ? "pb_button_hrz_post" : mode == MODE_HORIZONTAL_ANIMATION ? "pb_button_hrz_anim_post" : "pb_button_post", in: Bundle.resourceBundle(for: Nexilis.self), with: nil), for: .normal)
            } else if indexTap == Nexilis.IDX_NOTIF_CENTER {
                newButton.setImage(UIImage(named: mode == MODE_VERTICAL_SIDE_TAB ? "pb_button_vtcst_notif_center" : mode == MODE_HORIZONTAL_SIDE_TAB ? "pb_button_hrz_notif_center" : mode == MODE_HORIZONTAL_ANIMATION ? "pb_button_hrz_anim_notif_center" : "pb_button_notification", in: Bundle.resourceBundle(for: Nexilis.self), with: nil), for: .normal)
                if mode == MODE_VERTICAL_SIDE_TAB {
                    newButton.imageView?.contentMode = .scaleAspectFit
                }
            } else {
                newButton.setImage(UIImage(named: mode == MODE_HORIZONTAL_SIDE_TAB ? "pb_button_hrz_more" : mode == MODE_HORIZONTAL_ANIMATION ? "pb_button_hrz_anim_more" : "pb_button_others", in: Bundle.resourceBundle(for: Nexilis.self), with: nil), for: .normal)
            }
            groupView.addArrangedSubview(newButton)
            newButton.restorationIdentifier = "default_fb\(data[i])"
            newButton.accessibilityIdentifier = ""
            newButton.addTarget(self, action: #selector(fbTap), for: .touchUpInside)
        }
    }
    
    @objc func draggedView(_ sender:UIPanGestureRecognizer){
        let size = UIScreen.main.bounds
        let widthScreen = size.width
        let heightScreen = size.height
        let minimumx: CGFloat = configModeFB == MODE_HORIZONTAL_ANIMATION && isShow ? widthFBAnim + defaultWidthHeightMenuFB : configModeFB == MODE_VERTICAL_ANIMATION && isShow ? 60 : 40
        let maximumx = configModeFB == MODE_HORIZONTAL_ANIMATION && isShow ? widthScreen - widthFBAnim - defaultWidthHeightMenuFB : configModeFB == MODE_VERTICAL_ANIMATION && isShow ? widthScreen - 10 - defaultWidthHeightMenuFB : widthScreen - 40
        let maxMinXSideTab = isShow ? center.x : widthScreen + (center.x - widthScreen)
        let translation = sender.translation(in: self)
        var xPos = center.x + translation.x
        var yPos = center.y + translation.y
        bringSubviewToFront(self)
        if configModeFB == MODE_HORIZONTAL_SIDE_TAB || configModeFB == MODE_VERTICAL_SIDE_TAB {
            xPos = maxMinXSideTab
        } else {
            if (xPos < minimumx) {
                xPos = minimumx
            }
            if (xPos > maximumx) {
                xPos = maximumx
            }
        }
        if(isShow) {
            let minimumy = configModeFB == MODE_VERTICAL_SIDE_TAB ? heightVerticalSideTab - 100 : configModeFB == MODE_HORIZONTAL_SIDE_TAB ? 50 : configModeFB == MODE_HORIZONTAL_ANIMATION ? defaultWidthHeightMenuFB * 2 + 10 : configModeFB == MODE_VERTICAL_ANIMATION ? defaultHeightFB + defaultWidthHeightMenuFB : self.frame.size.height - 120 + ((5 - countMenuFB) * 25)
            let maximumy = configModeFB == MODE_VERTICAL_SIDE_TAB ? heightScreen - (heightVerticalSideTab - 100) : configModeFB == MODE_HORIZONTAL_SIDE_TAB ? heightScreen - 50 : configModeFB == MODE_HORIZONTAL_ANIMATION ? heightScreen - defaultWidthHeightMenuFB - 30 : configModeFB == MODE_VERTICAL_ANIMATION ? heightScreen - defaultHeightFB - 30 : heightScreen - 50
            if(yPos < minimumy) {
                yPos = minimumy
            }
            if(yPos > maximumy) {
                yPos = maximumy
            }
        } else {
            let minimumy: CGFloat = 50
            let maximumy = heightScreen - 50
            if(yPos < minimumy) {
                yPos = minimumy
            }
            if(yPos > maximumy) {
                yPos = maximumy
            }
        }
        center = CGPoint(x: xPos, y: yPos)
        sender.setTranslation(CGPoint.zero, in: self)
        if lastPosY != nil {
            lastPosY = nil
        }
//        SecureUserDefaults.shared.set(center.x, forKey: "xlastPosFB")
//        SecureUserDefaults.shared.set(center.y, forKey: "ylastPosFB")
    }
    
    @objc func imageFBUpdate(notification: NSNotification) {
        
    }
    
    @objc func checkCounter() {
        DispatchQueue.global().async { [self] in
            let counter = queryCountCounter()
            if counter > 0 {
                DispatchQueue.main.async { [self] in
                    if button_fb2 != nil && !indicatorCounterFB.isDescendant(of: button_fb2) {
                        button_fb2.addSubview(indicatorCounterFB)
                        indicatorCounterFB.layer.cornerRadius = 7.5
                        indicatorCounterFB.layer.masksToBounds = true
                        indicatorCounterFB.backgroundColor = .systemRed
                        indicatorCounterFB.anchor(top: button_fb2.topAnchor, left: button_fb2.leftAnchor, height: 15, minWidth: 15, maxWidth: 20)
                        indicatorCounterFB.addSubview(labelCounterFB)
                        labelCounterFB.anchor(left: indicatorCounterFB.leftAnchor, right: indicatorCounterFB.rightAnchor, paddingLeft: 5, paddingRight: 5, centerX: indicatorCounterFB.centerXAnchor, centerY: indicatorCounterFB.centerYAnchor)
                        labelCounterFB.font = .systemFont(ofSize: 10)
                        labelCounterFB.textColor = .white
                    }
                    if !indicatorCounterFBBig.isDescendant(of: nexilis_button){
                        nexilis_button.addSubview(indicatorCounterFBBig)
                        indicatorCounterFBBig.tintColor = .systemRed
                        indicatorCounterFBBig.image = UIImage(systemName: "staroflife.circle.fill")
                        indicatorCounterFBBig.anchor(top: nexilis_button.topAnchor, left: nexilis_button.leftAnchor, paddingTop: 5, paddingLeft: 5, width: 15, height: 15)
                    }
                    labelCounterFB.text = "\(counter)"
                }
            } else {
                DispatchQueue.main.async { [self] in
                    if button_fb2 != nil && indicatorCounterFB.isDescendant(of: button_fb2) {
                        indicatorCounterFB.removeFromSuperview()
                    }
                    if indicatorCounterFBBig.isDescendant(of: nexilis_button) {
                        indicatorCounterFBBig.removeFromSuperview()
                    }
                }
            }
        }
    }
    
    private func queryCountCounter() -> Int32 {
        var counter: Int32?
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            do {
                if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "SELECT SUM(counter) FROM MESSAGE_SUMMARY"), cursor.next() {
                    counter = cursor.int(forColumnIndex: 0)
                    cursor.close()
                }
            } catch {
                rollback.pointee = true
                print("Access database error: \(error.localizedDescription)")
            }
        })
        return counter ?? 0
    }
    
    @objc func qmeraTap() {
        show(isShow: !isShow)
    }
    
    @objc func fbTap(_ sender: UIButton) {
        let package_id = sender.restorationIdentifier!
        var app_id = sender.accessibilityIdentifier!
        var indexTap = 0
        if package_id.contains("_fb"){
            let listSplit = package_id.split(separator: "_", maxSplits: 1)
            let numIdx = listSplit[listSplit.firstIndex(where: { $0.contains("fb") }) ?? 0]
            indexTap = Int(String(numIdx).substring(from: 2, to: numIdx.count))!
            if listSplit.count == 2 {
                app_id = String(listSplit[1])
            }
        }
        Nexilis.buttonClicked(index: indexTap, id: app_id)
        hideButton()
    }
    
    @objc func qmeraLongPress(gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            if mySettingDelegate != nil {
                mySettingDelegate?.settingDelegate()
            } else {
                APIS.openSetting()
            }
            hideButton()
        }
    }
    
    @objc public func hideButton() {
        animationTimer.invalidate()
        if isShow {
            show(isShow: false)
        }
        if self.frame.origin.x < UIScreen.main.bounds.width / 2 - 30 {
            self.frame.origin.x = 0
        } else {
            self.frame.origin.x = UIScreen.main.bounds.width - defaultWidthFB
        }
    }
    
    public func show(isShow: Bool) {
        self.isShow = isShow
        if isShow {
            animationTimer.invalidate()
            pullButton()
            if indicatorCounterFBBig.isDescendant(of: nexilis_button) {
                indicatorCounterFBBig.isHidden = true
            }
            var height = CGFloat((defaultWidthHeightMenuFB * countMenuFB) + defaultHeightFB + 5) //defaultWidthHeightMenuFB
            var width = frame.width
            var xPosition = frame.origin.x
            if configModeFB == MODE_VERTICAL_ANIMATION {
                height = CGFloat((defaultWidthHeightMenuFB * (countMenuFB - 2)) + defaultHeightFB - 5)
                width = frame.width + defaultWidthHeightMenuFB
                if xPosition > UIScreen.main.bounds.width - defaultWidthFB - defaultWidthHeightMenuFB {
                    xPosition = UIScreen.main.bounds.width - defaultWidthFB - defaultWidthHeightMenuFB
                }
                scrollView.isHidden = false
            } else if configModeFB == MODE_HORIZONTAL_ANIMATION {
                height = defaultHeightFB + defaultWidthHeightMenuFB
                width = defaultWidthHeightMenuFB * (countMenuFB - 1)
                if xPosition > UIScreen.main.bounds.width - width {
                    xPosition = UIScreen.main.bounds.width - width
                }
            }
            var yPosition = frame.origin.y - height + defaultHeightFB
            if yPosition <= 25 {
                lastPosY = frame.origin.y
                yPosition = 25
            }
            if configModeFB != MODE_HORIZONTAL_SIDE_TAB &&  configModeFB != MODE_VERTICAL_SIDE_TAB {
                frame = CGRect(x: xPosition, y: yPosition, width: width, height: height)
            } else {
                UIView.animate(withDuration: 0.5, animations: { [self] in
                    var vst: CGFloat = 0.0
                    if configModeFB == MODE_VERTICAL_SIDE_TAB {
                        vst = UIScreen.main.bounds.width - defaultWidthFB - widthVerticalSideTab
                        let size = UIScreen.main.bounds
                        let heightScreen = size.height
                        if frame.origin.y < 20 {
                            frame.origin.y = 20
                        } else if frame.origin.y > heightScreen - heightVerticalSideTab {
                            frame.origin.y = heightScreen - heightVerticalSideTab
                        }
                    }
                    frame.origin.x = 0 + vst
                })
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: { [self] in
                if isShow {
                    let countSubviewsAfter = groupView.subviews.count
                    if countSubviewsAfter > 5 {
                        scrollView.flashScrollIndicators()
                    }
                }
            })
        } else {
            if indicatorCounterFBBig.isDescendant(of: nexilis_button) {
                indicatorCounterFBBig.isHidden = false
            }
            var height = CGFloat((defaultWidthHeightMenuFB * countMenuFB) + defaultHeightFB + 5) //defaultWidthHeightMenuFB
            var width = defaultWidthFB
            if configModeFB == MODE_VERTICAL_ANIMATION {
                height = CGFloat((defaultWidthHeightMenuFB * 3) + defaultHeightFB - 5)
                scrollView.isHidden = true
            } else if configModeFB == MODE_HORIZONTAL_ANIMATION {
                height = defaultHeightFB + defaultWidthHeightMenuFB
                width = defaultWidthFB
            }
            var yPosition = frame.origin.y + height - defaultHeightFB
            if lastPosY != nil {
                yPosition = lastPosY!
            }
            if configModeFB != MODE_HORIZONTAL_SIDE_TAB && configModeFB != MODE_VERTICAL_SIDE_TAB {
                frame = CGRect(x: frame.origin.x, y: yPosition, width: width, height: defaultHeightFB)
            } else {
                UIView.animate(withDuration: 0.5, animations: { [self] in
                    frame.origin.x = UIScreen.main.bounds.width - defaultWidthFB
                })
            }
            if configModeFB == MODE_VERTICAL_ANIMATION || configModeFB == MODE_HORIZONTAL_ANIMATION {
                checkDelayAnimation()
            }
        }
    }
}

public protocol SettingMABDelegate: AnyObject {
    func settingDelegate()
}
