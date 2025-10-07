//
//  HabitCalendarView.swift
//  vibe 1
//
//  Created by Assistant on 10/5/25.
//

import SwiftUI
import UIKit

struct HabitCalendarView: View {
    let habit: Habit
    @ObservedObject var habitStore: HabitStore
    @Environment(\.dismiss) private var dismiss
    @State private var currentMonth: Date = Date()
    @State private var selectedTab: Tab = .calendar
    
    enum Tab { case calendar, agent }
    @State private var showingEdit = false

    // Use the same palette as the rest of the app
    private let habitColors: [Color] = [
        Color.pink, Color.blue, Color.orange, Color.purple, Color.green,
        Color.red, Color.yellow, Color.indigo, Color.mint, Color.teal,
        Color.cyan, Color.brown
    ]
    private var habitColor: Color { habitColors[habit.colorIndex % habitColors.count] }
    
    private var monthTitle: String {
        let f = DateFormatter()
        f.dateFormat = "LLLL yyyy"
        return f.string(from: currentMonth)
    }
    
    // Month grid with leading placeholders so days align to Monday-first week
    private var monthGrid: [Date?] {
        let cal = Calendar.current
        guard let range = cal.range(of: .day, in: .month, for: currentMonth),
              let first = cal.date(from: cal.dateComponents([.year, .month], from: currentMonth))
        else { return [] }
        let weekday = cal.component(.weekday, from: first) // 1=Sun ... 7=Sat
        let mondayFirstIndex = (weekday + 5) % 7 // 0=Mon ... 6=Sun
        var grid: [Date?] = Array(repeating: nil, count: mondayFirstIndex)
        for day in range {
            if let d = cal.date(byAdding: .day, value: day - 1, to: first) {
                grid.append(d)
            }
        }
        return grid
    }
    
    private func isCompleted(_ date: Date) -> Bool {
        habit.completedDates.contains(HabitStore.dateKey(date))
    }
    
    private func toggle(_ date: Date) {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        habitStore.toggleHabit(habit, on: date)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Top header with gradient, pill title, and circular edit
            ZStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(8)
                    }
                    Spacer()
                    Button(action: { showingEdit = true }) {
                        Image(systemName: "pencil")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.25))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 16)
                
                Text(habit.name)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.25))
                    .clipShape(Capsule())
            }
            .padding(.vertical, 12)
            .background(
                LinearGradient(gradient: Gradient(colors: [habitColor, habitColor.opacity(0.7)]), startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            
            // Tabs
            HStack {
                TabButton(title: "Calendar", isActive: selectedTab == .calendar) { selectedTab = .calendar }
                TabButton(title: "Agent", isActive: selectedTab == .agent) { selectedTab = .agent }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            
            if selectedTab == .calendar {
                // Calendar card container
                VStack(spacing: 16) {
                    VStack(spacing: 16) {
                        HStack {
                            Button(action: { currentMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth }) {
                                Image(systemName: "chevron.left")
                                    .foregroundColor(habitColor)
                                    .padding(8)
                            }
                            Spacer()
                            Text(monthTitle)
                                .font(.system(size: 22, weight: .bold))
                            Spacer()
                            Button(action: { currentMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth }) {
                                Image(systemName: "chevron.right")
                                    .foregroundColor(habitColor)
                                    .padding(8)
                            }
                        }
                        .padding(.horizontal, 8)
                        
                        // Weekday headers
                        HStack {
                            ForEach(["Mon","Tue","Wed","Thu","Fri","Sat","Sun"], id: \.self) { d in
                                Text(d)
                                    .frame(maxWidth: .infinity)
                                    .font(.system(size: 16, weight: .semibold))
                            }
                        }
                        
                        // Grid of days
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 7), spacing: 16) {
                            ForEach(Array(monthGrid.enumerated()), id: \.offset) { _, item in
                                if let date = item {
                                    DayCircle(
                                        date: date,
                                        isCompleted: isCompleted(date),
                                        isToday: Calendar.current.isDateInToday(date),
                                        color: habitColor,
                                        dayNumber: Calendar.current.component(.day, from: date)
                                    ) {
                                        toggle(date)
                                    }
                                } else {
                                    // Empty cell for days outside month
                                    Color.clear.frame(height: 36)
                                }
                            }
                        }
                        .padding(.horizontal, 6)
                        .padding(.bottom, 6)
                    }
                    .padding(16)
                    .background(Color(.systemBackground))
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 6)
                    .padding(.horizontal, 16)
                }
                .padding(.top, 8)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            } else {
                // Agent chat simple UI
                VStack(spacing: 12) {
                    HStack(alignment: .bottom, spacing: 12) {
                        Circle().fill(habitColor).frame(width: 28, height: 28)
                        Text("How can I help?")
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        Spacer()
                    }
                }
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingEdit) {
            EditHabitView(habit: habit, habitStore: habitStore)
        }
    }
}

private struct TabButton: View {
    let title: String
    let isActive: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(isActive ? .pink : .secondary)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(isActive ? Color.pink.opacity(0.1) : Color.clear)
                .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

private struct DayCircle: View {
    let date: Date
    let isCompleted: Bool
    let isToday: Bool
    let color: Color
    let dayNumber: Int
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(isCompleted ? color : Color(.systemGray6))
                    .frame(width: 36, height: 36)
                    .shadow(color: Color.black.opacity(0.08), radius: 2, x: 0, y: 1)
                if isToday && !isCompleted {
                    Circle()
                        .stroke(style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [4, 3]))
                        .fill(Color.clear)
                        .foregroundColor(color)
                        .frame(width: 34, height: 34)
                }
                if isCompleted {
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                        .font(.system(size: 14, weight: .bold))
                } else {
                    // Day number (condensed) lower-right
                    Text("\(dayNumber)")
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                        .frame(width: 36, height: 36, alignment: .bottomTrailing)
                        .padding(3)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    HabitCalendarView(habit: Habit(name: "Read", selectedDays: ["Monday"], timeOfDay: Date(), frequencyPerWeek: 3, commitmentLevel: 5), habitStore: HabitStore())
}


