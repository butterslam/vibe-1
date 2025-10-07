//
//  vibe_1App.swift
//  vibe 1
//
//  Created by Jamie Cheatham on 10/4/25.
//
import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore


@main
struct vibe_1App: App {
    @StateObject private var habitStore = HabitStore()
    @StateObject private var notificationStore = NotificationStore()
    @StateObject private var authManager = AuthManager()
    
    init() {
        // Initialize Firebase
        FirebaseApp.configure()
        // Optional verbose logging while integrating
        // FirebaseConfiguration.shared.setLoggerLevel(.debug)
        // Firestore logging (enabled by default on debug builds)
        _ = Firestore.firestore()
        // Request notification permission on app launch
        NotificationManager.shared.requestAuthorization()
        
        // Development: Force sign out on app launch to test login flow
        #if DEBUG
        // Uncomment the line below to force sign out on every app launch for testing
        // Auth.auth().signOut()
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                ContentView()
                    .environmentObject(habitStore)
                    .environmentObject(notificationStore)
                    .environmentObject(authManager)
                    .onAppear {
                        // Schedule notifications for all habits when app appears
                        NotificationManager.shared.rescheduleAllNotifications(for: habitStore.habits)
                        // Note: Firebase notifications will be fetched when user opens notifications tab
                        // to avoid permission errors on app startup
                    }
            } else {
                AuthView()
                    .environmentObject(authManager)
            }
        }
    }
}
