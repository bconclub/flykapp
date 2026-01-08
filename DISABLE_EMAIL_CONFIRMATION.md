# How to Disable Email Confirmation in Supabase

To allow immediate login without email verification:

1. Go to your Supabase Dashboard: https://supabase.com/dashboard
2. Select your project
3. Go to **Authentication** → **Settings** (in the left sidebar)
4. Scroll down to **Email Auth** section
5. **Uncheck** "Enable email confirmations"
6. Click **Save**

After this, users can sign up and immediately sign in without email verification.

**Note:** This is recommended for development/testing only. For production, keep email confirmation enabled for security.

