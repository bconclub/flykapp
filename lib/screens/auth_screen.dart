import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _supabaseService = SupabaseService();
  
  bool _isSignUp = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill with admin credentials
    _emailController.text = 'admin@flyk.com';
    _passwordController.text = 'Flykadmin';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_isSignUp) {
        await _supabaseService.signUp(
          _emailController.text.trim(),
          _passwordController.text,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created! Please check your email.'),
            ),
          );
        }
      } else {
        await _supabaseService.signIn(
          _emailController.text.trim(),
          _passwordController.text,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.textSecondary,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _tryAdminLogin() async {
    setState(() => _isLoading = true);
    
    try {
      // First, try to sign in
      await _supabaseService.signIn('admin@flyk.com', 'Flykadmin');
    } catch (signInError) {
      // If sign in fails, try to create the account
      try {
        print('[Flyk] Admin account not found, creating...');
        final response = await _supabaseService.signUp('admin@flyk.com', 'Flykadmin');
        print('[Flyk] Sign up response: ${response.user?.email}, session: ${response.session != null}');
        
        if (mounted) {
          // Check if email confirmation is required
          if (response.user != null && response.session == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Account created! Email confirmation required.'),
                    const SizedBox(height: 8),
                    const Text('Option 1: Check your email and click the confirmation link', style: TextStyle(fontSize: 12)),
                    const SizedBox(height: 4),
                    const Text('Option 2: Disable email confirmation in Supabase Dashboard', style: TextStyle(fontSize: 12)),
                    const SizedBox(height: 4),
                    const Text('(Authentication → Settings → Uncheck "Enable email confirmations")', style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic)),
                  ],
                ),
                duration: const Duration(seconds: 8),
                backgroundColor: AppTheme.surfaceColor,
              ),
            );
          } else if (response.session != null) {
            // If we got a session, we're already signed in
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Admin account created and signed in!'),
              ),
            );
          }
        }
      } catch (signUpError) {
        print('[Flyk] Sign up error: $signUpError');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Error: ${signUpError.toString()}'),
                  const SizedBox(height: 8),
                  const Text('To fix: Go to Supabase Dashboard → Authentication → Settings', style: TextStyle(fontSize: 12)),
                  const Text('→ Uncheck "Enable email confirmations" → Save', style: TextStyle(fontSize: 12)),
                ],
              ),
              backgroundColor: AppTheme.textSecondary,
              duration: const Duration(seconds: 8),
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.mic,
                    size: 64,
                    color: AppTheme.textPrimary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Flyk',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Voice-to-text idea capture',
                    style: TextStyle(color: AppTheme.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  // Admin quick login button
                  OutlinedButton(
                    onPressed: _isLoading ? null : _tryAdminLogin,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: AppTheme.borderColor),
                    ),
                    child: Text(
                      'Quick Login: Admin',
                      style: TextStyle(color: AppTheme.textPrimary),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleAuth,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : Text(_isSignUp ? 'Sign Up' : 'Sign In'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            setState(() {
                              _isSignUp = !_isSignUp;
                            });
                          },
                    child: Text(
                      _isSignUp
                          ? 'Already have an account? Sign In'
                          : 'Don\'t have an account? Sign Up',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

