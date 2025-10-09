//
//  CustomTabBar.swift
//  vibe 1
//
//  Created by Jamie Cheatham on 10/4/25.
//

import SwiftUI

struct CustomTabBar: View {
    @Binding var selectedTab: TabSelection
    @ObservedObject var notificationStore: NotificationStore
    
    enum TabSelection {
        case home
        case guilds
        case notifications
        case profile
    }
    
    private var hasUnreadNotifications: Bool {
        return notificationStore.unreadCount > 0
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
            
            // Guilds Tab
            Button(action: { selectedTab = .guilds }) {
                VStack(spacing: 6) {
                    Image(systemName: selectedTab == .guilds ? "person.3.fill" : "person.3")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(selectedTab == .guilds ? .blue : .secondary)
                    
                    Text("Guilds")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(selectedTab == .guilds ? .blue : .secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Notifications Tab
            Button(action: { selectedTab = .notifications }) {
                VStack(spacing: 6) {
                    ZStack {
                        Image(systemName: selectedTab == .notifications ? "bell.fill" : "bell")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(selectedTab == .notifications ? .blue : .secondary)
                        
                        // Notification badge
                        if hasUnreadNotifications {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                                .offset(x: 8, y: -8)
                        }
                    }
                    
                    Text("Notifications")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(selectedTab == .notifications ? .blue : .secondary)
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
    CustomTabBar(selectedTab: .constant(.home), notificationStore: NotificationStore())
}
