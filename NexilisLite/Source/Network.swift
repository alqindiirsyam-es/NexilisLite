//
//  Network.swift
//  Runner
//
//  Created by Yayan Dwi on 20/04/20.
//  Copyright © 2020 The Chromium Authors. All rights reserved.
//

import Foundation
@_implementationOnly import Alamofire
import UniformTypeIdentifiers

public class Network {
    let uploadGroup = DispatchGroup()
    private var path = ""
    private var fileId = ""
    private var fileSize = 0
    private var isCancel = false
    private var progress = 0.0
    private var CHUNK_SIZE = 200 * 1024
    private var UPLOAD_URL = Utils.getURLBase() + "uploader"
    private var UPLOAD_URL_BACKUP = Utils.getURLBase() + "uploader_bkp"
    
    public init() {}
    
    public func upload(name: String, completion: @escaping (Bool, Double)->()) {
        DispatchQueue(label: "Network").async {
            do {
                let fileManager = FileManager.default
                let documentDir = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                let fileDir = documentDir.appendingPathComponent(name)
                let path = fileDir.path
                if FileManager.default.fileExists(atPath: path) {
                    let attrib = try FileManager.default.attributesOfItem(atPath: path)
                    let fileSize = attrib[.size] as! Int
                    let fileName = (path as NSString).lastPathComponent
                    //print("file exists: \(path) -> \(fileSize)")
                    if (fileSize > self.CHUNK_SIZE) {
                        Nexilis.putUploadFile(forKey: fileName, uploader: self)
                        //print("[bytes_processing] Size: " + String(fileSize))
                        var totalPart = fileSize / self.CHUNK_SIZE
                        if (fileSize % self.CHUNK_SIZE > 0) {
                            totalPart += 1
                        }
                        
                        do {
                            let outputFileHandle = try FileHandle(forReadingFrom: URL(fileURLWithPath: path))
                            var data = outputFileHandle.readData(ofLength: self.CHUNK_SIZE)
                            var index = 0
                            while !data.isEmpty {
                                if self.isCancel {
                                    completion(false, Double(0))
                                    break
                                }
                                self.uploadGroup.enter()
                                //print("[bytes_processing] Sending bytes part #" + String(index + 1) + " of " + String(totalPart) + " -->  " + String(data.count))
                                
                                let message = CoreMessage_TMessageBank.getUploadFile(p_image_id: fileName, file_size: String(fileSize), part_of: String(index), part_size: String(totalPart), p_file: [UInt8] (data))
                                
                                if let response = Nexilis.write(message: message), response.isEmpty {
                                    completion(false, self.progress)
                                    break
                                }
                                //print("[bytes_processing] part #" + String(index + 1) + " of " + String(totalPart) + " uploading...")
                                
                                let wait = self.uploadGroup.wait(timeout: .now() + 30)
                                //print("[bytes_processing] part #" + String(index + 1) + " of " + String(totalPart) + " wait!", wait)
                                if wait == DispatchTimeoutResult.timedOut {
                                    completion(false, self.progress)
                                    Nexilis.removeUploadFile(forKey: fileName)
                                    self.uploadGroup.leave()
                                    break
                                }
                                self.progress = Double(index + 1) / Double(totalPart) * 100
                                completion(true, self.progress)
                                
                                //print("[bytes_processing] part #" + String(index + 1) + " of " + String(totalPart) + " uploaded!")
                                data = outputFileHandle.readData(ofLength: self.CHUNK_SIZE)
                                index = index + 1
                            }
                            outputFileHandle.closeFile()
                            _ = Nexilis.removeUploadFile(forKey: fileName)
                        } catch {
                            //print(error.localizedDescription)
                        }
                    }
                    else {
                        let data = try Data(contentsOf: URL(fileURLWithPath: path))
                        
                        let message = CoreMessage_TMessageBank.getUploadFile(p_image_id: fileName, file_size: String(fileSize), part_of: "0", part_size: "0", p_file: [UInt8] (data))
                        
                        guard let response = Nexilis.write(message: message), !response.isEmpty else {
                            completion(false, self.progress)
                            return
                        }
                        //print("[bytes_processing] File uploaded!")
                        completion(response.count > 1, 100)
                    }
                } else {
                    //print("file not exists \(name)")
                    completion(false, 0)
                }
            } catch {
                //print(error.localizedDescription)
            }
        }
    }
    
