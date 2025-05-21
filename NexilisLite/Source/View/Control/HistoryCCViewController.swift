//
//  HistoryCCViewController.swift
//  NexilisLite
//
//  Created by Qindi on 24/03/22.
//

import UIKit
import QuickLook

public class HistoryCCViewController: UITableViewController, QLPreviewControllerDataSource {
    
    var data: [[String: Any?]]  = []
    public var isOfficer = false
    
    var previewItem: NSURL?
    
    var fromAPI = false

    public override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Call Center History".localized()
        
        if fromAPI {
            if let navigationBar = navigationController?.navigationBar {
                    let appearance = UINavigationBarAppearance()
                    appearance.configureWithOpaqueBackground() // or `.configureWithTransparentBackground()`
                    navigationBar.standardAppearance = appearance
                    navigationBar.scrollEdgeAppearance = appearance
                    let imageButton = UIImageView(frame: CGRect(x: -16, y: 0, width: 20, height: 44))
                    imageButton.image = UIImage(systemName: "chevron.backward", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .regular, scale: .default))?.withTintColor(.white)
                    imageButton.contentMode = .left
                    let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapExit))
                    imageButton.isUserInteractionEnabled = true
                    imageButton.addGestureRecognizer(tapGestureRecognizer)
                    let leftItem = UIBarButtonItem(customView: imageButton)
                    self.navigationItem.leftBarButtonItem = leftItem
                }
            tableView.contentInsetAdjustmentBehavior = .automatic
        }
        
    }
    
    @objc func didTapExit() {
        self.dismiss(animated: true, completion: nil)
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        getData()
    }
    
    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if data.count == 0 {
            return 1
        }
        return data.count
    }
    
    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if data.count == 0 {
            let cellNoData = UITableViewCell()
            cellNoData.backgroundColor = .clear
            cellNoData.selectionStyle = .none
            let contentData = cellNoData.contentView
            let viewContainer = UIView()
            contentData.addSubview(viewContainer)
            viewContainer.anchor(top: contentData.topAnchor, left: contentData.leftAnchor, bottom: contentData.bottomAnchor, right: contentData.rightAnchor)
            
            let textNoData = UILabel()
            viewContainer.addSubview(textNoData)
            textNoData.anchor(top: viewContainer.topAnchor, left:viewContainer.leftAnchor, right:viewContainer.rightAnchor, paddingTop: 20.0)
            textNoData.textAlignment = .center
            textNoData.text = "No call center history".localized()
            textNoData.font = .systemFont(ofSize: 14)
            return cellNoData
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellHistoryCC", for: indexPath) as! CellMyHistory
        let dataOfficer = getDataProfile(f_pin: data[indexPath.row]["officer"] as? String ?? "")
        let dataRequester = getDataProfile(f_pin: data[indexPath.row]["requester"] as? String ?? "")
        cell.imageOfficer.image = nil
        if dataOfficer.count > 0 {
            if isOfficer {
                cell.labelOfficer.text = dataRequester["name"] ?? ""
            } else {
                cell.labelOfficer.text = "Officer".localized() + " : " + (dataOfficer["name"] ?? "")
            }
            if !(dataOfficer["image"] ?? "").isEmpty || !(dataRequester["image"] ?? "").isEmpty {
                if isOfficer {
                    getImage(name: dataRequester["image"] ?? "", placeholderImage: UIImage(systemName: "person.circle.fill")!, isCircle: true, tableView: tableView, indexPath: indexPath) { result, isDownloaded, image in
                        cell.imageOfficer.image = image
                    }
                } else {
                    getImage(name: dataOfficer["image"] ?? "", placeholderImage: UIImage(systemName: "person.circle.fill")!, isCircle: true, tableView: tableView, indexPath: indexPath) { result, isDownloaded, image in
                        cell.imageOfficer.image = image
                    }
                }
            } else {
                cell.imageOfficer.image = UIImage(systemName: "person.circle.fill")!
                cell.imageOfficer.tintColor = .lightGray
            }
        } else {
            if isOfficer {
                cell.labelOfficer.text = "User"
            } else {
                cell.labelOfficer.text = "Officer".localized() + " : User"
            }
        }
        if isOfficer {
            cell.labelRequester.isHidden = true
        } else {
            if dataRequester.count > 0 {
                cell.labelRequester.text = "Requester".localized() + " : " + dataRequester["name"]!
            } else {
                cell.labelRequester.text = "Requester".localized() + " : User"
            }
        }
        cell.labelComplaintId.text = data[indexPath.row]["complaint_id"] as? String ?? ""
        let stringDate = data[indexPath.row]["date_start"] as? String ?? ""
        let date = Date(milliseconds: Int64(stringDate) ?? 0)
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy HH:mm"
        formatter.locale = NSLocale(localeIdentifier: "id") as Locale?
        cell.labelDate.text = formatter.string(from: date as Date)
        cell.viewContainer.layer.borderWidth = 1
        cell.viewContainer.layer.borderColor = UIColor.whiteBubbleColor.cgColor
        cell.viewContainer.layer.cornerRadius = 10
        cell.viewContainer.clipsToBounds = true
        
        cell.buttonEditor.addTarget(self, action: #selector(buttonClicked(sender:)), for: .touchUpInside)
        cell.buttonEditor.tag = indexPath.row
        
        cell.buttonPDF.addTarget(self, action: #selector(buttonPDFClicked(sender:)), for: .touchUpInside)
        cell.buttonPDF.tag = indexPath.row
        return cell
    }
    
    public override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
    
    func getData() {
        Database.shared.database?.inTransaction({ fmdb, rollback in
            do {
                var data: [[String: Any?]] = []
                if let cursorHistory = Database.shared.getRecords(fmdb: fmdb, query: "SELECT type, f_pin, complaint_id, time, time_end, requester FROM CALL_CENTER_HISTORY order by time desc") {
                    while cursorHistory.next() {
                        var row: [String: Any?] = [:]
                        row["type"] = cursorHistory.string(forColumnIndex: 0)
                        row["officer"] = cursorHistory.string(forColumnIndex: 1)
                        row["complaint_id"] = cursorHistory.string(forColumnIndex: 2)
                        row["date_start"] = cursorHistory.string(forColumnIndex: 3)
                        row["date_end"] = cursorHistory.string(forColumnIndex: 4)
                        row["requester"] = cursorHistory.string(forColumnIndex: 5)
                        data.append(row)
                    }
                    cursorHistory.close()
                }
                self.data = data
            } catch {
                rollback.pointee = true
                print("Access database error: \(error.localizedDescription)")
            }
        })
    }
    
    func getDataProfile(f_pin: String) -> [String: String]{
        var data: [String: String] = [:]
        Database.shared.database?.inTransaction({ fmdb, rollback in
            if let c = Database().getRecords(fmdb: fmdb, query: "select first_name || ' ' || last_name, image_id from BUDDY where f_pin = '\(f_pin)'"), c.next() {
                data["name"] = c.string(forColumnIndex: 0)!.trimmingCharacters(in: .whitespacesAndNewlines)
                data["image"] = c.string(forColumnIndex: 1)!
                c.close()
            }
        })
        return data
    }
    
    @objc func buttonClicked(sender: UIButton) {
        let editorGroupVC = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "editorGroupVC") as! EditorGroup
        editorGroupVC.isHistoryCC = true
        editorGroupVC.complaintId = data[sender.tag]["complaint_id"] as! String
        navigationController?.show(editorGroupVC, sender: nil)
    }
    
    @objc func buttonPDFClicked(sender: UIButton) {
        var dataMessages: [[String: Any?]] = []
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            do {
                let query = "SELECT f_pin, l_pin, message_text, audio_id, video_id, image_id, thumb_id, file_id FROM MESSAGE where call_center_id='\(data[sender.tag]["complaint_id"] as! String)' order by server_date asc"
                if let cursorData = Database.shared.getRecords(fmdb: fmdb, query: query) {
                    while cursorData.next() {
                        var row: [String: Any?] = [:]
                        row["f_pin"] = cursorData.string(forColumnIndex: 0)
                        row["l_pin"] = cursorData.string(forColumnIndex: 1)
                        row["message_text"] = cursorData.string(forColumnIndex: 2)
                        row["audio_id"] = cursorData.string(forColumnIndex: 3)
                        row["video_id"] = cursorData.string(forColumnIndex: 4)
                        row["image_id"] = cursorData.string(forColumnIndex: 5)
                        row["thumb_id"] = cursorData.string(forColumnIndex: 6)
                        row["file_id"] = cursorData.string(forColumnIndex: 7)
                        dataMessages.append(row)
                    }
                    cursorData.close()
                }
            } catch {
                rollback.pointee = true
                print("Access database error: \(error.localizedDescription)")
            }
        })
        let dataOfficer = getDataProfile(f_pin: data[sender.tag]["officer"] as! String)
        let dataRequester = getDataProfile(f_pin: data[sender.tag]["requester"] as! String)
        let stringDate = data[sender.tag]["date_start"] as! String
        let date = Date(milliseconds: Int64(stringDate) ?? 0)
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMMM yyyy"
        let lang: String = SecureUserDefaults.shared.value(forKey: "i18n_language") ?? "en"
        if lang == "id" {
            formatter.locale = NSLocale(localeIdentifier: "id") as Locale?
        }
        var textPDF = """
        <html>
            <head>
                <style>
                h1 {
                  text-align: center;
                }
                .column {
                  float: left;
                  width: 50%;
                }
                .row:after {
                  content: "";
                  display: table;
                  clear: both;
                }
                .customh3 {
                    text-align: right;
                }
                </style>
            </head>
            <body>
                <h1>Call Center History</h1>
                <div class="row">
                  <div class="column">
                    <h3>\(dataOfficer["name"]!) (Officer)</h3>
                    <h3>\(dataRequester["name"]!) (Requester)<h3>
                  </div>
                  <div class="column">
                    <h3 class="customh3">\(formatter.string(from: date as Date))</h3>
                  </div>
                </div>
        """
        for i in 0..<dataMessages.count {
            let name = getDataProfile(f_pin: dataMessages[i]["f_pin"] as! String)["name"]!
            textPDF = textPDF + """
            <p>\(name) : \(dataMessages[i]["message_text"]!!)<p>
            """
        }
        textPDF = textPDF + """
                    </body>
                </html>
        """
        convertToPdfFileAndShare(textMessage: textPDF)
    }
    
    func convertToPdfFileAndShare(textMessage: String){
        
        let fmt = UIMarkupTextPrintFormatter(markupText: textMessage)
        
        // 2. Assign print formatter to UIPrintPageRenderer
        let render = UIPrintPageRenderer()
        render.addPrintFormatter(fmt, startingAtPageAt: 0)
        
        // 3. Assign paperRect and printableRect
        let page = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4, 72 dpi
        render.setValue(page, forKey: "paperRect")
        render.setValue(page, forKey: "printableRect")
        
        // 4. Create PDF context and draw
        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, .zero, nil)
        
        for i in 0..<render.numberOfPages {
            UIGraphicsBeginPDFPage();
            render.drawPage(at: i, in: UIGraphicsGetPDFContextBounds())
        }
        
        UIGraphicsEndPDFContext();
        
        // 5. Save PDF file
        guard let outputURL = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("ContactCenter-\(Date().currentTimeMillis())").appendingPathExtension("pdf")
            else { fatalError("Destination URL not created") }
        
        pdfData.write(to: outputURL, atomically: true)
        //print("open \(outputURL.path)")
        
        if FileManager.default.fileExists(atPath: outputURL.path){
            
            let url = URL(fileURLWithPath: outputURL.path)
            self.previewItem = url as NSURL
            let previewController = QLPreviewController()
            let rightBarButton = UIBarButtonItem()
            previewController.navigationItem.rightBarButtonItem = rightBarButton
            previewController.dataSource = self
            previewController.modalPresentationStyle = .custom
            self.present(previewController, animated: true, completion: nil)
        }
        else {
            //print("document was not found")
        }
        
    }
    
    public func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    
    public func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return self.previewItem!
    }

}

class CellMyHistory: UITableViewCell {
    @IBOutlet weak var viewContainer: UIView!
    @IBOutlet weak var viewTitle: UIView!
    @IBOutlet weak var imageOfficer: UIImageView!
    @IBOutlet weak var labelOfficer: UILabel!
    @IBOutlet weak var labelRequester: UILabel!
    @IBOutlet weak var labelComplaintId: UILabel!
    @IBOutlet weak var labelDate: UILabel!
    @IBOutlet weak var buttonEditor: UIButton!
    @IBOutlet weak var buttonPDF: UIButton!
}
