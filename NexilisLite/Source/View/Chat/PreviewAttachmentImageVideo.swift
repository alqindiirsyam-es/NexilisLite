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
import QuickLook
import WebKit

protocol PreviewAttachmentImageVideoDelegate : NSObjectProtocol {
    func sendChatFromPreviewImage(message_text: String, attachment_flag: String, image_id: String, video_id: String, thumb_id: String, gif_id: String, file_id: String, viewController: UIViewController, specFile: String)
}

class PreviewAttachmentImageVideo: UIViewController, UIScrollViewDelegate, UITextViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate {
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
    var animatedImageView: SDAnimatedImageView!
    var currentTextTextField: String?
    var delegate: PreviewAttachmentImageVideoDelegate?
    var fromCopy = false
    var isGroup = false
    var isCC = false
    var tableViewConfigFile: UITableView!
    
    var lastPositionCursorMention = 0
    var lastTextLength = 0
    var tableMention = UITableView()
    var heightTableMention: NSLayoutConstraint!
    var listMentionWithText:[User] = []
    var listMentionInTextField:[User] = []
    
    var previewCollection: UICollectionView!
    var thumbnailCollection: UICollectionView!
    var attachments: [AttachmentItem] = []
    var currPage = 0
    let const: CGFloat = 50
    var minWidth: CGFloat!
    var maxWidth: CGFloat!
    
    override func viewWillDisappear(_ animated: Bool) {
        if self.isMovingFromParent {
            NotificationCenter.default.removeObserver(self)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.itemSize = CGSize(width:imagePreview.frame.width, height:imagePreview.frame.height)
        previewCollection = UICollectionView(frame: imagePreview.frame, collectionViewLayout: layout)
        self.view.addSubview(previewCollection)
        self.view.sendSubviewToBack(previewCollection)
        self.view.sendSubviewToBack(scrollViewImage)
        previewCollection.frame = CGRect(x: 0, y: 0, width: imagePreview.frame.width, height: imagePreview.frame.height)
        previewCollection.register(PreviewCell.self, forCellWithReuseIdentifier: "PreviewCell")
        previewCollection.showsHorizontalScrollIndicator = false
        previewCollection.delegate = self
        previewCollection.dataSource = self
        previewCollection.isPagingEnabled = true
        
        if attachments.count > 1 && attachments[0].type != .file {
            minWidth = (const + 3) * CGFloat(attachments.count)
            maxWidth = imagePreview.frame.width
            let layoutThumb = UICollectionViewFlowLayout()
            layoutThumb.scrollDirection = .horizontal
            layoutThumb.minimumLineSpacing = 3
            layoutThumb.itemSize = CGSize(width:const, height:const)
            thumbnailCollection = UICollectionView(frame: .zero, collectionViewLayout: layoutThumb)
            self.view.addSubview(thumbnailCollection)
            let fixMinWidth: CGFloat = minWidth < maxWidth ? minWidth : maxWidth
            var x = (imagePreview.frame.width / 2) - (fixMinWidth / 2)
            if fixMinWidth == maxWidth {
                x = 0
            }
            minWidth = fixMinWidth
            thumbnailCollection.frame = CGRect(x: x, y: imagePreview.frame.height - 120, width: fixMinWidth, height: const)
            thumbnailCollection.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "ThumbCell")
            thumbnailCollection.backgroundColor = .clear
            thumbnailCollection.showsHorizontalScrollIndicator = false
            thumbnailCollection.delegate = self
            thumbnailCollection.dataSource = self

    //            thumbnailCollection.dragInteractionEnabled = true
        }
        
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
            if attachments[currPage].isAck {
                buttonAckConfidential.setImage(imageAck, for: .normal)
            } else if attachments[currPage].isConfidential {
                buttonAckConfidential.setImage(imageConfidential, for: .normal)
            }
            buttonAckConfidential.tintColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : .white
            buttonAckConfidential.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .mainColor
        }
        
