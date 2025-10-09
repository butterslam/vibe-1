//
//  HabitInvitationView.swift
//  vibe 1
//
//  Created by Jamie Cheatham on 10/4/25.
//

import SwiftUI

struct HabitInvitationView: View {
    let habit: Habit
    let inviterUsername: String
    let invitedUsers: [InvitedUser]
    @State private var selectedReminderTime: Date = Date()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 18) {
                    // Header with habit name
                    VStack(spacing: 8) {
                        Text(habit.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.primary)
                        
                        Text("Habit Invitation")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)
                    
                    // Inviter and invited users section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Life")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        
                        HStack {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Text(String(inviterUsername.prefix(1)).uppercased())
                                        .font(.headline)
                                        .foregroundColor(.white)
                                )
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(inviterUsername)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text("Creator")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text("Accepted")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.2))
                                .foregroundColor(.green)
                                .cornerRadius(8)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        
                        if !invitedUsers.isEmpty {
                            Text("Other participants")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            ForEach(invitedUsers) { user in
                                HStack {
                                    Circle()
                                        .fill(Color.orange)
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Text(String(user.username.prefix(1)).uppercased())
                                                .font(.headline)
                                                .foregroundColor(.white)
                                        )
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(user.username)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Text("Invited")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Text(user.status.displayName)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(user.status.color.opacity(0.2))
                                        .foregroundColor(user.status.color)
                                        .cornerRadius(8)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                        }
                    }
                    
                    // Description section
                    if let description = habit.descriptionText, !description.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Description")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text(description)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        }
                    }
                    
                    // Days of the week cards
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Schedule")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                            ForEach(["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"], id: \.self) { day in
                                let isSelected = habit.selectedDays.contains(day)
                                
                                Text(day)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(isSelected ? .white : .primary)
                                    .frame(width: 40, height: 40)
                                    .background(
                                        Circle()
                                            .fill(isSelected ? Color.blue : Color(.systemGray5))
                                    )
                            }
                        }
                    }
                    
                    // Set a Reminder section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Set a Reminder")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        HStack {
                            Image(systemName: "bell.fill")
                                .foregroundColor(.blue)
                                .frame(width: 20)
                            
                            DatePicker("Reminder Time", selection: $selectedReminderTime, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                            
                            Spacer()
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // Action buttons
                    VStack(spacing: 16) {
                        Button(action: {
                            // Accept habit action
                            dismiss()
                        }) {
                            Text("Accept Habit")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .cornerRadius(12)
                        }
                        
                        Button(action: {
                            // Decline habit action
                            dismiss()
                        }) {
                            Text("Decline")
                                .font(.headline)
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.bottom, 32)
                }
                .padding(.horizontal)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Models

struct InvitedUser: Identifiable {
    let id = UUID()
    let username: String
    let status: InvitationStatus
}

enum InvitationStatus {
    case pending
    case accepted
    case declined
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .accepted: return "Accepted"
        case .declined: return "Declined"
        }
    }
    
    var color: Color {
        switch self {
        case .pending: return .orange
        case .accepted: return .green
        case .declined: return .red
        }
    }
}

// MARK: - Preview

#Preview {
    HabitInvitationView(
        habit: Habit(
            name: "Morning Workout",
            selectedDays: ["Mon", "Wed", "Fri"],
            timeOfDay: Date(),
            frequencyPerWeek: 3,
            commitmentLevel: 5,
            colorIndex: 0,
            completedDates: Set(),
            descriptionText: "Start your day with a 30-minute workout to boost energy and focus.",
            invitedAllies: ["yoyo", "alex"],
            reminderEnabled: true,
            createdByUserId: nil
        ),
        inviterUsername: "jamie",
        invitedUsers: [
            InvitedUser(username: "yoyo", status: .accepted),
            InvitedUser(username: "alex", status: .pending)
        ]
    )
}
