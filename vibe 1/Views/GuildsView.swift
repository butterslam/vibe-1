//
//  GuildsView.swift
//  vibe 1
//
//  UI scaffold for Guilds screen
//

import SwiftUI

struct GuildsView: View {
    struct Guild: Identifiable {
        let id = UUID()
        let name: String
        let description: String
        let image: Image
    }
    
    // Placeholder data
    private let joinedGuilds: [Guild] = [
        Guild(name: "Early Risers", description: "Wake up at 5am and win the day.", image: Image(systemName: "sun.max.fill")),
        Guild(name: "Deep Work Circle", description: "120 minutes focused work daily.", image: Image(systemName: "brain.head.profile"))
    ]
    
    @State private var showingCreate = false
    @State private var showingJoin = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // Top bar
                HStack {
                    Text("Guilds")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                    Spacer()
                    Button(action: { showingJoin = true }) {
                        Text("Join")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray5))
                            .cornerRadius(10)
                    }
                    Button(action: { showingCreate = true }) {
                        Text("Create New")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.orange)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Joined")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 20)
                        
                        LazyVStack(spacing: 12) {
                            ForEach(joinedGuilds) { guild in
                                GuildCard(guild: guild)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingCreate) {
            CreateGuildSheet()
        }
        .sheet(isPresented: $showingJoin) {
            JoinGuildSheet()
        }
    }
}

struct GuildCard: View {
    let guild: GuildsView.Guild
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 48, height: 48)
                guild.image
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.orange)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(guild.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                Text(guild.description)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            Spacer()
        }
        .padding(14)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Create / Join Sheets

struct JoinGuildSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var inviteLink: String = ""
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Enter invite link to join a guild")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 12)
                TextField("https://...", text: $inviteLink)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal, 16)
                Spacer()
            }
            .navigationTitle("Join Guild")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Join") { dismiss() } }
            }
        }
    }
}

struct CreateGuildSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selection: Selection = .casual
    @State private var name: String = ""
    @State private var description: String = ""
    @State private var selectedEmoji: String = "😊"
    @State private var showEmojiPicker = false
    @State private var showInvite = false
    @State private var showDescriptionEditor = false
    
    enum Selection { case casual, hardcore }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Create a Guild")
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                    
                    // Selector
                    HStack(spacing: 16) {
                        SelectCard(
                            title: "Casual",
                            emoji: "🤙",
                            subtitle: "Commit to specific habits with your guild members.",
                            isSelected: selection == .casual,
                            action: { selection = .casual }
                        )
                        SelectCard(
                            title: "Hardcore",
                            emoji: "🛡️",
                            subtitle: "Raise the stakes with guildmates and pay the price for missing habits.",
                            isSelected: selection == .hardcore,
                            action: { selection = .hardcore }
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name")
                            .font(.system(size: 20, weight: .bold))
                        HStack(spacing: 10) {
                            Button(action: { showEmojiPicker = true }) {
                                Text(selectedEmoji)
                                    .font(.system(size: 22))
                                    .frame(width: 44, height: 44)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(10)
                            }
                            .buttonStyle(PlainButtonStyle())
                            TextField("Name your guild...", text: $name)
                                .padding(12)
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        if showDescriptionEditor || !description.isEmpty {
                            HStack(spacing: 10) {
                                ZStack {
                                    Circle().fill(Color(.systemGray6))
                                        .frame(width: 44, height: 44)
                                    Image(systemName: "text.alignleft")
                                        .foregroundColor(.secondary)
                                }
                                TextEditor(text: $description)
                                    .frame(minHeight: 80)
                                    .padding(8)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(10)
                            }
                        } else {
                            Button(action: { showDescriptionEditor = true }) {
                                HStack {
                                    ZStack {
                                        Circle().fill(Color(.systemGray6))
                                            .frame(width: 44, height: 44)
                                        Image(systemName: "plus")
                                            .foregroundColor(.secondary)
                                    }
                                    Text("Add a description")
                                        .foregroundColor(.secondary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(12)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(10)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Invite members
                    Button(action: { showInvite = true }) {
                        Text("Invite Guild Members")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.orange)
                            .cornerRadius(14)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 20)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Back") { dismiss() } }
            }
            .sheet(isPresented: $showEmojiPicker) {
                EmojiPickerSheet(selected: $selectedEmoji)
            }
            .sheet(isPresented: $showInvite) {
                InviteMembersSheet()
            }
        }
    }
}

struct SelectCard: View {
    let title: String
    let emoji: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Text(emoji).font(.system(size: 26))
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                Text(subtitle)
                    .font(.system(size: 13))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                    .opacity(0.9)
            }
            .padding(18)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.orange.opacity(0.25) : Color.orange.opacity(0.12))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.orange : Color.clear, lineWidth: 2)
            )
            .cornerRadius(14)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EmojiPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selected: String
    private let emojis = ["😀","😄","😁","😎","🤙","🧠","🏃‍♀️","📚","🛡️","🔥","🌟","🎯","💪","🧘","🥗","🚴","🏋️","📈"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 6)
    var body: some View {
        NavigationView {
            ScrollView { LazyVGrid(columns: columns, spacing: 12) { ForEach(emojis, id: \.self) { e in
                Button(action: { selected = e; dismiss() }) { Text(e).font(.system(size: 28)) }
                .buttonStyle(PlainButtonStyle())
            } } .padding() }
            .navigationTitle("Pick Emoji")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
        }
    }
}

struct InviteMembersSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var username: String = ""
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Invite friends by username or create an invite link.")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 12)
                HStack {
                    TextField("Friend's username", text: $username)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Button("Invite") {}
                }
                .padding(.horizontal, 16)
                Button(action: {}) {
                    Text("Create Invite Link")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.orange)
                        .cornerRadius(12)
                }
                Spacer()
            }
            .navigationTitle("Invite Members")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
        }
    }
}

#Preview {
    GuildsView()
}


