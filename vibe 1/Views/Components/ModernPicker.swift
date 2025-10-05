//
//  ModernPicker.swift
//  vibe 1
//
//  Created by Jamie Cheatham on 10/4/25.
//

import SwiftUI

struct ModernPicker<T: Hashable & CaseIterable>: View {
    let title: String
    @Binding var selection: T
    let options: [T]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
            
            Menu {
                ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                    Button(getDisplayName(for: option)) {
                        selection = option
                    }
                }
            } label: {
                HStack {
                    Text(getDisplayName(for: selection))
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.secondary)
                        .font(.system(size: 12, weight: .medium))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
            }
        }
    }
    
    private func getDisplayName(for option: T) -> String {
        if let dayOfWeek = option as? DayOfWeek {
            return dayOfWeek.rawValue
        } else if let frequency = option as? Frequency {
            switch frequency {
            case .once: return "1 time"
            case .twice: return "2 times"
            case .three: return "3 times"
            case .four: return "4 times"
            case .five: return "5 times"
            }
        } else if let commitment = option as? CommitmentLevel {
            return "\(commitment.rawValue)/10 - \(commitment.description)"
        } else {
            return String(describing: option)
        }
    }
}

