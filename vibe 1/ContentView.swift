//
//  ContentView.swift
//  vibe 1
//
//  Created by Jamie Cheatham on 10/4/25.
//

import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @State private var isLoggedIn: Bool = Auth.auth().currentUser != nil
    
    var body: some View {
        Group {
            if isLoggedIn {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .AuthStateDidChange)) { _ in
            isLoggedIn = Auth.auth().currentUser != nil
        }
    }
}

#Preview {
    ContentView()
}