    public func upload(fileUrl: URL, completion: @escaping (Bool, Double)->()) {
        DispatchQueue(label: "Network").async {
            do {
                if FileManager.default.fileExists(atPath: fileUrl.path) {
                    let path = fileUrl.path
                    let attrib = try FileManager.default.attributesOfItem(atPath: path)
                    let fileSize = attrib[.size] as! Int
                    let fileName = (path as NSString).lastPathComponent
                    //print("file exists: \(path) -> \(fileSize)")
                    if (fileSize > self.CHUNK_SIZE) {
                        Nexilis.putUploadFile(forKey: fileName, uploader: self)
                        //print("[bytes_processing] Size: " + String(fileSize))
                        var totalPart = fileSize / self.CHUNK_SIZE
                        if (fileSize % self.CHUNK_SIZE > 0) {
                            totalPart += 1
                        }
                        
                        do {
                            let outputFileHandle = try FileHandle(forReadingFrom: URL(fileURLWithPath: path))
                            var data = outputFileHandle.readData(ofLength: self.CHUNK_SIZE)
                            var index = 0
                            while !data.isEmpty {
                                if self.isCancel {
                                    completion(false, Double(0))
                                    break
                                }
                                self.uploadGroup.enter()
                                //print("[bytes_processing] Sending bytes part #" + String(index + 1) + " of " + String(totalPart) + " -->  " + String(data.count))
                                
                                let message = CoreMessage_TMessageBank.getUploadFile(p_image_id: fileName, file_size: String(fileSize), part_of: String(index), part_size: String(totalPart), p_file: [UInt8] (data))
                                
                                if let response = Nexilis.write(message: message), response.isEmpty {
                                    completion(false, self.progress)
                                    break
                                }
                                //print("[bytes_processing] part #" + String(index + 1) + " of " + String(totalPart) + " uploading...")
                                
                                let wait = self.uploadGroup.wait(timeout: .now() + 30)
                                //print("[bytes_processing] part #" + String(index + 1) + " of " + String(totalPart) + " wait!", wait)
                                if wait == DispatchTimeoutResult.timedOut {
                                    completion(false, self.progress)
                                    Nexilis.removeUploadFile(forKey: fileName)
                                    self.uploadGroup.leave()
                                    break
                                }
                                self.progress = Double(index + 1) / Double(totalPart) * 100
                                completion(true, self.progress)
                                
                                //print("[bytes_processing] part #" + String(index + 1) + " of " + String(totalPart) + " uploaded!")
                                data = outputFileHandle.readData(ofLength: self.CHUNK_SIZE)
                                index = index + 1
                            }
                            outputFileHandle.closeFile()
                            _ = Nexilis.removeUploadFile(forKey: fileName)
                        } catch {
                            //print(error.localizedDescription)
                        }
                    }
                    else {
                        let data = try Data(contentsOf: URL(fileURLWithPath: path))
                        
                        let message = CoreMessage_TMessageBank.getUploadFile(p_image_id: fileName, file_size: String(fileSize), part_of: "0", part_size: "0", p_file: [UInt8] (data))
                        
                        guard let response = Nexilis.write(message: message), !response.isEmpty else {
                            completion(false, self.progress)
                            return
                        }
                        //print("[bytes_processing] File uploaded!")
                        completion(response.count > 1, 100)
                    }
                } else {
                    //print("file not exists \(fileUrl)")
                    completion(false, 0)
                }
            } catch {
                //print(error.localizedDescription)
            }
        }
    }
    
    public func uploadHTTP(name: String, completion: @escaping (Bool, Double)->()) {
        _ = uploadHTTP(UPLOAD_URL, filename: [name], completion: completion)
    }
    
    public func uploadHTTP(fileUrl: URL, completion: @escaping (Bool, Double)->()) {
        _ = uploadHTTP(UPLOAD_URL_BACKUP, files: [fileUrl], completion: completion)
    }
    
