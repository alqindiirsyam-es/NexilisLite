//
//  LiteBootstrapHTTPSClient.swift
//  NexilisLite
//
//  HTTPS replacement for the pre-decrypt AR01 / SSI01 / SOTL / SVL2 / DF01 operations - the same
//  contract as Android's BootstrapHttpsAuthClient (MABZTAAndroid, com.protector.bootstrapauth):
//
//    POST https://nexilis.io/idp/v1/authn/{challenge, login, otp/send, otp/verify, tfa}
//    Content-Type: application/json, Authorization: Bearer <ZTA install token>
//
//  Bodies use the legacy TMessage body keys literally (A97, A00, A92, A112, B6, Bm, FPR, SIG, PUK).
//  Pinned to the ZTA pins for nexilis.io, no redirects, bounded response, never through nuSDK and
//  never through RILSigningURLProtocol (RIL is enrolled only after the chain, and this runs
//  inside it). Nothing here logs a password, OTP, token or assertion.
//

import Foundation
import NexilisZTA

/// Wire-compatible copies of the TMessage body keys the HTTPS JSON envelope uses (Android:
/// BootstrapLegacyKeys).
enum LiteBootstrapKeys {
    static let code = "A97"
    static let message = "A07"
    static let account = "A00"
    static let accountReal = "A00real"
    /// The CLM connection id the mobile makes (Lite's `connection_id`, the server's IMEI).
    static let connectionID = "B10"
    static let name = "A92"
    static let challenge = "A112"
    static let email = "B6"
    static let password = "Bm"
    static let fingerprint = "FPR"
    static let signature = "SIG"
    static let publicKey = "PUK"
    /// The business entity key: required on /login, /otp/send and /otp/verify.
    static let businessEntity = "Api"
}

struct LiteBootstrapError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
    init(_ message: String) { self.message = message }
}

final class LiteBootstrapHTTPSClient {

    static let maxResponseBytes = 64 * 1024
    private let baseURL: URL
    private let installToken: String

    init(baseURL: URL, installToken: String) {
        self.baseURL = baseURL
        self.installToken = installToken
    }

    func challenge(_ body: [String: Any]) async throws -> [String: Any] { try await post("challenge", body) }
    func login(_ body: [String: Any]) async throws -> [String: Any] { try await post("login", body) }
    func sendOtp(_ body: [String: Any]) async throws -> [String: Any] { try await post("otp/send", body) }
    func verifyOtp(_ body: [String: Any]) async throws -> [String: Any] { try await post("otp/verify", body) }
    func tfa(_ body: [String: Any]) async throws -> [String: Any] { try await post("tfa", body) }

    private func post(_ path: String, _ body: [String: Any]) async throws -> [String: Any] {
        // Barrier #1 first, whoever called: defense in depth, not only the order of the chain.
        try SentinelOfflinePreflight.requireNetworkAllowed()
        var request = URLRequest(url: baseURL.appendingPathComponent(path),
                                 cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("no-store", forHTTPHeaderField: "Cache-Control")
        request.setValue("Bearer " + installToken, forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (stream, response) = try await Self.session.bytes(for: request)
        guard let http = response as? HTTPURLResponse else { throw LiteBootstrapError("Respons autentikasi bootstrap tidak valid.") }
        if (300...399).contains(http.statusCode) {
            stream.task.cancel(); throw LiteBootstrapError("Redirect autentikasi bootstrap ditolak.")
        }
        if http.statusCode >= 500 {
            stream.task.cancel(); throw LiteBootstrapError("Layanan autentikasi bootstrap tidak tersedia.")
        }
        guard (http.value(forHTTPHeaderField: "Content-Type") ?? "").lowercased().hasPrefix("application/json") else {
            stream.task.cancel(); throw LiteBootstrapError("Tipe respons autentikasi bootstrap tidak valid.")
        }
        var bytes = Data()
        for try await byte in stream {
            guard bytes.count < Self.maxResponseBytes else {
                stream.task.cancel(); throw LiteBootstrapError("Respons autentikasi bootstrap terlalu besar.")
            }
            bytes.append(byte)
        }
        guard !bytes.isEmpty, let result = try JSONSerialization.jsonObject(with: bytes) as? [String: Any] else {
            throw LiteBootstrapError("Respons autentikasi bootstrap kosong.")
        }
        // HTTP 4xx is a valid business rejection only when it carries the legacy code.
        if !(200...299).contains(http.statusCode), (result[LiteBootstrapKeys.code] as? String ?? "").isEmpty {
            throw LiteBootstrapError("Layanan autentikasi bootstrap gagal (HTTP \(http.statusCode)).")
        }
        return result
    }

    /// Ephemeral, pinned to the ZTA pins, behind Barrier #1 and nothing else.
    private static let session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.urlCache = nil
        configuration.httpCookieStorage = nil
        configuration.httpShouldSetCookies = false
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.timeoutIntervalForRequest = 15
        configuration.timeoutIntervalForResource = 30
        // Replaces whatever the default configuration carries - in particular RILSigningURLProtocol.
        configuration.protocolClasses = [SentinelOfflineGateURLProtocol.self]
        return URLSession(configuration: configuration, delegate: PinnedNoRedirectDelegate(), delegateQueue: nil)
    }()
}

private final class PinnedNoRedirectDelegate: NSObject, URLSessionTaskDelegate {
    private let pinned = PinnedURLSessionDelegate()
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        pinned.urlSession(session, didReceive: challenge, completionHandler: completionHandler)
    }
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        completionHandler(nil)
    }
}
