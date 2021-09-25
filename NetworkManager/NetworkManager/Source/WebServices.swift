//
//  WebServices.swift
//  NetworkManager
//
//  Created by Hoang Tran on 26/11/20.
//  Copyright © 2020 Hoang Tran. All rights reserved.
//

import Alamofire
import ObjectMapper

public let webServices = WebServices.shared

open class WebServices: NSObject {
    public static let shared = WebServices()
    public var authToken: AuthToken?
    
    //Configuration
    public var serverPath: String!
    public var language: String!
    public var tokenRefresher: MNTokenRefresher!
    
    open func setup(serverPath: String,
                    language: String,
                    appName: String = "",
                    companyName: String = "",
                    tokenRefresher: MNTokenRefresher = MNTokenRefresher()) {
        self.serverPath = serverPath
        self.language = language
        self.tokenRefresher = tokenRefresher
        
        networkManager.setDelegate(self.tokenRefresher)
        networkManager.updateUserAgentWithAppName(appName, companyName: companyName)
        let headers: [String: String] = ["Accept-Language": language, "time-zone": TimeZone.current.identifier]
        networkManager.updateDefaultHeaders(with: headers)
        networkManager.updateAuthorizedHeaders(with: headers)
        networkManager.updateAnonymousHeaders(with: headers)
    }
    
    open func updateLanguage(_ lang: String) {
        self.language = lang
        let headers: [String: String] = ["Accept-Language": lang]
        networkManager.updateDefaultHeaders(with: headers)
        networkManager.updateAnonymousHeaders(with: headers)
        networkManager.updateAuthorizedHeaders(with: headers)
    }
    
    open func updateRequestHeader(by authToken: AuthToken?) {
        if let token = authToken?.accessToken {
            networkManager.updateAuthorizedHeaders(with: ["Authorization": "Bearer " + token])
        }
        else {
            networkManager.updateAuthorizedHeaders(with: ["Authorization": ""])
        }
        self.authToken = authToken
    }
    
    open func updateRequestHeaderForAnonymous(by auth: AuthToken?) {
        if let token = auth?.accessToken {
            networkManager.updateAuthorizedHeaders(with: ["Authorization": "Bearer " + token])
        }
        else {
            networkManager.updateAuthorizedHeaders(with: ["Authorization": ""])
        }
        self.authToken = auth
    }
    
    @discardableResult public func request(method: HTTPMethod = .get,
                                           service: String,
                                           parameters: NMParameters? = nil,
                                           headerType: NMHeaderType = .authorized,
                                           encoding: ParameterEncoding = JSONEncoding.default,
                                           validate: Bool = true,
                                           completion: @escaping NMResultBlock) -> Request {
        return networkManager.request(method: method,
                                      service: service,
                                      parameters: parameters,
                                      headerType: headerType,
                                      encoding: encoding,
                                      validate: validate,
                                      completion: completion)
    }
    
    public func replaceTokenForRequest(_ request: URLRequest) -> URLRequest? {
        if let oldToken = self.authToken?.oldToken, oldToken.count > 0,
            let newToken = self.authToken?.accessToken {
            if let currentToken = request.value(forHTTPHeaderField: "Authorization") {
                var strings = currentToken.components(separatedBy: "Bearer ")
                if let last = strings.last, last.compare(oldToken) == .orderedSame {
                    strings.removeLast()
                    strings.append(newToken)
                    let authValue = strings.joined(separator: "Bearer ")
                    var newRequest = request
                    newRequest.setValue(authValue, forHTTPHeaderField: "Authorization")
                    print("😋[Info] Replace token for request \(request.url?.absoluteString ?? "")")
                    return newRequest
                }
            }
        }
        return nil
    }
    
    public func canReplaceTokenForRequest(_ request: URLRequest) -> Bool {
        if let oldToken = self.authToken?.oldToken, oldToken.count > 0,
            let _ = self.authToken?.accessToken {
            if let currentToken = request.value(forHTTPHeaderField: "Authorization") {
                if let last = currentToken.components(separatedBy: "Bearer ").last,
                    last.compare(oldToken) == .orderedSame {
                    return true
                }
            }
        }
        return false
    }
}

open class MNTokenRefresher: NSObject, NetworkManagerDelegate {
    public var isRefreshingToken = false
    
    open func networkManager(_ manager: NetworkManager,
                             requestedToRefreshTokenWithAcceptance acceptance: (Bool) -> Void,
                             completion: @escaping ((Bool, Error?) -> Void)) {
        if let refreshToken = webServices.authToken?.refreshToken {
            acceptance(true)
            self.refreshToken(networkManager: manager, refreshToken: refreshToken) { result in
                switch result {
                case .success(let token):
                    if let token = token {
                        webServices.authToken?.updateNewAccessTokenFrom(token)
                        webServices.updateRequestHeader(by: webServices.authToken)
                        NotificationCenter.default.post(name: NSNotification.Name.WebServicesDidRefreshedUserAuthenticationToken, object: webServices.authToken)
                        completion(true, nil)
                    }
                    else {
                        completion(false, nil)
                    }
                case .failure(let result):
                    completion(false, result.errors?.getAnError())
                }
            }
        }
        else {
            acceptance(false)
        }
    }
    
    open func refreshToken(networkManager: NetworkManager,
                           refreshToken: String,
                           completion: @escaping (NMResult<AuthToken?, NetworkManagerFailedData>) -> Void) {
        if self.isRefreshingToken == false {
            self.isRefreshingToken = true
            let params: [String: String] = ["refreshToken" : "Bearer " + refreshToken]
            let path = webServices.serverPath + Constants.Authentication.refreshToken
            networkManager.request(method: .post,
                                   service: path,
                                   parameters: params,
                                   validate: false) { [weak self] result in
                self?.isRefreshingToken = false
                switch result {
                case .success(let data):
                    var auth = Mapper<AuthToken>().map(JSONObject: data.data)
                    if auth?.refreshToken == nil { auth?.refreshToken = refreshToken }
                    completion(.success(auth))
                case .failure(let data):
                    webServices.authToken?.refreshToken = nil
                    completion(.failure(data))
                }
            }
        }
    }
    
    open func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        completion(.success(webServices.replaceTokenForRequest(urlRequest) ?? urlRequest))
    }
    
    open func canReplaceTokenForRequest(_ request: Request) -> Bool {
        if let req = request.request {
            return webServices.canReplaceTokenForRequest(req)
        }
        return false
    }
}

public extension NSNotification.Name {
    static let WebServicesDidRefreshedUserAuthenticationToken = NSNotification.Name("WebServicesDidRefreshedUserAuthenticationToken")
}
