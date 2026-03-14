//
//  Jeep_LED_Widget.swift
//  Jeep LED Widget
//
//  Widget for controlling Jeep LEDs from home screen
//

import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Timeline Provider
struct LEDWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> LEDWidgetEntry {
        LEDWidgetEntry(date: Date(), state: .default)
    }

    func getSnapshot(in context: Context, completion: @escaping (LEDWidgetEntry) -> Void) {
        let state = SharedLEDStateManager.shared.loadState()
        let entry = LEDWidgetEntry(date: Date(), state: state)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LEDWidgetEntry>) -> Void) {
        let state = SharedLEDStateManager.shared.loadState()
        let entry = LEDWidgetEntry(date: Date(), state: state)

        // Update every 5 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))

        completion(timeline)
    }
}

// MARK: - Widget Entry
struct LEDWidgetEntry: TimelineEntry {
    let date: Date
    let state: LEDState
}

// MARK: - Widget View
struct LEDWidgetView: View {
    var entry: LEDWidgetProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(state: entry.state)
        case .systemMedium:
            MediumWidgetView(state: entry.state)
        case .systemLarge:
            LargeWidgetView(state: entry.state)
        default:
            SmallWidgetView(state: entry.state)
        }
    }
}

// MARK: - Small Widget (Status Only)
struct SmallWidgetView: View {
    let state: LEDState

    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(LinearGradient(
                    colors: [Color(.systemGray6), Color(.systemGray5)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))

            VStack(spacing: 8) {
                // Status Icon
                Image(systemName: state.isOn ? "lightbulb.fill" : "lightbulb.slash.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(state.isOn ? ledColor : .gray)
                    .symbolEffect(.pulse, isActive: state.isOn)

                // Status Text
                Text(state.isOn ? state.colorName : "Off")
                    .font(.subheadline)
                    .fontWeight(.bold)

                if state.isOn {
                    Text(state.pattern)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer().frame(height: 4)

                // Connection Status
                HStack(spacing: 3) {
                    Circle()
                        .fill(state.isConnected ? Color.green : Color.red)
                        .frame(width: 5, height: 5)
                    Text(state.isConnected ? "Connected" : "Disconnected")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(12)
        }
    }

    var ledColor: Color {
        Color(red: state.colorRed, green: state.colorGreen, blue: state.colorBlue)
    }
}

// MARK: - Medium Widget (Status + Quick Actions)
struct MediumWidgetView: View {
    let state: LEDState

    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(LinearGradient(
                    colors: [Color(.systemGray6), Color(.systemGray5)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))

            HStack(spacing: 0) {
                // Left: Status
                VStack(spacing: 6) {
                    Image(systemName: state.isOn ? "lightbulb.fill" : "lightbulb.slash.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(state.isOn ? ledColor : .gray)
                        .symbolEffect(.pulse, isActive: state.isOn)

                    Text(state.isOn ? state.colorName : "Off")
                        .font(.subheadline)
                        .fontWeight(.bold)

                    if state.isOn {
                        Text(state.pattern)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 3) {
                        Circle()
                            .fill(state.isConnected ? Color.green : Color.red)
                            .frame(width: 5, height: 5)
                        Text(state.isConnected ? "•" : "•")
                            .font(.system(size: 9))
                            .foregroundStyle(state.isConnected ? .green : .red)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)

                // Right: Quick Actions
                VStack(spacing: 8) {
                    Button(intent: TurnOffIntent()) {
                        VStack(spacing: 4) {
                            Image(systemName: "power")
                                .font(.title2)
                            Text("Off")
                                .font(.caption2)
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.gray)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)

                    Button(intent: EmergencyIntent()) {
                        VStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.title2)
                            Text("Emergency")
                                .font(.caption2)
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(Color.red.opacity(0.2))
                        .foregroundColor(.red)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .padding(.trailing, 12)
            }
        }
    }

    var ledColor: Color {
        Color(red: state.colorRed, green: state.colorGreen, blue: state.colorBlue)
    }
}

// MARK: - Large Widget (Full Controls)
struct LargeWidgetView: View {
    let state: LEDState

    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(LinearGradient(
                    colors: [Color(.systemGray6), Color(.systemGray5)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))

            VStack(spacing: 12) {
                // Header: Status
                HStack {
                    Image(systemName: state.isOn ? "lightbulb.fill" : "lightbulb.slash.fill")
                        .font(.title3)
                        .foregroundStyle(state.isOn ? ledColor : .gray)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(state.isOn ? state.colorName : "Off")
                            .font(.subheadline)
                            .fontWeight(.bold)
                        if state.isOn {
                            Text("\(state.pattern) • \(state.speed)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    HStack(spacing: 3) {
                        Circle()
                            .fill(state.isConnected ? Color.green : Color.red)
                            .frame(width: 6, height: 6)
                        Text(state.isConnected ? "Connected" : "Disconnected")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                // Color Presets
                VStack(alignment: .leading, spacing: 6) {
                    Text("Colors")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 16)

                    HStack(spacing: 8) {
                        Button(intent: SetColorIntent(color: .red)) {
                            ColorButtonView(name: "Red", color: .red)
                        }
                        .buttonStyle(.plain)

                        Button(intent: SetColorIntent(color: .blue)) {
                            ColorButtonView(name: "Blue", color: .blue)
                        }
                        .buttonStyle(.plain)

                        Button(intent: SetColorIntent(color: .green)) {
                            ColorButtonView(name: "Green", color: .green)
                        }
                        .buttonStyle(.plain)

                        Button(intent: SetColorIntent(color: .white)) {
                            ColorButtonView(name: "White", color: .white)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                }

                // Quick Patterns
                VStack(alignment: .leading, spacing: 6) {
                    Text("Patterns")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 16)

                    HStack(spacing: 8) {
                        Button(intent: SetPatternIntent(pattern: .police)) {
                            PatternButtonView(name: "Police", icon: "light.beacon.max.fill", color: .red)
                        }
                        .buttonStyle(.plain)

                        Button(intent: SetPatternIntent(pattern: .hazard)) {
                            PatternButtonView(name: "Hazard", icon: "exclamationmark.triangle.fill", color: .orange)
                        }
                        .buttonStyle(.plain)

                        Button(intent: SetPatternIntent(pattern: .rainbow)) {
                            PatternButtonView(name: "Rainbow", icon: "rainbow", color: .purple)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 12)
            }
        }
    }

    var ledColor: Color {
        Color(red: state.colorRed, green: state.colorGreen, blue: state.colorBlue)
    }
}

// MARK: - Helper Views
struct ColorButtonView: View {
    let name: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 28, height: 28)
                .overlay(
                    Circle()
                        .strokeBorder(Color.white.opacity(0.3), lineWidth: 2)
                )
            Text(name)
                .font(.system(size: 10))
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct PatternButtonView: View {
    let name: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(name)
                .font(.system(size: 10))
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Widget Configuration
struct Jeep_LED_Widget: Widget {
    let kind: String = "Jeep_LED_Widget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LEDWidgetProvider()) { entry in
            if #available(iOS 17.0, *) {
                LEDWidgetView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                LEDWidgetView(entry: entry)
            }
        }
        .configurationDisplayName("Jeep LEDs")
        .description("Control your Jeep underglow LEDs")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - App Intents for Widget Buttons

struct TurnOffIntent: AppIntent {
    static var title: LocalizedStringResource = "Turn Off LEDs"
    static var openAppWhenRun: Bool = true  // This will open the app!

    func perform() async throws -> some IntentResult {
        SharedLEDStateManager.shared.turnOff()
        return .result()
    }
}

struct EmergencyIntent: AppIntent {
    static var title: LocalizedStringResource = "Emergency Mode"
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        SharedLEDStateManager.shared.setPattern("HAZARD")
        return .result()
    }
}

struct SetColorIntent: AppIntent {
    static var title: LocalizedStringResource = "Set Color"
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Color")
    var color: WidgetColorOption

    init() {}

    init(color: WidgetColorOption) {
        self.color = color
    }

    func perform() async throws -> some IntentResult {
        let (r, g, b) = color.rgbValues
        SharedLEDStateManager.shared.setColor(
            name: color.rawValue,
            red: r,
            green: g,
            blue: b
        )
        return .result()
    }
}

struct SetPatternIntent: AppIntent {
    static var title: LocalizedStringResource = "Set Pattern"
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Pattern")
    var pattern: WidgetPatternOption

    init() {}

    init(pattern: WidgetPatternOption) {
        self.pattern = pattern
    }

    func perform() async throws -> some IntentResult {
        SharedLEDStateManager.shared.setPattern(pattern.rawValue)
        return .result()
    }
}

// MARK: - Widget Options
enum WidgetColorOption: String, AppEnum {
    case red = "Red"
    case blue = "Blue"
    case green = "Green"
    case white = "White"

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Color")
    static var caseDisplayRepresentations: [WidgetColorOption: DisplayRepresentation] = [
        .red: "Red",
        .blue: "Blue",
        .green: "Green",
        .white: "White"
    ]

    var rgbValues: (Double, Double, Double) {
        switch self {
        case .red: return (1.0, 0.0, 0.0)
        case .blue: return (0.0, 0.0, 1.0)
        case .green: return (0.0, 1.0, 0.0)
        case .white: return (1.0, 1.0, 1.0)
        }
    }
}

enum WidgetPatternOption: String, AppEnum {
    case police = "POLICE"
    case hazard = "HAZARD"
    case rainbow = "RAINBOW"

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Pattern")
    static var caseDisplayRepresentations: [WidgetPatternOption: DisplayRepresentation] = [
        .police: "Police",
        .hazard: "Hazard",
        .rainbow: "Rainbow"
    ]
}

// MARK: - Preview
#Preview(as: .systemSmall) {
    Jeep_LED_Widget()
} timeline: {
    LEDWidgetEntry(date: .now, state: .default)
}

#Preview(as: .systemMedium) {
    Jeep_LED_Widget()
} timeline: {
    LEDWidgetEntry(date: .now, state: LEDState(
        isOn: true,
        colorName: "Red",
        colorRed: 1.0,
        colorGreen: 0.0,
        colorBlue: 0.0,
        pattern: "BLINK",
        brightness: 255,
        speed: "Medium",
        isConnected: true,
        lastUpdated: Date()
    ))
}

#Preview(as: .systemLarge) {
    Jeep_LED_Widget()
} timeline: {
    LEDWidgetEntry(date: .now, state: LEDState(
        isOn: true,
        colorName: "Blue",
        colorRed: 0.0,
        colorGreen: 0.0,
        colorBlue: 1.0,
        pattern: "SOLID",
        brightness: 255,
        speed: "Fast",
        isConnected: true,
        lastUpdated: Date()
    ))
}
