//
//  ContentView.swift
//  Jeep LEDs
//
//  Created by voyager on 2/22/26.
//

import SwiftUI
import CoreBluetooth

// MARK: - Haptic Feedback Helper
class HapticManager {
    static let shared = HapticManager()
    
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
    
    func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

struct ContentView: View {
    @StateObject private var bluetoothManager = BluetoothManager()
    @EnvironmentObject var deepLinkHandler: DeepLinkHandler
    @State private var selectedColor = Color.red
    @State private var brightness: Double = 255
    @State private var showingDeviceList = false
    @State private var showingSettings = false
    @State private var selectedPattern: String? = nil
    @State private var isRefreshing = false
    @State private var patternSpeed: PatternSpeed = .medium
    @State private var autoOffTimer: AutoOffTimer = .off
    @State private var timerEndDate: Date?
    @State private var timeRemaining: TimeInterval = 0
    @State private var showingTimerAlert = false
    @State private var commandCheckTimer: Timer?
    
    enum PatternSpeed: String, CaseIterable {
        case slow = "Slow"
        case medium = "Medium"
        case fast = "Fast"
        
        var multiplier: Double {
            switch self {
            case .slow: return 2.0      // 2x slower (longer delays)
            case .medium: return 1.0    // Normal speed
            case .fast: return 0.5      // 2x faster (shorter delays)
            }
        }
    }
    
    enum AutoOffTimer: String, CaseIterable {
        case off = "Off"
        case fifteenMin = "15 min"
        case thirtyMin = "30 min"
        case oneHour = "1 hour"
        case twoHours = "2 hours"
        
        var duration: TimeInterval {
            switch self {
            case .off: return 0
            case .fifteenMin: return 15 * 60
            case .thirtyMin: return 30 * 60
            case .oneHour: return 60 * 60
            case .twoHours: return 120 * 60
            }
        }
        
