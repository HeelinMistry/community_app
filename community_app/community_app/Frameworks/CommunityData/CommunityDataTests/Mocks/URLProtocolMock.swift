//
//  URLProtocolMock.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/04/27.
//

import XCTest
import Foundation

public final class URLProtocolMock: URLProtocol, @unchecked Sendable {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    public override static func canInit(with request: URLRequest) -> Bool { true }
    public override static func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    
    public override func startLoading() {
        guard let handler = URLProtocolMock.requestHandler else {
            XCTFail("Handler is not set.")
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    public override func stopLoading() {}
}
