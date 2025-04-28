//
//  ContentView.swift
//  HacSystem
//
//  Created by Nino on 4/5/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var bluetoothManager = BluetoothManager()
    
    var body: some View {
        if bluetoothManager.isBluetoothEnabled {
            ControlView()
        } else {
            BluetoothDisabledView()
        }
    }
}

#Preview {
    ContentView()
}
