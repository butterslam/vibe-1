//
//  AddHabitView.swift
//  vibe 1
//
//  Created by Jamie Cheatham on 10/4/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct AddHabitView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var habitStore: HabitStore
    // Notifications removed
    
    @State private var habitName = ""
    @State private var habitDescription = ""
    // Removed time-of-day as an inline selector; retained backing state for reminder scheduling
    @State private var selectedTime = Date()
    @State private var selectedDays: Set<String> = []
    @State private var showingConfetti = false
    @State private var errorMessage = ""
    @State private var selectedColorIndex = 0
    @State private var showingReminderPicker = false
    @State private var showingInviteAllies = false
    @State private var allySearchText = ""
    @State private var mockFriends: [Friend] = [
        Friend(name: "Alex Morgan"),
        Friend(name: "Jamie Lee"),
        Friend(name: "Riley Chen"),
        Friend(name: "Sam Patel"),
        Friend(name: "Jordan Smith"),
        Friend(name: "Taylor Brown")
    ]
    @State private var invitedAllies: Set<String> = []
    @State private var invitedAllyData: [String: String] = [:] // username -> userId mapping
    @State private var hasSelectedReminder = false
    @State private var isReminderDisabled = false
    
    private let daysOfWeek = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    private let fullDaysOfWeek = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    
    private let habitColors: [Color] = [
        Color.pink, Color.blue, Color.orange, Color.purple, Color.green,
        Color.red, Color.yellow, Color.indigo, Color.mint, Color.teal,
        Color.cyan, Color.brown
    ]
    
    var isFormValid: Bool {
        !habitName.isEmpty && !selectedDays.isEmpty
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    VStack(spacing: 32) {
                        // Header Section
                        VStack(spacing: 16) {
                            Text("Your future is a reflection of daily habits.")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            
                            Text("Add A Habit")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.primary)
                        }
                        .padding(.top, 20)
                        
                        VStack(spacing: 24) {
                        // 1. Habit Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Habit Name")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            TextField("e.g., Morning Exercise", text: $habitName)
                                .textFieldStyle(ModernTextFieldStyle())
                                .onChange(of: habitName) { _, _ in
                                    clearError()
                                }
                                .toolbar {
                                    ToolbarItemGroup(placement: .keyboard) {
                                        Spacer()
                                        Button("Done") {
                                            hideKeyboard()
                                        }
                                    }
                                }
                        }
                        
                        // 2. Invite Allies
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Invite Allies")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            Button(action: { showingInviteAllies = true }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "person.2.fill")
                                        .foregroundColor(invitedFriendsCount() > 0 ? .white : .blue)
                                    Text(inviteButtonTitle())
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(invitedFriendsCount() > 0 ? .white : .primary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(invitedFriendsCount() > 0 ? .white.opacity(0.9) : .secondary)
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(invitedFriendsCount() > 0 ? Color.green : Color(.systemGray6))
                                .cornerRadius(12)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }

                        // 3. Description
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            ZStack(alignment: .topLeading) {
                                if habitDescription.isEmpty {
                                    Text("What exactly are you going to do?")
                                        .foregroundColor(.secondary)
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 12)
                                }
                                TextEditor(text: $habitDescription)
                                    .frame(minHeight: 100)
                                    .padding(8)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                            }
                            .toolbar {
                                ToolbarItemGroup(placement: .keyboard) {
                                    Spacer()
                                    Button("Done") {
                                        hideKeyboard()
                                    }
                                }
                            }
                        }
                        
                        // 4. Days of Week
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Days of Week")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            HStack(spacing: 10) {
                                ForEach(Array(daysOfWeek.enumerated()), id: \.offset) { index, day in
                                    DayButton(
                                        day: day,
                                        isSelected: selectedDays.contains(fullDaysOfWeek[index]),
                                        action: {
                                            toggleDay(fullDaysOfWeek[index])
                                        }
                                    )
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                        }

                        // 5. Add a daily reminder
                        VStack(alignment: .leading, spacing: 12) {
                            Button(action: { showingReminderPicker = true }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "alarm")
                                        .foregroundColor(buttonForegroundColorForReminder())
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(reminderTitleText())
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(buttonTextColorForReminder())
                                        Text(reminderSubtitleText())
                                            .font(.system(size: 13, weight: .regular))
                                            .foregroundColor(reminderSubtitleColor())
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(buttonChevronColorForReminder())
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(backgroundColorForReminder())
                                .cornerRadius(12)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        // 4. Habit Color
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Habit Color")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                                ForEach(0..<habitColors.count, id: \.self) { index in
                                    ColorButton(
                                        color: habitColors[index],
                                        isSelected: selectedColorIndex == index,
                                        action: {
                                            selectedColorIndex = index
                                        }
                                    )
                                }
                            }
                        }
                        
                        // Error Message
                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.red)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                        }
                        
                        // 4. Add Habit Button
                        Button(action: addHabit) {
                            HStack {
                                if showingConfetti {
                                    Image(systemName: "party.popper.fill")
                                        .font(.system(size: 16, weight: .medium))
                                }
                                Text("Add Habit")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .foregroundColor(isFormValid ? .white : .secondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                isFormValid ? 
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ) : 
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.2)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(
                                color: isFormValid ? Color.blue.opacity(0.3) : Color.clear,
                                radius: 8,
                                x: 0,
                                y: 4
                            )
                        }
                        .disabled(!isFormValid)
                        .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 40)
            }
            .navigationBarHidden(true)
            .overlay(
                // White X button in top left
                VStack {
                    HStack {
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        .padding(.leading, 20)
                        .padding(.top, 20)
                        Spacer()
                    }
                    Spacer()
                }
            )
            .overlay(
                // Confetti Animation
                ConfettiView(isActive: $showingConfetti)
                    .allowsHitTesting(false)
            )
            .sheet(isPresented: $showingReminderPicker) {
                VStack(spacing: 16) {
                    // Top bar with trailing Set Reminder button
                    HStack {
                        Spacer()
                        Button(action: {
                            hasSelectedReminder = true
                            isReminderDisabled = false
                            showingReminderPicker = false
                        }) {
                            Text("Set Reminder")
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                    
                    // Time selector
                    DatePicker("",
                               selection: $selectedTime,
                               displayedComponents: .hourAndMinute)
                        .datePickerStyle(WheelDatePickerStyle())
                        .labelsHidden()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    
                    // Danger Zone
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Danger Zone")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.red)
                        Button(action: {
                            isReminderDisabled = true
                            hasSelectedReminder = false
                            showingReminderPicker = false
                        }) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.white)
                                Text("I don't want a reminder")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal)
                    Spacer()
                }
                .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showingInviteAllies) {
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("Invite Allies")
                            .font(.system(size: 20, weight: .bold))
                        Spacer()
                        Button("Done") { showingInviteAllies = false }
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .padding()
                    
                    // Search Bar
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search an Ally username", text: $allySearchText)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                    }
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                    
                    // Allies Search Results
                    AlliesSearchResultsView(query: allySearchText, invitedAllies: invitedAllies, onInvite: { user in
                        toggleInviteAllyWithId(user.username, userId: user.id)
                    })
                    .listStyle(.plain)
                }
                .presentationDetents([.large])
            }
        }
    }
    
    private func toggleDay(_ day: String) {
        if selectedDays.contains(day) {
            selectedDays.remove(day)
        } else {
            selectedDays.insert(day)
        }
        clearError()
    }
    
    private func clearError() {
        errorMessage = ""
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func addHabit() {
        guard isFormValid else {
            showError()
            return
        }
        
        let invitedNames = Array(invitedAllies)
        let newHabit = Habit(
            name: habitName,
            selectedDays: Array(selectedDays),
            timeOfDay: selectedTime,
            frequencyPerWeek: selectedDays.count,
            commitmentLevel: 5, // Default commitment level
            colorIndex: selectedColorIndex,
            completedDates: [],
            descriptionText: habitDescription.isEmpty ? nil : habitDescription,
            invitedAllies: invitedNames,
            reminderEnabled: !isReminderDisabled,
            createdByUserId: Auth.auth().currentUser?.uid
        )
        
        habitStore.addHabit(newHabit)
        
        // Send habit invitations to allies
        if !invitedNames.isEmpty {
            for allyName in invitedNames {
                if let allyUserId = invitedAllyData[allyName] {
                    Task {
                        do {
                            try await NotificationStore().sendHabitInvitation(
                                habitName: habitName,
                                toUserId: allyUserId,
                                habitId: newHabit.id.uuidString
                            )
                            print("Habit invitation sent to \(allyName)")
                        } catch {
                            print("Error sending habit invitation: \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
        
        // Show confetti animation
        withAnimation(.easeInOut(duration: 0.3)) {
            showingConfetti = true
        }
        
        // Dismiss after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            dismiss()
        }
    }
    
    private func showError() {
        if habitName.isEmpty {
            errorMessage = "Please enter a habit name"
        } else if selectedDays.isEmpty {
            errorMessage = "Please select at least one day"
        }
    }

    // MARK: - Allies Helpers (Mock)
    private func filteredFriends() -> [Friend] {
        let query = allySearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if query.isEmpty { return mockFriends }
        return mockFriends.filter { $0.name.lowercased().contains(query.lowercased()) }
    }
    
    private func toggleInvite(_ friend: Friend) {
        // Update mock friends if it exists there
        if let index = mockFriends.firstIndex(where: { $0._id == friend._id }) {
            mockFriends[index].invited.toggle()
        }
        
        // Also update the invited allies set
        if invitedAllies.contains(friend.name) {
            invitedAllies.remove(friend.name)
        } else {
            invitedAllies.insert(friend.name)
        }
    }
    
    private func toggleInviteAlly(_ username: String) {
        if invitedAllies.contains(username) {
            invitedAllies.remove(username)
            invitedAllyData.removeValue(forKey: username)
            print("Removed \(username) from invited allies")
        } else {
            invitedAllies.insert(username)
            print("Added \(username) to invited allies")
        }
        print("Current invited allies: \(invitedAllies)")
    }
    
    private func toggleInviteAllyWithId(_ username: String, userId: String) {
        if invitedAllies.contains(username) {
            invitedAllies.remove(username)
            invitedAllyData.removeValue(forKey: username)
            print("Removed \(username) from invited allies")
        } else {
            invitedAllies.insert(username)
            invitedAllyData[username] = userId
            print("Added \(username) (ID: \(userId)) to invited allies")
        }
        print("Current invited allies: \(invitedAllies)")
    }
    
    private func invitedFriends() -> [Friend] {
        mockFriends.filter { $0.invited }
    }
    
    private func invitedFriendsCount() -> Int {
        return invitedAllies.count
    }
    
    private func inviteButtonTitle() -> String {
        if invitedAllies.isEmpty { return "Invite Allies" }
        let firstNames = invitedAllies.map { nameFirstWord($0) }
        if firstNames.count == 1 {
            return "\(firstNames[0]) Invited"
        }
        if firstNames.count == 2 {
            return "\(firstNames[0]), \(firstNames[1]) Invited"
        }
        let additional = firstNames.count - 2
        return "\(firstNames[0]), \(firstNames[1]) + \(additional) More"
    }
    
    private func nameFirstWord(_ fullName: String) -> String {
        fullName.split(separator: " ").first.map(String.init) ?? fullName
    }
}

struct DayButton: View {
    let day: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(day)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(isSelected ? .white : .primary)
                .frame(width: 46, height: 40)
                .background(
                    isSelected ? 
                    Color.blue : 
                    Color(.systemGray6)
                )
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            isSelected ? Color.blue : Color(.systemGray4),
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ConfettiView: View {
    @Binding var isActive: Bool
    @State private var confettiPieces: [ConfettiPiece] = []
    
    var body: some View {
        ZStack {
            ForEach(confettiPieces, id: \.id) { piece in
                Circle()
                    .fill(piece.color)
                    .frame(width: piece.size, height: piece.size)
                    .position(piece.position)
                    .opacity(piece.opacity)
            }
        }
        .onChange(of: isActive) { _, active in
            if active {
                // Only create confetti if we have valid screen bounds
                let screenBounds = UIScreen.main.bounds
                if screenBounds.width.isFinite && screenBounds.height.isFinite && screenBounds.width > 0 && screenBounds.height > 0 {
                    createConfetti()
                }
            }
        }
    }
    
    private func createConfetti() {
        confettiPieces.removeAll()
        
        // Get safe screen bounds
        let screenBounds = UIScreen.main.bounds
        let screenWidth = screenBounds.width.isFinite ? screenBounds.width : 400
        let screenHeight = screenBounds.height.isFinite ? screenBounds.height : 800
        
        for _ in 0..<50 {
            let x = CGFloat.random(in: 0...screenWidth)
            let y = -50.0
            let size = CGFloat.random(in: 4...8)
            
            // Ensure all values are finite
            guard x.isFinite && y.isFinite && size.isFinite else { continue }
            
            let piece = ConfettiPiece(
                position: CGPoint(x: x, y: y),
                color: [Color.blue, Color.green, Color.orange, Color.pink, Color.purple, Color.yellow].randomElement() ?? Color.blue,
                size: size,
                opacity: 1.0
            )
            confettiPieces.append(piece)
        }
        
        // Animate confetti falling
        withAnimation(.easeOut(duration: 2.0)) {
            for i in confettiPieces.indices {
                let newY = screenHeight + 100
                if newY.isFinite {
                    confettiPieces[i].position.y = newY
                }
                confettiPieces[i].opacity = 0
            }
        }
        
        // Reset after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isActive = false
        }
    }
}

struct ConfettiPiece {
    let id = UUID()
    var position: CGPoint
    let color: Color
    let size: CGFloat
    var opacity: Double
}

struct Friend: Identifiable, Hashable {
    let _id = UUID()
    var id: UUID { _id }
    let name: String
    var invited: Bool = false
    var initials: String {
        let parts = name.split(separator: " ")
        let first = parts.first?.first.map(String.init) ?? ""
        let last = parts.dropFirst().first?.first.map(String.init) ?? ""
        return (first + last).uppercased()
    }
}

// MARK: - Allies Search Results (Firebase-backed)
struct AlliesSearchResultsView: View {
    let query: String
    let invitedAllies: Set<String>
    var onInvite: (AlliesService.User) -> Void
    @State private var results: [AlliesService.User] = []
    @State private var isLoading = false
    private let service = AlliesService()
    
    var body: some View {
        List {
            if isLoading {
                HStack {
                    ProgressView()
                    Text("Searching...")
                        .foregroundColor(.secondary)
                }
            }
            ForEach(results) { user in
                HStack(spacing: 12) {
                    AsyncAvatar(urlString: user.avatarURL)
                        .frame(width: 36, height: 36)
                    Text(user.username)
                        .foregroundColor(.primary)
                    Spacer()
                    Button(action: { onInvite(user) }) {
                        Text(invitedAllies.contains(user.username) ? "Invited" : "Invite")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(invitedAllies.contains(user.username) ? Color.green : Color.blue)
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .contentShape(Rectangle())
                .listRowBackground(Color.clear)
            }
        }
        .onChange(of: query) { _, newValue in
            Task { await performSearch(for: newValue) }
        }
        .task { await performSearch(for: query) }
    }
    
    private func performSearch(for text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { results = []; return }
        isLoading = true
        do {
            // Use prefix search first; server can broaden to contains if needed
            var fetched = try await service.searchUsers(prefix: trimmed, limit: 25)
            // Filter out the current user
            if let uid = Auth.auth().currentUser?.uid {
                fetched.removeAll { $0.id == uid }
            }
            results = fetched
        } catch {
            results = []
        }
        isLoading = false
    }
}

struct AsyncAvatar: View {
    let urlString: String?
    var body: some View {
        if let urlString = urlString, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    Circle().fill(Color(.systemGray5))
                case .success(let image):
                    image.resizable().scaledToFill().clipShape(Circle())
                case .failure:
                    Circle().fill(Color(.systemGray5))
                @unknown default:
                    Circle().fill(Color(.systemGray5))
                }
            }
        } else {
            Circle().fill(Color(.systemGray5))
                .overlay(Image(systemName: "person.circle.fill").foregroundColor(.secondary))
        }
    }
}

// MARK: - Helper Functions
extension AddHabitView {
    private func getCurrentUsername() -> String {
        // Get username from UserDefaults (set in ProfileView)
        return UserDefaults.standard.string(forKey: "UserUsername") ?? "You"
    }
    
    private func getCurrentUsernameAsync(completion: @escaping (String) -> Void) {
        guard let currentUser = Auth.auth().currentUser else { 
            completion("You")
            return 
        }
        
        // Try to get username from user's profile document
        Firestore.firestore().collection("users").document(currentUser.uid).getDocument { document, error in
            if let error = error {
                print("Error fetching user profile: \(error.localizedDescription)")
                completion("You")
                return
            }
            
            if let document = document, document.exists,
               let data = document.data(),
               let username = data["username"] as? String {
                completion(username)
            } else {
                completion("You")
            }
        }
    }
}

// MARK: - Reminder UI Helpers
extension AddHabitView {
    private func backgroundColorForReminder() -> Color {
        if isReminderDisabled { return Color.red }
        if hasSelectedReminder { return Color.green }
        return Color(.systemGray6)
    }
    
    private func buttonTextColorForReminder() -> Color {
        (hasSelectedReminder || isReminderDisabled) ? .white : .primary
    }
    
    private func buttonChevronColorForReminder() -> Color {
        (hasSelectedReminder || isReminderDisabled) ? Color.white.opacity(0.9) : .secondary
    }
    
    private func buttonForegroundColorForReminder() -> Color {
        (hasSelectedReminder || isReminderDisabled) ? .white : .blue
    }
    
    private func reminderSubtitleText() -> String {
        if isReminderDisabled { return "No Reminder Selected" }
        if hasSelectedReminder {
            let timeString = selectedTime.formatted(date: .omitted, time: .shortened)
            let selectedCount = selectedDays.count
            if selectedCount == 7 { return "\(timeString), Daily" }
            let initials = selectedDaysSorted().map { String($0.prefix(1)) }.joined()
            return initials.isEmpty ? timeString : "\(timeString), \(initials)"
        }
        return "Select a time"
    }
    
    private func reminderTitleText() -> String {
        if isReminderDisabled { return "No Reminder Selected" }
        return hasSelectedReminder ? "Reminder Scheduled" : "Add a daily reminder"
    }
    
    private func selectedDaysSorted() -> [String] {
        fullDaysOfWeek.filter { selectedDays.contains($0) }
    }
    
    private func reminderSubtitleColor() -> Color {
        if isReminderDisabled { return .white }
        if hasSelectedReminder { return .white.opacity(0.9) }
        return .secondary
    }
}
struct ColorButton: View {
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Circle()
                .fill(color)
                .frame(width: 40, height: 40)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: isSelected ? 3 : 0)
                )
                .overlay(
                    Circle()
                        .stroke(Color.black, lineWidth: isSelected ? 1 : 0)
                )
                .overlay(
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .opacity(isSelected ? 1 : 0)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    AddHabitView(habitStore: HabitStore())
}
