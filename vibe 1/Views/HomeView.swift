//
//  HomeView.swift
//  vibe 1
//
//  Created by Jamie Cheatham on 10/4/25.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var habitStore: HabitStore
    @EnvironmentObject var notificationStore: NotificationStore
    @State private var showingAddHabit = false
    @State private var showingCompletedSheet = false
    @State private var showingNotifications = false
    
    var weekProgress: [Double] {
        calculateWeekProgress()
    }
    
    var todayProgress: String {
        let todayHabits = getTodayHabits()
        let completedToday = todayHabits.filter { $0.isCompletedToday }.count
        return "\(completedToday)/\(todayHabits.count)"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Top overlay actions (bell right)
                    HStack {
                        Spacer()
                        Button(action: { showingNotifications = true }) {
                            ZStack {
                                Image(systemName: "bell")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.primary)
                                    .frame(width: 36, height: 36)
                                    .background(Color(.systemGray6))
                                    .clipShape(Circle())
                                
                                if notificationStore.unreadCount > 0 {
                                    Text("\(notificationStore.unreadCount)")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 16, height: 16)
                                        .background(Color.red)
                                        .clipShape(Circle())
                                        .offset(x: 12, y: -12)
                                }
                            }
                        }
                        .padding(.trailing, 20)
                    }
                    .padding(.top, 0)
                    
                    // This week section
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("This week")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.primary)
                                
                                Text("• \(habitStore.habits.count) active habits")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        
                        // Week progress circles
                        HStack(spacing: 12) {
                            ForEach(0..<7) { index in
                                WeekDayCircle(
                                    day: getDayInitial(for: index),
                                    progress: weekProgress[index],
                                    isToday: isToday(index: index)
                                )
                            }
                        }
                    }
                    .padding(.bottom, 30)
                    .padding(.horizontal, 20)
                    .padding(.top, 0)
                    
                    // Today section
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Today, \(getTodayDate())")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.primary)
                                
                                Text("• \(todayProgress) done")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            HStack(spacing: 12) {
                                // Move clock to former plus spot
                                Button(action: {
                                    showingCompletedSheet = true
                                }) {
                                    Image(systemName: "clock")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.secondary)
                                        .frame(width: 32, height: 32)
                                        .background(Color(.systemGray6))
                                        .clipShape(Circle())
                                }
                            }
                        }
                        
                        // Habit cards (Today only)
                        let scheduledToday = habitsFor(Date())
                        let todays = scheduledToday.filter { !$0.isCompletedToday }
                        if todays.isEmpty {
                            VStack(spacing: 12) {
                                Text("🔥 You're all done!")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.orange)
                                if scheduledToday.isEmpty {
                                    Text("No habits scheduled for today")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                                if !scheduledToday.isEmpty {
                                    Button(action: { showingCompletedSheet = true }) {
                                        Text("View Completed Habits")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(Color.orange)
                                            .cornerRadius(12)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(todays) { habit in
                                    HabitCardView(habit: habit, habitStore: habitStore, completionDisabled: false)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 50)

                // Future timeline (next 6 days)
                VStack(spacing: 20) {
                    ForEach(1...6, id: \.self) { offset in
                        let date = Calendar.current.date(byAdding: .day, value: offset, to: Date()) ?? Date()
                        let list = habitsFor(date)
                        if !list.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text(sectionTitle(for: date, offset: offset))
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.primary)
                                LazyVStack(spacing: 12) {
                                    ForEach(list) { habit in
                                        HabitCardView(habit: habit, habitStore: habitStore, completionDisabled: true)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                }
                .padding(.bottom, 40)
            }
            .navigationBarHidden(true)
        }
        .overlay(alignment: .bottomTrailing) {
            Button(action: { showingAddHabit = true }) {
                Image(systemName: "plus")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(
                        LinearGradient(gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.85)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.5), radius: 8, x: 0, y: 4)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 28)
            .zIndex(10)
        }
        .sheet(isPresented: $showingAddHabit) { AddHabitView(habitStore: habitStore) }
        .sheet(isPresented: $showingCompletedSheet) {
            let scheduled = habitsFor(Date())
            let completed = scheduled.filter { $0.isCompletedToday }
            CompletedHabitsSheet(habitStore: habitStore, habits: completed)
        }
        .sheet(isPresented: $showingNotifications) {
            NotificationsView(notificationStore: notificationStore, habitStore: habitStore)
        }
    }
    
    private func getTodayHabits() -> [Habit] {
        let today = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        let todayName = formatter.string(from: today)
        
        return habitStore.habits.filter { habit in
            habit.selectedDays.contains(todayName)
        }
    }

    private func habitsFor(_ date: Date) -> [Habit] {
        let f = DateFormatter()
        f.dateFormat = "EEEE"
        let name = f.string(from: date)
        return habitStore.habits.filter { $0.selectedDays.contains(name) }
    }

    private func sectionTitle(for date: Date, offset: Int) -> String {
        let df = DateFormatter()
        if offset == 1 {
            df.dateFormat = "MMM d"
            return "Tomorrow, \(df.string(from: date))"
        } else {
            df.dateFormat = "EEEE, MMM d"
            return df.string(from: date)
        }
    }
    
    private func calculateWeekProgress() -> [Double] {
        let calendar = Calendar.current
        let today = Date()
        var progress: [Double] = []
        
        // Find Monday of the current week (0=Mon..6=Sun)
        let weekday = calendar.component(.weekday, from: today) // 1=Sun..7=Sat
        let daysFromMonday = (weekday + 5) % 7
        guard let monday = calendar.date(byAdding: .day, value: -daysFromMonday, to: today) else {
            return Array(repeating: 0, count: 7)
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        
        for i in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: i, to: monday) else {
                progress.append(0)
                continue
            }
            let dayName = formatter.string(from: date)
            let dayHabits = habitStore.habits.filter { $0.selectedDays.contains(dayName) }
            if dayHabits.isEmpty {
                progress.append(0)
            } else {
                let completedCount = dayHabits.filter { habit in
                    if let completedDate = habit.completedDate {
                        return calendar.isDate(completedDate, inSameDayAs: date)
                    }
                    return false
                }.count
                progress.append(Double(completedCount) / Double(dayHabits.count))
            }
        }
        
        return progress
    }
    
    private func getDayInitial(for index: Int) -> String {
        // 0=Mon..6=Sun
        let days = ["M", "T", "W", "T", "F", "S", "S"]
        return days[index]
    }
    
    private func isToday(index: Int) -> Bool {
        return index == todayIndexMondayFirst()
    }

    private func todayIndexMondayFirst() -> Int {
        // Resolve today by day name to avoid locale/first-weekday confusion
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEEE" // Monday, Tuesday, ...
        let name = formatter.string(from: Date())
        let order = ["Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"]
        return order.firstIndex(of: name) ?? 0
    }
    
    private func getTodayDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: Date())
    }
}