        var icon: String {
            switch self {
            case .off: return "timer.slash"
            case .fifteenMin, .thirtyMin: return "timer"
            case .oneHour, .twoHours: return "clock"
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color(.systemBackground), Color(.systemGray6)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        if bluetoothManager.isConnected {
                            // Quick Actions Row
                            QuickActionsRow(
                                onAllOff: {
                                    HapticManager.shared.impact(.medium)
                                    selectedPattern = nil
                                    selectedColor = .black // Black represents "off" state
                                    bluetoothManager.setColor(red: 0, green: 0, blue: 0)
                                },
                                onAllWhite: {
                                    HapticManager.shared.impact(.medium)
                                    selectedPattern = "SOLID"
                                    selectedColor = .white
                                    bluetoothManager.setPattern("SOLID")
                                    bluetoothManager.setColor(red: 255, green: 255, blue: 255)
                                }
                            )

                            // Preset Colors (Primary Focus)
                            PresetColorsCard(
                                selectedColor: selectedColor,
                                onColorSelect: { color in
                                    HapticManager.shared.selection()
                                    selectedColor = color

                                    // Send color command - keeps current pattern active
                                    let rgb = color.rgbComponents
                                    bluetoothManager.setColor(
                                        red: Int(rgb.red * 255),
                                        green: Int(rgb.green * 255),
                                        blue: Int(rgb.blue * 255)
                                    )
                                }
                            )

                            // Patterns (color-agnostic)
                            PatternsCard(
                                selectedPattern: selectedPattern,
                                onPatternSelect: { pattern in
                                    HapticManager.shared.impact(.light)
                                    selectedPattern = pattern
                                    bluetoothManager.setPattern(pattern)
                                }
                            )
                            
                            // Effects (color-changing)
                            EffectsCard(
                                selectedPattern: selectedPattern,
                                onPatternSelect: { pattern in
                                    HapticManager.shared.impact(.medium)
                                    selectedPattern = pattern
                                    bluetoothManager.setPattern(pattern)
                                }
                            )
                            
                            // Pattern Speed Control
                            PatternSpeedCard(
                                speed: $patternSpeed,
                                onSpeedChange: { speed in
                                    HapticManager.shared.selection()
                                    bluetoothManager.setSpeed(speed.multiplier)
                                }
                            )

                            // Brightness Control
                            BrightnessCard(
                                brightness: $brightness,
                                onBrightnessChange: { value in
                                    bluetoothManager.setBrightness(Int(value))
                                }
                            )
                            
                            // Auto-Off Timer
                            AutoOffTimerCard(
                                selectedTimer: $autoOffTimer,
                                timeRemaining: timeRemaining,
                                onTimerChange: { timer in
                                    HapticManager.shared.impact(.light)
                                    startTimer(timer)
                                }
                            )

                            // Advanced: Custom Color Picker
                            CustomColorCard(
                                selectedColor: $selectedColor,
                                onColorChange: { color in
                                    selectedColor = color
                                    // If no pattern is active, default to SOLID
                                    if selectedPattern == nil {
                                        selectedPattern = "SOLID"
                                        bluetoothManager.setPattern("SOLID")
                                    }
                                    let rgb = color.rgbComponents
                                    bluetoothManager.setColor(
                                        red: Int(rgb.red * 255),
                                        green: Int(rgb.green * 255),
                                        blue: Int(rgb.blue * 255)
                                    )
                                }
                            )
                        } else {
                            // Not connected placeholder
                            NotConnectedPlaceholder()
                        }
                    }
                    .padding()
                }
                .refreshable {
                    await reconnect()
                }
            }
            .navigationTitle("Jeep LEDs")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showingDeviceList) {
                DeviceListSheet(bluetoothManager: bluetoothManager)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(bluetoothManager: bluetoothManager)
            }
            .alert("Auto-Off Timer", isPresented: $showingTimerAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                if timeRemaining <= 60 && timeRemaining > 0 {
                    Text("LEDs will turn off in 1 minute")
                } else if timeRemaining <= 0 {
                    Text("Auto-off timer expired. LEDs have been turned off.")
                }
            }
            .onChange(of: deepLinkHandler.activeLink) { _, newLink in
                if let link = newLink {
                    deepLinkHandler.process(link, viewModel: self)
                }
            }
            .onChange(of: selectedColor) { _, _ in
                updateSharedState()
            }
            .onChange(of: selectedPattern) { _, _ in
                updateSharedState()
            }
            .onChange(of: bluetoothManager.isConnected) { _, isConnected in
                updateSharedState()
                if isConnected {
                    // Success haptic for connection
                    HapticManager.shared.notification(.success)
                    // Process any pending widget commands when connection is established
                    processPendingCommands()
                } else {
                    // Warning haptic for disconnection
                    HapticManager.shared.notification(.warning)
                }
            }
            .onAppear {
                updateSharedState()
                // Process any pending widget commands
                processPendingCommands()
                
                // Start periodic check for widget commands (every 1 second for faster response)
                commandCheckTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                    processPendingCommands()
                }
                
