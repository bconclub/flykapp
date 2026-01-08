# Flyk

A voice-to-text idea capture app with Supabase backend, knowledge mapping, and offline-first architecture.

## Features

- 🎤 **Animated Morphing Voice Bubble** - Tap to record with beautiful morphing animation
- 🔄 **Record/Research Toggle** - Switch between simple recording and AI research mode
- 🗣️ **Voice-to-Text** - Automatic speech recognition with auto-correction
- 💾 **Offline-First** - Hive local storage with automatic Supabase sync
- 🔗 **Auto-Linking** - Ideas automatically link based on content similarity
- 📊 **Spectrum Screen** - Visual knowledge map showing clusters and white spaces
- 🔐 **Supabase Auth** - Secure user authentication
- 🌙 **Dark Theme** - Minimal, beautiful UI

## Architecture

- **Frontend:** Flutter (Web, Android, iOS)
- **Backend:** Supabase (Auth + Database)
- **Local Storage:** Hive (offline-first)
- **Sync:** Automatic bidirectional sync when online

## Project Structure

```
lib/
├── main.dart                    # App entry with auth wrapper
├── config/
│   └── supabase_config.dart     # Supabase credentials
├── models/
│   ├── idea.dart                # Idea model with Hive adapter
│   └── idea_link.dart           # Idea link model
├── screens/
│   ├── auth_screen.dart         # Sign up/sign in
│   ├── main_navigation.dart     # Bottom nav wrapper
│   ├── record_screen.dart       # Record screen with morphing bubble
│   ├── ideas_screen.dart        # Ideas list
│   ├── spectrum_screen.dart     # Knowledge map visualization
│   └── idea_detail_screen.dart  # View/edit with links & research
├── services/
│   ├── supabase_service.dart    # Supabase API client
│   ├── hive_service.dart        # Local storage
│   ├── sync_service.dart        # Offline sync logic
│   ├── speech_service.dart      # Speech-to-text
│   ├── idea_linking_service.dart # Content similarity & linking
│   └── research_service.dart    # AI research generation
├── widgets/
│   ├── morphing_voice_bubble.dart # Animated recording bubble
│   ├── mode_toggle.dart          # Record/Research toggle
│   └── idea_card.dart            # Idea list item
└── theme/
    └── app_theme.dart            # Dark theme
```

## Setup

### Prerequisites

- Flutter SDK (3.0.0 or higher)
- Supabase account
- Android Studio / Xcode (for mobile)

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Configure Supabase

1. Create a Supabase project at [supabase.com](https://supabase.com)
2. Get your project URL and anon key from Settings → API
3. Edit `lib/config/supabase_config.dart`:
   ```dart
   static const String supabaseUrl = 'YOUR_SUPABASE_URL';
   static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
   ```
4. Run the SQL schema from `SUPABASE_SETUP.md` in your Supabase SQL Editor

### 3. Run the App

```bash
# Web
flutter run -d chrome

# Android
flutter run -d android

# iOS
flutter run -d ios
```

## Usage

### Authentication

1. Launch the app
2. Sign up with email/password or sign in
3. Email verification may be required (check Supabase settings)

### Recording Ideas

1. **Record Mode:**
   - Tap the morphing voice bubble
   - Speak your idea
   - Tap again to stop
   - Idea is saved and auto-linked to similar ideas

2. **Research Mode:**
   - Toggle "Research" switch in Record screen
   - Record as normal
   - AI research is generated and saved with the idea

### Viewing Ideas

- **Ideas Tab:** Browse all saved ideas
- **Tap idea:** View full transcript, edit, see linked ideas
- **Research ideas:** Show research output if available
- **Linked ideas:** Navigate to related ideas

### Spectrum Screen

- **Knowledge Map:** Visual representation of idea connections
- **Clusters:** Top connected idea groups
- **White Spaces:** Isolated ideas (potential exploration areas)

### Offline Mode

- All ideas are saved locally first
- Works completely offline
- Automatic sync when connection is restored
- Manual sync via sync button

## Database Schema

See `SUPABASE_SETUP.md` for complete SQL schema.

**Tables:**
- `ideas` - User ideas with transcript, research, mode
- `idea_links` - Similarity links between ideas

**Row Level Security:**
- Users can only access their own ideas
- Automatic user_id assignment

## Technologies

- **Flutter** - Cross-platform framework
- **Supabase** - Backend (Auth + Database)
- **Hive** - Local NoSQL database
- **speech_to_text** - Speech recognition
- **fl_chart** - Data visualization
- **connectivity_plus** - Network status

## Development

### Generate Hive Adapters (if needed)

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Sync Issues

- Check Supabase RLS policies
- Verify user authentication
- Review sync service logs
- Check network connectivity

## Building

```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

## Troubleshooting

### Supabase Connection
- Verify URL and key in `supabase_config.dart`
- Check Supabase project is active
- Review Supabase logs

### Authentication
- Check email verification settings
- Verify RLS policies are set up
- Check Supabase Auth logs

### Sync Issues
- Ensure user is authenticated
- Check network connectivity
- Verify RLS policies allow operations
- Review app logs for errors

### Speech Recognition
- Grant microphone permissions
- Check internet (for cloud recognition)
- Verify speech_to_text package

## License

Open source - feel free to use and modify.
