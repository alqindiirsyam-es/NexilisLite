//
//  StringUtil.swift
//  Runner
//
//  Created by Yayan Dwi on 20/04/20.
//  Copyright © 2020 The Chromium Authors. All rights reserved.
//

import Foundation
import UIKit
import SDWebImage
import ImageIO
import MobileCoreServices
import CommonCrypto

extension Date {
    
    public func currentTimeMillis() -> Int {
        return Int(self.timeIntervalSince1970 * 1000)
    }
    
    func format(dateFormat: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = dateFormat
        return formatter.string(from: self)
    }
    
    var millisecondsSince1970:Int64 {
        return Int64((self.timeIntervalSince1970 * 1000.0).rounded())
    }
    
    public init(milliseconds:Int64) {
        self = Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1000)
    }
}

extension String {
    
    func toNormalString() -> String {
        let _source = self.replacingOccurrences(of: "+", with: "%20")
        if var result = _source.removingPercentEncoding {
            result = result.replacingOccurrences(of: "<NL>", with: "\n")
            result = result.replacingOccurrences(of: "<CR>", with: "\r")
            return decrypt(source: result)
        }
        return self
    }
    
    func toStupidString() -> String {
        if var result = self.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            result = result.replacingOccurrences(of: "\n", with: "<NL>")
            result = result.replacingOccurrences(of: "\r", with: "<CR>")
            result = result.replacingOccurrences(of: "+", with: "%2B")
            return result
        }
        return self
    }
    
    private func decrypt(source : String) -> String {
        if let result = source.removingPercentEncoding {
            return result
        }
        return source
    }
    
    public func matches(_ regex: String) -> Bool {
        return self.range(of: regex, options: .regularExpression, range: nil, locale: nil) != nil
    }
    
}

extension Int {
    
    func toHex() -> String {
        return String(format: "%02X", self)
    }
    
}

extension UIApplication {
    public static var appVersion: String? {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    }
    
    var rootViewController: UIViewController? {
        return UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.rootViewController
    }
    
    public var visibleViewController: UIViewController? {
        let keyWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
        if var topController = keyWindow?.rootViewController {
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            return topController
        }
        return nil
    }
}

extension UIView {
    
    public func anchor(top: NSLayoutYAxisAnchor? = nil,
                left: NSLayoutXAxisAnchor? = nil,
                bottom: NSLayoutYAxisAnchor? = nil,
                right: NSLayoutXAxisAnchor? = nil,
                paddingTop: CGFloat = 0,
                paddingLeft: CGFloat = 0,
                paddingBottom: CGFloat = 0,
                paddingRight: CGFloat = 0,
                centerX: NSLayoutXAxisAnchor? = nil,
                centerY: NSLayoutYAxisAnchor? = nil,
                width: CGFloat = 0,
                height: CGFloat = 0,
                minHeight: CGFloat = 0,
                maxHeight: CGFloat = 0,
                minWidth: CGFloat = 0,
                maxWidth: CGFloat = 0,
                dynamicLeft: Bool = false,
                dynamicRight: Bool = false) {
        
        translatesAutoresizingMaskIntoConstraints = false
        
        if let top = top {
            topAnchor.constraint(equalTo: top, constant: paddingTop).isActive = true
        }
        if let left = left {
            if dynamicLeft {
                leftAnchor.constraint(greaterThanOrEqualTo: left, constant: paddingLeft).isActive = true
            } else {
                leftAnchor.constraint(equalTo: left, constant: paddingLeft).isActive = true
            }
        }
        if let right = right {
            if dynamicRight {
                leftAnchor.constraint(lessThanOrEqualTo: right, constant: -paddingRight).isActive = true
            } else {
                rightAnchor.constraint(equalTo: right, constant: -paddingRight).isActive = true
            }
        }
        if let bottom = bottom {
            bottomAnchor.constraint(equalTo: bottom, constant: -paddingBottom).isActive = true
        }
        if let centerX = centerX {
            centerXAnchor.constraint(equalTo: centerX).isActive = true
        }
        if let centerY = centerY {
            centerYAnchor.constraint(equalTo: centerY).isActive = true
        }
        if height != 0 || minHeight != 0 || maxHeight != 0 {
            if minHeight != 0 && maxHeight != 0 {
                heightAnchor.constraint(greaterThanOrEqualToConstant: minHeight).isActive = true
                heightAnchor.constraint(lessThanOrEqualToConstant: maxHeight).isActive = true
            } else if minHeight != 0 && maxHeight == 0 {
                heightAnchor.constraint(greaterThanOrEqualToConstant: minHeight).isActive = true
            } else if minHeight == 0 && maxHeight != 0 {
                heightAnchor.constraint(lessThanOrEqualToConstant: maxHeight).isActive = true
            } else {
                heightAnchor.constraint(equalToConstant: height).isActive = true
            }
        }
        if width != 0 || minWidth != 0 || maxWidth != 0 {
            if minWidth != 0 && maxWidth != 0 {
                heightAnchor.constraint(greaterThanOrEqualToConstant: minWidth).isActive = true
                heightAnchor.constraint(lessThanOrEqualToConstant: maxWidth).isActive = true
            } else if minWidth != 0 && maxWidth == 0 {
                heightAnchor.constraint(greaterThanOrEqualToConstant: minWidth).isActive = true
            } else if minWidth == 0 && maxWidth != 0 {
                heightAnchor.constraint(lessThanOrEqualToConstant: maxWidth).isActive = true
            } else {
                widthAnchor.constraint(equalToConstant: width).isActive = true
            }
        }
    }
    
