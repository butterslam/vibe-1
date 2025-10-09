//
//  NotificationStore.swift
//  vibe 1
//
//  Created by Jamie Cheatham on 10/4/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

@MainActor
class NotificationStore: ObservableObject {
    @Published var notifications: [AppNotification] = []
    @Published var unreadCount: Int = 0
    @Published var isLoading: Bool = false
    
    private let db = Firestore.firestore()
    private var notificationsListener: ListenerRegistration?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupAuthListener()
    }
    
    deinit {
        notificationsListener?.remove()
    }
    
    // MARK: - Auth State Management
    
    private func setupAuthListener() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            if let user = user {
                self?.loadNotifications(for: user.uid)
            } else {
                self?.clearNotifications()
            }
        }
    }
    
    private func clearNotifications() {
        notificationsListener?.remove()
        notifications = []
        unreadCount = 0
    }
    
    // MARK: - Load Notifications
    
    private func loadNotifications(for userId: String) {
        notificationsListener?.remove()
        isLoading = true
        
        notificationsListener = db.collection("notifications")
            .whereField("recipientUserId", isEqualTo: userId)
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                self.isLoading = false
                
                if let error = error {
                    print("Error loading notifications: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.notifications = []
                    self.updateUnreadCount()
                    return
                }
                
                self.notifications = documents.compactMap { document in
                    try? document.data(as: AppNotification.self)
                }
                self.updateUnreadCount()
            }
    }
    
    private func updateUnreadCount() {
        unreadCount = notifications.filter { !$0.isRead }.count
    }
    
    // MARK: - Send Notifications
    
    func sendNotification(_ notification: AppNotification) async throws {
        guard let currentUser = Auth.auth().currentUser else {
            throw NotificationError.notAuthenticated
        }
        
        // Don't send notifications to yourself
        if notification.recipientUserId == currentUser.uid {
            return
        }
        
        var notificationData = try Firestore.Encoder().encode(notification)
        notificationData["timestamp"] = FieldValue.serverTimestamp()
        
        try await db.collection("notifications").addDocument(data: notificationData)
    }
    
    func sendHabitInvitation(
        habitName: String,
        toUserId: String,
        habitId: String
    ) async throws {
        guard let currentUser = Auth.auth().currentUser else {
            throw NotificationError.notAuthenticated
        }
        
        // Get current user's profile for sender info
        let userDoc = try await db.collection("users").document(currentUser.uid).getDocument()
        guard let userData = userDoc.data(),
              let username = userData["username"] as? String else {
            throw NotificationError.userProfileNotFound
        }
        
        let avatarURL = userData["avatarURL"] as? String
        
        let notification = AppNotification.habitInvitation(
            habitName: habitName,
            fromUsername: username,
            fromUserId: currentUser.uid,
            fromAvatarURL: avatarURL,
            toUserId: toUserId,
            habitId: habitId
        )
        
        try await sendNotification(notification)
    }
    
    func sendAllyInvitation(toUserId: String) async throws {
        guard let currentUser = Auth.auth().currentUser else {
            throw NotificationError.notAuthenticated
        }
        
        // Get current user's profile for sender info
        let userDoc = try await db.collection("users").document(currentUser.uid).getDocument()
        guard let userData = userDoc.data(),
              let username = userData["username"] as? String else {
            throw NotificationError.userProfileNotFound
        }
        
        let avatarURL = userData["avatarURL"] as? String
        
        let notification = AppNotification.allyInvitation(
            fromUsername: username,
            fromUserId: currentUser.uid,
            fromAvatarURL: avatarURL,
            toUserId: toUserId
        )
        
        try await sendNotification(notification)
    }
    
    func sendHabitCompletedNotification(
        habitName: String,
        toUserId: String,
        habitId: String
    ) async throws {
        guard let currentUser = Auth.auth().currentUser else {
            throw NotificationError.notAuthenticated
        }
        
        // Get current user's profile for sender info
        let userDoc = try await db.collection("users").document(currentUser.uid).getDocument()
        guard let userData = userDoc.data(),
              let username = userData["username"] as? String else {
            throw NotificationError.userProfileNotFound
        }
        
        let avatarURL = userData["avatarURL"] as? String
        
        let notification = AppNotification.habitCompleted(
            habitName: habitName,
            fromUsername: username,
            fromUserId: currentUser.uid,
            fromAvatarURL: avatarURL,
            toUserId: toUserId,
            habitId: habitId
        )
        
        try await sendNotification(notification)
    }
    
    // MARK: - Notification Actions
    
    func markAsRead(_ notification: AppNotification) async throws {
        guard let notificationId = notification.id else { return }
        
        try await db.collection("notifications").document(notificationId).updateData([
            "isRead": true
        ])
    }
    
    func markAllAsRead() async throws {
        guard let currentUser = Auth.auth().currentUser else { return }
        
        let batch = db.batch()
        let unreadNotifications = notifications.filter { !$0.isRead }
        
        for notification in unreadNotifications {
            guard let notificationId = notification.id else { continue }
            let docRef = db.collection("notifications").document(notificationId)
            batch.updateData(["isRead": true], forDocument: docRef)
        }
        
        try await batch.commit()
    }
    
    func deleteNotification(_ notification: AppNotification) async throws {
        guard let notificationId = notification.id else { return }
        
        try await db.collection("notifications").document(notificationId).delete()
    }
    
    func handleNotificationAction(_ notification: AppNotification) async throws {
        guard let actionType = notification.actionType else { return }
        
        switch actionType {
        case .acceptHabitInvitation:
            try await acceptHabitInvitation(notification)
        case .declineHabitInvitation:
            try await declineHabitInvitation(notification)
        case .acceptAllyInvitation:
            try await acceptAllyInvitation(notification)
        case .declineAllyInvitation:
            try await declineAllyInvitation(notification)
        case .acceptGuildInvitation:
            try await acceptGuildInvitation(notification)
        case .declineGuildInvitation:
            try await declineGuildInvitation(notification)
        case .viewHabit, .viewProfile, .viewGuild, .joinChallenge:
            // These are handled by the UI navigation
            break
        }
        
        // Mark as read after handling
        try await markAsRead(notification)
    }
    
    // MARK: - Action Handlers
    
    private func acceptHabitInvitation(_ notification: AppNotification) async throws {
        // This would integrate with your habit system
        // For now, just mark as read
        print("Accepting habit invitation for habit: \(notification.habitId ?? "unknown")")
    }
    
    private func declineHabitInvitation(_ notification: AppNotification) async throws {
        print("Declining habit invitation for habit: \(notification.habitId ?? "unknown")")
    }
    
    private func acceptAllyInvitation(_ notification: AppNotification) async throws {
        guard let currentUser = Auth.auth().currentUser,
              let allyId = notification.senderUserId else { return }
        
        // Add ally relationship
        try await db.collection("allies").addDocument(data: [
            "userId": currentUser.uid,
            "allyId": allyId,
            "createdAt": FieldValue.serverTimestamp()
        ])
        
        // Send acceptance notification back
        let userDoc = try await db.collection("users").document(currentUser.uid).getDocument()
        guard let userData = userDoc.data(),
              let username = userData["username"] as? String else { return }
        
        let avatarURL = userData["avatarURL"] as? String
        
        let acceptanceNotification = AppNotification.allyAccepted(
            fromUsername: username,
            fromUserId: currentUser.uid,
            fromAvatarURL: avatarURL,
            toUserId: allyId
        )
        
        try await sendNotification(acceptanceNotification)
    }
    
    private func declineAllyInvitation(_ notification: AppNotification) async throws {
        print("Declining ally invitation from: \(notification.senderUserId ?? "unknown")")
    }
    
    private func acceptGuildInvitation(_ notification: AppNotification) async throws {
        print("Accepting guild invitation for guild: \(notification.guildId ?? "unknown")")
    }
    
    private func declineGuildInvitation(_ notification: AppNotification) async throws {
        print("Declining guild invitation for guild: \(notification.guildId ?? "unknown")")
    }
}

// MARK: - Error Types

enum NotificationError: Error, LocalizedError {
    case notAuthenticated
    case userProfileNotFound
    case invalidNotification
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User not authenticated"
        case .userProfileNotFound:
            return "User profile not found"
        case .invalidNotification:
            return "Invalid notification"
        case .networkError:
            return "Network error occurred"
        }
    }
}
