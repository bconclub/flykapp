import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'services/hive_service.dart';
import 'screens/main_navigation.dart';
import 'theme/app_theme.dart';

void main() {
  print('[Flyk] main() called');
  WidgetsFlutterBinding.ensureInitialized();
  print('[Flyk] WidgetsFlutterBinding initialized');
  
  // Run app immediately, initialize services in background
  print('[Flyk] Running app...');
  runApp(const FlykApp());
  print('[Flyk] runApp() called');
  
  // Initialize Supabase in background (non-blocking)
  Future.microtask(() async {
    try {
      print('[Flyk] Initializing Supabase...');
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        anonKey: SupabaseConfig.supabaseAnonKey,
      );
      print('[Flyk] Supabase initialized successfully');
    } catch (e) {
      print('[Flyk] Supabase error: $e');
    }
  });
  
  // Initialize Hive in background
  Future.microtask(() async {
    try {
      print('[Flyk] Initializing Hive...');
      final hiveService = HiveService();
      await hiveService.init();
      print('[Flyk] Hive initialized successfully');
    } catch (e) {
      print('[Flyk] Hive error: $e');
    }
  });
}

class FlykApp extends StatelessWidget {
  const FlykApp({super.key});

  @override
  Widget build(BuildContext context) {
    print('[Flyk] FlykApp.build() called');
    return MaterialApp(
      title: 'Flyk',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainNavigation(),
      builder: (context, child) {
        print('[Flyk] MaterialApp builder called');
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
          child: child ?? const SizedBox(),
        );
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  Widget build(BuildContext context) {
    // Skip all checks - go straight to main app
    return const MainNavigation();
  }
}