                // Also check when app becomes active from background
                NotificationCenter.default.addObserver(
                    forName: UIApplication.willEnterForegroundNotification,
                    object: nil,
                    queue: .main
                ) { _ in
                    print("🔄 App entering foreground - checking for widget commands")
                    processPendingCommands()
                }
            }
            .onDisappear {
                // Stop the command check timer when view disappears
                commandCheckTimer?.invalidate()
                commandCheckTimer = nil
                
                // Remove notification observers
                NotificationCenter.default.removeObserver(self)
            }
        }
    }
    
    // Pull-to-refresh reconnection
    private func reconnect() async {
        if !bluetoothManager.isConnected {
            bluetoothManager.startScanning()
            // Give it time to scan and potentially reconnect
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            bluetoothManager.stopScanning()
        }
    }
    
    // MARK: - Auto-Off Timer Functions
    
    private func startTimer(_ timer: AutoOffTimer) {
        if timer == .off {
            // Cancel timer
            timerEndDate = nil
            timeRemaining = 0
            return
        }
        
        // Start new timer
        timerEndDate = Date().addingTimeInterval(timer.duration)
        timeRemaining = timer.duration
        
        // Start countdown
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { t in
            guard let endDate = timerEndDate else {
                t.invalidate()
                return
            }
            
            let remaining = endDate.timeIntervalSinceNow
            
            if remaining <= 0 {
                // Timer expired
                t.invalidate()
                handleTimerExpired()
            } else {
                timeRemaining = remaining
                
                // Show warning at 1 minute remaining
                if remaining <= 60 && remaining > 59 && !showingTimerAlert {
                    showTimerWarning()
                }
            }
        }
    }
    
    private func handleTimerExpired() {
        // Strong haptic for timer expiration
        HapticManager.shared.notification(.warning)
        
        // Turn off LEDs
        selectedPattern = nil
        selectedColor = .black
        bluetoothManager.setColor(red: 0, green: 0, blue: 0)
        
        // Reset timer
        autoOffTimer = .off
        timerEndDate = nil
        timeRemaining = 0
        
        // Show notification
        showTimerExpiredNotification()
    }
    
    private func showTimerWarning() {
        // Gentle haptic for 1-minute warning
        HapticManager.shared.notification(.warning)
        
        showingTimerAlert = true
        
        // Auto-dismiss alert after showing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            showingTimerAlert = false
        }
    }
    
    private func showTimerExpiredNotification() {
        // This will be shown via the alert modifier
        // For now, we'll just use a simple approach
    }
    
    // MARK: - Deep Link Actions
    
    func turnOff() {
        selectedPattern = nil
        selectedColor = .black
        bluetoothManager.setColor(red: 0, green: 0, blue: 0)
        updateSharedState()
    }

    func setColor(name: String) {
        let colorMap: [String: Color] = [
            "red": Color(red: 1.0, green: 0.0, blue: 0.0),
            "orange": Color(red: 1.0, green: 0.5, blue: 0.0),
            "yellow": Color(red: 1.0, green: 1.0, blue: 0.0),
            "green": Color(red: 0.0, green: 1.0, blue: 0.0),
            "cyan": Color(red: 0.0, green: 1.0, blue: 1.0),
            "blue": Color(red: 0.0, green: 0.0, blue: 1.0),
            "purple": Color(red: 0.5, green: 0.0, blue: 1.0),
            "pink": Color(red: 1.0, green: 0.0, blue: 0.5),
            "white": .white
        ]

        guard let color = colorMap[name.lowercased()] else { return }

        selectedColor = color
        if selectedPattern == nil {
            selectedPattern = "SOLID"
            bluetoothManager.setPattern("SOLID")
        }

        let rgb = color.rgbComponents
        bluetoothManager.setColor(
            red: Int(rgb.red * 255),
            green: Int(rgb.green * 255),
            blue: Int(rgb.blue * 255)
        )
        updateSharedState()
    }

    func setPattern(name: String) {
        selectedPattern = name.uppercased()
        bluetoothManager.setPattern(name.uppercased())
        updateSharedState()
    }

    func setEmergency() {
        selectedPattern = "HAZARD"
        bluetoothManager.setPattern("HAZARD")
        updateSharedState()
    }

    func updateSharedState() {
        let rgb = selectedColor.rgbComponents
        let state = LEDState(
            isOn: selectedColor != .black,
            colorName: getColorName(selectedColor),
            colorRed: rgb.red,
            colorGreen: rgb.green,
            colorBlue: rgb.blue,
            pattern: selectedPattern ?? "SOLID",
            brightness: Int(brightness),
            speed: patternSpeed.rawValue,
            isConnected: bluetoothManager.isConnected,
            lastUpdated: Date()
        )
        SharedLEDStateManager.shared.saveState(state)
    }
    
    // Check for pending commands from widgets/Siri
    func processPendingCommands() {
        print("🔍 Checking for pending commands... (BT connected: \(bluetoothManager.isConnected))")
        
        guard bluetoothManager.isConnected else {
            print("⚠️ Cannot process pending commands - not connected to Bluetooth")
            return
        }
        
        if let command = SharedLEDStateManager.shared.getPendingCommand() {
            print("🎯 Processing widget command: \(command)")
            
            if command == "OFF" {
                print("   Executing: Turn off LEDs")
                turnOff()
            } else if command.hasPrefix("COLOR:") {
                let components = command.replacingOccurrences(of: "COLOR:", with: "").split(separator: ",")
                if components.count == 3,
                   let r = Int(components[0]),
                   let g = Int(components[1]),
                   let b = Int(components[2]) {
                    print("   Executing: Set color to RGB(\(r),\(g),\(b))")
                    
                    // Update UI
                    selectedColor = Color(red: Double(r)/255.0, green: Double(g)/255.0, blue: Double(b)/255.0)
                    selectedPattern = "SOLID"
                    
                    // Send Bluetooth commands
                    bluetoothManager.setPattern("SOLID")
                    bluetoothManager.setColor(red: r, green: g, blue: b)
                }
            } else if command.hasPrefix("PATTERN:") {
                let pattern = command.replacingOccurrences(of: "PATTERN:", with: "")
                print("   Executing: Set pattern to \(pattern)")
                
                // Update UI
                selectedPattern = pattern
                
                // Send Bluetooth command
                bluetoothManager.setPattern(pattern)
            }
        } else {
            print("ℹ️ No pending commands to process")
        }
    }

    private func getColorName(_ color: Color) -> String {
        let rgb = color.rgbComponents

        if rgb.red == 0 && rgb.green == 0 && rgb.blue == 0 {
            return "Off"
        } else if rgb.red > 0.9 && rgb.green < 0.1 && rgb.blue < 0.1 {
            return "Red"
        } else if rgb.red < 0.1 && rgb.green < 0.1 && rgb.blue > 0.9 {
            return "Blue"
        } else if rgb.red < 0.1 && rgb.green > 0.9 && rgb.blue < 0.1 {
            return "Green"
        } else if rgb.red > 0.9 && rgb.green > 0.4 && rgb.blue < 0.1 {
            return "Orange"
        } else if rgb.red > 0.9 && rgb.green > 0.9 && rgb.blue < 0.1 {
            return "Yellow"
        } else if rgb.red < 0.1 && rgb.green > 0.9 && rgb.blue > 0.9 {
            return "Cyan"
        } else if rgb.red > 0.4 && rgb.green < 0.1 && rgb.blue > 0.9 {
            return "Purple"
        } else if rgb.red > 0.9 && rgb.green < 0.1 && rgb.blue > 0.4 {
            return "Pink"
        } else if rgb.red > 0.9 && rgb.green > 0.9 && rgb.blue > 0.9 {
            return "White"
        } else {
            return "Custom"
        }
    }
}

