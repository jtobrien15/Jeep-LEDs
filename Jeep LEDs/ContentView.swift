//
//  ContentView.swift
//  Jeep LEDs
//
//  Created by voyager on 2/22/26.
//

import SwiftUI
import CoreBluetooth

struct ContentView: View {
    @StateObject private var bluetoothManager = BluetoothManager()
    @State private var selectedColor = Color.red
    @State private var brightness: Double = 255
    @State private var showingDeviceList = false
    @State private var showingSettings = false
    @State private var selectedPattern: String? = nil

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
                                    selectedPattern = nil
                                    bluetoothManager.setColor(red: 0, green: 0, blue: 0)
                                },
                                onAllWhite: {
                                    selectedPattern = nil
                                    selectedColor = .white
                                    bluetoothManager.setColor(red: 255, green: 255, blue: 255)
                                }
                            )

                            // Preset Colors (Primary Focus)
                            PresetColorsCard(
                                selectedColor: selectedColor,
                                onColorSelect: { color in
                                    selectedColor = color
                                    selectedPattern = nil
                                    let rgb = color.rgbComponents
                                    bluetoothManager.setColor(
                                        red: Int(rgb.red * 255),
                                        green: Int(rgb.green * 255),
                                        blue: Int(rgb.blue * 255)
                                    )
                                }
                            )

                            // Pattern Controls
                            PatternCard(
                                selectedPattern: selectedPattern,
                                selectedColor: selectedColor,
                                onPatternSelect: { pattern in
                                    selectedPattern = pattern
                                    bluetoothManager.setPattern(pattern)
                                }
                            )

                            // Brightness Control
                            BrightnessCard(
                                brightness: $brightness,
                                onBrightnessChange: { value in
                                    bluetoothManager.setBrightness(Int(value))
                                }
                            )

                            // Advanced: Custom Color Picker
                            CustomColorCard(
                                selectedColor: $selectedColor,
                                onColorChange: { color in
                                    selectedColor = color
                                    selectedPattern = nil
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
        ("Red", .red),
        ("Orange", .orange),
        ("Yellow", .yellow),
        ("Green", .green),
        ("Cyan", .cyan),
        ("Blue", .blue),
        ("Purple", .purple),
        ("Pink", .pink)
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

// MARK: - Pattern Card
struct PatternCard: View {
    let selectedPattern: String?
    let selectedColor: Color
    let onPatternSelect: (String) -> Void

    let patterns = [
        (name: "Solid", code: "SOLID", icon: "circle.fill"),
        (name: "Blink", code: "BLINK", icon: "bolt.fill"),
        (name: "Breathe", code: "BREATHE", icon: "waveform.path.ecg"),
        (name: "Strobe", code: "STROBE", icon: "flashlight.on.fill"),
        (name: "Police", code: "POLICE", icon: "light.beacon.max.fill"),
        (name: "Hazard", code: "HAZARD", icon: "exclamationmark.triangle.fill"),
        (name: "Alternate", code: "ALTERNATE", icon: "arrow.left.arrow.right"),
        (name: "Rainbow", code: "RAINBOW", icon: "rainbow"),
        (name: "Chase", code: "CHASE", icon: "arrow.right.circle.fill"),
        (name: "Sparkle", code: "SPARKLE", icon: "sparkles"),
        (name: "Fade In/Out", code: "FADE", icon: "circle.lefthalf.filled"),
        (name: "Running", code: "RUNNING", icon: "figure.run")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "wand.and.stars")
                    .foregroundStyle(selectedColor.visibleAccent)
                Text("Effects")
                    .font(.title3)
                    .fontWeight(.semibold)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                ForEach(patterns, id: \.code) { pattern in
                    PatternButton(
                        name: pattern.name,
                        icon: pattern.icon,
                        isSelected: selectedPattern == pattern.code,
                        accentColor: selectedColor.visibleAccent,
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
    
    var isCloseToWhite: Bool {
        let rgb = rgbComponents
        // Consider it white if all RGB values are above 0.9 (230/255)
        return rgb.red > 0.9 && rgb.green > 0.9 && rgb.blue > 0.9
    }
    
    // Returns black if color is close to white, otherwise returns the color itself
    var visibleAccent: Color {
        isCloseToWhite ? .black : self
    }
}

#Preview {
    ContentView()
}
