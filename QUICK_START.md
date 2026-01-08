# Quick Start Guide

## Install Flutter

1. **Download Flutter SDK:**
   - Visit: https://flutter.dev/docs/get-started/install/windows
   - Download the Flutter SDK zip file
   - Extract it to a location like `C:\src\flutter` (avoid spaces in path)

2. **Add Flutter to PATH:**
   - Open System Environment Variables
   - Add `C:\src\flutter\bin` to your PATH
   - Restart your terminal/PowerShell

3. **Verify Installation:**
   ```bash
   flutter doctor
   ```

4. **Install Dependencies:**
   ```bash
   cd C:\Users\user\Builds\Flyk
   flutter pub get
   ```

## Run the App

### Option 1: Web (Easiest)
```bash
flutter run -d chrome
```

### Option 2: Android
- Requires Android Studio and an emulator/device
```bash
flutter run -d android
```

### Option 3: Check Available Devices
```bash
flutter devices
```

## Troubleshooting

### Flutter not found:
- Ensure Flutter is in your PATH
- Restart terminal after adding to PATH
- Try: `C:\src\flutter\bin\flutter doctor` (adjust path as needed)

### Dependencies not installing:
- Run `flutter pub get` in the project directory
- Check internet connection

### Web not working:
- Ensure Chrome is installed
- Try: `flutter run -d edge` for Edge browser

