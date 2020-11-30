//
//  Models.swift
//  NetworkManager
//
//  Created by Hoang Tran on 11/30/20.
//  Copyright © 2020 Hoang Tran. All rights reserved.
//

import Alamofire
import ObjectMapper

public typealias NMResult = (_ result: Result<NMResultData, NMResultData>) -> Void
public typealias NMProgressBlock = (_ percent: Double, _ objectToUpload: Any) -> Void

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
