//
//  HabitStore.swift
//  vibe 1
//
//  Created by Jamie Cheatham on 10/4/25.
//

import Foundation
import EventKit

class HabitStore: ObservableObject {
    @Published var habits: [Habit] = []
    @Published var selectedDate: Date = Date()
    
    private let eventStore = EKEventStore()
     
    init() {
        loadHabits()
    }
    
    func addHabit(_ habit: Habit) {
        habits.append(habit)
        saveHabits()
        addToCalendar(habit)
        // Schedule notification for the new habit
        NotificationManager.shared.scheduleNotification(for: habit)
    }
    
    func deleteHabit(at indexSet: IndexSet) {
        // Remove notifications for deleted habits
        for index in indexSet {
            if index < habits.count {
                NotificationManager.shared.removeNotifications(for: habits[index])
            }
        }
        
        habits.remove(atOffsets: indexSet)
        saveHabits()
    }
    
    func updateHabit(_ habit: Habit, name: String, timeOfDay: Date, selectedDays: [String], colorIndex: Int, descriptionText: String?, invitedAllies: [String]?, reminderEnabled: Bool) {
        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            habits[index].name = name
            habits[index].timeOfDay = timeOfDay
            habits[index].selectedDays = selectedDays
            habits[index].frequencyPerWeek = selectedDays.count
            habits[index].colorIndex = colorIndex
            habits[index].descriptionText = descriptionText
            habits[index].invitedAllies = invitedAllies
            habits[index].reminderEnabled = reminderEnabled
            saveHabits()
            
            // Reschedule notification for the updated habit
            NotificationManager.shared.scheduleNotification(for: habits[index])
        }
    }
    
    func toggleHabitCompletion(_ habit: Habit) {
        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            habits[index].isCompletedToday.toggle()
            let todayKey = Self.dateKey(Date())
            if habits[index].isCompletedToday {
                habits[index].completedDate = Date()
                habits[index].completedDates.insert(todayKey)
            } else {
                habits[index].completedDate = nil
                habits[index].completedDates.remove(todayKey)
            }
            saveHabits()
        }
    }

    // Toggle completion for a specific day (used by calendar UI)
    func toggleHabit(_ habit: Habit, on date: Date) {
        guard let index = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        let key = Self.dateKey(date)
        if habits[index].completedDates.contains(key) {
            habits[index].completedDates.remove(key)
        } else {
            habits[index].completedDates.insert(key)
        }
        // Update today convenience flags
        let todayKey = Self.dateKey(Date())
        habits[index].isCompletedToday = habits[index].completedDates.contains(todayKey)
        habits[index].completedDate = habits[index].isCompletedToday ? Date() : nil
        saveHabits()
    }

    static func dateKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    private func saveHabits() {
        if let encoded = try? JSONEncoder().encode(habits) {
            UserDefaults.standard.set(encoded, forKey: "SavedHabits")
        }
    }
    
    private func loadHabits() {
        if let data = UserDefaults.standard.data(forKey: "SavedHabits"),
           let decoded = try? JSONDecoder().decode([Habit].self, from: data) {
            habits = decoded
        }
    }
    
    private func addToCalendar(_ habit: Habit) {
        if #available(iOS 17.0, *) {
            eventStore.requestFullAccessToEvents { [weak self] granted, error in
                guard granted, error == nil else { return }
                
                DispatchQueue.main.async {
                    self?.createCalendarEvent(for: habit)
                }
            }
        } else {
            eventStore.requestAccess(to: .event) { [weak self] granted, error in
                guard granted, error == nil else { return }
                
                DispatchQueue.main.async {
                    self?.createCalendarEvent(for: habit)
                }
            }
        }
    }
    
    private func createCalendarEvent(for habit: Habit) {
        // Create events for each selected day
        for day in habit.selectedDays {
            let event = EKEvent(eventStore: eventStore)
            event.title = habit.name
            event.notes = "Frequency: \(habit.frequencyPerWeek) times per week\nCommitment: \(habit.commitmentLevel)/10"
            
            // Set start time based on habit's time
            let timeComponents = Calendar.current.dateComponents([.hour, .minute], from: habit.timeOfDay)
            var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: selectedDate)
            dateComponents.hour = timeComponents.hour
            dateComponents.minute = timeComponents.minute
            
            if let startDate = Calendar.current.date(from: dateComponents) {
                event.startDate = startDate
                event.endDate = Calendar.current.date(byAdding: .hour, value: 1, to: startDate) ?? startDate
            }
            
            // Create recurring event for this specific day
            let recurrenceRule = EKRecurrenceRule(
                recurrenceWith: .weekly,
                interval: 1,
                daysOfTheWeek: [EKRecurrenceDayOfWeek(dayOfTheWeek: getDayOfWeek(day), weekNumber: 0)],
                daysOfTheMonth: nil,
                monthsOfTheYear: nil,
                weeksOfTheYear: nil,
                daysOfTheYear: nil,
                setPositions: nil,
                end: nil
            )
            
            event.recurrenceRules = [recurrenceRule]
            event.calendar = eventStore.defaultCalendarForNewEvents
            
            do {
                try eventStore.save(event, span: .futureEvents)
            } catch {
                print("Failed to save event: \(error)")
            }
        }
    }
    
    private func getDayOfWeek(_ day: String) -> EKWeekday {
        switch day {
        case "Monday": return .monday
        case "Tuesday": return .tuesday
        case "Wednesday": return .wednesday
        case "Thursday": return .thursday
        case "Friday": return .friday
        case "Saturday": return .saturday
        case "Sunday": return .sunday
        default: return .monday
        }
    }
}
