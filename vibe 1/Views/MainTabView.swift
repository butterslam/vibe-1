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
    
    var body: some View {
        ZStack {
            // Main content
            VStack(spacing: 0) {
                // Content area
                ZStack {
                    if selectedTab == .home {
                        HomeView(habitStore: habitStore)
                    } else if selectedTab == .guilds {
                        GuildsView()
                    } else if selectedTab == .profile {
                        // Profile View
                        ProfileView(habitStore: habitStore)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Custom Tab Bar
                CustomTabBar(selectedTab: $selectedTab)
            }
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(HabitStore())
}
