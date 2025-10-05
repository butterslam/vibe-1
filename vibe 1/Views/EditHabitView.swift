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
    
    private let daysOfWeek = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    private let fullDaysOfWeek = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    
    init(habit: Habit, habitStore: HabitStore) {
        self.habit = habit
        self.habitStore = habitStore
        
        // Initialize state with habit data
        _habitName = State(initialValue: habit.name)
        _selectedTime = State(initialValue: habit.timeOfDay)
        _selectedDays = State(initialValue: Set(habit.selectedDays))
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
                            
                            // 2. Time of Day
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Time of Day")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                DatePicker("", selection: $selectedTime, displayedComponents: .hourAndMinute)
                                    .datePickerStyle(WheelDatePickerStyle())
                                    .labelsHidden()
                                    .frame(maxWidth: .infinity)
                                    .padding()
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
                            
                            // 4. Save Changes Button
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
        habitStore.updateHabit(habit, name: habitName, timeOfDay: selectedTime, selectedDays: Array(selectedDays))
        dismiss()
    }
    
    private func deleteHabit() {
        if let index = habitStore.habits.firstIndex(where: { $0.id == habit.id }) {
            habitStore.deleteHabit(at: IndexSet(integer: index))
        }
        dismiss()
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
