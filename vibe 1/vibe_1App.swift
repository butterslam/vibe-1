//
//  vibe_1App.swift
//  vibe 1
//
//  Created by Jamie Cheatham on 10/4/25.
//

import SwiftUI

@main
struct vibe_1App: App {
    @StateObject private var habitStore = HabitStore()
    
    init() {
        // Request notification permission on app launch
        NotificationManager.shared.requestAuthorization()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(habitStore)
                .onAppear {
                    // Schedule notifications for all habits when app appears
                    NotificationManager.shared.rescheduleAllNotifications(for: habitStore.habits)
                }
        }
    }
}
