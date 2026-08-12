//
//  Download.swift
//  Runner
//
//  Created by Yayan Dwi on 24/04/20.
//  Copyright © 2020 The Chromium Authors. All rights reserved.
//

import Foundation
import Alamofire

/// How many bytes of a transfer have gone through, and how many there are in total, for
/// whatever transfers are in flight.
///
/// Fix: progress used to travel as a bare percentage, which is all a ring needs but not
/// enough to tell anyone how big the file actually is. Written by `Download` for HTTP
/// downloads and by `Network` for HTTP uploads; read by the chat screens to label the ring
/// with "3,4 MB / 12 MB".
public enum TransferBytes {

    private static let queue = DispatchQueue(label: "TRANSFER_BYTES")
    private static var byFile: [String: (completed: Int64, total: Int64)] = [:]

    public static func set(name: String, completed: Int64, total: Int64) {
        guard !name.isEmpty, total > 0 else {
            return
        }
        queue.sync {
            byFile[name] = (completed, total)
        }
    }

    public static func get(name: String) -> (completed: Int64, total: Int64)? {
        var value: (completed: Int64, total: Int64)?
        queue.sync {
            value = byFile[name]
        }
        return value
    }

    public static func clear(name: String) {
        queue.sync {
            byFile.removeValue(forKey: name)
        }
    }
}

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
    var DOWNLOAD_URL_BACKUP = Utils.getURLBase() + "filepalio/backuprestore/"
    
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
    
    public func startHTTP(forKey: String, downloadUrl: String, completion: @escaping (String, Double)->()) {
        startHTTP(filename: forKey, baseURL: downloadUrl, completion: completion)
    }
    
    public func startHTTP(forKey: String, isBackup: Bool = false, completion: @escaping (String, Double)->()) {
        startHTTP(filename: forKey, baseURL: isBackup ? DOWNLOAD_URL_BACKUP : DOWNLOAD_URL, completion: completion)
    }
    
    /// Posted for every HTTP download, carrying "name" (the file) and "progress" (0...100,
    /// or -100 when it failed).
    ///
    /// Fix: a download used to be reachable only through the closure whoever started it
    /// passed in, so leaving the chat left the transfer running with nothing listening -
    /// and no way for the reopened chat to find out about it. This lets any screen follow a
    /// download it did not start, exactly like "onUploadChat" already does for uploads.
    public static let progressNotification = Notification.Name("onDownloadChat")

    private static let listenerQueue = DispatchQueue(label: "DOWNLOAD_LISTENERS")
    private static var listeners: [String: [(String, Double) -> ()]] = [:]
    private static var progressByFile: [String: Double] = [:]

    /// Whether an HTTP download for this file is running right now.
    public static func isDownloading(forKey: String) -> Bool {
        var running = false
        listenerQueue.sync {
            running = listeners[forKey] != nil
        }
        return running
    }

    /// Progress of a running download, so a screen that has just appeared can draw it at
    /// the right place instead of starting again from zero.
    public static func progress(forKey: String) -> Double? {
        var value: Double?
        listenerQueue.sync {
            value = progressByFile[forKey]
        }
        return value
    }

    // Registers `completion` against the file and reports whether a transfer for it is
    // already in flight (in which case the caller must NOT start a second one - it will be
    // driven by the one already running).
    private static func addListener(filename: String, completion: @escaping (String, Double)->()) -> Bool {
        var alreadyRunning = false
        var lastKnownProgress: Double?
        listenerQueue.sync {
            alreadyRunning = listeners[filename] != nil
            listeners[filename, default: []].append(completion)
            lastKnownProgress = progressByFile[filename]
        }
        // Also counts as in flight: a download running over the socket path
        // (start(forKey:delegate:)), which registers itself in the same place.
        if !alreadyRunning, Nexilis.getDownload(forKey: filename) != nil {
            alreadyRunning = true
        }
        if alreadyRunning, let lastKnownProgress = lastKnownProgress {
            // Straight away, so a freshly drawn progress ring starts where the transfer
            // actually is rather than at zero.
            completion(filename, lastKnownProgress)
        }
        return alreadyRunning
    }

    private static func publish(filename: String, progress: Double) {
        var current: [(String, Double) -> ()] = []
        var worthReporting = false
        listenerQueue.sync {
            // Alamofire reports progress for every chunk that arrives - hundreds of times a
            // second on a fast connection - and each report walks a table view looking for
            // the row to draw. A progress ring cannot show more than about a percent
            // anyway, so anything finer than that is dropped here rather than burning the
            // main thread on it.
            let previous = progressByFile[filename] ?? -1.0
            worthReporting = progress - previous >= 1.0
            if worthReporting {
                progressByFile[filename] = progress
                current = listeners[filename] ?? []
            }
        }
        guard worthReporting else {
            return
        }
        for listener in current {
            listener(filename, progress)
        }
        postProgressNotification(filename: filename, progress: progress)
    }

    // Ends the transfer: everyone waiting is told, and every trace of it is dropped so the
    // file can be downloaded again later.
    //
    // Fix: on failure the old code left the download registered forever, and the guard at
    // the top of startHTTP then silently swallowed every retry for that file until the app
    // was restarted.
    private static func finish(filename: String, progress: Double) {
        var current: [(String, Double) -> ()] = []
        listenerQueue.sync {
            current = listeners.removeValue(forKey: filename) ?? []
            progressByFile.removeValue(forKey: filename)
        }
        TransferBytes.clear(name: filename)
        _ = Nexilis.removeDownload(forKey: filename)
        for listener in current {
            listener(filename, progress)
        }
        postProgressNotification(filename: filename, progress: progress)
    }

    private static func postProgressNotification(filename: String, progress: Double) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Download.progressNotification,
                                            object: nil,
                                            userInfo: ["name": filename, "progress": progress])
        }
    }

    public func startHTTP(filename: String, baseURL: String, completion: @escaping (String, Double)->()) {
        // Fix: this used to be `if Nexilis.getDownload(forKey:) == nil { ... }` with no else
        // branch at all - a caller asking for a file that was already downloading was
        // dropped on the floor, its completion never called even once. That is what made a
        // transfer look dead after leaving the chat and coming back: the download itself was
        // still running (it lives on a shared Alamofire session, nothing cancels it), the
        // reopened screen simply had no way to attach to it. Now every caller is registered
        // as a listener and gets the progress of the one transfer that is running.
        if Download.addListener(filename: filename, completion: completion) {
            return
        }
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
//            print("FULL URL: \(fullURL)")
            do {
                _ = SessionManager.shared.session.download(fullURL, headers: headers)
                .downloadProgress(queue: downloadBufferQueue) { progress in
                    let frac = progress.fractionCompleted*100
                    if frac != 100.0 {
                        // Kept alongside the percentage so the ring can be labelled with the
                        // size, not just filled in.
                        TransferBytes.set(name: filename,
                                          completed: progress.completedUnitCount,
                                          total: progress.totalUnitCount)
                        Download.publish(filename: filename, progress: frac)
                    }
                }
                .responseData { result in
                    if let response = result.response, response.statusCode == 200, let successResponse = result.value {
//                        print("Response success")
                        do {
                            let dResponse = FileEncryption.shared.decryptFileFromServer(data: successResponse)
                            if dResponse != nil {
                                try FileEncryption.shared.writeSecure(filename: filename, data: dResponse!)
                            } else {
                                try FileEncryption.shared.writeSecure(filename: filename, data: successResponse)
                            }
                        }
                        catch {}
                        // finish() is what clears the registration now - and it does so on
                        // the failure path too, which is what lets a failed download be
                        // retried instead of being dead until the next app launch.
                        Download.finish(filename: filename, progress: 100)
                    }
                    else {
//                        let statusCode = result.response?.statusCode
//                        print("Response fail: \(result.debugDescription)")
                        Download.finish(filename: filename, progress: -100)
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
