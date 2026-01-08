# Widget Setup Guide

## Android Widget Setup

The Android widget is configured in the following files:
- `android/app/src/main/res/xml/widget_info.xml` - Widget configuration
- `android/app/src/main/res/layout/widget_layout.xml` - Widget layout
- `android/app/src/main/kotlin/com/example/flyk/FlykWidgetProvider.kt` - Widget provider

### To enable the widget:

1. Build and install the app on an Android device
2. Long-press on the home screen
3. Select "Widgets" from the menu
4. Find "Flyk" widget
5. Drag it to your home screen
6. Long-press the widget button to start recording

### Widget Features:
- Long-press the widget button to start voice recording
- Widget shows recording status
- Displays last saved idea

## iOS Widget Setup

iOS widgets require a Widget Extension. To set up:

1. Open the project in Xcode
2. File → New → Target
3. Select "Widget Extension"
4. Name it "FlykWidget"
5. Configure the widget extension to use the same App Group: `group.com.flyk.app`
6. Implement the widget UI in SwiftUI

### App Group Configuration:

Both the main app and widget extension must share the same App Group:
- App Group ID: `group.com.flyk.app`
- Configure in Xcode: Signing & Capabilities → App Groups

### Widget Features:
- Long-press the widget to start recording
- Widget updates when new ideas are saved
- Shows recording status

## Testing Widgets

### Android:
- Widget appears in the widget picker after first app install
- Long-press widget button triggers recording
- Widget updates when app saves new ideas

### iOS:
- Add widget from home screen edit mode
- Long-press widget to interact
- Widget updates via App Group shared data

## Troubleshooting

### Widget not appearing:
- Ensure app is installed and run at least once
- Check widget configuration files are correct
- For iOS, verify App Group is configured in both app and extension

### Widget not updating:
- Check App Group ID matches in all configurations
- Verify `HomeWidget.updateWidget()` is called after saving ideas
- Check logs for widget update errors

### Recording not starting from widget:
- Ensure microphone permissions are granted
- Check deep link handling in main.dart
- Verify widget provider is properly registered