    public func addTopBorder(with color: UIColor?, andWidth borderWidth: CGFloat, view: UIView = UIView()) {
        let border = view
        border.backgroundColor = color
        border.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
        border.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: borderWidth)
        addSubview(border)
    }

    public func addBottomBorder(with color: UIColor?, andWidth borderWidth: CGFloat, x: CGFloat = 0, view: UIView = UIView()) {
        let border = view
        border.backgroundColor = color
        border.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        border.frame = CGRect(x: x, y: frame.size.height - borderWidth, width: frame.size.width, height: borderWidth)
        addSubview(border)
    }

    public func addLeftBorder(with color: UIColor?, andWidth borderWidth: CGFloat) {
        let border = UIView()
        border.backgroundColor = color
        border.frame = CGRect(x: 0, y: 0, width: borderWidth, height: frame.size.height)
        border.autoresizingMask = [.flexibleHeight, .flexibleRightMargin]
        addSubview(border)
    }

    public func addRightBorder(with color: UIColor?, andWidth borderWidth: CGFloat) {
        let border = UIView()
        border.backgroundColor = color
        border.autoresizingMask = [.flexibleHeight, .flexibleLeftMargin]
        border.frame = CGRect(x: frame.size.width - borderWidth, y: 0, width: borderWidth, height: frame.size.height)
        addSubview(border)
    }
    
    public func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 0.0);
        image.draw(in: CGRect(x: 0, y: 0, width: targetSize.width, height: targetSize.height))
        let newImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
    
}

extension UIViewController {
    
    var previousViewController: UIViewController? {
        guard let navigationController = navigationController else { return nil }
        let count = navigationController.viewControllers.count
        return count < 2 ? nil : navigationController.viewControllers[count - 2]
    }
    
}

extension UIImage {
    class func gifImageWithData(_ data: Data) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }
        
        let frameCount = CGImageSourceGetCount(source)
        var images: [UIImage] = []
        
        for i in 0..<frameCount {
            if let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) {
                let image = UIImage(cgImage: cgImage)
                images.append(image)
            }
        }
        
        return UIImage.animatedImage(with: images, duration: 0.0)
    }
    
    func gifData() -> Data? {
        guard let cgImages = self.images?.compactMap({ $0.cgImage }) else {
            return nil
        }

        let frameProperties = [kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFDelayTime as String: 0.1]] // Adjust delay time if necessary

        let destinationData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(destinationData as CFMutableData, kUTTypeGIF, cgImages.count, nil) else {
            return nil
        }

        let framePropertiesPointer = UnsafeMutablePointer<NSDictionary>.allocate(capacity: cgImages.count)
        defer {
            framePropertiesPointer.deallocate()
        }
        for i in 0..<cgImages.count {
            framePropertiesPointer[i] = frameProperties as NSDictionary
        }

        CGImageDestinationSetProperties(destination, [kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFLoopCount as String: 0]] as CFDictionary)
        for image in cgImages {
            CGImageDestinationAddImage(destination, image, framePropertiesPointer.pointee)
        }

        guard CGImageDestinationFinalize(destination) else {
            return nil
        }

        return destinationData as Data
    }
    
    public func resize(target: CGSize) -> UIImage {
        // Determine the scale factor that preserves aspect ratio
        let widthRatio = target.width / size.width
        let heightRatio = target.height / size.height
        
        let scaleFactor = min(widthRatio, heightRatio)
        
        // Compute the new image size that preserves aspect ratio
        let scaledImageSize = CGSize(
            width: size.width * scaleFactor,
            height: size.height * scaleFactor
        )
        
        // Draw and return the resized UIImage
        let renderer = UIGraphicsImageRenderer(
            size: scaledImageSize
        )
        
        let scaledImage = renderer.image { _ in
            self.draw(in: CGRect(
                origin: .zero,
                size: scaledImageSize
            ))
        }
        
        return scaledImage
    }
    
    static func imageWithColor(color: UIColor, size: CGSize) -> UIImage? {
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        UIRectFill(rect)
        guard let image: UIImage = UIGraphicsGetImageFromCurrentImageContext() else {
            return nil
        }
        UIGraphicsEndImageContext()
        return image
    }
    
    func mimeType() -> String? {
        guard let imageData = self.pngData() else {
            return nil
        }

        let byteArray = [UInt8](imageData)
        
        if byteArray.starts(with: [0xFF, 0xD8, 0xFF]) {
            return "image/jpeg"
        } else if byteArray.starts(with: [0x89, 0x50, 0x4E, 0x47]) {
            return "image/png"
        } else if byteArray.starts(with: [0x47, 0x49, 0x46, 0x38]) {
            return "image/gif"
        } else if byteArray.starts(with: [0x49, 0x49, 0x2A, 0x00]) || byteArray.starts(with: [0x4D, 0x4D, 0x00, 0x2A]) {
            return "image/tiff"
        }
        return nil
    }
    
    convenience init?(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) {
        UIGraphicsBeginImageContext(size)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }

        context.setFillColor(color.cgColor)
        context.fill(CGRect(origin: .zero, size: size))

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        guard let cgImage = image?.cgImage else { return nil }
        self.init(cgImage: cgImage)
    }

}

extension Data {
    func mimeType() -> String? {
        let byteArray = [UInt8](self)
        
        if byteArray.starts(with: [0xFF, 0xD8, 0xFF]) {
            return "image/jpeg"
        } else if byteArray.starts(with: [0x89, 0x50, 0x4E, 0x47]) {
            return "image/png"
        } else if byteArray.starts(with: [0x47, 0x49, 0x46, 0x38]) {
            return "image/gif"
        } else if byteArray.starts(with: [0x49, 0x49, 0x2A, 0x00]) || byteArray.starts(with: [0x4D, 0x4D, 0x00, 0x2A]) {
            return "image/tiff"
        } else if byteArray.starts(with: [0x25, 0x50, 0x44, 0x46]) {
            return "application/pdf"
        } else if byteArray.starts(with: [0x50, 0x4B, 0x03, 0x04]) {
            return "application/zip"
        }
        return nil
    }
}

extension UIImage {
    
