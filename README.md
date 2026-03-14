# Jeep LED Controller

iOS app for controlling Neopixel LED underglow lights via Bluetooth using an Arduino Uno and Adafruit Bluefruit LE module.

## Features

### iOS App
- 🎨 **8 Preset Colors** - Red, Orange, Yellow, Green, Cyan, Blue, Purple, Pink
- 🌈 **11 Patterns** - Solid, Blink, Breathe, Strobe, Police, Hazard, Alternate, Rainbow, Chase, Sparkle, Fade, Running
- ⚡ **Pattern Speed Control** - Slow, Medium, Fast
- 🔆 **Brightness Control** - Low, Medium, High
- ⏱️ **Auto-Off Timer** - 15 min, 30 min, 1 hour, 2 hours
- 📳 **Haptic Feedback** - Throughout the app
- 🔄 **Auto-Reconnect** - Remembers last connected device

### Home Screen Widget
- Quick access to LED controls from your home screen
- Turn off, emergency hazard mode
- Direct color selection
- Pattern controls

### Siri Shortcuts
- "Turn off Jeep LEDs"
- "Set Jeep LEDs to [color]"
- "Set Jeep LEDs pattern to [pattern]"
- "Activate emergency LEDs"

## Hardware Requirements

- **iOS Device** - iPhone running iOS 16+
- **Arduino** - Uno R2 or compatible
- **Bluetooth Module** - Adafruit Bluefruit LE UART Friend
- **LED Strip** - Adafruit Neopixel (60 LEDs, GRB format)
- **Power Supply** - External 5V for LEDs (Arduino cannot power LED strip)

## Wiring

```
Bluefruit LE UART Friend:
  - TX  → Arduino Pin 10
  - RX  → Arduino Pin 11
  - VIN → Arduino 5V
  - GND → Arduino GND

Neopixel LED Strip:
  - Data → Arduino Pin 6
  - 5V   → External 5V Power Supply
  - GND  → Common Ground (Arduino + Power Supply)
```

## Installation

### Arduino Setup

1. Install Arduino IDE
2. Install Adafruit NeoPixel library (Tools > Manage Libraries)
3. Open `Arduino/ArduinoCode_Final.txt`
4. Verify settings:
   - Board: Arduino Uno
   - Port: Your Arduino's port
5. Upload to Arduino

### iOS App Setup

1. Open `Jeep LEDs.xcodeproj` in Xcode
2. Select your development team in Signing & Capabilities
3. Build and run on your iPhone
4. Grant Bluetooth permissions when prompted

### Widget Setup

1. Long-press on home screen
2. Tap "+" to add widget
3. Search for "Jeep LEDs"
4. Select widget size and add to home screen

### Siri Shortcuts Setup

1. Open Shortcuts app
2. Tap "+" to create new shortcut
3. Search for "Jeep LEDs" actions
4. Add desired actions and save

See `Documentation/WIDGET_SIRI_SETUP.md` for detailed instructions.

## Project Structure

```
Jeep LEDs/
├── Arduino/                          # Arduino sketches
│   ├── ArduinoCode_Final.txt        # Production version (USE THIS)
│   ├── ArduinoCode_NoString.txt     # Debug version with detailed logging
│   ├── ArduinoCode_SimpleTest.txt   # LED hardware test
│   └── ...                          # Other test/diagnostic files
├── Documentation/                    # Project documentation
│   ├── DEBUGGING_GUIDE.md           # Troubleshooting guide
│   ├── TROUBLESHOOTING_STEPS.md     # Hardware diagnostics
│   └── WIDGET_SIRI_SETUP.md         # Widget and Siri integration
├── Jeep LEDs/                       # Main iOS app
│   ├── BluetoothManager.swift       # Bluetooth communication
│   ├── ContentView.swift            # Main UI
│   ├── SharedLEDState.swift         # App/Widget communication
│   └── SiriIntents.swift            # Siri Shortcuts definitions
└── Jeep LED Widget/                 # Home screen widget
    └── Jeep_LED_Widget.swift        # Widget implementation
```

## Command Protocol

The Arduino receives commands via Bluetooth in the following format:

- **Color**: `C<red>,<green>,<blue>\n` (e.g., `C255,0,0\n` for red)
- **Pattern**: `P<pattern>\n` (e.g., `PRAINBOW\n`)
- **Brightness**: `B<brightness>\n` (e.g., `B128\n` for 50%)
- **Speed**: `S<speed>\n` (e.g., `S100\n` for normal speed)

## Troubleshooting

### LEDs Not Responding
1. Upload `Arduino/ArduinoCode_SimpleTest.txt` to verify LED hardware
2. Check wiring connections
3. Verify external power supply is connected
4. See `Documentation/TROUBLESHOOTING_STEPS.md`

### Bluetooth Connection Issues
1. Check Bluefruit module is powered (LED lit)
2. Verify TX/RX wiring is correct
3. Try disconnecting and reconnecting in app
4. Power cycle the Bluefruit module

### Wrong Colors Displayed
1. Try changing `NEO_GRB` to `NEO_RGB` in Arduino code (line 23)
2. Some LED strips use different color orders (GRB, RGB, RGBW, etc.)
3. Use `Arduino/LED_Type_Tester.txt` to identify your strip type

## Technical Details

### Why No Arduino String Class?

The production Arduino code (`ArduinoCode_Final.txt`) completely avoids the Arduino `String` class. The String class has known memory fragmentation issues on Arduino Uno's limited 2KB RAM, especially when:
- Called frequently in loops
- Used with SoftwareSerial interrupts
- Combined with Neopixel library

Instead, we use direct char array parsing which is:
- More reliable (no memory fragmentation)
- Faster (no dynamic allocation)
- More memory efficient

This was the root cause of the "commands received but LEDs not responding" issue that plagued earlier versions.

### iOS Architecture

- **BluetoothManager**: Handles BLE communication with priority queue system
- **SharedLEDStateManager**: Enables app/widget/Siri communication via App Groups
- **HapticManager**: Provides tactile feedback throughout the app
- **App Intents**: Modern iOS framework for widgets and Siri integration

## License

MIT License - Feel free to use and modify for your own projects.

## Credits

Built with:
- SwiftUI for iOS app
- Arduino for hardware control
- Adafruit NeoPixel library
- Adafruit Bluefruit LE

## Version History

### v3.0 (March 2026)
- Fixed critical Arduino String class bug
- Added home screen widget support
- Implemented Siri shortcuts
- Added haptic feedback
- Enhanced Bluetooth reliability with priority queue
- Pattern speed controls
- Auto-off timer

### v2.0 (March 2026)
- Added pattern support
- Improved UI/UX
- Brightness controls

### v1.0 (February 2026)
- Initial release
- Basic color control
- Bluetooth connectivity
