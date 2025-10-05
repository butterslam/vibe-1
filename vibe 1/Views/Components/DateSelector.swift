//
//  DateSelector.swift
//  vibe 1
//
//  Created by Jamie Cheatham on 10/4/25.
//

import SwiftUI

struct DateSelector: View {
    @Binding var selectedDate: Date
    
    var body: some View {
        HStack {
            Image(systemName: "calendar")
                .foregroundColor(.blue)
                .font(.system(size: 16, weight: .medium))
            
            DatePicker("", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(CompactDatePickerStyle())
                .labelsHidden()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
}