    // Internal: returning Alamofire.UploadRequest would drag `import Alamofire`
    // into the generated .swiftinterface, and consumers do not have that module
    // because Alamofire is linked into this framework rather than installed
    // beside it. The public uploadHTTP(name:) / uploadHTTP(fileUrl:) overloads
    // return Void and stay public.
    func uploadHTTP(_ endUrl: String, files: [URL] = [], filename: [String] = [], parameters: [String : Any] = [:], completion: @escaping (Bool, Double)->()) -> UploadRequest {
        
        var filesIn = [URL]()
        filesIn.append(contentsOf: files)
        if !filename.isEmpty {
            do {
                let fileManager = FileManager.default
                let documentDir = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                for name in filename {
                    let fileDir = documentDir.appendingPathComponent(name)
                    let path = fileDir.path
                    if FileManager.default.fileExists(atPath: path) {
                        let fileURL = URL(fileURLWithPath: path)
                        filesIn.append(fileURL)
                    }
                }
            }
            catch {}
        }
        
        //print("FULL URL: \(endUrl)")
        var endUrl = endUrl
        if let encodedUrlString = endUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            endUrl = encodedUrlString
        }
        let BOUNDARY = "esuploader-" + "\(Date().currentTimeMillis())"
        let MIME_TYPE = "multipart/form-data; boundary=" + BOUNDARY
        let headers: HTTPHeaders = [
            "Content-Type": MIME_TYPE,
            "Host": Utils.getURLBase().component(2, separatedBy: "/"),
            "Accept-Encoding": "gzip, deflate, br",
            "Connection": "Keep-Alive",
            "Accept": "*/*",
            "User-Agent": Utils.getUserAgent(),
            "Cookie": Utils.getCookiesMobile()
        ]
        //print("HEADER: \(headers)")
        
        let uploadRequest = SessionManager.shared.session.upload(multipartFormData: { (multipartFormData: MultipartFormData) in
            for (key, value) in parameters {
                var dataToUpload = "\(value)".data(using: String.Encoding.utf8)!
                if Nexilis.checkingAccess(key: "secure_folder_encrypt"){
                    dataToUpload = FileEncryption.shared.encryptFileToServer(data: dataToUpload) ?? Data()
                }
                multipartFormData.append(dataToUpload, withName: key as String)
                //print(multipartFormData)
            }
            
            for i in 0..<filesIn.count {
                let urlFile = filesIn[i]
                do {
                    var dataToUpload = try Data(contentsOf: urlFile)
                    if Nexilis.checkingAccess(key: "secure_folder_encrypt"){
                        dataToUpload = FileEncryption.shared.encryptFileToServer(data: dataToUpload) ?? Data()
                    }
                    let mime = self.mimeType(for: filesIn[i])
                    multipartFormData.append(dataToUpload, withName: "file\(i+1)", fileName: filesIn[i].lastPathComponent, mimeType: mime)
                    Nexilis.putUploadFile(forKey: filesIn[i].lastPathComponent, uploader: self)
                } catch {
                }
                //print(multipartFormData)
            }
            
        }, to: endUrl, headers: headers)
        .uploadProgress { progress in
//            print("Response progress: \(progress.fractionCompleted*100)")
            let frac = progress.fractionCompleted*100
            if frac != 100.0 {
                // Recorded per file so the chat can label the upload ring with the size it
                // is working through, the same way downloads do.
                for url in filesIn {
                    TransferBytes.set(name: url.lastPathComponent,
                                      completed: progress.completedUnitCount,
                                      total: progress.totalUnitCount)
                }
                completion(!progress.isCancelled,frac)
            }
        }
        .responseJSON { result in
            // Fix: this used to clear `filesTempServer`, an array nothing ever put anything
            // into - so every file uploaded over HTTP stayed registered as "uploading"
            // forever, holding its Network object alive with it. The files that were
            // actually sent are `filesIn`, and they are released whichever way the request
            // ended.
            for url in filesIn {
                _ = Nexilis.removeUploadFile(forKey: url.lastPathComponent)
                TransferBytes.clear(name: url.lastPathComponent)
            }
            if let response = result.response, response.statusCode == 200 {
                //print("Response success")
                completion(true,100)
                
            }
            else {
//                let statusCode = result.response?.statusCode
//                print("Response fail: \(statusCode) <><> \(result)")
                completion(false,0)
            }
        }
        
        return uploadRequest
    }
    
    func mimeType(for url: URL) -> String {
        if #available(iOS 14.0, *) {
            if let utType = UTType(filenameExtension: url.pathExtension),
               let mimeType = utType.preferredMIMEType {
                return mimeType
            }
        }
        return "application/octet-stream"
    }
    
    public func cancel() {
        self.isCancel = true
    }
}
