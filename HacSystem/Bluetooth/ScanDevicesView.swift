//
//  Untitled.swift
//  HacSystem
//
//  Created by Nino on 4/28/25.
//
import SwiftUI

struct ScanDevicesView: View {
    @ObservedObject var bluetoothManager: BluetoothNewManager
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List(bluetoothManager.scannedDevices) { device in
                VStack(alignment: .leading) {
                    Text(device.name)
                        .font(.headline)
                }
                .onTapGesture {
                    bluetoothManager.selectDevice(device)
                    presentationMode.wrappedValue.dismiss()
                }
            }
            .navigationTitle("Scan Devices")
        }
    }
}
