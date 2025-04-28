//
//  BluetoothManager.swift
//  HacSystem
//
//  Created by Nino on 4/20/25.
//

import Foundation
import CoreBluetooth
import UIKit

class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate {
    private var centralManager: CBCentralManager!
    @Published var isBluetoothEnabled: Bool = false
    @Published var scannedDevices: [CBPeripheral] = []

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            isBluetoothEnabled = true
            centralManager.scanForPeripherals(withServices: nil, options: nil)
        default:
            isBluetoothEnabled = false
            scannedDevices.removeAll()
//            redirectToBluetoothSettings()
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if !scannedDevices.contains(where: { $0.identifier == peripheral.identifier }) {
            scannedDevices.append(peripheral)
        }
    }

//    private func redirectToBluetoothSettings() {
//        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
//        if UIApplication.shared.canOpenURL(settingsUrl) {
//            DispatchQueue.main.async {
//                UIApplication.shared.open(settingsUrl)
//            }
//        }
//    }
}
