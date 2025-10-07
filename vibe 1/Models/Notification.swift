//
//  Notification.swift
//  vibe 1
//
//  Created by Jamie Cheatham on 10/4/25.
//

import Foundation

struct AppNotification: Identifiable, Codable {
    var id: UUID
    let type: NotificationType
    let title: String
    let message: String
    let timestamp: Date
    var isRead: Bool
    let relatedHabitId: UUID?
    let fromUserId: String?
    let fromUsername: String?
    let fromUserAvatarURL: String?
    
    init(type: NotificationType, title: String, message: String, relatedHabitId: UUID? = nil, fromUserId: String? = nil, fromUsername: String? = nil, fromUserAvatarURL: String? = nil, timestamp: Date = Date()) {
        self.id = UUID()
        self.type = type
        self.title = title
        self.message = message
        self.timestamp = timestamp
        self.isRead = false
        self.relatedHabitId = relatedHabitId
        self.fromUserId = fromUserId
        self.fromUsername = fromUsername
        self.fromUserAvatarURL = fromUserAvatarURL
    }
}

enum NotificationType: String, Codable, CaseIterable {
    case allyInvitation = "ally_invitation"
    case habitReminder = "habit_reminder"
    case achievement = "achievement"
    
    var icon: String {
        switch self {
        case .allyInvitation:
            return "person.2.fill"
        case .habitReminder:
            return "alarm"
        case .achievement:
            return "trophy.fill"
        }
    }
    
    var color: String {
        switch self {
        case .allyInvitation:
            return "blue"
        case .habitReminder:
            return "orange"
        case .achievement:
            return "yellow"
        }
    }
}
