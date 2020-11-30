//
//  AuthToken.swift
//  WebServices
//
//  Created by Hoang Tran on 11/26/20.
//  Copyright © 2020 Hoang Tran. All rights reserved.
//

public struct AuthToken: Codable {
    public var accessToken: String
    public var refreshToken: String
    public var expiresIn: Double?
    public var oldToken: String?
    private var createdAt: Date?
    
    public func tockenExpiredDate() -> Date? {
        if let createdAt = self.createdAt, let expiredIn = self.expiresIn {
            return createdAt.addingTimeInterval(expiredIn)
        }
        return self.getExpiredDateFromAccessToken()
    }
    
    public mutating func updateNewAccessTokenFrom(_ token: AuthToken) {
        self.oldToken = self.accessToken
        self.accessToken = token.accessToken
        self.createdAt = token.createdAt
        self.expiresIn = token.expiresIn
    }
}

// - Extract token
public extension AuthToken {
    private func getJwtBodyData(_ tokenStr: String?) -> Data? {
        guard let tokenStr = tokenStr else {
            return nil
        }
        let segments = tokenStr.components(separatedBy: ".")
        var base64String = segments[1]
        let requiredLength = Int(4 * ceil(Float(base64String.count) / 4.0))
        let nbrPaddings = requiredLength - base64String.count
        if nbrPaddings > 0 {
            let padding = String().padding(toLength: nbrPaddings, withPad: "=", startingAt: 0)
            base64String = base64String.appending(padding)
        }
        base64String = base64String.replacingOccurrences(of: "-", with: "+")
        base64String = base64String.replacingOccurrences(of: "_", with: "/")
        return Data(base64Encoded: base64String, options: .ignoreUnknownCharacters)
    }
    
    func getJwtDictFromToken(_ tokenStr: String?) -> [String: Any]? {
        if let data = self.getJwtBodyData(tokenStr) {
            return try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
        }
        return nil
    }
    
    func getJwtDict() -> [String: Any]? {
        return self.getJwtDictFromToken(self.accessToken)
    }
    
    func getDeviceTokenFromAccessToken() -> String? {
        if let dict = self.getJwtDict() {
            return dict["device_id"] as? String
        }
        return nil
    }
    
    func getOrganizationIDFromAccessToken() -> String? {
        if let dict = self.getJwtDict() {
            return dict["organization_id"] as? String
        }
        return nil
    }
    
    func getExpiredDateFromAccessToken() -> Date? {
        if let dict = self.getJwtDict(),
            let timeInterval = dict["exp"] as? Double {
            return Date(timeIntervalSince1970: timeInterval)
        }
        return nil
    }
}
