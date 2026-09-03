//
//  FloatingButton.swift
//  Qmera
//
//  Created by Yayan Dwi on 03/09/21.
//

import UIKit
import nuSDKService
@_implementationOnly import NotificationBannerSwift
public class FloatingButton: UIView, UIGestureRecognizerDelegate {
    
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
    
    public static var datePull: Date?
    var animationTimer = Timer()
    var configAnim: Int = Int(Utils.getFloatingAnim().components(separatedBy: "~")[0]) ?? 1
    var isLoopingAnim = (Int(Utils.getFloatingAnim().component(1, separatedBy: "~")) ?? 1) == 1 ? true : false
    var lastRunAnimationHrz = -1
    var lastRunAnimationVrt = -1
    
    var panGesture: UIPanGestureRecognizer?
    var defaultWidthFB = (UIScreen.main.bounds.height * 0.5) / 7.5
    var defaultHeightFB = (UIScreen.main.bounds.height * 0.5) / 7.5
    let defaultWidthHeightMenuFB = (UIScreen.main.bounds.height * 0.45) / 7.5
    let widthFBAnim = (UIScreen.main.bounds.height * 0.8) / 7.5
    let heightFBAnim = (UIScreen.main.bounds.height * 1) / 7.5
    let heightFBSideTab = (UIScreen.main.bounds.height * 1.05) / 6.5
    let widthFBSideTab: CGFloat = 20
    let widthVerticalSideTab: CGFloat = 60
    // How the vertical side tab is built, one button at a time: a 30pt button, 20pt of air
    // between two of them, and 10pt above the first and below the last. So every button after
    // the first adds exactly 50pt to the box.
    let verticalSideTabButtonSize: CGFloat = 30
    let verticalSideTabSpacing: CGFloat = 20
    let verticalSideTabPadding: CGFloat = 10
    /// The box never shrinks below four buttons, and never grows past five - a sixth is scrolled
    /// to rather than made room for.
    let verticalSideTabMinButtons = 4
    let verticalSideTabMaxButtons = 5
    /// Fix: this was a fixed 250, the height of five buttons, whatever was actually in it - so a
    /// side tab configured with four left a button's worth of empty box hanging under the last
    /// one. It follows what it holds now (see updateVerticalSideTabSize), between the two limits
    /// above, which is also why it is no longer a constant: the drag limits and the on-screen
    /// clamping all read it.
    var heightVerticalSideTab: CGFloat = 250
    /// The height of the box, and the air above and below the buttons in it - both change with
    /// the number of buttons, so both are held on to.
    private var verticalSideTabHeightConstraint: NSLayoutConstraint?
    private var verticalSideTabTopConstraint: NSLayoutConstraint?
    private var verticalSideTabBottomConstraint: NSLayoutConstraint?
    
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
                urlGif = Bundle.resourceBundle(for: Nexilis.self).url(forResource: configModeFB == MODE_VERTICAL_ANIMATION ? "pb_def_icon_mode2" : "pb_def_icon_mode4", withExtension: "gif") ?? nil
                if urlGif == nil {
                    urlGif = Bundle.resourcesMediaBundle(for: Nexilis.self).url(forResource: configModeFB == MODE_VERTICAL_ANIMATION ? "pb_def_icon_mode2" : "pb_def_icon_mode4", withExtension: "gif")!
                }
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
        frame = CGRect(x: UIScreen.main.bounds.width - defaultWidthFB, y: (UIScreen.main.bounds.height / 2) - defaultHeightFB, width: configModeFB == MODE_VERTICAL_SIDE_TAB ? widthVerticalSideTab + defaultWidthFB : configModeFB == MODE_HORIZONTAL_SIDE_TAB ? UIScreen.main.bounds.width - defaultWidthFB : defaultWidthFB, height: configModeFB == MODE_VERTICAL_SIDE_TAB ? heightVerticalSideTab : defaultHeightFB)
        
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
        qmeraTap.delegate = self
        
