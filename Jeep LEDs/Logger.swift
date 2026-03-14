//
//  Logger.swift
//  Jeep LEDs
//
//  Simple logging utility that writes to device console
//

import Foundation
import os.log

class AppLogger {
    static let shared = AppLogger()

    private let logger = Logger(subsystem: "com.jtobrien.jeepled", category: "main")

    func log(_ message: String) {
        logger.info("\(message, privacy: .public)")
        print(message)
    }

    func logColorTap(colorName: String, r: Int, g: Int, b: Int) {
        let msg = "🎨 USER TAPPED: \(colorName) RGB(\(r),\(g),\(b))"
        logger.info("\(msg, privacy: .public)")
        print(msg)
    }

    func logCommand(command: String, type: String) {
        let msg = "📤 SENDING \(type): \(command)"
        logger.info("\(msg, privacy: .public)")
        print(msg)
    }
}
