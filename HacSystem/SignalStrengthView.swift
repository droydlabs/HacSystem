//
//  SignalStrengthView.swift
//  HacSystem
//
//  Created by dev droydlabs on 2025-05-30.
//

import SwiftUI

enum SignalStrength: String {
    case weak = "Weak"
    case average = "Average"
    case strong = "Strong"

    var color: Color {
        switch self {
        case .weak:
            return .red
        case .average:
            return .yellow
        case .strong:
            return .green
        }
    }
}

struct SignalStrengthView: View {
    @Binding var strength: SignalStrength

    var body: some View {
        VStack(alignment: .center, spacing: -12) {
            Image(systemName: "dot.radiowaves.left.and.right")
                .font(.system(size: 32))
                .foregroundColor(strength.color)
                .padding(11)
                
            Text(strength.rawValue)
                .font(.caption)
                .foregroundColor(strength.color)
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.7))
        )
    }
}

