//
//  Download.swift
//  Runner
//
//  Created by Yayan Dwi on 24/04/20.
//  Copyright © 2020 The Chromium Authors. All rights reserved.
//

import Foundation
@_implementationOnly import Alamofire
/// How many bytes of a transfer have gone through, and how many there are in total, for
/// whatever transfers are in flight.
///
/// Fix: progress used to travel as a bare percentage, which is all a ring needs but not
/// enough to tell anyone how big the file actually is. Written by `Download` for HTTP
/// downloads and by `Network` for HTTP uploads; read by the chat screens to label the ring
/// with "3,4 MB / 12 MB".
/// Thumbnails, fetched the moment a message carrying one arrives.
///
/// A media bubble is drawn around its thumbnail: without one there is a blank square of the wrong
/// size, which fills in and resizes under the reader a moment later. Waiting until the row scrolls
/// into view means every conversation opens onto blanks and settles afterwards. A thumbnail is a
/// few tens of kilobytes - small enough to be worth having before anybody asks for it.
///
/// Deliberately modest, because this runs while the reader is doing something else entirely: two
/// at a time, off the main thread, and nothing is fetched that is already here or already on its
/// way. There is no rush and nothing waiting on it.
public enum ThumbnailPrefetch {

    private static let queue = DispatchQueue(label: "nexilis.thumbnails")
    /// Kicking a transfer off is quick, but it is still work, and it does not belong in the shared
    /// line beside anything the reader is waiting for.
    private static let starting = DispatchQueue(label: "nexilis.thumbnails.start", qos: .background)
    private static var waiting: [String] = []
    private static var running: Set<String> = []
    /// Two. Enough that a burst of messages does not trickle in one by one, few enough that this
    /// never competes with the file the reader actually asked for.
    private static let atOnce = 2
    /// How many are worth remembering.
    ///
    /// Fix: the queue had no end to it. Messages arrive one at a time from the socket but in their
    /// hundreds from a sync, and every one of them was remembered - so a conversation the reader
    /// opened waited behind a list of thumbnails for messages they may never scroll to. Anything
    /// dropped here is not lost: the conversation fetches what it draws.
    private static let mostToRemember = 40

    public static func fetch(_ name: String?) {
        guard let name = name, !name.isEmpty else { return }
        // Fix: this used to open a block on the global queue for every message that arrived, each
        // one going off to touch the file system. A sync handing over hundreds of messages at once
        // meant hundreds of those blocks, and GCD answers that by making threads - which is how a
        // prefetch meant to stay out of the way came to be the thing in the way. One queue does the
        // deciding now, in order, and the only work handed out is a transfer.
        queue.async {
            guard !running.contains(name), !waiting.contains(name),
                  !isHere(name), !Download.isDownloading(forKey: name) else {
                return
            }
            waiting.append(name)
            if waiting.count > mostToRemember {
                waiting.removeFirst(waiting.count - mostToRemember)
            }
            start()
        }
    }

    /// Both places a file can already be: the plain copy, and the secure store it is moved to.
    private static func isHere(_ name: String) -> Bool {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        if FileManager.default.fileExists(atPath: documents.appendingPathComponent(name).path) {
            return true
        }
        return FileEncryption.shared.isSecureExists(filename: name)
    }

    /// Called on `queue`, and only there.
    private static func start() {
        // Newest first. What has just arrived is what the reader is about to open; the older a
        // message is, the more likely its row will be drawn - and its thumbnail asked for - long
        // before this queue would have reached it.
        while running.count < atOnce, let name = waiting.popLast() {
            running.insert(name)
            starting.async {
                guard !Download.isDownloading(forKey: name) else {
                    // Somebody else is already fetching it; they will finish it just as well.
                    done(name)
                    return
                }
                Download().startHTTP(forKey: name) { _, progress in
                    guard progress >= 100 || progress < 0 else { return }
                    done(name)
                }
            }
        }
    }

