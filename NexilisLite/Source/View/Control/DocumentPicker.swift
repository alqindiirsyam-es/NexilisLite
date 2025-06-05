//
//  DocumentPicker.swift
//  Qmera
//
//  Created by Akhmad Al Qindi Irsyam on 13/09/21.
//

import UIKit
import MobileCoreServices
import UniformTypeIdentifiers

public protocol DocumentPickerDelegate: AnyObject {
    func didSelectDocument(document: Any?)
}

class Document: UIDocument {
    var data: Data?
    override func contents(forType typeName: String) throws -> Any {
        guard let data = data else { return Data() }
        return try NSKeyedArchiver.archivedData(withRootObject:data,
                                                requiringSecureCoding: true)
    }
    override func load(fromContents contents: Any, ofType typeName:
                        String?) throws {
        guard let data = contents as? Data else { return }
        self.data = data
    }
}

open class DocumentPicker: NSObject {
    private var pickerController: UIDocumentPickerViewController?
    private weak var presentationController: UIViewController?
    private weak var delegate: DocumentPickerDelegate?
    
    private var pickedDocument: Document?
    
    init(presentationController: UIViewController, delegate: DocumentPickerDelegate) {
        super.init()
        self.presentationController = presentationController
        self.delegate = delegate
    }
    
    public func present() {
        self.pickerController = UIDocumentPickerViewController(forOpeningContentTypes: [.data], asCopy: true)
//        self.pickerController?.allowsMultipleSelection = true
        self.pickerController!.delegate = self
        self.presentationController?.present(self.pickerController!, animated: true)
    }
    
}

extension DocumentPicker: UIDocumentPickerDelegate {
    
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        delegate?.didSelectDocument(document: urls)
    }
    
    public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        delegate?.didSelectDocument(document: nil)
    }
}
