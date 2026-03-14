# Jeep LEDs - Widget & Siri Setup Guide

This guide will help you set up widgets and Siri shortcuts for your Jeep LED control app.

## Prerequisites

All the code files have been created:
- ✅ `SharedLEDState.swift` - Shared data model
- ✅ `JeepLEDsWidget.swift` - Widget implementation
- ✅ `DeepLinkHandler.swift` - Deep link handling
- ✅ `SiriIntents.swift` - Siri shortcuts support
- ✅ Updated `Jeep_LEDsApp.swift` - Deep link integration
- ✅ Updated `ContentView.swift` - State synchronization

## Step 1: Add Widget Extension Target

1. Open your project in Xcode
2. Go to **File → New → Target**
3. Select **Widget Extension**
4. Configure:
   - Product Name: `Jeep LEDs Widget`
   - Uncheck "Include Configuration Intent"
   - Click **Finish**
   - Click **Activate** when prompted

5. **Add the widget file:**
   - Delete the default widget file created by Xcode
   - Add `JeepLEDsWidget.swift` to the **Jeep LEDs Widget** target
   - Make sure `SharedLEDState.swift` is added to BOTH targets (main app AND widget)

## Step 2: Configure App Groups

App Groups allow the main app and widget to share data.

### For Main App Target:
1. Select **Jeep LEDs** target
2. Go to **Signing & Capabilities** tab
3. Click **+ Capability**
4. Add **App Groups**
5. Click **+** and create: `group.com.yourname.jeepleds`
   - Replace `yourname` with your actual identifier
6. Check the checkbox to enable it

### For Widget Target:
1. Select **Jeep LEDs Widget** target
2. Repeat steps 2-6 above
3. **Important:** Use the SAME App Group ID

### Update the App Group ID in Code:
1. Open `SharedLEDState.swift`
2. Find line 38: `private let appGroupID = "group.com.yourname.jeepleds"`
3. Replace with YOUR actual App Group ID

## Step 3: Add URL Scheme for Deep Links

1. Select **Jeep LEDs** target
2. Go to **Info** tab
3. Expand **URL Types**
4. Click **+** to add a new URL Type
5. Configure:
   - **Identifier:** `com.yourname.jeepleds`
   - **URL Schemes:** `jeepleds`
   - **Role:** Editor

## Step 4: Add Files to Targets

Make sure these files are added to the correct targets:

### Main App Target (Jeep LEDs):
- ✅ SharedLEDState.swift
- ✅ DeepLinkHandler.swift
- ✅ SiriIntents.swift
- ✅ ContentView.swift
- ✅ BluetoothManager.swift
- ✅ Jeep_LEDsApp.swift

### Widget Target (Jeep LEDs Widget):
- ✅ SharedLEDState.swift
- ✅ JeepLEDsWidget.swift

## Step 5: Build and Run

1. Select the **Jeep LEDs** scheme
2. Build and run (Cmd+R)
3. The app should compile successfully

4. To test the widget:
   - Select **Jeep LEDs Widget** scheme
   - Run on simulator or device
   - The widget will appear in the widget gallery

## Step 6: Add Widgets to Home Screen

On your iPhone:
1. Long-press on home screen
2. Tap **+** button in top-left
3. Search for "Jeep LEDs"
4. Choose widget size:
   - **Small:** Status display
   - **Medium:** Status + Quick actions
   - **Large:** Full controls with colors and patterns

## Step 7: Set Up Siri Shortcuts

### Quick Setup (Suggested Shortcuts):
After running the app once, iOS will automatically suggest these shortcuts:
- "Turn off my Jeep LEDs"
- "Activate emergency lights"
- "Set Jeep LEDs to [color]"
- "Set Jeep LED pattern to [pattern]"

### Manual Setup:
1. Open **Shortcuts app**
2. Tap **+** to create new shortcut
3. Add action **"Turn Off Jeep LEDs"** (or other intents)
4. Name it and tap Done

### Add to Siri:
1. In Shortcuts app, tap the ••• on your shortcut
2. Tap **Add to Siri**
3. Record your custom phrase, like:
   - "Jeep lights off"
   - "Emergency mode"
   - "Set Jeep lights to red"
   - "Hazard lights on"

## Available Siri Commands

### Pre-configured Voice Commands:
- **"Turn off my Jeep LEDs"**
- **"Turn off Jeep lights"**
- **"Jeep lights off"**

- **"Activate emergency lights"**
- **"Turn on hazard lights on my Jeep"**
- **"Emergency mode for Jeep LEDs"**

- **"Set Jeep LEDs to red"** (or blue, green, etc.)
- **"Change Jeep lights to blue"**
- **"Make my Jeep lights purple"**

- **"Set Jeep LED pattern to police"**
- **"Change Jeep LEDs pattern to rainbow"**

### Supported Colors:
Red, Orange, Yellow, Green, Cyan, Blue, Purple, Pink, White

### Supported Patterns:
Solid, Blink, Breathe, Strobe, Police, Hazard, Rainbow, Chase

## Widget Features

### Small Widget:
- LED status (On/Off)
- Current color name
- Current pattern
- Connection status

### Medium Widget:
- All small widget features
- **Quick actions:**
  - Power Off button
  - Emergency button

### Large Widget:
- All status information
- **Color preset buttons:**
  - Red, Blue, Green
- **Pattern buttons:**
  - Police, Hazard, Rainbow

## Deep Link URLs

The widget and Siri shortcuts use these URL schemes:

```
jeepleds://off                    - Turn off LEDs
jeepleds://emergency              - Activate hazard mode
jeepleds://color/red              - Set color to red
jeepleds://color/blue             - Set color to blue
jeepleds://pattern/police         - Set police pattern
jeepleds://pattern/rainbow        - Set rainbow pattern
```

You can test these in Safari on your device!

## Troubleshooting

### Widget Not Updating:
- Make sure App Group ID matches in both targets
- Check that SharedLEDState.swift is in both targets
- Try removing and re-adding the widget

### Siri Not Working:
- Make sure you've run the app at least once
- Check Settings → Siri & Search → Jeep LEDs
- Verify shortcuts are enabled

### Deep Links Not Working:
- Verify URL scheme is added (jeepleds)
- Check that DeepLinkHandler is properly set up
- Make sure app is properly signed

### "No Such Module" Error:
- Clean build folder (Cmd+Shift+K)
- Delete derived data
- Rebuild project

## Privacy & Permissions

The widget and Siri shortcuts work even when:
- App is not running
- iPhone is locked
- Bluetooth is disconnected

Note: Commands will be queued and sent when Bluetooth reconnects.

## Testing Checklist

- [ ] Widget shows current LED status
- [ ] Small widget displays correctly
- [ ] Medium widget shows quick actions
- [ ] Large widget shows color/pattern buttons
- [ ] Tapping widget buttons opens app and executes command
- [ ] "Turn off" Siri command works
- [ ] "Set color" Siri command works
- [ ] "Emergency" Siri command works
- [ ] Deep links work from Safari
- [ ] State syncs between app and widget
- [ ] Connection status updates in widget

## Next Steps

Once everything is working:
1. Customize the App Group ID to match your team
2. Add more color/pattern presets to large widget
3. Create custom Siri shortcuts for common scenarios
4. Share your favorite shortcuts with friends!

---

**Enjoy controlling your Jeep LEDs with widgets and Siri! 🎉**