// MARK: - Connection Status Card
struct ConnectionStatusCard: View {
    let isConnected: Bool
    let statusMessage: String
    @Binding var showingDeviceList: Bool

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isConnected ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                        .frame(width: 40, height: 40)
                    Circle()
                        .fill(isConnected ? Color.green : Color.red)
                        .frame(width: 16, height: 16)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(isConnected ? "Connected" : "Not Connected")
                        .font(.headline)
                    Text(statusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            Button(action: { showingDeviceList = true }) {
                HStack {
                    Image(systemName: isConnected ? "antenna.radiowaves.left.and.right.circle.fill" : "antenna.radiowaves.left.and.right")
                    Text(isConnected ? "Change Device" : "Connect")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isConnected ? Color.blue : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
    }
}

// MARK: - Quick Actions Row
struct QuickActionsRow: View {
    let onAllOff: () -> Void
    let onAllWhite: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            QuickActionButton(
                icon: "power",
                title: "Off",
                color: .gray,
                action: onAllOff
            )

            QuickActionButton(
                icon: "light.max",
                title: "White",
                color: .orange,
                action: onAllWhite
            )
        }
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .cornerRadius(12)
        }
    }
}

// MARK: - Preset Colors Card
struct PresetColorsCard: View {
    let selectedColor: Color
    let onColorSelect: (Color) -> Void

