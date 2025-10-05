//
//  HabitCard.swift
//  vibe 1
//
//  Created by Jamie Cheatham on 10/4/25.
//

import SwiftUI

struct HabitCard: View {
    let habit: Habit
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(habit.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(habit.day)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(habit.frequencyPerWeek)x/week")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                    
                    Text("\(habit.commitmentLevel)/10")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                ForEach(0..<habit.commitmentLevel, id: \.self) { _ in
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                }
                ForEach(habit.commitmentLevel..<10, id: \.self) { _ in
                    Circle()
                        .fill(Color(.systemGray4))
                        .frame(width: 8, height: 8)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}
