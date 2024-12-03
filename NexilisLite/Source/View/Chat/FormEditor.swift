//
//  FormEditor.swift
//  NexilisLite
//
//  Created by Qindi on 20/05/22.
//

import UIKit
import NotificationBannerSwift
import nuSDKService

class FormEditor: UIViewController {
    
    var jsonData = ""
    var dataMessage: [String: Any?] = [:]
    var dataPerson: [String: String?] = [:]
    var isAorR: Int?
    var dateApproved = ""

    override func viewDidLoad() {
        super.viewDidLoad()

        let containerView = UIView()
        self.view.addSubview(containerView)
        containerView.backgroundColor = .white
        containerView.anchor(top: self.view.topAnchor, left: self.view.leftAnchor, bottom: self.view.bottomAnchor, right: self.view.rightAnchor, paddingTop: 50, paddingLeft: 40, paddingBottom: 100, paddingRight: 40)
        
        let viewTitle = UIView()
        viewTitle.backgroundColor = .mainColor
        containerView.addSubview(viewTitle)
        viewTitle.anchor(top: containerView.topAnchor, left: containerView.leftAnchor, right: containerView.rightAnchor, height: 40)
        
        if let json = try! JSONSerialization.jsonObject(with: jsonData.data(using: String.Encoding.utf8)!, options: []) as? [String: Any] {
            let title = UILabel()
            title.text = (json["form_title"] as! String).replacingOccurrences(of: "+", with: " ")
            title.font = .systemFont(ofSize: 15.0, weight: .bold)
            title.textColor = .white
            viewTitle.addSubview(title)
            title.anchor(centerX: viewTitle.centerXAnchor, centerY: viewTitle.centerYAnchor)
            
            if checkForm(json: json){
                buildRorAView(json: json, viewTitle: viewTitle, containerView: containerView)
            } else {
                buildWaitingApprovalView(json: json, viewTitle: viewTitle, containerView: containerView)
            }
            
            let buttonClose = UIButton()
            buttonClose.frame.size = CGSize(width: 50, height: 50)
            buttonClose.layer.cornerRadius = 25
            buttonClose.clipsToBounds = true
            buttonClose.setBackgroundImage(UIImage(systemName: "xmark.circle"), for: .normal)
            buttonClose.tintColor = .mainColor
            buttonClose.actionHandle(controlEvents: .touchUpInside,
             ForAction:{() -> Void in
                self.dismiss(animated: true, completion: nil)
             })
            self.view.addSubview(buttonClose)
            buttonClose.anchor(top: containerView.bottomAnchor, centerX: self.view.centerXAnchor, width: 50, height: 50)
        }
    }
    
    private func checkForm(json: [String: Any]) -> Bool {
        var result = false
//        Database.shared.database?.inTransaction({ (fmdb, rollback) in
//            if let dataForm = Database().getRecords(fmdb: fmdb, query: "select sq_no, created_date from FORM where form_id = '\(dataMessage["reff_id"] as! String)'"), dataForm.next() {
//                result = true
//                isAorR = Int(dataForm.int(forColumnIndex: 0))
//                dateApproved = dataForm.string(forColumnIndex: 1)!
//            }
//        })
        return result
    }
    
