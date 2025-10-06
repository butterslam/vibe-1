//
//  CustomTabBar.swift
//  vibe 1
//
//  Created by Jamie Cheatham on 10/4/25.
//

import SwiftUI

struct CustomTabBar: View {
    @Binding var selectedTab: TabSelection
    
    enum TabSelection {
        case home
        case addHabit
        case profile
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Home Tab
            Button(action: { selectedTab = .home }) {
                VStack(spacing: 6) {
                    Image(systemName: selectedTab == .home ? "house.fill" : "house")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(selectedTab == .home ? .blue : .secondary)
                    
                    Text("Home")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(selectedTab == .home ? .blue : .secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Add Habit Tab
            Button(action: { selectedTab = .addHabit }) {
                VStack(spacing: 6) {
                    Image(systemName: selectedTab == .addHabit ? "plus.circle.fill" : "plus.circle")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(selectedTab == .addHabit ? .blue : .secondary)
                    
                    Text("Add Habit")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(selectedTab == .addHabit ? .blue : .secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Profile Tab
            Button(action: { selectedTab = .profile }) {
                VStack(spacing: 6) {
                    Image(systemName: selectedTab == .profile ? "person.fill" : "person")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(selectedTab == .profile ? .blue : .secondary)
                    
                    Text("Profile")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(selectedTab == .profile ? .blue : .secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color(.systemGray4)),
            alignment: .top
        )
    }
}

#Preview {
    CustomTabBar(selectedTab: .constant(.home))
}
