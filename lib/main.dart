import 'dart:async';

import 'package:arunika_app/core/auth/auth_notifier.dart';
import 'package:arunika_app/core/logger/app_logger.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:arunika_app/presentation/navigation/app_router.dart';
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
        // Forward to the default handler so the error is still logged in debug.
        FlutterError.presentError(details);
      };

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
    },
  );
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