    var isPortrait:  Bool    { size.height > size.width }
    var isLandscape: Bool    { size.width > size.height }
    var breadth:     CGFloat { min(size.width, size.height) }
    var breadthSize: CGSize  { .init(width: breadth, height: breadth) }
    var breadthRect: CGRect  { .init(origin: .zero, size: breadthSize) }
    public var circleMasked: UIImage? {
        guard let cgImage = cgImage?
                .cropping(to: .init(origin: .init(x: isLandscape ? ((size.width-size.height)/2).rounded(.down) : 0,
                                                  y: isPortrait  ? ((size.height-size.width)/2).rounded(.down) : 0),
                                    size: breadthSize)) else { return nil }
        let format = imageRendererFormat
        format.opaque = false
        return UIGraphicsImageRenderer(size: breadthSize, format: format).image { _ in
            UIBezierPath(ovalIn: breadthRect).addClip()
            UIImage(cgImage: cgImage, scale: format.scale, orientation: imageOrientation)
                .draw(in: .init(origin: .zero, size: breadthSize))
        }
    }
    
}

extension NSObject {
    
    private static var urlStore = [String:String]()

    public func getImage(name url: String, placeholderImage: UIImage? = nil, isCircle: Bool = false, tableView: UITableView? = nil, indexPath: IndexPath? = nil, completion: @escaping (Bool, Bool, UIImage?)->()) {
        let tmpAddress = String(format: "%p", unsafeBitCast(self, to: Int.self))
        type(of: self).urlStore[tmpAddress] = url
        if url.isEmpty {
            completion(false, false, placeholderImage)
            return
        }
        do {
            let documentDir = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let file = documentDir.appendingPathComponent(url)
            if FileManager().fileExists(atPath: file.path) {
                let image = UIImage(contentsOfFile: file.path)?.sd_resizedImage(with: CGSize(width: 400, height: 400), scaleMode: .aspectFill)
                completion(true, false, isCircle ? image?.circleMasked : image)
            } else if var tempData = try FileEncryption.shared.readSecure(filename: url) {
                let dataDecrypt = FileEncryption.shared.decryptFileFromServer(data: tempData)
                if dataDecrypt != nil {
                    tempData = dataDecrypt!
                }
                let image = UIImage(data: tempData)?.sd_resizedImage(with: CGSize(width: 400, height: 400), scaleMode: .aspectFill)
//                FileEncryption.shared.wipeData(&tempData)
                completion(true, true, isCircle ? image?.circleMasked : image)
            } else {
                completion(false, false, placeholderImage)
                Download().startHTTP(forKey: url) { (name, progress) in
                    guard progress == 100 else {
                        return
                    }
                    
                    DispatchQueue.main.async {
                        if type(of: self).urlStore[tmpAddress] == name && tableView == nil {
                            if FileManager().fileExists(atPath: file.path) {
                                let image = UIImage(contentsOfFile: file.path)?.sd_resizedImage(with: CGSize(width: 400, height: 400), scaleMode: .aspectFill)
                                completion(true, true, isCircle ? image?.circleMasked : image)
                            } else if FileEncryption.shared.isSecureExists(filename: url) {
                                do {
                                    if var imageData = try FileEncryption.shared.readSecure(filename: url) {
                                        let dataDecrypt = FileEncryption.shared.decryptFileFromServer(data: imageData)
                                        if dataDecrypt != nil {
                                            imageData = dataDecrypt!
                                        }
                                        let image = UIImage(data: imageData)?.sd_resizedImage(with: CGSize(width: 400, height: 400), scaleMode: .aspectFill)
                                        completion(true, true, isCircle ? image?.circleMasked : image)
                                    }
                                } catch {
                                    
                                }
                            }
                        }
                        guard let tableView = tableView else { return }
                        tableView.beginUpdates()
                        if let indexPath = indexPath,
                           indexPath.section < tableView.numberOfSections,
                           indexPath.row < tableView.numberOfRows(inSection: indexPath.section) {
                            tableView.reloadRows(at: [indexPath], with: .none)
                        }
                        tableView.endUpdates()
                    }
                }
            }
        } catch {
            completion(false, false, placeholderImage)
            Download().startHTTP(forKey: url) { (name, progress) in
                guard progress == 100 else {
                    return
                }
                
                DispatchQueue.main.async {
                    guard let tableView = tableView else { return }
                    tableView.beginUpdates()
                    if let indexPath = indexPath,
                       indexPath.section < tableView.numberOfSections,
                       indexPath.row < tableView.numberOfRows(inSection: indexPath.section) {
                        tableView.reloadRows(at: [indexPath], with: .none)
                    }
                    tableView.endUpdates()
                }
            }
        }
    }
    
    func loadImage(named: String, placeholderImage: UIImage?, completion: @escaping (UIImage?, Bool) -> ()) {
        guard !named.isEmpty else {
            completion(placeholderImage, true)
            return
        }
        SDWebImageManager.shared.loadImage(with: URL.palioImage(named: named), options: .highPriority, progress: .none) { image, data, error, type, finish, url in
            completion(image, finish)
        }
    }
    
    public func deleteAllRecordDatabase() {
        Database.shared.database?.inTransaction({ fmdb, rollback in
            do {
                _ = Database.shared.deleteRecord(fmdb: fmdb, table: "BUDDY", _where: "")
                _ = Database.shared.deleteRecord(fmdb: fmdb, table: "GROUPZ", _where: "")
                _ = Database.shared.deleteRecord(fmdb: fmdb, table: "MESSAGE", _where: "")
                _ = Database.shared.deleteRecord(fmdb: fmdb, table: "GROUPZ_MEMBER", _where: "")
                _ = Database.shared.deleteRecord(fmdb: fmdb, table: "DISCUSSION_FORUM", _where: "")
                _ = Database.shared.deleteRecord(fmdb: fmdb, table: "POST", _where: "")
                _ = Database.shared.deleteRecord(fmdb: fmdb, table: "MESSAGE_STATUS", _where: "")
                _ = Database.shared.deleteRecord(fmdb: fmdb, table: "MESSAGE_SUMMARY", _where: "")
                _ = Database.shared.deleteRecord(fmdb: fmdb, table: "OUTGOING", _where: "")
                _ = Database.shared.deleteRecord(fmdb: fmdb, table: "FOLLOW", _where: "")
                _ = Database.shared.deleteRecord(fmdb: fmdb, table: "MESSAGE_FAVORITE", _where: "")
                _ = Database.shared.deleteRecord(fmdb: fmdb, table: "LINK_PREVIEW", _where: "")
                _ = Database.shared.deleteRecord(fmdb: fmdb, table: "PULL_DB", _where: "")
                _ = Database.shared.deleteRecord(fmdb: fmdb, table: "PREFS", _where: "")
                _ = Database.shared.deleteRecord(fmdb: fmdb, table: "CALL_CENTER_HISTORY", _where: "")
                _ = Database.shared.deleteRecord(fmdb: fmdb, table: "FORM_DATA", _where: "")
                _ = Database.shared.deleteRecord(fmdb: fmdb, table: "TASK_PIC", _where: "")
                _ = Database.shared.deleteRecord(fmdb: fmdb, table: "TASK_DETAIL", _where: "")
            } catch {
                rollback.pointee = true
                print("Access database error: \(error.localizedDescription)")
            }
        })
        Utils.setFinishInitPrefs(value: false)
    }
    
}

