//
//  SettingsView.swift
//  Jeep LEDs
//
//  Settings and connection management
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var bluetoothManager: BluetoothManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeviceList = false
    
    var body: some View {
        NavigationStack {
            List {
                // Connection Section
                Section {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(bluetoothManager.isConnected ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                                .frame(width: 50, height: 50)
                            Circle()
                                .fill(bluetoothManager.isConnected ? Color.green : Color.red)
                                .frame(width: 20, height: 20)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(bluetoothManager.isConnected ? "Connected" : "Not Connected")
                                .font(.headline)
                            Text(bluetoothManager.statusMessage)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                    
                    if let deviceName = bluetoothManager.lastConnectedDeviceName {
                        LabeledContent("Device", value: deviceName)
                    }
                    
                    Button(action: { showingDeviceList = true }) {
                        Label(
                            bluetoothManager.isConnected ? "Change Device" : "Connect to Device",
                            systemImage: "antenna.radiowaves.left.and.right"
                        )
                    }
                    
                    if bluetoothManager.isConnected {
                        Button(role: .destructive, action: {
                            bluetoothManager.disconnect()
                        }) {
                            Label("Disconnect", systemImage: "xmark.circle")
                        }
                    }
                    
                    if bluetoothManager.hasEverConnected {
                        Button(role: .destructive, action: {
                            bluetoothManager.forgetDevice()
                        }) {
                            Label("Forget Device", systemImage: "trash")
                        }
                    }
                } header: {
                    Text("Bluetooth Connection")
                }
                
                // About Section
                Section {
                    LabeledContent("Device", value: "Adafruit Bluefruit LE")
                    LabeledContent("LED Strip", value: "8 LEDs")
                    LabeledContent("Controller", value: "Arduino Uno R2")
                } header: {
                    Text("Hardware")
                }
                
                // App Info
                Section {
                    LabeledContent("Version", value: "1.0")
                    LabeledContent("Build", value: "1")
                } header: {
                    Text("App Info")
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingDeviceList) {
                DeviceListSheet(bluetoothManager: bluetoothManager)
            }
        }
    }
}

#Preview {
    SettingsView(bluetoothManager: BluetoothManager())
}
