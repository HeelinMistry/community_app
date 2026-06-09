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
}

/// Helper enum for notification-related errors.
public enum NotificationError: Error, LocalizedError {
    /// Indicates that notification permission was denied by the user.
    case denied
    /// Indicates that a notification cannot be scheduled for a date in the past.
    case pastDate
    
    /// A short, localized title for the error.
    public var title: String {
        switch self {
        case .denied: return "Permission Denied"
        case .pastDate: return "Event has already passed"
        }
    }
    
    /// A detailed, localized description for the error.
    public var message: String {
        switch self {
        case .denied: return "Notification permission was denied. Please enable notifications in Settings to receive match reminders."
        case .pastDate: return "Notification cannot be set for a past date. Please select a future date."
        }
    }
}
