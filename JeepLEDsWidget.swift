//
//  JeepLEDsWidget.swift
//  Jeep LEDs Widget
//
//  Widget for controlling Jeep LEDs from home screen
//

import WidgetKit
import SwiftUI

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
            LinearGradient(
                colors: [Color(.systemBackground), Color(.systemGray6)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(spacing: 12) {
                // Status Icon
                Image(systemName: state.isOn ? "lightbulb.fill" : "lightbulb.slash.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(state.isOn ? ledColor : .gray)

                // Status Text
                Text(state.isOn ? state.colorName : "Off")
                    .font(.headline)
                    .fontWeight(.semibold)

                if state.isOn {
                    Text(state.pattern)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                // Connection Status
                HStack(spacing: 4) {
                    Circle()
                        .fill(state.isConnected ? Color.green : Color.red)
                        .frame(width: 6, height: 6)
                    Text(state.isConnected ? "Connected" : "Disconnected")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
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
            LinearGradient(
                colors: [Color(.systemBackground), Color(.systemGray6)],
                startPoint: .top,
                endPoint: .bottom
            )

            HStack(spacing: 16) {
                // Left: Status
                VStack(spacing: 8) {
                    Image(systemName: state.isOn ? "lightbulb.fill" : "lightbulb.slash.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(state.isOn ? ledColor : .gray)

                    Text(state.isOn ? state.colorName : "Off")
                        .font(.headline)
                        .fontWeight(.semibold)

                    if state.isOn {
                        Text(state.pattern)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 4) {
                        Circle()
                            .fill(state.isConnected ? Color.green : Color.red)
                            .frame(width: 6, height: 6)
                        Text(state.isConnected ? "Connected" : "Disconnected")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)

                Divider()

                // Right: Quick Actions
                VStack(spacing: 8) {
                    Text("Quick")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Link(destination: URL(string: "jeepleds://off")!) {
                        QuickActionButton(
                            icon: "power",
                            label: "Off",
                            color: .gray
                        )
                    }

                    Link(destination: URL(string: "jeepleds://emergency")!) {
                        QuickActionButton(
                            icon: "exclamationmark.triangle.fill",
                            label: "Emergency",
                            color: .red
                        )
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
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
            LinearGradient(
                colors: [Color(.systemBackground), Color(.systemGray6)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(spacing: 16) {
                // Header: Status
                HStack {
                    Image(systemName: state.isOn ? "lightbulb.fill" : "lightbulb.slash.fill")
                        .font(.title2)
                        .foregroundStyle(state.isOn ? ledColor : .gray)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(state.isOn ? state.colorName : "Off")
                            .font(.headline)
                        if state.isOn {
                            Text("\(state.pattern) • \(state.speed)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        Circle()
                            .fill(state.isConnected ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                        Text(state.isConnected ? "Connected" : "Disconnected")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Divider()

                // Color Presets
                VStack(alignment: .leading, spacing: 8) {
                    Text("Colors")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        Link(destination: URL(string: "jeepleds://color/red")!) {
                            ColorButton(name: "Red", color: .red)
                        }
                        Link(destination: URL(string: "jeepleds://color/blue")!) {
                            ColorButton(name: "Blue", color: .blue)
                        }
                        Link(destination: URL(string: "jeepleds://color/green")!) {
                            ColorButton(name: "Green", color: .green)
                        }
                    }
                }

                Divider()

                // Quick Patterns
                VStack(alignment: .leading, spacing: 8) {
                    Text("Patterns")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 8) {
                        Link(destination: URL(string: "jeepleds://pattern/police")!) {
                            PatternButton(name: "Police", icon: "light.beacon.max.fill")
                        }
                        Link(destination: URL(string: "jeepleds://pattern/hazard")!) {
                            PatternButton(name: "Hazard", icon: "exclamationmark.triangle.fill")
                        }
                        Link(destination: URL(string: "jeepleds://pattern/rainbow")!) {
                            PatternButton(name: "Rainbow", icon: "rainbow")
                        }
                    }
                }
            }
            .padding()
        }
    }

    var ledColor: Color {
        Color(red: state.colorRed, green: state.colorGreen, blue: state.colorBlue)
    }
}

// MARK: - Helper Views
struct QuickActionButton: View {
    let icon: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
            Text(label)
                .font(.caption2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.15))
        .foregroundColor(color)
        .cornerRadius(8)
    }
}

struct ColorButton: View {
    let name: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 32, height: 32)
            Text(name)
                .font(.caption2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

struct PatternButton: View {
    let name: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
            Text(name)
                .font(.caption2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(Color(.systemBackground))
        .foregroundColor(.primary)
        .cornerRadius(8)
    }
}

// MARK: - Widget Configuration
@main
struct JeepLEDsWidget: Widget {
    let kind: String = "JeepLEDsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LEDWidgetProvider()) { entry in
            LEDWidgetView(entry: entry)
        }
        .configurationDisplayName("Jeep LEDs")
        .description("Control your Jeep underglow LEDs")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Preview
#Preview(as: .systemSmall) {
    JeepLEDsWidget()
} timeline: {
    LEDWidgetEntry(date: .now, state: .default)
}
