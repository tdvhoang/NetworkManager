//
//  NetworkManager.swift
//  NetworkManager
//
//  Created by Hoang Tran on 26/11/20.
//  Copyright © 2020 Hoang Tran. All rights reserved.
//

import Alamofire
import ObjectMapper

public protocol NetworkManagerDelegate: AnyObject, RequestAdapter {
    func networkManager(_ manager: NetworkManager, requestedToRefreshTokenWithAcceptance acceptance: (Bool) -> Void, completion: @escaping ((Bool, Error?) -> Void))
    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void)
    func canReplaceTokenForRequest(_ request: Request) -> Bool
}

let networkManager = NetworkManager.shared

open class NetworkManager {
    public static let shared = NetworkManager()
    
    private let sessionManager: Session
    private weak var delegate: NetworkManagerDelegate!
    private var acceptedHTTPCodes = [Int]()
    private let interceptor = SessionManagerRetrier()
    
    private lazy var defaultHeaders = HTTPHeaders.default
    private lazy var anonymousHeaders = HTTPHeaders.default
    private lazy var authorizedHeaders = HTTPHeaders.default
    
    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.allowsCellularAccess = true
        #if DEBUG
        configuration.timeoutIntervalForRequest = 20
        #else
        configuration.timeoutIntervalForRequest = 60
        #endif
        configuration.timeoutIntervalForResource = 120
        configuration.urlCredentialStorage = nil
        configuration.httpMaximumConnectionsPerHost = 10
        
        sessionManager = Session(configuration: configuration, interceptor: interceptor, eventMonitors: [MNNetworkLogger.shared])
        