    let presetColors: [(name: String, color: Color)] = [
        ("Red", Color(red: 1.0, green: 0.0, blue: 0.0)),        // Pure red: 255,0,0
        ("Orange", Color(red: 1.0, green: 0.5, blue: 0.0)),     // Pure orange: 255,127,0
        ("Yellow", Color(red: 1.0, green: 1.0, blue: 0.0)),     // Pure yellow: 255,255,0
        ("Green", Color(red: 0.0, green: 1.0, blue: 0.0)),      // Pure green: 0,255,0
        ("Cyan", Color(red: 0.0, green: 1.0, blue: 1.0)),       // Pure cyan: 0,255,255
        ("Blue", Color(red: 0.0, green: 0.0, blue: 1.0)),       // Pure blue: 0,0,255
        ("Purple", Color(red: 0.5, green: 0.0, blue: 1.0)),     // Pure purple: 127,0,255
        ("Pink", Color(red: 1.0, green: 0.0, blue: 0.5))        // Pure pink: 255,0,127
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "paintpalette.fill")
                    .foregroundStyle(.blue)
                Text("Colors")
                    .font(.title3)
                    .fontWeight(.semibold)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 70))], spacing: 16) {
                ForEach(presetColors, id: \.name) { preset in
                    ColorButton(
                        name: preset.name,
                        color: preset.color,
                        isSelected: colorsMatch(selectedColor, preset.color),
                        action: { onColorSelect(preset.color) }
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
    }

    func colorsMatch(_ c1: Color, _ c2: Color) -> Bool {
        let rgb1 = c1.rgbComponents
        let rgb2 = c2.rgbComponents
        return abs(rgb1.red - rgb2.red) < 0.01 &&
               abs(rgb1.green - rgb2.green) < 0.01 &&
               abs(rgb1.blue - rgb2.blue) < 0.01
    }
}

struct ColorButton: View {
    let name: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(color)
                        .frame(width: 56, height: 56)
                        .overlay(
                            Circle()
                                .strokeBorder(isSelected ? Color.primary : Color.clear, lineWidth: 3)
                        )
                        .shadow(color: color.opacity(0.4), radius: isSelected ? 8 : 4)

                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .shadow(radius: 2)
                    }
                }

                Text(name)
                    .font(.caption2)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(.primary)
            }
        }
    }
}

// MARK: - Patterns Card (color-agnostic)
struct PatternsCard: View {
    let selectedPattern: String?
    let onPatternSelect: (String) -> Void

    let patterns = [
        (name: "Solid", code: "SOLID", icon: "circle.fill"),
        (name: "Blink", code: "BLINK", icon: "bolt.fill"),
        (name: "Breathe", code: "BREATHE", icon: "waveform.path.ecg"),
        (name: "Strobe", code: "STROBE", icon: "flashlight.on.fill"),
        (name: "Alternate", code: "ALTERNATE", icon: "arrow.left.arrow.right"),
        (name: "Chase", code: "CHASE", icon: "arrow.right.circle.fill"),
        (name: "Sparkle", code: "SPARKLE", icon: "sparkles"),
        (name: "Fade In/Out", code: "FADE", icon: "circle.lefthalf.filled"),
        (name: "Running", code: "RUNNING", icon: "figure.run")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "wand.and.stars")
                    .foregroundStyle(.purple)
                Text("Patterns")
                    .font(.title3)
                    .fontWeight(.semibold)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                ForEach(patterns, id: \.code) { pattern in
                    PatternButton(
                        name: pattern.name,
                        icon: pattern.icon,
                        isSelected: selectedPattern == pattern.code,
                        accentColor: .purple,
                        action: { onPatternSelect(pattern.code) }
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
    }
}

// MARK: - Effects Card (color-changing)
struct EffectsCard: View {
    let selectedPattern: String?
    let onPatternSelect: (String) -> Void

