//
//  CustomTextView.swift
//  Qmera
//
//  Created by Akhmad Al Qindi Irsyam on 27/09/21.
//

import UIKit

protocol CustomTextViewPasteDelegate : AnyObject {
    func customTextViewDidPasteText(image: UIImage?, dataGIF: Data?)
    /// Plain text is about to be put into the field in one piece.
    ///
    /// Fix: a paste here does not go through the text view's shouldChangeTextIn - this class
    /// answers the paste itself and writes the text with replace(_:withText:), which reports the
    /// change afterwards but never offers it first. Anything that has to know a whole piece of
    /// text arrived at once - a name that is to become a mention again, see EditorGroup's
    /// adoptPastedMentions - has to be told here.
    func customTextViewWillPasteText()
}

extension CustomTextViewPasteDelegate {
    func customTextViewWillPasteText() {}
}

class CustomTextView: UITextView {
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        let menuController = UIMenuController.shared
        if var menuItems = menuController.menuItems,
           (menuItems.map { $0.action }).elementsEqual([#selector(toggleBoldface), #selector(toggleItalics), #selector(toggleUnderline)]) {
            menuItems.append(UIMenuItem(title: "Strikethrough", action: #selector(toggleStrikethrough)))
            menuController.menuItems = menuItems
        }
        return super.canPerformAction(action, withSender: sender)
    }
    
    @objc func toggleStrikethrough(_ sender: Any?) {
        if let range = self.selectedTextRange {
            let startPosition = self.offset(from: self.beginningOfDocument, to: range.start)
            if startPosition == 0 || checkCharBefore(char: self.text.substring(from: startPosition - 1, to: startPosition - 1)) {
                self.replace(self.textRange(from: range.start, to: range.end)!, withText: "~\(self.text(in: range)!)~")
            } else {
                self.replace(self.textRange(from: range.start, to: range.end)!, withText: " ~\(self.text(in: range)!)~")
            }
            UIMenuController.shared.hide(for: self)
        }
    }

    override func toggleBoldface(_ sender: Any?) {
        if let range = self.selectedTextRange {
            let startPosition = self.offset(from: self.beginningOfDocument, to: range.start)
            if startPosition == 0 || checkCharBefore(char: self.text.substring(from: startPosition - 1, to: startPosition - 1)) {
                self.replace(self.textRange(from: range.start, to: range.end)!, withText: "*\(self.text(in: range)!)*")
            } else {
                self.replace(self.textRange(from: range.start, to: range.end)!, withText: " *\(self.text(in: range)!)*")
            }
            UIMenuController.shared.hide(for: self)
        }
    }
    
    override func toggleUnderline(_ sender: Any?) {
        if let range = self.selectedTextRange {
            let startPosition = self.offset(from: self.beginningOfDocument, to: range.start)
            if startPosition == 0 || checkCharBefore(char: self.text.substring(from: startPosition - 1, to: startPosition - 1)) {
                self.replace(self.textRange(from: range.start, to: range.end)!, withText: "^\(self.text(in: range)!)^")
            } else {
                self.replace(self.textRange(from: range.start, to: range.end)!, withText: " ^\(self.text(in: range)!)^")
            }
            UIMenuController.shared.hide(for: self)
        }
    }
    
    override func toggleItalics(_ sender: Any?) {
        if let range = self.selectedTextRange {
            let startPosition = self.offset(from: self.beginningOfDocument, to: range.start)
            if startPosition == 0 || checkCharBefore(char: self.text.substring(from: startPosition - 1, to: startPosition - 1)) {
                self.replace(self.textRange(from: range.start, to: range.end)!, withText: "_\(self.text(in: range)!)_")
            } else {
                self.replace(self.textRange(from: range.start, to: range.end)!, withText: " _\(self.text(in: range)!)_")
            }
            UIMenuController.shared.hide(for: self)
        }
    }
    
    func checkCharBefore(char: String) -> Bool {
        return char == " " || char == "\n"
    }
    
    weak var customDelegate: CustomTextViewPasteDelegate?
    override func paste(_ sender: Any?) {
        if let pasteboardItems = UIPasteboard.general.items.first {
            if pasteboardItems["public.jpeg"] != nil || pasteboardItems["public.png"] != nil || pasteboardItems["public.gif"] != nil || (pasteboardItems.keys.first != nil && pasteboardItems.keys.first!.contains(".gif")) {
                let dataGif = UIPasteboard.general.data(forPasteboardType: "com.compuserve.gif")
                customDelegate?.customTextViewDidPasteText(image: pasteboardItems["public.png"] as? UIImage ?? pasteboardItems["public.jpeg"] as? UIImage, dataGIF: dataGif)
                return
            } else if let string = UIPasteboard.general.string {
                var formattedText = string
                // Replace "- " only if it starts a line (after \n or at beginning)
                if let bulletRegex = try? NSRegularExpression(pattern: #"(?m)^(?:- |\* |• )"#) {
                    formattedText = bulletRegex.stringByReplacingMatches(
                        in: formattedText,
                        options: [],
                        range: NSRange(location: 0, length: formattedText.utf16.count),
                        withTemplate: "  • "
                    )
                }

                // Replace numbered lists "1.", "2.", etc. only if they start a line
                if let numberRegex = try? NSRegularExpression(pattern: #"(?m)^(\d+)\."#) {
                    formattedText = numberRegex.stringByReplacingMatches(
                        in: formattedText,
                        options: [],
                        range: NSRange(location: 0, length: formattedText.utf16.count),
                        withTemplate: "  $1."
                    )
                }
                customDelegate?.customTextViewWillPasteText()
                self.replace(self.selectedTextRange!, withText: formattedText)
                return
            }
        } else if let string = UIPasteboard.general.string {
            customDelegate?.customTextViewWillPasteText()
            self.replace(self.selectedTextRange!, withText: string)
        }
        super.paste(sender)
    }

}

extension UIMenuController {
    func hide(for view: UIView) {
        if #available(iOS 13.0, *) {
            self.hideMenu(from: view)
        } else {
            self.setMenuVisible(false, animated: true)
        }
    }
}