        acceptedHTTPCodes.append(contentsOf: Array<Int>(200..<300))
        acceptedHTTPCodes.append(contentsOf: [400, 402, 403, 404])
    }
    
    public func setDelegate(_ delegate: NetworkManagerDelegate) {
        self.interceptor.delegate = self
        self.delegate = delegate
    }
    
    func updateDefaultHeaders(with dictHeader: [String: String]) {
        for (key, value) in dictHeader {
            self.defaultHeaders[key] = value
        }
    }
    
    func updateAnonymousHeaders(with dictHeader: [String: String]) {
        for (key, value) in dictHeader {
            self.anonymousHeaders[key] = value
        }
    }
    
    func updateAuthorizedHeaders(with dictHeader: [String: String]) {
        for (key, value) in dictHeader {
            self.authorizedHeaders[key] = value
        }
    }
    
    @discardableResult
    public func request(method: HTTPMethod = .get,
                        service: String,
                        parameters: NMParameters? = nil,
                        headerType: NMHeaderType = .authorized,
                        encoding: ParameterEncoding = JSONEncoding.default,
                        validate: Bool = true,
                        completion: @escaping NMResultBlock) -> Request {
        let headers = getHeaderFieldsForType(headerType)
        
        var req = sessionManager.request(service,
                                         method: method,
                                         parameters: parameters?.getParametersAsDict(),
                                         encoding: encoding,
                                         headers: headers,
                                         requestModifier: parameters?.modifierForRequest)
        if validate {
            req = req.validate(statusCode: acceptedHTTPCodes)
        }
        var cURL = ""
        req.cURLDescription { [unowned req] _ in
            cURL = req.cURLString()
        }
        req.responseJSON { [weak self] response in
            req.printLog(for: response, cURL: cURL)
            self?.parseDataResponse(response, completion: completion)
        }
        
        return req
    }
    
    @discardableResult
    public func uploadWith(body: [(String, Any)],
                           to path: String,
                           headerType: NMHeaderType = .authorized,
                           validate: Bool = true,
                           progression: NMProgressBlock?,
                           completion: @escaping NMResultBlock) -> Request {
        let headers = self.getHeaderFieldsForType(headerType)
        var objectUsedToUpload: Any? = nil
        var req = sessionManager.upload(multipartFormData: { formData in
            for (index, item) in body.enumerated() {
                let (key, value) = item
                switch value {
                case let string as String:
                    if let data = string.data(using: .utf8) {
                        formData.append(data, withName: key)
                    }
                case let photoURL as URL:
                    formData.append(photoURL, withName: key)
                    objectUsedToUpload = photoURL
                case let image as UIImage:
                    if let data = image.jpegData(compressionQuality: 0.5) {
                        formData.append(data, withName: key, fileName: "img_\(index).jpg", mimeType: "image/jpeg")
                    }
                    objectUsedToUpload = image
                default:
                    break
                }
            }
        }, to: path, headers: headers)
        req.uploadProgress(closure: { progress in
            progression?(progress.fractionCompleted, objectUsedToUpload)
        })
        if validate {
            req = req.validate(statusCode: acceptedHTTPCodes)
        }
        var cURL = ""
        req.cURLDescription { [unowned req] _ in
            cURL = req.cURLString()
        }
        req.responseData(completionHandler: { [weak self] response in
            req.printLog(for: response, cURL: cURL)
            var string = ""
            if let data = response.data {
                if let dict = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) {
                    self?.parseDataResponse(response, dict: dict, completion: completion)
                    return
                }
                else if let str = String(data: data, encoding: .utf8) {
                    string = str
                }
            }
            let result = NMResultData(statusCode: response.response?.statusCode ?? 0, string: string, response: response.response)
            completion(.success(result))
        })
        
        return req
    }
    
    @discardableResult
    public func download(method: HTTPMethod = .get,
                        service: Alamofire.URLConvertible,
                        parameters: NMParameters? = nil,
                        headerType: NMHeaderType = .anonymous,
                        validate: Bool = false,
                        progression: NMProgressBlock? = nil,
                        completion: @escaping NMDownloadResultBlock) -> Request {
        let headers = getHeaderFieldsForType(headerType)
        
        let destination: DownloadRequest.Destination = { (url, response) -> (URL, Alamofire.DownloadRequest.Options) in
            var fileInTempFolder = FileManager.default.temporaryDirectory
            fileInTempFolder.appendPathComponent(response.url?.lastPathComponent ?? url.lastPathComponent)
            return (fileInTempFolder, [.removePreviousFile, .createIntermediateDirectories])
        }
        
        var req = sessionManager.download(service,
                                         method: method,
                                         parameters: parameters?.getParametersAsDict(),
                                         headers: headers,
                                         requestModifier: parameters?.modifierForRequest,
                                         to: destination)
        if validate {
            req = req.validate(statusCode: acceptedHTTPCodes)
        }
        var cURL = ""
        req.cURLDescription { [unowned req] _ in
            cURL = req.cURLString()
        }
        req.downloadProgress {
            progression?($0.fractionCompleted, service)
        }
        req.responseURL { response in
            req.printLog(for: response, cURL: cURL)
            switch response.result {
            case .success(let url):
                completion(.success(url))
            case .failure(let error):
                completion(.failure(error))
            }
        }
        return req
    }
    
    private func getHeaderFieldsForType(_ headerType: NMHeaderType) -> HTTPHeaders? {
        var headers: HTTPHeaders?
        switch headerType {
        case .default:
            headers = self.defaultHeaders
        case .defaultWithAdditionalFields(let additionalFields):
            headers = self.defaultHeaders
            for (key, value) in additionalFields.dictionary {
                headers?[key] = value
            }
            
        case .anonymous:
            headers = self.anonymousHeaders
        case .anonymousWithAdditionalFields(let additionalFields):
            headers = self.anonymousHeaders
            for (key, value) in additionalFields.dictionary {
                headers?[key] = value
            }
            
        case .authorized:
            headers = self.authorizedHeaders
        case .authorizedWithAdditionalFields(let additionalFields):
            headers = self.authorizedHeaders
            for (key, value) in additionalFields.dictionary {
                headers?[key] = value
            }
        }
        
        return headers
    }
    
    func updateUserAgentWithAppName(_ appName: String, companyName: String) {
        let info = Bundle.main.infoDictionary
        let appVersion = info?["CFBundleShortVersionString"] as? String ?? "Unknown"
        var name = appName
        if name.isEmpty {
            name = info?["CFBundleName"] as? String ?? "Unknown"
        }
        let userAgent = "\(companyName)/\(name)-iOS-\(appVersion)"
        self.defaultHeaders.update(HTTPHeader.userAgent(userAgent))
        self.anonymousHeaders.update(HTTPHeader.userAgent(userAgent))
        self.authorizedHeaders.update(HTTPHeader.userAgent(userAgent))
    }
}

