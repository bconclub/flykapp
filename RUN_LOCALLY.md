# How to Run Flyk Locally

## Quick Start (If Flutter is Installed)

```bash
# 1. Install dependencies
flutter pub get

# 2. Run on web (easiest)
flutter run -d chrome

# 3. Or check available devices
flutter devices
```

## Install Flutter First (If Not Installed)

### Windows Installation

1. **Download Flutter SDK:**
   - Visit: https://docs.flutter.dev/get-started/install/windows
   - Download the Flutter SDK zip
   - Extract to `C:\src\flutter` (or any path without spaces)

2. **Add to PATH:**
   - Press `Win + X` → System → Advanced system settings
   - Click "Environment Variables"
   - Under "User variables", edit "Path"
   - Add: `C:\src\flutter\bin` (or your Flutter path)
   - Click OK and **restart your terminal/PowerShell**

3. **Verify Installation:**
   ```bash
   flutter doctor
   ```

4. **Install Dependencies:**
   ```bash
   cd C:\Users\user\Builds\Flyk
   flutter pub get
   ```

5. **Run the App:**
   ```bash
   # Web (easiest, no emulator needed)
   flutter run -d chrome
   
   # Or check what's available
   flutter devices
   ```

## Before Running

### 1. Configure Supabase (Required)

Edit `lib/config/supabase_config.dart`:

```dart
class SupabaseConfig {
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
}
```

**Note:** The app will still run without Supabase, but features requiring auth/database won't work.

### 2. Install Dependencies

```bash
flutter pub get
```

## Running Options

### Web (Recommended for Quick Testing)
```bash
flutter run -d chrome
```
- Fastest to start
- No emulator needed
- Speech recognition works on localhost

### Android
```bash
flutter run -d android
```
- Requires Android Studio + emulator or device
- Full feature support

### iOS (Mac only)
```bash
flutter run -d ios
```
- Requires Xcode
- Mac only

## Troubleshooting

### "flutter: command not found"
- Flutter not in PATH
- Restart terminal after adding to PATH
- Verify: `where.exe flutter` (should show path)

### "No devices found"
- For web: Install Chrome
- For Android: Start emulator or connect device
- Check: `flutter devices`

### Dependencies Error
```bash
flutter clean
flutter pub get
```

### Supabase Connection Error
- App will still run but auth/sync won't work
- Configure Supabase credentials first
- See `SUPABASE_SETUP.md` for database setup

## Quick Test Without Supabase

The app will run and show:
- Onboarding screens ✅
- Record screen ✅
- Ideas list (empty) ✅
- Spectrum screen (empty) ✅

But won't work:
- Authentication
- Saving to cloud
- Syncing

For full functionality, set up Supabase first!