extension URL {
    
    static func palioImage(named: String) -> URL? {
        return URL(string: Utils.getURLBase() + "filepalio/image/\(named)")
    }
    
}

extension UIColor {
    public static var mainColor: UIColor {
        return renderColor(hex: "#046cfc")
    }
    
    public static var borderTabColor: UIColor {
        return renderColor(hex: "#c4e4f4")
    }
    
    public static var nxColor: UIColor {
        return renderColor(hex: "#04ecfc")
    }
    
    public static var secondaryColor: UIColor {
        return renderColor(hex: "#FAFAFF")
    }
    
    public static var blackDarkMode: UIColor {
        return renderColor(hex: "#262626")
    }
    
    public static var orangeColor: UIColor {
        return renderColor(hex: "#FFA03E")
    }
    
    public static var orangeBNI: UIColor {
        return renderColor(hex: "#EE6600")
    }
    
    public static var greenColor: UIColor {
        return renderColor(hex: "#C7EA46")
    }
    
    public static var whiteBubbleColor: UIColor {
        if UIApplication.shared.visibleViewController?.traitCollection.userInterfaceStyle == .dark {
            return blackDarkMode
        }
        return renderColor(hex: "#F5F5F5")
    }
    
    public static var grayTitleColor: UIColor {
        return renderColor(hex: "#5A5A5A")
    }
    
    public static var docColor: UIColor {
        return renderColor(hex: "#798F9A")
    }
    
    public static var mentionColor: UIColor {
        return UIApplication.shared.visibleViewController?.traitCollection.userInterfaceStyle == .dark ? renderColor(hex: "#f6fcae") : renderColor(hex: "#53bdea")
    }
    
    public static var blueBubbleColor: UIColor {
        if UIApplication.shared.visibleViewController?.traitCollection.userInterfaceStyle == .dark {
            return renderColor(hex: "#367dd9")
        }
        return renderColor(hex: "#C5D1E1")
    }
    
    public static var officialColor: UIColor {
        return renderColor(hex: "#4c87ef")
    }
    
    public static var verifiedColor: UIColor {
        return renderColor(hex: "#00b333")
    }
    
    public static var ccColor: UIColor {
        return renderColor(hex: "#FFF1A353")
    }
    
    public static var internalColor: UIColor {
        return renderColor(hex: "#ff0000")
    }
    
    public static var blueTextField: UIColor {
        return renderColor(hex: "#4c92d2")
    }
    
    public static var whatsappGreenColor: UIColor {
        return renderColor(hex: "#25D366")
    }
    
    public static var whatsappGreenTitleColor: UIColor {
        return renderColor(hex: "#295C3B")
    }
    
    public static var whatsappGreenLightColor: UIColor {
        return renderColor(hex: "#E5FCE4")
    }
    
    public class func renderColor(hex: String) -> UIColor {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }

        if ((cString.count) != 6) {
            return UIColor.gray
        }

        var rgbValue:UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)

        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
}

extension UIView {
    
    public func circle() {
        layer.cornerRadius = 0.5 * bounds.size.width
        clipsToBounds = true
    }
    
    public func maxCornerRadius() -> CGFloat {
        return (self.frame.width > self.frame.height) ? self.frame.height / 2 : self.frame.width / 2
    }
    
}

extension String {
    
    public func localized(uppercased: Bool = false) -> String {
        if let _ : String = SecureUserDefaults.shared.value(forKey: "i18n_language") {} else {
            // we set a default, just in case
            let langDefault = UserDefaults.standard.stringArray(forKey: "AppleLanguages")
            if langDefault![0].contains("id") {
                SecureUserDefaults.shared.set("id", forKey: "i18n_language")
            } else {
                SecureUserDefaults.shared.set("en", forKey: "i18n_language")
            }
        }
        let lang: String = SecureUserDefaults.shared.value(forKey: "i18n_language") ?? ""
        let bundle = Bundle.resourceBundle(for: Nexilis.self).path(forResource: lang, ofType: "lproj")
        let bundlePath = Bundle(path: bundle!)
        let result = NSLocalizedString(
            self,
            tableName: "Localizable",
            bundle: bundlePath!,
            value: self,
            comment: self)
        if uppercased {
            return result.uppercased()
        }
        return result
    }
    
}

extension UIViewController {
    
    public func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 0.0);
        image.draw(in: CGRect(x: 0, y: 0, width: targetSize.width, height: targetSize.height))
        let newImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
    
}

extension UITextView {

    enum ShouldChangeCursor {
        case incrementCursor
        case preserveCursor
    }