    private func buildRorAView(json: [String: Any], viewTitle: UIView, containerView: UIView) {
        if isAorR != nil {
            let viewStatus = UIView()
            containerView.addSubview(viewStatus)
            viewStatus.anchor(top: viewTitle.bottomAnchor, left: containerView.leftAnchor, right: containerView.rightAnchor, height: 20)
            
            let textStatus = UILabel()
            viewStatus.addSubview(textStatus)
            textStatus.anchor(centerX: viewStatus.centerXAnchor, centerY: viewStatus.centerYAnchor)
            textStatus.font = .systemFont(ofSize: 14, weight: .bold)
            textStatus.textColor = .white
            
            let imageProvince = UIImageView()
            imageProvince.image = UIImage(systemName: "doc.text.image")
            imageProvince.tintColor = .mainColor
            imageProvince.contentMode = .scaleToFill
            containerView.addSubview(imageProvince)
            imageProvince.anchor(top: viewStatus.bottomAnchor, left: containerView.leftAnchor, paddingTop: 15, paddingLeft: 10, width: 20, height: 20)
            
            let province = UILabel()
            province.text = "Province".localized()
            province.font = .systemFont(ofSize: 14.0, weight: .bold)
            province.textColor = .gray
            containerView.addSubview(province)
            province.anchor(top: viewStatus.bottomAnchor, left: imageProvince.rightAnchor, right: containerView.rightAnchor, paddingTop: 10, paddingLeft: 10)
            
            let provinceFill = UILabel()
            provinceFill.text = json["province"] as? String
            provinceFill.font = .systemFont(ofSize: 14.0)
            provinceFill.textColor = .black
            containerView.addSubview(provinceFill)
            provinceFill.anchor(top: province.bottomAnchor, left:  imageProvince.rightAnchor, right: containerView.rightAnchor, paddingLeft: 10)
            
            let imageClub = UIImageView()
            imageClub.image = UIImage(systemName: "doc.text.image")
            imageClub.tintColor = .mainColor
            imageClub.contentMode = .scaleToFill
            containerView.addSubview(imageClub)
            imageClub.anchor(top: provinceFill.bottomAnchor, left: containerView.leftAnchor, paddingTop: 15, paddingLeft: 10, width: 20, height: 20)
            
            let club = UILabel()
            club.text = "Club".localized()
            club.font = .systemFont(ofSize: 14.0, weight: .bold)
            club.textColor = .gray
            containerView.addSubview(club)
            club.anchor(top: provinceFill.bottomAnchor, left: imageClub.rightAnchor, right: containerView.rightAnchor, paddingTop: 10, paddingLeft: 10)
            
            let clubFill = UILabel()
            clubFill.text = json["club"] as? String
            clubFill.font = .systemFont(ofSize: 14.0)
            clubFill.textColor = .black
            containerView.addSubview(clubFill)
            clubFill.anchor(top: club.bottomAnchor, left: imageClub.rightAnchor, right: containerView.rightAnchor, paddingLeft: 10)
            
            let imageAorR = UIImageView()
            imageAorR.image = UIImage(systemName: "person.fill")
            imageAorR.tintColor = .mainColor
            imageAorR.contentMode = .scaleToFill
            containerView.addSubview(imageAorR)
            imageAorR.anchor(top: clubFill.bottomAnchor, left: containerView.leftAnchor, paddingTop: 15, paddingLeft: 10, width: 20, height: 20)
            
            let descAorR = UILabel()
            descAorR.font = .systemFont(ofSize: 14.0, weight: .bold)
            descAorR.textColor = .gray
            containerView.addSubview(descAorR)
            descAorR.anchor(top: clubFill.bottomAnchor, left: imageAorR.rightAnchor, right: containerView.rightAnchor, paddingTop: 10, paddingLeft: 10)
            
            let name = UILabel()
            name.text = User.getData(pin: User.getMyPin())?.fullName
            name.font = .systemFont(ofSize: 14.0)
            name.textColor = .black
            containerView.addSubview(name)
            name.anchor(top: descAorR.bottomAnchor, left: imageAorR.rightAnchor, right: containerView.rightAnchor, paddingLeft: 10)
            
            let imageDateAorR = UIImageView()
            imageDateAorR.image = UIImage(systemName: "person.fill")
            imageDateAorR.tintColor = .mainColor
            imageDateAorR.contentMode = .scaleToFill
            containerView.addSubview(imageDateAorR)
            imageDateAorR.anchor(top: name.bottomAnchor, left: containerView.leftAnchor, paddingTop: 15, paddingLeft: 10, width: 20, height: 20)
            
            let dateAorR = UILabel()
            dateAorR.text = "Time".localized()
            dateAorR.font = .systemFont(ofSize: 14.0, weight: .bold)
            dateAorR.textColor = .gray
            containerView.addSubview(dateAorR)
            dateAorR.anchor(top: name.bottomAnchor, left: imageAorR.rightAnchor, right: containerView.rightAnchor, paddingTop: 10, paddingLeft: 10)
            
            let dateLabel = UILabel()
            let stringDate = dateApproved.isEmpty ? "\(Date().currentTimeMillis())" : dateApproved
            let date = Date(milliseconds: Int64(stringDate)!)
            let formatter = DateFormatter()
            formatter.dateFormat = "dd MMM yyyy, HH:mm"
            formatter.locale = NSLocale(localeIdentifier: "id") as Locale?
            dateLabel.text = formatter.string(from: date as Date)
            dateLabel.font = .systemFont(ofSize: 14.0)
            dateLabel.textColor = .black
            containerView.addSubview(dateLabel)
            dateLabel.anchor(top: dateAorR.bottomAnchor, left: imageAorR.rightAnchor, right: containerView.rightAnchor, paddingLeft: 10)
            
            if isAorR == 0 {
                viewStatus.backgroundColor = .systemRed
                textStatus.text = "Rejected".localized()
                descAorR.text = "Rejected by".localized()
            } else {
                viewStatus.backgroundColor = .systemGreen
                textStatus.text = "Approved".localized()
                descAorR.text = "Approved by".localized()
            }
        }
    }
    
