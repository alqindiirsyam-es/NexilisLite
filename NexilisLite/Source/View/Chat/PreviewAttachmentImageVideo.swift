//
//  PreviewAttachmentImageVideo.swift
//  Qmera
//
//  Created by Akhmad Al Qindi Irsyam on 08/09/21.
//

import UIKit
import AVKit
import AVFoundation
import SDWebImage

protocol PreviewAttachmentImageVideoDelegate : NSObjectProtocol {
    func sendChatFromPreviewImage(message_text: String, attachment_flag: String, image_id: String, video_id: String, thumb_id: String, gif_id: String, viewController: UIViewController, specFile: String)
}

class PreviewAttachmentImageVideo: UIViewController, UIScrollViewDelegate, UITextViewDelegate {
    @IBOutlet var imagePreview: UIImageView!
    @IBOutlet var buttonSend: UIButton!
    @IBOutlet var textFieldSend: UITextView!
    @IBOutlet var buttonCancel: UIButton!
    @IBOutlet weak var buttonSpecFile: UIButton!
    @IBOutlet var constraintViewTextField: NSLayoutConstraint!
    @IBOutlet var heightTextFieldSend: NSLayoutConstraint!
    @IBOutlet var constraintButtonSend: NSLayoutConstraint!
    @IBOutlet var scrollViewImage: UIScrollView!
    @IBOutlet weak var buttonAckConfidential: UIButton!
    @IBOutlet weak var constraintLeftTextField: NSLayoutConstraint!
    @IBOutlet weak var constraintButtonAckCondential: NSLayoutConstraint!
    var imageVideoData: [UIImagePickerController.InfoKey: Any]?
    var image: UIImage?
    var urlVideoPhpPicker: URL?
    var dataGIF: Data?
    var animatedImageView: SDAnimatedImageView!
    var currentTextTextField: String?
    var delegate: PreviewAttachmentImageVideoDelegate?
    var isHiddenTextField = false
    var fromCopy = false
    var isConfidential = false
    var isAck = false
    var isGroup = false
    var isCC = false
    var isGIF = false
    var tableViewConfigFile: UITableView!
    var specFileString = ""
    
