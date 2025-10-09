//
//  ProfileView.swift
//  vibe 1
//
//  Created by Jamie Cheatham on 10/4/25.
//

import SwiftUI
import PhotosUI
import AVFoundation
import FirebaseAuth

struct ProfileView: View {
    @ObservedObject var habitStore: HabitStore
    // Notifications removed
    @EnvironmentObject var authManager: AuthManager
    @State private var showingImagePicker = false
    @State private var showingCameraPicker = false
    @State private var showingPhotoSource = false
    @State private var selectedImage: UIImage?
    @State private var username = "User"
    @State private var showingUsernameAlert = false
    @State private var tempUsername = ""
    @State private var showCameraDeniedAlert = false
    @State private var showPhotosDeniedAlert = false
    @State private var showingAllies = false
    @State private var allies: [String] = ["Alex", "Jordan", "Sam"]
    @State private var showingSettings = false
    // Notifications removed
    
    var currentStreak: Int {
        calculateCurrentStreak()
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    profileHeaderSection()
                    statsSection()
                }
                .padding(.bottom, 40)
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
        }
        .sheet(isPresented: $showingCameraPicker) {
            CameraPicker(selectedImage: $selectedImage)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsSheet(username: $username, authManager: authManager, requestPush: {
                // Notifications removed
            })
        }
        .sheet(isPresented: $showingAllies) {
            AlliesSheet()
        }
        // Notifications sheet removed
        .alert("Change Username", isPresented: $showingUsernameAlert) {
            TextField("Username", text: $tempUsername)
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                username = tempUsername
                saveUserData()
            }
        } message: {
            Text("Enter your username")
        }
        .onAppear {
            loadUserData()
        }
        .onChange(of: selectedImage) { _, _ in
            saveUserData()
            // Upload avatar to Firebase Storage and save url to Firestore
            if let image = selectedImage, let uid = Auth.auth().currentUser?.uid {
                Task {
                    do {
                        let url = try await StorageService().uploadAvatar(image: image, for: uid)
                        try await AlliesService().upsertUser(uid: uid, username: username, avatarURL: url)
                        print("[Firebase] avatar uploaded & user updated")
                    } catch {
                        print("[Firebase] avatar upload/update failed:", error.localizedDescription)
                    }
                }
            }
        }
        .overlay(alignment: .top) { topOverlays() }
        .alert("Camera Access Needed", isPresented: $showCameraDeniedAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Please enable camera access in Settings to take a photo.")
        }
        .alert("Photos Access Needed", isPresented: $showPhotosDeniedAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Please enable photo library access in Settings to choose a photo.")
        }
    }

    private func requestCameraAndPresent() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            showingCameraPicker = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted { showingCameraPicker = true } else { showCameraDeniedAlert = true }
                }
            }
        default:
            showCameraDeniedAlert = true
        }
    }
    
    private func requestPhotosAndPresent() {
        if #available(iOS 14, *) {
            let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
            switch status {
            case .authorized, .limited:
                showingImagePicker = true
            case .notDetermined:
                PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
                    DispatchQueue.main.async {
                        if newStatus == .authorized || newStatus == .limited { showingImagePicker = true } else { showPhotosDeniedAlert = true }
                    }
                }
            default:
                showPhotosDeniedAlert = true
            }
        } else {
            let status = PHPhotoLibrary.authorizationStatus()
            switch status {
            case .authorized:
                showingImagePicker = true
            case .notDetermined:
                PHPhotoLibrary.requestAuthorization { newStatus in
                    DispatchQueue.main.async {
                        if newStatus == .authorized { showingImagePicker = true } else { showPhotosDeniedAlert = true }
                    }
                }
            default:
                showPhotosDeniedAlert = true
            }
        }
    }
    
    private var completedTodayCount: Int {
        habitStore.habits.filter { $0.isCompletedToday }.count
    }
    
    private var weeklyGoalProgress: String {
        let totalWeeklyHabits = habitStore.habits.reduce(0) { $0 + $1.frequencyPerWeek }
        let completedThisWeek = habitStore.habits.filter { $0.isCompletedToday }.reduce(0) { $0 + $1.frequencyPerWeek }
        return "\(completedThisWeek)/\(totalWeeklyHabits)"
    }
    
    private var bestStreak: Int {
        // For now, return current streak. In a real app, you'd track this over time
        return currentStreak
    }
    
    private func calculateCurrentStreak() -> Int {
        let calendar = Calendar.current
        let today = Date()
        var streak = 0
        var currentDate = today
        
        // Check backwards from today
        for _ in 0..<365 { // Check up to a year back
            let dayName = getDayName(for: currentDate)
            let habitsForDay = habitStore.habits.filter { $0.selectedDays.contains(dayName) }
            
            if habitsForDay.isEmpty {
                // No habits for this day, continue checking
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
                continue
            }
            
            // Check if any habit was completed on this day
            let hasCompletedHabit = habitsForDay.contains { habit in
                if let completedDate = habit.completedDate {
                    return calendar.isDate(completedDate, inSameDayAs: currentDate)
                }
                return false
            }
            
            if hasCompletedHabit {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else {
                break
            }
        }
        
        return streak
    }
    
    private func getDayName(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
    
    private func saveUserData() {
        UserDefaults.standard.set(username, forKey: "UserUsername")
        if let imageData = selectedImage?.jpegData(compressionQuality: 0.8) {
            UserDefaults.standard.set(imageData, forKey: "UserProfileImage")
        }
    }
    
    private func loadUserData() {
        username = UserDefaults.standard.string(forKey: "UserUsername") ?? "User"
        if let imageData = UserDefaults.standard.data(forKey: "UserProfileImage"),
           let image = UIImage(data: imageData) {
            selectedImage = image
        }
    }
}

// MARK: - Extracted Sections
extension ProfileView {
    @ViewBuilder private func profileHeaderSection() -> some View {
        VStack(spacing: 12) {
            Button(action: { showingPhotoSource = true }) {
                ZStack {
                    if let selectedImage = selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Color(.systemGray5))
                            .frame(width: 120, height: 120)
                            .overlay(
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.secondary)
                            )
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            .confirmationDialog("Select Photo", isPresented: $showingPhotoSource, titleVisibility: .visible) {
                Button("Take Photo") { requestCameraAndPresent() }
                Button("Choose from Library") { requestPhotosAndPresent() }
                Button("Cancel", role: .cancel) {}
            }
            
            if selectedImage == nil {
                Button("Add photo") { showingPhotoSource = true }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.blue)
            }
            
            VStack(spacing: 12) {
                Text(username)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                HStack(spacing: 8) {
                    Text("🔥").font(.system(size: 20))
                    Text("\(currentStreak) day streak")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(20)
                Button(action: { showingAllies = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "person.2.fill").foregroundColor(.blue)
                        Text("Allies • \(allies.count)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.blue)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(18)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.top, 20)
    }
    
    @ViewBuilder private func statsSection() -> some View {
        VStack(spacing: 24) {
            Text("Your Progress")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.primary)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                StatCard(title: "Total Habits", value: "\(habitStore.habits.count)", icon: "list.bullet", color: .blue)
                StatCard(title: "Completed Today", value: "\(completedTodayCount)", icon: "checkmark.circle", color: .green)
                StatCard(title: "Weekly Goal", value: "\(weeklyGoalProgress)", icon: "target", color: .purple)
                StatCard(title: "Best Streak", value: "\(bestStreak)", icon: "flame", color: .orange)
            }
        }
        .padding(.horizontal, 20)
    }
    
    @ViewBuilder private func topOverlays() -> some View {
        HStack {
            Button(action: { showingSettings = true }) {
                Image(systemName: "gearshape")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 36, height: 36)
                    .background(Color(.systemGray6))
                    .clipShape(Circle())
            }
            .padding(.leading, 20)
            .padding(.top, 12)
            Spacer()
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
            
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    DispatchQueue.main.async {
                        self.parent.selectedImage = image as? UIImage
                    }
                }
            }
        }
    }
}

