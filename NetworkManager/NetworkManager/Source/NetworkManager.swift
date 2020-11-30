//
//  NetworkManager.swift
//  NetworkManager
//
//  Created by Hoang Tran on 26/11/20.
//  Copyright © 2020 Hoang Tran. All rights reserved.
//

import Alamofire
import ObjectMapper

public protocol NetworkManagerDelegate: class, RequestAdapter {
    func networkManager(_ manager: NetworkManager, requestedToRefreshTokenWithAcceptance acceptance: (Bool) -> Void, completion: @escaping ((Bool, Error?) -> Void))
    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void)
    func canReplaceTokenForRequest(_ request: Request) -> Bool
}

open class NetworkManager {
    public static let shared = NetworkManager()
    
    private let sessionManager: Session
    private weak var delegate: NetworkManagerDelegate!
    private var acceptedHTTPCodes = [Int]()
    private var interceptor = SessionManagerRetrier()
    
    private lazy var defaultHeaders = HTTPHeaders.default
    private lazy var anonymousHeaders = HTTPHeaders.default
    private lazy var authorizedHeaders = HTTPHeaders.default
    
    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.allowsCellularAccess = true
        configuration.timeoutIntervalForRequest = 60
        configuration.timeoutIntervalForResource = 120
        configuration.urlCredentialStorage = nil
		configuration.httpMaximumConnectionsPerHost = 10
		
        sessionManager = Session(configuration: configuration, interceptor: interceptor, eventMonitors: [MNNetworkLogger.shared])
        
        self.acceptedHTTPCodes.append(contentsOf: Array<Int>(200..<300))
        self.acceptedHTTPCodes.append(contentsOf: [400, 402, 403, 404])
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
                        headerType: NMHeaderType = NMHeaderType.authorized,
                        encoding: ParameterEncoding = JSONEncoding.default,
                        validate: Bool = true,
                        completion: @escaping NMResult) -> Request {
        let headers = getHeaderFieldsForType(headerType)
        
        var req = sessionManager.request(service,
                                              method: method,
                                              parameters: parameters?.getParametersAsDict(),
                                              encoding: encoding,
                                              headers: headers,
                                              requestModifier: parameters?.modifierForRequest)
        if validate {
            req = req.validate(statusCode: self.acceptedHTTPCodes)
        }
        var cURL = ""
        req.cURLDescription { [unowned req] _ in
            cURL = req.cURLString()
        }
        req.responseJSON { [weak self] response in
            req.printLog(for: response, cURL: cURL)
            self?.handleParseDataResponse(response, completion: completion)
        }
        
        return req
    }
    
    @discardableResult
    public func uploadObject(_ object: Any,
                             to url: URL,
                             headerType: NMHeaderType = NMHeaderType.default,
                             encoding: ParameterEncoding = JSONEncoding.default,
                             body: [String: String]? = nil,
                             validate: Bool = true,
                             progression: NMProgressBlock?,
                             completion: @escaping NMResult) -> Request {
        let headers = self.getHeaderFieldsForType(headerType)
        
        var req = sessionManager.upload(multipartFormData: { formData in
            if let body = body {
                for (key, value) in body {
                    if let data = value.data(using: .utf8) {
                        formData.append(data, withName: key)
                    }
                }
            }
            if let photoURL = object as? URL {
                formData.append(photoURL, withName: "file")
            }
            else if let image = object as? UIImage {
                if let data = image.jpegData(compressionQuality: 0.5) {
                    formData.append(data, withName: "file", mimeType: "image/jpeg")
                }
            }
        }, to: url, headers: headers)
        req.uploadProgress(closure: { progress in
            progression?(progress.fractionCompleted, object)
        })
        if validate {
            req = req.validate(statusCode: self.acceptedHTTPCodes)
        }
        var cURL = ""
        req.cURLDescription { [unowned req] _ in
            cURL = req.cURLString()
        }
        req.responseData(completionHandler: { response in
            req.printLog(for: response, cURL: cURL)
            var string = ""
            if let data = response.data, let str = String(data: data, encoding: .utf8) {
                string = str
            }
            let resultData = NMResultData(statusCode: response.response?.statusCode ?? 0, string: string)
            completion(.success(resultData))
        })
        
        return req
    }
    
    @discardableResult
    public func uploadImage(_ image: UIImage,
                            to url: URL,
                            headerType: NMHeaderType = NMHeaderType.default,
                            encoding: ParameterEncoding = JSONEncoding.default,
                            body: [String: String]? = nil,
                            validate: Bool = true,
                            progression: NMProgressBlock?,
                            completion: @escaping NMResult) -> Request {
        return self.uploadObject(image, to: url, headerType: headerType, encoding: encoding, body: body, validate: validate, progression: progression, completion: completion)
    }
    
    @discardableResult
    public func uploadPhotoURL(_ photoURL: URL,
                               to url: URL,
                               headerType: NMHeaderType = NMHeaderType.default,
                               encoding: ParameterEncoding = JSONEncoding.default,
                               body: [String: String]? = nil,
                               validate: Bool = true,
                               progression: NMProgressBlock?,
                               completion: @escaping NMResult) -> Request {
        return self.uploadObject(photoURL, to: url, headerType: headerType, encoding: encoding, body: body, validate: validate, progression: progression, completion: completion)
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
        let userAgent = "\(companyName)/\(name)-\(appVersion)"
        self.defaultHeaders.update(HTTPHeader.userAgent(userAgent))
        self.anonymousHeaders.update(HTTPHeader.userAgent(userAgent))
        self.authorizedHeaders.update(HTTPHeader.userAgent(userAgent))
    }
}

