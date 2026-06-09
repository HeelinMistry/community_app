//
//  NotificationError.swift
//  CommunityCore
//
//  Created by Heelin Mistry on 2026/06/09.
//

import Foundation

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
