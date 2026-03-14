//
//  SiriIntents.swift
//  Jeep LEDs
//
//  Siri Shortcuts and App Intents
//

import Foundation
import AppIntents
import SwiftUI

// MARK: - Turn Off LEDs Intent
struct TurnOffLEDsIntent: AppIntent {
    static var title: LocalizedStringResource = "Turn Off Jeep LEDs"
    static var description = IntentDescription("Turn off the Jeep underglow LEDs")

    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult {
        SharedLEDStateManager.shared.turnOff()
        return .result(dialog: "Jeep LEDs turned off")
    }
}

// MARK: - Set Color Intent
struct SetLEDColorIntent: AppIntent {
    static var title: LocalizedStringResource = "Set Jeep LED Color"
    static var description = IntentDescription("Change the color of the Jeep underglow LEDs")

    static var openAppWhenRun: Bool = false

    @Parameter(title: "Color")
    var color: LEDColorOption

    @MainActor
    func perform() async throws -> some IntentResult {
        let (r, g, b) = color.rgbValues
        SharedLEDStateManager.shared.setColor(
            name: color.rawValue,
            red: r,
            green: g,
            blue: b
        )
        return .result(dialog: "Jeep LEDs set to \(color.rawValue)")
    }
}

// MARK: - Set Pattern Intent
struct SetLEDPatternIntent: AppIntent {
    static var title: LocalizedStringResource = "Set Jeep LED Pattern"
    static var description = IntentDescription("Change the pattern of the Jeep underglow LEDs")

    static var openAppWhenRun: Bool = false

    @Parameter(title: "Pattern")
    var pattern: LEDPatternOption

    @MainActor
    func perform() async throws -> some IntentResult {
        SharedLEDStateManager.shared.setPattern(pattern.rawValue)
        return .result(dialog: "Jeep LED pattern set to \(pattern.rawValue)")
    }
}

// MARK: - Emergency Mode Intent
struct EmergencyModeIntent: AppIntent {
    static var title: LocalizedStringResource = "Activate Emergency LEDs"
    static var description = IntentDescription("Activate emergency hazard pattern on Jeep LEDs")

    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult {
        SharedLEDStateManager.shared.setPattern("HAZARD")
        return .result(dialog: "Emergency hazard lights activated")
    }
}

// MARK: - LED Color Options
enum LEDColorOption: String, AppEnum {
    case red = "Red"
    case orange = "Orange"
    case yellow = "Yellow"
    case green = "Green"
    case cyan = "Cyan"
    case blue = "Blue"
    case purple = "Purple"
    case pink = "Pink"
    case white = "White"

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "LED Color")
    static var caseDisplayRepresentations: [LEDColorOption: DisplayRepresentation] = [
        .red: "Red",
        .orange: "Orange",
        .yellow: "Yellow",
        .green: "Green",
        .cyan: "Cyan",
        .blue: "Blue",
        .purple: "Purple",
        .pink: "Pink",
        .white: "White"
    ]

    var rgbValues: (Double, Double, Double) {
        switch self {
        case .red: return (1.0, 0.0, 0.0)
        case .orange: return (1.0, 0.5, 0.0)
        case .yellow: return (1.0, 1.0, 0.0)
        case .green: return (0.0, 1.0, 0.0)
        case .cyan: return (0.0, 1.0, 1.0)
        case .blue: return (0.0, 0.0, 1.0)
        case .purple: return (0.5, 0.0, 1.0)
        case .pink: return (1.0, 0.0, 0.5)
        case .white: return (1.0, 1.0, 1.0)
        }
    }
}

// MARK: - LED Pattern Options
enum LEDPatternOption: String, AppEnum {
    case solid = "SOLID"
    case blink = "BLINK"
    case breathe = "BREATHE"
    case strobe = "STROBE"
    case police = "POLICE"
    case hazard = "HAZARD"
    case rainbow = "RAINBOW"
    case chase = "CHASE"

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "LED Pattern")
    static var caseDisplayRepresentations: [LEDPatternOption: DisplayRepresentation] = [
        .solid: "Solid",
        .blink: "Blink",
        .breathe: "Breathe",
        .strobe: "Strobe",
        .police: "Police",
        .hazard: "Hazard",
        .rainbow: "Rainbow",
        .chase: "Chase"
    ]
}

// MARK: - App Shortcuts Provider
struct JeepLEDsShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: TurnOffLEDsIntent(),
            phrases: [
                "Turn off my \(.applicationName)",
                "Turn off \(.applicationName)",
                "Disable \(.applicationName)"
            ],
            shortTitle: "Turn Off",
            systemImageName: "power"
        )

        AppShortcut(
            intent: EmergencyModeIntent(),
            phrases: [
                "Activate \(.applicationName) emergency",
                "Turn on \(.applicationName) hazard lights",
                "Emergency mode on \(.applicationName)"
            ],
            shortTitle: "Emergency",
            systemImageName: "exclamationmark.triangle.fill"
        )

        AppShortcut(
            intent: SetLEDColorIntent(),
            phrases: [
                "Set \(.applicationName) to \(\.$color)",
                "Change \(.applicationName) to \(\.$color)",
                "Make \(.applicationName) \(\.$color)"
            ],
            shortTitle: "Set Color",
            systemImageName: "paintpalette.fill"
        )

        AppShortcut(
            intent: SetLEDPatternIntent(),
            phrases: [
                "Set \(.applicationName) pattern to \(\.$pattern)",
                "Change \(.applicationName) to \(\.$pattern)",
                "Run \(.applicationName) \(\.$pattern)"
            ],
            shortTitle: "Set Pattern",
            systemImageName: "wand.and.stars"
        )
    }
}