        textFieldSend.layer.cornerRadius = textFieldSend.maxCornerRadius()
        textFieldSend.layer.borderWidth = 1.0
        textFieldSend.backgroundColor = .white
        if attachments[currPage].text.isEmpty {
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
        previewCollection.addGestureRecognizer(dismissKeyboard)
        
        buttonCancel.circle()
        buttonCancel.backgroundColor = .secondaryColor.withAlphaComponent(0.4)
        buttonCancel.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        
        buttonSpecFile.circle()
        buttonSpecFile.backgroundColor = .secondaryColor.withAlphaComponent(0.4)
        buttonSpecFile.addTarget(self, action: #selector(showSpecFile), for: .touchUpInside)
        if attachments[currPage].isConfidential || self.isCC {
            buttonSpecFile.isEnabled = false
        }
        
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
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if attachments.count == 0 {
            scrollViewImage.minimumZoomScale = 1.0
            scrollViewImage.maximumZoomScale = 4.0
            scrollViewImage.zoomScale = 1.0
            scrollViewImage.delegate = self

            scrollViewDidZoom(scrollViewImage)
        }
    }
    
    @objc func showChooserACKConfidential() {
        var isCC = false
        let alertController = LibAlertController(title: "Message Mode".localized(), message: "Select".localized() + " " + "Message Mode".localized(), preferredStyle: .actionSheet)
        let vc = delegate
        if vc is EditorPersonal {
            let editorVc = vc as! EditorPersonal
            isCC = editorVc.isContactCenter
        }
        if !isCC {
            let imageConfidential = resizeImage(image: UIImage(named: "confidential_icon", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, targetSize: CGSize(width: 30, height: 30)).withRenderingMode(.alwaysOriginal)
            let confidentialAction = UIAlertAction(title: "Confidential Message".localized(), style: .default, handler: { [self] (UIAlertAction) in
                if !attachments[currPage].isConfidential {
                    attachments[currPage].isConfidential = true
                    self.buttonAckConfidential.setImage(imageConfidential, for: .normal)
                }
                if attachments[currPage].isAck {
                    attachments[currPage].isAck = false
                }
                attachments[currPage].specFileString = ""
                self.buttonSpecFile.setImage(UIImage(named: "pb_ic_attach_spc_off", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withRenderingMode(.alwaysOriginal).resize(target: CGSize(width: 40, height: 40)), for: .normal)
                self.buttonSpecFile.isEnabled = false
                self.setPreviousVariableMessageMode()
            })
            confidentialAction.setValue(imageConfidential, forKey: "image")
            alertController.addAction(confidentialAction)
        }
        let imageAck = resizeImage(image: UIImage(named: "ack_icon", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, targetSize: CGSize(width: 30, height: 30)).withRenderingMode(.alwaysOriginal)
        let ackAction = UIAlertAction(title: "Confirmation Message".localized(), style: .default, handler: { [self] (UIAlertAction) in
            if !attachments[currPage].isAck {
                attachments[currPage].isAck = true
                self.buttonAckConfidential.setImage(imageAck, for: .normal)
            }
            if attachments[currPage].isConfidential {
                attachments[currPage].isConfidential = false
            }
            if !self.buttonSpecFile.isEnabled {
                self.buttonSpecFile.isEnabled = true
            }
            self.setPreviousVariableMessageMode()
        })
        ackAction.setValue(imageAck, forKey: "image")
        alertController.addAction(ackAction)
        alertController.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: { [self] (UIAlertAction) in
            attachments[currPage].isConfidential = false
            attachments[currPage].isAck = false
            self.buttonAckConfidential.setImage(UIImage(systemName: "gearshape.fill", withConfiguration: UIImage.SymbolConfiguration(scale: .large))?.withTintColor(.white).withRenderingMode(.alwaysTemplate), for: .normal)
            if !self.buttonSpecFile.isEnabled {
                self.buttonSpecFile.isEnabled = true
            }
            self.setPreviousVariableMessageMode()
        }))
        self.present(alertController, animated: true, completion: nil)
    }
    
    func setPreviousVariableMessageMode() {
        let vc = delegate
        if vc is EditorPersonal && attachments.count == 1 {
            let editorVc = vc as! EditorPersonal
            editorVc.setAckConfidential(isAck: attachments[currPage].isAck, isConfidential: attachments[currPage].isConfidential)
        } else if vc is EditorGroup && attachments.count == 1 {
            let editorVc = vc as! EditorGroup
            editorVc.setAckConfidential(isAck: attachments[currPage].isAck, isConfidential: attachments[currPage].isConfidential)
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
                DispatchQueue.main.async {
                    textView.selectedRange = NSRange(location: newCursorPosition, length: 0)
                }
            }
        }

        // Handle Numbered Lists (e.g., "1. " [space] + letter → " 1.")
        let numberPattern = #"(?<=\n|^)(\d+)\. (\S)"# // Matches "1. X"
        if let match = text.range(of: numberPattern, options: .regularExpression) {
            let matchedText = text[match]

            let replacedText = text.replacingOccurrences(of: matchedText, with: "  \(matchedText)", range: match)

            let newCursorPosition = cursorPosition + 2  // Adjust cursor
            textView.text = replacedText
            DispatchQueue.main.async {
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

        // Ensure valid range
        guard range.location <= nsText.length else { return true }

        let newText = nsText.replacingCharacters(in: range, with: text)
        var lines = newText.components(separatedBy: "\n")

        guard let textRange = Range(range, in: textView.text) else { return true }
        let prefixText = textView.text[..<textRange.lowerBound]
        let affectedLineIndex = max(prefixText.components(separatedBy: "\n").count - 1, 0)
        guard affectedLineIndex < lines.count else { return true }

        let affectedLine = lines[affectedLineIndex]

        // ---- Auto-indent new lines ----
        if text == "\n" {
            let previousLine = lines[affectedLineIndex]

            // Handle bullet points
            if previousLine.hasPrefix("  •") {
                let newBullet = "\n  • "
                safeReplaceText(in: textView, range: range, with: newBullet)
                return false
            }

            // Handle numbered list continuation
            if let match = previousLine.range(of: #"^\s{2}(\d+)\."#, options: .regularExpression),
               let numberMatch = previousLine[match].components(separatedBy: ".").first,
               let number = Int(numberMatch.trimmingCharacters(in: .whitespaces)) {
                let newNumber = "\n  \(number + 1). "
                safeReplaceText(in: textView, range: range, with: newNumber)
                return false
            }
        }

        // ---- Handle backspace cases ----
        if text.isEmpty {
            // Empty bullet → "- "
            if affectedLine.trimmingCharacters(in: .whitespaces) == "•" {
                lines[affectedLineIndex] = "- "
                updateTextView(textView, with: lines.joined(separator: "\n"), cursorOffset: -1)
                return false
            }

            // Bullet or number deletion checks, safely bounded
            if range.location >= 2,
               let twoChars = textView.text.substring(with: NSRange(location: range.location - 2, length: 2)),
               twoChars == "  " {
                lines[affectedLineIndex] = affectedLine.trimmingCharacters(in: .whitespaces)
                updateTextView(textView, with: lines.joined(separator: "\n"), cursorOffset: -2)
                return false
            }
        }

        return true
    }
    
    private func safeReplaceText(in textView: UITextView, range: NSRange, with newText: String) {
        let nsText = textView.text as NSString
        textView.text = nsText.replacingCharacters(in: range, with: newText)
        DispatchQueue.main.async {
            textView.selectedRange = NSRange(location: range.location + newText.utf16.count, length: 0)
        }
    }

    private func updateTextView(_ textView: UITextView, with newText: String, cursorOffset: Int) {
        textView.text = newText
        DispatchQueue.main.async {
            let newLoc = max(textView.selectedRange.location + cursorOffset, 0)
            textView.selectedRange = NSRange(location: newLoc, length: 0)
        }
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
        attachments[currPage].text = textView.text
    }
    
    func textViewDidChangeSelection(_ textView: UITextView) {
        if delegate is EditorGroup {
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
        if let nowTextFieldSend = self.textFieldSend {
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
        //indention code:
        let text = textView.text ?? ""
        let cursorLocation = textView.selectedRange.location

        // Find current line range where cursor is
        if let lineRange = (text as NSString).lineRange(for: NSRange(location: cursorLocation, length: 0)) as NSRange? {
            let line = (text as NSString).substring(with: lineRange)

            // Detect bullet ("  •") or numbered ("  1.") list
            if line.hasPrefix("  •") || line.range(of: #"^\s{2}\d+\."#, options: .regularExpression) != nil {
                var bulletEnd = lineRange.location + 2
                if !line.hasPrefix("  •") {
                    bulletEnd = lineRange.location + 3
                }

                // Prevent cursor before bullet/number
                if cursorLocation < bulletEnd {
                    DispatchQueue.main.async {
                        textView.selectedRange = NSRange(location: bulletEnd, length: 0)
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
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imagePreview
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let scrollViewSize = scrollView.bounds.size

        let contentWidth  = scrollView.contentSize.width
        let contentHeight = scrollView.contentSize.height

        let verticalInset = max(0, (scrollViewSize.height - contentHeight) / 2)
        let horizontalInset = max(0, (scrollViewSize.width - contentWidth) / 2)

        scrollView.contentInset = UIEdgeInsets(
            top: verticalInset,
            left: horizontalInset,
            bottom: verticalInset,
            right: horizontalInset
        )
    }
    
    @objc func dismissKeyboard() {
        textFieldSend.resignFirstResponder()
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
        var i = 0
        Nexilis.showLoader(text: "Sending...".localized())
        DispatchQueue.global().async { [self] in
            for att in attachments {
                let semaphore = DispatchSemaphore(value: 0)
                if att.type == .file {
                    DispatchQueue.global().async { [self] in
                        guard let previewItem = self.attachments[i].fileURL else { return }
                        guard var dataFile = try? Data(contentsOf: previewItem as URL) else { return }
                        func sanitizeFile(mimeType: String, sanitizeAction: (Data) -> MessageGuardLite.Result) -> Data? {
                            let res = sanitizeAction(dataFile)

                            if res.verdict == .block {
                                DispatchQueue.main.async {
                                    APIS.showMessageGuardFile(mime: res.mime)
                                }
                                return nil
                            }
                            return res.data ?? Data()
                        }
                        func processIt(with data: Data) {
                            guard let urlFile = att.fileURL?.absoluteString else { return }
                            let originalFileName = (urlFile as NSString).lastPathComponent.removingPercentEncoding ?? "file"
                            let renamedNameFile = "Nexilis_\(Date().currentTimeMillis())_\(originalFileName)"

                            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                            let fileURL = documentsDirectory.appendingPathComponent(renamedNameFile)

                            if !FileManager.default.fileExists(atPath: fileURL.path) {
                                try? data.write(to: fileURL)
                            }

                            DispatchQueue.main.async { [self] in
                                delegate!.sendChatFromPreviewImage(message_text: "\(originalFileName)|\(att.text)", attachment_flag: "6", image_id: "", video_id: "", thumb_id: "", gif_id: "",  file_id: renamedNameFile, viewController: self, specFile: att.specFileString)
                                if i == attachments.count - 1 {
                                    Nexilis.hideLoader { [self] in
                                        self.dismiss(animated: true, completion: nil)
                                    }
                                } else {
                                    semaphore.signal()
                                }
                            }
                        }
                        if Nexilis.checkingAccess(key: "message_guard") {
                            let guardLite = MessageGuardLite(limits: .defaults())
                            let mimeType = MessageGuardLite.sniffMime(dataFile)

                            if mimeType == "image/png" || mimeType == "image/jpeg" {
                                if let sanitized = sanitizeFile(mimeType: mimeType, sanitizeAction: guardLite.sanitizeImage) {
                                    dataFile = sanitized
                                } else { return }
                            } else if mimeType == "application/pdf" {
                                if let sanitized = sanitizeFile(mimeType: mimeType, sanitizeAction: guardLite.sanitizePdf) {
                                    dataFile = sanitized
                                } else { return }
                            }
                            processIt(with: dataFile)
                        } else {
                            processIt(with: dataFile)
                        }
                    }
                } else if att.type == .image {
                    DispatchQueue.global().async { [self] in
                        var originalImageName = ""
                        if (fromCopy) {
                            originalImageName = "\(Date().currentTimeMillis())"
                        }
                        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                        let compressedImageName = "Nexilis_image_\(Date().currentTimeMillis())_\(originalImageName.components(separatedBy: ".")[0]).jpeg"
                        let thumbName = "THUMB_Nexilis_image_\(Date().currentTimeMillis())_\(originalImageName.components(separatedBy: ".")[0]).jpeg"
                        let fileURL = documentsDirectory.appendingPathComponent(compressedImageName)
                        var compressedImage = att.image?.jpeg ?? Data()
                        if Nexilis.checkingAccess(key: "message_guard") {
                            let guardLite = MessageGuardLite(limits: .defaults())
                            let res = guardLite.sanitizeImage(compressedImage)
                            if res.verdict != .block {
                                compressedImage = res.data ?? Data()
                            } else {
                                DispatchQueue.main.async {
                                    APIS.showMessageGuardFile(mime: res.mime)
                                }
                                return
                            }
                        }
                        if let compressed = compressImageLikeWhatsApp(UIImage(data: compressedImage) ?? UIImage()) {
                            compressedImage = compressed
                        }
                        let data = compressedImage
                        if !FileManager.default.fileExists(atPath: fileURL.path) {
                            do {
                                try data.write(to: fileURL)
                                //print("file saved")
                            } catch {
                                //print("error saving file:", error)
                            }
                        }
                        let thumbImage = UIImage(data: compressedImage)
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
                        DispatchQueue.main.async { [self] in
                            delegate!.sendChatFromPreviewImage(message_text: att.text, attachment_flag: "1", image_id: compressedImageName, video_id: "", thumb_id: thumbName, gif_id: "", file_id: "", viewController: self, specFile: att.specFileString)
                            if i == attachments.count - 1 {
                                Nexilis.hideLoader { [self] in
                                    self.dismiss(animated: true, completion: nil)
                                }
                            } else {
                                semaphore.signal()
                            }
                        }
                    }
                } else {
                    DispatchQueue.main.async { [self] in
                        previewCollection.reloadData()
                    }
                    DispatchQueue.global().async { [self] in
                        var dataVideo: Data?
                        if att.videoURL != nil || att.gif != nil {
                            if att.videoURL != nil {
                                dataVideo = try? Data(contentsOf: att.videoURL!)
                            } else {
                                dataVideo = att.gif
                            }
                        }
                        if att.type == .video {
                            Nexilis.dispatch = DispatchGroup()
                            Nexilis.dispatch?.enter()
                            let compressedURL = NSURL.fileURL(withPath: NSTemporaryDirectory() + UUID().uuidString + ".mp4")
                            compressVideo(inputURL: att.videoURL!,
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
                        DispatchQueue.main.async { [self] in
                            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                            var urlVideo = ""
                            var originalVideoName = ""
                            var renamedVideoName = ""
                            var thumbName = ""
                            if att.type == .gif {
                                originalVideoName = "\(Date().currentTimeMillis())_gif"
                                renamedVideoName = "Nexilis_gif_\(Date().currentTimeMillis())_\(originalVideoName)"
                                thumbName = "THUMB_Nexilis_gif_\(Date().currentTimeMillis())_\(originalVideoName.components(separatedBy: ".")[0]).jpeg"
                            } else {
                                urlVideo = att.videoURL!.absoluteString
                                originalVideoName = (urlVideo as NSString).lastPathComponent
                                renamedVideoName = "Nexilis_video_\(Date().currentTimeMillis())_\(originalVideoName.components(separatedBy: ".")[0]).mp4"
                                thumbName = "THUMB_Nexilis_video_\(Date().currentTimeMillis())_\(originalVideoName.components(separatedBy: ".")[0]).jpeg"
                            }
                            let fileURL = documentsDirectory.appendingPathComponent(renamedVideoName)
                            if !FileManager.default.fileExists(atPath: fileURL.path) {
                                do {
                                    if let dataVideo = dataVideo {
                                        try dataVideo.write(to: fileURL)
                                    }
                                    //print("file saved")
                                } catch {
                                    //print("error saving file:", error)
                                }
                            }
                            var dataThumbVideo: Data?
                            if att.type != .gif {
                                let thumb = thumbnail(url: att.videoURL!)
                                dataThumbVideo = thumb!.jpegData(compressionQuality:  0.5)
                            }
                            let fileURLTHUMB = documentsDirectory.appendingPathComponent(thumbName)
                            if !FileManager.default.fileExists(atPath: fileURLTHUMB.path) {
                                do {
                                    if let dataThumbVideo = dataThumbVideo, att.type == .video {
                                        try dataThumbVideo.write(to: fileURLTHUMB)
                                    } else {
                                        if let dataThumbGif = UIImage(data: dataVideo!) {
                                            if let compressedDataThumbGif = dataThumbGif.jpegData(compressionQuality: 0.5) {
                                                try compressedDataThumbGif.write(to: fileURLTHUMB)
                                            }
                                        }
                                    }
                                    //print("thumb saved")
                                } catch {
                                    //print("error saving file:", error)
                                }
                            }
                            delegate!.sendChatFromPreviewImage(message_text: att.text, attachment_flag: "2", image_id: "", video_id: att.type != .gif ? renamedVideoName : "", thumb_id: thumbName, gif_id: att.type == .gif ? renamedVideoName : "", file_id: "", viewController: self, specFile: att.specFileString)
                            if i == attachments.count - 1 {
                                Nexilis.hideLoader { [self] in
                                    self.dismiss(animated: true, completion: nil)
                                }
                            } else {
                                semaphore.signal()
                            }
                        }
                    }
                }
                semaphore.wait()
                i+=1
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
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return attachments.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let item = attachments[indexPath.row]
        if collectionView == previewCollection {
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "PreviewCell",
                for: indexPath
            ) as! PreviewCell
            cell.type = item.type
            if item.type == .image {
                cell.imageView.image = item.image
            } else if item.type == .video {
                let thumb = thumbnail(url: item.videoURL!)
                cell.imageView.image = thumb
                cell.url = item.videoURL!
                cell.setupNewView()
            } else if item.type == .gif {
                cell.data = item.gif
                cell.setupNewView()
            } else {
                cell.url = item.fileURL
                cell.setupNewView()
            }
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "ThumbCell",
                for: indexPath
            )
            let img = UIImageView(frame: cell.bounds)
            img.contentMode = .scaleAspectFill
            img.layer.cornerRadius = 4
            img.clipsToBounds = true
            
            if item.type == .image {
                img.image = item.image
            }
            if item.type == .video {
                img.image = thumbnail(url: item.videoURL!)
            }
            if item.type == .gif {
                img.image = UIImage(data: item.gif!)
            }
            cell.contentView.addSubview(img)
            
            if indexPath.row == currPage {
                let cont = UIView(frame: cell.bounds)
                cell.contentView.addSubview(cont)
                cont.layer.cornerRadius = 4
                cont.clipsToBounds = true
                cont.layer.borderColor = UIColor.white.cgColor
                cont.layer.borderWidth = 3
                cont.backgroundColor = .black.withAlphaComponent(0.3)
                
                let imageTrash = UIImageView(image: UIImage(systemName: "trash", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20)))
                cont.addSubview(imageTrash)
                imageTrash.tintColor = .white
                imageTrash.anchor(centerX: cont.centerXAnchor, centerY: cont.centerYAnchor)
            }
            
            if cell.gestureRecognizers?.isEmpty ?? true {
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cellTapped(_:)))
                cell.addGestureRecognizer(tapGesture)
            }

            return cell
        }
    }
    
    @objc func cellTapped(_ sender: UITapGestureRecognizer) {
        guard let cell = sender.view as? UICollectionViewCell,
                  let indexPath = thumbnailCollection.indexPath(for: cell)
            else { return }
        let index = indexPath.item
        if index == currPage {
            deletePreview(at: index)
        } else {
            let offset = CGFloat(index) * previewCollection.frame.width
            var animated = true
            if abs(index - currPage) > 1 {
                animated = false
            }
            previewCollection.setContentOffset(CGPoint(x: offset, y: 0), animated: animated)
        }
    }
    
    func deletePreview(at index: Int) {
        let indexPath = IndexPath(item: index, section: 0)
        guard let cell = previewCollection.cellForItem(at: indexPath) else { return }
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut, animations: {
            cell.alpha = 0
            cell.transform = CGAffineTransform(translationX: 0, y: -60)
        }) { [self] _ in
            attachments.remove(at: index)
            previewCollection.performBatchUpdates({
                previewCollection.deleteItems(at: [indexPath])
            }, completion: nil)
            thumbnailCollection.performBatchUpdates({
                thumbnailCollection.deleteItems(at: [indexPath])
            })
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: { [self] in
                if attachments.count > 1 {
                    minWidth = minWidth - 53
                    var x = (imagePreview.frame.width / 2) - (minWidth / 2)
                    if minWidth == maxWidth {
                        x = 0
                    }
                    thumbnailCollection.frame = CGRect(x: x, y: thumbnailCollection.frame.origin.y, width: minWidth, height: const)
                    let idxReload = index > attachments.count - 1 ? attachments.count - 1 : index
                    currPage = idxReload
                    
                    self.textFieldSend.text = attachments[idxReload].text
                    handleRichText(self.textFieldSend)
                    
                    if attachments[idxReload].specFileString.isEmpty {
                        buttonSpecFile.setImage(UIImage(named: "pb_ic_attach_spc_off", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withRenderingMode(.alwaysOriginal).resize(target: CGSize(width: 40, height: 40)), for: .normal)
                    } else {
                        buttonSpecFile.setImage(UIImage(named: "pb_ic_attach_spc", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withRenderingMode(.alwaysOriginal).resize(target: CGSize(width: 40, height: 40)), for: .normal)
                    }
                    
                    let imageConfidential = resizeImage(image: UIImage(named: "confidential_icon", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, targetSize: CGSize(width: 30, height: 30)).withRenderingMode(.alwaysOriginal)
                    let imageAck = resizeImage(image: UIImage(named: "ack_icon", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, targetSize: CGSize(width: 30, height: 30)).withRenderingMode(.alwaysOriginal)
                    if attachments[idxReload].isAck {
                        buttonAckConfidential.setImage(imageAck, for: .normal)
                    } else if attachments[idxReload].isConfidential {
                        buttonAckConfidential.setImage(imageConfidential, for: .normal)
                        if self.buttonSpecFile.isEnabled {
                            self.buttonSpecFile.isEnabled = false
                        }
                    } else {
                        self.buttonAckConfidential.setImage(UIImage(systemName: "gearshape.fill", withConfiguration: UIImage.SymbolConfiguration(scale: .large))?.withTintColor(.white).withRenderingMode(.alwaysTemplate), for: .normal)
                        if !self.buttonSpecFile.isEnabled && !self.isCC {
                            self.buttonSpecFile.isEnabled = true
                        }
                    }
                    
                    let indexPathReload = IndexPath(item: currPage, section: 0)
                    thumbnailCollection.reloadItems(at: [indexPathReload])
                } else {
                    thumbnailCollection.removeFromSuperview()
                }
            })
        }
    }
    
    func thumbnail(url:URL)->UIImage?{
        let asset = AVURLAsset(url: url, options: nil)
        let imgGenerator = AVAssetImageGenerator(asset: asset)
        imgGenerator.appliesPreferredTrackTransform = true
        if let cgImage = try? imgGenerator.copyCGImage(at: CMTimeMake(value: 0, timescale: 1), actualTime: nil) {
            let thumbnail = UIImage(cgImage: cgImage)
            return thumbnail
        }
        return nil
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == previewCollection {
            let centerX = scrollView.contentOffset.x + scrollView.frame.width / 2
            let page = Int(centerX / scrollView.frame.width)
            if page != currPage {
                currPage = page
                
                DispatchQueue.main.async { [self] in
                    self.textFieldSend.text = attachments[page].text
                    handleRichText(self.textFieldSend)
                    
                    if attachments[page].specFileString.isEmpty {
                        buttonSpecFile.setImage(UIImage(named: "pb_ic_attach_spc_off", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withRenderingMode(.alwaysOriginal).resize(target: CGSize(width: 40, height: 40)), for: .normal)
                    } else {
                        buttonSpecFile.setImage(UIImage(named: "pb_ic_attach_spc", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withRenderingMode(.alwaysOriginal).resize(target: CGSize(width: 40, height: 40)), for: .normal)
                    }
                    
                    let imageConfidential = resizeImage(image: UIImage(named: "confidential_icon", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, targetSize: CGSize(width: 30, height: 30)).withRenderingMode(.alwaysOriginal)
                    let imageAck = resizeImage(image: UIImage(named: "ack_icon", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, targetSize: CGSize(width: 30, height: 30)).withRenderingMode(.alwaysOriginal)
                    if attachments[page].isAck {
                        buttonAckConfidential.setImage(imageAck, for: .normal)
                    } else if attachments[page].isConfidential {
                        buttonAckConfidential.setImage(imageConfidential, for: .normal)
                        if self.buttonSpecFile.isEnabled {
                            self.buttonSpecFile.isEnabled = false
                        }
                    } else {
                        self.buttonAckConfidential.setImage(UIImage(systemName: "gearshape.fill", withConfiguration: UIImage.SymbolConfiguration(scale: .large))?.withTintColor(.white).withRenderingMode(.alwaysTemplate), for: .normal)
                        if !self.buttonSpecFile.isEnabled && !self.isCC {
                            self.buttonSpecFile.isEnabled = true
                        }
                    }
                }
                
//                thumbnailCollection.reloadData()
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if collectionView == previewCollection {
            if let cell = cell as? PreviewCell {
                cell.resetZoom()
                cell.stopVideo()
            }
        }
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
        if !attachments[currPage].specFileString.contains(type) {
            if !attachments[currPage].specFileString.isEmpty {
                attachments[currPage].specFileString += ","
            }
            attachments[currPage].specFileString += type
        } else {
            attachments[currPage].specFileString = attachments[currPage].specFileString.replacingOccurrences(of: type, with: "")
            if attachments[currPage].specFileString == "," {
                attachments[currPage].specFileString = ""
            }
        }
        if attachments[currPage].specFileString.isEmpty {
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
            cell.accessoryType = attachments[currPage].specFileString.contains("share,download") ? .checkmark : .none
        } else {
            content.text = "Can Forward".localized()
            content.secondaryText = "The user, as the receiver, can forward the attachment.".localized()
            cell.accessoryType = attachments[currPage].specFileString.contains("forward") ? .checkmark : .none
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

enum AttachmentType {
    case image
    case video
    case file
    case gif
}

struct AttachmentItem {
    var type: AttachmentType
    var image: UIImage?
    var gif: Data?
    var videoURL: URL?
    var fileURL: URL?
    var text: String = ""
    var specFileString: String = ""
    var isAck: Bool = false
    var isConfidential: Bool = false
}

class PreviewCell: UICollectionViewCell, UIScrollViewDelegate {

    let zoomScrollView = UIScrollView()
    let imageView = UIImageView()
    let playPauseButton = UIButton(type: .system)
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?
    var isPlaying = false
    var type: AttachmentType!
    var url: URL?
    var data: Data?
    var animatedImageView: SDAnimatedImageView!
    var webView: WKWebView?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupZoom()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupZoom()
    }

    private func setupZoom() {

        zoomScrollView.frame = bounds
        zoomScrollView.delegate = self
        zoomScrollView.minimumZoomScale = 1
        zoomScrollView.maximumZoomScale = 4
        zoomScrollView.showsVerticalScrollIndicator = false
        zoomScrollView.showsHorizontalScrollIndicator = false
        
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(doubleTapZoom))
        doubleTap.numberOfTapsRequired = 2
        zoomScrollView.addGestureRecognizer(doubleTap)

        contentView.addSubview(zoomScrollView)

        imageView.frame = zoomScrollView.bounds
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true

        zoomScrollView.addSubview(imageView)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        resetZoom()
        imageView.image = nil
        stopVideo()
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
        player = nil
        animatedImageView?.removeFromSuperview()
        animatedImageView = nil
        playPauseButton.removeFromSuperview()
        webView?.removeFromSuperview()
        webView = nil
        zoomScrollView.isScrollEnabled = true
        zoomScrollView.isUserInteractionEnabled = true
    }
    
    func setupNewView() {
        if type == .video {
            playPauseButton.setImage(UIImage(systemName: "play.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 30)), for: .normal)
            playPauseButton.tintColor = .gray
            playPauseButton.backgroundColor = UIColor.white
            playPauseButton.layer.cornerRadius = 35
            playPauseButton.clipsToBounds = true
            if playPauseButton.superview == nil {
                contentView.addSubview(playPauseButton)
            }
            playPauseButton.anchor(centerX: contentView.centerXAnchor, centerY: contentView.centerYAnchor, width: 70, height: 70)
            playPauseButton.addTarget(self, action: #selector(playPauseTapped), for: .touchUpInside)
            playPauseButton.isUserInteractionEnabled = true
            
            guard let url = url else { return }
            player = AVPlayer(url: url)
            playerLayer = AVPlayerLayer(player: player)
            playerLayer?.frame = imageView.bounds
            playerLayer?.videoGravity = .resizeAspect
            if let playerLayer = playerLayer {
                imageView.layer.addSublayer(playerLayer)
            }
            NotificationCenter.default.addObserver(self, selector: #selector(videoDidEnd), name: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem)
        } else if type == .gif {
            animatedImageView = SDAnimatedImageView()
            animatedImageView.contentMode = .scaleAspectFit
            imageView.addSubview(animatedImageView)
            animatedImageView.anchor(top: imageView.topAnchor, left: imageView.leftAnchor, bottom: imageView.bottomAnchor, right: imageView.rightAnchor)
            if let animatedImage = SDAnimatedImage(data: data!) {
                animatedImageView.image = animatedImage
            }
        } else if type == .file {
            guard let url = url else { return }

            // Disable zoomScrollView biar gak bentrok
            zoomScrollView.isScrollEnabled = false
            zoomScrollView.isUserInteractionEnabled = false

            let webView = WKWebView(frame: contentView.bounds)
            webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

            // penting: aktifkan scroll
            webView.scrollView.isScrollEnabled = true
            webView.scrollView.bounces = true

            contentView.addSubview(webView)
            self.webView = webView

            webView.loadFileURL(url, allowingReadAccessTo: url)
        }
    }
    
    @objc private func playPauseTapped() {
        guard let player = player else { return }
        if !isPlaying {
            player.play()
            playPauseButton.isHidden = true
            isPlaying.toggle()
        }
    }
    
    @objc private func videoDidEnd() {
        guard let player = player else { return }
        player.seek(to: .zero)
        player.play()
        isPlaying = true
    }
    
    func stopVideo() {
        player?.pause()
        player?.seek(to: .zero)
        isPlaying = false
        playPauseButton.isHidden = false
    }
    
    @objc func doubleTapZoom(_ gesture: UITapGestureRecognizer) {

        let point = gesture.location(in: imageView)

        if zoomScrollView.zoomScale == 1 {

            let width = zoomScrollView.frame.width / 3
            let height = zoomScrollView.frame.height / 3

            let rect = CGRect(
                x: point.x - width / 2,
                y: point.y - height / 2,
                width: width,
                height: height
            )

            zoomScrollView.zoom(to: rect, animated: true)

        } else {
            zoomScrollView.setZoomScale(1, animated: true)
        }
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let scrollSize = scrollView.bounds.size
        let contentWidth = scrollView.contentSize.width
        let contentHeight = scrollView.contentSize.height

        let verticalInset = max(0, (scrollSize.height - contentHeight) / 2)
        let horizontalInset = max(0, (scrollSize.width - contentWidth) / 2)

        scrollView.contentInset = UIEdgeInsets(
            top: verticalInset,
            left: horizontalInset,
            bottom: verticalInset,
            right: horizontalInset
        )
    }
    
    func resetZoom() {
        zoomScrollView.setZoomScale(1, animated: false)
        zoomScrollView.contentInset = .zero
    }
}
