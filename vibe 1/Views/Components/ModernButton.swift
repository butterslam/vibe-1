//
//  ModernButton.swift
//  vibe 1
//
//  Created by Jamie Cheatham on 10/4/25.
//

import SwiftUI

struct ModernButton: View {
    let title: String
    let action: () -> Void
    var style: ButtonStyle = .primary
    var size: ButtonSize = .medium
    
    enum ButtonStyle {
        case primary
        case secondary
        case destructive
    }
    
    enum ButtonSize {
        case small
        case medium
        case large
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: size.fontSize, weight: .medium))
                .foregroundColor(style.foregroundColor)
                .frame(maxWidth: .infinity)
                .frame(height: size.height)
                .background(style.backgroundColor)
                .cornerRadius(size.cornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: size.cornerRadius)
                        .stroke(style.borderColor, lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

extension ModernButton.ButtonStyle {
    var backgroundColor: Color {
        switch self {
        case .primary: return Color.blue
        case .secondary: return Color.clear
        case .destructive: return Color.red
        }
    }
    
    var foregroundColor: Color {
        switch self {
        case .primary: return Color.white
        case .secondary: return Color.blue
        case .destructive: return Color.white
        }
    }
    
    var borderColor: Color {
        switch self {
        case .primary: return Color.blue
        case .secondary: return Color.blue
        case .destructive: return Color.red
        }
    }
}

extension ModernButton.ButtonSize {
    var height: CGFloat {
        switch self {
        case .small: return 32
        case .medium: return 44
        case .large: return 56
        }
    }
    
    var fontSize: CGFloat {
        switch self {
        case .small: return 14
        case .medium: return 16
        case .large: return 18
        }
    }
    
    var cornerRadius: CGFloat {
        switch self {
        case .small: return 6
        case .medium: return 8
        case .large: return 12
        }
    }
}