private extension NetworkManager {
    func handleParseDataResponse(_ response: AFDataResponse<Any>,
                                 successCode: String = "",
                                 completion: @escaping NMResult) {
        var statusCode: Int?
        if let responseValue = response.response {
            statusCode = responseValue.statusCode
        }
        if statusCode == 401 {
            self.interceptor.isTokenExpired = true
        }
        switch response.result {
        case .success(let value):
            let boundCode = self.parseSuccessCodeMessage(value)
            if boundCode.isSuccess {
                let resultData = NMResultData(statusCode: statusCode ?? 0,result: value, data: self.parseData(value))
                completion(.success(resultData))
            }
            else {
                let errors = self.parseErrors(errors: boundCode.errors)
                let resultData = NMResultData(statusCode: statusCode ?? 0, requestID: boundCode.requestId, errors: errors)
                completion(.failure(resultData))
            }
        case .failure(let error as NSError):
            let resultData = NMResultData(statusCode: statusCode ?? error.code, requestID: "n/a", errors: [NMError(err: error)])
            completion(.failure(resultData))
        }
    }
    
    func parseSuccessCodeMessage(_ response: Any)
        -> (isSuccess:Bool, errors: Any?, requestId: String) {
        var isSuccess: Bool = false
        var errors: Any? = nil
        var requestId: String = ""
        if let dictData = response as? [String : Any] {
            if let value = dictData["isSuccess"] as? Bool {
                isSuccess = value
            } else if let value = dictData["IsSuccess"] as? Bool {
                isSuccess = value
            }
            
            if let errorsData = dictData["errors"] {
                errors = errorsData
            } else if let errorsData = dictData["Errors"] as? String {
                errors = errorsData
            }
            if errors == nil {
                errors = self.parseData(response)
            }
            
            if let value = dictData["requestId"] as? String {
                requestId = value
            } else if let value = dictData["requestID"] as? String {
                requestId = value
            }
        }
        return (isSuccess, errors, requestId)
    }
    
    func parseData(_ response: Any) -> Any? {
        if let dictData = response as? [String : Any] {
            if let data = dictData["data"] {
                return data
            } else if let data = dictData["responsData"] {
                return data
            }
        }
        return nil
    }
    
    func parseErrors(errors: Any?) -> [NMError]? {
        if let mess = errors as? String {
            return [NMError(code: "0", message: mess)]
        }
//        var data = Data(json.utf8)
//        let decoder = JSONDecoder()
//        return try? decoder.decode([NMError].self, from: errors)
        return nil
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
