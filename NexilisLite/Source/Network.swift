//
//  Network.swift
//  Runner
//
//  Created by Yayan Dwi on 20/04/20.
//  Copyright © 2020 The Chromium Authors. All rights reserved.
//

import Foundation
import Alamofire

public class Network {
    let uploadGroup = DispatchGroup()
    private var path = ""
    private var fileId = ""
    private var fileSize = 0
    private var isCancel = false
    private var progress = 0.0
    private var CHUNK_SIZE = 200 * 1024
    private var UPLOAD_URL = Utils.getURLBase() + "uploader"
    
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
    
    public func uploadHTTP(name: String, completion: @escaping (Bool, Double, [String:Any]?)->()) {
        _ = uploadHTTP(UPLOAD_URL, filename: [name], completion: completion)
    }
    
    public func uploadHTTP(fileUrl: URL, completion: @escaping (Bool, Double, [String:Any]?)->()) {
        _ = uploadHTTP(UPLOAD_URL, files: [fileUrl], completion: completion)
    }
    
    public func uploadHTTP(_ endUrl: String, files: [URL] = [], filename: [String] = [], parameters: [String : Any] = [:], completion: @escaping (Bool, Double, [String:Any]?)->()) -> UploadRequest {
        
        var filesIn = [URL]()
        var filesTempServer = [URL]()
        filesIn.append(contentsOf: files)
        if !filename.isEmpty {
            do {
                let fileManager = FileManager.default
                let documentDir = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                let tempDir = documentDir.appendingPathComponent("temp")
                if !fileManager.fileExists(atPath: tempDir.path) {
                    do {
                        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true, attributes: nil)
                    } catch {
                        print("Error creating directory: \(error)")
                    }
                }
                for name in filename {
                    let fileDir = documentDir.appendingPathComponent(name)
                    let path = fileDir.path
                    if FileManager.default.fileExists(atPath: path) {
                        let fileURL = URL(fileURLWithPath: path)
                        let filenameServer = "\(name)"
                        let fileDirServer = tempDir.appendingPathComponent(filenameServer)
                        let fileURLServer = URL(fileURLWithPath: fileDirServer.path)
                        try FileEncryption.shared.encryptFile(fileURL, fileURLServer, MasterKeyUtil.shared.getServerKey())
//                        let dataSecure = try FileEncryption.shared.encryptFile(fileURL)
//                        dataSecure?.write(to: fileURLSecure)
                        filesIn.append(fileURL)
                        filesTempServer.append(fileURLServer)
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
            "Host": Utils.getURLBase().components(separatedBy: "/")[2],
            "Accept-Encoding": "gzip, deflate, br",
            "Connection": "Keep-Alive",
            "Accept": "*/*",
            "User-Agent": Utils.getUserAgent(),
            "Cookie": Utils.getCookiesMobile()
        ]
        //print("HEADER: \(headers)")
        
        let uploadRequest = SessionManager.shared.session.upload(multipartFormData: { (multipartFormData: MultipartFormData) in
            for (key, value) in parameters {
                multipartFormData.append("\(value)".data(using: String.Encoding.utf8)!, withName: key as String)
                //print(multipartFormData)
            }
            
            for i in 0..<filesIn.count {
                multipartFormData.append(filesIn[i], withName: "file\(i+1)", fileName: filesIn[i].lastPathComponent, mimeType: "application/octet-stream")
                Nexilis.putUploadFile(forKey: filesIn[i].lastPathComponent, uploader: self)
                //print(multipartFormData)
            }
            
        }, to: endUrl, headers: headers)
        .responseJSON { result in
            if let response = result.response, response.statusCode == 200, let successResponse = result.value as? [String:Any] {
                //print("Response success")
                for url in filesTempServer {
                    Nexilis.removeUploadFile(forKey: url.lastPathComponent)
                }
                completion(true,100,successResponse)
                
            }
            else {
                let statusCode = result.response?.statusCode
                //print("Response fail: \(statusCode)")
                completion(false,0,nil)
            }
        }
        .uploadProgress { progress in
            //print("Response progress: \(progress.fractionCompleted*100)")
            let frac = progress.fractionCompleted*100
            if frac != 100.0 {
                completion(!progress.isCancelled,frac,nil)
            }
        }
        
        return uploadRequest
    }
    
    public func cancel() {
        self.isCancel = true
    }
}
