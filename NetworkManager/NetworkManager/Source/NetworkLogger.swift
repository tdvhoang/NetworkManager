//
//  NetworkLogger.swift
//  NetworkManager
//
//  Created by Hoang Tran on 11/30/20.
//  Copyright © 2020 Hoang Tran. All rights reserved.
//

import Foundation
import Alamofire
import ObjectMapper

open class MNNetworkLogger: EventMonitor {
    public let queue = DispatchQueue(label: "MNNetworkLoggerQueue", qos: .utility)
    
    public static var shared = MNNetworkLogger()
    public var prefixString = "[Info]"
    
    private init() {}
    
    public func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        print("\(prefixString) URLSession: \(session), didBecomeInvalidWithError: \(error?.localizedDescription ?? "None")")
    }
    
//    public func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge) {
//        print("🤷\(prefixString) URLSession: \(session), task: \(task), didReceiveChallenge: \(challenge)")
//    }
//
//    public func urlSession(_ session: URLSession,
//                           task: URLSessionTask,
//                           didSendBodyData bytesSent: Int64,
//                           totalBytesSent: Int64,
//                           totalBytesExpectedToSend: Int64) {
//        print("\(prefixString) URLSession: \(session), task: \(task), didSendBodyData: \(bytesSent), totalBytesSent: \(totalBytesSent), totalBytesExpectedToSent: \(totalBytesExpectedToSend)")
//    }
    
//    public func urlSession(_ session: URLSession, taskNeedsNewBodyStream task: URLSessionTask) {
//        print("\(prefixString) URLSession: \(session), taskNeedsNewBodyStream: \(task)")
//    }
    
    public func urlSession(_ session: URLSession,
                           task: URLSessionTask,
                           willPerformHTTPRedirection response: HTTPURLResponse,
                           newRequest request: URLRequest) {
        print("\(prefixString) URLSession: \(session), task: \(task), willPerformHTTPRedirection: \(response), newRequest: \(request)")
    }
    
//    public func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
//        print("\(prefixString) URLSession: \(session), task: \(task), didFinishCollecting: \(metrics)")
//    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        print("\(prefixString) URLSession: \(session), task: \(task), didCompleteWithError: \(error?.localizedDescription ?? "None")")
    }
    
    public func urlSession(_ session: URLSession, taskIsWaitingForConnectivity task: URLSessionTask) {
        print("🥺\(prefixString) URLSession: \(session), taskIsWaitingForConnectivity: \(task)")
    }
    
//    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
//        print("\(prefixString) URLSession: \(session), dataTask: \(dataTask), didReceiveDataOfLength: \(data.count)")
//    }
    
//    public func urlSession(_ session: URLSession,
//                           dataTask: URLSessionDataTask,
//                           willCacheResponse proposedResponse: CachedURLResponse) {
//        print("\(prefixString) URLSession: \(session), dataTask: \(dataTask), willCacheResponse: \(proposedResponse)")
//    }
    
    public func urlSession(_ session: URLSession,
                           downloadTask: URLSessionDownloadTask,
                           didResumeAtOffset fileOffset: Int64,
                           expectedTotalBytes: Int64) {
        print("😎\(prefixString) URLSession: \(session), downloadTask: \(downloadTask), didResumeAtOffset: \(fileOffset), expectedTotalBytes: \(expectedTotalBytes)")
    }
    
//    public func urlSession(_ session: URLSession,
//                           downloadTask: URLSessionDownloadTask,
//                           didWriteData bytesWritten: Int64,
//                           totalBytesWritten: Int64,
//                           totalBytesExpectedToWrite: Int64) {
//        print("\(prefixString) URLSession: \(session), downloadTask: \(downloadTask), didWriteData bytesWritten: \(bytesWritten), totalBytesWritten: \(totalBytesWritten), totalBytesExpectedToWrite: \(totalBytesExpectedToWrite)")
//    }
    
    public func urlSession(_ session: URLSession,
                           downloadTask: URLSessionDownloadTask,
                           didFinishDownloadingTo location: URL) {
        print("🥳\(prefixString) URLSession: \(session), downloadTask: \(downloadTask), didFinishDownloadingTo: \(location)")
    }
    
    public func request(_ request: Request, didCreateInitialURLRequest urlRequest: URLRequest) {
        print("\(prefixString) Initial Create URLRequest: \(urlRequest.url?.absoluteString ?? "None")")
    }
    
    public func request(_ request: Request, didFailToCreateURLRequestWithError error: Error) {
        print("\(prefixString) Request: \(request) didFailToCreateURLRequestWithError: \(error)")
    }
    
    public func request(_ request: Request, didAdaptInitialRequest initialRequest: URLRequest, to adaptedRequest: URLRequest) {
        if initialRequest != adaptedRequest {
            print("\(prefixString) Request: \(request) didAdaptInitialRequest \(initialRequest) to \(adaptedRequest)")
        }
    }
    
    public func request(_ request: Request, didFailToAdaptURLRequest initialRequest: URLRequest, withError error: Error) {
        print("\(prefixString) Request: \(request) didFailToAdaptURLRequest \(initialRequest) withError \(error)")
    }
    
