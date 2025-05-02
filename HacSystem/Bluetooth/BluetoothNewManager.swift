//
//  BluetoothNewManager.swift
//  HacSystem
//
//  Created by Nino on 4/28/25.
//

import CoreBluetooth

class BluetoothNewManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    @Published var scannedDevices: [DiscoveredDevice] = []
    @Published var selectedDevices: [DiscoveredDevice] = []
    @Published var selectedDeviceId: UUID?
    @Published var isBluetoothEnabled: Bool = false
    
    private var centralManager: CBCentralManager!
    private var peripherals: [UUID: CBPeripheral] = [:]

    private var shouldStartScanning = false

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func startScanning() {
        if centralManager.state == .poweredOn {
            isBluetoothEnabled = true
            centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        } else {
            isBluetoothEnabled = false
            shouldStartScanning = true
        }
    }

    func stopScanning() {
        centralManager.stopScan()
        shouldStartScanning = false
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            print("Bluetooth powered on")
            isBluetoothEnabled = true
            if shouldStartScanning {
                centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
            }
        } else {
            isBluetoothEnabled = false
            print("Bluetooth not ready: \(central.state.rawValue)")
        }
    }

    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {

        peripherals[peripheral.identifier] = peripheral

        let device = DiscoveredDevice(id: peripheral.identifier,
                                      name: peripheral.name ?? "Unknown",
                                      advertisementData: advertisementData)

        DispatchQueue.main.async {
            // Check if the device being scanned is the selected device
           if let selectedDeviceId = self.selectedDeviceId,
              selectedDeviceId == device.id {
               
               // Find the index of the selected device in the selectedDevices array
               if let index = self.selectedDevices.firstIndex(where: { $0.id == device.id }) {
                   // Create a new updated device with the latest advertising data and RSSI
                   
                   
                   
                   if let manufacturerData = device.advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data {
                       guard manufacturerData.count >= 4 else {
                           print("Manufacturer data is too short")
                           return
                       }

                       let tpu1 = Int(manufacturerData[0])
                       let tpu2 = Int(manufacturerData[1])
                       let tpu3 = Int(manufacturerData[2])
                       let batteryBar = Int(manufacturerData[3])

                       let info = DeviceInfo(batteryLevel: batteryBar, tpu1: tpu1, tpu2: tpu2, tpu3: tpu3)
                       
                       let updatedDevice = DiscoveredDevice(id: device.id,
                                                            name: device.name, advertisementData: device.advertisementData, info: info)
                       // Replace the old selected device with the updated one
                       self.selectedDevices[index] = updatedDevice
                   }

               }
           }

           // Update scannedDevices with the latest data
           if !self.scannedDevices.contains(where: { $0.id == device.id }) {
               self.scannedDevices.append(device)
               
           } else {
               if let index = self.scannedDevices.firstIndex(where: { $0.id == device.id }) {
                   // Replace the existing device in the scanned list
                   let updatedDevice = DiscoveredDevice(id: device.id,
                                                        name: device.name, advertisementData: device.advertisementData)
                   self.scannedDevices[index] = updatedDevice
               }
           }
        }
    }
    
    func parseManufacturerData(_ data: Data, discoveredDevice: DiscoveredDevice) {
            }

    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        peripherals[peripheral.identifier] = nil
    }
    
    func selectDevice(_ device: DiscoveredDevice) {
        if !selectedDevices.contains(where: { $0.id == device.id }) {
            selectedDevices.append(device)
        }
        
        selectedDeviceId = device.id
        
//        if let peripheral = peripherals[device.id] {
//           centralManager.connect(peripheral, options: nil)
//           peripheral.delegate = self
//       }
        
    }

    func setSelectedDevice(_ device: DiscoveredDevice) {
        selectedDeviceId = device.id
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices([CBUUID(string: "180F"), CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")]) // Battery Service
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            for service in services {
                if service.uuid == CBUUID(string: "180F") {
                    peripheral.discoverCharacteristics([CBUUID(string: "2A19")], for: service)
                }
                
                if service.uuid == CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E") {
                    peripheral.discoverCharacteristics([CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")], for: service)
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if service.uuid == CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E") {
            if let characteristics = service.characteristics {
                for characteristic in characteristics {
                    print("NINOTEST \(characteristic.uuid)")
                }
            }
        }
        
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                if characteristic.uuid == CBUUID(string: "2A19") {
                    peripheral.readValue(for: characteristic)
                }
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic.uuid == CBUUID(string: "2A19"), let value = characteristic.value {
            let batteryLevel = value.first ?? 0
            
            DispatchQueue.main.async {
                if let index = self.selectedDevices.firstIndex(where: { $0.id == peripheral.identifier }), batteryLevel >= 0 {
                    var updatedDevice = self.selectedDevices[index]
                    
                    self.selectedDevices[index] = updatedDevice
                }
            }
            
            // After reading, disconnect from the peripheral
            centralManager.cancelPeripheralConnection(peripheral)
        }
        
        if characteristic.uuid == CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"), let value = characteristic.value {
            print("NINOTEST \(value)")
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }

}

struct DeviceInfo {
    var batteryLevel: Int?
    var tpu1: Int?
    var tpu2: Int?
    var tpu3: Int?
}

struct DiscoveredDevice: Identifiable, Equatable {
    let id: UUID
    let name: String
    let advertisementData: [String: Any]
    var info: DeviceInfo?
    
    
    static func == (lhs: DiscoveredDevice, rhs: DiscoveredDevice) -> Bool {
            return lhs.id == rhs.id
        }
}
