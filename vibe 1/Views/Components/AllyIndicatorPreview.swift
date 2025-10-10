//
//  AllyIndicatorPreview.swift
//  vibe 1
//
//  Created by Jamie Cheatham on 10/4/25.
//

import SwiftUI

struct AllyIndicatorPreview: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Swords Ally Indicator Preview")
                .font(.title2)
                .fontWeight(.bold)
                .padding()
            
            // Sample habit card with allies
            VStack(spacing: 16) {
                Text("Sample Habit Card with Allies")
                    .font(.headline)
                    .padding(.bottom, 10)
                
                // Habit card with allies
                HStack(spacing: 16) {
                    // Colored bar
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: 4)
                        .cornerRadius(2)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        // Habit name
                        Text("Morning Workout")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(2)
                        
                        // Ally indicator (showing allies)
                        AllyIndicator(allyCount: 2)
                        
                        // Day indicators
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
                    
                    // Completion indicator
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.blue)
                        
                        Text("3")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray5), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            }
            
            // Sample habit card without allies
            VStack(spacing: 16) {
                Text("Sample Habit Card without Allies")
                    .font(.headline)
                    .padding(.bottom, 10)
                
                // Habit card without allies
                HStack(spacing: 16) {
                    // Colored bar
                    Rectangle()
                        .fill(Color.orange)
                        .frame(width: 4)
                        .cornerRadius(2)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        // Habit name
                        Text("Evening Reading")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(2)
                        
                        // No ally indicator (no allies)
                        
                        // Day indicators
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
                    
                    // Completion indicator
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.orange)
                        
                        Text("1")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray5), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    AllyIndicatorPreview()
}
