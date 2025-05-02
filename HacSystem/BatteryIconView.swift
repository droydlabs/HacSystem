//
//  BatteryIconView.swift
//  HacSystem
//
//  Created by Nino on 5/3/25.
//
import SwiftUI

struct BatteryIconView: View {
    @Binding var level: Int

    var body: some View {
        Image(systemName: batteryImageName(for: level))
            .font(.system(size: 40))
            .foregroundColor(.green)
            .padding(12)
            .background(
               RoundedRectangle(cornerRadius: 10)
                   .fill(Color.black.opacity(0.7))
            )
    }

    func batteryImageName(for level: Int) -> String {
        switch level {
        case 1:
            return "battery.25"
        case 2:
            return "battery.50"
        case 3:
            return "battery.75"
        case 4, 5:
            return "battery.100"
        default:
            return "battery.0"
        }
    }
}
