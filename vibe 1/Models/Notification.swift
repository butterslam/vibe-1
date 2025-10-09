//
//  Notification.swift
//  vibe 1
//
//  Created by Jamie Cheatham on 10/4/25.
//

import Foundation
import FirebaseFirestore

struct AppNotification: Identifiable, Codable {
    @DocumentID var id: String?
    let type: NotificationType
    let title: String
    let message: String
    let timestamp: Date
    let recipientUserId: String
    let senderUserId: String?
    let senderUsername: String?
    let senderAvatarURL: String?
    var isRead: Bool
    let actionType: ActionType?
    let actionData: [String: String]?
    let habitId: String?
    let allyId: String?
    let guildId: String?
    
    enum NotificationType: String, Codable, CaseIterable {
        case habitInvitation = "habit_invitation"
        case habitCompleted = "habit_completed"
        case allyInvitation = "ally_invitation"
        case allyAccepted = "ally_accepted"
        case guildInvitation = "guild_invitation"
        case guildChallenge = "guild_challenge"
        case system = "system"
        
        var displayName: String {
            switch self {
            case .habitInvitation: return "Habit Invitation"
            case .habitCompleted: return "Habit Completed"
            case .allyInvitation: return "Ally Invitation"
            case .allyAccepted: return "Ally Accepted"
            case .guildInvitation: return "Guild Invitation"
            case .guildChallenge: return "Guild Challenge"
            case .system: return "System"
            }
        }
        
        var icon: String {
            switch self {
            case .habitInvitation: return "checkmark.circle"
            case .habitCompleted: return "checkmark.circle.fill"
            case .allyInvitation: return "person.2"
            case .allyAccepted: return "person.2.fill"
            case .guildInvitation: return "person.3"
            case .guildChallenge: return "person.3.fill"
            case .system: return "gear"
            }
        }
    }
    
    enum ActionType: String, Codable {
        case acceptHabitInvitation = "accept_habit_invitation"
        case declineHabitInvitation = "decline_habit_invitation"
        case acceptAllyInvitation = "accept_ally_invitation"
        case declineAllyInvitation = "decline_ally_invitation"
        case acceptGuildInvitation = "accept_guild_invitation"
        case declineGuildInvitation = "decline_guild_invitation"
        case viewHabit = "view_habit"
        case viewProfile = "view_profile"
        case viewGuild = "view_guild"
        case joinChallenge = "join_challenge"
    }
    
    init(
        type: NotificationType,
        title: String,
        message: String,
        recipientUserId: String,
        senderUserId: String? = nil,
        senderUsername: String? = nil,
        senderAvatarURL: String? = nil,
        isRead: Bool = false,
        actionType: ActionType? = nil,
        actionData: [String: String]? = nil,
        habitId: String? = nil,
        allyId: String? = nil,
        guildId: String? = nil
    ) {
        self.type = type
        self.title = title
        self.message = message
        self.timestamp = Date()
        self.recipientUserId = recipientUserId
        self.senderUserId = senderUserId
        self.senderUsername = senderUsername
        self.senderAvatarURL = senderAvatarURL
        self.isRead = isRead
        self.actionType = actionType
        self.actionData = actionData
        self.habitId = habitId
        self.allyId = allyId
        self.guildId = guildId
    }
}

// MARK: - Notification Factory Methods

extension AppNotification {
    static func habitInvitation(
        habitName: String,
        fromUsername: String,
        fromUserId: String,
        fromAvatarURL: String?,
        toUserId: String,
        habitId: String
    ) -> AppNotification {
        return AppNotification(
            type: .habitInvitation,
            title: "Habit Invitation",
            message: "\(fromUsername) invited you to join their '\(habitName)' habit",
            recipientUserId: toUserId,
            senderUserId: fromUserId,
            senderUsername: fromUsername,
            senderAvatarURL: fromAvatarURL,
            actionType: .acceptHabitInvitation,
            actionData: ["habitId": habitId],
            habitId: habitId
        )
    }
    
    static func allyInvitation(
        fromUsername: String,
        fromUserId: String,
        fromAvatarURL: String?,
        toUserId: String
    ) -> AppNotification {
        return AppNotification(
            type: .allyInvitation,
            title: "Ally Invitation",
            message: "\(fromUsername) wants to be your ally",
            recipientUserId: toUserId,
            senderUserId: fromUserId,
            senderUsername: fromUsername,
            senderAvatarURL: fromAvatarURL,
            actionType: .acceptAllyInvitation,
            actionData: ["allyId": fromUserId]
        )
    }
    
    static func habitCompleted(
        habitName: String,
        fromUsername: String,
        fromUserId: String,
        fromAvatarURL: String?,
        toUserId: String,
        habitId: String
    ) -> AppNotification {
        return AppNotification(
            type: .habitCompleted,
            title: "Habit Completed! 🎉",
            message: "\(fromUsername) just completed their '\(habitName)' habit",
            recipientUserId: toUserId,
            senderUserId: fromUserId,
            senderUsername: fromUsername,
            senderAvatarURL: fromAvatarURL,
            actionType: .viewHabit,
            actionData: ["habitId": habitId],
            habitId: habitId
        )
    }
    
    static func allyAccepted(
        fromUsername: String,
        fromUserId: String,
        fromAvatarURL: String?,
        toUserId: String
    ) -> AppNotification {
        return AppNotification(
            type: .allyAccepted,
            title: "New Ally! 🤝",
            message: "\(fromUsername) accepted your ally request",
            recipientUserId: toUserId,
            senderUserId: fromUserId,
            senderUsername: fromUsername,
            senderAvatarURL: fromAvatarURL,
            actionType: .viewProfile,
            actionData: ["userId": fromUserId]
        )
    }
}