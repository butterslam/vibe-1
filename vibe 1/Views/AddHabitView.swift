//
//  AddHabitView.swift
//  vibe 1
//
//  Created by Jamie Cheatham on 10/4/25.
//

import SwiftUI

struct AddHabitView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var habitStore: HabitStore
    
    @State private var habitName = ""
    @State private var selectedTime = Date()
    @State private var selectedDays: Set<String> = []
    @State private var showingConfetti = false
    @State private var errorMessage = ""
    
    private let daysOfWeek = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    private let fullDaysOfWeek = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    
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
        
        let newHabit = Habit(
            name: habitName,
            selectedDays: Array(selectedDays),
            timeOfDay: selectedTime,
            frequencyPerWeek: selectedDays.count,
            commitmentLevel: 5 // Default commitment level
        )
        
        habitStore.addHabit(newHabit)
        
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
                .frame(width: 40, height: 40)
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
        .onChange(of: isActive) { active in
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

#Preview {
    AddHabitView(habitStore: HabitStore())
}
