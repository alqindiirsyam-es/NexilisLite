//
//  ImagePicker.swift
//  Qmera
//
//  Created by Akhmad Al Qindi Irsyam on 08/09/21.
//

import UIKit

public protocol ImageVideoPickerDelegate: AnyObject {
    func didSelect(imagevideo: Any?)
}

open class ImageVideoPicker: NSObject {
    
    private let pickerController: UIImagePickerController
    private weak var presentationController: UIViewController?
    private weak var delegate: ImageVideoPickerDelegate?
    var isBlackCancelButton = false
    
    public init(presentationController: UIViewController, delegate: ImageVideoPickerDelegate) {
        self.pickerController = UIImagePickerController()
        
        super.init()
        
        self.presentationController = presentationController
        self.delegate = delegate
        
        self.pickerController.delegate = self
        self.pickerController.allowsEditing = false
    }
    
    enum Source {
        case imageAlbum
        case videoAlbum
        case imageCamera
        case videoCamera
    }
    
    func present(source sourceView: Source) {
        if UIBarButtonItem.appearance().titleTextAttributes(for: .normal) != nil {
            isBlackCancelButton = UIBarButtonItem.appearance().titleTextAttributes(for: .normal)?.values.first as! NSObject == UIColor.black
        }
        if !isBlackCancelButton {
            let cancelButtonAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black, NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16)]
            UIBarButtonItem.appearance().setTitleTextAttributes(cancelButtonAttributes , for: .normal)
        }
        if (sourceView == .imageAlbum) {
            self.pickerController.mediaTypes = ["public.image"]
            self.pickerController.sourceType = .savedPhotosAlbum
            self.pickerController.modalPresentationStyle = .custom
            self.presentationController?.present(self.pickerController, animated: true)
        } else if (sourceView == .videoAlbum) {
            self.pickerController.mediaTypes = ["public.movie"]
            self.pickerController.sourceType = .savedPhotosAlbum
            self.pickerController.videoQuality = .typeHigh
            self.pickerController.modalPresentationStyle = .custom
            self.presentationController?.present(self.pickerController, animated: true)
        } else if (sourceView == .imageCamera) {
            self.pickerController.mediaTypes = ["public.image"]
            self.pickerController.sourceType = .camera
            self.pickerController.modalPresentationStyle = .custom
            self.presentationController?.present(self.pickerController, animated: true)
        } else if (sourceView == .videoCamera) {
            self.pickerController.mediaTypes = ["public.movie"]
            self.pickerController.sourceType = .camera
            self.pickerController.videoQuality = .typeHigh
            self.pickerController.modalPresentationStyle = .custom
            self.presentationController?.present(self.pickerController, animated: true)
        }
    }
    
    private func pickerController(_ controller: UIImagePickerController, didSelect imagevideo: Any?) {
        if !isBlackCancelButton {
            let cancelButtonAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16)]
            UIBarButtonItem.appearance().setTitleTextAttributes(cancelButtonAttributes , for: .normal)
        }
        controller.dismiss(animated: false, completion: {
            self.delegate?.didSelect(imagevideo: imagevideo)
        })
    }
}

extension ImageVideoPicker: UIImagePickerControllerDelegate {
    
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.pickerController(picker, didSelect: nil)
    }
    
    public func imagePickerController(_ picker: UIImagePickerController,
                                      didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        self.pickerController(picker, didSelect: info)
    }
}

extension ImageVideoPicker: UINavigationControllerDelegate {
    
}