struct WeekDayCircle: View {
    let day: String
    let progress: Double
    let isToday: Bool
    
    var body: some View {
        let size: CGFloat = isToday ? 52 : 40
        let ringWidth: CGFloat = isToday ? 5 : 3
        ZStack {
            // Background circle
            Circle()
                .stroke(Color(.systemGray4), lineWidth: 2)
                .frame(width: size, height: size)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: ringWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: progress)
            
            // Day letter
            Text(day)
                .font(.system(size: isToday ? 17 : 14, weight: .semibold))
                .foregroundColor(isToday ? .blue : .secondary)
        }
        .shadow(color: isToday ? Color.black.opacity(0.25) : Color.clear, radius: isToday ? 6 : 0, x: 0, y: isToday ? 3 : 0)
    }
}

struct HabitCardView: View {
    let habit: Habit
    let habitStore: HabitStore
    var completionDisabled: Bool = false
    @State private var showingEditSheet = false
    @State private var showingCalendar = false
    @State private var dragOffset: CGFloat = 0
    @State private var isEditRevealed = false
    @State private var editHighlight: Double = 0 // 0..1 for color transition
    @State private var isCompleteRevealed = false
    @State private var completeHighlight: Double = 0 // 0..1 for color transition
    @State private var isHorizontalDrag = false
    
    private let habitColors: [Color] = [
        Color.pink, Color.blue, Color.orange, Color.purple, Color.green,
        Color.red, Color.yellow, Color.indigo, Color.mint, Color.teal,
        Color.cyan, Color.brown
    ]
    
    private var habitColor: Color {
        return habitColors[habit.colorIndex % habitColors.count]
    }
    
