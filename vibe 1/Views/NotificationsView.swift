//
//  NotificationsView.swift
//  vibe 1
//
//  Created by Jamie Cheatham on 10/4/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct NotificationsView: View {
    @EnvironmentObject var notificationStore: NotificationStore
    @State private var selectedFilter: NotificationFilter = .all
    @State private var showingHabitInvitation: Bool = false
    @State private var selectedHabit: Habit?
    @State private var selectedInviterUsername: String = ""
    @State private var selectedInvitedUsers: [InvitedUser] = []
    
    enum NotificationFilter: String, CaseIterable {
        case all = "All"
        case unread = "Unread"
        case habit = "Habits"
        case ally = "Allies"
        case guild = "Guilds"
    }
    
    var filteredNotifications: [AppNotification] {
        switch selectedFilter {
        case .all:
            return notificationStore.notifications
        case .unread:
            return notificationStore.notifications.filter { !$0.isRead }
        case .habit:
            return notificationStore.notifications.filter { 
                $0.type == .habitInvitation || $0.type == .habitCompleted 
            }
        case .ally:
            return notificationStore.notifications.filter { 
                $0.type == .allyInvitation || $0.type == .allyAccepted 
            }
        case .guild:
            return notificationStore.notifications.filter { 
                $0.type == .guildInvitation || $0.type == .guildChallenge 
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter Pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(NotificationFilter.allCases, id: \.self) { filter in
                            FilterPill(
                                title: filter.rawValue,
                                isSelected: selectedFilter == filter,
                                action: { selectedFilter = filter }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 16)
                
                // Notifications List
                if notificationStore.isLoading {
                    ProgressView("Loading notifications...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredNotifications.isEmpty {
                    EmptyNotificationsView(filter: selectedFilter)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredNotifications) { notification in
                                NotificationCard(
                                    notification: notification,
                                    onTap: { handleNotificationTap(notification) },
                                    onDismiss: { dismissNotification(notification) }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Mark All Read") {
                        Task {
                            try? await notificationStore.markAllAsRead()
                        }
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.blue)
                    .disabled(notificationStore.notifications.filter { !$0.isRead }.isEmpty)
                }
            }
            .sheet(isPresented: $showingHabitInvitation) {
                if let habit = selectedHabit {
                    HabitInvitationView(
                        habit: habit,
                        inviterUsername: selectedInviterUsername,
                        invitedUsers: selectedInvitedUsers
                    )
                }
            }
        }
    }
    
    private func handleNotificationTap(_ notification: AppNotification) {
        // Mark notification as read
        Task {
            do {
                try await notificationStore.markAsRead(notification)
            } catch {
                print("Error marking notification as read: \(error.localizedDescription)")
            }
        }
        
        // Handle different notification types
        switch notification.type {
        case .habitInvitation:
            handleHabitInvitationTap(notification)
        case .allyInvitation:
            // Handle ally invitation (could show profile or accept/decline)
            print("Ally invitation tapped")
        case .habitCompleted:
            // Handle habit completed (could show habit details)
            print("Habit completed notification tapped")
        case .allyAccepted:
            // Handle ally accepted
            print("Ally accepted notification tapped")
        case .guildInvitation, .guildChallenge, .system:
            // Handle other notification types
            print("Other notification type tapped: \(notification.type)")
        }
    }
    
    private func handleHabitInvitationTap(_ notification: AppNotification) {
        print("🔔 Habit invitation tapped:")
        print("   Notification ID: \(notification.id ?? "nil")")
        print("   Habit ID: \(notification.habitId ?? "nil")")
        print("   Sender Username: \(notification.senderUsername ?? "nil")")
        print("   Recipient User ID: \(notification.recipientUserId)")
        print("   Current User: \(Auth.auth().currentUser?.uid ?? "nil")")
        
        guard let habitId = notification.habitId,
              let senderUsername = notification.senderUsername else {
            print("❌ Missing habit ID or sender username for habit invitation")
            return
        }
        
        // Fetch habit data from Firebase
        Task {
            do {
                print("🔍 Fetching habit data for habitId: \(habitId)")
                let habit = try await fetchHabitFromFirebase(habitId: habitId)
                let invitedUsers = try await fetchInvitedUsersForHabit(habitId: habitId)
                
                await MainActor.run {
                    selectedHabit = habit
                    selectedInviterUsername = senderUsername
                    selectedInvitedUsers = invitedUsers
                    showingHabitInvitation = true
                }
            } catch {
                print("❌ Error fetching habit data: \(error.localizedDescription)")
                print("   Error details: \(error)")
            }
        }
    }
    
    private func fetchHabitFromFirebase(habitId: String) async throws -> Habit {
        print("🔍 Attempting to fetch habit from Firebase:")
        print("   Habit ID: \(habitId)")
        print("   Current User: \(Auth.auth().currentUser?.uid ?? "nil")")
        
        let db = Firestore.firestore()
        let document = try await db.collection("habits").document(habitId).getDocument()
        
        print("   Document exists: \(document.exists)")
        print("   Document data: \(document.data() ?? [:])")
        
        guard let data = document.data() else {
            print("❌ No document data found")
            throw NSError(domain: "NotificationsView", code: 1, userInfo: [NSLocalizedDescriptionKey: "Habit not found"])
        }
        
        // Convert Firebase data to Habit object
        return Habit(
            name: data["name"] as? String ?? "",
            selectedDays: data["selectedDays"] as? [String] ?? [],
            timeOfDay: (data["timeOfDay"] as? Timestamp)?.dateValue() ?? Date(),
            frequencyPerWeek: data["frequencyPerWeek"] as? Int ?? 0,
            commitmentLevel: data["commitmentLevel"] as? Int ?? 1,
            colorIndex: data["colorIndex"] as? Int ?? 0,
            completedDates: Set(data["completedDates"] as? [String] ?? []),
            descriptionText: data["descriptionText"] as? String,
            invitedAllies: data["invitedAllies"] as? [String],
            reminderEnabled: data["reminderEnabled"] as? Bool ?? true,
            createdByUserId: data["createdByUserId"] as? String
        )
    }
    
    private func fetchInvitedUsersForHabit(habitId: String) async throws -> [InvitedUser] {
        // For now, return mock data. In a real implementation, you'd fetch this from Firebase
        // based on the habit's invitedAllies array and their response status
        return [
            InvitedUser(username: "alex", status: .pending),
            InvitedUser(username: "sam", status: .accepted)
        ]
    }
    
    private func dismissNotification(_ notification: AppNotification) {
        Task {
            do {
                try await notificationStore.deleteNotification(notification)
            } catch {
                print("Error dismissing notification: \(error.localizedDescription)")
            }
        }
    }
}


// MARK: - UI Components

struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    isSelected ? 
                    Color.blue : 
                    Color(.systemGray6)
                )
                .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct NotificationCard: View {
    let notification: AppNotification
    let onTap: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            if let avatarURL = notification.senderAvatarURL, let url = URL(string: avatarURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        Circle()
                            .fill(Color(.systemGray5))
                            .overlay(
                                Image(systemName: notification.type.icon)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.secondary)
                            )
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure(_):
                        Circle()
                            .fill(Color(.systemGray5))
                            .overlay(
                                Image(systemName: notification.type.icon)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.secondary)
                            )
                    @unknown default:
                        Circle()
                            .fill(Color(.systemGray5))
                            .overlay(
                                Image(systemName: notification.type.icon)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.secondary)
                            )
                    }
                }
                .frame(width: 44, height: 44)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: notification.type.icon)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    )
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(notification.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if !notification.isRead {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 8, height: 8)
                    }
                }
                
                Text(notification.message)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                Text(timeAgoString(from: notification.timestamp))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            // Dismiss Button
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 24, height: 24)
                    .background(Color(.systemGray6))
                    .clipShape(Circle())
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .onTapGesture {
            onTap()
        }
    }
    
    
    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct EmptyNotificationsView: View {
    let filter: NotificationsView.NotificationFilter
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: iconForFilter)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text(titleForFilter)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            Text(messageForFilter)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
    
    private var iconForFilter: String {
        switch filter {
        case .all: return "bell.slash"
        case .unread: return "bell"
        case .habit: return "checkmark.circle"
        case .ally: return "person.2"
        case .guild: return "person.3"
        }
    }
    
    private var titleForFilter: String {
        switch filter {
        case .all: return "No notifications yet"
        case .unread: return "All caught up!"
        case .habit: return "No habit notifications"
        case .ally: return "No ally notifications"
        case .guild: return "No guild notifications"
        }
    }
    
    private var messageForFilter: String {
        switch filter {
        case .all: return "You'll see notifications about your habits, allies, and guilds here."
        case .unread: return "You have no unread notifications."
        case .habit: return "Notifications about your habits will appear here."
        case .ally: return "Notifications from your allies will appear here."
        case .guild: return "Notifications from your guilds will appear here."
        }
    }
}


#Preview {
    NotificationsView()
        .environmentObject(NotificationStore())
}
