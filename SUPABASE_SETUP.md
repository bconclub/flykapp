# Supabase Setup Guide

## 1. Create Supabase Project

1. Go to [supabase.com](https://supabase.com)
2. Sign up or log in
3. Create a new project
4. Note your project URL and anon key from Settings → API

## 2. Update Configuration

Edit `lib/config/supabase_config.dart`:

```dart
class SupabaseConfig {
  static const String supabaseUrl = 'https://your-project.supabase.co';
  static const String supabaseAnonKey = 'your-anon-key-here';
}
```

## 3. Database Schema

Run these SQL commands in your Supabase SQL Editor:

### Ideas Table

```sql
CREATE TABLE ideas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  transcript TEXT NOT NULL,
  research_output TEXT,
  mode TEXT CHECK (mode IN ('record', 'research')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ,
  CONSTRAINT ideas_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Enable Row Level Security
ALTER TABLE ideas ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see their own ideas
CREATE POLICY "Users can view own ideas"
  ON ideas FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: Users can insert their own ideas
CREATE POLICY "Users can insert own ideas"
  ON ideas FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own ideas
CREATE POLICY "Users can update own ideas"
  ON ideas FOR UPDATE
  USING (auth.uid() = user_id);

-- Policy: Users can delete their own ideas
CREATE POLICY "Users can delete own ideas"
  ON ideas FOR DELETE
  USING (auth.uid() = user_id);
```

### Idea Links Table

```sql
CREATE TABLE idea_links (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  idea_id_1 UUID NOT NULL REFERENCES ideas(id) ON DELETE CASCADE,
  idea_id_2 UUID NOT NULL REFERENCES ideas(id) ON DELETE CASCADE,
  similarity DECIMAL(3,2) NOT NULL CHECK (similarity >= 0 AND similarity <= 1),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT idea_links_unique UNIQUE (idea_id_1, idea_id_2),
  CONSTRAINT idea_links_different CHECK (idea_id_1 != idea_id_2)
);

-- Enable Row Level Security
ALTER TABLE idea_links ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view links for their ideas
CREATE POLICY "Users can view own idea links"
  ON idea_links FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM ideas
      WHERE (ideas.id = idea_links.idea_id_1 OR ideas.id = idea_links.idea_id_2)
      AND ideas.user_id = auth.uid()
    )
  );

-- Policy: Users can insert links for their ideas
CREATE POLICY "Users can insert own idea links"
  ON idea_links FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM ideas
      WHERE (ideas.id = idea_links.idea_id_1 OR ideas.id = idea_links.idea_id_2)
      AND ideas.user_id = auth.uid()
    )
  );
```

## 4. Authentication

The app uses Supabase Auth. Users will need to sign up/sign in.

### Optional: Email Auth Setup

1. Go to Authentication → Settings
2. Enable Email provider
3. Configure email templates if needed

## 5. Testing

1. Run the app: `flutter run`
2. Sign up with a test email
3. Record an idea
4. Check Supabase dashboard to see the data

## 6. Troubleshooting

### RLS Policy Errors
- Ensure policies are created correctly
- Check that user_id matches auth.uid()

### Connection Issues
- Verify Supabase URL and key are correct
- Check network connectivity
- Review Supabase logs in dashboard

### Sync Issues
- Check if user is authenticated
- Verify RLS policies allow operations
- Check app logs for specific errors

