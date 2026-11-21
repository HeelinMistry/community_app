//
//  URLProtocolMock.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/04/27.
//
import XCTest
import Foundation

public final class URLProtocolMock: URLProtocol, @unchecked Sendable {
    public typealias RequestHandler = (URLRequest) throws -> (HTTPURLResponse, Data)

    private static let lock = NSLock()
    private static var _requestHandler: RequestHandler?
    private static var handlerQueue: [RequestHandler] = []

    /// Setting a handler updates the active handler and enqueues it for the next request.
    /// Setting `nil` clears only the active fallback handler without wiping queued handlers.
    public static var requestHandler: RequestHandler? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _requestHandler
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _requestHandler = newValue
            if let newValue {
                handlerQueue.append(newValue)
            }
        }
    }

    /// Enqueues an additional handler for upcoming requests in FIFO order.
    public static func enqueueHandler(_ handler: @escaping RequestHandler) {
        lock.lock()
        defer { lock.unlock() }
        handlerQueue.append(handler)
    }

    /// Clears queued and active handlers cleanly (e.g., in `tearDown()`).
    public static func reset() {
        lock.lock()
        defer { lock.unlock() }
        _requestHandler = nil
        handlerQueue.removeAll()
    }

    public override static func canInit(with request: URLRequest) -> Bool { true }
    public override static func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    public override func startLoading() {
        let handler: RequestHandler? = {
            URLProtocolMock.lock.lock()
            defer { URLProtocolMock.lock.unlock() }
            if !URLProtocolMock.handlerQueue.isEmpty {
                return URLProtocolMock.handlerQueue.removeFirst()
            }
            return URLProtocolMock._requestHandler
        }()

        guard let handler else {
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
