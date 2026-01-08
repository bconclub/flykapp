# Flyk - Build Truth

**Last Updated:** Current Build  
**Status:** Development - Authentication Disabled

---

## 🎯 Current State

### ✅ What's Working

**Core Features:**
- ✅ Voice recording with speech-to-text (`speech_to_text` package)
- ✅ Animated morphing voice bubble (tap to record)
- ✅ Record/Research mode toggle ("Just capture" | "Capture + act")
- ✅ Auto-correction of transcripts (capitalization)
- ✅ Local storage with Hive (offline-first)
- ✅ Ideas list with timestamps
- ✅ Idea detail screen (view, edit, delete)
- ✅ Auto-tagging with domain classification (Business, Tech, Creative, Personal)
- ✅ Entity extraction and learning
- ✅ Idea auto-linking based on content similarity
- ✅ Spectrum screen with knowledge map visualization (clusters, connections)
- ✅ Bottom navigation (Capture, Ideas, Spectrum)
- ✅ Dark theme - **Monochrome (black, white, grayscale only)**
- ✅ Supabase backend integration (database operations)
- ✅ Offline sync service (syncs to Supabase when online)

**Screens:**
1. **Record Screen** (`record_screen.dart`) - Main capture interface
2. **Ideas Screen** (`ideas_screen.dart`) - List of all saved ideas
3. **Spectrum Screen** (`spectrum_screen.dart`) - Visual knowledge map
4. **Idea Detail Screen** (`idea_detail_screen.dart`) - View/edit with linked ideas
5. **Onboarding Screen** (`onboarding_screen.dart`) - 3-page intro (not shown currently)
6. **Auth Screen** (`auth_screen.dart`) - Login/signup (not shown currently)

**Services:**
- `SpeechService` - Voice-to-text conversion
- `HiveService` - Local storage (offline-first)
- `SupabaseService` - Backend API client
- `SyncService` - Bidirectional sync (local ↔ Supabase)
- `IdeaLinkingService` - Content similarity & auto-linking
- `AutoTaggingService` - Domain/keyword extraction
- `EntityLearningService` - Entity extraction & learning
- `ResearchService` - AI research (placeholder implementation)

---

## 🚫 What's Disabled/Commented Out

### Authentication
- ❌ **Authentication is DISABLED** - App opens directly to homepage
- ❌ Login/signup screen not shown
- ❌ All auth methods in `SupabaseService` are commented out:
  - `signUp()`, `signIn()`, `signOut()`, `currentUser`, `authStateChanges`
- ✅ **Using hardcoded test user_id:** `00000000-0000-0000-0000-000000000000`
- 📝 **Location:** `lib/config/test_user_config.dart`

### Onboarding
- ❌ Onboarding screen not shown (bypassed)
- ✅ Onboarding code exists but is skipped in `main.dart`

### Auth Wrapper
- ❌ `AuthWrapper` in `main.dart` bypasses all checks
- ✅ Goes directly to `MainNavigation()`

---

## 🏗️ Architecture

### Tech Stack
- **Framework:** Flutter (Web, Android, iOS support)
- **Backend:** Supabase (PostgreSQL database)
- **Local Storage:** Hive (NoSQL, offline-first)
- **State Management:** Flutter StatefulWidget
- **UI:** Material Design 3, Dark Theme (Monochrome)

### Data Flow
```
User Input (Voice) 
  → SpeechService (speech-to-text)
  → AutoTaggingService (domain/keywords)
  → EntityLearningService (extract entities)
  → Idea Model
  → HiveService (save locally)
  → SyncService (sync to Supabase when online)
```

### Project Structure
```
lib/
├── main.dart                    # Entry point, goes directly to MainNavigation
├── config/
│   ├── supabase_config.dart     # Supabase URL & anon key
│   └── test_user_config.dart    # Hardcoded test user_id (auth disabled)
├── models/
│   ├── idea.dart                # Idea model with Hive adapter
│   ├── idea_link.dart          # Idea link model
│   └── user_entity.dart        # Entity model
├── screens/
│   ├── main_navigation.dart    # Bottom nav wrapper
│   ├── record_screen.dart      # Capture screen
│   ├── ideas_screen.dart       # Ideas list
│   ├── spectrum_screen.dart    # Knowledge map
│   ├── idea_detail_screen.dart # Detail view
│   ├── onboarding_screen.dart  # Onboarding (not shown)
│   └── auth_screen.dart        # Login (not shown)
├── services/
│   ├── supabase_service.dart   # Backend API (auth methods commented)
│   ├── hive_service.dart       # Local storage
│   ├── sync_service.dart       # Offline sync
│   ├── speech_service.dart     # Voice recognition
│   ├── idea_linking_service.dart # Content similarity
│   ├── auto_tagging_service.dart # Domain/keyword tagging
│   ├── entity_learning_service.dart # Entity extraction
│   └── research_service.dart   # AI research (placeholder)
├── widgets/
│   ├── morphing_voice_bubble.dart # Animated record button
│   └── mode_toggle.dart        # Record/Research toggle
└── theme/
    └── app_theme.dart          # Dark monochrome theme
```

---

## 📦 Dependencies

### Core
- `flutter` - Framework
- `supabase_flutter: ^2.5.0` - Backend (auth disabled)
- `hive: ^2.2.3` - Local storage
- `hive_flutter: ^1.1.0` - Hive Flutter integration
- `speech_to_text: ^6.6.0` - Voice recognition
- `home_widget: ^0.8.1` - Home screen widgets (Android/iOS)

### UI/Visualization
- `fl_chart: ^0.66.0` - Charts (used in Spectrum screen)
- `flutter_animate: ^4.5.0` - Animations

