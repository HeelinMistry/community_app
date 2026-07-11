//
//  DashboardModel.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/07/11.
//

import Foundation
import CommunityCore

public nonisolated struct DashboardModel: Sendable, Equatable, Encodable, Decodable {
    private var matches: Matches = []
    public var suppliers: Suppliers = []
    
    public mutating func update(
        matches: Matches? = nil,
        suppliers: Suppliers? = nil
    ) {
        if let matches { self.matches = matches }
        if let suppliers { self.suppliers = suppliers }
    }
    
    // MARK: - Match Filtering
    
    public var upcomingMatches: Matches {
//        guard let matches else { return [] }
        let now = Date()
        return matches.filter { match in
            guard let matchDate = DashboardModel.isoDateFormatter.date(from: match.start_datetime) else { return false }
            return matchDate > now
        }.sorted(by: {
            guard let date1 = DashboardModel.isoDateFormatter.date(from: $0.start_datetime),
                  let date2 = DashboardModel.isoDateFormatter.date(from: $1.start_datetime) else { return false }
            return date1 < date2 // Sort upcoming from earliest to latest
        })
    }
    
    public var historyMatches: Matches {
//        guard let matches else { return [] }
        let now = Date()
        return matches.filter { match in
            guard let matchDate = DashboardModel.isoDateFormatter.date(from: match.start_datetime) else { return false }
            return matchDate <= now
        }.sorted(by: {
            guard let date1 = DashboardModel.isoDateFormatter.date(from: $0.start_datetime),
                  let date2 = DashboardModel.isoDateFormatter.date(from: $1.start_datetime) else { return false }
            return date1 > date2 // Sort history from newest to oldest
        })
    }
    
    public static let isoDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
        return formatter
    }()
}