    var lastPositionCursorMention = 0
    var lastTextLength = 0
    var tableMention = UITableView()
    var heightTableMention: NSLayoutConstraint!
    var listMentionWithText:[User] = []
    var listMentionInTextField:[User] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if (imageVideoData != nil) {
            if (imageVideoData![.mediaType] as! String == "public.movie") {
                do {
                    let asset = AVURLAsset(url: imageVideoData![.mediaURL] as! URL, options: nil)
                    let imgGenerator = AVAssetImageGenerator(asset: asset)
                    imgGenerator.appliesPreferredTrackTransform = true
                    let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(value: 0, timescale: 1), actualTime: nil)
                    let thumbnail = UIImage(cgImage: cgImage)
                    imagePreview.image = thumbnail
                    let symbolPlay = UIImageView(image: UIImage(systemName: "play.circle.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 50, weight: .bold, scale: .default)))
                    imagePreview.addSubview(symbolPlay)
                    symbolPlay.tintColor = .black.withAlphaComponent(0.5)
                    symbolPlay.translatesAutoresizingMaskIntoConstraints = false
                    symbolPlay.centerXAnchor.constraint(equalTo: imagePreview.centerXAnchor).isActive = true
                    symbolPlay.centerYAnchor.constraint(equalTo: imagePreview.centerYAnchor).isActive = true
                    let objectTap = ObjectGesture(target: self, action: #selector(previewImageVideoTapped(_:)))
                    scrollViewImage.addGestureRecognizer(objectTap)
                    objectTap.videoURL = imageVideoData![.mediaURL] as? NSURL
                } catch let error {
                    //print("*** Error generating thumbnail: \(error.localizedDescription)")
                }
            } else {
                imagePreview.image = imageVideoData![.originalImage] as? UIImage
            }
        } else {
            if urlVideoPhpPicker != nil {
                do {
                    let asset = AVURLAsset(url: urlVideoPhpPicker!, options: nil)
                    let imgGenerator = AVAssetImageGenerator(asset: asset)
                    imgGenerator.appliesPreferredTrackTransform = true
                    let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(value: 0, timescale: 1), actualTime: nil)
                    let thumbnail = UIImage(cgImage: cgImage)
                    imagePreview.image = thumbnail
                    let symbolPlay = UIImageView(image: UIImage(systemName: "play.circle.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 50, weight: .bold, scale: .default)))
                    imagePreview.addSubview(symbolPlay)
                    symbolPlay.tintColor = .black.withAlphaComponent(0.5)
                    symbolPlay.translatesAutoresizingMaskIntoConstraints = false
                    symbolPlay.centerXAnchor.constraint(equalTo: imagePreview.centerXAnchor).isActive = true
                    symbolPlay.centerYAnchor.constraint(equalTo: imagePreview.centerYAnchor).isActive = true
                    let objectTap = ObjectGesture(target: self, action: #selector(previewImageVideoTapped(_:)))
                    scrollViewImage.addGestureRecognizer(objectTap)
                    objectTap.videoURL = urlVideoPhpPicker as? NSURL
                } catch let error {
                    print("*** Error generating thumbnail: \(error.localizedDescription)")
                }
            } else if isGIF {
                animatedImageView = SDAnimatedImageView()
                animatedImageView.contentMode = .scaleAspectFit
                imagePreview.addSubview(animatedImageView)
                animatedImageView.anchor(top: imagePreview.topAnchor, left: imagePreview.leftAnchor, bottom: imagePreview.bottomAnchor, right: imagePreview.rightAnchor)
                if let animatedImage = SDAnimatedImage(data: dataGIF!) {
                    animatedImageView.image = animatedImage
                }
            } else {
                imagePreview.image = image
            }
        }
        
        if ((imageVideoData != nil && imageVideoData![.mediaType] as! String == "public.image") || isHiddenTextField) {
            scrollViewImage.maximumZoomScale = 4
            scrollViewImage.minimumZoomScale = 1
            scrollViewImage.delegate = self
        }
        
        if (isHiddenTextField) {
            textFieldSend.removeFromSuperview()
            buttonSend.removeFromSuperview()
            buttonAckConfidential.removeFromSuperview()
        } else {
            buttonSend.setImage(resizeImage(image: self.traitCollection.userInterfaceStyle == .dark ? UIImage(named: "Send-(White)", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withTintColor(.blackDarkMode) : UIImage(named: "Send-(White)", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, targetSize: CGSize(width: 30, height: 30)).withRenderingMode(.alwaysOriginal), for: .normal)
            
            buttonSend.circle()
            buttonSend.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
            buttonSend.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .mainColor
            if isCC {
                buttonAckConfidential.isHidden = true
                constraintLeftTextField.constant = 20
            } else {
                buttonAckConfidential.circle()
                buttonAckConfidential.addTarget(self, action: #selector(showChooserACKConfidential), for: .touchUpInside)
                let imageConfidential = resizeImage(image: UIImage(named: "confidential_icon", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, targetSize: CGSize(width: 30, height: 30)).withRenderingMode(.alwaysOriginal)
                let imageAck = resizeImage(image: UIImage(named: "ack_icon", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, targetSize: CGSize(width: 30, height: 30)).withRenderingMode(.alwaysOriginal)
                if isAck {
                    buttonAckConfidential.setImage(imageAck, for: .normal)
                } else if isConfidential {
                    buttonAckConfidential.setImage(imageConfidential, for: .normal)
                }
                buttonAckConfidential.tintColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : .white
                buttonAckConfidential.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .mainColor
            }
            
            textFieldSend.layer.cornerRadius = textFieldSend.maxCornerRadius()
            textFieldSend.layer.borderWidth = 1.0
            textFieldSend.backgroundColor = .white
            if (currentTextTextField == "" || currentTextTextField == nil) {
                textFieldSend.text = "Send message".localized()
                textFieldSend.textColor = UIColor.lightGray
            } else {
                textFieldSend.text = currentTextTextField
            }
            textFieldSend.textContainerInset = UIEdgeInsets(top: 12, left: 20, bottom: 12, right: 40)
            textFieldSend.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.5).cgColor
            textFieldSend.tintColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .black
            textFieldSend.font = UIFont.systemFont(ofSize: 12)
            textFieldSend.delegate = self
            textFieldSend.allowsEditingTextAttributes = true
            
            let center: NotificationCenter = NotificationCenter.default
            center.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
            center.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
            
            let dismissKeyboard = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
            dismissKeyboard.cancelsTouchesInView = false
            scrollViewImage.addGestureRecognizer(dismissKeyboard)
        }
        
        buttonCancel.circle()
        buttonCancel.backgroundColor = .secondaryColor.withAlphaComponent(0.4)
        buttonCancel.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        
        buttonSpecFile.circle()
        buttonSpecFile.backgroundColor = .secondaryColor.withAlphaComponent(0.4)
        buttonSpecFile.addTarget(self, action: #selector(showSpecFile), for: .touchUpInside)
        
        if let vc = delegate as? EditorGroup {
            self.listMentionWithText = vc.listMentionWithText
            self.listMentionInTextField = vc.listMentionInTextField
            tableMention = UITableView()
            tableMention.register(UITableViewCell.self, forCellReuseIdentifier: "cellMention")
            tableMention.dataSource = self
            tableMention.delegate = self
            tableMention.contentInset = UIEdgeInsets(top: -25, left: 0, bottom: 0, right: 0)
            tableMention.backgroundColor = .white
            self.view.addSubview(tableMention)
            tableMention.anchor(left: view.leftAnchor, bottom: textFieldSend.topAnchor, right: view.rightAnchor)
            heightTableMention = tableMention.heightAnchor.constraint(equalToConstant: 0)
            self.heightTableMention.isActive = true
        }
        lastTextLength = textFieldSend.text.count
    }
    
    @objc func showChooserACKConfidential() {
        let alertController = LibAlertController(title: "Message Mode".localized(), message: "Select".localized() + " " + "Message Mode".localized(), preferredStyle: .actionSheet)
        let imageConfidential = resizeImage(image: UIImage(named: "confidential_icon", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, targetSize: CGSize(width: 30, height: 30)).withRenderingMode(.alwaysOriginal)
        let confidentialAction = UIAlertAction(title: "Confidential Message".localized(), style: .default, handler: { (UIAlertAction) in
            if !self.isConfidential {
                self.isConfidential = true
                self.buttonAckConfidential.setImage(imageConfidential, for: .normal)
            }
            if self.isAck {
                self.isAck = false
            }
            self.setPreviousVariableMessageMode()
        })
        confidentialAction.setValue(imageConfidential, forKey: "image")
        alertController.addAction(confidentialAction)
        let imageAck = resizeImage(image: UIImage(named: "ack_icon", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, targetSize: CGSize(width: 30, height: 30)).withRenderingMode(.alwaysOriginal)
        let ackAction = UIAlertAction(title: "Confirmation Message".localized(), style: .default, handler: { (UIAlertAction) in
            if !self.isAck {
                self.isAck = true
                self.buttonAckConfidential.setImage(imageAck, for: .normal)
            }
            if self.isConfidential {
                self.isConfidential = false
            }
            self.setPreviousVariableMessageMode()
        })
        ackAction.setValue(imageAck, forKey: "image")
        alertController.addAction(ackAction)
        alertController.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: { (UIAlertAction) in
            self.isConfidential = false
            self.isAck = false
            self.buttonAckConfidential.setImage(UIImage(systemName: "gearshape.fill", withConfiguration: UIImage.SymbolConfiguration(scale: .large))?.withTintColor(.white).withRenderingMode(.alwaysTemplate), for: .normal)
            self.setPreviousVariableMessageMode()
        }))
        self.present(alertController, animated: true, completion: nil)
    }
    
    func setPreviousVariableMessageMode() {
        let vc = delegate
        if vc is EditorPersonal {
            let editorVc = vc as! EditorPersonal
            editorVc.setAckConfidential(isAck: self.isAck, isConfidential: self.isConfidential)
        } else if vc is EditorGroup {
            let editorVc = vc as! EditorGroup
            editorVc.setAckConfidential(isAck: self.isAck, isConfidential: self.isConfidential)
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        //indention code:
        let text = textView.text ?? ""
        let cursorPosition = textView.selectedRange.location
        
        let tempListMention = listMentionInTextField
        if listMentionInTextField.count > 0 {
            for j in 0..<listMentionInTextField.count {
                var index = j
                if tempListMention.count != listMentionInTextField.count {
                    index = j - (tempListMention.count - listMentionInTextField.count)
                }
                var upper = (Int(listMentionInTextField[index].ex_block ?? "0") ?? 0)
                if cursorPosition <= upper {
                    upper += text.count - lastTextLength
                    listMentionInTextField[index].ex_block = "\(upper)"
                }
                let lower = upper - listMentionInTextField[index].fullName.count
                let name = listMentionInTextField[index].fullName.trimmingCharacters(in: .whitespaces)
                if textView.text.substring(from: lower, to: upper) != "@\(name)" {
                    listMentionInTextField.remove(at: index)
                }
            }
        }
        
        // Handle Bullets (- [space] + letter → • )
        let bulletPattern = #"(?<=\n|^)- (\S)"#
        if let match = text.range(of: bulletPattern, options: .regularExpression) {
            let matchedText = text[match]

            if let spaceIndex = matchedText.firstIndex(of: " ") {
                let firstLetter = matchedText[matchedText.index(after: spaceIndex)...]
                let replacedText = text.replacingOccurrences(of: matchedText, with: "  • \(firstLetter)", range: match)

                let newCursorPosition = cursorPosition + 2  // Adjust cursor position
                textView.text = replacedText
                textView.selectedRange = NSRange(location: newCursorPosition, length: 0)
            }
        }

        // Handle Numbered Lists (e.g., "1. " [space] + letter → " 1.")
        let numberPattern = #"(?<=\n|^)(\d+)\. (\S)"# // Matches "1. X"
        if let match = text.range(of: numberPattern, options: .regularExpression) {
            let matchedText = text[match]

            if let spaceIndex = matchedText.firstIndex(of: " ") {
                let firstLetter = matchedText[matchedText.index(after: spaceIndex)...]
                let replacedText = text.replacingOccurrences(of: matchedText, with: "  \(matchedText)", range: match)

                let newCursorPosition = cursorPosition + 2  // Adjust cursor
                textView.text = replacedText
                textView.selectedRange = NSRange(location: newCursorPosition, length: 0)
            }
        }

        handleRichText(textView)
        lastTextLength = text.count
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.lightGray {
            textView.text = nil
            textView.textColor = UIColor.black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Send message".localized()
            textView.textColor = UIColor.lightGray
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text.isEmpty {
            if let vc = delegate as? EditorGroup {
                if listMentionInTextField.count > 0 {
                    for i in 0..<listMentionInTextField.count {
                        if lastPositionCursorMention == Int(listMentionInTextField[i].ex_block!)! + 1 {
                            let fulltextForMention = textView.text.substring(from: 0, to: lastPositionCursorMention - 1)
                            let diff = textView.text.count - fulltextForMention.count
                            var text = textView.text ?? ""
                            let nameMention = listMentionInTextField[i].fullName.trimmingCharacters(in: .whitespaces)
                            let rangeReplacement = NSRange(location: lastPositionCursorMention - nameMention.count - 1, length: nameMention.count + 1)
                            let replacementText = ""
                            
                            let copyAttributedText = text.richText(isEditing: true, group_id: vc.dataGroup["group_id"]  as? String ?? "", listMentionInTextField: listMentionInTextField)
                            copyAttributedText.removeAttribute(.foregroundColor, range: rangeReplacement)
                            
                            textView.attributedText = copyAttributedText

                            // Replace the old text with the new text using the replaceSubrange(_:with:) method
                            if let startIndex = text.index(text.startIndex, offsetBy: rangeReplacement.location, limitedBy: text.endIndex),
                               let endIndex = text.index(startIndex, offsetBy: rangeReplacement.length, limitedBy: text.endIndex) {
                                text.replaceSubrange(startIndex..<endIndex, with: replacementText)
                            }
                            listMentionInTextField.remove(at: i)
                            
                            textView.attributedText = text.richText(isEditing: true, group_id: vc.dataGroup["group_id"]  as? String ?? "", listMentionInTextField: listMentionInTextField)
                            
                            let newPosition = textView.position(from: textView.beginningOfDocument, offset: textView.text.count - diff)
                            textView.selectedTextRange = textView.textRange(from: newPosition!, to: newPosition!)
                            textViewDidChangeSelection(textView)
                            handleRichText(textView)
                            return false
                        }
                    }
                }
            }
        }
        let indent = handleIndent(textView, range, text)
        if !indent {
            textViewDidChangeSelection(textView)
            handleRichText(textView)
            return indent
        }
        if (textView.text.count == 0) {
            return text != "\n"
        }
        return true
    }
    
    private func handleIndent(_ textView: UITextView, _ range: NSRange, _ text: String) -> Bool {
        guard let nsText = textView.text as NSString? else { return true }
        let newText = nsText.replacingCharacters(in: range, with: text)
        var lines = newText.components(separatedBy: "\n")
        
        // Ensure range location is valid, considering Unicode scalars
        guard let textRange = Range(range, in: textView.text) else { return true }
        let prefixText = textView.text[..<textRange.lowerBound]
        let affectedLineIndex = prefixText.components(separatedBy: "\n").count - 1
        guard affectedLineIndex >= 0, affectedLineIndex < lines.count else { return true }
        
        let affectedLine = lines[affectedLineIndex]
        
        // Prevent deleting two-space indentation before bullet/number
        if affectedLine.hasPrefix("  •") || affectedLine.range(of: #"^\s{2}\d+\."#, options: .regularExpression) != nil {
            if let lineStart = textView.text.range(of: affectedLine)?.lowerBound,
               let startIndex = textView.text.distance(of: lineStart) {
                if range.location == startIndex || range.location == startIndex + 1 {
                    return false
                }
            }
        }
        
        // Auto-indent new lines based on previous line
        if text == "\n" {
            let previousLine = lines[affectedLineIndex]
            
            if previousLine.hasPrefix("  •") {
                let newBullet = "\n  • "
                textView.text = nsText.replacingCharacters(in: range, with: newBullet)
                textView.selectedRange = NSRange(location: range.location + newBullet.utf16.count, length: 0)
                return false
            }
            
            if let match = previousLine.range(of: #"^\s{2}(\d+)\."#, options: .regularExpression),
               let numberMatch = previousLine[match].components(separatedBy: ".").first,
               let number = Int(numberMatch.trimmingCharacters(in: .whitespaces)) {
                
                let newNumber = "\n  \(number + 1). "
                textView.text = nsText.replacingCharacters(in: range, with: newNumber)
                textView.selectedRange = NSRange(location: range.location + newNumber.utf16.count, length: 0)
                return false
            }
        }
        
        // Handle Backspace on Empty Bullet (Convert "  • " → "- ")
        if text.isEmpty && affectedLine.trimmingCharacters(in: .whitespaces) == "•" {
            lines[affectedLineIndex] = "- "  // Replace "  • " with "- "
            textView.text = lines.joined(separator: "\n")
            textView.selectedRange = NSRange(location: range.location - 1, length: 0)
            return false
        }
        
        // Handle Backspace on Numbered List
        if text.isEmpty, affectedLine.range(of: #"^\s{2}(\d+)\.$"#, options: .regularExpression) != nil {
            lines[affectedLineIndex] = affectedLine.trimmingCharacters(in: .whitespaces)
            textView.text = lines.joined(separator: "\n")
            textView.selectedRange = NSRange(location: range.location - 1, length: 0)
            return false
        }
        return true
    }
    
    private func handleRichText(_ textView: UITextView) {
        if let vc = delegate as? EditorGroup {
            textView.preserveCursorPosition(withChanges: { _ in
                textView.attributedText = textView.text.richText(isEditing: true, group_id: vc.dataGroup["group_id"]  as? String ?? "", listMentionInTextField: self.listMentionInTextField)
                return .preserveCursor
            })
        } else {
            textView.preserveCursorPosition(withChanges: { _ in
                textView.attributedText = textView.text.richText(isEditing: true)
                return .preserveCursor
            })
        }
    }
    
    func textViewDidChangeSelection(_ textView: UITextView) {
        if let vc = delegate as? EditorGroup {
            lastPositionCursorMention = textView.selectedRange.location
            var isShowMention = false

            let fulltextForMention = textView.text.prefix(lastPositionCursorMention)
            
            let lines = fulltextForMention.split(separator: "\n")
            if let lastLineIndex = lines.lastIndex(where: { !$0.isEmpty }) {
                let words = lines[lastLineIndex].split(separator: " ")
                if let lastWordIndex = words.lastIndex(where: { !$0.isEmpty }) {
                    let mentionText = words[lastWordIndex]
                    let lastChar = fulltextForMention.last
                    if lastChar != "\n" && lastChar != " " {
                        if mentionText.starts(with: "@") || (mentionText.count >= 2 && (self.textFieldSend.textColor != UIColor.lightGray) && extractFromAtIfSymbolsBefore(String(mentionText)) == nil) {
                            showMention(text: mentionText.starts(with: "@") ? String(mentionText.dropFirst()) : String(mentionText))
                            isShowMention = true
                        } else if let textM = extractFromAtIfSymbolsBefore(String(mentionText)) {
                            showMention(text: String(textM.dropFirst()))
                            isShowMention = true
                        }
                    }
                }
            }
            
            if !isShowMention {
                hideMention()
            }
        }
        if var nowTextFieldSend = self.textFieldSend {
            if let sr = nowTextFieldSend.selectedTextRange {
                if let fnt = nowTextFieldSend.font {
                    let cursorPosition = textView.caretRect(for: sr.start).origin
                    let doubleCurrentLine = cursorPosition.y / fnt.lineHeight
                    if doubleCurrentLine.isFinite {
                        let currentLine = Int(ceil(doubleCurrentLine))
                        UIView.animate(withDuration: 0.3) {
                            let layoutManager = textView.layoutManager
                            var numberOfLines = 0
                            var index = 0
                            let numberOfGlyphs = layoutManager.numberOfGlyphs

                            while index < numberOfGlyphs {
                                var lineRange = NSRange()
                                layoutManager.lineFragmentRect(forGlyphAt: index, effectiveRange: &lineRange)
                                index = NSMaxRange(lineRange)
                                numberOfLines += 1
                            }
                            if currentLine == 1 && (numberOfLines == 1 || numberOfLines == 0) {
                                self.heightTextFieldSend.constant = 40
                            } else if (self.heightTextFieldSend.constant < 95.0 || (self.constraintViewTextField != nil && self.constraintViewTextField.constant < 95.0)) && currentLine >= 4 {
                                self.heightTextFieldSend.constant = 95.0
                            } else if currentLine < 4 && numberOfLines < 5 {
                                if (nowTextFieldSend.text.count > 0 && self.heightTextFieldSend.constant != nowTextFieldSend.contentSize.height) {
                                    self.heightTextFieldSend.constant = nowTextFieldSend.contentSize.height
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func extractFromAtIfSymbolsBefore(_ text: String) -> String? {
        guard let atIndex = text.firstIndex(of: "@") else {
            return nil
        }
        
        let beforeAt = text[..<atIndex]
        let afterAt = text[atIndex...]

        // Define symbols as anything that's not a letter or digit
        let symbolSet = CharacterSet.letters.union(.decimalDigits).inverted
        let isAllSymbols = beforeAt.unicodeScalars.allSatisfy { symbolSet.contains($0) }

        return isAllSymbols ? String(afterAt) : nil
    }
    
    private func showMention(text: String) {
        listMentionWithText.removeAll()
        Database.shared.database?.inTransaction({ fmdb, rollback in
            let vc = delegate as! EditorGroup
            do {
                let idMe = User.getMyPin()!
                if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "SELECT f_pin, first_name || ' ' || ifnull(last_name, '') name FROM GROUPZ_MEMBER where group_id='\(vc.dataGroup["group_id"]  as? String ?? "")' AND f_pin <> '\(idMe)' AND name LIKE '%\(text)%'") {
                    while cursor.next() {
                        let user = User(pin: "")
                        user.pin = cursor.string(forColumnIndex: 0) ?? ""
                        user.firstName = cursor.string(forColumnIndex: 1) ?? ""
                        if !user.pin.isEmpty {
                            let userFromBuddy = User.getDataCanNil(pin: user.pin, fmdb: fmdb)
                            if userFromBuddy != nil {
                                listMentionWithText.append(userFromBuddy!)
                            } else {
                                listMentionWithText.append(user)
                            }
                        }
                    }
                    cursor.close()
                }
                listMentionWithText.removeAll(where: { listMentionInTextField.contains($0) })
                let nowTableMention = tableMention
                let nowHeightTableMention = heightTableMention!
                if listMentionWithText.count > 0 {
                    if listMentionWithText.count < 5 {
                        nowHeightTableMention.constant = CGFloat(44 * listMentionWithText.count)
                    } else {
                        nowHeightTableMention.constant = 44 * 4
                    }
                    nowTableMention.reloadData()
                } else {
                    nowHeightTableMention.constant = 44
                    self.hideMention()
                }
            } catch {
                rollback.pointee = true
                print("Access database error: \(error.localizedDescription)")
            }
        })
    }
    
    private func hideMention() {
        if self.heightTableMention != nil && self.heightTableMention.constant != 0 {
            listMentionWithText.removeAll()
            tableMention.reloadData()
            self.heightTableMention.constant = 0
        }
    }
    
    @objc func previewImageVideoTapped(_ sender: ObjectGesture) {
        let player = AVPlayer(url: sender.videoURL! as URL)
        let playerVC = AVPlayerViewController()
        playerVC.player = player
        playerVC.modalPresentationStyle = .custom
        self.present(playerVC, animated: true, completion: nil)
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imagePreview
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        if scrollViewImage.zoomScale > 1 {
            if let image = imagePreview.image {
                let ratioW = imagePreview.frame.width / image.size.width
                let ratioH = imagePreview.frame.height / image.size.height
                
                let ratio = ratioW < ratioH ? ratioW : ratioH
                let newWidth = image.size.width * ratio
                let newHeight = image.size.height * ratio
                
                let conditionLeft = newWidth*scrollViewImage.zoomScale > imagePreview.frame.width
                
                let left = 0.5 * (conditionLeft ? newWidth - imagePreview.frame.width : (scrollViewImage.frame.width - scrollViewImage.contentSize.width))
                
                let conditionTop = newHeight*scrollViewImage.zoomScale > imagePreview.frame.height
                
                let top = 0.01 * (conditionTop ? newHeight - imagePreview.frame.width : (scrollViewImage.frame.height - scrollViewImage.contentSize.height))
                
                scrollViewImage.contentInset = UIEdgeInsets(top: top, left: left, bottom: top, right: left)
            }
        } else {
            scrollViewImage.contentInset = .zero
        }
    }
    
    @objc func dismissKeyboard() {
        textFieldSend.resignFirstResponder() // dismiss keyoard
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        let info:NSDictionary = notification.userInfo! as NSDictionary
        let keyboardSize = (info[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        
        let keyboardHeight: CGFloat = keyboardSize.height
        
        let _: CGFloat = info[UIResponder.keyboardAnimationDurationUserInfoKey] as! NSNumber as! CGFloat
        
        UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseInOut, animations: {
            self.constraintViewTextField.constant = keyboardHeight + 10
            self.constraintButtonSend.constant = keyboardHeight + 10
            self.constraintButtonAckCondential.constant = keyboardHeight + 10
        }, completion: nil)
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseInOut, animations: {
            self.constraintViewTextField.constant = 20
            self.constraintButtonSend.constant = 20
            self.constraintButtonAckCondential.constant = 20
        }, completion: nil)
        
    }
    
    @objc func sendTapped() {
        if (image != nil) || (imageVideoData != nil && imageVideoData![.mediaType] as! String == "public.image") {
            Nexilis.showLoader()
            DispatchQueue.global().async { [self] in
                var originalImageName = ""
                if (fromCopy) {
                    originalImageName = "\(Date().currentTimeMillis())"
                } else if (imageVideoData![.imageURL] == nil) {
                    originalImageName = "takeImage_\(Date().currentTimeMillis())"
                } else {
                    let urlImage = (imageVideoData![.imageURL] as! NSURL).absoluteString
                    originalImageName = (urlImage! as NSString).lastPathComponent
                }
                let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                let compressedImageName = "Nexilis_image_\(Date().currentTimeMillis())_\(originalImageName.components(separatedBy: ".")[0]).jpeg"
                let thumbName = "THUMB_Nexilis_image_\(Date().currentTimeMillis())_\(originalImageName.components(separatedBy: ".")[0]).jpeg"
                let fileURL = documentsDirectory.appendingPathComponent(compressedImageName)
                var compressedImage:Data!
                if (image != nil) {
                    compressedImage = image!.jpeg ?? Data()
                } else {
                    compressedImage = (imageVideoData![.originalImage] as! UIImage).jpeg ?? Data()
                }
                if Nexilis.checkingAccess(key: "message_guard") {
                    let guardLite = MessageGuardLite(limits: .defaults())
                    let res = guardLite.sanitizeImage(compressedImage)
                    if res.verdict != .block {
                        compressedImage = res.data ?? Data()
                    } else {
                        DispatchQueue.main.async {
                            Nexilis.hideLoader {}
                        }
                        APIS.showMessageGuardFile(mime: res.mime)
                        return
                    }
                }
                if let compressed = compressImageLikeWhatsApp(UIImage(data: compressedImage) ?? UIImage()) {
                    compressedImage = compressed
                }
                if let data = compressedImage,
                   !FileManager.default.fileExists(atPath: fileURL.path) {
                    do {
                        try data.write(to: fileURL)
                        //print("file saved")
                    } catch {
                        //print("error saving file:", error)
                    }
                }
                let thumbImage = UIImage(data: compressedImage!)
                let fileURLTHUMB = documentsDirectory.appendingPathComponent(thumbName)
                if let dataThumb = thumbImage!.jpegData(compressionQuality:  0.25),
                   !FileManager.default.fileExists(atPath: fileURLTHUMB.path) {
                    do {
                        try dataThumb.write(to: fileURLTHUMB)
                        //print("thumb saved")
                    } catch {
                        //print("error saving file:", error)
                    }
                }
                DispatchQueue.main.async {
                    Nexilis.hideLoader { [self] in
                        self.dismiss(animated: true, completion: nil)
                        if (textFieldSend.text!.trimmingCharacters(in: .whitespacesAndNewlines) == "Send message".localized() && textFieldSend.textColor == UIColor.lightGray) {
                            delegate!.sendChatFromPreviewImage(message_text: "", attachment_flag: "1", image_id: compressedImageName, video_id: "", thumb_id: thumbName, gif_id: "", viewController: self, specFile: specFileString)
                        } else {
                            delegate!.sendChatFromPreviewImage(message_text: textFieldSend.text!, attachment_flag: "1", image_id: compressedImageName, video_id: "", thumb_id: thumbName, gif_id: "", viewController: self, specFile: specFileString)
                        }
                    }
                }
            }
        } else {
            Nexilis.showLoader(text: "Compressing...".localized())
            DispatchQueue.global().async { [self] in
                var dataVideo: Data?
                if imageVideoData != nil || urlVideoPhpPicker != nil {
                    if imageVideoData != nil {
                        dataVideo = try? Data(contentsOf: imageVideoData![.mediaURL] as! URL)
                    } else {
                        dataVideo = try? Data(contentsOf: urlVideoPhpPicker!)
                    }
                }
                if dataGIF == nil {
                    Nexilis.dispatch = DispatchGroup()
                    Nexilis.dispatch?.enter()
                    let compressedURL = NSURL.fileURL(withPath: NSTemporaryDirectory() + UUID().uuidString + ".mp4")
                    compressVideo(inputURL: (imageVideoData != nil ? imageVideoData![.mediaURL] as? URL : urlVideoPhpPicker)!,
                                  outputURL: compressedURL) { exportSession in
                        guard let session = exportSession else {
                            if let dispatch = Nexilis.dispatch {
                                dispatch.leave()
                            }
                            return
                        }
                        
                        if session.status == .completed {
                            guard let compressedData = try? Data(contentsOf: compressedURL) else {
                                return
                            }
                            dataVideo = compressedData
                            if let dispatch = Nexilis.dispatch {
                                dispatch.leave()
                            }
                        }
                    }
                    Nexilis.dispatch?.wait()
                    Nexilis.dispatch = nil
                }
                DispatchQueue.main.async {
                    Nexilis.hideLoader { [self] in
                        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                        var urlVideo = ""
                        var originalVideoName = ""
                        var renamedVideoName = ""
                        var thumbName = ""
                        if (fromCopy && dataGIF != nil) {
                            originalVideoName = "\(Date().currentTimeMillis())_copyGif"
                            renamedVideoName = "Nexilis_gif_\(Date().currentTimeMillis())_\(originalVideoName)"
                            thumbName = "THUMB_Nexilis_gif_\(Date().currentTimeMillis())_\(originalVideoName.components(separatedBy: ".")[0]).jpeg"
                        } else {
                            if imageVideoData != nil {
                                urlVideo = (imageVideoData![.mediaURL] as! NSURL).absoluteString!
                            } else {
                                urlVideo = (urlVideoPhpPicker! as NSURL).absoluteString!
                            }
                            originalVideoName = (urlVideo as NSString).lastPathComponent
                            renamedVideoName = "Nexilis_video_\(Date().currentTimeMillis())_\(originalVideoName.components(separatedBy: ".")[0]).mp4"
                            thumbName = "THUMB_Nexilis_video_\(Date().currentTimeMillis())_\(originalVideoName.components(separatedBy: ".")[0]).jpeg"
                        }
                        let fileURL = documentsDirectory.appendingPathComponent(renamedVideoName)
                        if !FileManager.default.fileExists(atPath: fileURL.path) {
                            do {
                                if let dataVideo = dataVideo {
                                    try dataVideo.write(to: fileURL)
                                } else if let dataGIF = dataGIF {
                                    try dataGIF.write(to: fileURL)
                                }
                                //print("file saved")
                            } catch {
                                //print("error saving file:", error)
                            }
                        }
                        var dataThumbVideo: Data?
                        if !fromCopy {
                            dataThumbVideo = imagePreview.image!.jpegData(compressionQuality:  0.5)
                        }
                        let fileURLTHUMB = documentsDirectory.appendingPathComponent(thumbName)
                        if !FileManager.default.fileExists(atPath: fileURLTHUMB.path) {
                            do {
                                if let dataThumbVideo = dataThumbVideo {
                                    try dataThumbVideo.write(to: fileURLTHUMB)
                                } else {
                                    if let dataGIF = dataGIF {
                                        if let dataThumbGif = UIImage(data: dataGIF) {
                                            if let compressedDataThumbGif = dataThumbGif.jpegData(compressionQuality: 0.5) {
                                                try compressedDataThumbGif.write(to: fileURLTHUMB)
                                            }
                                        }
                                    }
                                }
                                //print("thumb saved")
                            } catch {
                                //print("error saving file:", error)
                            }
                        }
                        self.dismiss(animated: true, completion: nil)
                        if (textFieldSend.text!.trimmingCharacters(in: .whitespacesAndNewlines) == "Send message".localized() && textFieldSend.textColor == UIColor.lightGray) {
                            delegate!.sendChatFromPreviewImage(message_text: "", attachment_flag: "2", image_id: "", video_id: renamedVideoName, thumb_id: thumbName, gif_id: dataGIF != nil ? renamedVideoName : "", viewController: self, specFile: specFileString)
                        } else {
                            delegate!.sendChatFromPreviewImage(message_text: textFieldSend.text!, attachment_flag: "2", image_id: "", video_id: renamedVideoName, thumb_id: thumbName, gif_id: dataGIF != nil ? renamedVideoName : "", viewController: self, specFile: specFileString)
                        }
                    }
                }
            }
        }
    }
    
    func compressVideo(inputURL: URL,
                       outputURL: URL,
                       handler:@escaping (_ exportSession: AVAssetExportSession?) -> Void) {
        let urlAsset = AVURLAsset(url: inputURL, options: nil)
        guard let exportSession = AVAssetExportSession(asset: urlAsset,
                                                       presetName: AVAssetExportPresetHighestQuality) else {
            handler(nil)
            
            return
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true
        exportSession.exportAsynchronously {
            handler(exportSession)
        }
    }
    
    func compressImageLikeWhatsApp(_ image: UIImage, maxFileSizeMB: Double = 1.0, maxDimension: CGFloat = 1280) -> Data? {
        let resizedImage = resizeImage(image: image, maxDimension: maxDimension)
        var compressedData = resizedImage.jpegData(compressionQuality: 0.7) ?? Data()
        var imageSizeMB = Double(compressedData.count) / (1024.0 * 1024.0)
        
        while imageSizeMB > maxFileSizeMB {
            guard let tempImage = UIImage(data: compressedData) else { break }
            compressedData = tempImage.jpegData(compressionQuality: 0.5) ?? compressedData
            imageSizeMB = Double(compressedData.count) / (1024.0 * 1024.0)
//            print("Compressed to: \(imageSizeMB) MB")
        }
        
        return compressedData
    }

    func resizeImage(image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let aspectRatio = size.width / size.height
        
        var newSize: CGSize
        if aspectRatio > 1 {
            newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else {
            newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        }

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    @objc func cancelTapped() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func showSpecFile() {
        let modalVC = UIViewController()
        if let viewModal = modalVC.view {
            viewModal.backgroundColor = .whiteBubbleColor
            
            let closeButton = UIButton(type: .close)
            viewModal.addSubview(closeButton)
            closeButton.anchor(top: viewModal.topAnchor, right: viewModal.rightAnchor, paddingTop: 15, paddingRight: 15, width: 30, height: 30)
            closeButton.layer.cornerRadius = 15
            closeButton.clipsToBounds = true
            closeButton.backgroundColor = .lightGray.withAlphaComponent(0.1)
            let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
            closeButton.setImage(UIImage(systemName: "xmark", withConfiguration: config), for: .normal)
            closeButton.addAction(UIAction { _ in
                modalVC.dismiss(animated: true)
            }, for: .touchUpInside)
            
            let imageSpec = UIButton(type: .custom)
            viewModal.addSubview(imageSpec)
            imageSpec.anchor(top: viewModal.topAnchor, left: viewModal.leftAnchor, paddingTop: 25, paddingLeft: 15, width: 40, height: 40)
            imageSpec.layer.cornerRadius = 20
            imageSpec.clipsToBounds = true
            imageSpec.backgroundColor = .lightGray.withAlphaComponent(0.1)
            imageSpec.setImage(UIImage(named: "pb_ic_attach_spc", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withRenderingMode(.alwaysOriginal).resize(target: CGSize(width: 35, height: 35)), for: .normal)
            
            let title = UILabel()
            title.text = "Option for Attachment".localized()
            viewModal.addSubview(title)
            title.anchor(top: viewModal.topAnchor, left: imageSpec.rightAnchor, paddingTop: 23, paddingLeft: 10)
            title.textColor = .label
            title.font = .boldSystemFont(ofSize: 16)
            
            let subtitle = UILabel()
            subtitle.text = "Select option :".localized()
            viewModal.addSubview(subtitle)
            subtitle.anchor(top: title.bottomAnchor, left: imageSpec.rightAnchor, paddingLeft: 10)
            subtitle.textColor = .gray
            subtitle.font = .systemFont(ofSize: 14)
            
            tableViewConfigFile = UITableView()
            viewModal.addSubview(tableViewConfigFile)
            tableViewConfigFile.backgroundColor = .white
            tableViewConfigFile.layer.cornerRadius = 8.0
            tableViewConfigFile.clipsToBounds = true
            tableViewConfigFile.anchor(top: imageSpec.bottomAnchor, left: viewModal.leftAnchor, bottom: viewModal.bottomAnchor, right: viewModal.rightAnchor, paddingTop: 15, paddingLeft: 15, paddingBottom: 80, paddingRight: 15)
            tableViewConfigFile.register(UITableViewCell.self, forCellReuseIdentifier: "cellConfigFile")
            tableViewConfigFile.dataSource = self
            tableViewConfigFile.delegate = self
            tableViewConfigFile.separatorStyle = .singleLine
            tableViewConfigFile.tableFooterView = UIView()
            if #available(iOS 15.0, *) {
                tableViewConfigFile.sectionHeaderTopPadding = 0
            }
            
            if #available(iOS 15.0, *) {
                if let sheet = modalVC.sheetPresentationController {
                    sheet.detents = [.medium()]
                }
            } else {
                // Fallback on earlier versions
            }
        }
        UIApplication.shared.visibleViewController?.present(modalVC, animated: true)
    }
}

extension PreviewAttachmentImageVideo: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == tableViewConfigFile {
            return 2
        }
        return listMentionWithText.count
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if tableView == tableMention, let vc = delegate as? EditorGroup {
            tableView.deselectRow(at: indexPath, animated: true)
            let nowTextField = textFieldSend!
            let fulltextForMention = nowTextField.text.substring(from: 0, to: lastPositionCursorMention - 1)
            let diff = nowTextField.text.count - fulltextForMention.count
            let lines = fulltextForMention.split(separator: "\n")
            if let lastLineIndex = lines.lastIndex(where: { !$0.isEmpty }) {
                let words = lines[lastLineIndex].split(separator: " ")
                if let lastWordIndex = words.lastIndex(where: { !$0.isEmpty }) {
                    var lastWord = words[lastWordIndex]
                    if let textM = extractFromAtIfSymbolsBefore(String(lastWord)) {
                        lastWord = textM[textM.startIndex..<textM.endIndex]
                    }
                    if let rangeLastWord = fulltextForMention.range(of: lastWord, options: .backwards) {
                        listMentionInTextField.append(listMentionWithText[indexPath.row])
                        
                        var addSpaceAfterReplacement = ""
                        if diff == 0 {
                            addSpaceAfterReplacement = " "
                        }
                        
                        var text = nowTextField.text ?? ""
                        let nameMention = listMentionWithText[indexPath.row].fullName.trimmingCharacters(in: .whitespaces)
                        listMentionInTextField.last?.ex_block = "\(fulltextForMention.distance(from: fulltextForMention.startIndex, to: rangeLastWord.lowerBound) + nameMention.count)" //upperbound
                        let replacementText = "@\(nameMention)"
                        
                        // Replace the old text with the new text using the replaceSubrange(_:with:) method
                        text.replaceSubrange(rangeLastWord, with: replacementText + addSpaceAfterReplacement)
                        
                        nowTextField.attributedText = text.richText(isEditing: true, group_id: vc.dataGroup["group_id"]  as? String ?? "", listMentionInTextField: listMentionInTextField)
                        
                        let newPosition = nowTextField.position(from: nowTextField.beginningOfDocument, offset: nowTextField.text.count - diff)
                        nowTextField.selectedTextRange = nowTextField.textRange(from: newPosition!, to: newPosition!)
                        
                        hideMention()
                        lastTextLength = nowTextField.text.count
                        return
                    }
                }
            }
        }
        var type = ""
        if indexPath.row == 0 {
            type = "share,download"
        } else {
            type = "forward"
        }
        if !specFileString.contains(type) {
            if !specFileString.isEmpty {
                specFileString += ","
            }
            specFileString += type
        } else {
            specFileString = specFileString.replacingOccurrences(of: type, with: "")
            if specFileString == "," {
                specFileString = ""
            }
        }
        if specFileString.isEmpty {
            buttonSpecFile.setImage(UIImage(named: "pb_ic_attach_spc_off", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withRenderingMode(.alwaysOriginal).resize(target: CGSize(width: 40, height: 40)), for: .normal)
        } else {
            buttonSpecFile.setImage(UIImage(named: "pb_ic_attach_spc", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withRenderingMode(.alwaysOriginal).resize(target: CGSize(width: 40, height: 40)), for: .normal)
        }
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == tableMention {
            let cellMention = tableView.dequeueReusableCell(withIdentifier: tableView == tableMention ? "cellMention" : "cellEditMention", for: indexPath as IndexPath)
            var content = cellMention.defaultContentConfiguration()
            content.textProperties.font = UIFont.systemFont(ofSize: 11 + offset())
            content.imageProperties.tintColor = .black
            content.imageProperties.maximumSize = CGSize(width: 24, height: 24)
            if indexPath.row < listMentionWithText.count {
                getImage(name: listMentionWithText[indexPath.row].thumb, placeholderImage: UIImage(systemName: "person"), isCircle: true, tableView: tableView, indexPath: indexPath, completion: { result, isDownloaded, image in
                    content.image = image
                })
                content.text = listMentionWithText[indexPath.row].firstName + " " + listMentionWithText[indexPath.row].lastName
            }
            cellMention.contentConfiguration = content
            return cellMention
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellConfigFile", for: indexPath as IndexPath)
        var content = cell.defaultContentConfiguration()
        content.textProperties.font = .systemFont(ofSize: 16, weight: .medium)
        content.textProperties.color = .label
        content.secondaryTextProperties.font = .systemFont(ofSize: 14)
        content.secondaryTextProperties.color = .gray
        if indexPath.row == 0 {
            content.text = "Can Share and Download".localized()
            content.secondaryText = "The user, as the receiver, can share and download the attachment.".localized()
            cell.accessoryType = specFileString.contains("share,download") ? .checkmark : .none
        } else {
            content.text = "Can Forward".localized()
            content.secondaryText = "The user, as the receiver, can forward the attachment.".localized()
            cell.accessoryType = specFileString.contains("forward") ? .checkmark : .none
        }
        cell.contentConfiguration = content
        cell.tintColor = .black
        return cell
    }
    
    func offset() -> CGFloat{
        guard let fontSize = Int(SecureUserDefaults.shared.value(forKey: "font_size") ?? "0") else { return 0 }
        return CGFloat(fontSize)
    }
}