### Utilities
- `connectivity_plus: ^5.0.2` - Network status
- `shared_preferences: ^2.2.2` - Simple key-value storage
- `intl: ^0.19.0` - Internationalization
- `collection: ^1.18.0` - Collection utilities

---

## 🎨 UI/UX Details

### Theme
- **Color Scheme:** Monochrome (black, white, grayscale only)
- **Background:** `#000000` (pure black)
- **Surface:** `#1A1A1A` (dark gray)
- **Text Primary:** `#FFFFFF` (white)
- **Text Secondary:** `#808080` (medium gray)
- **Border:** `#404040` (light gray)

### Brand Copy
- **Onboarding:**
  - "Capture" - "One tap. Never lose an idea again."
  - "Connect" - "See how your ideas link."
  - "Act" - "Get next steps, not just notes."
- **Record Screen:**
  - Empty state: "Your ideas deserve more than a graveyard. Tap to start."
  - Button label: "Flyk it"
  - Toggle: "Just capture" | "Capture + act"
- **Ideas Screen:**
  - Empty: "Nothing yet. Your best idea is one tap away."
- **Spectrum Screen:**
  - Header: "Your idea universe"
  - Empty: "Start capturing. Watch patterns emerge."
- **Idea Detail:**
  - Research header: "Next steps to make this real"

### Navigation
- Bottom navigation with 3 tabs:
  1. **Capture** (mic icon) - Record screen
  2. **Ideas** (lightbulb icon) - Ideas list
  3. **Spectrum** (graph icon) - Knowledge map

---

## 🔧 Configuration

### Supabase
- **Config File:** `lib/config/supabase_config.dart`
- **Current URL:** `https://niypveotxuledkrcikun.supabase.co`
- **Status:** Configured but auth disabled

### Test User
- **Config File:** `lib/config/test_user_config.dart`
- **Test User ID:** `00000000-0000-0000-0000-000000000000`
- **Usage:** All ideas saved with this hardcoded user_id

---

## 🚀 Running the App

### Development
```bash
flutter run -d chrome
```

### Build
```bash
flutter build web
```

### Clean Build
```bash
flutter clean
flutter pub get
flutter run -d chrome
```

---

## 📝 Known Limitations

1. **Authentication Disabled**
   - All users share the same test user_id
   - No user isolation
   - Auth code commented but preserved for re-enable

2. **Hive on Web**
   - Hive has limited web support
   - Initialization is non-blocking (may fail silently)
   - Local storage may not persist on web

3. **Research Service**
   - Placeholder implementation
   - Returns dummy text
   - Needs AI API integration (OpenAI/Anthropic)

4. **Speech-to-Text**
   - Requires browser permissions
   - May not work on all browsers
   - Web support varies by browser

5. **Supabase Sync**
   - Requires online connection
   - RLS policies may block operations without proper auth
   - Test user_id may not have proper permissions

---

## 🔄 To Re-Enable Authentication

1. **Uncomment auth methods** in `lib/services/supabase_service.dart`
2. **Update `main.dart`** to use `AuthWrapper` with auth checks
3. **Remove test user_id** usage, replace with `currentUser?.id`
4. **Update all services** to use `currentUser` instead of `TestUserConfig.testUserId`
5. **Enable auth screen** in navigation flow
6. **Configure Supabase** email confirmation settings

**Files to modify:**
- `lib/main.dart` - Re-enable auth checks
- `lib/services/supabase_service.dart` - Uncomment auth methods
- `lib/services/sync_service.dart` - Re-enable auth check
- `lib/screens/record_screen.dart` - Use `currentUser` instead of test user
- `lib/screens/onboarding_screen.dart` - Use `currentUser` instead of test user

---

## 📊 Database Schema

### Ideas Table
- `id` (UUID)
- `user_id` (UUID) - Currently using test user_id
- `transcript` (TEXT)
- `research_output` (TEXT, nullable)
- `mode` (TEXT: 'record' or 'research')
- `domain` (TEXT, nullable) - Auto-tagged domain
- `keywords` (TEXT[], nullable) - Auto-extracted keywords
- `created_at` (TIMESTAMPTZ)
- `updated_at` (TIMESTAMPTZ)
- `is_synced` (BOOLEAN)

### Idea Links Table
- `id` (UUID)
- `idea_id_1` (UUID)
- `idea_id_2` (UUID)
- `similarity` (DECIMAL 0-1)
- `created_at` (TIMESTAMPTZ)

### User Entities Table
- `id` (UUID)
- `user_id` (UUID)
- `name` (TEXT)
- `type` (TEXT: 'person', 'concept', 'place', etc.)
- `mention_count` (INTEGER)
- `is_important` (BOOLEAN)
- `domain` (TEXT, nullable)

---

## 🐛 Debugging

### Console Logs
- All services use `print()` and `debugPrint()` for logging
- Look for `[Flyk]` prefix in console output

### Common Issues
1. **App stuck on loading** - Check Supabase initialization
2. **Ideas not saving** - Check Hive initialization (web limitations)
3. **Sync not working** - Check network connectivity
4. **Speech not working** - Check browser permissions

---

## 📌 Next Steps (Future)

- [ ] Re-enable authentication
- [ ] Integrate real AI research API
- [ ] Improve Hive web support
- [ ] Add error handling UI
- [ ] Add loading states
- [ ] Implement proper offline queue
- [ ] Add idea search/filter
- [ ] Export ideas feature
- [ ] Home screen widgets (Android/iOS)

---

**Build Status:** ✅ Functional (Auth Disabled)  
**Last Build:** Current  
**Platforms:** Web ✅ | Android ⚠️ | iOS ⚠️

