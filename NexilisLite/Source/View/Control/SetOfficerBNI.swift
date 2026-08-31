//
//  SetOfficerBNI.swift
//  NexilisLite
//
//  Created by Qindi on 20/06/22.
//

import UIKit
@_implementationOnly import NotificationBannerSwift
import nuSDKService

class SetOfficerBNI: UIViewController {
    
    var nextData: [Int: [CategoryCC]] = [:]
    var chosenData: [CategoryCC] = []
    var dataSecondLayer: [String] = ["No".localized(),"Yes".localized()]
    var chosenSecondLayer: String = "No".localized()
    var chosenWorkingArea: WorkingArea?
    let subContainerView = UIView()
    let titleSetOfficer = UILabel()
    var showPickerInt = 0
    var isSecondLayerChooser = false
    var isWorkingArea = false
    var paddingTopFinishButton = NSLayoutConstraint()
    var paddingBottomSLButton = NSLayoutConstraint()
    var f_pin = ""
    var name = ""
    let buttonSet = UIButton()
    let secondLayerButton = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        getInisialData()

        view.backgroundColor = .black.withAlphaComponent(0.3)
        
        let containerView = UIView()
        view.addSubview(containerView)
        containerView.anchor(centerX: view.centerXAnchor, centerY: view.centerYAnchor, width: view.bounds.width - 40, minHeight: 100, maxHeight: view.bounds.height - 100)
        containerView.backgroundColor = .white.withAlphaComponent(0.9)
        containerView.layer.cornerRadius = 15.0
        containerView.clipsToBounds = true
        
        subContainerView.backgroundColor = .clear
        containerView.addSubview(subContainerView)
        subContainerView.anchor(top: containerView.topAnchor, left: containerView.leftAnchor, bottom: containerView.bottomAnchor, right: containerView.rightAnchor, paddingTop: 20.0, paddingLeft: 10.0, paddingBottom: 20.0, paddingRight: 10.0)
        
        let buttonClose = UIButton(type: .close)
        buttonClose.frame.size = CGSize(width: 30, height: 30)
        buttonClose.layer.cornerRadius = 15.0
        buttonClose.clipsToBounds = true
        buttonClose.backgroundColor = .secondaryColor.withAlphaComponent(0.5)
        buttonClose.addTarget(self, action: #selector(close), for: .touchUpInside)
        containerView.addSubview(buttonClose)
        buttonClose.anchor(top: containerView.topAnchor, right: containerView.rightAnchor, width: 30, height: 30)
        
        titleSetOfficer.font = .systemFont(ofSize: 18, weight: .bold)
        titleSetOfficer.text = "Set Category Officer".localized()
        titleSetOfficer.textAlignment = .center
        subContainerView.addSubview(titleSetOfficer)
        titleSetOfficer.anchor(top: subContainerView.topAnchor, left: subContainerView.leftAnchor, right: subContainerView.rightAnchor)
        
        makeFinish()
        makeButtonSecondLayer()
        makeButtonType()
        makeButtonSubType(level: 0)
    }
    
    private func getInisialData() {
        let data = CategoryCC.getDatafromParent(parent: CategoryCC.default_parent)
        nextData[0] = data
        chosenData.append(nextData[0]![0])
    }
    
    @objc func close() {
        self.dismiss(animated: true)
    }
    
