//
//  NMError.swift
//  NetworkManager
//
//  Created by Hoang Tran on 11/26/20.
//  Copyright © 2020 Hoang Tran. All rights reserved.
//

import Foundation
import ObjectMapper

struct NMErrorContext: MapContext {
    let statusCode: Int?
}

public struct NMError: Mappable, Error {
    public var code: Int?
    public var message: String?
    public var json: [String: Any]?
    
    //Debug
    public var param: String?
    public var value: String?
    public var location: String?
    
    public init?(map: Map) { }
    
    public mutating func mapping(map: Map) {
        self.code <- map["code"]
        self.message <- map["msg"]
        self.param <- map["param"]
        self.value <- map["value"]
        self.location <- map["location"]
        self.json = map.JSON
        
        //Correction
        self.code = self.code ?? (map.context as? NMErrorContext)?.statusCode
        self.code = self.code ?? (map.context as? NMResultDataContext)?.statusCode
    }
    
    public init(err: Error) {
        self.code = (err as NSError).code
        self.message = err.localizedDescription
    }
    
    public init(code: Int = 0, message: String = "") {
        self.code = code
        self.message = message
    }
    
    public func asNSError() -> NSError {
        return NSError(domain: self.message ?? "", code: self.code ?? 0, userInfo: nil)
    }
}

public extension Array where Element == NMError {
    func getAnError() -> NSError? {
        for anError in self {
            if let errorCode = anError.code {
                return NSError(domain: anError.message ?? "", code: errorCode, userInfo: nil)
            }
        }
        if let first = self.first {
            return first.asNSError()
        }
        return nil
    }
}