    func preserveCursorPosition(withChanges mutatingFunction: (UITextPosition?) -> (ShouldChangeCursor)) {

        //save the cursor positon
        var cursorPosition: UITextPosition? = nil
        if let selectedRange = self.selectedTextRange {
            let offset = self.offset(from: self.beginningOfDocument, to: selectedRange.start)
            cursorPosition = self.position(from: self.beginningOfDocument, offset: offset)
        }

        //make mutaing changes that may reset the cursor position
        let shouldChangeCursor = mutatingFunction(cursorPosition)

        //restore the cursor
        if var cursorPosition = cursorPosition {

            if shouldChangeCursor == .incrementCursor {
                cursorPosition = self.position(from: cursorPosition, offset: 1) ?? cursorPosition
            }

            if let range = self.textRange(from: cursorPosition, to: cursorPosition) {
                self.selectedTextRange = range
            }
        }

    }

}

extension String {
    
    public func substring(from: Int?, to: Int?) -> String {
        if let start = from {
            guard start < self.count else {
                return ""
            }
        }
        
        if let end = to {
            guard end >= 0 else {
                return ""
            }
        }
        
        if let start = from, let end = to {
            guard end - start >= 0 else {
                return ""
            }
        }
        
        let startIndex: String.Index
        if let start = from, start >= 0 {
            startIndex = self.index(self.startIndex, offsetBy: start)
        } else {
            startIndex = self.startIndex
        }
        
        let endIndex: String.Index
        if let end = to, end >= 0, end < self.count {
            endIndex = self.index(self.startIndex, offsetBy: end + 1)
        } else {
            endIndex = self.endIndex
        }
        
        return String(self[startIndex ..< endIndex])
    }
    
    static public func offset() -> CGFloat{
        guard let fontSize = Int(SecureUserDefaults.shared.value(forKey: "font_size") ?? "0") else { return 0 }
        return CGFloat(fontSize)
    }
    
    public func richText(
        isEditing: Bool = false,
        isSearching: Bool = false,
        textSearch: String = "",
        group_id: String = "",
        listMentionInTextField: [User] = []
    ) -> NSMutableAttributedString {
        
        let font = UIFont.systemFont(ofSize: 12 + String.offset())
        let boldFont = UIFont.boldSystemFont(ofSize: 12 + String.offset())
        let italicFont = UIFont.italicSystemFont(ofSize: 12 + String.offset())
        let boldItalicFont = UIFont.systemFont(ofSize: 12 + String.offset(), weight: .semibold)
        
        let textUTF8 = self
        let finalText = NSMutableAttributedString(string: textUTF8, attributes: [.font: font])
        
        let formattingRules: [(String, [NSAttributedString.Key: Any])] = [
            ("_", [.font: italicFont]), // Italic
            ("*", [.font: boldFont]), // Bold
            ("~", [.strikethroughStyle: NSUnderlineStyle.single.rawValue]),
            ("^", [.underlineStyle: NSUnderlineStyle.single.rawValue]),
            ("$", [.font: italicFont, .foregroundColor: UIColor.darkGray]) // Italic + Gray for $
        ]

        for (sign, attributes) in formattingRules {
            applyTextFormatting(to: finalText, sign: sign, attributes: attributes, isEditing: isEditing)
        }
        
        processMentions(in: finalText, groupID: group_id, isEditing: isEditing)
        
        if isSearching {
            highlightSearchText(in: finalText, searchText: textSearch)
        }
        
        return finalText
    }

    // MARK: - Helper Functions

    private func applyTextFormatting(
        to text: NSMutableAttributedString,
        sign: String,
        attributes: [NSAttributedString.Key: Any],
        isEditing: Bool
    ) {
        let escapedSign = NSRegularExpression.escapedPattern(for: sign)
        let pattern = "\(escapedSign)(.+?)\(escapedSign)" // Ensure sign is correctly escaped in regex
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return }

        let matches = regex.matches(in: text.string, options: [], range: NSRange(location: 0, length: text.length))

        for match in matches.reversed() { // Iterate in reverse to prevent index shifting
            let fullRange = match.range
            let textRange = match.range(at: 1)

            // Apply the desired formatting
            for (key, value) in attributes {
                text.addAttribute(key, value: value, range: textRange)
            }

            if !isEditing {
                // Remove formatting characters (signs)
                text.replaceCharacters(in: NSRange(location: fullRange.upperBound - sign.count, length: sign.count), with: "")
                text.replaceCharacters(in: NSRange(location: fullRange.lowerBound, length: sign.count), with: "")
            } else {
                // Change color of formatting characters (grayed out)
                text.addAttribute(.foregroundColor, value: UIColor.gray, range: NSRange(location: fullRange.lowerBound, length: sign.count))
                text.addAttribute(.foregroundColor, value: UIColor.gray, range: NSRange(location: fullRange.upperBound - sign.count, length: sign.count))
            }
        }
    }

    private func processMentions(in text: NSMutableAttributedString, groupID: String, isEditing: Bool) {
        let regex = try? NSRegularExpression(pattern: "@(\\w+)", options: [])
        let matches = regex?.matches(in: text.string, options: [], range: NSRange(location: 0, length: text.length)) ?? []

        for match in matches.reversed() {
            let range = match.range(at: 1)
            let username = (text.string as NSString).substring(with: range)
            
            if let member = Member.getMember(f_pin: username) {
                let fullName = "\(member.firstName) \(member.lastName)".trimmingCharacters(in: .whitespaces)
                text.replaceCharacters(in: range, with: fullName)
                
                if !groupID.isEmpty, Member.getMemberInGroup(f_pin: username, group_id: groupID) != nil {
                    let newRange = (text.string as NSString).range(of: "@\(fullName)")
                    text.addAttribute(.foregroundColor, value: UIColor.mentionColor, range: newRange)
                }
            }
        }
    }

    private func highlightSearchText(in text: NSMutableAttributedString, searchText: String) {
        let range = (text.string as NSString).range(of: searchText, options: .caseInsensitive)
        if range.location != NSNotFound {
            text.addAttribute(.backgroundColor, value: UIColor.systemYellow, range: range)
        }
    }
    
    func distance(of index: String.Index) -> Int? {
        return utf16.distance(from: startIndex, to: index)
    }
    
}

extension UIFont {
    var bold: UIFont {
        return with(traits: .traitBold)
    } // bold
    
