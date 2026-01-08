# Install Flutter on Windows

## Quick Install (Recommended)

### Option 1: Using Git (if you have Git installed)

```powershell
# Navigate to where you want Flutter
cd C:\Users\user

# Clone Flutter
git clone https://github.com/flutter/flutter.git -b stable

# Add to PATH (temporary for this session)
$env:Path += ";C:\Users\user\flutter\bin"

# Verify
flutter doctor
```

### Option 2: Download ZIP

1. **Download Flutter SDK:**
   - Go to: https://docs.flutter.dev/get-started/install/windows
   - Click "Download Flutter SDK"
   - Download the zip file (about 1.5GB)

2. **Extract:**
   - Extract to `C:\Users\user\flutter`
   - Make sure the `bin` folder is at `C:\Users\user\flutter\bin`

3. **Add to PATH permanently:**
   - Press `Win + X` → System
   - Click "Advanced system settings"
   - Click "Environment Variables"
   - Under "User variables", find "Path" → Edit
   - Click "New" → Add: `C:\Users\user\flutter\bin`
   - Click OK on all dialogs

4. **Restart PowerShell/Terminal**

5. **Verify:**
   ```powershell
   flutter doctor
   ```

## After Installation

Once Flutter is installed, run:

```powershell
cd C:\Users\user\Builds\Flyk
flutter pub get
flutter run -d chrome
```

## Troubleshooting

### "flutter: command not found"
- Make sure you added `C:\Users\user\flutter\bin` to PATH
- Restart your terminal
- Verify: `$env:Path` should include the Flutter bin path

### "git: command not found"
- Install Git: https://git-scm.com/download/win
- Or use Option 2 (download ZIP) instead

### Flutter doctor shows issues
- Most warnings are fine for web development
- For Android: Install Android Studio
- For iOS: Mac only