    private var completionCount: Int {
        // Calculate completion count based on completedDate
        if let completedDate = habit.completedDate {
            let calendar = Calendar.current
            let daysSinceCompletion = calendar.dateComponents([.day], from: completedDate, to: Date()).day ?? 0
            return max(0, habit.frequencyPerWeek - daysSinceCompletion)
        }
        return 0
    }
    
    var body: some View {
        ZStack {
            // Complete button background (revealed on right swipe)
            HStack {
                Button(action: {
                    if !habit.isCompletedToday {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        habitStore.toggleHabitCompletion(habit)
                    }
                }) {
                    Text("Done")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 90, height: 60)
                        .background(
                            Color(hue: 0.33, saturation: 0.3 + 0.7 * completeHighlight, brightness: 0.95 - 0.15 * completeHighlight)
                        )
                        .cornerRadius(12)
                }
                .opacity(isCompleteRevealed && !completionDisabled ? 1 : 0)
                Spacer()
            }

            // Edit button background (revealed on swipe left)
            HStack {
                Spacer()
                Button(action: {
                    showingEditSheet = true
                }) {
                    Text("Edit")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 80, height: 60)
                        .background(
                            Color(hue: 0.0, saturation: 0.3 + 0.7 * editHighlight, brightness: 1.0 - 0.2 * editHighlight)
                        )
                        .cornerRadius(12)
                }
                .opacity(isEditRevealed ? 1 : 0)
            }
            
            // Main card content
            HStack(spacing: 16) {
                // Colored bar
                Rectangle()
                    .fill(habitColor)
                    .frame(width: 4)
                    .cornerRadius(2)
                
                VStack(alignment: .leading, spacing: 8) {
                    // Habit name
                    Text(habit.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    // Day indicators
                    HStack(spacing: 4) {
                        ForEach(0..<7) { index in
                            DayIndicator(
                                day: getDayInitial(for: index),
                                isSelected: habit.selectedDays.contains(getFullDayName(for: index)),
                                isCompleted: isDayCompleted(index: index),
                                color: habitColor
                            )
                        }
                    }
                }
                
                Spacer()
                
                // Completion indicator
                HStack(spacing: 4) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(habitColor)
                    
                    Text("\(completionCount)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray5), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            .offset(x: dragOffset)
            .opacity(completionDisabled ? 0.6 : 1.0)
            .onTapGesture {
                showingCalendar = true
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 18)
                    .onChanged { value in
                        // Only react to mostly-horizontal gestures
                        let t = value.translation.width
                        let v = value.translation.height
                        let threshold: CGFloat = 18
                        if !isHorizontalDrag {
                            if abs(t) > threshold && abs(t) > abs(v) + 10 { // decide horizontal intent
                                isHorizontalDrag = true
                            } else {
                                // ignore vertical scrolls
                                return
                            }
                        }
                        if t < 0 { // left: edit
                            let h = max(0, min(-t - threshold, 100)) // horizontal progress beyond threshold
                            dragOffset = -h
                            let reveal = min(max(h / 100, 0), 1)
                            isEditRevealed = reveal > 0
                            editHighlight = reveal
                            // hide complete side
                            isCompleteRevealed = false
                            completeHighlight = 0
                        } else if t > 0 { // right: complete
                            if completionDisabled {
                                // allow tiny nudge and spring back
                                let h = max(0, min(t - threshold, 18))
                                dragOffset = h
                                isCompleteRevealed = false
                                completeHighlight = 0
                            } else {
                                let h = max(0, min(t - threshold, 100))
                                dragOffset = h
                                let reveal = min(max(h / 100, 0), 1)
                                isCompleteRevealed = reveal > 0
                                completeHighlight = reveal
                            }
                            // hide edit side
                            isEditRevealed = false
                            editHighlight = 0
                        } else {
                            dragOffset = 0
                            isEditRevealed = false
                            editHighlight = 0
                            isCompleteRevealed = false
                            completeHighlight = 0
                        }
                    }
                    .onEnded { value in
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                            if -dragOffset > 70 { // commit edit
                                // commit edit
                                dragOffset = -100
                                isEditRevealed = true
                                editHighlight = 1
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                showingEditSheet = true
                                // reset after opening
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    dragOffset = 0
                                    isEditRevealed = false
                                    editHighlight = 0
                                    isCompleteRevealed = false
                                    completeHighlight = 0
                                }
                            } else if dragOffset > 70 && !completionDisabled { // commit complete
                                dragOffset = 100
                                isCompleteRevealed = true
                                completeHighlight = 1
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                if !habit.isCompletedToday {
                                    habitStore.toggleHabitCompletion(habit)
                                }
                                // slide off to right quickly
                                withAnimation(.easeIn(duration: 0.15)) {
                                    dragOffset = UIScreen.main.bounds.width
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                    dragOffset = 0
                                    isCompleteRevealed = false
                                    completeHighlight = 0
                                    isEditRevealed = false
                                    editHighlight = 0
                                }
                            } else {
                                dragOffset = 0
                                isEditRevealed = false
                                editHighlight = 0
                                isCompleteRevealed = false
                                completeHighlight = 0
                            }
                            isHorizontalDrag = false
                        }
                    }
            )
        }
        .sheet(isPresented: $showingEditSheet) {
            EditHabitView(habit: habit, habitStore: habitStore)
        }
        .sheet(isPresented: $showingCalendar) {
            HabitCalendarView(habit: habit, habitStore: habitStore)
        }
    }
    
    private func getDayInitial(for index: Int) -> String {
        let days = ["M", "T", "W", "T", "F", "S", "S"]
        return days[index]
    }
    
    private func getFullDayName(for index: Int) -> String {
        let days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        return days[index]
    }
    
    private func todayIndexMondayFirst() -> Int {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEEE"
        let name = formatter.string(from: Date())
        let order = ["Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"]
        return order.firstIndex(of: name) ?? 0
    }
    
    private func isDayCompleted(index: Int) -> Bool {
        // Show completion if this index corresponds to the date in completedDate
        guard let completedDate = habit.completedDate else { return false }
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        let completedName = formatter.string(from: completedDate)
        let order = ["Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"]
        let completedIndex = order.firstIndex(of: completedName) ?? todayIndexMondayFirst()
        return index == completedIndex && calendar.isDateInToday(completedDate)
    }
}

