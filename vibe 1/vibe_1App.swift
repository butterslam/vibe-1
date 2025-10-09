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
    @StateObject private var authManager = AuthManager()
    
    init() {
        // Initialize Firebase
        FirebaseApp.configure()
        // Optional verbose logging while integrating
        // FirebaseConfiguration.shared.setLoggerLevel(.debug)
        // Firestore logging (enabled by default on debug builds)
        _ = Firestore.firestore()
        // Notifications removed
        
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
                    .environmentObject(authManager)
            } else {
                AuthView()
                    .environmentObject(authManager)
            }
        }
    }
}
