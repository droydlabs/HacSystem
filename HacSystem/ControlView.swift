//
//  ControlView.swift
//  HacSystem
//
//  Created by Nino on 4/20/25.
//

import SwiftUI
struct ControlView: View {
    @State private var selectedOption = "Device 1"
    @State private var options: [String] = ["Device 1", "Device 2", "Device 3"]
    
    @State private var device1: Int = 2
    @State private var device2: Int = 2
    @State private var device3: Int = 2
    
    @State private var showAddNewSheet = false
    
    var body: some View {
        
        ZStack {
            Image("grafitti")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

            VStack {
                Picker("Please choose an option", selection: $selectedOption) {
                    ForEach(options, id: \.self) { option in
                        Text(option)
                    }

                    Text("➕ Add New…")
                        .foregroundColor(.blue)
                        .tag("__add_new__")

                }
                .pickerStyle(MenuPickerStyle())
                .padding()
                .frame(width: UIScreen.main.bounds.width * 0.85)
                .background(Color.white)
                .cornerRadius(10)
                .onChange(of: selectedOption) { newValue in
                    if newValue == "__add_new__" {
                        // Revert selection and show action
                        selectedOption = options.first ?? ""
                        showAddNewSheet = true
                    }
                }
                .sheet(isPresented: $showAddNewSheet) {
                    AddNewOptionView { newOption in
                        if let newOption = newOption, !newOption.isEmpty {
                            options.append(newOption)
                            selectedOption = newOption
                        }
                    }
                }
                .padding()

                Spacer()

                HStack {
                    LevelView(label: "Back", level: $device1)
                    LevelView(label: "Left", level: $device2)
                    LevelView(label: "Right", level: $device3)
                }

                Spacer()

            }

            Spacer()
        }

    }
}