    private func buildWaitingApprovalView(json: [String: Any], viewTitle: UIView, containerView: UIView) {
        let imageRequested = UIImageView()
        imageRequested.image = UIImage(systemName: "person.fill")
        imageRequested.tintColor = .mainColor
        imageRequested.contentMode = .scaleToFill
        containerView.addSubview(imageRequested)
        imageRequested.anchor(top: viewTitle.bottomAnchor, left: containerView.leftAnchor, paddingTop: 15, paddingLeft: 10, width: 20, height: 20)
        
        let requestedBy = UILabel()
        requestedBy.text = "Requested by".localized()
        requestedBy.font = .systemFont(ofSize: 14.0, weight: .bold)
        requestedBy.textColor = .gray
        containerView.addSubview(requestedBy)
        requestedBy.anchor(top: viewTitle.bottomAnchor, left: imageRequested.rightAnchor, right: containerView.rightAnchor, paddingTop: 10, paddingLeft: 10)
        
        let name = UILabel()
        name.text = dataPerson["name"] as? String
        name.font = .systemFont(ofSize: 14.0)
        name.textColor = .black
        containerView.addSubview(name)
        name.anchor(top: requestedBy.bottomAnchor, left: imageRequested.rightAnchor, right: containerView.rightAnchor, paddingLeft: 10)
        
        let imageClubType = UIImageView()
        imageClubType.image = UIImage(systemName: "doc.text.image")
        imageClubType.tintColor = .mainColor
        imageClubType.contentMode = .scaleToFill
        containerView.addSubview(imageClubType)
        imageClubType.anchor(top: name.bottomAnchor, left: containerView.leftAnchor, paddingTop: 15, paddingLeft: 10, width: 20, height: 20)
        
        let clubType = UILabel()
        clubType.text = "Club Type".localized()
        clubType.font = .systemFont(ofSize: 14.0, weight: .bold)
        clubType.textColor = .gray
        containerView.addSubview(clubType)
        clubType.anchor(top: name.bottomAnchor, left: imageClubType.rightAnchor, right: containerView.rightAnchor, paddingTop: 10, paddingLeft: 10)
        
        let clubTypeFill = UILabel()
        clubTypeFill.text = json["club_type"] as? String
        clubTypeFill.font = .systemFont(ofSize: 14.0)
        clubTypeFill.textColor = .black
        containerView.addSubview(clubTypeFill)
        clubTypeFill.anchor(top: clubType.bottomAnchor, left: imageClubType.rightAnchor, right: containerView.rightAnchor, paddingLeft: 10)
        
        let imageProvince = UIImageView()
        imageProvince.image = UIImage(systemName: "doc.text.image")
        imageProvince.tintColor = .mainColor
        imageProvince.contentMode = .scaleToFill
        containerView.addSubview(imageProvince)
        imageProvince.anchor(top: clubTypeFill.bottomAnchor, left: containerView.leftAnchor, paddingTop: 15, paddingLeft: 10, width: 20, height: 20)
        
        let province = UILabel()
        province.text = "Province".localized()
        province.font = .systemFont(ofSize: 14.0, weight: .bold)
        province.textColor = .gray
        containerView.addSubview(province)
        province.anchor(top: clubTypeFill.bottomAnchor, left: imageProvince.rightAnchor, right: containerView.rightAnchor, paddingTop: 10, paddingLeft: 10)
        
        let provinceFill = UILabel()
        provinceFill.text = json["province"] as? String
        provinceFill.font = .systemFont(ofSize: 14.0)
        provinceFill.textColor = .black
        containerView.addSubview(provinceFill)
        provinceFill.anchor(top: province.bottomAnchor, left:  imageProvince.rightAnchor, right: containerView.rightAnchor, paddingLeft: 10)
        
        let imageClub = UIImageView()
        imageClub.image = UIImage(systemName: "doc.text.image")
        imageClub.tintColor = .mainColor
        imageClub.contentMode = .scaleToFill
        containerView.addSubview(imageClub)
        imageClub.anchor(top: provinceFill.bottomAnchor, left: containerView.leftAnchor, paddingTop: 15, paddingLeft: 10, width: 20, height: 20)
        
        let club = UILabel()
        club.text = "Club".localized()
        club.font = .systemFont(ofSize: 14.0, weight: .bold)
        club.textColor = .gray
        containerView.addSubview(club)
        club.anchor(top: provinceFill.bottomAnchor, left: imageClub.rightAnchor, right: containerView.rightAnchor, paddingTop: 10, paddingLeft: 10)
        
        let clubFill = UILabel()
        clubFill.text = json["club"] as? String
        clubFill.font = .systemFont(ofSize: 14.0)
        clubFill.textColor = .black
        containerView.addSubview(clubFill)
        clubFill.anchor(top: club.bottomAnchor, left: imageClub.rightAnchor, right: containerView.rightAnchor, paddingLeft: 10)
        
        let buttonReject = UIButton()
        buttonReject.backgroundColor = .systemRed
        buttonReject.setImage(UIImage(systemName: "xmark"), for: .normal)
        buttonReject.tintColor = .white
        buttonReject.setTitle("Reject".localized(), for: .normal)
        buttonReject.titleLabel?.font = .boldSystemFont(ofSize: 15)
        buttonReject.layer.cornerRadius = 8
        containerView.addSubview(buttonReject)
        buttonReject.anchor(left: containerView.leftAnchor, bottom: containerView.bottomAnchor, paddingLeft: 10, paddingBottom: 10, width: (self.view.bounds.width / 2) - 55, height: 50)
        buttonReject.tag = 0
        buttonReject.addTarget(self, action: #selector(rejectApproveForm(_:)), for: .touchUpInside)
        
        let buttonAccept = UIButton()
        buttonAccept.backgroundColor = .systemGreen
        buttonAccept.setImage(UIImage(systemName: "checkmark"), for: .normal)
        buttonAccept.tintColor = .white
        buttonAccept.setTitle("Approve".localized(), for: .normal)
        buttonAccept.titleLabel?.font = .boldSystemFont(ofSize: 15)
        buttonAccept.layer.cornerRadius = 8
        containerView.addSubview(buttonAccept)
        buttonAccept.anchor(bottom: containerView.bottomAnchor, right: containerView.rightAnchor, paddingBottom: 10, paddingRight: 10, width: (self.view.bounds.width / 2) - 55, height: 50)
        buttonAccept.tag = 1
        buttonAccept.addTarget(self, action: #selector(rejectApproveForm(_:)), for: .touchUpInside)
    }
    
    @objc func rejectApproveForm(_ sender: UIButton) {
        let refId = dataMessage["reff_id"] as? String
        let isApprove = sender.tag
        if !CheckConnection.isConnectedToNetwork()  || API.nGetCLXConnState() == 0 {
            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
            imageView.tintColor = .white
            let banner = FloatingNotificationBanner(title: "Check your connection".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
            banner.show()
            return
        }
        DispatchQueue.global().async { [self] in
            let idMe = User.getMyPin()!
            let resp = Nexilis.writeAndWait(message: CoreMessage_TMessageBank.getFormApproval(p_f_pin: idMe, p_ref_id: refId ?? "", p_approve: "\(isApprove)", p_note: "", p_sign: ""))
            if resp != nil {
//                Database.shared.database?.inTransaction({ (fmdb, rollback) in
//                    do {
//                        _ = try Database.shared.insertRecord(fmdb: fmdb, table: "FORM", cvalues: [
//                            "form_id" : refId ?? "",
//                            "name" : "",
//                            "created_date" : "\(Date().currentTimeMillis())",
//                            "created_by" : dataPerson["f_pin"]!!,
//                            "sq_no" : isApprove,
//                        ], replace: true)
//                    } catch {
//                        rollback.pointee = true
//                        //print(error)
//                    }
//                })
                DispatchQueue.main.async {
                    self.view.subviews.forEach({ $0.removeFromSuperview() })
                    self.viewDidLoad()
                }
            } else {
                DispatchQueue.main.async {
                    let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                    imageView.tintColor = .white
                    let banner = FloatingNotificationBanner(title: "Unable to access servers".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                    banner.show()
                }
            }
        }
    }
}
