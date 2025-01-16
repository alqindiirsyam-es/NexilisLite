//
//  PreviewAttachmentImageVideo.swift
//  Qmera
//
//  Created by Akhmad Al Qindi Irsyam on 08/09/21.
//

import UIKit
import AVKit
import AVFoundation

protocol PreviewAttachmentImageVideoDelegate : NSObjectProtocol {
    func sendChatFromPreviewImage(message_text: String, attachment_flag: String, image_id: String, video_id: String, thumb_id: String, viewController: UIViewController)
}

class PreviewAttachmentImageVideo: UIViewController, UIScrollViewDelegate, UITextViewDelegate {
    @IBOutlet var imagePreview: UIImageView!
    @IBOutlet var buttonSend: UIButton!
    @IBOutlet var textFieldSend: UITextView!
    @IBOutlet var buttonCancel: UIButton!
    @IBOutlet var constraintViewTextField: NSLayoutConstraint!
    @IBOutlet var heightTextFieldSend: NSLayoutConstraint!
    @IBOutlet var constraintButtonSend: NSLayoutConstraint!
    @IBOutlet var scrollViewImage: UIScrollView!
    @IBOutlet weak var buttonAckConfidential: UIButton!
    @IBOutlet weak var constraintLeftTextField: NSLayoutConstraint!
    @IBOutlet weak var constraintButtonAckCondential: NSLayoutConstraint!
    var imageVideoData: [UIImagePickerController.InfoKey: Any]?
    var image: UIImage?
    var currentTextTextField: String?
    var delegate: PreviewAttachmentImageVideoDelegate?
    var isHiddenTextField = false
    var fromCopy = false
    var isConfidential = false
    var isAck = false
    var isGroup = false
    var isCC = false
    
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
            imagePreview.image = image
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
            textFieldSend.backgroundColor = .white.withAlphaComponent(0.5)
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
            view.addGestureRecognizer(dismissKeyboard)
        }
        
        buttonCancel.circle()
        buttonCancel.backgroundColor = .secondaryColor.withAlphaComponent(0.4)
        buttonCancel.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
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
        let stack = self.presentingViewController as! UINavigationController
        let vc = stack.viewControllers[stack.viewControllers.count - 1]
        if vc is EditorPersonal {
            let editorVc = vc as! EditorPersonal
            editorVc.setAckConfidential(isAck: self.isAck, isConfidential: self.isConfidential)
        } else {
            let editorVc = vc as! EditorGroup
            editorVc.setAckConfidential(isAck: self.isAck, isConfidential: self.isConfidential)
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        textView.attributedText = textView.text.richText(isEditing: true)
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
        let cursorPosition = textView.caretRect(for: self.textFieldSend.selectedTextRange!.start).origin
        let currentLine = Int(cursorPosition.y / self.textFieldSend.font!.lineHeight)
        UIView.animate(withDuration: 0.3) {
            if currentLine == 0 {
                self.heightTextFieldSend.constant = 40
            } else if currentLine < 4 {
                self.heightTextFieldSend.constant = self.textFieldSend.contentSize.height// Padding
            }
        }
        return true
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
        if fromCopy || (imageVideoData![.mediaType] as! String == "public.image") {
            var originalImageName = ""
            if (fromCopy) {
                originalImageName = "\(Date().currentTimeMillis())_copyImage"
            } else if (imageVideoData![.imageURL] == nil) {
                originalImageName = "\(Date().currentTimeMillis())_takeImage"
            } else {
                let urlImage = (imageVideoData![.imageURL] as! NSURL).absoluteString
                originalImageName = (urlImage! as NSString).lastPathComponent
            }
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let compressedImageName = "THUMB-Nexilis_image_\(originalImageName)"
            let thumbName = "THUMB_Nexilis_image_\(originalImageName)"
            let fileURL = documentsDirectory.appendingPathComponent(compressedImageName)
            var compressedImage:Data?
            if (fromCopy) {
                compressedImage = image!.jpegData(compressionQuality:  1.0)
            } else {
                compressedImage = (imageVideoData![.originalImage] as! UIImage).jpegData(compressionQuality:  1.0)
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
            self.dismiss(animated: true, completion: nil)
            if (textFieldSend.text!.trimmingCharacters(in: .whitespacesAndNewlines) == "Send message".localized() && textFieldSend.textColor == UIColor.lightGray) {
                delegate!.sendChatFromPreviewImage(message_text: "", attachment_flag: "1", image_id: compressedImageName, video_id: "", thumb_id: thumbName, viewController: self)
            } else {
                delegate!.sendChatFromPreviewImage(message_text: textFieldSend.text!, attachment_flag: "1", image_id: compressedImageName, video_id: "", thumb_id: thumbName, viewController: self)
            }
        } else {
            guard var dataVideo = try? Data(contentsOf: imageVideoData![.mediaURL] as! URL) else {
                return
            }
            let sizeOfVideo = Double(dataVideo.count / 1048576)
            if (sizeOfVideo > 10.0) {
                let compressedURL = NSURL.fileURL(withPath: NSTemporaryDirectory() + UUID().uuidString + ".mp4")
                compressVideo(inputURL: imageVideoData![.mediaURL] as! URL,
                              outputURL: compressedURL) { exportSession in
                    guard let session = exportSession else {
                        return
                    }
                    
                    switch session.status {
                    case .unknown:
                        break
                    case .waiting:
                        break
                    case .exporting:
                        break
                    case .completed:
                        guard let compressedData = try? Data(contentsOf: compressedURL) else {
                            return
                        }
                        dataVideo = compressedData
                    case .failed:
                        break
                    case .cancelled:
                        break
                    @unknown default:
                        break
                    }
                }
            }
            let urlVideo = (imageVideoData![.mediaURL] as! NSURL).absoluteString
            let originalVideoName = (urlVideo! as NSString).lastPathComponent
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let renamedVideoName = "Nexilis_video_\(originalVideoName)"
            let thumbName = "THUMB_Nexilis_video_\(originalVideoName)"
            let fileURL = documentsDirectory.appendingPathComponent(renamedVideoName)
            if !FileManager.default.fileExists(atPath: fileURL.path) {
                do {
                    try dataVideo.write(to: fileURL)
                    //print("file saved")
                } catch {
                    //print("error saving file:", error)
                }
            }
            let dataThumbVideo = imagePreview.image!.jpegData(compressionQuality:  1.0)
            let fileURLTHUMB = documentsDirectory.appendingPathComponent(thumbName)
            if !FileManager.default.fileExists(atPath: fileURLTHUMB.path) {
                do {
                    try dataThumbVideo!.write(to: fileURLTHUMB)
                    //print("thumb saved")
                } catch {
                    //print("error saving file:", error)
                }
            }
            self.dismiss(animated: true, completion: nil)
            if (textFieldSend.text!.trimmingCharacters(in: .whitespacesAndNewlines) == "Send message".localized() && textFieldSend.textColor == UIColor.lightGray) {
                delegate!.sendChatFromPreviewImage(message_text: "", attachment_flag: "2", image_id: "", video_id: renamedVideoName, thumb_id: thumbName, viewController: self)
            } else {
                delegate!.sendChatFromPreviewImage(message_text: textFieldSend.text!, attachment_flag: "2", image_id: "", video_id: renamedVideoName, thumb_id: thumbName, viewController: self)
            }
        }
    }
    
    func compressVideo(inputURL: URL,
                       outputURL: URL,
                       handler:@escaping (_ exportSession: AVAssetExportSession?) -> Void) {
        let urlAsset = AVURLAsset(url: inputURL, options: nil)
        guard let exportSession = AVAssetExportSession(asset: urlAsset,
                                                       presetName: AVAssetExportPresetMediumQuality) else {
            handler(nil)
            
            return
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.exportAsynchronously {
            handler(exportSession)
        }
    }
    
    @objc func cancelTapped() {
        self.dismiss(animated: true, completion: nil)
    }
}