    private static func done(_ name: String) {
        queue.async {
            // Progress is reported many times; only the report that ends it frees the place.
            guard running.remove(name) != nil else { return }
            start()
        }
    }
}

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
    
    /// The transfer this instance started, so it can be stopped.
    private var inFlight: DownloadRequest?

    /// Stops a running download and tells everyone watching that it is over. Reported as a failure
    /// (-100), which is the same thing every listener already knows how to handle.
    public static func cancel(forKey key: String) {
        guard let download = Nexilis.getDownload(forKey: key) else { return }
        download.inFlight?.cancel()
        download.inFlight = nil
        _ = Nexilis.removeDownload(forKey: key)
        var waiting: [(String, Double) -> ()] = []
        listenerQueue.sync {
            waiting = listeners[key] ?? []
            listeners[key] = nil
            progressByFile[key] = nil
            calledOff.insert(key)
        }
        // Fix: the listeners were thrown away rather than told it was over. Whoever started the
        // download keeps its own record of what it is following, and clears that record from this
        // very completion - which now never ran. The record stayed, and the next tap on the same
        // file was turned away as "already following it": a download could be stopped once and
        // then never asked for again.
        for report in waiting {
            report(key, -100)
        }
        NotificationCenter.default.post(name: Download.progressNotification,
                                        object: nil,
                                        userInfo: ["name": key, "progress": -100.0])
    }

    /// Files the reader stopped, as against transfers that failed on their own.
    ///
    /// Both are reported the same way - there is one way to say "this is over" and everything
    /// already understands it - but they do not mean the same thing. A file that could not be had
    /// should not be fetched again on its own; a file somebody chose not to fetch is simply not
    /// fetched, and the bubble goes on offering it.
    private static var calledOff: Set<String> = []

    public static func wasCalledOff(forKey key: String) -> Bool {
        var yes = false
        listenerQueue.sync { yes = calledOff.contains(key) }
        return yes
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
            // Asked for again, so whatever was decided about it last time no longer applies.
            calledOff.remove(filename)
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

    /// How big a file is on the server, without fetching it.
    ///
    /// The sender normally says so when the message goes out, but an older client - or one whose
    /// message lost the field on the way - says nothing, and a receiver cannot measure a file it
    /// has not got. A HEAD asks the same URL the download would use and reads Content-Length off
    /// the reply: the header comes back, the body never does. Answers on the main thread, and
    /// remembers, because the answer cannot change.
    private static var remoteSizes: [String: Int64] = [:]
    private static var askingSize: Set<String> = []

    public static func knownRemoteSize(forKey key: String) -> Int64? {
        return remoteSizes[key]
    }

    /// Everyone waiting on one answer about one file.
    private static var sizeWaiters: [String: [(Int64) -> Void]] = [:]

    public static func remoteSize(forKey key: String, completion: @escaping (Int64) -> Void) {
        guard !key.isEmpty else { return }
        if let already = remoteSizes[key] {
            completion(already)
            return
        }
        // Fix: a second asker, arriving while the first request was still in the air, was turned
        // away without ever being answered. A chat row is rebuilt many times over the life of a
        // transfer - once for every tick of it - and each rebuild asks again from a new view, so
        // the one caller that did get the answer was almost always attached to a view that had
        // already been thrown away. The size appeared only after the screen was left and opened
        // again, by which point the answer was in hand and returned straight away. Everybody who
        // asked is answered.
        sizeWaiters[key, default: []].append(completion)
        guard !askingSize.contains(key) else { return }
        askingSize.insert(key)

        let base = Download().DOWNLOAD_URL
        let sep = base.last == "/" ? "" : "/"
        var full = "\(base)\(sep)\(key)"
        if let encoded = full.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            full = encoded
        }
        guard let url = URL(string: full) else {
            askingSize.remove(key)
            sizeWaiters.removeValue(forKey: key)
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.setValue(Utils.getUserAgent(), forHTTPHeaderField: "User-Agent")
        request.setValue(Utils.getCookiesMobile(), forHTTPHeaderField: "Cookie")
        request.timeoutInterval = 12

        URLSession.shared.dataTask(with: request) { _, response, _ in
            let length = (response as? HTTPURLResponse)
                .flatMap { $0.value(forHTTPHeaderField: "Content-Length") }
                .flatMap { Int64($0) } ?? 0
            DispatchQueue.main.async {
                askingSize.remove(key)
                let waiting = sizeWaiters.removeValue(forKey: key) ?? []
                guard length > 0 else { return }
                remoteSizes[key] = length
                for report in waiting {
                    report(length)
                }
            }
        }.resume()
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
                "Host": Utils.getURLBase().component(2, separatedBy: "/"),
                "Accept-Encoding": "gzip, deflate, br",
                "Connection": "Keep-Alive",
                "Accept": "*/*",
                "User-Agent": Utils.getUserAgent(),
                "Cookie": Utils.getCookiesMobile()
            ]
//            print("FULL URL: \(fullURL)")
            do {
                // Kept, rather than started and forgotten. Nothing could cancel a transfer before
                // because nobody held on to it - see the note above about it living on a shared
                // session. A reader who has changed their mind needs something to cancel.
                let request = SessionManager.shared.session.download(fullURL, headers: headers)
                inFlight = request
                _ = request.downloadProgress(queue: downloadBufferQueue) { progress in
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
                                                    evaluators: [Utils.getURLBase().component(2, separatedBy: "/"): DisabledTrustEvaluator()])
        self.session = Session(configuration: sessionConfiguration, serverTrustManager: serverTrustManager)
    }
}
