//
//  SharedLEDState.swift
//  Jeep LEDs
//
//  Shared state between main app and widgets
//

import Foundation
import SwiftUI
import UIKit

// MARK: - Shared LED State
struct LEDState: Codable {
    var isOn: Bool
    var colorName: String
    var colorRed: Double
    var colorGreen: Double
    var colorBlue: Double
    var pattern: String
    var brightness: Int
    var speed: String
    var isConnected: Bool
    var lastUpdated: Date

    static let `default` = LEDState(
        isOn: false,
        colorName: "Red",
        colorRed: 1.0,
        colorGreen: 0.0,
        colorBlue: 0.0,
        pattern: "SOLID",
        brightness: 255,
        speed: "Medium",
        isConnected: false,
        lastUpdated: Date()
    )
}

// MARK: - Shared Defaults Manager
class SharedLEDStateManager {
    static let shared = SharedLEDStateManager()

    // App Group ID for sharing data between app and widget
    private let appGroupID = "group.com.jtobrien.jeepled"
    private let stateKey = "ledState"

    private var userDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    // Save state
    func saveState(_ state: LEDState) {
        guard let defaults = userDefaults else {
            print("❌ Failed to access App Group UserDefaults")
            return
        }

        if let encoded = try? JSONEncoder().encode(state) {
            defaults.set(encoded, forKey: stateKey)
            print("✅ Saved LED state to shared defaults")
        }
    }

    // Load state
    func loadState() -> LEDState {
        guard let defaults = userDefaults,
              let data = defaults.data(forKey: stateKey),
              let state = try? JSONDecoder().decode(LEDState.self, from: data) else {
            print("⚠️ Using default LED state")
            return .default
        }

        return state
    }

    // Quick actions - save pending commands that the app will process
    func turnOff() {
        var state = loadState()
        state.isOn = false
        state.colorName = "Off"
        state.colorRed = 0
        state.colorGreen = 0
        state.colorBlue = 0
        state.lastUpdated = Date()
        saveState(state)
        
        // Queue command for the app to process
        savePendingCommand("OFF")
    }

    func setColor(name: String, red: Double, green: Double, blue: Double) {
        var state = loadState()
        state.isOn = true
        state.colorName = name
        state.colorRed = red
        state.colorGreen = green
        state.colorBlue = blue
        state.pattern = "SOLID"
        state.lastUpdated = Date()
        saveState(state)
        
        // Queue command for the app to process
        let r = Int(red * 255)
        let g = Int(green * 255)
        let b = Int(blue * 255)
        savePendingCommand("COLOR:\(r),\(g),\(b)")
    }

    func setPattern(_ pattern: String) {
        var state = loadState()
        state.isOn = true
        state.pattern = pattern
        state.lastUpdated = Date()
        saveState(state)
        
        // Queue command for the app to process
        savePendingCommand("PATTERN:\(pattern)")
    }
    
    // Save a pending command for the main app to execute
    private func savePendingCommand(_ command: String) {
        guard let defaults = userDefaults else {
            print("❌ ERROR: Could not access App Group UserDefaults!")
            return
        }
        defaults.set(command, forKey: "pendingCommand")
        defaults.set(Date(), forKey: "pendingCommandTime")
        defaults.synchronize() // Force immediate write
        print("💾 Widget saved pending command: \(command)")
        print("   App Group: \(appGroupID)")
        print("   Timestamp: \(Date())")
        
        // Verify it was saved
        if let saved = defaults.string(forKey: "pendingCommand") {
            print("✅ Verified command was saved: \(saved)")
        } else {
            print("❌ WARNING: Command was NOT saved!")
        }
    }
    
    // Get and clear pending command (called by main app)
    func getPendingCommand() -> String? {
        guard let defaults = userDefaults else {
            print("❌ ERROR: Could not access App Group UserDefaults!")
            return nil
        }
        
        guard let command = defaults.string(forKey: "pendingCommand"),
              let commandTime = defaults.object(forKey: "pendingCommandTime") as? Date else {
            // No pending command - this is normal
            return nil
        }
        
        let age = Date().timeIntervalSince(commandTime)
        print("📥 Found pending command: \(command)")
        print("   Age: \(String(format: "%.1f", age))s")
        
        // Only process commands from the last 30 seconds to avoid stale commands
        if age < 30 {
            defaults.removeObject(forKey: "pendingCommand")
            defaults.removeObject(forKey: "pendingCommandTime")
            defaults.synchronize() // Force immediate write
            print("✅ Retrieved and cleared pending command: \(command)")
            return command
        } else {
            print("⚠️ Command too old (\(String(format: "%.1f", age))s), ignoring")
            defaults.removeObject(forKey: "pendingCommand")
            defaults.removeObject(forKey: "pendingCommandTime")
            return nil
        }
    }
}
