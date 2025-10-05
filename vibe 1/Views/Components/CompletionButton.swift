//
//  CompletionButton.swift
//  vibe 1
//
//  Created by Jamie Cheatham on 10/4/25.
//

import SwiftUI

struct CompletionButton: View {
    let habit: Habit
    let onToggle: () -> Void
    
    @State private var successTextOpacity = 0.0
    
    // Reduced size by 30%: 50 * 0.7 = 35
    private let buttonSize: CGFloat = 35
    private let tapAreaSize: CGFloat = 40 // Slightly larger tap area
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            // Animated completion button
            Button(action: {
                // Allow toggling both ways
                onToggle()
                
                // Show success text with animation only when marking complete
                if habit.isCompletedToday {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        successTextOpacity = 1.0
                    }
                    
                    // Start fade out animation after 2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation(.easeOut(duration: 0.5)) {
                            successTextOpacity = 0.0
                        }
                    }
                } else {
                    // Reset success text opacity when uncompleting
                    successTextOpacity = 0.0
                }
            }) {
                ZStack {
                    // Larger tap area (invisible)
                    Color.clear
                        .frame(width: tapAreaSize, height: tapAreaSize)
                    
                    if habit.isCompletedToday {
                        // Completed state - blue checkmark
                        Circle()
                            .fill(Color.blue)
                            .frame(width: buttonSize, height: buttonSize)
                            .overlay(
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            )
                            .transition(.scale)
                    } else {
                        // Incomplete state - square outline
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.blue, lineWidth: 2)
                            .frame(width: buttonSize, height: buttonSize)
                            .transition(.scale)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            .frame(width: tapAreaSize, height: tapAreaSize) // Fixed frame to prevent movement
            
            // Text below button with fixed height to prevent layout shifts
            Group {
                if habit.isCompletedToday {
                    Text("Nice work!")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.blue)
                        .opacity(successTextOpacity)
                        .animation(.easeInOut(duration: 0.3), value: successTextOpacity)
                } else {
                    Text("Mark Done")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.blue)
                }
            }
            .frame(height: 16) // Fixed height to prevent vertical shifts
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        CompletionButton(
            habit: Habit(
                name: "Morning Exercise",
                selectedDays: ["Monday"],
                timeOfDay: Date(),
                frequencyPerWeek: 1,
                commitmentLevel: 5
            ),
            onToggle: {}
        )
        
        CompletionButton(
            habit: Habit(
                name: "Evening Reading",
                selectedDays: ["Monday"],
                timeOfDay: Date(),
                frequencyPerWeek: 1,
                commitmentLevel: 5
            ),
            onToggle: {}
        )
    }
}
