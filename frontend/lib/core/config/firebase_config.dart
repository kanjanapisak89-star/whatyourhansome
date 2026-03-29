import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Resolves Firebase configuration for the current platform.
///
/// Priority order:
///   1. Build-time `--dart-define` values (used in production via Railway)
///   2. Compile-time fallback constants from firebase_options.dart
///
/// In production, pass values at build time:
///   flutter build web \
///     --dart-define=FIREBASE_API_KEY=... \
///     --dart-define=FIREBASE_PROJECT_ID=... \
///     --dart-define=FIREBASE_APP_ID=... \
///     --dart-define=FIREBASE_MESSAGING_SENDER_ID=... \
///     --dart-define=FIREBASE_AUTH_DOMAIN=... \
///     --dart-define=FIREBASE_STORAGE_BUCKET=...
class FirebaseConfig {
  // ---------------------------------------------------------------------------
  // Build-time injected values (--dart-define)
  // ---------------------------------------------------------------------------
  static const String _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const String _projectId =
      String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const String _appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const String _messagingSenderId =
      String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static const String _authDomain =
      String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
  static const String _storageBucket =
      String.fromEnvironment('FIREBASE_STORAGE_BUCKET');

  // ---------------------------------------------------------------------------
  // Fallback constants (from firebase_options.dart / FlutterFire CLI)
  // ---------------------------------------------------------------------------
  static const String _fallbackApiKey =
      'AIzaSyBXqJ8vZ9QZ8Z8Z8Z8Z8Z8Z8Z8Z8Z8Z8Z8';
  static const String _fallbackProjectId = 'loft-71a46';
  static const String _fallbackAppId =
      '1:627999904421:web:9829c36b5547e0d7ccf34c';
  static const String _fallbackMessagingSenderId = '627999904421';
  static const String _fallbackAuthDomain = 'loft-71a46.firebaseapp.com';
  static const String _fallbackStorageBucket = 'loft-71a46.firebasestorage.app';

  // ---------------------------------------------------------------------------
  // Resolved values
  // ---------------------------------------------------------------------------
  static String get apiKey =>
      _apiKey.isNotEmpty ? _apiKey : _fallbackApiKey;
  static String get projectId =>
      _projectId.isNotEmpty ? _projectId : _fallbackProjectId;
  static String get appId =>
      _appId.isNotEmpty ? _appId : _fallbackAppId;
  static String get messagingSenderId =>
      _messagingSenderId.isNotEmpty
          ? _messagingSenderId
          : _fallbackMessagingSenderId;
  static String get authDomain =>
      _authDomain.isNotEmpty ? _authDomain : _fallbackAuthDomain;
  static String get storageBucket =>
      _storageBucket.isNotEmpty ? _storageBucket : _fallbackStorageBucket;

  /// Returns [FirebaseOptions] for the web platform, resolving values from
  /// build-time defines first, then falling back to compiled-in constants.
  static FirebaseOptions get webOptions => FirebaseOptions(
        apiKey: apiKey,
        appId: appId,
        messagingSenderId: messagingSenderId,
        projectId: projectId,
        authDomain: authDomain,
        storageBucket: storageBucket,
      );

  /// Logs the resolved config source for debugging (never logs secret values).
  static void debugPrintSource() {
    debugPrint('FirebaseConfig: apiKey      → ${_apiKey.isNotEmpty ? "dart-define" : "fallback"}');
    debugPrint('FirebaseConfig: projectId   → ${_projectId.isNotEmpty ? "dart-define" : "fallback"} (${projectId})');
    debugPrint('FirebaseConfig: appId       → ${_appId.isNotEmpty ? "dart-define" : "fallback"}');
    debugPrint('FirebaseConfig: senderId    → ${_messagingSenderId.isNotEmpty ? "dart-define" : "fallback"}');
    debugPrint('FirebaseConfig: authDomain  → ${_authDomain.isNotEmpty ? "dart-define" : "fallback"} (${authDomain})');
    debugPrint('FirebaseConfig: storage     → ${_storageBucket.isNotEmpty ? "dart-define" : "fallback"} (${storageBucket})');
  }
}
