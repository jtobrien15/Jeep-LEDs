//
//  Jeep_LEDsApp.swift
//  Jeep LEDs
//
//  Created by voyager on 2/22/26.
//

import SwiftUI
import WidgetKit

@main
struct Jeep_LEDsApp: App {
    @StateObject private var deepLinkHandler = DeepLinkHandler()
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        print("🚀 MAIN APP LAUNCHED")
        print("🚀 This is the MAIN APP, not the widget extension")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(deepLinkHandler)
                .onOpenURL { url in
                    deepLinkHandler.handle(url)
                }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                print("📱 App became active - reloading widgets")
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }
}
