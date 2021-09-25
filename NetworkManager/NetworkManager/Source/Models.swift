//
//  Models.swift
//  NetworkManager
//
//  Created by Hoang Tran on 11/30/20.
//  Copyright © 2020 Hoang Tran. All rights reserved.
//

import Alamofire
import ObjectMapper

typealias NetworkBoolCompletion = (NMResult<Bool?, NetworkManagerFailedData>) -> Void
typealias NetworkStringCompletion = (NMResult<String?, NetworkManagerFailedData>) -> Void
typealias NetworkAnyCompletion = (NMResult<Any?, NetworkManagerFailedData>) -> Void
typealias NetworkURLCompletion = (NMResult<URL?, NetworkManagerFailedData>) -> Void
typealias NetworkRawDataCompletion = (NMResult<NetworkManagerSuccessData, NetworkManagerFailedData>) -> Void

typealias NetworkArrayCompletion<T> = (NMResult<[T]?, NetworkManagerFailedData>) -> Void
typealias NetworkObjectCompletion<T> = (NMResult<T?, NetworkManagerFailedData>) -> Void
typealias NetworkPagingCompletion<T: BaseMappable> = (NMResult<NMPagingResult<T>?, NetworkManagerFailedData>) -> Void

struct NMPagingResult<T: BaseMappable> {
    public var data: [T]?
    public var paging: NetworkManagerPagingData?
    
    init(result: NetworkManagerSuccessData) {
        self.data = Mapper<T>().mapArray(JSONObject: result.data)
        self.paging = result.paging
    }
}

public enum NMResult<Success, Failure> {
    case success(Success)
    case failure(Failure)
}

public typealias NMResultBlock = (_ result: NMResult<NetworkManagerSuccessData, NetworkManagerFailedData>) -> Void
public typealias NMDownloadResultBlock = (_ result: NMResult<URL?, Error>) -> Void

/// objectUsedToUpload maybe UIImage/String/URL
public typealias NMProgressBlock = (_ percent: Double, _ objectUsedToUpload: Any?) -> Void

public protocol NMParameters { }
public extension NMParameters {
    func getParametersAsDict() -> [String: Any]? { return self as? Parameters }
    func modifierForRequest(_ request: inout URLRequest) throws -> Void {
        try (self as? Array<Any>)?.modifierForRequest(&request)
        try (self as? Dictionary<AnyHashable, Any>)?.modifierForRequest(&request)
    }
}

extension Dictionary: NMParameters {
    func modifierForRequest(_ request: inout URLRequest) throws -> Void { }
}

extension Array: NMParameters {
    func modifierForRequest(_ request: inout URLRequest) throws -> Void {
        if self.count > 0 {
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: self)
        }
    }
}

public enum NMHeaderType {
    case `default`, anonymous, authorized
    case defaultWithAdditionalFields(HTTPHeaders)
    case anonymousWithAdditionalFields(HTTPHeaders)
    case authorizedWithAdditionalFields(HTTPHeaders)
    
    func isAuthorized() -> Bool {
        switch self {
        case .authorized, .anonymousWithAdditionalFields(_):
            return true
        default:
            return false
        }
    }
}
