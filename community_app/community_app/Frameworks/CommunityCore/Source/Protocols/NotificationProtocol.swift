//
//  NotificationProtocol.swift
//  CommunityCore
//
//  Created by Heelin Mistry on 2026/06/08.
//

import UserNotifications

/// A protocol for managing user notifications within the application.
public protocol NotificationProtocol {
    /// Requests authorization from the user to send notifications.
    ///
    /// - Throws: `NotificationError.denied` if authorization is denied.
    func requestAuthorization() async throws
    
    /// Schedules a notification for a match event.
    ///
    /// - Parameters:
    ///   - id: A unique identifier for the notification.
    ///   - title: The title of the notification.
    ///   - location: The location of the match event.
    ///   - startDate: The date and time when the match starts.
    /// - Returns: A tuple containing the actual scheduled date and a confirmation message.
    /// - Throws: `NotificationError.pastDate` if the `startDate` is in the past.
    func scheduleMatchNotification(
            id: String,
            title: String,
            location: String,
            startDate: Date
        ) async throws -> (scheduledDate: Date, message: String)
    
    /// Cancels a previously scheduled match notification.
    ///
    /// - Parameter id: The unique identifier of the notification to cancel.
    func cancelMatchNotification(id: String)
    
    /// Checks if a notification with the given identifier is currently scheduled.
    ///
    /// - Parameter identifier: The unique identifier of the notification to check.
    /// - Returns: `true` if a notification with the given identifier is scheduled, otherwise `false`.
    func isNotificationScheduled(with identifier: String) async -> Bool
}
