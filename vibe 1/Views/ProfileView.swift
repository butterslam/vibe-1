//
//  ProfileView.swift
//  vibe 1
//
//  Created by Jamie Cheatham on 10/4/25.
//

import SwiftUI
import PhotosUI

struct ProfileView: View {
    @ObservedObject var habitStore: HabitStore
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var username = "User"
    @State private var showingUsernameAlert = false
    @State private var tempUsername = ""
    
    var currentStreak: Int {
        calculateCurrentStreak()
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Header Section
                    VStack(spacing: 20) {
                        // Profile Picture
                        Button(action: {
                            showingImagePicker = true
                        }) {
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
                                
                                // Add photo overlay
                                Circle()
                                    .stroke(Color.blue, lineWidth: 3)
                                    .frame(width: 120, height: 120)
                                    .overlay(
                                        VStack {
                                            Spacer()
                                            HStack {
                                                Spacer()
                                                Image(systemName: "camera.fill")
                                                    .font(.system(size: 16, weight: .semibold))
                                                    .foregroundColor(.white)
                                                    .frame(width: 32, height: 32)
                                                    .background(Color.blue)
                                                    .clipShape(Circle())
                                                    .offset(x: 8, y: 8)
                                            }
                                        }
                                    )
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Username and Streak
                        VStack(spacing: 12) {
                            HStack(spacing: 8) {
                                Text(username)
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.primary)
                                
                                Button(action: {
                                    tempUsername = username
                                    showingUsernameAlert = true
                                }) {
                                    Image(systemName: "pencil")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.blue)
                                }
                            }
                            
                            // Streak Display
                            HStack(spacing: 8) {
                                Text("🔥")
                                    .font(.system(size: 20))
                                
                                Text("\(currentStreak) day streak")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.orange)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(20)
                        }
                    }
                    .padding(.top, 20)
                    
                    // Stats Section
                    VStack(spacing: 24) {
                        Text("Your Progress")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            // Total Habits
                            StatCard(
                                title: "Total Habits",
                                value: "\(habitStore.habits.count)",
                                icon: "list.bullet",
                                color: .blue
                            )
                            
                            // Completed Today
                            StatCard(
                                title: "Completed Today",
                                value: "\(completedTodayCount)",
                                icon: "checkmark.circle",
                                color: .green
                            )
                            
                            // Weekly Goal
                            StatCard(
                                title: "Weekly Goal",
                                value: "\(weeklyGoalProgress)",
                                icon: "target",
                                color: .purple
                            )
                            
                            // Best Streak
                            StatCard(
                                title: "Best Streak",
                                value: "\(bestStreak)",
                                icon: "flame",
                                color: .orange
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 40)
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
        }
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

#Preview {
    ProfileView(habitStore: HabitStore())
}
