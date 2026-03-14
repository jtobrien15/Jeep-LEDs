//
//  DeepLinkHandler.swift
//  Jeep LEDs
//
//  Handles deep links from widgets and Siri shortcuts
//

import Foundation
import SwiftUI
import Combine

enum DeepLink: Equatable {
    case off
    case color(String) // red, blue, green, etc.
    case pattern(String) // police, hazard, rainbow, etc.
    case emergency
    case openApp

    init?(url: URL) {
        guard url.scheme == "jeepleds" else { return nil }

        let host = url.host ?? ""
        let path = url.pathComponents.dropFirst().first ?? ""

        switch host {
        case "off":
            self = .off
        case "emergency":
            self = .emergency
        case "color":
            self = .color(path)
        case "pattern":
            self = .pattern(path)
        default:
            self = .openApp
        }
    }
}

class DeepLinkHandler: ObservableObject {
    @Published var activeLink: DeepLink?

    func handle(_ url: URL) {
        guard let link = DeepLink(url: url) else { return }
        activeLink = link
    }

    func process(_ link: DeepLink, viewModel: ContentView) {
        switch link {
        case .off:
            viewModel.turnOff()

        case .color(let colorName):
            viewModel.setColor(name: colorName)

        case .pattern(let patternName):
            viewModel.setPattern(name: patternName)

        case .emergency:
            viewModel.setEmergency()

        case .openApp:
            break // Just open the app
        }

        // Clear the link
        activeLink = nil
    }
}

// MARK: - Helper Functions for ContentView
// These need to be added directly in ContentView.swift as methods,
// not as extensions, because they access private properties