//    public func request(_ request: Request, didCreateURLRequest urlRequest: URLRequest) {
//        print("\(prefixString) Request: \(request) didCreateURLRequest: \(urlRequest.url?.absoluteString ?? "None")")
//    }
//
//    public func request(_ request: Request, didCreateTask task: URLSessionTask) {
//        print("\(prefixString) Request: \(request) didCreateTask \(task)")
//    }
    
    public func request(_ request: Request, didGatherMetrics metrics: URLSessionTaskMetrics) {
//        print("\(prefixString) Request: \(request) didGatherMetrics \(metrics)")
    }
    
    public func request(_ request: Request, didFailTask task: URLSessionTask, earlyWithError error: Error) {
        print("\(prefixString) Request: \(request) didFailTask \(task) earlyWithError \(error)")
    }
    
    public func request(_ request: Request, didCompleteTask task: URLSessionTask, with error: Error?) {
        print("\(prefixString) Request: \(request) didCompleteTask \(task) withError: \(error?.localizedDescription ?? "None")")
    }
    
    public func requestDidFinish(_ request: Request) {
        print("\(prefixString) Request didFinish: \(request)")
    }
    
    public func requestDidResume(_ request: Request) {
        print("\(prefixString) Request didResume: \(request)")
    }
    
//    public func request(_ request: Request, didResumeTask task: URLSessionTask) {
//        print("\(prefixString) Request: \(request) didResumeTask: \(task)")
//    }
    
    public func requestDidSuspend(_ request: Request) {
        print("\(prefixString) Request didSuspend: \(request)")
    }
    
    public func request(_ request: Request, didSuspendTask task: URLSessionTask) {
        print("\(prefixString) Request: \(request) didSuspendTask: \(task)")
    }
    
    public func requestDidCancel(_ request: Request) {
        print("\(prefixString) Request didCancel: \(request)")
    }
    
    public func request(_ request: Request, didCancelTask task: URLSessionTask) {
        print("\(prefixString) Request: \(request) didCancelTask: \(task)")
    }
    
//    public func request(_ request: DataRequest, didParseResponse response: DataResponse<Data?, Error>) {
//        print("\(prefixString) Request: \(request), didParseResponse: \(response)")
//    }
//
//    public func request<Value>(_ request: DataRequest, didParseResponse response: DataResponse<Value, Error>) {
//        print("\(prefixString) Request: \(request), didParseResponse: \(response)")
//    }
//
//    public func request(_ request: DownloadRequest, didParseResponse response: DownloadResponse<Data?, Error>) {
//        print("\(prefixString) Request: \(request), didParseResponse: \(response)")
//    }
//
//    public func request<Value>(_ request: DownloadRequest, didParseResponse response: DownloadResponse<Value, Error>) {
//        print("\(prefixString) Request: \(request), didParseResponse: \(response)")
//    }
    
    public func requestIsRetrying(_ request: Request) {
        print("\(prefixString) Request isRetrying: \(request)")
    }
    
//    public func request(_ request: DataRequest, didValidateRequest urlRequest: URLRequest?, response: HTTPURLResponse, data: Data?, withResult result: Request.ValidationResult) {
//        print("\(prefixString) Request: \(request), didValidateRequestWithResult: \(result)")
//    }
    
    public func request(_ request: DataStreamRequest, didValidateRequest urlRequest: URLRequest?, response: HTTPURLResponse, withResult result: Request.ValidationResult) {
        print("\(prefixString) Request: \(request), didValidateRequestWithResult: \(result)")
    }
    
    public func request<Value>(_ request: DataStreamRequest, didParseStream result: Result<Value, AFError>) {
        print("\(prefixString) Request: \(request), didParseStreamWithResult: \(result)")
    }
    
    public func request(_ request: UploadRequest, didCreateUploadable uploadable: UploadRequest.Uploadable) {
        print("\(prefixString) Request: \(request), didCreateUploadable: \(uploadable)")
    }
    
    public func request(_ request: UploadRequest, didFailToCreateUploadableWithError error: Error) {
        print("\(prefixString) Request: \(request), didFailToCreateUploadableWithError: \(error)")
    }
    
//    public func request(_ request: UploadRequest, didProvideInputStream stream: InputStream) {
//        print("\(prefixString) Request: \(request), didProvideInputStream: \(stream)")
//    }
    
    public func request(_ request: DownloadRequest, didFinishDownloadingUsing task: URLSessionTask, with result: Result<URL, Error>) {
        print("\(prefixString) Request: \(request), didFinishDownloadingUsing: \(task), withResult: \(result)")
    }
    
