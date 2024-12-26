//
//  Download.swift
//  Runner
//
//  Created by Yayan Dwi on 24/04/20.
//  Copyright © 2020 The Chromium Authors. All rights reserved.
//

import Foundation
import Alamofire

public class Download {
    
    public init() {}
    
    var delegate : DownloadDelegate?
    
    public func getDelegate() -> DownloadDelegate? {
        return delegate
    }
    
    private var downloadBufferQueue = DispatchQueue(label: "DOWNLOAD_BUFFER", attributes: .concurrent)
    
    var DOWNLOAD_BUFFER = [Data?]()
    var DOWNLOAD_SESSION = [Session]()
    var DOWNLOAD_URL = Utils.getURLBase() + "filepalio/image/"
    
    public func start(forKey: String, delegate: DownloadDelegate){
        self.delegate = delegate
        let download = Nexilis.getDownload(forKey: forKey)
        if download == nil {
            Nexilis.addDownload(forKey: forKey, download: self)
        }
        _ = Nexilis.write(message: CoreMessage_TMessageBank.getImageDownload(p_image_id: forKey))
    }
    
    var onDownloadProgress: ((String, Double) -> ())?
    
    public func start(forKey: String, completion: @escaping (String, Double)->()) {
        self.onDownloadProgress = completion
        let download = Nexilis.getDownload(forKey: forKey)
        if download == nil {
            Nexilis.addDownload(forKey: forKey, download: self)
        }
        _ = Nexilis.write(message: CoreMessage_TMessageBank.getImageDownload(p_image_id: forKey))
    }
    
    public func startHTTP(forKey: String, isImage: Bool = true, completion: @escaping (String, Double)->()) {
        _ = startHTTP(filename: forKey, isImage: isImage, baseURL: DOWNLOAD_URL, completion: completion)
    }
    
    public func startHTTP(filename: String, isImage: Bool = true, baseURL: String, completion: @escaping (String, Double)->()) {
        let download = Nexilis.getDownload(forKey: filename)
        if download == nil {
            Nexilis.addDownload(forKey: filename, download: self)
            var sep = ""
            if baseURL.last != "/" {
                sep = "/"
            }
            var fullURL = "\(baseURL)\(sep)\(filename)"
            if let encodedUrlString = fullURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                fullURL = encodedUrlString
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
            do {
                let downloadRequest = SessionManager.shared.session.download(fullURL, headers: headers)
                .downloadProgress(queue: downloadBufferQueue) { progress in
                    let frac = progress.fractionCompleted*100
                    if frac != 100.0 {
                        completion(filename,frac)
                    }
                }
                .responseData { result in
                    if let response = result.response, response.statusCode == 200, let successResponse = result.value {
                        //print("Response success")
                        do {
                            let documentDir = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                            let url = documentDir.appendingPathComponent(filename)
                            //print("write file \(url.path)")
                            let dResponse = try FileEncryption.shared.decryptToMemory(successResponse, MasterKeyUtil.shared.getServerKey())
                            if isImage {
                                let imageOr = UIImage(data: successResponse)
                                let imageDec = UIImage(data: dResponse)
                                if imageDec != nil {
                                    try dResponse.write(to: url)
                                } else {
                                    try successResponse.write(to: url)
                                }
                            }
                            else {
                                try dResponse.write(to: url)
                            }
                            Nexilis.removeDownload(forKey: filename)
                            completion(filename,100)
                        }
                        catch {}
                    }
                    else {
                        let statusCode = result.response?.statusCode
                        print("Response fail: \(result.debugDescription)")
                        completion(filename,0)
                    }
                }
            }
            catch {}
        }
        
    }
    
    func put(part: Int, buffer: Data){
        downloadBufferQueue.async (flags: .barrier){
            self.DOWNLOAD_BUFFER.insert(buffer, at: part)
        }
    }
    
    func size() -> Int {
        var size = 0
        downloadBufferQueue.sync {
            for b in DOWNLOAD_BUFFER {
                size += b?.count ?? 0
            }
        }
        return size
    }
    
    func remove() -> Data {
        var result = Data()
        downloadBufferQueue.sync {
            for i in DOWNLOAD_BUFFER {
                if let b = i {
                    result.append(contentsOf: b)
                }
            }
        }
        return result
    }
}

public class SessionManager {
    static let shared = SessionManager()
    let session: Session

    private init() {
        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.timeoutIntervalForRequest = 60
        let serverTrustManager = ServerTrustManager(allHostsMustBeEvaluated: false,
                                                    evaluators: [Utils.getURLBase().components(separatedBy: "/")[2]: DisabledTrustEvaluator()])
        self.session = Session(configuration: sessionConfiguration, serverTrustManager: serverTrustManager)
    }
}