    var italic: UIFont {
        return with(traits: .traitItalic)
    } // italic
    
    func with(traits: UIFontDescriptor.SymbolicTraits) -> UIFont {
        guard let descriptor = self.fontDescriptor.withSymbolicTraits(traits) else {
            return self
        } // guard
        
        return UIFont(descriptor: descriptor, size: 0)
    } // with(traits:)
}

extension UILabel {
    public func set(image: UIImage, with text: String, size: CGFloat, y: CGFloat) {
        let attachment = NSTextAttachment()
        attachment.image = image
        attachment.bounds = CGRect(x: 0, y: y, width: size, height: size)
        let attachmentStr = NSAttributedString(attachment: attachment)
        
        let mutableAttributedString = NSMutableAttributedString()
        mutableAttributedString.append(attachmentStr)
        
        let textString = NSAttributedString(string: text, attributes: [.font: self.font!])
        mutableAttributedString.append(textString)
        
        self.attributedText = mutableAttributedString
    }
    
    public func setAttributeText(image: UIImage, with textMutable: NSAttributedString, size: CGFloat, y: CGFloat) {
        let attachment = NSTextAttachment()
        attachment.image = image
        attachment.bounds = CGRect(x: 0, y: y, width: size, height: size)
        let attachmentStr = NSAttributedString(attachment: attachment)
        
        let mutableAttributedString = NSMutableAttributedString()
        mutableAttributedString.append(attachmentStr)
        
        mutableAttributedString.append(textMutable)
        
        self.attributedText = mutableAttributedString
    }
}

extension Bundle {

    public static func resourceBundle(for frameworkClass: AnyClass) -> Bundle {
        let frameworkBundle = Bundle(for: frameworkClass)
        guard let resourceBundleURL = frameworkBundle.url(forResource: "NexilisLite", withExtension: "bundle"),
              let resourceBundle = Bundle(url: resourceBundleURL) else {
            return frameworkBundle
        }
        return resourceBundle
    }
    
    public static func resourcesMediaBundle(for frameworkClass: AnyClass) -> Bundle {
        let frameworkBundle = Bundle(for: frameworkClass)

        guard let resourceBundleURL = frameworkBundle.url(forResource: "NexilisLiteResources", withExtension: "bundle"),
              let resourceBundle = Bundle(url: resourceBundleURL) else {
            return frameworkBundle
        }

        return resourceBundle
    }
    
}

//extension UIFont {
//
//    static func register(from url: URL) throws {
//        guard let fontDataProvider = CGDataProvider(url: url as CFURL) else {
//            throw fatalError("Could not create font data provider for \(url).")
//        }
//        let font = CGFont(fontDataProvider)
//        var error: Unmanaged<CFError>?
//        guard CTFontManagerRegisterGraphicsFont(font!, &error) else {
//            throw error!.takeUnretainedValue()
//        }
//    }
//
//}

extension UIButton {
    private func actionHandleBlock(action:(() -> Void)? = nil) {
        struct __ {
            static var action :(() -> Void)?
        }
        if action != nil {
            __.action = action
        } else {
            __.action?()
        }
    }
    
    @objc private func triggerActionHandleBlock() {
        self.actionHandleBlock()
    }
    
    public func actionHandle(controlEvents control :UIControl.Event, ForAction action:@escaping () -> Void) {
        self.actionHandleBlock(action: action)
        self.addTarget(self, action: #selector(self.triggerActionHandleBlock), for: control)
    }
    
    public func setImageRightOfText(image: UIImage?, for state: UIControl.State) {
        self.setImage(image, for: state)
        self.titleEdgeInsets = UIEdgeInsets(top: 0, left: -((image?.size.width ?? 0) + 5), bottom: 0, right: (image?.size.width ?? 0))
        self.imageEdgeInsets = UIEdgeInsets(top: 10, left: (self.titleLabel?.frame.size.width ?? 0) + 90, bottom: 10, right: -((self.titleLabel?.frame.size.width ?? 0) + 5))
    }
}

extension UINavigationController {
    func replaceAllViewController(with viewController: UIViewController, animated: Bool) {
        pushViewController(viewController, animated: animated)
        viewControllers.removeSubrange(1...viewControllers.count - 2)
    }
    
    var rootViewController : UIViewController? {
        return viewControllers.first
    }
    
    func popViewController(animated: Bool, completion: @escaping () -> Void) {
        popViewController(animated: animated)

        if animated, let coordinator = transitionCoordinator {
            coordinator.animate(alongsideTransition: nil) { _ in
                completion()
            }
        } else {
            completion()
        }
    }
}

extension UIImageView {

    private static var taskKey = 0
    private static var urlKey = 0

