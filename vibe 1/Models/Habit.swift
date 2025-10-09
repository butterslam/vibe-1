//
//  Habit.swift
//  vibe 1
//
//  Created by Jamie Cheatham on 10/4/25.
//

import Foundation

struct Habit: Identifiable, Codable {
    let id: UUID
    var name: String
    var selectedDays: [String] // Array of selected days
    var timeOfDay: Date // Time when the habit should be done
    var frequencyPerWeek: Int
    var commitmentLevel: Int
    var createdAt: Date
    var isCompletedToday: Bool = false
    var completedDate: Date?
    var colorIndex: Int = 0 // Index for habit color
    // New per-day completion tracking (keys formatted as yyyy-MM-dd in current calendar)
    var completedDates: Set<String> = []
    // New fields
    var descriptionText: String? = nil
    var invitedAllies: [String]? = []
    var reminderEnabled: Bool = true
    // Creator of this habit (Firebase uid)
    var createdByUserId: String? = nil
    
    init(name: String, selectedDays: [String], timeOfDay: Date, frequencyPerWeek: Int, commitmentLevel: Int, colorIndex: Int = 0, completedDates: Set<String> = [], descriptionText: String? = nil, invitedAllies: [String]? = [], reminderEnabled: Bool = true, createdByUserId: String? = nil) {
        self.id = UUID()
        self.name = name
        self.selectedDays = selectedDays
        self.timeOfDay = timeOfDay
        self.frequencyPerWeek = frequencyPerWeek
        self.commitmentLevel = commitmentLevel
        self.createdAt = Date()
        self.isCompletedToday = false
        self.completedDate = nil
        self.colorIndex = colorIndex
        self.completedDates = completedDates
        self.descriptionText = descriptionText
        self.invitedAllies = invitedAllies
        self.reminderEnabled = reminderEnabled
        self.createdByUserId = createdByUserId
    }
    
    // Legacy support for old format
    var day: String {
        return selectedDays.first ?? "Monday"
    }
}

enum DayOfWeek: String, CaseIterable {
    case monday = "Monday"
    case tuesday = "Tuesday"
    case wednesday = "Wednesday"
    case thursday = "Thursday"
    case friday = "Friday"
    case saturday = "Saturday"
    case sunday = "Sunday"
}

enum Frequency: Int, CaseIterable {
    case once = 1
    case twice = 2
    case three = 3
    case four = 4
    case five = 5
    
    var displayName: String {
        switch self {
        case .once: return "1 time"
        case .twice: return "2 times"
        case .three: return "3 times"
        case .four: return "4 times"
        case .five: return "5 times"
        }
    }
}

enum CommitmentLevel: Int, CaseIterable {
    case one = 1
    case two = 2
    case three = 3
    case four = 4
    case five = 5
    case six = 6
    case seven = 7
    case eight = 8
    case nine = 9
    case ten = 10
    
    var displayName: String {
        return "\(rawValue)/10"
    }
    
    var description: String {
        switch self {
        case .one, .two, .three: return "Low"
        case .four, .five, .six: return "Medium"
        case .seven, .eight, .nine: return "High"
        case .ten: return "Maximum"
        }
    }
}
