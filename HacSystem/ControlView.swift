//
//  ControlView.swift
//  HacSystem
//
//  Created by Nino on 4/20/25.
//

import SwiftUI

struct ControlView: View {
    @StateObject private var bluetoothManager = BluetoothNewManager()
    
    @State private var device1: Int = 2
    @State private var device2: Int = 2
    @State private var device3: Int = 2
    
    @State private var battery: Int = 2
    
    @State private var showingScanner = false
    
    private let newValueUuid = UUID()
    
    var body: some View {
        
        ZStack {
            Image("grafitti")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

            VStack {

                if bluetoothManager.selectedDevices.isEmpty {
                    
                    Button(action: {
                        showingScanner = true
                    }) {
                        Text("Add Device")
                            .padding()
                            .frame(width: UIScreen.main.bounds.width * 0.85)
                            .background(Color.white)
                            .cornerRadius(10)
                    }
                } else {
                    Picker("Select a Device", selection: $bluetoothManager.selectedDeviceId) {
                        ForEach(bluetoothManager.selectedDevices) { device in
                            Text(device.name)
                                .tag(device.id)
                        }
                        
                        Text("➕ Add New…")
                            .foregroundColor(.blue)
                            .tag(newValueUuid)
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding()
                    .frame(width: UIScreen.main.bounds.width * 0.85)
                    .background(Color.white)
                    .cornerRadius(10)
                    .onChange(of: bluetoothManager.selectedDeviceId) { newValue in
                        if newValue == newValueUuid {
                            // Revert selection and show action
                            bluetoothManager.selectedDeviceId = bluetoothManager.selectedDevices.first?.id
                            showingScanner = true
                        }
                    }
               
                }
                
                Spacer()

                if bluetoothManager.selectedDeviceId != nil {
                    
                    Image(.logo)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 250, height: 150)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white.opacity(0.2))
                        )
                
                    BatteryIconView(level: $battery)
                    
                    HStack {
                        LevelView(level: $device1) {
                            bluetoothManager.sendToDevice(deviceOffset: 1, value: $0)
                        }
                        LevelView(level: $device2) {
                            bluetoothManager.sendToDevice(deviceOffset: 2, value: $0)
                        }
                        LevelView(level: $device3) {
                            bluetoothManager.sendToDevice(deviceOffset: 3, value: $0)
                        }
                    }
                    .onReceive(bluetoothManager.$selectedDevices) { newValue in
                        guard let device = bluetoothManager.selectedDevices.first(
                            where: { $0.id == bluetoothManager.selectedDeviceId }
                        ), bluetoothManager.isWriting == false
                        else { return }
                        
                        device1 = device.info?.tpu1 ?? 1
                        device2 = device.info?.tpu2 ?? 1
                        device3 = device.info?.tpu3 ?? 1
                        battery = device.info?.batteryLevel ?? 1
                    }
                    .allowsHitTesting(!bluetoothManager.isWriting)
                    
                }
            }
            .frame(height: UIScreen.main.bounds.height * 0.75)
        }
        .sheet(isPresented: $showingScanner) {
            ScanDevicesView(bluetoothManager: bluetoothManager)
        }
        .onAppear {
            bluetoothManager.startScanning()
        }
        .onDisappear {
            bluetoothManager.stopScanning()
        }

    }
}
