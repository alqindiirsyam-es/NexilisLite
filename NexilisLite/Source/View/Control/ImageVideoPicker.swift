//
//  ImagePicker.swift
//  Qmera
//
//  Created by Akhmad Al Qindi Irsyam on 08/09/21.
//

import UIKit
import PhotosUI
import ImageIO

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
    
    public enum Source {
        case imageAlbum
        case videoAlbum
        case imageCamera
        case videoCamera
    }
    
    public func present(source sourceView: Source) {
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

// MARK: - Turning picked items into attachments

/// Fix: "Preparing..." used to walk the picked items one at a time on a background thread,
/// blocking on a semaphore between each - so five photos meant five loads back to back, and
/// a thread parked for all of them. Worse, several failure paths never signalled that
/// semaphore (a write that threw, an image that came back nil), and the ones that did still
/// had to satisfy `attachments.count == results.count` before the loader was allowed to go
/// away: one item failing left "Preparing..." on screen for good.
///
/// This loads every item at once, keeps their order, always reports back exactly once per
/// item, and reports progress - which matters most for the case that made this slow in the
/// first place: a photo or video shot on the camera that iCloud has since offloaded, where
/// most of the wait is the download coming back.
final class PickerAttachmentLoader {

    // What the picked image is loaded at. The send path resizes to 1280 anyway
    // (compressImageLikeWhatsApp), so decoding a 12MP camera photo at full size only to
    // throw most of it away is the expensive part being avoided here.
    private static let maxImagePixelSize: CGFloat = 2048

    private static let gifType = "com.compuserve.gif"
    private static let imageType = "public.image"
    private static let movieType = "public.movie"
    private static let quickTimeType = "com.apple.quicktime-movie"

    /// Returns the Progress covering the whole batch, so a caller that put a Cancel in front of the
    /// reader has something to cancel: cancelling it cancels the loads underneath, each of which
    /// then finishes with nothing and lets the batch complete rather than hanging.
    @discardableResult
    static func load(results: [PHPickerResult],
                     onProgress: @escaping (Double) -> Void,
                     completion: @escaping ([AttachmentItem]) -> Void) -> Progress {
        guard !results.isEmpty else {
            completion([])
            return Progress(totalUnitCount: 0)
        }
        // Slots, not appends: the items finish in whatever order they finish, and the order
        // they were picked in is the order they have to be sent in.
        var loaded = [AttachmentItem?](repeating: nil, count: results.count)
        let lock = NSLock()
        let group = DispatchGroup()
        let overall = Progress(totalUnitCount: Int64(results.count) * 100)
        var observation: NSKeyValueObservation?
        observation = overall.observe(\.fractionCompleted, options: [.new]) { progress, _ in
            let fraction = progress.fractionCompleted
            DispatchQueue.main.async {
                onProgress(fraction)
            }
        }

        for (index, result) in results.enumerated() {
            group.enter()
            let provider = result.itemProvider
            var hasFinished = false
            let finish: (AttachmentItem?) -> Void = { item in
                // Belt and braces: a provider calling back twice would unbalance the group.
                lock.lock()
                let alreadyDone = hasFinished
                hasFinished = true
                if !alreadyDone {
                    loaded[index] = item
                }
                lock.unlock()
                if !alreadyDone {
                    group.leave()
                }
            }

            if provider.hasItemConformingToTypeIdentifier(gifType) {
                let child = provider.loadDataRepresentation(forTypeIdentifier: gifType) { data, _ in
                    if let data = data {
                        finish(AttachmentItem(type: .gif, gif: data))
                    } else {
                        // Not really a gif after all - the picker offers that type for some
                        // animated items that are actually QuickTime movies.
                        loadQuickTimeFallback(provider: provider, finish: finish)
                    }
                }
                overall.addChild(child, withPendingUnitCount: 100)
            } else if provider.hasItemConformingToTypeIdentifier(imageType) {
                let child = provider.loadFileRepresentation(forTypeIdentifier: imageType) { url, _ in
                    guard let url = url, let image = downsampledImage(at: url) else {
                        finish(nil)
                        return
                    }
                    finish(AttachmentItem(type: .image, image: image))
                }
                overall.addChild(child, withPendingUnitCount: 100)
            } else if provider.hasItemConformingToTypeIdentifier(movieType) {
                let child = provider.loadFileRepresentation(forTypeIdentifier: movieType) { url, _ in
                    guard let url = url, let destination = copyIntoDocuments(url) else {
                        finish(nil)
                        return
                    }
                    finish(AttachmentItem(type: .video, videoURL: destination))
                }
                overall.addChild(child, withPendingUnitCount: 100)
            } else {
                overall.completedUnitCount += 100
                finish(nil)
            }
        }

        group.notify(queue: .main) {
            observation?.invalidate()
            observation = nil
            completion(overall.isCancelled ? [] : loaded.compactMap({ $0 }))
        }
        return overall
    }

    private static func loadQuickTimeFallback(provider: NSItemProvider, finish: @escaping (AttachmentItem?) -> Void) {
        guard provider.hasItemConformingToTypeIdentifier(quickTimeType) else {
            finish(nil)
            return
        }
        provider.loadFileRepresentation(forTypeIdentifier: quickTimeType) { url, _ in
            guard let url = url, let destination = copyIntoDocuments(url) else {
                finish(nil)
                return
            }
            finish(AttachmentItem(type: .video, videoURL: destination))
        }
    }

    // The URL a provider hands over is only valid inside its callback, so the file has to be
    // taken out of there before returning.
    private static func copyIntoDocuments(_ url: URL) -> URL? {
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        var nameFile = url.lastPathComponent
        if nameFile.contains("&uuid") || nameFile.isEmpty {
            nameFile = UUID().uuidString + ".mov"
        }
        let destinationURL = documentsDirectory.appendingPathComponent(nameFile)
        do {
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            try fileManager.copyItem(at: url, to: destinationURL)
            return destinationURL
        } catch {
            return nil
        }
    }

    // ImageIO decodes straight to the size asked for, so a 12MP HEIC never has to exist as a
    // 48MB bitmap on the way in - which is where most of the "Preparing..." on a camera photo
    // was going.
    private static func downsampledImage(at url: URL) -> UIImage? {
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxImagePixelSize
        ]
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            // Whatever it is, ImageIO could not read it - fall back to letting UIImage try.
            return (try? Data(contentsOf: url)).flatMap({ UIImage(data: $0) })
        }
        return UIImage(cgImage: cgImage)
    }
}