//    public func request(_ request: DownloadRequest, didCreateDestinationURL url: URL) {
//        print("\(prefixString) Request: \(request), didCreateDestinationURL: \(url)")
//    }
    
    public func request(_ request: DownloadRequest, didValidateRequest urlRequest: URLRequest?, response: HTTPURLResponse, temporaryURL: URL?, destinationURL: URL?, withResult result: Request.ValidationResult) {
        print("\(prefixString) Request: \(request), didValidateRequestWithResult: \(result)")
    }
}

//MARK: - Custom cURL print
extension Request {
    /// cURL representation of the instance.
    ///
    /// - Returns: The cURL equivalent of the instance.
    public func cURLString() -> String {
        guard
            let request = lastRequest,
            let url = request.url,
            let host = url.host,
            let method = request.httpMethod else { return "$ curl command could not be created" }

        var components = ["curl -v \"\(url.absoluteString)\""]

        components.append("-X \(method)")

        if let credentialStorage = delegate?.sessionConfiguration.urlCredentialStorage {
            let protectionSpace = URLProtectionSpace(host: host,
                                                     port: url.port ?? 0,
                                                     protocol: url.scheme,
                                                     realm: host,
                                                     authenticationMethod: NSURLAuthenticationMethodHTTPBasic)

            if let credentials = credentialStorage.credentials(for: protectionSpace)?.values {
                for credential in credentials {
                    guard let user = credential.user, let password = credential.password else { continue }
                    components.append("-u \(user):\(password)")
                }
            } else {
                if let credential = credential, let user = credential.user, let password = credential.password {
                    components.append("-u \(user):\(password)")
                }
            }
        }

        if let configuration = delegate?.sessionConfiguration, configuration.httpShouldSetCookies {
            if
                let cookieStorage = configuration.httpCookieStorage,
                let cookies = cookieStorage.cookies(for: url), !cookies.isEmpty {
                let allCookies = cookies.map { "\($0.name)=\($0.value)" }.joined(separator: ";")

                components.append("-b \"\(allCookies)\"")
            }
        }

        var headers = HTTPHeaders()

        if let sessionHeaders = delegate?.sessionConfiguration.headers {
            for header in sessionHeaders where header.name != "Cookie" {
                headers[header.name] = header.value
            }
        }

        for header in request.headers where header.name != "Cookie" {
            headers[header.name] = header.value
        }

        for header in headers {
            let escapedValue = header.value.replacingOccurrences(of: "\"", with: "\\\"")
            components.append("-H \"\(header.name): \(escapedValue)\"")
        }

        if let httpBodyData = request.httpBody {
            let httpBody = String(decoding: httpBodyData, as: UTF8.self)
            var escapedBody = httpBody.replacingOccurrences(of: "\\\"", with: "\\\\\"")
            escapedBody = escapedBody.replacingOccurrences(of: "\"", with: "\\\"")

            components.append("-d \"\(escapedBody)\"")
        }

        return components.joined(separator: " \\\n\t")
    }
    
    public func printLog<T>(for response: AFDataResponse<T>, cURL: String) {
        #if DEBUG
        DispatchQueue.global().async {
            var logStrs: [String] = [ "🙏 request with cURL: \n\(cURL)"]
            defer {
                print(logStrs.joined(separator: "\n"))
            }
            let statusCode = response.response?.statusCode ?? 0
            if let start = response.metrics?.taskInterval.start, let duration = response.metrics?.taskInterval.duration {
                logStrs.append("start \(start)")
                logStrs.append("duration \(String(format: "%.3f", duration))s")
            }
            logStrs.append("response header: \((response.response?.allHeaderFields as? [String: Any])?.toJsonString(prettyPrinted: false) ?? "")")
            var statusEmoji = "🤔"
            if statusCode > 199 && statusCode < 300 { statusEmoji = "😁" }
            else if statusCode > 399 && statusCode < 500 { statusEmoji = "☹️" }
            logStrs.append("\(statusEmoji) status code: \(statusCode)")
            var dataDebug: String!
            switch response.result {
            case .success(let data as Any):
                dataDebug = "data:\n"
                if let data = data as? [String: Any] {
                    dataDebug += data.toJsonString()
                }
                else if let data = data as? String {
                    dataDebug += data
                }
                else if let data = data as? Data, let str = String(data: data, encoding: .utf8) {
                    dataDebug += str
                }
                else {
                    dataDebug += "\(data)"
                }
                logStrs.append(dataDebug)
                break
            case .failure(let error):
                logStrs.append("Error: \(error)")
                break
            }
        }
        #endif
    }
}

extension Dictionary where Key == String {
    func toJsonString(prettyPrinted: Bool = true) -> String {
        if let stringData = try? JSONSerialization.data(withJSONObject: self, options: prettyPrinted ? .prettyPrinted : []) {
            if let string = String(data: stringData, encoding: .utf8) {
                return string
            }
        }
        return ""
    }
}
