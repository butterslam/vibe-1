//
//  AllyIndicatorTest.swift
//  vibe 1
//
//  Created by Jamie Cheatham on 10/4/25.
//

import SwiftUI

struct AllyIndicatorTest: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("AllyIndicator Test")
                .font(.title)
                .fontWeight(.bold)
            
            // Test the image directly
            VStack {
                Text("Direct Image Test:")
                Image("swords")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 50)
                    .border(Color.red, width: 2)
            }
            
            // Test the AllyIndicator component
            VStack {
                Text("AllyIndicator Component Test:")
                AllyIndicator(allyCount: 2)
                    .border(Color.blue, width: 2)
            }
            
            // Test with a sample habit that has allies
            VStack {
                Text("Sample Habit with Allies:")
                let sampleHabit = Habit(
                    name: "Test Habit with Allies",
                    selectedDays: ["Monday", "Wednesday", "Friday"],
                    timeOfDay: Date(),
                    frequencyPerWeek: 3,
                    commitmentLevel: 5,
                    invitedAllies: ["ally1@example.com", "ally2@example.com"]
                )
                
                HStack(spacing: 16) {
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: 4)
                        .cornerRadius(2)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(sampleHabit.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(2)
                        
                        // This should show the ally indicator
                        if let allies = sampleHabit.invitedAllies, !allies.isEmpty {
                            AllyIndicator(allyCount: allies.count)
                        }
                        
                        HStack(spacing: 4) {
                            ForEach(["M","T","W","T","F","S","S"], id: \.self) { day in
                                Circle()
                                    .fill(Color(.systemGray5))
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        Text(day)
                                            .font(.system(size: 10, weight: .semibold))
                                            .foregroundColor(.secondary)
                                    )
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray5), lineWidth: 1)
                )
            }
        }
        .padding()
    }
}

#Preview {
    AllyIndicatorTest()
}
