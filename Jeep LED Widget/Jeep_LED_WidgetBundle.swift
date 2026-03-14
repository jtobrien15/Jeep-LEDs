//
//  Jeep_LED_WidgetBundle.swift
//  Jeep LED Widget
//
//  Created by voyager on 2/25/26.
//

import WidgetKit
import SwiftUI

@main
struct Jeep_LED_WidgetBundle: WidgetBundle {
    var body: some Widget {
        Jeep_LED_Widget()
        Jeep_LED_WidgetControl()
        Jeep_LED_WidgetLiveActivity()
    }
}