    func makeButtonWorkingArea() {
        let workingAreaButton = UIView()
        workingAreaButton.backgroundColor = .white
        workingAreaButton.isUserInteractionEnabled = true
        subContainerView.insertSubview(workingAreaButton, belowSubview: secondLayerButton)
        workingAreaButton.anchor(left: subContainerView.leftAnchor, bottom: buttonSet.topAnchor, right: subContainerView.rightAnchor, paddingBottom: 10, height: 40)
        workingAreaButton.layer.cornerRadius = 10
        workingAreaButton.layer.masksToBounds = true
        let titleTypeButton = UILabel()
        titleTypeButton.font = .systemFont(ofSize: 14, weight: .bold)
        titleTypeButton.text = "Working Area".localized()
        titleTypeButton.textColor = .gray
        workingAreaButton.addSubview(titleTypeButton)
        titleTypeButton.anchor(left: workingAreaButton.leftAnchor, paddingLeft: 10, centerY: workingAreaButton.centerYAnchor)
        let accessoryType = UIImageView()
        accessoryType.image = UIImage(systemName: "chevron.right")
        accessoryType.tintColor = .gray
        workingAreaButton.addSubview(accessoryType)
        accessoryType.anchor(right: workingAreaButton.rightAnchor, paddingRight: 10, centerY: workingAreaButton.centerYAnchor)
        let chosenType = UILabel()
        chosenType.font = .systemFont(ofSize: 14)
        chosenType.text = chosenWorkingArea == nil ? "" : chosenWorkingArea!.name
        chosenType.textColor = .gray
        workingAreaButton.addSubview(chosenType)
        workingAreaButton.tag = 0
        workingAreaButton.restorationIdentifier = "workingArea"
        chosenType.anchor(right: accessoryType.leftAnchor, paddingLeft: 15, centerY: workingAreaButton.centerYAnchor)
        let tap = UITapGestureRecognizer(target: self, action: #selector(showWorkingAreaPicker(sender:)))
        workingAreaButton.addGestureRecognizer(tap)
    }
    
    func makeButtonSecondLayer() {
        secondLayerButton.backgroundColor = .white
        secondLayerButton.isUserInteractionEnabled = true
        subContainerView.addSubview(secondLayerButton)
        secondLayerButton.anchor(left: subContainerView.leftAnchor, right: subContainerView.rightAnchor, height: 40)
        paddingBottomSLButton = secondLayerButton.bottomAnchor.constraint(equalTo: buttonSet.topAnchor, constant: -10)
        paddingBottomSLButton.isActive = true
        secondLayerButton.layer.cornerRadius = 10
        secondLayerButton.layer.masksToBounds = true
        let titleTypeButton = UILabel()
        titleTypeButton.font = .systemFont(ofSize: 14, weight: .bold)
        titleTypeButton.text = "Second Layer".localized()
        titleTypeButton.textColor = .gray
        secondLayerButton.addSubview(titleTypeButton)
        titleTypeButton.anchor(left: secondLayerButton.leftAnchor, paddingLeft: 10, centerY: secondLayerButton.centerYAnchor)
        let accessoryType = UIImageView()
        accessoryType.image = UIImage(systemName: "chevron.right")
        accessoryType.tintColor = .gray
        secondLayerButton.addSubview(accessoryType)
        accessoryType.anchor(right: secondLayerButton.rightAnchor, paddingRight: 10, centerY: secondLayerButton.centerYAnchor)
        let chosenType = UILabel()
        chosenType.font = .systemFont(ofSize: 14)
        chosenType.text = dataSecondLayer[0]
        chosenType.textColor = .gray
        secondLayerButton.addSubview(chosenType)
        secondLayerButton.tag = 0
        secondLayerButton.restorationIdentifier = "secondLayer"
        chosenType.anchor(right: accessoryType.leftAnchor, paddingLeft: 15, centerY: secondLayerButton.centerYAnchor)
        let tap = UITapGestureRecognizer(target: self, action: #selector(showPicker(sender:)))
        secondLayerButton.addGestureRecognizer(tap)
    }
    
    func makeButtonType() {
        let typeButton = UIView()
        typeButton.backgroundColor = .white
        typeButton.isUserInteractionEnabled = true
        subContainerView.addSubview(typeButton)
        typeButton.anchor(top: titleSetOfficer.bottomAnchor, left: subContainerView.leftAnchor, right: subContainerView.rightAnchor, paddingTop: 10, height: 40)
        typeButton.layer.cornerRadius = 10
        typeButton.layer.masksToBounds = true
        let titleTypeButton = UILabel()
        titleTypeButton.font = .systemFont(ofSize: 14, weight: .bold)
        titleTypeButton.text = "Product".localized()
        titleTypeButton.textColor = .gray
        typeButton.addSubview(titleTypeButton)
        titleTypeButton.anchor(left: typeButton.leftAnchor, paddingLeft: 10, centerY: typeButton.centerYAnchor)
        let accessoryType = UIImageView()
        accessoryType.image = UIImage(systemName: "chevron.right")
        accessoryType.tintColor = .gray
        typeButton.addSubview(accessoryType)
        accessoryType.anchor(right: typeButton.rightAnchor, paddingRight: 10, centerY: typeButton.centerYAnchor)
        let chosenType = UILabel()
        chosenType.font = .systemFont(ofSize: 14)
        chosenType.text = chosenData[0].service_name
        chosenType.textColor = .gray
        typeButton.addSubview(chosenType)
        typeButton.tag = 0
        chosenType.anchor(right: accessoryType.leftAnchor, paddingLeft: 15, centerY: typeButton.centerYAnchor)
        let tap = UITapGestureRecognizer(target: self, action: #selector(showPicker(sender:)))
        typeButton.addGestureRecognizer(tap)
    }
    
    func makeButtonSubType(level: Int) {
        let data = CategoryCC.getDatafromParent(parent: chosenData[level].service_id)
        if data.count != 0 {
            nextData[level + 1] = data
            if chosenData.count - 1 == level + 1 {
                chosenData.remove(at: level + 1)
                chosenData.insert(nextData[level + 1]![0], at: level + 1)
            } else {
                chosenData.append(nextData[level + 1]![0])
            }
            let typeButton = UIView()
            typeButton.backgroundColor = .white
            typeButton.isUserInteractionEnabled = true
            subContainerView.addSubview(typeButton)
            let constPaddingTop = level == 0 ? 55 : 55 + (45 * level)
            typeButton.anchor(top: titleSetOfficer.bottomAnchor, left: subContainerView.leftAnchor, right: subContainerView.rightAnchor, paddingTop: CGFloat(constPaddingTop), height: 40)
            typeButton.layer.cornerRadius = 10
            typeButton.layer.masksToBounds = true
            let titleTypeButton = UILabel()
            titleTypeButton.font = .systemFont(ofSize: 14, weight: .bold)
            titleTypeButton.text = level == 0 ? "Category".localized() :"Sub-Category".localized()
            titleTypeButton.textColor = .gray
            typeButton.addSubview(titleTypeButton)
            titleTypeButton.anchor(left: typeButton.leftAnchor, paddingLeft: 10, centerY: typeButton.centerYAnchor)
            let accessoryType = UIImageView()
            accessoryType.image = UIImage(systemName: "chevron.right")
            accessoryType.tintColor = .gray
            typeButton.addSubview(accessoryType)
            accessoryType.anchor(right: typeButton.rightAnchor, paddingRight: 10, centerY: typeButton.centerYAnchor)
            let chosenType = UILabel()
            chosenType.font = .systemFont(ofSize: 14)
            chosenType.text = chosenData[level + 1].service_name
            chosenType.textColor = .gray
            typeButton.addSubview(chosenType)
            typeButton.tag = level + 1
            chosenType.anchor(right: accessoryType.leftAnchor, paddingLeft: 15, centerY: typeButton.centerYAnchor)
            let tap = UITapGestureRecognizer(target: self, action: #selector(showPicker(sender:)))
            typeButton.addGestureRecognizer(tap)
            paddingTopFinishButton.constant = CGFloat(constPaddingTop) + 50 + 45
            if chosenSecondLayer == "Yes".localized() {
                paddingTopFinishButton.constant = paddingTopFinishButton.constant + 45
            }
        } else {
            paddingTopFinishButton.constant = 105
        }
    }
    
    @objc func showWorkingAreaPicker(sender: UITapGestureRecognizer) {
        let workingAreaPickerVC = WorkingAreaPicker()
        workingAreaPickerVC.selectedData = { selectedData in
            self.chosenWorkingArea = selectedData
            let buttonWA = self.subContainerView.subviews[2]
            let titleChosen = buttonWA.subviews[buttonWA.subviews.count - 1] as! UILabel
            titleChosen.text = selectedData.name
        }
        self.present(workingAreaPickerVC, animated: true, completion: nil)
    }
    
    @objc func showPicker(sender: UITapGestureRecognizer) {
        showPickerInt = sender.view!.tag
        
        let fullData = nextData[showPickerInt]
        var index = (fullData?.firstIndex(of: chosenData[showPickerInt]))!
        var titleChooser = "Select Product".localized()
        if showPickerInt == 1 {
            titleChooser = "Select Category".localized()
        } else if showPickerInt > 1 {
            titleChooser = "Select Sub-Category".localized()
        }
        
        if sender.view!.restorationIdentifier == "workingArea" {
            isWorkingArea = true
        } else if sender.view!.restorationIdentifier == "secondLayer" {
            isSecondLayerChooser = true
            index = dataSecondLayer.firstIndex(of: chosenSecondLayer)!
            titleChooser = "Is Second Layer?".localized()
        } else {
            isSecondLayerChooser = false
            if self.chosenData.count - self.showPickerInt > 2 {
                return
            }
        }
        
        let pickerView = UIPickerView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width - 10, height: 100))
        pickerView.dataSource = self
        pickerView.delegate = self
        
        let vc = UIViewController()
        vc.preferredContentSize = CGSize(width: UIScreen.main.bounds.width - 10, height: 100)
        pickerView.selectRow(index, inComponent: 0, animated: false)
        
        vc.view.addSubview(pickerView)
        pickerView.translatesAutoresizingMaskIntoConstraints = false
        pickerView.centerXAnchor.constraint(equalTo: vc.view.centerXAnchor).isActive = true
        pickerView.centerYAnchor.constraint(equalTo: vc.view.centerYAnchor).isActive = true
        
        let alert = LibAlertController(title: titleChooser, message: "", preferredStyle: .actionSheet)
        
        alert.setValue(vc, forKey: "contentViewController")
        alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: { (UIAlertAction) in
        }))
        
        alert.addAction(UIAlertAction(title: "Select".localized(), style: .default, handler: { (UIAlertAction) in
            let selectedIndex = pickerView.selectedRow(inComponent: 0)
            if self.isSecondLayerChooser {
                self.isSecondLayerChooser = false
                var buttonSecondLayer = self.subContainerView.subviews[2]
                if self.dataSecondLayer[selectedIndex] == "Yes".localized() {
                    if self.chosenSecondLayer != self.dataSecondLayer[selectedIndex] {
                        self.makeButtonWorkingArea()
                        self.paddingBottomSLButton.constant -= 45
                        self.paddingTopFinishButton.constant += 45
                    }
                } else {
                    if self.chosenSecondLayer != self.dataSecondLayer[selectedIndex] {
                        let buttonWA = self.subContainerView.subviews[2]
                        buttonWA.removeConstraints(buttonWA.constraints)
                        buttonWA.removeFromSuperview()
                        self.paddingBottomSLButton.constant += 45
                        self.paddingTopFinishButton.constant -= 45
                        self.chosenWorkingArea = nil
                        buttonSecondLayer = self.subContainerView.subviews[2]
                    }
                }
                let titleChosen = buttonSecondLayer.subviews[buttonSecondLayer.subviews.count - 1] as! UILabel
                titleChosen.text = self.dataSecondLayer[selectedIndex]
                self.chosenSecondLayer = self.dataSecondLayer[selectedIndex]
                return
            }
            let data = CategoryCC.getDatafromParent(parent: self.nextData[self.showPickerInt]![selectedIndex].service_id)
            var moreSubViews = 1
            if self.chosenSecondLayer == "Yes".localized() {
                moreSubViews = 2
            }
            if !(self.subContainerView.subviews[self.subContainerView.subviews.count - (2 + self.showPickerInt + moreSubViews)] is UIButton) {
                let buttonSubType = self.subContainerView.subviews[self.subContainerView.subviews.count - 1]
                buttonSubType.removeConstraints(buttonSubType.constraints)
                buttonSubType.removeFromSuperview()
                self.chosenData.remove(at: self.showPickerInt + 1)
            }
            self.chosenData.remove(at: self.showPickerInt)
            self.chosenData.insert(self.nextData[self.showPickerInt]![selectedIndex], at: self.showPickerInt)
            var buttonType = self.subContainerView.subviews[self.subContainerView.subviews.count - 1]
            if data.count != 0 {
                self.makeButtonSubType(level: self.showPickerInt)
                buttonType = self.subContainerView.subviews[self.subContainerView.subviews.count - 2]
            } else {
                self.paddingTopFinishButton.constant = CGFloat(self.showPickerInt == 0 ? 60 : 60 + (45 * self.showPickerInt)) + CGFloat(45 * moreSubViews)
            }
            let titleChosen = buttonType.subviews[buttonType.subviews.count - 1] as! UILabel
            titleChosen.text = self.chosenData[self.showPickerInt].service_name
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func makeFinish() {
        buttonSet.backgroundColor = .black
        buttonSet.setImage(UIImage(systemName: "checkmark"), for: .normal)
        buttonSet.tintColor = .white
        buttonSet.setTitle("Set Officer".localized(), for: .normal)
        buttonSet.titleLabel?.font = .boldSystemFont(ofSize: 15)
        buttonSet.layer.cornerRadius = 8
        subContainerView.addSubview(buttonSet)
        buttonSet.anchor(bottom: subContainerView.bottomAnchor, right: subContainerView.rightAnchor, width: (self.view.bounds.width / 2) - 55, height: 40)
        paddingTopFinishButton = buttonSet.topAnchor.constraint(equalTo: titleSetOfficer.bottomAnchor, constant: 10)
        paddingTopFinishButton.isActive = true
        buttonSet.addTarget(self, action: #selector(setOfficer), for: .touchUpInside)
    }
    
    @objc func setOfficer() {
        let alert = LibAlertController(title: "Set Officer Account".localized(), message: "Are you sure want to add \(name) to Officer Account category \(self.chosenData[self.chosenData.count - 1].service_name)?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Yes".localized(), style: .default, handler: { (action) -> Void in
            if !CheckConnection.isConnectedToNetwork()  || API.nGetCLXConnState() == 0 {
                let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                imageView.tintColor = .white
                let banner = FloatingNotificationBanner(title: "Check your connection".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                banner.show()
                return
            }
            let message = CoreMessage_TMessageBank.getManagementContactCenterBNI(l_pin:  self.f_pin, type: "1", category_id: "\(self.chosenData[self.chosenData.count - 1].service_id)", area_id: self.chosenSecondLayer == "Yes".localized() ? "1" : "0", is_second_layer: self.chosenWorkingArea != nil && self.chosenSecondLayer == "Yes".localized() ? self.chosenWorkingArea!.area_id : "")
//            message.mBodies[CoreMessage_TMessageKey.CATEGORY_ID] = "\(self.chosenData[self.chosenData.count - 1].service_id)"
            if let response = Nexilis.writeSync(message: message) {
                if response.isOk() {
                    DispatchQueue.main.async {
                        let imageView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
                        imageView.tintColor = .white
                        let banner = FloatingNotificationBanner(title: "Successfully changed".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .success, colors: nil, iconPosition: .center)
                        banner.show()
                        self.dismiss(animated: true)
                    }
                }
                DispatchQueue.main.async {
                    if response.getBody(key: CoreMessage_TMessageKey.ERRCOD, default_value: "99") == "11" {
                        let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                        imageView.tintColor = .white
                        let banner = FloatingNotificationBanner(title: "Username or password does not match".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                        banner.show()
                    } else if response.getBody(key: CoreMessage_TMessageKey.ERRCOD, default_value: "99") == "20" {
                        let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                        imageView.tintColor = .white
                        let banner = FloatingNotificationBanner(title: "Invalid password".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
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
        }))
        alert.addAction(UIAlertAction(title: "No".localized(), style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

}

extension SetOfficerBNI: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if isSecondLayerChooser {
            return dataSecondLayer.count
        }
        return nextData[showPickerInt]!.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if isSecondLayerChooser {
            return dataSecondLayer[row]
        }
        return nextData[showPickerInt]![row].service_name
    }
}
