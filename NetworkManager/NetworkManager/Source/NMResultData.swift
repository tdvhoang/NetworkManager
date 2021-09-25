//
//  NMResultData.swift
//  NetworkManager
//
//  Created by Hoang Tran on 11/26/20.
//  Copyright © 2020 Hoang Tran. All rights reserved.
//

import Foundation
import ObjectMapper

struct NMResultDataContext: MapContext {
    let data: Data?
    let statusCode: Int?
}

public protocol NetworkManagerResultData {
    /// Data return from backend
    var result: Any? { get }
    ///Json data return from backend, useful for Codable
    var jsonData: Data? { get }
    var response: HTTPURLResponse? { get }
    
    //Debug
    var statusCode: Int? { get }
    var message: String? { get } //message = result["message"]
}

public protocol NetworkManagerPagingData {
    /// Current page
    var page: Int! { get }
    /// Total pages
    var totalPages: Int! { get }
    /// Page size
    var limit: Int! { get }
    /// Total items
    var total: Int! { get }
    
    func haveNextPage() -> Bool
}

public protocol NetworkManagerSuccessData: NetworkManagerResultData {
    /// data = result["data"], maybe: dict/array/string/data
    var data: Any? { get }
    /// pagination data
    var paging: NetworkManagerPagingData? { get }
}

extension NetworkManagerSuccessData {
    /// return data as? [String: Any]
    var dataAsDict: [String: Any]? { get { return data as? [String: Any] } }
    /// return data as? [Any]
    var dataAsArray: [Any]? { get { return data as? [Any] } }
    /// return data as? String
    var dataAsString: String? { get { return data as? String } }
    /// return data as? Data
    var dataAsData: Data? { get { return data as? Data } }
}

public protocol NetworkManagerFailedData: Error, NetworkManagerResultData {
    var errors: [NMError]? { get }
    func getMessageError() -> String
}

extension NetworkManagerFailedData {
    static func fromError(_ error: Error) -> NetworkManagerFailedData {
        return NMResultData(error: error)
    }
}

public struct NMResultData: Mappable, NetworkManagerSuccessData, NetworkManagerFailedData {
    public var result: Any? //Data return from backend
    public var jsonData: Data? //Json data return from backend, useful for Codable
    public var data: Any? //data = result["data"], maybe: dict/array/string/data
    public var response: HTTPURLResponse?
    
    //Paging
    public var paging: NetworkManagerPagingData?
    
    //Debug
    public var errors: [NMError]?
    public var statusCode: Int?
    public var message: String? //message = result["message"]
    
    public init?(map: Map) { }
    
    public mutating func mapping(map: Map) {
        let context = (map.context as? NMResultDataContext)
        self.result = map.JSON
        self.jsonData = context?.data
        self.data <- map["data"]
        self.paging = Mapper<NMPagingData>().map(JSONObject: map.JSON["pagination"])
        self.statusCode <- map["code"]
        self.message <- map["msg"]
        
        //Corrrection
        self.statusCode = self.statusCode ?? context?.statusCode
        if map.mappingType == .fromJSON {
            let errorContext = NMErrorContext(statusCode: self.statusCode)
            self.errors = Mapper<NMError>(context: errorContext).mapArray(JSONObject: map.JSON["errors"])
        }
        else {
            self.errors <- map["errors"]
        }
    }
    
    public init(statusCode: Int, string: String, response: HTTPURLResponse?) {
        self.statusCode = statusCode
        self.data = string
        self.result = string
        self.response = response
    }
    
    public init(statusCode: Int, errors: [NMError]?, response: HTTPURLResponse?) {
        self.statusCode = statusCode
        self.errors = errors
        self.response = response
    }
    
    public init(error: Error) {
        self.errors = [NMError(err: error)]
        self.statusCode = (error as NSError).code
    }
    
    public func getMessageError() -> String {
        let anError = self.errors?.getAnError()
        #if DEBUG
        return "[Code: \(String(describing: anError?.code ?? 0))] - \(anError?.domain ?? "")"
        #else
        return anError?.domain ?? ""
        #endif
    }
}

public struct NMPagingData: Mappable, NetworkManagerPagingData {
    public var page: Int!
    public var totalPages: Int!
    public var limit: Int!
    public var total: Int!
    
    public init?(map: Map) {
        if map.JSON["page"] == nil { return nil }
        if map.JSON["pageCount"] == nil { return nil }
        if map.JSON["pageSize"] == nil { return nil }
        if map.JSON["rowCount"] == nil { return nil }
    }
    
    public mutating func mapping(map: Map) {
        self.page <- map["page"]
        self.totalPages <- map["pageCount"]
        self.limit <- map["pageSize"]
        self.total <- map["rowCount"]
    }
    
    public func haveNextPage() -> Bool {
        return (page + 1) * limit < total
    }
}
