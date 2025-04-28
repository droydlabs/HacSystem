//
//  AddNewLevelView.swift
//  HacSystem
//
//  Created by Nino on 4/5/25.
//

import SwiftUI

struct AddNewOptionView: View {
    @Environment(\.dismiss) var dismiss
    @State private var newValue = ""
    let onAdd: (String?) -> Void

    var body: some View {
        NavigationView {
            Form {
                TextField("New Option", text: $newValue)
            }
            .navigationTitle("Add New Option")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onAdd(newValue)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onAdd(nil)
                        dismiss()
                    }
                }
            }
        }
    }
}
