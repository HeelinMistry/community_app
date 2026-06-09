//
//  NotificationUseCases.swift
//  CommunityCore
//
//  Created by Heelin Mistry on 2026/06/09.
//

import UserNotifications

public final class NotificationUseCases: NotificationProtocol {
    public func requestAuthorization() async throws {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        
        guard settings.authorizationStatus == .authorized else {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            guard granted else {
                throw NotificationError.denied
            }
            return
        }
    }
    
    public func scheduleMatchNotification(id: String, title: String, location: String, startDate: Date) async throws -> (scheduledDate: Date, message: String) {
        
        let calendar = Calendar.current
        guard startDate > Date.now else { throw NotificationError.pastDate }
        
        // Calculate trigger date
        let notificationDate = calendar.date(byAdding: .minute, value: -15, to: startDate) ?? startDate
        let finalTriggerDate = notificationDate <= Date.now ? startDate : notificationDate
        let message = notificationDate <= Date.now ? "Match starting soon!" : "Reminder set for 15 mins before."
        
        // Setup content
        let content = UNMutableNotificationContent()
        content.title = "Upcoming Match: \(title)"
        content.body = "Your match at \(location) is starting \(finalTriggerDate == startDate ? "now" : "in 15 minutes")!"
        content.sound = .default
        content.userInfo = ["match_id": id]
        
        // Setup trigger
        let comps = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: finalTriggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        
        // Schedule
        let request = UNNotificationRequest(identifier: "match-reminder-\(id)", content: content, trigger: trigger)
        try await UNUserNotificationCenter.current().add(request)
        
        return (finalTriggerDate, message)
    }
    
    public func cancelMatchNotification(id: String) {
        let requestIdentifier = "match-reminder-\(id)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [requestIdentifier])
    }
}
