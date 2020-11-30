//
//  NMError.swift
//  NetworkManager
//
//  Created by Hoang Tran on 11/26/20.
//  Copyright © 2020 Hoang Tran. All rights reserved.
//

import Foundation

public struct NMError: Codable, Error {
    
    public var code: String
    public var message: String
    
    public init(err: Error) {
        self.code = "\((err as NSError).code)"
        self.message = err.localizedDescription
    }
    
    public init(code: String = "\(#file).\(#function).\(#line)", message: String) {
        self.code = code
        self.message = message
    }
    
    public init(code: Int) {
        self.code = "\(code)"
        self.message = ""
    }
    
//    public mutating func mapping(map: Map) {
//        if let code = [map.JSON["code"], map.JSON["Code"], map.JSON["errorCode"]].compactMap({ $0 }).first as? String {
//            self.code = code
//        }
//        if let mess = [map.JSON["field"], map.JSON["message"], map.JSON["Message"], map.JSON["errorMessage"]].compactMap({ $0 }).first as? String {
//            self.message = mess
//        }
//    }
    
    public func asNSError() -> NSError {
        return NSError(domain: self.message, code: Int(self.code) ?? 0, userInfo: ["codeString": self.code])
    }
}

public extension Array where Element == NMError {
    func getAnError() -> NSError? {
        for anError in self {
            if let errorCode = Int(anError.code) {
                return NSError(domain: anError.message, code: errorCode, userInfo: nil)
            }
        }
        if let first = self.first {
            return first.asNSError()
        }
        return nil
    }
}