private extension NetworkManager {
    func parseDataResponse<T>(_ response: AFDataResponse<T>,
                              dict: Any? = nil,
                              completion: @escaping NMResultBlock) {
        var statusCode: Int?
        if let responseValue = response.response {
            statusCode = responseValue.statusCode
        }
        if statusCode == 401 {
            self.interceptor.isTokenExpired = true
        }
        switch response.result {
        case .success(let value):
            let context = NMResultDataContext(data: response.data, statusCode: statusCode)
            let result = Mapper<NMResultData>(context: context).map(JSONObject: dict ?? value)
            if var result = result {
                result.response = response.response
                statusCode = result.statusCode ?? statusCode
                result.statusCode = result.statusCode ?? statusCode
                if result.errors == nil && statusCode != nil && statusCode! < 400 && statusCode != 401 {
                    completion(.success(result))
                }
                else {
                    completion(.failure(result))
                }
            }
            else {
                let failedResult = NMResultData(statusCode: statusCode ?? 0, errors: nil, response: response.response)
                completion(.failure(failedResult))
            }
        case .failure(let error):
            statusCode = statusCode ?? (error.underlyingError as NSError?)?.code
            let resultData = NMResultData(statusCode: statusCode ?? 0, errors: [NMError(err: error)], response: response.response)
            completion(.failure(resultData))
        }
    }
}

extension NetworkManager: SessionManagerRetrierDelegate {
    func refreshToken(acceptance: ((Bool) -> Void), completion: @escaping ((Bool, Error?) -> Void)) {
        self.delegate.networkManager(self, requestedToRefreshTokenWithAcceptance: acceptance, completion: completion)
    }
    
    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        self.delegate.adapt(urlRequest, for: session, completion: completion)
    }
    
    func canReplaceTokenForRequest(_ request: Request) -> Bool {
        return self.delegate.canReplaceTokenForRequest(request)
    }
}

private protocol SessionManagerRetrierDelegate {
    func refreshToken(acceptance: ((Bool) -> Void), completion: @escaping ((Bool, Error?) -> Void))
    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void)
    func canReplaceTokenForRequest(_ request: Request) -> Bool
}

private class SessionManagerRetrier: RequestInterceptor {
    private lazy var completions = [(RetryResult) -> Void]()
    fileprivate var delegate: SessionManagerRetrierDelegate?
    fileprivate var isTokenExpired = false
    fileprivate var isRefreshingToken = false
    
    func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        if (request.task?.response as? HTTPURLResponse)?.statusCode == 401 ||
            request.response?.statusCode == 401 ||
            (error as NSError).code == 401 {
            if self.delegate?.canReplaceTokenForRequest(request) == true {
                completion(.retryWithDelay(0.1))
            }
            else {
                if self.isRefreshingToken {
                    self.completions.append(completion)
                }
                else {
                    self.delegate?.refreshToken(acceptance: { [weak self] refresh in
                        self?.isTokenExpired = true
                        if refresh {
                            self?.isRefreshingToken = true
                            self?.completions.append(completion)
                        }
                        else {
                            completion(.doNotRetry)
                            self?.completions.forEach({ $0(.doNotRetry) })
                            self?.completions.removeAll()
                        }
                    }, completion: { [weak self] (success, error) in
                        self?.isRefreshingToken = false
                        self?.isTokenExpired = false
                        var result: RetryResult = .retryWithDelay(0.1)
                        if success == false {
                            result = .doNotRetry
                            if let error = error {
                                result = .doNotRetryWithError(error)
                            }
                        }
                        self?.completions.forEach({ $0(result) })
                        self?.completions.removeAll()
                    })
                }
            }
        }
        else {
            completion(.doNotRetry)
        }
    }
    
    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        if let delegate = self.delegate {
            delegate.adapt(urlRequest, for: session, completion: completion)
        }
        else {
            completion(.success(urlRequest))
        }
    }
}
