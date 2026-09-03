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
    // The strip is laid out, not framed - see viewDidLoad. Its width still has to change as
    // attachments are deleted, so the constraint is kept.
    private var thumbnailWidthConstraint: NSLayoutConstraint?
    // Pulling a frame out of a video is expensive enough to be worth doing once per file:
    // it used to run again for every single cell dequeue, in both collections.
    private var videoThumbnailCache: [String: UIImage] = [:]
    var attachments: [AttachmentItem] = []
    // Ticks the "Compressing NN%" text on the loader while an export is running; see
    // showCompressionProgress(for:).
    private var compressionProgressTimer: Timer?
    var currPage = 0

    // The row of things that can be decided about a video before it is sent - the same set the
    // share sheet offers, so a video sent from either place is edited the same way.
    private var videoTrimStrip: VideoTrimStrip?
    private var videoMuteButton: UIButton?
    private var videoInfoPill: UILabel?
    private var videoFormatToggle: UIStackView?
    private var videoModeButton: UIButton?
    private var gifModeButton: UIButton?
    private var lastVideoStripIndex = -1
    /// Follows the video as it plays and carries the marker along the strip with it. A display link
    /// rather than the player's own observer: it is tied to the screen refreshing, so it either
    /// runs or it does not, and there is no token to be dropped without anybody noticing.
    private var videoTicker: CADisplayLink?
    private var activeTranscoder: VideoTranscoder?
    /// Set while the marker is being dragged. Playing writes the marker's position twenty times a
    /// second, and the finger writes it too - so without this the two pull against each other and
    /// the marker stutters between where it is being dragged and where the video has got to.
    private var isScrubbingVideo = false
    let const: CGFloat = 50
    var minWidth: CGFloat!
    var maxWidth: CGFloat!
    
    override func viewWillDisappear(_ animated: Bool) {
        if self.isMovingFromParent {
            NotificationCenter.default.removeObserver(self)
        }
    }

    deinit {
        // A repeating timer holds its target; without this it would outlive the screen.
        compressionProgressTimer?.invalidate()
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
            minWidth = fixMinWidth
            // Fix: this used to be a hardcoded frame at `UIScreen.main.bounds.height - 120`,
            // worked out in viewDidLoad before anything had been laid out - on some screens
            // that lands right on top of the text field, and it stays there when the
            // keyboard pushes the text field up. Anchoring it above the text field puts it
            // in the right place on every screen and lets it follow the keyboard for free.
            thumbnailCollection.translatesAutoresizingMaskIntoConstraints = false
            let thumbnailWidth = thumbnailCollection.widthAnchor.constraint(equalToConstant: fixMinWidth)
            thumbnailWidthConstraint = thumbnailWidth
            NSLayoutConstraint.activate([
                thumbnailCollection.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                thumbnailCollection.bottomAnchor.constraint(equalTo: textFieldSend.topAnchor, constant: -12),
                thumbnailWidth,
                thumbnailCollection.heightAnchor.constraint(equalToConstant: const)
            ])
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
        buildVideoControls()
        
        buttonCancel.circle()
        buttonCancel.backgroundColor = .secondaryColor.withAlphaComponent(0.4)
        buttonCancel.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        
        buttonSpecFile.circle()
        buttonSpecFile.backgroundColor = .secondaryColor.withAlphaComponent(0.4)
        buttonSpecFile.addTarget(self, action: #selector(showSpecFile), for: .touchUpInside)
        if attachments[currPage].isConfidential || self.isCC {
            buttonSpecFile.isEnabled = false
            if self.isCC {
                buttonSpecFile.isHidden = true
            }
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
        // See UITextView.applyRichText - it is what keeps this from blinking and jumping to
        // the bottom of the box on every keystroke.
        if let vc = delegate as? EditorGroup {
            textView.applyRichText(textView.text.richText(isEditing: true, group_id: vc.dataGroup["group_id"]  as? String ?? "", listMentionInTextField: self.listMentionInTextField))
        } else {
            textView.applyRichText(textView.text.richText(isEditing: true))
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
        Nexilis.showLoader(text: "Sending...".localized())
        // Fix: the attachments used to be walked by a for loop on a background thread that
        // blocked on a semaphore after each one and, for a video, on a DispatchGroup until
        // the export had finished. Both are blocking waits, held by a thread at the QoS this
        // screen was started from, while the work being waited on runs lower -
        // AVAssetExportSession does its encoding on its own default-priority thread. That is
        // exactly the priority inversion the Thread Performance Checker reported, with a
        // thread parked for the entire length of a compression on top of it. Nothing waits
        // now: each attachment starts the next one from its own completion.
        //
        // The DispatchGroup it waited on was Nexilis.dispatch, which is shared - Callback's
        // connectionStateChanged calls leave() on it whenever the connection changes state.
        // A reconnect in the middle of a compression would release the wait early and leave
        // the export's own leave() to over-release the group.
        sendAttachment(at: 0)
    }

    private func sendAttachment(at index: Int) {
        guard index < attachments.count else {
            finishSending()
            return
        }
        let attachment = attachments[index]
        let sendNext: () -> Void = { [weak self] in
            self?.sendAttachment(at: index + 1)
        }
        switch attachment.type {
        case .file:
            sendFileAttachment(attachment, completion: sendNext)
        case .image:
            sendImageAttachment(attachment, completion: sendNext)
        default:
            sendVideoAttachment(attachment, completion: sendNext)
        }
    }

    private func finishSending() {
        DispatchQueue.main.async {
            Nexilis.hideLoader { [weak self] in
                self?.dismiss(animated: true, completion: nil)
            }
        }
    }

    // Fix: every way out of these calls the completion. They used to just `return`, which
    // left the semaphore un-signalled - the loop then waited for a signal that was never
    // coming, and the "Sending..." loader stayed up for good.
    private func sendFileAttachment(_ att: AttachmentItem, completion: @escaping () -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [self] in
            guard let previewItem = att.fileURL,
                  var dataFile = try? Data(contentsOf: previewItem) else {
                completion()
                return
            }
            func sanitize(with action: (Data) -> MessageGuardLite.Result) -> Data? {
                let res = action(dataFile)
                if res.verdict == .block {
                    DispatchQueue.main.async {
                        APIS.showMessageGuardFile(mime: res.mime)
                    }
                    return nil
                }
                return res.data ?? Data()
            }
            if Nexilis.checkingAccess(key: "message_guard") {
                let guardLite = MessageGuardLite(limits: .defaults())
                let mimeType = MessageGuardLite.sniffMime(dataFile)
                if mimeType == "image/png" || mimeType == "image/jpeg" {
                    guard let sanitized = sanitize(with: guardLite.sanitizeImage) else {
                        completion()
                        return
                    }
                    dataFile = sanitized
                } else if mimeType == "application/pdf" {
                    guard let sanitized = sanitize(with: guardLite.sanitizePdf) else {
                        completion()
                        return
                    }
                    dataFile = sanitized
                }
            }
            guard let urlFile = att.fileURL?.absoluteString else {
                completion()
                return
            }
            let originalFileName = (urlFile as NSString).lastPathComponent.removingPercentEncoding ?? "file"
            let renamedNameFile = "Nexilis_\(Date().currentTimeMillis())_\(originalFileName)"
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileURL = documentsDirectory.appendingPathComponent(renamedNameFile)
            if !FileManager.default.fileExists(atPath: fileURL.path) {
                try? dataFile.write(to: fileURL)
            }
            DispatchQueue.main.async { [self] in
                delegate!.sendChatFromPreviewImage(message_text: "\(originalFileName)|\(att.text)", attachment_flag: "6", image_id: "", video_id: "", thumb_id: "", gif_id: "",  file_id: renamedNameFile, viewController: self, specFile: att.specFileString)
                completion()
            }
        }
    }

    private func sendImageAttachment(_ att: AttachmentItem, completion: @escaping () -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [self] in
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
                    completion()
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
                } catch {
                }
            }
            let thumbImage = UIImage(data: compressedImage)
            let fileURLTHUMB = documentsDirectory.appendingPathComponent(thumbName)
            if let dataThumb = thumbImage?.jpegData(compressionQuality:  0.25),
               !FileManager.default.fileExists(atPath: fileURLTHUMB.path) {
                do {
                    try dataThumb.write(to: fileURLTHUMB)
                } catch {
                }
            }
            DispatchQueue.main.async { [self] in
                delegate!.sendChatFromPreviewImage(message_text: att.text, attachment_flag: "1", image_id: compressedImageName, video_id: "", thumb_id: thumbName, gif_id: "", file_id: "", viewController: self, specFile: att.specFileString)
                completion()
            }
        }
    }

    private func sendVideoAttachment(_ att: AttachmentItem, completion: @escaping () -> Void) {
        DispatchQueue.main.async { [self] in
            previewCollection.reloadData()
        }
        guard att.type == .video, let videoURL = att.videoURL else {
            // A gif already carries its bytes with it - there is nothing to compress.
            writeVideoAttachment(att, sourceURL: nil, completion: completion)
            return
        }
        // Asked for as an animated picture instead, so it is drawn rather than encoded.
        if att.asGIF {
            makeGIF(from: att) { [weak self] converted in
                guard let self = self, let converted = converted else {
                    completion()
                    return
                }
                self.writeVideoAttachment(converted, sourceURL: nil, completion: completion)
            }
            return
        }
        let compressedURL = URL(fileURLWithPath: NSTemporaryDirectory() + UUID().uuidString + ".mp4")
        // Fix: this went through an export preset, and a preset settles the resolution and the
        // bitrate together - so the only way to a smaller file was a smaller picture, and the size
        // shown beside the length could never be the size actually sent. The video keeps the size
        // it was shot at and it is the bitrate that comes down, at exactly the rate the figure on
        // screen was worked out from. Trim and sound are handled in the same pass.
        var span: CMTimeRange?
        if att.duration > 0 {
            let range = att.trimmedRange
            if range.lowerBound > 0 || range.upperBound < att.duration {
                span = CMTimeRange(start: CMTime(seconds: range.lowerBound, preferredTimescale: 600),
                                   end: CMTime(seconds: range.upperBound, preferredTimescale: 600))
            }
        }
        let transcoder = VideoTranscoder()
        activeTranscoder = transcoder
        transcoder.start(source: videoURL,
                         destination: compressedURL,
                         timeRange: span,
                         muted: !att.carriesAudio,
                         progress: { fraction in
            Nexilis.loadingAlert.message = "\("Compressing".localized()) \(Int(fraction * 100))%"
        }, completion: { [weak self] ok in
            guard let self = self else {
                return
            }
            self.activeTranscoder = nil
            let usable = ok && FileManager.default.fileExists(atPath: compressedURL.path)
            self.writeVideoAttachment(att, sourceURL: usable ? compressedURL : videoURL, completion: completion)
        })
    }

    // Fix: this used to run on the MAIN queue, and it read the whole video into memory with
    // Data(contentsOf:) before writing it back out again. A clip from the iPhone camera is
    // routinely hundreds of megabytes: that is a memory spike big enough to be killed for,
    // and the UI was frozen for the whole of it. Copying the file hands the bytes to the
    // filesystem instead of through the app, and none of it touches the main thread.
    private func writeVideoAttachment(_ att: AttachmentItem, sourceURL: URL?, completion: @escaping () -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [self] in
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            var originalVideoName = ""
            var renamedVideoName = ""
            var thumbName = ""
            if att.type == .gif {
                originalVideoName = "\(Date().currentTimeMillis())_gif"
                renamedVideoName = "Nexilis_gif_\(originalVideoName)"
                thumbName = "THUMB_Nexilis_gif_\(Date().currentTimeMillis())_\(originalVideoName.components(separatedBy: ".")[0]).jpeg"
            } else {
                let urlVideo = att.videoURL?.absoluteString ?? ""
                originalVideoName = (urlVideo as NSString).lastPathComponent
                renamedVideoName = "Nexilis_video_\(Date().currentTimeMillis())_\(originalVideoName.components(separatedBy: ".")[0]).mp4"
                thumbName = "THUMB_Nexilis_video_\(Date().currentTimeMillis())_\(originalVideoName.components(separatedBy: ".")[0]).jpeg"
            }
            let fileURL = documentsDirectory.appendingPathComponent(renamedVideoName)
            if !FileManager.default.fileExists(atPath: fileURL.path) {
                if let sourceURL = sourceURL {
                    try? FileManager.default.copyItem(at: sourceURL, to: fileURL)
                } else if let gif = att.gif {
                    try? gif.write(to: fileURL)
                }
            }
            let fileURLTHUMB = documentsDirectory.appendingPathComponent(thumbName)
            if !FileManager.default.fileExists(atPath: fileURLTHUMB.path) {
                if att.type == .video, let videoURL = att.videoURL,
                   let dataThumbVideo = thumbnail(url: videoURL)?.jpegData(compressionQuality: 0.5) {
                    try? dataThumbVideo.write(to: fileURLTHUMB)
                } else if let gif = att.gif, let dataThumbGif = UIImage(data: gif),
                          let compressedDataThumbGif = dataThumbGif.jpegData(compressionQuality: 0.5) {
                    try? compressedDataThumbGif.write(to: fileURLTHUMB)
                }
            }
            // The compressed copy has been handed over; the temporary file it lived in is of
            // no further use and can be tens of megabytes.
            if let sourceURL = sourceURL, sourceURL.path.hasPrefix(NSTemporaryDirectory()) {
                try? FileManager.default.removeItem(at: sourceURL)
            }
            DispatchQueue.main.async { [self] in
                delegate!.sendChatFromPreviewImage(message_text: att.text, attachment_flag: "0", image_id: "", video_id: renamedVideoName, thumb_id: thumbName, gif_id: att.type == .gif ? renamedVideoName : "", file_id: "", viewController: self, specFile: att.specFileString)
                completion()
            }
        }
    }

    /// Turns the chosen part of a video into an animated gif, which then travels the way a gif
    /// picked from the keyboard does.
    private func makeGIF(from att: AttachmentItem, completion: @escaping (AttachmentItem?) -> Void) {
        guard let source = att.videoURL else {
            completion(nil)
            return
        }
        DispatchQueue.global(qos: .userInitiated).async {
            let asset = AVURLAsset(url: source)
            let whole = CMTimeGetSeconds(asset.duration)
            let from = att.trimStart
            let to = att.trimEnd > 0 ? att.trimEnd : whole
            let length = max(0.1, to - from)
            // Ten frames a second is what a gif is usually worth; more only makes the file larger
            // without looking better.
            let perSecond = 10.0
            let count = max(2, min(150, Int(length * perSecond)))
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            generator.requestedTimeToleranceBefore = .zero
            generator.requestedTimeToleranceAfter = .zero
            generator.maximumSize = CGSize(width: 480, height: 480)

            let data = NSMutableData()
            guard let destination = CGImageDestinationCreateWithData(data, "com.compuserve.gif" as CFString, count, nil) else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            CGImageDestinationSetProperties(destination, [
                kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: 0]
            ] as CFDictionary)
            let frameProperties = [
                kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFDelayTime: 1.0 / perSecond]
            ] as CFDictionary
            for step in 0..<count {
                let at = CMTime(seconds: from + length * Double(step) / Double(count), preferredTimescale: 600)
                guard let frame = try? generator.copyCGImage(at: at, actualTime: nil) else {
                    continue
                }
                CGImageDestinationAddImage(destination, frame, frameProperties)
            }
            guard CGImageDestinationFinalize(destination) else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            var converted = att
            converted.type = .gif
            converted.gif = data as Data
            DispatchQueue.main.async {
                completion(converted)
            }
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
                cell.imageView.image = cachedThumbnail(for: item.videoURL!)
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
            // Fix: a plain UICollectionViewCell has nothing to reset itself, and this piled
            // another image view (and, for the selected one, another border and trash icon)
            // on top of whatever the recycled cell was still showing. It went unnoticed
            // while nothing ever reloaded these cells; now that the selection moves, it
            // would leave the old highlight behind.
            cell.contentView.subviews.forEach({ $0.removeFromSuperview() })
            let img = UIImageView(frame: cell.bounds)
            img.contentMode = .scaleAspectFill
            img.layer.cornerRadius = 4
            img.clipsToBounds = true
            
            if item.type == .image {
                img.image = item.image
            }
            if item.type == .video, let videoURL = item.videoURL {
                img.image = cachedThumbnail(for: videoURL)
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
    
    private func buildVideoControls() {
        let trim = VideoTrimStrip()
        trim.onChange = { [weak self] start, end in
            self?.videoTrimChanged(startFraction: start, endFraction: end)
        }
        trim.onScrub = { [weak self] fraction in
            self?.videoPlayheadMoved(to: fraction)
        }
        trim.onScrubEnded = { [weak self] fraction in
            self?.videoPlayheadMoved(to: fraction)
            self?.isScrubbingVideo = false
            self?.currentVideoCell()?.playPause()
        }
        view.addSubview(trim)
        trim.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            // Fix: hung from the top of the screen, which is where the close button already is -
            // so the strip lay over it and there was no way out of the screen. It hangs from the
            // button instead.
            trim.topAnchor.constraint(equalTo: buttonCancel.bottomAnchor, constant: 12),
            trim.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            trim.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            trim.heightAnchor.constraint(equalToConstant: 40)
        ])
        videoTrimStrip = trim

        let mute = UIButton(type: .system)
        mute.tintColor = .white
        mute.backgroundColor = UIColor(white: 0.15, alpha: 0.9)
        mute.layer.cornerRadius = 15
        mute.addTarget(self, action: #selector(toggleVideoMute), for: .touchUpInside)
        view.addSubview(mute)
        mute.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mute.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            mute.topAnchor.constraint(equalTo: trim.bottomAnchor, constant: 8),
            mute.widthAnchor.constraint(equalToConstant: 46),
            mute.heightAnchor.constraint(equalToConstant: 30)
        ])
        videoMuteButton = mute

        let info = UILabel()
        info.font = .systemFont(ofSize: 12, weight: .semibold)
        info.textColor = .white
        info.textAlignment = .center
        info.backgroundColor = UIColor(white: 0.15, alpha: 0.9)
        info.layer.cornerRadius = 15
        info.clipsToBounds = true
        view.addSubview(info)
        info.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            info.leadingAnchor.constraint(equalTo: mute.trailingAnchor, constant: 8),
            info.centerYAnchor.constraint(equalTo: mute.centerYAnchor),
            info.heightAnchor.constraint(equalToConstant: 30),
            info.widthAnchor.constraint(greaterThanOrEqualToConstant: 108)
        ])
        videoInfoPill = info

        let asVideo = UIButton(type: .system)
        asVideo.setImage(UIImage(systemName: "video.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)), for: .normal)
        asVideo.addTarget(self, action: #selector(chooseVideoFormat), for: .touchUpInside)
        let asGIF = UIButton(type: .system)
        asGIF.setTitle("GIF", for: .normal)
        asGIF.titleLabel?.font = .systemFont(ofSize: 12, weight: .bold)
        asGIF.addTarget(self, action: #selector(chooseGIFFormat), for: .touchUpInside)
        let toggle = UIStackView(arrangedSubviews: [asVideo, asGIF])
        toggle.axis = .horizontal
        toggle.distribution = .fillEqually
        toggle.backgroundColor = UIColor(white: 0.15, alpha: 0.9)
        toggle.layer.cornerRadius = 15
        toggle.clipsToBounds = true
        view.addSubview(toggle)
        toggle.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            toggle.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            toggle.leadingAnchor.constraint(greaterThanOrEqualTo: info.trailingAnchor, constant: 8),
            toggle.centerYAnchor.constraint(equalTo: mute.centerYAnchor),
            toggle.widthAnchor.constraint(equalToConstant: 96),
            toggle.heightAnchor.constraint(equalToConstant: 30)
        ])
        videoFormatToggle = toggle
        videoModeButton = asVideo
        gifModeButton = asGIF
        refreshVideoControls()
    }

    /// Everything here belongs to one video, so it is put away whenever the attachment being looked
    /// at is anything else.
    func refreshVideoControls() {
        let item = attachments.indices.contains(currPage) ? attachments[currPage] : nil
        let isVideo = item?.type == .video
        [videoTrimStrip, videoMuteButton, videoInfoPill, videoFormatToggle].forEach { $0?.isHidden = !isVideo }
        guard let item = item, isVideo else {
            return
        }
        // A gif carries no sound at all, so there is nothing to decide: the button shows what is
        // going to happen and stops taking taps.
        let silent = item.isMuted || item.asGIF
        videoMuteButton?.setImage(UIImage(systemName: silent ? "speaker.slash.fill" : "speaker.wave.2.fill",
                                          withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)), for: .normal)
        videoMuteButton?.isEnabled = !item.asGIF
        videoMuteButton?.alpha = item.asGIF ? 0.45 : 1
        videoModeButton?.tintColor = item.asGIF ? UIColor(white: 1, alpha: 0.45) : .white
        videoModeButton?.backgroundColor = item.asGIF ? .clear : UIColor(white: 0.35, alpha: 1)
        gifModeButton?.setTitleColor(item.asGIF ? .white : UIColor(white: 1, alpha: 0.45), for: .normal)
        gifModeButton?.backgroundColor = item.asGIF ? UIColor(white: 0.35, alpha: 1) : .clear
        updateVideoInfoPill()
        bindVideoPlayback()
        if lastVideoStripIndex != currPage {
            lastVideoStripIndex = currPage
            loadVideoStrip()
        }
    }

    private func updateVideoInfoPill() {
        guard attachments.indices.contains(currPage) else {
            return
        }
        let item = attachments[currPage]
        let seconds = Int(item.trimmedDuration.rounded())
        var text = String(format: "%d:%02d", seconds / 60, seconds % 60)
        // Fix: this was a share of the file as it arrived, which is not what is going to be sent -
        // the video is re-encoded first, and at a lower rate. What is shown is worked out from the
        // rate it is being encoded at, which is a figure this app decides rather than reads, and it
        // is the same one handed to the encoder.
        if item.targetBitrate > 0 {
            let carried = item.targetBitrate + (item.carriesAudio ? 64_000 : 0)
            text += "  \u{00B7}  " + ByteCountFormatter.string(fromByteCount: Int64(carried / 8 * item.trimmedDuration), countStyle: .file)
        } else if let url = item.videoURL {
            let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
            let whole = (attributes?[.size] as? NSNumber)?.int64Value ?? 0
            let share = item.duration > 0 ? item.trimmedDuration / item.duration : 1
            text += "  \u{00B7}  " + ByteCountFormatter.string(fromByteCount: Int64(Double(whole) * share), countStyle: .file)
        }
        videoInfoPill?.text = "  " + text + "  "
    }

    /// The frames along the strip, read off the video on a background queue and kept, so coming
    /// back to it is instant.
    private func loadVideoStrip() {
        guard attachments.indices.contains(currPage), let url = attachments[currPage].videoURL,
              let strip = videoTrimStrip else {
            return
        }
        let item = attachments[currPage]
        if !item.stripFrames.isEmpty {
            strip.show(frames: item.stripFrames, start: item.trimStart, end: item.trimEnd, duration: item.duration)
            return
        }
        let page = currPage
        let asset = AVURLAsset(url: url)
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let seconds = CMTimeGetSeconds(asset.duration)
            let videoTrack = asset.tracks(withMediaType: .video).first
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            generator.maximumSize = CGSize(width: 120, height: 120)
            var images: [UIImage] = []
            let wanted = 12
            for step in 0..<wanted {
                let at = CMTime(seconds: seconds * Double(step) / Double(wanted), preferredTimescale: 600)
                if let frame = try? generator.copyCGImage(at: at, actualTime: nil) {
                    images.append(UIImage(cgImage: frame))
                }
            }
            DispatchQueue.main.async {
                guard let self = self, self.attachments.indices.contains(page), self.currPage == page else {
                    return
                }
                if seconds.isFinite, self.attachments[page].duration == 0 {
                    self.attachments[page].duration = seconds
                }
                self.attachments[page].videoBitrate = Double(videoTrack?.estimatedDataRate ?? 0)
                self.attachments[page].audioBitrate = Double(asset.tracks(withMediaType: .audio).first?.estimatedDataRate ?? 0)
                self.attachments[page].targetBitrate = videoTrack.map { Double(VideoTranscoder.targetBitrate(for: $0)) } ?? 0
                self.attachments[page].stripFrames = images
                let ready = self.attachments[page]
                strip.show(frames: images, start: ready.trimStart, end: ready.trimEnd, duration: ready.duration)
                self.updateVideoInfoPill()
            }
        }
    }

    /// Fix: the cell is bound to the strip in refreshVideoControls, and on the way into this
    /// screen that runs before the collection view has made any cells - so cellForItem answered
    /// nil, nothing was bound, and playing the very first video moved no marker. It came right
    /// only after moving to another attachment and back, which is when the binding finally found a
    /// cell. Binding happens as a cell appears as well, which is the moment there is one to bind.
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard collectionView == previewCollection, indexPath.item == currPage else {
            return
        }
        DispatchQueue.main.async { [weak self] in
            self?.bindVideoPlayback()
        }
    }

    private func currentVideoCell() -> PreviewCell? {
        guard attachments.indices.contains(currPage), attachments[currPage].type == .video else {
            return nil
        }
        return previewCollection.cellForItem(at: IndexPath(item: currPage, section: 0)) as? PreviewCell
    }

    /// Hands the cell what the strip has decided, and starts following it while it plays.
    private func bindVideoPlayback() {
        guard attachments.indices.contains(currPage), let cell = currentVideoCell() else {
            stopFollowingPlayback()
            return
        }
        let item = attachments[currPage]
        cell.keptRange = item.duration > 0 ? item.trimmedRange : nil
        cell.startFrom = item.trimStart
        // The speaker button decided this, and it should be true of what is being previewed as
        // well as of what is sent - otherwise the preview says one thing and the message another.
        cell.player?.isMuted = !item.carriesAudio
        cell.onPlaybackChanged = { [weak self] playing in
            if playing {
                self?.startFollowingPlayback()
            } else {
                self?.stopFollowingPlayback()
            }
        }
    }

    private func startFollowingPlayback() {
        videoTicker?.invalidate()
        let link = CADisplayLink(target: self, selector: #selector(followVideoPlayback))
        link.add(to: .main, forMode: .common)
        videoTicker = link
    }

    private func stopFollowingPlayback() {
        videoTicker?.invalidate()
        videoTicker = nil
    }

    @objc private func followVideoPlayback() {
        // While the marker is being held it belongs to the finger, not to the video.
        guard !isScrubbingVideo else {
            return
        }
        guard attachments.indices.contains(currPage),
              let cell = currentVideoCell(), let player = cell.player else {
            stopFollowingPlayback()
            return
        }
        let whole = attachments[currPage].duration
        let at = CMTimeGetSeconds(player.currentTime())
        guard whole > 0, at.isFinite else {
            return
        }
        videoTrimStrip?.movePlayhead(to: at / whole)
        cell.stopIfPastTrim()
    }

    private func videoPlayheadMoved(to fraction: Double) {
        guard attachments.indices.contains(currPage), attachments[currPage].duration > 0 else {
            return
        }
        let whole = attachments[currPage].duration
        attachments[currPage].trimStart = min(max(attachments[currPage].trimStart, 0), whole)
        // The video stops the moment the marker is taken hold of: it carries on running otherwise,
        // and what is on screen then has nothing to do with where the marker is being put.
        if !isScrubbingVideo {
            isScrubbingVideo = true
            currentVideoCell()?.pauseVideo()
        }
        let at = whole * fraction
        currentVideoCell()?.startFrom = at
        currentVideoCell()?.showFrame(at: at)
    }

    private func videoTrimChanged(startFraction: Double, endFraction: Double) {
        guard attachments.indices.contains(currPage), attachments[currPage].duration > 0 else {
            return
        }
        let whole = attachments[currPage].duration
        attachments[currPage].trimStart = whole * startFraction
        attachments[currPage].trimEnd = whole * endFraction
        updateVideoInfoPill()
        bindVideoPlayback()
    }

    @objc private func toggleVideoMute() {
        guard attachments.indices.contains(currPage) else {
            return
        }
        attachments[currPage].isMuted.toggle()
        refreshVideoControls()
    }

    @objc private func chooseVideoFormat() {
        setVideoAsGIF(false)
    }

    @objc private func chooseGIFFormat() {
        setVideoAsGIF(true)
    }

    private func setVideoAsGIF(_ wanted: Bool) {
        guard attachments.indices.contains(currPage) else {
            return
        }
        attachments[currPage].asGIF = wanted
        refreshVideoControls()
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
                    thumbnailWidthConstraint?.constant = minWidth
                    view.layoutIfNeeded()
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
    
    private func cachedThumbnail(for url: URL) -> UIImage? {
        if let cached = videoThumbnailCache[url.absoluteString] {
            return cached
        }
        let image = thumbnail(url: url)
        if let image = image {
            videoThumbnailCache[url.absoluteString] = image
        }
        return image
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
                let previousPage = currPage
                currPage = page
                
                DispatchQueue.main.async { [self] in
                    refreshVideoControls()
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

                updateThumbnailSelection(previousPage: previousPage, animated: true)
            }
        }
    }

    // Fix: the strip was left exactly where it was whenever the pager moved - the call that
    // would have redrawn it is the commented-out reloadData this replaces. So the highlight
    // stayed on whichever thumbnail had it first, and with more than a few attachments the
    // one actually being previewed was often not even scrolled into view.
    private func updateThumbnailSelection(previousPage: Int, animated: Bool) {
        guard let thumbnailCollection = thumbnailCollection,
              currPage >= 0, currPage < attachments.count else {
            return
        }
        // Only the two that change - a full reloadData would rebuild every thumbnail on
        // every swipe.
        var toReload = [IndexPath(item: currPage, section: 0)]
        if previousPage >= 0, previousPage < attachments.count, previousPage != currPage {
            toReload.append(IndexPath(item: previousPage, section: 0))
        }
        thumbnailCollection.reloadItems(at: toReload)
        thumbnailCollection.scrollToItem(at: IndexPath(item: currPage, section: 0),
                                         at: .centeredHorizontally,
                                         animated: animated)
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

    // What has been decided about a video before it is sent. Kept on the attachment so that moving
    // between them and coming back finds the same choices.
    var duration: Double = 0
    var trimStart: Double = 0
    /// Zero until the far handle is moved, and then it means the same as "all of it".
    var trimEnd: Double = 0
    var isMuted = false
    var asGIF = false
    var videoBitrate: Double = 0
    var audioBitrate: Double = 0
    /// What the video will be encoded at when it is sent, which is the figure worth showing.
    var targetBitrate: Double = 0
    var stripFrames: [UIImage] = []

    /// Sound goes unless it has been turned off - and a gif has none to begin with.
    var carriesAudio: Bool {
        return !isMuted && !asGIF
    }

    var trimmedRange: ClosedRange<Double> {
        let end = trimEnd > 0 ? trimEnd : duration
        return trimStart...max(trimStart, end)
    }

    var trimmedDuration: Double {
        let range = trimmedRange
        return max(0, range.upperBound - range.lowerBound)
    }
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
    /// The part of the video that is being kept, if any. Playing stays inside it, so what is heard
    /// and seen is what is going to be sent.
    var keptRange: ClosedRange<Double>?
    /// Where playing starts from, which the strip above decides.
    var startFrom: Double = 0
    /// Told whenever playing starts or stops, so the marker on the strip can follow.
    var onPlaybackChanged: ((Bool) -> Void)?

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
    
    func playPause() {
        playPauseTapped()
    }

    @objc private func playPauseTapped() {
        guard let player = player else { return }
        if !isPlaying {
            // Fix: nothing could be heard even with the sound left on. The session is on whatever
            // category was last set - ambient, most of the time - and ambient is silenced by the
            // ring switch, so on a phone set to silent the video played to nobody. Playback is
            // what this is, and saying so is what makes it audible either way.
            if !player.isMuted {
                try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
                try? AVAudioSession.sharedInstance().setActive(true)
            }
            player.seek(to: CMTime(seconds: max(startFrom, keptRange?.lowerBound ?? 0), preferredTimescale: 600),
                        toleranceBefore: .zero, toleranceAfter: .zero)
            player.play()
            playPauseButton.isHidden = true
            isPlaying.toggle()
            onPlaybackChanged?(true)
        }
    }

    /// Stops where it is, without moving back to the beginning.
    func pauseVideo() {
        guard isPlaying else {
            return
        }
        player?.pause()
        isPlaying = false
        playPauseButton.isHidden = false
        onPlaybackChanged?(false)
    }

    /// Seeks without starting, so the picture can follow the marker being dragged.
    func showFrame(at seconds: Double) {
        player?.seek(to: CMTime(seconds: seconds, preferredTimescale: 600),
                     toleranceBefore: CMTime(seconds: 0.15, preferredTimescale: 600),
                     toleranceAfter: CMTime(seconds: 0.15, preferredTimescale: 600))
    }
    
    @objc private func videoDidEnd() {
        // Fix: this started the video again the moment it finished, so it never stopped - which is
        // not something anybody asked it to do, and it left the marker running in circles. It ends
        // where the trim begins, ready to be played again if that is wanted.
        guard let player = player else { return }
        player.pause()
        player.seek(to: CMTime(seconds: keptRange?.lowerBound ?? 0, preferredTimescale: 600))
        isPlaying = false
        playPauseButton.isHidden = false
        onPlaybackChanged?(false)
    }

    /// Called as the video runs. Stops it where the trim says to, rather than letting it run on
    /// into the part being cut away.
    func stopIfPastTrim() {
        guard isPlaying, let player = player, let range = keptRange else {
            return
        }
        guard CMTimeGetSeconds(player.currentTime()) >= range.upperBound else {
            return
        }
        player.pause()
        player.seek(to: CMTime(seconds: range.lowerBound, preferredTimescale: 600),
                    toleranceBefore: .zero, toleranceAfter: .zero)
        isPlaying = false
        playPauseButton.isHidden = false
        onPlaybackChanged?(false)
    }
    
    func stopVideo() {
        player?.pause()
        player?.seek(to: CMTime(seconds: keptRange?.lowerBound ?? 0, preferredTimescale: 600))
        isPlaying = false
        playPauseButton.isHidden = false
        onPlaybackChanged?(false)
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
