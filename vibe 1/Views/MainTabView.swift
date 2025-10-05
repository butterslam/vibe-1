//
//  MainTabView.swift
//  vibe 1
//
//  Created by Jamie Cheatham on 10/4/25.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var habitStore: HabitStore
    @State private var selectedTab: CustomTabBar.TabSelection = .home
    @State private var showingAddHabit = false
    
    var body: some View {
        ZStack {
            // Main content
            VStack(spacing: 0) {
                // Content area
                ZStack {
                    if selectedTab == .home {
                        HomeView(habitStore: habitStore)
                    } else {
                        // Add Habit View
                        AddHabitView(habitStore: habitStore)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Custom Tab Bar
                CustomTabBar(selectedTab: $selectedTab)
            }
        }
        .onChange(of: selectedTab) { _, newTab in
            if newTab == .addHabit {
                showingAddHabit = true
                selectedTab = .home // Reset to home after showing sheet
            }
        }
        .sheet(isPresented: $showingAddHabit) {
            AddHabitView(habitStore: habitStore)
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(HabitStore())
}
