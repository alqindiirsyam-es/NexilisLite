//
//  ConfigureFloatingButton.swift
//  NexilisLite
//
//  Created by Akhmad Al Qindi Irsyam on 19/09/23.
//

import UIKit

public class ConfigureFloatingButton: UIViewController {
    let subContainerView = UIView()
    let titleConfigureFB = UILabel()
    var chosenMode: String = "1"
    var fullMode: [String] = ["1", "2", "3", "4", "5"]
    var dataMode: [String] = ["1. Floating Button (Vertical Mode)".localized(),"2. Animation (Vertical Mode)".localized(),"3. Animation (Horizontal Mode)".localized(),"4. Side-Tab (Horizontal Mode)".localized(), "5. Side-Tab (Vertical Mode)".localized()]
    var paddingTopFinishButton = NSLayoutConstraint()
    let buttonSet = UIButton()
    let modeButton = UIView()
    var paddingBottomSLButton = NSLayoutConstraint()
    var showPickerInt = 0
    let chosenModeTitle = UILabel()

    public override func viewDidLoad() {
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
        
        titleConfigureFB.font = .systemFont(ofSize: 18, weight: .bold)
        titleConfigureFB.text = "Configure Floating Button".localized()
        titleConfigureFB.textAlignment = .center
        subContainerView.addSubview(titleConfigureFB)
        titleConfigureFB.anchor(top: subContainerView.topAnchor, left: subContainerView.leftAnchor, right: subContainerView.rightAnchor)
        
        makeFinish()
        makeButtonMode()
        
    }
    
    private func getInisialData() {
        chosenMode = Utils.getConfigModeFB()
    }
    
    @objc func close() {
        self.dismiss(animated: true)
    }
    
    func makeFinish() {
        buttonSet.backgroundColor = .black
        buttonSet.setImage(UIImage(systemName: "checkmark"), for: .normal)
        buttonSet.tintColor = .white
        buttonSet.setTitle("Set".localized(), for: .normal)
        buttonSet.titleLabel?.font = .boldSystemFont(ofSize: 15)
        buttonSet.layer.cornerRadius = 8
        subContainerView.addSubview(buttonSet)
        buttonSet.anchor(bottom: subContainerView.bottomAnchor, right: subContainerView.rightAnchor, width: (self.view.bounds.width / 2) - 55, height: 40)
        paddingTopFinishButton = buttonSet.topAnchor.constraint(equalTo: titleConfigureFB.bottomAnchor, constant: 10)
        paddingTopFinishButton.isActive = true
        buttonSet.addTarget(self, action: #selector(setFB), for: .touchUpInside)
    }
    
    func makeButtonMode() {
        modeButton.backgroundColor = .white
        modeButton.isUserInteractionEnabled = true
        subContainerView.addSubview(modeButton)
        modeButton.anchor(top: titleConfigureFB.bottomAnchor, left: subContainerView.leftAnchor, right: subContainerView.rightAnchor, paddingTop: 10, height: 40)
        modeButton.layer.cornerRadius = 10
        modeButton.layer.masksToBounds = true
        let titleTypeButton = UILabel()
        titleTypeButton.font = .systemFont(ofSize: 14, weight: .bold)
        titleTypeButton.text = "New Mode".localized()
        titleTypeButton.textColor = .gray
        modeButton.addSubview(titleTypeButton)
        titleTypeButton.anchor(left: modeButton.leftAnchor, paddingLeft: 10, centerY: modeButton.centerYAnchor)
        let accessoryType = UIImageView()
        accessoryType.image = UIImage(systemName: "chevron.right")
        accessoryType.tintColor = .gray
        modeButton.addSubview(accessoryType)
        accessoryType.anchor(right: modeButton.rightAnchor, paddingRight: 10, centerY: modeButton.centerYAnchor)
        chosenModeTitle.font = .systemFont(ofSize: 14)
        chosenModeTitle.text = dataMode[Int(chosenMode)! - 1]
        chosenModeTitle.textColor = .gray
        modeButton.addSubview(chosenModeTitle)
        modeButton.tag = 0
        chosenModeTitle.anchor(right: accessoryType.leftAnchor, paddingLeft: 15, centerY: modeButton.centerYAnchor)
        let tap = UITapGestureRecognizer(target: self, action: #selector(showPicker(sender:)))
        modeButton.addGestureRecognizer(tap)
        let constPaddingTop = 55
        paddingTopFinishButton.constant = CGFloat(constPaddingTop)
    }
    
    @objc func setFB() {
        Utils.setConfigModeFB(value: chosenMode)
        if !Utils.getAfterConfigFB() {
            Utils.setAfterConfigFB(value: true)
        }
        DispatchQueue.main.async {
            Nexilis.floatingButton.removeFromSuperview()
            Nexilis.floatingButton = FloatingButton()
            let viewController = (UIApplication.shared.windows.first?.rootViewController)!
            Nexilis.addFB(viewController: viewController, fromMAB: Nexilis.fromMAB)
        }
        close()
    }
    
    @objc func showPicker(sender: UITapGestureRecognizer) {
        showPickerInt = sender.view!.tag
        
        let index = fullMode.firstIndex(of: chosenMode)!
        let titleChooser = "New Mode".localized()
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
        
        alert.addAction(UIAlertAction(title: "Select".localized(), style: .default, handler: { [self] (UIAlertAction) in
            let selectedIndex = pickerView.selectedRow(inComponent: 0)
            chosenMode = fullMode[selectedIndex]
            chosenModeTitle.text = dataMode[selectedIndex]
        }))
        self.present(alert, animated: true, completion: nil)
    }

}

extension ConfigureFloatingButton: UIPickerViewDelegate, UIPickerViewDataSource {
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }
    
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return dataMode.count
    }
    
    public func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return dataMode[row]
    }
}

