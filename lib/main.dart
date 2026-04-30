import 'dart:async';

import 'package:arunika_app/core/auth/auth_notifier.dart';
import 'package:arunika_app/core/logger/app_logger.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:arunika_app/data/repositories/notification_repository.dart';
import 'package:arunika_app/presentation/navigation/app_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background message handler — no-op for now.
}

void main() {
  // Wrap everything — including binding initialisation — in the same zone so
  // that runApp is called from the same zone as ensureInitialized().
  runZonedGuarded(
    () async {
      final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

      // Capture Flutter framework errors (widget build/layout errors, etc.)
      FlutterError.onError = (FlutterErrorDetails details) {
        AppLogger.error(
          'Flutter framework error',
          name: 'FlutterError',
          error: details.exception,
          stackTrace: details.stack,
        );
        // Forward to the default handler so the error is still logged in debug.
        FlutterError.presentError(details);
      };

      // Keep splash screen visible until we finish initialisation.
      FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

      // Initialise Firebase — gracefully skip if not configured (e.g. missing
      // google-services.json / GoogleService-Info.plist in dev builds).
      try {
        await Firebase.initializeApp();
        FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler,
        );
      } catch (e) {
        AppLogger.error(
          'Firebase init failed — push notifications disabled',
          name: 'Firebase',
          error: e,
        );
      }

      setupLocator();

      await locator<AuthNotifier>().checkAuth();

      // Request notification permission and register FCM token.
      await _initFCM();

      // Remove the splash screen now that the app is ready.
      FlutterNativeSplash.remove();

      runApp(const MyApp());
    },
    (error, stackTrace) {
      AppLogger.error(
        'Unhandled async error',
        name: 'ZonedGuarded',
        error: error,
        stackTrace: stackTrace,
      );
    },
  );
}

Future<void> _initFCM() async {
  try {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();

    final token = await messaging.getToken();
    if (token != null) {
      try {
        await locator<NotificationRepository>().registerToken(token);
      } catch (_) {
        // Not logged in yet — token will be registered after login.
      }
    }

    messaging.onTokenRefresh.listen((newToken) async {
      try {
        await locator<NotificationRepository>().registerToken(newToken);
      } catch (_) {}
    });
  } catch (e) {
    AppLogger.error(
      'FCM init failed — push notifications disabled',
      name: 'FCM',
      error: e,
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Arunika App',
      theme: ThemeData(primarySwatch: Colors.orange),
      routerConfig: AppRouter.router,
    );
  }
}
