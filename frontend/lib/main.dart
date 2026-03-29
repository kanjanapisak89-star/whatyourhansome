import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/widgets/splash_screen.dart';
import 'core/config/firebase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set system UI overlay style (status bar, navigation bar)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF000000),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  
  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(
    const ProviderScope(
      child: LoftApp(),
    ),
  );
}

class LoftApp extends StatefulWidget {
  const LoftApp({super.key});

  @override
  State<LoftApp> createState() => _LoftAppState();
}

class _LoftAppState extends State<LoftApp> {
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  String _errorMessage = '';

  Future<void> _initializeApp() async {
    try {
      // Load .env for local development — missing file is fine in production.
      try {
        await dotenv.load(fileName: '.env');
        debugPrint('AppInit: .env loaded successfully');
      } catch (e) {
        debugPrint('AppInit: .env not found — using build-time defines / fallbacks (expected in production)');
      }

      // Log which Firebase config source is active.
      FirebaseConfig.debugPrintSource();

      // Initialize Firebase with explicit options so the app works even when
      // google-services.json / GoogleService-Info.plist are absent (web only).
      if (Firebase.apps.isEmpty) {
        if (kIsWeb) {
          debugPrint('AppInit: initializing Firebase for web with resolved options');
          await Firebase.initializeApp(
            options: FirebaseConfig.webOptions,
          );
        } else {
          debugPrint('AppInit: initializing Firebase for native platform');
          await Firebase.initializeApp();
        }
      } else {
        debugPrint('AppInit: Firebase already initialized — skipping');
      }

      debugPrint('AppInit: Firebase initialized successfully (project: ${FirebaseConfig.projectId})');

      // Minimum splash duration for a polished UX.
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _isInitialized = true;
      });
    } catch (e, stack) {
      debugPrint('AppInit ERROR: $e');
      debugPrint('AppInit STACK: $stack');
      setState(() {
        _errorMessage = e.toString();
        _hasError = true;
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), // iPhone 11 Pro dimensions
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        if (!_isInitialized) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme,
            home: const SplashScreen(),
          );
        }

        if (_hasError) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text(
                        'Failed to initialize app',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_errorMessage.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isInitialized = false;
                            _hasError = false;
                            _errorMessage = '';
                          });
                          _initializeApp();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return MaterialApp.router(
          title: 'Loft',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          routerConfig: appRouter,
        );
      },
    );
  }
}
