//
//  HabitStore.swift
//  vibe 1
//
//  Created by Jamie Cheatham on 10/4/25.
//

import Foundation
import EventKit
import FirebaseAuth
import FirebaseFirestore

class HabitStore: ObservableObject {
    @Published var habits: [Habit] = []
    @Published var selectedDate: Date = Date()
    
    private let eventStore = EKEventStore()
    private let db = Firestore.firestore()
    private var habitsListener: ListenerRegistration?
    
    init() {
        // Load habits when user changes
        setupAuthListener()
    }
    
    deinit {
        habitsListener?.remove()
    }
    
    func addHabit(_ habit: Habit) {
        guard let currentUser = Auth.auth().currentUser else {
            print("No authenticated user to save habit")
            return
        }
        
        // Ensure habit has the current user's ID
        var habitWithUser = habit
        habitWithUser.createdByUserId = currentUser.uid
        
        // Save to Firebase
        Task {
            do {
                try await saveHabitToFirebase(habitWithUser)
                await MainActor.run {
                    habits.append(habitWithUser)
                    addToCalendar(habitWithUser)
                }
            } catch {
                print("Error saving habit to Firebase: \(error.localizedDescription)")
            }
        }
    }
    
    func deleteHabit(at indexSet: IndexSet) {
        guard let currentUser = Auth.auth().currentUser else { return }
        
        for index in indexSet {
            if index < habits.count {
                let habit = habits[index]
                // Only allow deletion of habits created by current user
                if habit.createdByUserId == currentUser.uid {
                    Task {
                        do {
                            try await deleteHabitFromFirebase(habit)
                            await MainActor.run {
                                habits.remove(at: index)
                            }
                        } catch {
                            print("Error deleting habit from Firebase: \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
    }
    
    func updateHabit(_ habit: Habit, name: String, timeOfDay: Date, selectedDays: [String], colorIndex: Int, descriptionText: String?, invitedAllies: [String]?, reminderEnabled: Bool) {
        guard let currentUser = Auth.auth().currentUser,
              let index = habits.firstIndex(where: { $0.id == habit.id }),
              habits[index].createdByUserId == currentUser.uid else { return }
        
        habits[index].name = name
        habits[index].timeOfDay = timeOfDay
        habits[index].selectedDays = selectedDays
        habits[index].frequencyPerWeek = selectedDays.count
        habits[index].colorIndex = colorIndex
        habits[index].descriptionText = descriptionText
        habits[index].invitedAllies = invitedAllies
        habits[index].reminderEnabled = reminderEnabled
        
        // Save to Firebase
        Task {
            do {
                try await updateHabitInFirebase(habits[index])
            } catch {
                print("Error updating habit in Firebase: \(error.localizedDescription)")
            }
        }
    }
    
    func toggleHabitCompletion(_ habit: Habit) {
        guard let currentUser = Auth.auth().currentUser,
              let index = habits.firstIndex(where: { $0.id == habit.id }),
              habits[index].createdByUserId == currentUser.uid else { return }
        
        let wasCompleted = habits[index].isCompletedToday
        habits[index].isCompletedToday.toggle()
        let todayKey = Self.dateKey(Date())
        if habits[index].isCompletedToday {
            habits[index].completedDate = Date()
            habits[index].completedDates.insert(todayKey)
        } else {
            habits[index].completedDate = nil
            habits[index].completedDates.remove(todayKey)
        }
        
        // Save to Firebase
        Task {
            do {
                try await updateHabitInFirebase(habits[index])
                
                // Send completion notification to allies if habit was just completed
                if habits[index].isCompletedToday && !wasCompleted {
                    await sendHabitCompletionNotifications(for: habits[index])
                }
            } catch {
                print("Error updating habit completion in Firebase: \(error.localizedDescription)")
            }
        }
    }

    // Toggle completion for a specific day (used by calendar UI)
    func toggleHabit(_ habit: Habit, on date: Date) {
        guard let currentUser = Auth.auth().currentUser,
              let index = habits.firstIndex(where: { $0.id == habit.id }),
              habits[index].createdByUserId == currentUser.uid else { return }
        
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
        
        // Save to Firebase
        Task {
            do {
                try await updateHabitInFirebase(habits[index])
            } catch {
                print("Error updating habit completion in Firebase: \(error.localizedDescription)")
            }
        }
    }

    static func dateKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    // MARK: - Firebase Methods
    
    private func setupAuthListener() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            if let user = user {
                self?.loadHabitsFromFirebase(for: user.uid)
            } else {
                self?.clearHabits()
            }
        }
    }
    
    private func clearHabits() {
        habitsListener?.remove()
        habits = []
    }
    
    private func loadHabitsFromFirebase(for userId: String) {
        habitsListener?.remove()
        
        habitsListener = db.collection("habits")
            .whereField("createdByUserId", isEqualTo: userId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error loading habits: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.habits = []
                    return
                }
                
                self.habits = documents.compactMap { document in
                    try? document.data(as: Habit.self)
                }
            }
    }
    
    private func saveHabitToFirebase(_ habit: Habit) async throws {
        guard let currentUser = Auth.auth().currentUser else {
            throw NSError(domain: "HabitStore", code: 1, userInfo: [NSLocalizedDescriptionKey: "No authenticated user"])
        }
        
        let habitData: [String: Any] = [
            "id": habit.id.uuidString,
            "name": habit.name,
            "selectedDays": habit.selectedDays,
            "timeOfDay": habit.timeOfDay,
            "frequencyPerWeek": habit.frequencyPerWeek,
            "commitmentLevel": habit.commitmentLevel,
            "createdAt": habit.createdAt,
            "isCompletedToday": habit.isCompletedToday,
            "completedDate": habit.completedDate as Any,
            "colorIndex": habit.colorIndex,
            "completedDates": Array(habit.completedDates),
            "descriptionText": habit.descriptionText as Any,
            "invitedAllies": habit.invitedAllies as Any,
            "reminderEnabled": habit.reminderEnabled,
            "createdByUserId": currentUser.uid
        ]
        
        try await db.collection("habits").document(habit.id.uuidString).setData(habitData)
    }
    
    private func updateHabitInFirebase(_ habit: Habit) async throws {
        let habitData: [String: Any] = [
            "name": habit.name,
            "selectedDays": habit.selectedDays,
            "timeOfDay": habit.timeOfDay,
            "frequencyPerWeek": habit.frequencyPerWeek,
            "commitmentLevel": habit.commitmentLevel,
            "isCompletedToday": habit.isCompletedToday,
            "completedDate": habit.completedDate as Any,
            "colorIndex": habit.colorIndex,
            "completedDates": Array(habit.completedDates),
            "descriptionText": habit.descriptionText as Any,
            "invitedAllies": habit.invitedAllies as Any,
            "reminderEnabled": habit.reminderEnabled
        ]
        
        try await db.collection("habits").document(habit.id.uuidString).updateData(habitData)
    }
    
    private func deleteHabitFromFirebase(_ habit: Habit) async throws {
        try await db.collection("habits").document(habit.id.uuidString).delete()
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
    
    private func sendHabitCompletionNotifications(for habit: Habit) async {
        guard let currentUser = Auth.auth().currentUser else { return }
        
        // Get allies for the current user
        let alliesQuery = db.collection("allies")
            .whereField("userId", isEqualTo: currentUser.uid)
        
        do {
            let alliesSnapshot = try await alliesQuery.getDocuments()
            
            for allyDoc in alliesSnapshot.documents {
                guard let allyId = allyDoc.data()["allyId"] as? String else { continue }
                
                // Create notification directly in Firebase instead of using NotificationStore
                await sendHabitCompletedNotificationDirectly(
                    habitName: habit.name,
                    toUserId: allyId,
                    habitId: habit.id.uuidString,
                    senderUserId: currentUser.uid
                )
            }
        } catch {
            print("Error sending habit completion notifications: \(error.localizedDescription)")
        }
    }
    
    private func sendHabitCompletedNotificationDirectly(
        habitName: String,
        toUserId: String,
        habitId: String,
        senderUserId: String
    ) async {
        do {
            // Get sender's profile info
            let userDoc = try await db.collection("users").document(senderUserId).getDocument()
            guard let userData = userDoc.data(),
                  let username = userData["username"] as? String else { return }
            
            let avatarURL = userData["avatarURL"] as? String
            
            // Create notification
            let notification = AppNotification(
                type: .habitCompleted,
                title: "Habit Completed! 🎉",
                message: "\(username) completed their habit: \(habitName)",
                recipientUserId: toUserId,
                senderUserId: senderUserId,
                senderUsername: username,
                senderAvatarURL: avatarURL,
                isRead: false,
                actionType: .viewHabit,
                actionData: ["habitId": habitId],
                habitId: habitId,
                allyId: nil,
                guildId: nil
            )
            
            // Save to Firebase
            try await db.collection("notifications").addDocument(data: [
                "type": notification.type.rawValue,
                "title": notification.title,
                "message": notification.message,
                "recipientUserId": notification.recipientUserId,
                "senderUserId": notification.senderUserId,
                "senderUsername": notification.senderUsername,
                "senderAvatarURL": notification.senderAvatarURL as Any,
                "isRead": notification.isRead,
                "actionType": notification.actionType?.rawValue as Any,
                "actionData": notification.actionData as Any,
                "habitId": notification.habitId as Any,
                "allyId": notification.allyId as Any,
                "guildId": notification.guildId as Any,
                "timestamp": notification.timestamp
            ])
            
        } catch {
            print("Error sending habit completion notification: \(error.localizedDescription)")
        }
    }
}
