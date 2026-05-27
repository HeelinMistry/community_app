//
//  LocationServiceMock.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/05/27.
//

import Combine
import CoreLocation
import CommunityCore // Assuming LocationProtocol is in CommunityCore

@MainActor
public final class LocationServiceMock: LocationProtocol {
    public var authorizationStatus: CLAuthorizationStatus?
    public var lastKnownLocation: CLLocation?

    // MARK: - Call Tracking for async methods
    public var requestLocationAuthorizationCallCount = 0
    public var lastKnownLocationCallCount = 0

    // MARK: - Mock Behavior for async methods
    public var requestLocationAuthorizationResult: Result<Void, Error> = .success(())
    public var lastKnownLocationResult: Result<Void, Error> = .success(())

    // Initializer
    public init(
        authorizationStatus: CLAuthorizationStatus? = .notDetermined,
        lastKnownLocation: CLLocation? = nil
    ) {
        self.authorizationStatus = authorizationStatus
        self.lastKnownLocation = lastKnownLocation
    }

    // MARK: - LocationProtocol Conformance

    @MainActor // Explicitly mark the method as MainActor isolated
    public func lastKnownLocation() async throws {
        lastKnownLocationCallCount += 1
        switch lastKnownLocationResult {
        case .success:
            // In a real scenario, you'd update `self.lastKnownLocation` here
            // based on what the test needs it to be set to before calling this.
            // For now, we just succeed.
            return
        case .failure(let error):
            throw error
        }
    }

    @MainActor // Explicitly mark the method as MainActor isolated
    public func requestLocationAuthorization() async throws {
        requestLocationAuthorizationCallCount += 1
        switch requestLocationAuthorizationResult {
        case .success:
            // Simulate authorization status change after request
            if authorizationStatus == .notDetermined {
                authorizationStatus = .authorizedWhenInUse
            }
            return
        case .failure(let error):
            throw error
        }
    }
}
