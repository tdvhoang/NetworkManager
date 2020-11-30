//
//  NMResultData.swift
//  NetworkManager
//
//  Created by Hoang Tran on 11/26/20.
//  Copyright © 2020 Hoang Tran. All rights reserved.
//

import Foundation

public struct NMResultData: Error {
    public var result: Any? //Data return from backend
    public var data: Any? //data = result["data"]
    public var message: String? //message = result["message"]
    public var statusCode: Int
    
    //Paging
    public var total: Int?
    public var paging: Paging?
    
    //Debug
    public var requestID: String?
    public var errors: [NMError]?
    
    public init(statusCode: Int, string: String) {
        self.statusCode = statusCode
        self.data = string
        self.result = string
    }
    
    public init(statusCode: Int, result: Any?, data: Any?) {
        self.statusCode = statusCode
        self.result = result
        self.data = data
        
        //From result
        if let dict = result as? [String: Any] {
            //Total
            if let total = dict["total"] as? Int {
                self.total = total
            }
            //Message
            self.message = dict["message"] as? String
            //RequestID
            self.requestID = dict["requestId"] as? String
        }
        
        //Paging
        if let dict = data as? [String: Any] {
            let page = dict["page"] as? Int
            let totalPages = dict["totalPages"] as? Int
            let limit = dict["limit"] as? Int
            let total = dict["total"] as? Int
            
            self.paging = Paging(page: page, totalPages: totalPages, limit: limit, total: total)
        }
    }
    
    public init(statusCode: Int, requestID: String?, errors: [NMError]?) {
        self.statusCode = statusCode
        self.requestID = requestID
        self.errors = errors
    }
    
    public struct Paging {
        public var page: Int?
        public var totalPages: Int?
        public var limit: Int?
        public var total: Int?
        
        public func haveNextPage() -> Bool {
            if let total = self.total, let page = self.page, let limit = self.limit {
                return (page + 1) * limit < total
            }
            return false
        }
    }
}