    let effects = [
        (name: "Rainbow", code: "RAINBOW", icon: "rainbow"),
        (name: "Police", code: "POLICE", icon: "light.beacon.max.fill"),
        (name: "Hazard", code: "HAZARD", icon: "exclamationmark.triangle.fill")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(.pink)
                Text("Effects")
                    .font(.title3)
                    .fontWeight(.semibold)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                ForEach(effects, id: \.code) { effect in
                    PatternButton(
                        name: effect.name,
                        icon: effect.icon,
                        isSelected: selectedPattern == effect.code,
                        accentColor: .pink,
                        action: { onPatternSelect(effect.code) }
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
    }
}

// MARK: - Pattern Speed Card
struct PatternSpeedCard: View {
    @Binding var speed: ContentView.PatternSpeed
    let onSpeedChange: (ContentView.PatternSpeed) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "gauge.with.dots.needle.67percent")
                    .foregroundStyle(.cyan)
                Text("Pattern Speed")
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            
            HStack(spacing: 12) {
                ForEach(ContentView.PatternSpeed.allCases, id: \.self) { speedOption in
                    SpeedButton(
                        level: speedOption.rawValue,
                        icon: iconForSpeed(speedOption),
                        isSelected: speed == speedOption,
                        action: {
                            speed = speedOption
                            onSpeedChange(speedOption)
                        }
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
    }
    
    private func iconForSpeed(_ speed: ContentView.PatternSpeed) -> String {
        switch speed {
        case .slow: return "tortoise.fill"
        case .medium: return "hare.fill"
        case .fast: return "bolt.fill"
        }
    }
}

struct SpeedButton: View {
    let level: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(level)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isSelected ? Color.cyan : Color.cyan.opacity(0.1))
            .foregroundColor(isSelected ? .white : .cyan)
            .cornerRadius(10)
        }
    }
}

struct PatternButton: View {
    let name: String
    let icon: String
    let isSelected: Bool
    let accentColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                Text(name)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isSelected ? accentColor : accentColor.opacity(0.1))
            .foregroundColor(isSelected ? .white : accentColor)
            .cornerRadius(10)
        }
    }
}

// MARK: - Brightness Card
struct BrightnessCard: View {
    @Binding var brightness: Double
    let onBrightnessChange: (Double) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "sun.max.fill")
                    .foregroundStyle(.orange)
                Text("Brightness")
                    .font(.title3)
                    .fontWeight(.semibold)
            }

            HStack(spacing: 12) {
                BrightnessButton(
                    level: "Low",
                    icon: "sun.min",
                    value: 85,
                    currentBrightness: brightness,
                    action: {
                        brightness = 85
                        onBrightnessChange(85)
                    }
                )
                
                BrightnessButton(
                    level: "Medium",
                    icon: "sun.max",
                    value: 170,
                    currentBrightness: brightness,
                    action: {
                        brightness = 170
                        onBrightnessChange(170)
                    }
                )
                
                BrightnessButton(
                    level: "High",
                    icon: "sun.max.fill",
                    value: 255,
                    currentBrightness: brightness,
                    action: {
                        brightness = 255
                        onBrightnessChange(255)
                    }
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
    }
}

struct BrightnessButton: View {
    let level: String
    let icon: String
    let value: Double
    let currentBrightness: Double
    let action: () -> Void
    
    var isSelected: Bool {
        abs(currentBrightness - value) < 10
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(level)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isSelected ? Color.orange : Color.orange.opacity(0.1))
            .foregroundColor(isSelected ? .white : .orange)
            .cornerRadius(10)
        }
    }
}

