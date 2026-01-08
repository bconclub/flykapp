import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'services/hive_service.dart';
import 'screens/main_navigation.dart';
import 'theme/app_theme.dart';

void main() async {
  print('[Flyk] main() called');
  WidgetsFlutterBinding.ensureInitialized();
  print('[Flyk] WidgetsFlutterBinding initialized');
  
  // Initialize Supabase (non-blocking)
  try {
    print('[Flyk] Initializing Supabase...');
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
    print('[Flyk] Supabase initialized successfully');
    debugPrint('Supabase initialized');
  } catch (e, stackTrace) {
    print('[Flyk] Supabase initialization error: $e');
    print('[Flyk] Stack trace: $stackTrace');
    debugPrint('Supabase initialization error: $e');
    // Continue anyway - app will work offline
  }
  
  // Initialize Hive in background (non-blocking for web)
  Future.microtask(() async {
    try {
      print('[Flyk] Initializing Hive...');
      final hiveService = HiveService();
      await hiveService.init();
      print('[Flyk] Hive initialized successfully');
      debugPrint('Hive initialized');
    } catch (e, stackTrace) {
      print('[Flyk] Hive initialization error: $e');
      print('[Flyk] Stack trace: $stackTrace');
      debugPrint('Hive initialization error: $e');
      // Continue anyway - web doesn't fully support Hive
    }
  });
  
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  print('[Flyk] Running app...');
  runApp(const FlykApp());
  print('[Flyk] runApp() called');
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
