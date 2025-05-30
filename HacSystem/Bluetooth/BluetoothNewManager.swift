//
//  BluetoothNewManager.swift
//  HacSystem
//
//  Created by Nino on 4/28/25.
//

import CoreBluetooth

class BluetoothNewManager: NSObject, ObservableObject {
    @Published var scannedDevices: [DiscoveredDevice] = []
    @Published var selectedDevices: [DiscoveredDevice] = []
    @Published var selectedDeviceId: UUID?
    @Published var isBluetoothEnabled: Bool = false
    
    @Published var isWriting: Bool = false
    
    private var centralManager: CBCentralManager!
    private var peripherals: [UUID: CBPeripheral] = [:]
    private var nusTxCharacteristic: CBCharacteristic!

    private var shouldStartScanning = false
    
    private var message: MessageData?

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
    
    func selectDevice(_ device: DiscoveredDevice) {
        if !selectedDevices.contains(where: { $0.id == device.id }) {
            selectedDevices.append(device)
        }
        
        selectedDeviceId = device.id
        
    }
    
    func setSelectedDevice(_ device: DiscoveredDevice) {
        selectedDeviceId = device.id
    }
    
    func sendToDevice(deviceOffset: Int, value: Int) {
        guard let selectedDeviceId else { return }
        
        if let peripheral = peripherals[selectedDeviceId] {
            isWriting = true
            message = MessageData(offset: deviceOffset, value: value)
            
            centralManager.connect(peripheral, options: nil)
            peripheral.delegate = self
       }
    }
}

extension BluetoothNewManager: CBCentralManagerDelegate {
    
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

        let localName = advertisementData[CBAdvertisementDataLocalNameKey] as? String
        let deviceName = localName ?? peripheral.name ?? "Unknown"
        let device = DiscoveredDevice(id: peripheral.identifier,
                                      name: deviceName,
                                      advertisementData: advertisementData)

        if let selectedDeviceId = self.selectedDeviceId, selectedDeviceId == device.id,
           let index = self.selectedDevices.firstIndex(where: { $0.id == device.id }),
           let manufacturerData = device.advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data {
    
           guard manufacturerData.count >= 4 else {
               print("Manufacturer data is too short")
               return
           }

           let tpu1 = Int(manufacturerData[2])
           let tpu2 = Int(manufacturerData[3])
           let tpu3 = Int(manufacturerData[4])
           let batteryBar = Int(manufacturerData[5])

            if let message {
                let currentValue: Int = switch message.offset {
                case 1: tpu1
                case 2: tpu2
                case 3: tpu3
                default: -1
                }

                if message.value == currentValue  {
                    
                    self.message = nil
                } else {
                    return
                }
                
                
            }
            
            guard message == nil else { return }
            
            let strength = getSignalStrength(rssi: RSSI.intValue)
            let info = DeviceInfo(batteryLevel: batteryBar, tpu1: tpu1, tpu2: tpu2, tpu3: tpu3, signalStrength: strength)
            let updatedDevice = DiscoveredDevice(id: device.id,name: device.name,
                                                advertisementData: device.advertisementData, info: info)

            self.selectedDevices[index] = updatedDevice
            
            isWriting = false
       }
            
        // Update scannedDevices with the latest data
        if self.scannedDevices.contains(where: { $0.id == device.id }) == false,
           device.name.lowercased().hasPrefix("hac"){
            self.scannedDevices.append(device)
        } else if let index = self.scannedDevices.firstIndex(where: { $0.id == device.id }) {

            let updatedDevice = DiscoveredDevice(id: device.id, name: device.name,
                                                advertisementData: device.advertisementData)
            self.scannedDevices[index] = updatedDevice
        }

    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        peripherals[peripheral.identifier] = nil
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        guard message != nil else { return }
        
        peripheral.discoverServices([CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")])
        
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            peripheral.readRSSI()
        }
    }
}

extension BluetoothNewManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard message != nil else { return }
        
        if let services = peripheral.services {
            for service in services {
                if service.uuid == CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E") {
                    peripheral.discoverCharacteristics([CBUUID(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E")], for: service)
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let message else { return }
        
        for characteristic in service.characteristics! {
            if characteristic.uuid == CBUUID(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E") { // TX characteristic UUID
                nusTxCharacteristic = characteristic
                
                guard let selectedDevice = selectedDevices.first(where: { $0.id == selectedDeviceId }), let info = selectedDevice.info else { return }
                
                var tpu1Value: UInt8 = UInt8(info.tpu1 ?? 0) // Change this value to set TPU1
                var tpu2Value: UInt8 = UInt8(info.tpu2 ?? 0) // Change this value to set TPU2
                var tpu3Value: UInt8 = UInt8(info.tpu3 ?? 0) // Change this value to set TPU3
                
                switch message.offset {
                case 1: tpu1Value = UInt8(message.value)
                case 2: tpu2Value = UInt8(message.value)
                case 3: tpu3Value = UInt8(message.value)
                default:
                    break;
                }

                let command: [UInt8] = [0x01, tpu1Value, tpu2Value, tpu3Value]
                let dataToWrite = Data(command)
                peripheral.writeValue(dataToWrite, for: nusTxCharacteristic, type: .withResponse)

            }
        }
    }
    

    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Failed to write value: \(error.localizedDescription)")
            isWriting = false
        } else {
            print("Data written successfully! Offset: \(message?.offset ?? 0) Value: \(message?.value ?? 0)")
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: (any Error)?) {
        guard let selectedDevice = selectedDevices.first(where: { $0.id == selectedDeviceId }), let info = selectedDevice.info,
                let index = self.selectedDevices.firstIndex(where: { $0.id == selectedDevice.id }) else { return }

        if let error = error {
            print("Failed to read RSSI: \(error.localizedDescription)")
        } else {
            print("Current RSSI: \(RSSI.intValue) dBm")
            
            let strength = getSignalStrength(rssi: RSSI.intValue)

            let newInfo = DeviceInfo(batteryLevel: info.batteryLevel, tpu1: info.tpu1, tpu2: info.tpu2, tpu3: info.tpu3, signalStrength: strength)
            let updatedDevice = DiscoveredDevice(id: selectedDevice.id,name: selectedDevice.name,
                                                advertisementData: selectedDevice.advertisementData, info: newInfo)
            self.selectedDevices[index] = updatedDevice
        }
    }
    
    func getSignalStrength(rssi: Int) -> SignalStrength {
        return switch rssi {
        case let x where x >= -60: .strong
        case -80 ... -61: .average
        default: .weak
        }
    }
    
}

struct DeviceInfo {
    var batteryLevel: Int?
    var tpu1: Int?
    var tpu2: Int?
    var tpu3: Int?
    var signalStrength: SignalStrength?
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

struct MessageData {
    let offset: Int
    let value: Int
}