// Camera picker
struct CameraPicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraPicker
        init(_ parent: CameraPicker) { self.parent = parent }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            picker.dismiss(animated: true) { self.parent.dismiss() }
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { picker.dismiss(animated: true) { self.parent.dismiss() } }
    }
}

// MARK: - Settings Sheet

import FirebaseAuth

struct SettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var username: String
    @ObservedObject var authManager: AuthManager
    var requestPush: () -> Void
    @State private var editingUsername: String = ""
    @State private var showingSignOutAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile")) {
                    HStack {
                        Text("Username")
                        Spacer()
                        TextField("Username", text: $editingUsername)
                            .multilineTextAlignment(.trailing)
                    }
                    Button("Save Username") {
                        username = editingUsername
                        let service = AlliesService()
                        if let uid = Auth.auth().currentUser?.uid {
                            Task {
                                do {
                                    try await service.upsertUser(uid: uid, username: editingUsername, avatarURL: nil)
                                    print("[Firebase] upsertUser ok for", uid)
                                } catch {
                                    print("[Firebase] upsertUser error:", error.localizedDescription)
                                }
                            }
                        } else {
                            print("[Firebase] No signed-in user; cannot write")
                        }
                    }
                }
                Section(header: Text("Notifications")) {
                    Button("Activate push notifications") {
                        requestPush()
                    }
                }
                Section {
                    Button("Log out of account") {
                        showingSignOutAlert = true
                    }
                        .foregroundColor(.red)
                    Button("Delete account and all information") {}
                        .foregroundColor(.red)
                }
            }
            .alert("Sign Out", isPresented: $showingSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    do {
                        try authManager.signOut()
                        dismiss()
                    } catch {
                        print("Error signing out: \(error.localizedDescription)")
                    }
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
            }
            .onAppear { editingUsername = username }
        }
    }
}