struct DayIndicator: View {
    let day: String
    let isSelected: Bool
    let isCompleted: Bool
    let color: Color
    
    var body: some View {
        ZStack {
            Circle()
                .fill(isCompleted ? color : (isSelected ? Color(.systemGray5) : Color.clear))
                .frame(width: 24, height: 24)
            
            if isCompleted {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
            } else {
                Text(day)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(isSelected ? .secondary : Color(.systemGray4))
            }
        }
    }
}

// MARK: - Completed Habits Sheet

struct CompletedHabitsSheet: View {
    @ObservedObject var habitStore: HabitStore
    var habits: [Habit]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 12) {
                    if habits.isEmpty {
                        Text("No completed habits today")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(.top, 20)
                    } else {
                        ForEach(habits) { habit in
                            CompletedHabitCard(habit: habit, habitStore: habitStore)
                        }
                    }
                }
                .padding(16)
            }
            .navigationTitle("Completed Today")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
        }
    }
}

struct CompletedHabitCard: View {
    let habit: Habit
    @ObservedObject var habitStore: HabitStore
    
    private let habitColors: [Color] = [
        Color.pink, Color.blue, Color.orange, Color.purple, Color.green,
        Color.red, Color.yellow, Color.indigo, Color.mint, Color.teal,
        Color.cyan, Color.brown
    ]
    private var habitColor: Color { habitColors[habit.colorIndex % habitColors.count] }
    
    var body: some View {
        HStack(spacing: 16) {
            Rectangle()
                .fill(habitColor)
                .frame(width: 4)
                .cornerRadius(2)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(habit.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                // Selected days display (no interaction)
                HStack(spacing: 4) {
                    ForEach(["M","T","W","T","F","S","S"], id: \.self) { d in
                        Circle()
                            .fill(Color(.systemGray6))
                            .frame(width: 24, height: 24)
                            .overlay(Text(d).font(.system(size: 10, weight: .semibold)).foregroundColor(.secondary))
                    }
                }
            }
            Spacer()
            Button(action: {
                // Undo completion: mark as not completed today and return to Home
                if habit.isCompletedToday {
                    habitStore.toggleHabitCompletion(habit)
                }
            }) {
                Text("Undo")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray5))
                    .cornerRadius(10)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    HomeView(habitStore: HabitStore())
}