        let qmeraLongPress = UILongPressGestureRecognizer(target: self, action: #selector(qmeraLongPress(gestureRecognizer:)))
        self.addGestureRecognizer(qmeraLongPress)
        
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
            scrollView.backgroundColor = UIColor.white.withAlphaComponent(0.8)
            scrollView.layer.borderColor = UIColor.gray.cgColor
            scrollView.layer.borderWidth = 0.2
            scrollView.layer.cornerRadius = 5.0
            scrollView.layer.masksToBounds = true
            scrollView.leftAnchor.constraint(equalTo: nexilis_button.rightAnchor).isActive = true
            scrollView.centerYAnchor.constraint(equalTo: nexilis_button.centerYAnchor).isActive = true
            scrollView.widthAnchor.constraint(equalToConstant: widthVerticalSideTab).isActive = true
            verticalSideTabHeightConstraint = scrollView.heightAnchor.constraint(equalToConstant: heightVerticalSideTab)
            verticalSideTabHeightConstraint?.isActive = true
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
            groupView.spacing = verticalSideTabSpacing
            verticalSideTabTopConstraint = groupView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: verticalSideTabPadding)
            verticalSideTabBottomConstraint = groupView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -verticalSideTabPadding)
            verticalSideTabTopConstraint?.isActive = true
            verticalSideTabBottomConstraint?.isActive = true
            groupView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
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
        // Messages can be read while the app is away - on another device, or from a notification -
        // and nothing posts to this button while it is in the background. Counting again on the
        // way back is what stops a mark surviving from one session into the next.
        center.addObserver(self, selector: #selector(checkCounter), name: UIApplication.didBecomeActiveNotification, object: nil)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideButton))
        tapGesture.cancelsTouchesInView = false
        UIApplication.shared.windows.first?.rootViewController?.view.addGestureRecognizer(tapGesture)
    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        let location = sender.location(in: self)
        print("Tap location: \(location)")
    }
    
    public func setImageWithURL(_ isDocked: Bool) {
        if configModeFB != MODE_VERTICAL_FLOATING_BUTTON {
            return
        }
        var urlFb = Utils.getIconCenter()
        if isDocked {
            urlFb = Utils.getUrlDock() ?? ""
        }
        if urlFb.isEmpty {
            return
        }
        let task = URLSession.shared.dataTask(with: URL(string: (urlFb))!) { dataImage, response, error in
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
        if FloatingButton.datePull == nil || Int(Date().timeIntervalSince(FloatingButton.datePull!)) >= 60 {
            FloatingButton.datePull = Date()
        } else if Int(Date().timeIntervalSince(FloatingButton.datePull!)) < 60 {
            return
        }
        if groupView.subviews.count == 0 {
            getDefaultButton()
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
                        if !APIS.checkAppStateisBackground() {
                            DispatchQueue.global().async {
                                let urlString = Utils.getURLBase() + "get_file_from_path?img=" + icon
                                if let cachedImage = ImageCache.shared.image(forKey: urlString) {
                                    DispatchQueue.main.async() {
                                        newButton.setImage(cachedImage, for: .normal)
                                    }
                                    return
                                }
                                Utils.fetchDataWithCookiesAndUserAgent(from: URL(string: urlString)!) { data, response, error in
                                    guard let data = data, error == nil else { return }
                                    // always update the UI from the main thread
                                    DispatchQueue.main.async() {
                                        if let image = UIImage(data: data) {
                                            newButton.setImage(image, for: .normal)
                                            ImageCache.shared.save(image: UIImage(data: data)!, forKey: urlString)
                                        }
                                    }
                                }
                            }
                        }
                        groupView.addArrangedSubview(newButton)
                        newButton.restorationIdentifier = package_id
                        newButton.accessibilityIdentifier = app_id
                        newButton.addTarget(self, action: #selector(fbTap), for: .touchUpInside)
                        let qmeraLongPress = UILongPressGestureRecognizer(target: self, action: #selector(qmeraLongPress(gestureRecognizer:)))
                        newButton.addGestureRecognizer(qmeraLongPress)
                    }
                }
            } else {
                if !Utils.getHistoryPullFB().isEmpty {
                    setFBFromPull()
                }
                while API.nGetCLXConnState() == 0 || !API.bInetConnAvailable() {
                    Thread.sleep(forTimeInterval: 1)
                }
                if let response = Nexilis.writeAndWait(message: CoreMessage_TMessageBank.pullFloatingButton(), timeout: 10000) {
                    if response.isOk() {
                        Utils.setHistoryPullFB(value: response.getBody(key: CoreMessage_TMessageKey.DATA, default_value: ""))
                        setFBFromPull()
                    }
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
                                    newButton.frame = CGRect(x: 0, y: 0, width: verticalSideTabButtonSize, height: verticalSideTabButtonSize)
                                    newButton.widthAnchor.constraint(equalToConstant: verticalSideTabButtonSize).isActive = true
                                    newButton.heightAnchor.constraint(equalToConstant: verticalSideTabButtonSize).isActive = true
                                    newButton.contentMode = .scaleAspectFill
                                    newButton.clipsToBounds = true
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
                                } else if indexTap == Nexilis.IDX_SETTING {
                                    newButton.setImage(UIImage(named: mode == MODE_VERTICAL_SIDE_TAB ? "pb_button_vtcst_setting" : mode == MODE_HORIZONTAL_SIDE_TAB ? "pb_button_hrz_setting" : mode == MODE_HORIZONTAL_ANIMATION ? "pb_button_hrz_anim_setting" : "pb_button_setting", in: Bundle.resourceBundle(for: Nexilis.self), with: nil), for: .normal)
                                } else {
                                    newButton.setImage(UIImage(named: mode == MODE_HORIZONTAL_SIDE_TAB ? "pb_button_hrz_more" : mode == MODE_HORIZONTAL_ANIMATION ? "pb_button_hrz_anim_more" : "pb_button_others", in: Bundle.resourceBundle(for: Nexilis.self), with: nil), for: .normal)
                                }
                                if !icon.isEmpty {
                                    if !APIS.checkAppStateisBackground() {
                                        DispatchQueue.global().async {
                                            let urlString = Utils.getURLBase() + "get_file_from_path?img=" + icon
                                            if let cachedImage = ImageCache.shared.image(forKey: urlString) {
                                                DispatchQueue.main.async() {
                                                    newButton.setImage(cachedImage, for: .normal)
                                                }
                                                return
                                            }
                                            Utils.fetchDataWithCookiesAndUserAgent(from: URL(string: urlString)!) { data, response, error in
                                                guard let data = data, error == nil else { return }
                                                // always update the UI from the main thread
                                                DispatchQueue.main.async() {
                                                    if let image = UIImage(data: data) {
                                                        newButton.setImage(image, for: .normal)
                                                        ImageCache.shared.save(image: UIImage(data: data)!, forKey: urlString)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                groupView.addArrangedSubview(newButton)
                                newButton.restorationIdentifier = package_id
                                newButton.accessibilityIdentifier = app_id
                                newButton.addTarget(self, action: #selector(fbTap), for: .touchUpInside)
                                let qmeraLongPress = UILongPressGestureRecognizer(target: self, action: #selector(qmeraLongPress(gestureRecognizer:)))
                                newButton.addGestureRecognizer(qmeraLongPress)
                            }
                            updateVerticalSideTabSize()
                        }
                    }
                }
            }
        }
    }
    
    /// Sizes the vertical side tab to what is actually in it.
    ///
    /// The box is as tall as its buttons need, from four of them up to five; a sixth and beyond
    /// are reached by scrolling, which is what the box did for every count before. Below four
    /// the box stays the height of four and the buttons are centred in it, rather than hanging
    /// from the top with the space left underneath.
    private func updateVerticalSideTabSize() {
        guard configModeFB == MODE_VERTICAL_SIDE_TAB else {
            return
        }
        let count = groupView.arrangedSubviews.count
        // Nothing has been built yet - the box keeps the size it has rather than collapsing to
        // an empty one that the buttons would then have to grow back out of.
        guard count > 0 else {
            return
        }
        let shown = min(max(count, verticalSideTabMinButtons), verticalSideTabMaxButtons)
        let boxHeight = CGFloat(shown) * verticalSideTabButtonSize
            + CGFloat(shown - 1) * verticalSideTabSpacing
            + verticalSideTabPadding * 2
        let buttonsHeight = CGFloat(count) * verticalSideTabButtonSize
            + CGFloat(count - 1) * verticalSideTabSpacing
        // With fewer buttons than the box is tall for, the air above and below takes the whole
        // difference, half each - which is what puts them in the middle. With more, this is the
        // 10pt it always was and the rest is scrolled.
        let padding = max(verticalSideTabPadding, (boxHeight - buttonsHeight) / 2)

        heightVerticalSideTab = boxHeight
        verticalSideTabHeightConstraint?.constant = boxHeight
        verticalSideTabTopConstraint?.constant = padding
        verticalSideTabBottomConstraint?.constant = -padding

        // The view is the box, and it is placed by its frame rather than by constraints, so a
        // box that changed height has to be told - and put back on screen if the new height
        // pushed its foot past the bottom.
        frame.size.height = boxHeight
        let heightScreen = UIScreen.main.bounds.height
        if frame.origin.y > heightScreen - boxHeight {
            frame.origin.y = heightScreen - boxHeight
        }
        layoutIfNeeded()
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
                newButton.frame = CGRect(x: 0, y: 0, width: verticalSideTabButtonSize, height: verticalSideTabButtonSize)
                newButton.widthAnchor.constraint(equalToConstant: verticalSideTabButtonSize).isActive = true
                newButton.heightAnchor.constraint(equalToConstant: verticalSideTabButtonSize).isActive = true
                newButton.contentMode = .scaleAspectFill
                newButton.clipsToBounds = true
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
            } else if indexTap == Nexilis.IDX_SETTING {
                newButton.setImage(UIImage(named: mode == MODE_VERTICAL_SIDE_TAB ? "pb_button_vtcst_setting" : mode == MODE_HORIZONTAL_SIDE_TAB ? "pb_button_hrz_setting" : mode == MODE_HORIZONTAL_ANIMATION ? "pb_button_hrz_anim_setting" : "pb_button_setting", in: Bundle.resourceBundle(for: Nexilis.self), with: nil), for: .normal)
            } else {
                newButton.setImage(UIImage(named: mode == MODE_HORIZONTAL_SIDE_TAB ? "pb_button_hrz_more" : mode == MODE_HORIZONTAL_ANIMATION ? "pb_button_hrz_anim_more" : "pb_button_others", in: Bundle.resourceBundle(for: Nexilis.self), with: nil), for: .normal)
            }
            groupView.addArrangedSubview(newButton)
            newButton.restorationIdentifier = "default_fb\(data[i])"
            newButton.accessibilityIdentifier = ""
            newButton.addTarget(self, action: #selector(fbTap), for: .touchUpInside)
            let qmeraLongPress = UILongPressGestureRecognizer(target: self, action: #selector(qmeraLongPress(gestureRecognizer:)))
            newButton.addGestureRecognizer(qmeraLongPress)
        }
        updateVerticalSideTabSize()
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
    
    /// Whether anything is unread at all, as of the last count.
    private var hasUnreadMark = false

    /// Puts the mark on the button, or takes it off.
    ///
    /// Fix: whether the mark showed was decided in two places that did not agree - counting put
    /// the view in and took it out again, while opening and closing the button hid and unhid the
    /// same view. Coming back from an Editor that had just cleared the last unread message could
    /// leave it behind: attached, not hidden, and marking a button with nothing behind it until
    /// the app was restarted. One answer now, asked from both places.
    func updateUnreadMark() {
        indicatorCounterFBBig.isHidden = !hasUnreadMark || isShow
        indicatorCounterFB.isHidden = !hasUnreadMark
    }

    /// The line the unread count is read on, and which read is the newest.
    ///
    /// Fix: every count ran on the shared global queue, so two of them started close together
    /// could come back in either order - and they are started close together all the time, since
    /// "reloadTabChats" is posted from dozens of places, several of them in a row as a chat is
    /// opened and its messages are marked read. The count taken just *before* a chat was read
    /// could then land after the count taken once it had been, putting the mark back for
    /// messages that were already read and leaving it there until something else counted again.
    /// The slower the device the wider that window is, which is why an iPhone 7 shows it and a
    /// newer phone rarely does: the count is a SUM over three joined tables.
    ///
    /// One serial line means the reads happen in the order they were asked for, and the request
    /// number means only the newest one is read at all - a burst of posts now costs one query
    /// rather than one each.
    private let counterQueue = DispatchQueue(label: "io.nexilis.floatingbutton.counter", qos: .utility)
    private let counterLock = NSLock()
    private var counterRequests = 0

    private func newCounterRequest() -> Int {
        counterLock.lock()
        counterRequests += 1
        let request = counterRequests
        counterLock.unlock()
        return request
    }

    private func isNewestCounterRequest(_ request: Int) -> Bool {
        counterLock.lock()
        let newest = counterRequests
        counterLock.unlock()
        return request == newest
    }

    @objc func checkCounter() {
        let request = newCounterRequest()
        counterQueue.async { [weak self] in
            guard let self = self, self.isNewestCounterRequest(request) else {
                return
            }
            let counter = Int(APIS.getTotalCounter())
            // Asked again while this one was reading: that read is about to happen on this same
            // line, and it knows something this one does not.
            guard self.isNewestCounterRequest(request) else {
                return
            }
            DispatchQueue.main.async { [weak self] in
                guard let self = self, self.isNewestCounterRequest(request) else {
                    return
                }
                self.applyCounter(counter)
            }
        }
    }

    /// Puts a count on the button: the number beside the conversations item, and the mark on the
    /// button itself. Nothing here reads the database, so it cannot be the one that is late.
    private func applyCounter(_ counter: Int) {
        hasUnreadMark = counter > 0
        if hasUnreadMark {
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
            if !indicatorCounterFBBig.isDescendant(of: nexilis_button) {
                nexilis_button.addSubview(indicatorCounterFBBig)
                indicatorCounterFBBig.tintColor = .systemRed
                indicatorCounterFBBig.image = UIImage(systemName: "staroflife.circle.fill")
                indicatorCounterFBBig.anchor(top: nexilis_button.topAnchor, left: nexilis_button.leftAnchor, paddingTop: 5, paddingLeft: 5, width: 15, height: 15)
            }
            labelCounterFB.text = "\(counter)"
        } else {
            // Hidden as well as taken out: taking it out only works if it is where it was
            // expected to be, and hiding it is true wherever it ended up.
            if indicatorCounterFB.superview != nil {
                indicatorCounterFB.removeFromSuperview()
            }
            if indicatorCounterFBBig.superview != nil {
                indicatorCounterFBBig.removeFromSuperview()
            }
        }
        updateUnreadMark()
    }

    @objc func qmeraTap() {
        show(isShow: !isShow)
    }
    
    @objc func fbTap(_ sender: UIButton) {
        let package_id = sender.restorationIdentifier!
        var app_id = sender.accessibilityIdentifier!
        var indexTap = 0
        if package_id.contains("_fb"){
            let listSplit = package_id.split(separator: "_", maxSplits: 2, omittingEmptySubsequences: false).map { String($0) }
            let numIdx = listSplit[listSplit.firstIndex(where: { $0.contains("fb") }) ?? 0]
            indexTap = Int(String(numIdx).substring(from: 2, to: numIdx.count)) ?? 0
            if listSplit.count == 3 {
                app_id = String(listSplit[2])
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
            updateUnreadMark()
            // Opening the menu is a good moment to ask again: it is rare, it is the reader's own
            // doing, and it is the gesture somebody makes when the mark looks wrong.
            checkCounter()
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
                width = defaultWidthHeightMenuFB * countMenuFB
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
            updateUnreadMark()
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

/// Implemented by a host-app screen that wants a say in whether the floating button shows over
/// it - a screen that is sometimes a tab and sometimes pushed on its own, say. Screens that do
/// not implement it get the default answer for their bundle (see `FloatingButton.refresh()`).
public protocol FloatingButtonScreen: AnyObject {
    var showsFloatingButton: Bool { get }
}

// MARK: - Where the button is allowed to show
//
// Fix: this used to be nineteen separate `Nexilis.floatingButton.isHidden = ...` statements
// spread across the library and the host app - every screen that could ever cover the button
// had to remember to hide it on the way in, and every screen it could come back over had to
// remember to show it again. A screen that forgot (or a route nobody thought of - a push from
// a notification, a modal dismissed a different way) left the button floating over a chat, or
// left it gone for the rest of the session. It is one decision, so it is made in one place
// now, from the screen that is actually on top.
public extension FloatingButton {

    /// When true the button only ever shows over the host app's own screens: anything the
    /// library puts up - a chat editor, a call, a settings list - hides it, and it comes back
    /// by itself once that screen is gone. Left false, every screen keeps deciding for itself,
    /// which is what apps embedding this library have always relied on.
    static var showsOnAppScreensOnly: Bool = false {
        didSet {
            guard showsOnAppScreensOnly != oldValue else {
                return
            }
            if showsOnAppScreensOnly {
                observeAppState()
                startWatchdog()
                refresh()
            } else {
                stopWatchdog()
            }
        }
    }

    /// Held down while something is going on that the button has no business floating over -
    /// a call above all, which keeps running long after the screen that started it is gone.
    /// Outranks every other rule, in either mode.
    static var isSuppressed: Bool = false {
        didSet {
            guard isSuppressed != oldValue else {
                return
            }
            if isSuppressed {
                applyHidden(true)
            } else if showsOnAppScreensOnly {
                refresh()
            }
        }
    }

    /// The single place the button's visibility is set. Screens keep calling this; when
    /// `showsOnAppScreensOnly` is on it defers to whatever screen is really on top rather than
    /// taking the caller's word for it.
    ///
    /// Also the reason nothing needs to know whether the button exists yet: the property is
    /// implicitly unwrapped, so every one of those old direct assignments was a crash waiting
    /// for a screen that appeared before the button had been built.
    static func setHidden(_ hidden: Bool) {
        guard !isSuppressed else {
            applyHidden(true)
            return
        }
        guard !showsOnAppScreensOnly else {
            refresh()
            return
        }
        applyHidden(hidden)
    }

    /// Re-decides where the button belongs. Safe to call from anywhere, as often as wanted.
    static func refresh() {
        guard showsOnAppScreensOnly else {
            return
        }
        // Now, for the callers whose hierarchy is already settled (a screen appearing, the
        // button being added) so nothing flashes...
        if Thread.isMainThread {
            evaluate()
        }
        // ...and again next turn, for the ones where it is not: during a dismissal or a pop the
        // screen on its way out is still in the hierarchy, so deciding only now would get its
        // answer rather than the one underneath it.
        DispatchQueue.main.async {
            evaluate()
        }
    }

    /// Works out whether the button belongs over the screen showing right now, and shows or
    /// hides it to match.
    ///
    /// Fix: this cannot be driven by viewDidAppear alone. UIKit only reaches the library's hook
    /// there if every screen calls super - and 67 of the screens in this project do not, this
    /// app's chat list and the chat editors among them, which is exactly why the button stayed
    /// hidden after coming back out of a chat. So it is answered from the hierarchy itself,
    /// from several angles: the navigation swizzles (which always run, whatever a screen does),
    /// every screen that asks for a change, and a watchdog for the routes neither covers.
    private static func evaluate() {
        guard showsOnAppScreensOnly, let button = Nexilis.floatingButton, button.superview != nil else {
            return
        }
        if isSuppressed {
            if !button.isHidden {
                button.isHidden = true
            }
            return
        }
        guard let top = topScreen() else {
            return
        }
        let shouldHide: Bool
        if let screen = top as? FloatingButtonScreen {
            shouldHide = !screen.showsFloatingButton
        } else {
            // The host app's own screens, and only those. Anything from this library - or a
            // system screen covering everything, like a share sheet or a preview - is not the
            // app's own screen and the button stays out of its way.
            shouldHide = Bundle(for: type(of: top)) != Bundle.main
        }
        // Only when it actually changes: this runs on a timer as well, and assigning isHidden
        // on every tick would be pointless work.
        if button.isHidden != shouldHide {
            button.isHidden = shouldHide
            if !shouldHide {
                // Back in view, and most often straight out of a chat that has just cleared its
                // unread messages. Ask again rather than trusting a mark set before that.
                button.checkCounter()
            }
        }
    }

    private static func applyHidden(_ hidden: Bool) {
        guard let button = Nexilis.floatingButton else {
            return
        }
        if Thread.isMainThread {
            button.isHidden = hidden
        } else {
            DispatchQueue.main.async {
                Nexilis.floatingButton?.isHidden = hidden
            }
        }
    }

    // MARK: - Watchdog
    //
    // The guarantee that the button can never be left stuck. Every notification-driven path can
    // be missed - a screen that never calls super, a modal dismissed a way nobody hooked, a
    // controller swapped out from under the window - and the cost of missing one is a button
    // that is gone for the rest of the session. Re-deciding a few times a second costs a walk
    // down a handful of view-controller pointers and one comparison; it runs only while this
    // policy is on and only while the app is in front.

    private static var watchdog: Timer?
    private static var appStateObserved = false

    private static func startWatchdog() {
        DispatchQueue.main.async {
            watchdog?.invalidate()
            guard showsOnAppScreensOnly else {
                return
            }
            let timer = Timer(timeInterval: 0.3, repeats: true) { _ in
                evaluate()
            }
            // Generous tolerance so the system can coalesce these with whatever else it is
            // waking up for, and common mode so a scroll in progress does not silence it.
            timer.tolerance = 0.2
            RunLoop.main.add(timer, forMode: .common)
            watchdog = timer
        }
    }

    private static func stopWatchdog() {
        DispatchQueue.main.async {
            watchdog?.invalidate()
            watchdog = nil
        }
    }

    private static func observeAppState() {
        guard !appStateObserved else {
            return
        }
        appStateObserved = true
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { _ in
            startWatchdog()
            evaluate()
        }
        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { _ in
            stopWatchdog()
        }
    }

    /// The screen the reader is actually looking at: through whatever is presented, then down
    /// into tab bars and navigation stacks.
    private static func topScreen() -> UIViewController? {
        guard var controller = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            return nil
        }
        // Containers only ever nest a handful deep; the count is here so a malformed hierarchy
        // cannot spin this forever.
        for _ in 0..<20 {
            if let presented = controller.presentedViewController {
                controller = presented
            } else if let tab = controller as? UITabBarController, let selected = tab.selectedViewController {
                controller = selected
            } else if let navigation = controller as? UINavigationController, let top = navigation.topViewController {
                controller = top
            } else {
                break
            }
        }
        return controller
    }
}
