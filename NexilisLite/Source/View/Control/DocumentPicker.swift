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
        var supportedTypes: [UTType] = [
            // General text and images
            .image, .text, .plainText, .utf8PlainText, .utf16ExternalPlainText, .utf16PlainText,
            .delimitedText, .commaSeparatedText, .tabSeparatedText, .utf8TabSeparatedText,
            .rtf, .pdf, .webArchive,
            // Images
            .jpeg, .tiff, .gif, .png, .bmp, .ico, .rawImage, .svg, .livePhoto,
            // Media
            .movie, .video, .audio, .quickTimeMovie, .mpeg, .mpeg2Video, .mpeg2TransportStream,
            .mp3, .mpeg4Movie, .mpeg4Audio, .avi, .aiff, .wav, .midi,
            // Archives
            .archive, .gzip, .bz2, .zip, .appleArchive,
            // Documents
            .spreadsheet, .epub, .presentation,
            // Code and script types
            .sourceCode, .cSource, .objectiveCSource, .swiftSource, .cPlusPlusSource,
            .objectiveCPlusPlusSource, .script, .shellScript, .pythonScript, .rubyScript,
            .perlScript, .json, .xml, .html,
            // Custom UTTypes via extension
            UTType(filenameExtension: "java")!,     // Java
            UTType(filenameExtension: "ts")!,       // TypeScript
            UTType(filenameExtension: "yaml")!,     // YAML
            UTType(filenameExtension: "yml")!,      // YAML
            UTType(filenameExtension: "sql")!,      // SQL
            UTType(filenameExtension: "csv")!,      // CSV
            UTType(filenameExtension: "ini")!,      // INI
            UTType(filenameExtension: "log")!,      // Log
            UTType(filenameExtension: "js")!,       // JavaScript
            UTType(filenameExtension: "md")!        // Markdown
        ]
        if #available(iOS 18.0, *){
            supportedTypes.append(.css)
        }
        self.pickerController = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes, asCopy: true)
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