    private var currentTask: URLSessionTask? {
        get { return objc_getAssociatedObject(self, &UIImageView.taskKey) as? URLSessionTask }
        set { objc_setAssociatedObject(self, &UIImageView.taskKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    private var currentURL: URL? {
        get { return objc_getAssociatedObject(self, &UIImageView.urlKey) as? URL }
        set { objc_setAssociatedObject(self, &UIImageView.urlKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    public func loadImageAsync(with urlString: String?, isGif: Bool = false) {
        // cancel prior task, if any

        weak var oldTask = currentTask
        currentTask = nil
        oldTask?.cancel()

        // reset imageview's image

        self.image = nil

        // allow supplying of `nil` to remove old image and then return immediately

        guard let urlString = urlString else { return }

        // check cache
        
        if isGif, let cachedImageGif = ImageCache.shared.imageGif(forKey: urlString) {
            guard let gifImage = UIImage.gifImageWithData(Data(referencing: cachedImageGif)) else {
                print("Failed to create the GIF image.")
                return
            }
            self.image = gifImage
            return
        }

        if let cachedImage = ImageCache.shared.image(forKey: urlString) {
            self.image = cachedImage
            return
        }

        // download

        let url = URL(string: urlString)!
        currentURL = url
        let urlConfig = URLSessionConfiguration.default
        let sessionDelegate = SelfSignedURLSessionDelegate()
        let session = URLSession(configuration: urlConfig, delegate: sessionDelegate, delegateQueue: nil)
        let task = session.dataTask(with: url) { [weak self] data, response, error in
            self?.currentTask = nil

            //error handling

            if let error = error {
                // don't bother reporting cancelation errors

                if (error as NSError).domain == NSURLErrorDomain && (error as NSError).code == NSURLErrorCancelled {
                    return
                }

                //print(error)
                return
            }

            guard let data = data else {
                //print("unable to extract image")
                return
            }
            
            let downloadedImage = UIImage(data: data)
            if isGif {
                ImageCache.shared.saveGif(data: NSData(data: data), forKey: urlString)
            } else {
                if downloadedImage != nil {
                    ImageCache.shared.save(image: downloadedImage!, forKey: urlString)
                }
            }

            if url == self?.currentURL {
                DispatchQueue.main.async {
                    if isGif {
                        guard let gifImage = UIImage.gifImageWithData(data) else {
                            print("Failed to create the GIF image.")
                            return
                        }
                        self?.image = gifImage
                    } else {
                        self?.image = downloadedImage
                    }
                }
            }
        }

        // save and start new task

        currentTask = task
        task.resume()
    }
    
    private func actionHandleBlock(action:(() -> Void)? = nil) {
        struct __ {
            static var action :(() -> Void)?
        }
        if action != nil {
            __.action = action
        } else {
            __.action?()
        }
    }
    
    @objc private func triggerActionHandleBlock() {
        self.actionHandleBlock()
    }
    
    func actionHandle(controlEvents control :UIControl.Event, ForAction action:@escaping () -> Void) {
        self.actionHandleBlock(action: action)
        self.isUserInteractionEnabled = true
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.triggerActionHandleBlock)))
    }

}

extension UITextField {

    public enum PaddingSide {
        case left(CGFloat)
        case right(CGFloat)
        case both(CGFloat)
    }

    public func addPadding(_ padding: PaddingSide) {

        self.leftViewMode = .always
        self.layer.masksToBounds = true


        switch padding {

        case .left(let spacing):
            let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: spacing, height: self.frame.height))
            self.leftView = paddingView
            self.rightViewMode = .always

        case .right(let spacing):
            let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: spacing, height: self.frame.height))
            self.rightView = paddingView
            self.rightViewMode = .always

        case .both(let spacing):
            let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: spacing, height: self.frame.height))
            // left
            self.leftView = paddingView
            self.leftViewMode = .always
            // right
            self.rightView = paddingView
            self.rightViewMode = .always
        }
    }
}

public class ImageCache {
    public static let shared = ImageCache()
    private let cache = NSCache<NSString, UIImage>()
    private let cacheGif = NSCache<NSString, NSData>()
    private var cacheKeyMap: [String: String] = [:]

    private init() {
        if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let cacheDirectory = documentsDirectory.appendingPathComponent("fileCacheImage")
            loadCacheFromDisk(directory: cacheDirectory)
            
            let cacheGifDirectory = documentsDirectory.appendingPathComponent("fileCacheGif")
            loadCacheFromDisk(directory: cacheGifDirectory)
        }
    }

    public func save(image: UIImage, forKey key: String) {
        let sanitizedKey = sanitizeKey(key)
        cache.setObject(image, forKey: sanitizedKey as NSString)
        cacheKeyMap[key] = sanitizedKey
        if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let cacheDirectory = documentsDirectory.appendingPathComponent("fileCacheImage")
            saveCacheToDisk(directory: cacheDirectory)
        }
    }
    
    public func saveGif(data: NSData, forKey key: String) {
        let sanitizedKey = sanitizeKey(key)
        cacheGif.setObject(data, forKey: sanitizedKey as NSString)
        cacheKeyMap[key] = sanitizedKey
        if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let cacheDirectory = documentsDirectory.appendingPathComponent("fileCacheGif")
            saveCacheToDisk(directory: cacheDirectory)
        }
    }

    public func image(forKey key: String) -> UIImage? {
        let sanitizedKey = sanitizeKey(key)
        return cache.object(forKey: sanitizedKey as NSString)
    }
    public func imageGif(forKey key: String) -> NSData? {
        let sanitizedKey = sanitizeKey(key)
        return cacheGif.object(forKey: sanitizedKey as NSString)
    }
    
    func saveCacheToDisk(directory: URL) {
        let fileManager = FileManager.default

        if !fileManager.fileExists(atPath: directory.path) {
            do {
                try fileManager.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                return
            }
        }

        let mappingFilePath = directory.appendingPathComponent("keyMapping.json")
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: cacheKeyMap, options: [])
            try jsonData.write(to: mappingFilePath)
        } catch {
            return
        }

        for (originalKey, sanitizedKey) in cacheKeyMap {
            if let image = cache.object(forKey: sanitizedKey as NSString),
               let imageData = image.pngData() {
                let filePath = directory.appendingPathComponent("\(sanitizedKey).png")
                do {
                    try imageData.write(to: filePath)
                } catch {
                }
            }
        }
    }
    
    func loadCacheFromDisk(directory: URL) {
        let fileManager = FileManager.default

        // Load mapping
        let mappingFilePath = directory.appendingPathComponent("keyMapping.json")
        guard let jsonData = try? Data(contentsOf: mappingFilePath),
              let loadedMapping = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: String] else {
            return
        }

        if cacheKeyMap.count == 0 {
            cacheKeyMap = loadedMapping
        }

        // Load images
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            for fileURL in fileURLs {
                if fileURL.lastPathComponent == "keyMapping.json" { continue } // Skip mapping file

                let sanitizedKey = fileURL.deletingPathExtension().lastPathComponent
                if let imageData = try? Data(contentsOf: fileURL),
                   let image = UIImage(data: imageData) {
                    cache.setObject(image, forKey: sanitizedKey as NSString)
                }
            }
        } catch {
//            print("Failed to load cache from disk: \(error)")
        }
    }
    
    private func sanitizeKey(_ key: String) -> String {
        let data = Data(key.utf8)
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}

