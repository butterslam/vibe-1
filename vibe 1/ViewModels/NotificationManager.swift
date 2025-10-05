//
//  NotificationManager.swift
//  vibe 1
//
//  Created by Jamie Cheatham on 10/4/25.
//

import Foundation
import UserNotifications

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    private init() {}
    
    // Request notification permission
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Error requesting notification permission: \(error.localizedDescription)")
            }
        }
    }
    
    // Schedule notification for a habit
    func scheduleNotification(for habit: Habit) {
        // Remove existing notifications for this habit
        removeNotifications(for: habit)
        
        // Schedule new notifications for each selected day
        for day in habit.selectedDays {
            guard let weekday = getWeekdayNumber(from: day) else { continue }
            
            // Create notification content
            let content = UNMutableNotificationContent()
            content.title = "Time for \(habit.name)!"
            content.body = "Your habit is starting in 5 minutes"
            content.sound = .default
            content.badge = 1
            
            // Calculate notification time (5 minutes before habit time)
            let calendar = Calendar.current
            let habitComponents = calendar.dateComponents([.hour, .minute], from: habit.timeOfDay)
            
            var dateComponents = DateComponents()
            dateComponents.weekday = weekday
            dateComponents.hour = habitComponents.hour
            dateComponents.minute = habitComponents.minute
            
            // Subtract 5 minutes
            if let notificationDate = calendar.date(from: dateComponents),
               let adjustedDate = calendar.date(byAdding: .minute, value: -5, to: notificationDate) {
                let adjustedComponents = calendar.dateComponents([.weekday, .hour, .minute], from: adjustedDate)
                
                // Create trigger
                let trigger = UNCalendarNotificationTrigger(dateMatching: adjustedComponents, repeats: true)
                
                // Create request with unique identifier
                let identifier = "\(habit.id.uuidString)-\(day)"
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                
                // Schedule notification
                UNUserNotificationCenter.current().add(request) { error in
                    if let error = error {
                        print("Error scheduling notification: \(error.localizedDescription)")
                    } else {
                        print("Notification scheduled for \(habit.name) on \(day)")
                    }
                }
            }
        }
    }
    
    // Remove notifications for a specific habit
    func removeNotifications(for habit: Habit) {
        let identifiers = habit.selectedDays.map { "\(habit.id.uuidString)-\($0)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
    // Remove all notifications
    func removeAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    // Reschedule all notifications for all habits
    func rescheduleAllNotifications(for habits: [Habit]) {
        removeAllNotifications()
        for habit in habits {
            scheduleNotification(for: habit)
        }
    }
    
    // Convert day name to weekday number (1 = Sunday, 2 = Monday, etc.)
    private func getWeekdayNumber(from day: String) -> Int? {
        switch day {
        case "Sunday": return 1
        case "Monday": return 2
        case "Tuesday": return 3
        case "Wednesday": return 4
        case "Thursday": return 5
        case "Friday": return 6
        case "Saturday": return 7
        default: return nil
        }
    }
}
