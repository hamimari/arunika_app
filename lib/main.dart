import 'dart:async';

import 'package:arunika_app/core/auth/auth_notifier.dart';
import 'package:arunika_app/core/logger/app_logger.dart';
import 'package:arunika_app/core/theme/app_theme.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:arunika_app/firebase_options.dart';
import 'package:arunika_app/presentation/navigation/app_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

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
        // Forward to Crashlytics in release mode.
        FirebaseCrashlytics.instance.recordFlutterFatalError(details);
        // Forward to the default handler so the error is still logged in debug.
        FlutterError.presentError(details);
      };

      // Initialise Firebase before anything else.
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        // Disable crash reporting outside release builds to keep the dashboard
        // free of debug/test noise.
        await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
          kReleaseMode,
        );
      } catch (e, st) {
        AppLogger.error(
          'Firebase initialisation failed',
          name: 'Firebase',
          error: e,
          stackTrace: st,
        );
        // Re-throw so developers see the error clearly during development.
        rethrow;
      }

      // Keep splash screen visible until we finish initialisation.
      FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

      setupLocator();

      await locator<AuthNotifier>().checkAuth();

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
      // Forward uncaught async errors to Crashlytics in release mode.
      FirebaseCrashlytics.instance.recordError(error, stackTrace, fatal: true);
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Arunika World',
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
    );
  }
}