public class LibAlertController: UIAlertController {
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Customize the title's font
        let titleFont = UIFont.boldSystemFont(ofSize: 16)
        let titleAttributes = [NSAttributedString.Key.font: titleFont]
        setValue(NSAttributedString(string: self.title ?? "", attributes: titleAttributes), forKey: "attributedTitle")
        
        // Change the font for the message
        let messageFont = UIFont.systemFont(ofSize: 14)
        let messageAttributes = [NSAttributedString.Key.font: messageFont]
        setValue(NSAttributedString(string: self.message ?? "", attributes: messageAttributes), forKey: "attributedMessage")
        
        for i in self.actions {
            let attributedText = NSAttributedString(string: i.title ?? "", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16)])

            guard let label = (i.value(forKey: "__representer") as AnyObject).value(forKey: "label") as? UILabel else { return }
            label.attributedText = attributedText
        }

    }
}


extension UISearchBar
{

    public func setMagnifyingGlassColorTo(color: UIColor)
    {
        // Search Icon
        let textFieldInsideSearchBar = self.value(forKey: "searchField") as? UITextField
        let glassIconView = textFieldInsideSearchBar?.leftView as? UIImageView
        glassIconView?.image = glassIconView?.image?.withRenderingMode(.alwaysTemplate)
        glassIconView?.tintColor = color
    }

    func setClearButtonColorTo(color: UIColor)
    {
        // Clear Button
        let textFieldInsideSearchBar = self.value(forKey: "searchField") as? UITextField
        let crossIconView = textFieldInsideSearchBar?.value(forKey: "clearButton") as? UIButton
        crossIconView?.setImage(crossIconView?.currentImage?.withRenderingMode(.alwaysTemplate), for: .normal)
        crossIconView?.tintColor = color
    }

    func setPlaceholderTextColorTo(color: UIColor)
    {
        let textFieldInsideSearchBar = self.value(forKey: "searchField") as? UITextField
        textFieldInsideSearchBar?.textColor = color
        let textFieldInsideSearchBarLabel = textFieldInsideSearchBar!.value(forKey: "placeholderLabel") as? UILabel
        textFieldInsideSearchBarLabel?.textColor = color
    }
    
    public func setCustomBackgroundImage(image: UIImage)
    {
        setSearchFieldBackgroundImage(resizeImage(image: image, targetHeight: 30), for: .normal)
    }
    
    func resizeImage(image: UIImage, targetHeight: CGFloat) -> UIImage? {
        let scaleFactor = targetHeight / image.size.height
        let targetWidth = image.size.width * scaleFactor
        let newSize = CGSize(width: targetWidth, height: targetHeight)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        
        image.draw(in: CGRect(origin: .zero, size: newSize))
        guard let newImage = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
        
        return newImage
    }
    
    public func updateHeight(height: CGFloat, radius: CGFloat = 8.0, borderColor: CGColor = UIColor.white.cgColor) {
            let image: UIImage? = UIImage.imageWithColor(color: UIColor.clear, size: CGSize(width: 1, height: height))
            setSearchFieldBackgroundImage(image, for: .normal)
            for subview in self.subviews {
                for subSubViews in subview.subviews {
                    if #available(iOS 13.0, *) {
                        for child in subSubViews.subviews {
                            if let textField = child as? UISearchTextField {
                                textField.layer.cornerRadius = radius
                                textField.clipsToBounds = true
                                textField.layer.borderColor = borderColor
                                textField.layer.borderWidth = 1.0
                            }
                        }
                        continue
                    }
                    if let textField = subSubViews as? UITextField {
                        textField.layer.cornerRadius = radius
                        textField.clipsToBounds = true
                        textField.layer.borderColor = borderColor
                        textField.layer.borderWidth = 1.0
                    }
                }
            }
        }
}

extension String {
    init(unicodeScalar: UnicodeScalar) {
        self.init(Character(unicodeScalar))
    }


    init?(unicodeCodepoint: Int) {
        if let unicodeScalar = UnicodeScalar(unicodeCodepoint) {
            self.init(unicodeScalar: unicodeScalar)
        } else {
            return nil
        }
    }


    static func +(lhs: String, rhs: Int) -> String {
        return lhs + String(unicodeCodepoint: rhs)!
    }


    static func +=(lhs: inout String, rhs: Int) {
        lhs = lhs + rhs
    }
}

extension UIGraphicsRenderer {
    static func renderImagesAt(urls: [NSURL], size: CGSize, scale: CGFloat = 1) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)

        let options: [NSString: Any] = [
            kCGImageSourceThumbnailMaxPixelSize: max(size.width * scale, size.height * scale),
            kCGImageSourceCreateThumbnailFromImageAlways: true
        ]

        let thumbnails = try urls.map { url -> CGImage in
            let imageSource = CGImageSourceCreateWithURL(url, nil)

            let scaledImage = CGImageSourceCreateThumbnailAtIndex(imageSource!, 0, options as CFDictionary)
            
            return scaledImage!
        }

        // Translate Y-axis down because cg images are flipped and it falls out of the frame (see bellow)
        let rect = CGRect(x: 0,
                          y: -size.height,
                          width: size.width,
                          height: size.height)

        let resizedImage = renderer.image { ctx in

            let context = ctx.cgContext
            context.scaleBy(x: 1, y: -1) //Flip it ( cg y-axis is flipped)

            for image in thumbnails {
                context.draw(image, in: rect)
            }
        }

        return resizedImage
    }
    
    static func renderImageAt(url: NSURL, size: CGSize, scale: CGFloat = 1) -> UIImage {
            return renderImagesAt(urls: [url], size: size, scale: scale)
        }
}

extension NSAttributedString {
    convenience init(html: String) throws {
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        guard let data = html.data(using: .utf8) else {
            throw NSError(domain: "Invalid HTML", code: 0, userInfo: nil)
        }
        try self.init(data: data, options: options, documentAttributes: nil)
    }
}
