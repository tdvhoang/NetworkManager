//
//  NetworkManagerTests.swift
//  NetworkManagerTests
//
//  Created by Hoang Tran on 11/26/20.
//

import XCTest
@testable import NetworkManager

class NetworkManagerTests: XCTestCase {
    
    let manager = NetworkManager.shared

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        manager.updateUserAgentWithAppName("NetworkManagerTest", companyName: "Vinh Hoang")
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        // Given
        let urlString = "https://httpbin.org/json"
        let expectation = self.expectation(description: "GET request should succeed: \(urlString)")
        let request = manager.request(service: urlString, headerType: .default, validate: false) { result in
            switch result {
            case .success(let data):
                print("[Info] success")
                break
            case .failure(let data):
                print("[Info] failed")
                break
            }
            DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
                expectation.fulfill()
            }
        }
        
//        var response: DataResponse<Data?, AFError>?
//
//        // When
//        AF.request(urlString, parameters: ["foo": "bar"])
//            .response { resp in
//                response = resp
//                expectation.fulfill()
//            }
//
        waitForExpectations(timeout: 60, handler: nil)
        
        // Then
        XCTAssertNotNil(request)
//        XCTAssertNotNil(response?.request)
//        XCTAssertNotNil(response?.response)
//        XCTAssertNotNil(response?.data)
//        XCTAssertNil(response?.error)
    }

//    func testPerformanceExample() throws {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }

}
