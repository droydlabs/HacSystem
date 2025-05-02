//
//  LevelView.swift
//  HacSystem
//
//  Created by Nino on 4/5/25.
//

import SwiftUI

struct LevelView: View {
    let label: String
    @Binding var level: Int
    private let totalLevels: Int = 4

    @GestureState private var dragOffset: CGFloat = 0

    var onLevelChange: ((Int) -> Void)? = nil

    var body: some View {
        VStack {
            GeometryReader { geometry in
                let fullHeight = geometry.size.height
                let levelHeight = fullHeight / CGFloat(totalLevels)
                let currentHeight = CGFloat(level + 1) * levelHeight + dragOffset

                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(white: 0.8))
                        .overlay(
                            Canvas { context, size in
                                for i in 1..<totalLevels {
                                    let y = size.height - CGFloat(i) * levelHeight
                                    var line = Path()
                                    line.addRect(CGRect(x: 0, y: y, width: size.width, height: 1))
                                    context.fill(line, with: .color(.black))
                                }
                            }
                            .blendMode(.destinationOut)
                        )
                        .compositingGroup()

                    RoundedRectangle(cornerRadius: 16)
                        .fill(gradientForLevel(level))
                        .frame(height: max(0, min(fullHeight, currentHeight)))
                }
                .cornerRadius(16)
                .gesture(
                    DragGesture()
                        .updating($dragOffset) { value, state, _ in
                            state = -value.translation.height
                        }
                        .onEnded { value in
                            let finalHeight = CGFloat(level + 1) * levelHeight - value.translation.height
                            let snappedLevel = Int((finalHeight / levelHeight).rounded()) - 1
                            level = min(max(snappedLevel, 0), totalLevels - 1)
                            onLevelChange?(level)
                        }
                )
                .onTapGesture { location in
                    let tapY = location.y
                    let levelIndex = Int(((fullHeight - tapY) / levelHeight).rounded(.up)) - 1
                    level = min(max(levelIndex, 0), totalLevels - 1)
                    onLevelChange?(level)
                }
                .animation(.easeInOut(duration: 0.2), value: level)
            }
            .frame(width: 80, height: 300)
            .shadow(color: Color.gray, radius: 4)
        }
        .padding()
    }

    // MARK: - Color logic per level
    private func gradientForLevel(_ level: Int) -> LinearGradient {
        switch level {
        case 0:
            return LinearGradient(colors: [.black.opacity(0.7), .gray],
                                  startPoint: .top,
                                  endPoint: .bottom)
        case 1:
            return LinearGradient(colors: [.yellow.opacity(0.4), .orange],
                                  startPoint: .top,
                                  endPoint: .bottom)
        case 2:
            return LinearGradient(colors: [.yellow.opacity(0.7), .orange],
                                  startPoint: .top,
                                  endPoint: .bottom)
        default:
            return LinearGradient(colors: [.yellow, .orange],
                                  startPoint: .top,
                                  endPoint: .bottom)
        }
    }
}
