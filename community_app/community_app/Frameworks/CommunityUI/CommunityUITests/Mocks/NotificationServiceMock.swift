//
//  NotificationServiceMock.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/06/09.
//

import CommunityCore
import Foundation

final class NotificationMock: NotificationProtocol, @unchecked Sendable {
    var authorizationRequested = false
    var scheduledMatchID: String?
    var cancelledMatchID: String?
    var scheduledMatch: Bool = false
    
    var shouldThrowError = false
    
    public func requestAuthorization() async throws {
        if shouldThrowError { throw NotificationError.denied }
        authorizationRequested = true
    }
    
    public func scheduleMatchNotification(
        id: String,
        title: String,
        location: String,
        startDate: Date
    ) async throws -> (scheduledDate: Date, message: String) {
        if shouldThrowError { throw NotificationError.pastDate }
        self.scheduledMatchID = id
        scheduledMatch = true
        return (startDate, "Scheduled")
    }
    
    public func cancelMatchNotification(id: String) {
        self.cancelledMatchID = id
    }
    
    func isNotificationScheduled(with identifier: String) async -> Bool {
        return scheduledMatch
    }
}