// MARK: - Auto-Off Timer Card
struct AutoOffTimerCard: View {
    @Binding var selectedTimer: ContentView.AutoOffTimer
    let timeRemaining: TimeInterval
    let onTimerChange: (ContentView.AutoOffTimer) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "timer")
                    .foregroundStyle(.red)
                Text("Auto-Off Timer")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // Show remaining time if timer is active
                if selectedTimer != .off && timeRemaining > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.caption)
                        Text(formatTimeRemaining(timeRemaining))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .monospacedDigit()
                    }
                    .foregroundStyle(.red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))], spacing: 12) {
                ForEach(ContentView.AutoOffTimer.allCases, id: \.self) { timer in
                    TimerButton(
                        label: timer.rawValue,
                        icon: timer.icon,
                        isSelected: selectedTimer == timer,
                        isActive: selectedTimer == timer && timeRemaining > 0,
                        action: {
                            selectedTimer = timer
                            onTimerChange(timer)
                        }
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
    }
    
    private func formatTimeRemaining(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }
}

struct TimerButton: View {
    let label: String
    let icon: String
    let isSelected: Bool
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(isActive ? Color.red : Color.clear, lineWidth: 2)
            )
        }
    }
    
    private var backgroundColor: Color {
        if isActive {
            return Color.red
        } else if isSelected {
            return Color.red.opacity(0.2)
        } else {
            return Color.red.opacity(0.1)
        }
    }
    
    private var foregroundColor: Color {
        isActive ? .white : .red
    }
}

// MARK: - Custom Color Card
struct CustomColorCard: View {
    @Binding var selectedColor: Color
    let onColorChange: (Color) -> Void
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack {
                    Image(systemName: "eyedropper.halffull")
                        .foregroundStyle(.indigo)
                    Text("Custom Color")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundStyle(.secondary)
                }
            }

            if isExpanded {
                VStack(spacing: 12) {
                    ColorPicker("Pick any color", selection: $selectedColor, supportsOpacity: false)
                        .onChange(of: selectedColor) { _, newColor in
                            onColorChange(newColor)
                        }

                    RoundedRectangle(cornerRadius: 12)
                        .fill(selectedColor)
                        .frame(height: 80)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
    }
}

// MARK: - Not Connected Placeholder
struct NotConnectedPlaceholder: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "antenna.radiowaves.left.and.right.slash")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("Not Connected")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Connect to your Adafruit Bluefruit module to control your Jeep's LED lights")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
    }
}

// MARK: - Device List Sheet
struct DeviceListSheet: View {
    @ObservedObject var bluetoothManager: BluetoothManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if bluetoothManager.discoveredDevices.isEmpty {
                    ContentUnavailableView(
                        "No Devices Found",
                        systemImage: "antenna.radiowaves.left.and.right",
                        description: Text("Make sure your Bluefruit module is powered on and in range")
                    )
                } else {
                    ForEach(bluetoothManager.discoveredDevices, id: \.identifier) { device in
                        Button(action: {
                            HapticManager.shared.impact(.medium)
                            bluetoothManager.connect(to: device)
                            dismiss()
                        }) {
                            HStack(spacing: 16) {
                                Image(systemName: "cpu")
                                    .font(.title2)
                                    .foregroundStyle(.blue)
                                    .frame(width: 40)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(device.name ?? "Unknown Device")
                                        .font(.headline)
                                    Text(device.identifier.uuidString)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
            }
            .navigationTitle("Available Devices")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        bluetoothManager.stopScanning()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        bluetoothManager.startScanning()
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Scan")
                        }
                    }
                }
            }
            .onAppear {
                bluetoothManager.startScanning()
            }
            .onDisappear {
                bluetoothManager.stopScanning()
            }
        }
    }
}

// MARK: - Color Extension for RGB Components
extension Color {
    var rgbComponents: (red: Double, green: Double, blue: Double) {
        #if canImport(UIKit)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        UIColor(self).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return (Double(red), Double(green), Double(blue))
        #else
        return (0, 0, 0)
        #endif
    }
    

}

#Preview {
    ContentView()
}
