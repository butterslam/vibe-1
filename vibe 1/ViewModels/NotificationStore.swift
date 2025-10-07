//
//  NotificationStore.swift
//  vibe 1
//
//  Created by Jamie Cheatham on 10/4/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class NotificationStore: ObservableObject {
    @Published var notifications: [AppNotification] = []
    
    private let db = Firestore.firestore()
    private let userDefaults = UserDefaults.standard
    private let notificationsKey = "app_notifications"
    
    init() {
        loadNotifications()
    }
    
    // MARK: - Local Storage
    private func loadNotifications() {
        if let data = userDefaults.data(forKey: notificationsKey),
           let decoded = try? JSONDecoder().decode([AppNotification].self, from: data) {
            notifications = decoded.sorted { $0.timestamp > $1.timestamp }
        }
    }
    
    private func saveNotifications() {
        if let encoded = try? JSONEncoder().encode(notifications) {
            userDefaults.set(encoded, forKey: notificationsKey)
        }
    }
    
    // MARK: - Notification Management
    func addNotification(_ notification: AppNotification) {
        notifications.insert(notification, at: 0)
        saveNotifications()
        
        // Also save to Firebase for cross-device sync
        saveNotificationToFirebase(notification)
    }
    
    func markAsRead(_ notification: AppNotification) {
        if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
            notifications[index].isRead = true
            saveNotifications()
        }
    }
    
    func markAllAsRead() {
        for index in notifications.indices {
            notifications[index].isRead = true
        }
        saveNotifications()
    }
    
    func deleteNotification(_ notification: AppNotification) {
        notifications.removeAll { $0.id == notification.id }
        saveNotifications()
    }
    
    var unreadCount: Int {
        notifications.filter { !$0.isRead }.count
    }
    
    // MARK: - Testing Functions
    func createTestNotification() {
        let testNotification = AppNotification(
            type: .allyInvitation,
            title: "Test Invitation",
            message: "This is a test notification to verify the system works",
            relatedHabitId: UUID(),
            fromUserId: "test-user-id",
            fromUsername: "TestUser",
            fromUserAvatarURL: nil
        )
        addNotification(testNotification)
    }
    
    func createTestNotificationForCurrentUser() {
        guard let currentUser = Auth.auth().currentUser else { return }
        
        let testNotification = AppNotification(
            type: .allyInvitation,
            title: "Test Invitation",
            message: "This is a test notification sent to you",
            relatedHabitId: UUID(),
            fromUserId: "test-user-id",
            fromUsername: "TestUser",
            fromUserAvatarURL: nil
        )
        
        // Send directly to current user
        sendNotificationToAllyWithId(testNotification, allyUserId: currentUser.uid, allyUsername: "Current User")
    }
    
    // MARK: - Ally Invitation Notifications
    func sendAllyInvitationNotification(to allyUsername: String, habitName: String, fromUsername: String, habitId: UUID) {
        // Fetch current user's avatar URL and send notification
        Task {
            let avatarURL = await getCurrentUserAvatarURL()
            let notification = AppNotification(
                type: .allyInvitation,
                title: "Habit Invitation",
                message: "\(fromUsername) invited you to partake in \"\(habitName)\"",
                relatedHabitId: habitId,
                fromUserId: Auth.auth().currentUser?.uid,
                fromUsername: fromUsername,
                fromUserAvatarURL: avatarURL
            )
            
            // Send notification to Firebase for the invited ally
            sendNotificationToAlly(notification, allyUsername: allyUsername)
        }
    }
    
    func sendAllyInvitationNotification(to allyUserId: String, allyUsername: String, habitName: String, fromUsername: String, habitId: UUID) {
        // Fetch current user's avatar URL and send notification
        Task {
            let avatarURL = await getCurrentUserAvatarURL()
            let notification = AppNotification(
                type: .allyInvitation,
                title: "Habit Invitation",
                message: "\(fromUsername) invited you to partake in \"\(habitName)\"",
                relatedHabitId: habitId,
                fromUserId: Auth.auth().currentUser?.uid,
                fromUsername: fromUsername,
                fromUserAvatarURL: avatarURL
            )
            
            // Send notification directly to Firebase using the user ID
            sendNotificationToAllyWithId(notification, allyUserId: allyUserId, allyUsername: allyUsername)
        }
    }
    
    private func sendNotificationToAlly(_ notification: AppNotification, allyUsername: String) {
        guard let currentUser = Auth.auth().currentUser else { 
            print("No authenticated user for sending notification to ally")
            return 
        }
        
        // First, we need to find the ally's user ID by their username
        db.collection("usernames")
            .document(allyUsername.lowercased())
            .getDocument { [weak self] document, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error finding ally by username: \(error.localizedDescription)")
                    return
                }
                
                guard let document = document, document.exists,
                      let allyUserId = document.data()?["uid"] as? String else {
                    print("Ally username '\(allyUsername)' not found in Firebase")
                    // For testing purposes, we'll still create a local notification
                    // In production, you might want to handle this differently
                    return
                }
                
                        // Create notification data for the ally
                        let notificationData: [String: Any] = [
                            "type": notification.type.rawValue,
                            "title": notification.title,
                            "message": notification.message,
                            "timestamp": Timestamp(date: notification.timestamp),
                            "isRead": notification.isRead,
                            "relatedHabitId": notification.relatedHabitId?.uuidString ?? "",
                            "fromUserId": notification.fromUserId ?? "",
                            "fromUsername": notification.fromUsername ?? "",
                            "fromUserAvatarURL": notification.fromUserAvatarURL ?? "",
                            "toUserId": allyUserId
                        ]
                
                // Save notification to Firebase for the ally
                self.db.collection("notifications").addDocument(data: notificationData) { error in
                    if let error = error {
                        print("Error sending notification to ally: \(error.localizedDescription)")
                    } else {
                        print("Successfully sent notification to ally: \(allyUsername)")
                    }
                }
            }
    }
    
    private func sendNotificationToAllyWithId(_ notification: AppNotification, allyUserId: String, allyUsername: String) {
        guard let currentUser = Auth.auth().currentUser else { 
            print("No authenticated user for sending notification to ally")
            return 
        }
        
                        // Create notification data for the ally
                        let notificationData: [String: Any] = [
                            "type": notification.type.rawValue,
                            "title": notification.title,
                            "message": notification.message,
                            "timestamp": Timestamp(date: notification.timestamp),
                            "isRead": notification.isRead,
                            "relatedHabitId": notification.relatedHabitId?.uuidString ?? "",
                            "fromUserId": notification.fromUserId ?? "",
                            "fromUsername": notification.fromUsername ?? "",
                            "fromUserAvatarURL": notification.fromUserAvatarURL ?? "",
                            "toUserId": allyUserId
                        ]
        
        // Save notification to Firebase for the ally
        db.collection("notifications").addDocument(data: notificationData) { error in
            if let error = error {
                print("Error sending notification to ally \(allyUsername): \(error.localizedDescription)")
            } else {
                print("Successfully sent notification to ally: \(allyUsername) (ID: \(allyUserId))")
            }
        }
    }
    
    // MARK: - Firebase Integration
    private func saveNotificationToFirebase(_ notification: AppNotification) {
        guard let currentUser = Auth.auth().currentUser else { 
            print("No authenticated user for saving notification to Firebase")
            return 
        }
        
        let notificationData: [String: Any] = [
            "type": notification.type.rawValue,
            "title": notification.title,
            "message": notification.message,
            "timestamp": Timestamp(date: notification.timestamp),
            "isRead": notification.isRead,
            "relatedHabitId": notification.relatedHabitId?.uuidString ?? "",
            "fromUserId": notification.fromUserId ?? "",
            "fromUsername": notification.fromUsername ?? "",
            "fromUserAvatarURL": notification.fromUserAvatarURL ?? "",
            "toUserId": currentUser.uid
        ]
        
        db.collection("notifications").addDocument(data: notificationData) { error in
            if let error = error {
                print("Error saving notification to Firebase: \(error.localizedDescription)")
                // For now, we'll continue with local storage only
                // In production, you'd want to set up proper Firestore security rules
            } else {
                print("Successfully saved notification to Firebase")
            }
        }
    }
    
    func fetchNotificationsFromFirebase() {
        guard let currentUser = Auth.auth().currentUser else { 
            print("No authenticated user for fetching notifications")
            return 
        }
        
        db.collection("notifications")
            .whereField("toUserId", isEqualTo: currentUser.uid)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching notifications: \(error.localizedDescription)")
                    // For now, we'll work with local storage only
                    // In production, you'd want to set up proper Firestore security rules
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                let firebaseNotifications = documents.compactMap { doc -> AppNotification? in
                    let data = doc.data()
                    
                    guard let typeString = data["type"] as? String,
                          let type = NotificationType(rawValue: typeString),
                          let title = data["title"] as? String,
                          let message = data["message"] as? String,
                          let firebaseTimestamp = data["timestamp"] as? Timestamp else {
                        return nil
                    }
                    
                    let habitIdString = data["relatedHabitId"] as? String
                    let habitId = habitIdString?.isEmpty == false ? UUID(uuidString: habitIdString!) : nil
                    
                    // Create notification with Firebase document ID to prevent duplicates
                    var notification = AppNotification(
                        type: type,
                        title: title,
                        message: message,
                        relatedHabitId: habitId,
                        fromUserId: data["fromUserId"] as? String,
                        fromUsername: data["fromUsername"] as? String,
                        fromUserAvatarURL: data["fromUserAvatarURL"] as? String,
                        timestamp: firebaseTimestamp.dateValue()
                    )
                    
                    // Use Firebase document ID as the notification ID
                    notification.id = UUID(uuidString: doc.documentID) ?? UUID()
                    
                    return notification
                }
                
                // Merge with local notifications, avoiding duplicates
                let existingIds = Set(self.notifications.map { $0.id })
                let newNotifications = firebaseNotifications.filter { !existingIds.contains($0.id) }
                
                // Additional duplicate check based on content and timestamp
                let finalNewNotifications = newNotifications.filter { newNotification in
                    !self.notifications.contains { existingNotification in
                        existingNotification.title == newNotification.title &&
                        existingNotification.message == newNotification.message &&
                        abs(existingNotification.timestamp.timeIntervalSince(newNotification.timestamp)) < 5 // Within 5 seconds
                    }
                }
                
                DispatchQueue.main.async {
                    self.notifications.append(contentsOf: finalNewNotifications)
                    self.notifications.sort { $0.timestamp > $1.timestamp }
                    self.saveNotifications()
                }
            }
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentUserAvatarURL() async -> String? {
        guard let currentUser = Auth.auth().currentUser else { return nil }
        
        do {
            let document = try await db.collection("users").document(currentUser.uid).getDocument()
            if let data = document.data(),
               let avatarURL = data["avatarURL"] as? String,
               !avatarURL.isEmpty {
                return avatarURL
            }
        } catch {
            print("Error fetching current user avatar URL: \(error.localizedDescription)")
        }
        
        return nil
    }
}
