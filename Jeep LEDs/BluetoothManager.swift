//
//  BluetoothManager.swift
//  Jeep LEDs
//
//  Manages Bluetooth Low Energy communication with Adafruit Bluefruit
//

import Foundation
import CoreBluetooth
import Combine

class BluetoothManager: NSObject, ObservableObject {
    // UART service UUID for Adafruit Bluefruit
    private let uartServiceUUID = CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
    private let txCharacteristicUUID = CBUUID(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E")
    private let rxCharacteristicUUID = CBUUID(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E")

    @Published var isConnected = false
    @Published var discoveredDevices: [CBPeripheral] = []
    @Published var statusMessage = "Not connected"
    @Published var hasEverConnected = false
    @Published var lastConnectedDeviceName: String?

    private var centralManager: CBCentralManager!
    private var connectedPeripheral: CBPeripheral?
    private var txCharacteristic: CBCharacteristic?
    private var shouldAutoReconnect = false
    private var lastConnectedDeviceID: UUID?
    private var commandQueue: [String] = []
    private var isProcessingCommand = false

    // UserDefaults keys
    private let lastDeviceIDKey = "LastConnectedDeviceID"
    private let lastDeviceNameKey = "LastConnectedDeviceName"
    private let hasConnectedKey = "HasEverConnected"

    override init() {
        super.init()

        // Load saved device info
        if let uuidString = UserDefaults.standard.string(forKey: lastDeviceIDKey),
           let uuid = UUID(uuidString: uuidString) {
            lastConnectedDeviceID = uuid
            shouldAutoReconnect = true
        }

        lastConnectedDeviceName = UserDefaults.standard.string(forKey: lastDeviceNameKey)
        hasEverConnected = UserDefaults.standard.bool(forKey: hasConnectedKey)

        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    // Start scanning for Bluetooth devices
    func startScanning() {
        discoveredDevices.removeAll()
        statusMessage = "Scanning for devices..."
        centralManager.scanForPeripherals(withServices: nil, options: nil)
    }

    // Stop scanning
    func stopScanning() {
        centralManager.stopScan()
        if !isConnected {
            statusMessage = "Scan stopped"
        }
    }

    // Connect to a specific peripheral
    func connect(to peripheral: CBPeripheral) {
        stopScanning()
        statusMessage = "Connecting to \(peripheral.name ?? "device")..."
        
        // Set peripheral reference BEFORE calling connect to avoid Core Bluetooth warning
        connectedPeripheral = peripheral
        peripheral.delegate = self
        
        centralManager.connect(peripheral, options: nil)

        // Save device info for auto-reconnect
        lastConnectedDeviceID = peripheral.identifier
        UserDefaults.standard.set(peripheral.identifier.uuidString, forKey: lastDeviceIDKey)
        UserDefaults.standard.set(peripheral.name, forKey: lastDeviceNameKey)
        UserDefaults.standard.set(true, forKey: hasConnectedKey)

        hasEverConnected = true
        lastConnectedDeviceName = peripheral.name
    }

    // Disconnect from current peripheral
    func disconnect() {
        shouldAutoReconnect = false
        if let peripheral = connectedPeripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }

    // Forget saved device
    func forgetDevice() {
        disconnect()
        UserDefaults.standard.removeObject(forKey: lastDeviceIDKey)
        UserDefaults.standard.removeObject(forKey: lastDeviceNameKey)
        lastConnectedDeviceID = nil
        lastConnectedDeviceName = nil
    }

    // Send command to Arduino with queuing for reliability
    func sendCommand(_ command: String, priority: Bool = false) {
        let queueSizeBefore = commandQueue.count
        
        // If priority command, clear conflicting commands from queue
        if priority {
            let commandType = String(command.prefix(1))
            let removedCommands = commandQueue.filter { String($0.prefix(1)) == commandType }
            commandQueue.removeAll { queuedCmd in
                String(queuedCmd.prefix(1)) == commandType
            }
            
            if !removedCommands.isEmpty {
                print("⚡ PRIORITY: Cleared \(removedCommands.count) pending '\(commandType)' command(s)")
                for cmd in removedCommands {
                    print("   Removed: '\(cmd.trimmingCharacters(in: .whitespacesAndNewlines))'")
                }
            }
        }
        
        commandQueue.append(command)
        print("📋 Queue: \(queueSizeBefore) → \(commandQueue.count) commands | Added: '\(command.trimmingCharacters(in: .whitespacesAndNewlines))'")
        
        processCommandQueue()
    }

    private func processCommandQueue() {
        guard !isProcessingCommand, !commandQueue.isEmpty else { return }
        guard let characteristic = txCharacteristic,
              let peripheral = connectedPeripheral else {
            commandQueue.removeAll()
            return
        }

        isProcessingCommand = true
        let command = commandQueue.removeFirst()

        guard let data = command.data(using: .utf8) else {
            isProcessingCommand = false
            processCommandQueue()
            return
        }

        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        print("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📤 [\(timestamp)] SENDING COMMAND")
        print("   Command: '\(command.trimmingCharacters(in: .whitespacesAndNewlines))'")
        print("   Length: \(data.count) bytes")
        print("   Hex: \(data.map { String(format: "%02X", $0) }.joined(separator: " "))")
        
        // Decode the command type for clarity
        let cmdType = command.first
        let cmdDescription: String
        switch cmdType {
        case "C": cmdDescription = "COLOR"
        case "P": cmdDescription = "PATTERN"
        case "B": cmdDescription = "BRIGHTNESS"
        case "S": cmdDescription = "SPEED"
        default: cmdDescription = "UNKNOWN"
        }
        print("   Type: \(cmdDescription)")

        // Send entire command at once for reliability
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let startTime = Date()
            
            // Send entire command in one write
            peripheral.writeValue(data, for: characteristic, type: .withoutResponse)
            
            let sendTime = Date().timeIntervalSince(startTime)
            print("   ✓ Transmitted in \(Int(sendTime * 1000000))µs")
            
            // Wait for Arduino to process (allow 150ms for command to be received and processed)
            Thread.sleep(forTimeInterval: 0.15)
            
            let elapsed = Date().timeIntervalSince(startTime)
            print("✅ [\(DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium))] Command complete (\(Int(elapsed * 1000))ms total)")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")

            DispatchQueue.main.async {
                self?.isProcessingCommand = false
                self?.processCommandQueue()
            }
        }
    }

    // Send color command (RGB format)
    func setColor(red: Int, green: Int, blue: Int, priority: Bool = true) {
        let command = "C\(red),\(green),\(blue)\n"
        sendCommand(command, priority: priority)
        print("🎨 Color command queued: RGB(\(red),\(green),\(blue)) [Priority: \(priority)]")
    }

    // Send pattern command
    func setPattern(_ pattern: String, priority: Bool = true) {
        let command = "P\(pattern)\n"
        sendCommand(command, priority: priority)
        print("✨ Pattern command queued: \(pattern) [Priority: \(priority)]")
    }

    // Send brightness command
    func setBrightness(_ brightness: Int, priority: Bool = false) {
        let command = "B\(brightness)\n"
        sendCommand(command, priority: priority)
        print("🔆 Brightness command queued: \(brightness)")
    }
    
    // Send speed command (multiplier: 0.5 = fast, 1.0 = medium, 2.0 = slow)
    func setSpeed(_ multiplier: Double, priority: Bool = false) {
        // Convert multiplier to percentage (50 = fast, 100 = medium, 200 = slow)
        let speedPercent = Int(multiplier * 100)
        let command = "S\(speedPercent)\n"
        sendCommand(command, priority: priority)
        print("⚡ Speed command queued: \(speedPercent)% (multiplier: \(multiplier))")
    }
}

// MARK: - CBCentralManagerDelegate
extension BluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            statusMessage = "Bluetooth ready"

            // Try to auto-reconnect to last device
            if shouldAutoReconnect, let lastID = lastConnectedDeviceID {
                statusMessage = "Reconnecting to last device..."
                let peripherals = centralManager.retrievePeripherals(withIdentifiers: [lastID])
                if let peripheral = peripherals.first {
                    connect(to: peripheral)
                } else {
                    // Device not found, scan for it
                    startScanning()
                }
            }
        case .poweredOff:
            statusMessage = "Bluetooth is off"
        case .unauthorized:
            statusMessage = "Bluetooth not authorized"
        case .unsupported:
            statusMessage = "Bluetooth not supported"
        default:
            statusMessage = "Bluetooth unavailable"
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // Only add devices with names
        if let name = peripheral.name, !name.isEmpty {
            if !discoveredDevices.contains(where: { $0.identifier == peripheral.identifier }) {
                discoveredDevices.append(peripheral)

                // Auto-connect to last device if found
                if shouldAutoReconnect, peripheral.identifier == lastConnectedDeviceID {
                    connect(to: peripheral)
                    shouldAutoReconnect = false
                }
            }
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        isConnected = true
        connectedPeripheral = peripheral
        statusMessage = "Connected to \(peripheral.name ?? "device")"
        peripheral.delegate = self
        peripheral.discoverServices([uartServiceUUID])

        print("✅ Connected to \(peripheral.name ?? "device")")
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        isConnected = false
        connectedPeripheral = nil
        txCharacteristic = nil
        commandQueue.removeAll()
        isProcessingCommand = false
        statusMessage = "Disconnected"

        print("❌ Disconnected from device")

        // Try to reconnect if it was unexpected
        if shouldAutoReconnect || error != nil {
            statusMessage = "Attempting to reconnect..."
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                if let self = self, !self.isConnected {
                    self.centralManager.connect(peripheral, options: nil)
                }
            }
        }
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        statusMessage = "Failed to connect: \(error?.localizedDescription ?? "Unknown error")"
        print("⚠️ Connection failed: \(error?.localizedDescription ?? "Unknown")")
    }
}

// MARK: - CBPeripheralDelegate
extension BluetoothManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }

        for service in services {
            if service.uuid == uartServiceUUID {
                peripheral.discoverCharacteristics([txCharacteristicUUID, rxCharacteristicUUID], for: service)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }

        for characteristic in characteristics {
            if characteristic.uuid == txCharacteristicUUID {
                txCharacteristic = characteristic
                statusMessage = "Ready to control LEDs"
                print("✅ TX characteristic found - ready to send commands")
            } else if characteristic.uuid == rxCharacteristicUUID {
                // Enable notifications for receiving data from Arduino
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }
}