// Allies UI
struct AlliesSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText: String = ""
    @State private var results: [AlliesService.User] = []
    @State private var isSearching = false
    @State private var pendingSearch: DispatchWorkItem?
    @State private var contactsAuthNotAuthorized = false
    @State private var showingContactsPrompt = false
    private let service = AlliesService()

    private func performSearch() {
        isSearching = true
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        Task {
            do {
                var fetched = try await service.searchUsers(prefix: query)
                if let uid = Auth.auth().currentUser?.uid {
                    fetched.removeAll { $0.id == uid }
                }
                results = fetched
            } catch {
                results = []
            }
            isSearching = false
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Contacts invite prompt if permission not granted
                    if contactsAuthNotAuthorized {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Invite from Contacts")
                                .font(.system(size: 16, weight: .semibold))
                            Button(action: { requestContactsAccess() }) {
                                HStack {
                                    Image(systemName: "person.crop.circle.badge.plus")
                                    Text("Invite contacts")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.blue)
                                .cornerRadius(12)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal, 16)
                    }
                    // Search card
                    HStack(spacing: 10) {
                        Text("🔎")
                            .font(.system(size: 22))
                            .frame(width: 44, height: 44)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        TextField("Search an Ally's username", text: $searchText)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .keyboardType(.asciiCapable)
                    }
                    .padding(.horizontal, 16)
                    
                    // Allies results list
                    VStack(alignment: .leading, spacing: 8) {
                        if isSearching {
                            ProgressView().padding(.horizontal, 16)
                        }
                        ForEach(results) { user in
                            HStack {
                                if let urlStr = user.avatarURL, let url = URL(string: urlStr) {
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .empty:
                                            ProgressView()
                                        case .success(let image):
                                            image.resizable().scaledToFill()
                                        case .failure(_):
                                            Circle().fill(Color(.systemGray5))
                                                .overlay(Text(String(user.username.prefix(1))).font(.system(size: 16, weight: .bold)))
                                        @unknown default:
                                            Circle().fill(Color(.systemGray5))
                                                .overlay(Text(String(user.username.prefix(1))).font(.system(size: 16, weight: .bold)))
                                        }
                                    }
                                    .frame(width: 36, height: 36)
                                    .clipShape(Circle())
                                } else {
                                    Circle().fill(Color(.systemGray5)).frame(width: 36, height: 36)
                                        .overlay(Text(String(user.username.prefix(1))).font(.system(size: 16, weight: .bold)))
                                }
                                Text(user.username)
                                    .font(.system(size: 16, weight: .semibold))
                                Spacer()
                                if user.id != Auth.auth().currentUser?.uid {
                                    Button("Add") {
                                        Task {
                                            do {
                                                try await NotificationStore().sendAllyInvitation(toUserId: user.id)
                                                print("Ally invitation sent to \(user.username)")
                                            } catch {
                                                print("Error sending ally invitation: \(error.localizedDescription)")
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(12)
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.systemGray5), lineWidth: 1))
                            .shadow(color: Color.black.opacity(0.04), radius: 1, x: 0, y: 1)
                            .padding(.horizontal, 16)
                        }
                    }
                    
                    // Invite section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Invite an Ally to join this app")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 16)
                        Button(action: {}) {
                            Text("Create Invite Link")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.blue)
                                .cornerRadius(14)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Your Allies")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
            .onChange(of: searchText) { _, _ in
                // Debounce to avoid spamming queries and reduce keyboard subsystem logs
                pendingSearch?.cancel()
                let work = DispatchWorkItem { performSearch() }
                pendingSearch = work
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: work)
            }
            .task {
                // Show prompt when not authorized yet
                contactsAuthNotAuthorized = CNContactStore.authorizationStatus(for: .contacts) != .authorized
            }
        }
    }
}

import Contacts

extension AlliesSheet {
    private func requestContactsAccess() {
        let store = CNContactStore()
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .authorized:
            // Already authorized; proceed to contacts invite flow
            print("Contacts already authorized")
        case .notDetermined:
            store.requestAccess(for: .contacts) { granted, _ in
                DispatchQueue.main.async {
                    contactsAuthNotAuthorized = !granted
                }
            }
        default:
            // Denied or restricted
            contactsAuthNotAuthorized = true
        }
    }
}

#Preview {
    ProfileView(habitStore: HabitStore())
        .environmentObject(AuthManager())
}
