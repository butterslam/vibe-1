// MARK: - Reminder UI Helpers (mirrors AddHabitView)
extension EditHabitView {
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
//
//  EditHabitView.swift
//  vibe 1
//
//  Created by Jamie Cheatham on 10/4/25.
//

import SwiftUI

struct EditHabitView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var habitStore: HabitStore
    let habit: Habit
    
    @State private var habitName = ""
    @State private var selectedTime = Date()
    @State private var selectedDays: Set<String> = []
    @State private var showingDeleteAlert = false
    @State private var selectedColorIndex = 0
    @State private var habitDescription: String = ""
    @State private var invitedAllies: [String] = []
    @State private var reminderEnabled: Bool = true
    @State private var showingReminderPicker = false
    @State private var hasSelectedReminder = false
    @State private var isReminderDisabled = false
    
    private let daysOfWeek = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    private let fullDaysOfWeek = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    
    private let habitColors: [Color] = [
        Color.pink, Color.blue, Color.orange, Color.purple, Color.green,
        Color.red, Color.yellow, Color.indigo, Color.mint, Color.teal,
        Color.cyan, Color.brown
    ]
    
    init(habit: Habit, habitStore: HabitStore) {
        self.habit = habit
        self.habitStore = habitStore
        
        // Initialize state with habit data
        _habitName = State(initialValue: habit.name)
        _selectedDays = State(initialValue: Set(habit.selectedDays))
        _selectedColorIndex = State(initialValue: habit.colorIndex)
        _habitDescription = State(initialValue: habit.descriptionText ?? "")
        _invitedAllies = State(initialValue: habit.invitedAllies ?? [])
        _reminderEnabled = State(initialValue: habit.reminderEnabled)
        _selectedTime = State(initialValue: habit.timeOfDay)
        _showingReminderPicker = State(initialValue: false)
        _hasSelectedReminder = State(initialValue: habit.reminderEnabled)
        _isReminderDisabled = State(initialValue: !habit.reminderEnabled)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    VStack(spacing: 32) {
                        // Header Section
                        VStack(spacing: 16) {
                            Text("Edit \"\(habit.name)\"")
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
                                    .toolbar {
                                        ToolbarItemGroup(placement: .keyboard) {
                                            Spacer()
                                            Button("Done") {
                                                hideKeyboard()
                                            }
                                        }
                                    }
                            }

                            // Allies Section
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Allies")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                VStack(alignment: .leading, spacing: 10) {
                                    AllyRow(username: currentUserDisplayName(), isPrimary: true)
                                    ForEach(invitedAllies, id: \.self) { name in
                                        AllyRow(username: name, isPrimary: false)
                                    }
                                }
                                .padding(12)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                            
                            // 2. Description
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Description")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                                TextEditor(text: $habitDescription)
                                    .frame(minHeight: 100)
                                    .padding(8)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                            }

                            // 3. Days of Week
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Days of Week")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                HStack(spacing: 8) {
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
                            }
                            
                            // 4. Reminder (same UI as Add Habit)
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

                            // 5. Habit Color
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
                            
                            // 6. Allies summary (read-only)
                            if !invitedAllies.isEmpty {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Allies")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text(invitedAllies.joined(separator: ", "))
                                        .foregroundColor(.secondary)
                                }
                            }

                            // 7. Save Changes Button
                            Button(action: saveChanges) {
                                Text("Save Changes")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(16)
                                    .shadow(
                                        color: Color.blue.opacity(0.3),
                                        radius: 8,
                                        x: 0,
                                        y: 4
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // 5. Delete Habit Button
                            Button(action: {
                                showingDeleteAlert = true
                            }) {
                                Text("Delete Habit")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.red)
                            }
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
        }
        .alert("Delete Habit", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteHabit()
            }
        } message: {
            Text("Are you sure you want to delete this habit? This action cannot be undone.")
        }
        .sheet(isPresented: $showingReminderPicker) {
            VStack(spacing: 16) {
                HStack {
                    Spacer()
                    Button(action: {
                        hasSelectedReminder = true
                        isReminderDisabled = false
                        reminderEnabled = true
                        // persist selectedTime on save
                        showingReminderPicker = false
                    }) {
                        Text("Set Reminder")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
                .padding(.horizontal)
                .padding(.top, 12)

                DatePicker("", selection: $selectedTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(WheelDatePickerStyle())
                    .labelsHidden()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Danger Zone")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.red)
                    Button(action: {
                        isReminderDisabled = true
                        hasSelectedReminder = false
                        reminderEnabled = false
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
    }
    
    private func toggleDay(_ day: String) {
        if selectedDays.contains(day) {
            selectedDays.remove(day)
        } else {
            selectedDays.insert(day)
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func saveChanges() {
        habitStore.updateHabit(
            habit,
            name: habitName,
            timeOfDay: selectedTime,
            selectedDays: Array(selectedDays),
            colorIndex: selectedColorIndex,
            descriptionText: habitDescription.isEmpty ? nil : habitDescription,
            invitedAllies: invitedAllies,
            reminderEnabled: reminderEnabled
        )
        dismiss()
    }
    
    private func deleteHabit() {
        if let index = habitStore.habits.firstIndex(where: { $0.id == habit.id }) {
            habitStore.deleteHabit(at: IndexSet(integer: index))
        }
        dismiss()
    }
}

private func currentUserDisplayName() -> String {
    // Placeholder for current user; replace with real profile name when available
    return "You"
}

struct AllyRow: View {
    let username: String
    let isPrimary: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            if isPrimary {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .foregroundColor(.blue)
                    .frame(width: 36, height: 36)
                    .background(Color.clear)
            } else {
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(initials(for: username))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.blue)
                    )
            }
            
            Text(username)
                .font(.system(size: 15, weight: isPrimary ? .semibold : .regular))
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
    
    private func initials(for name: String) -> String {
        let parts = name.split(separator: " ")
        let first = parts.first?.first.map(String.init) ?? ""
        let last = parts.dropFirst().first?.first.map(String.init) ?? ""
        return (first + last).uppercased()
    }
}

#Preview {
    EditHabitView(
        habit: Habit(
            name: "Morning Exercise",
            selectedDays: ["Monday", "Wednesday", "Friday"],
            timeOfDay: Date(),
            frequencyPerWeek: 3,
            commitmentLevel: 5
        ),
        habitStore: HabitStore()
    )
}
