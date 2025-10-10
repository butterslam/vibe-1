//
//  AllyIndicator.swift
//  vibe 1
//
//  Created by Jamie Cheatham on 10/4/25.
//

import SwiftUI

struct AllyIndicator: View {
    let allyCount: Int
    
    var body: some View {
        Image("swords")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 20, height: 20)
            .opacity(0.8)
    }
}

#Preview {
    VStack(spacing: 20) {
        Text("Swords Ally Indicator")
            .font(.headline)
            .padding(.bottom, 10)
        
        AllyIndicator(allyCount: 2)
        
        // Show how it looks in context
        HStack {
            Text("Morning Workout")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
            
            AllyIndicator(allyCount: 2)
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
        
        // Show different sizes
        HStack(spacing: 20) {
            Text("Small:")
            AllyIndicator(allyCount: 2)
            
            Text("Medium:")
            AllyIndicator(allyCount: 2)
                .scaleEffect(1.2)
            
            Text("Large:")
            AllyIndicator(allyCount: 2)
                .scaleEffect(1.5)
        }
    }
    .padding()
}
