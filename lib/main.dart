import 'dart:async';
import 'dart:io' show HandshakeException, Platform, SocketException;

import 'package:arunika_app/core/auth/auth_notifier.dart';
import 'package:arunika_app/core/feature_flags/feature_flags_notifier.dart';
import 'package:arunika_app/core/logger/app_logger.dart';
import 'package:dio/dio.dart';
import 'package:arunika_app/core/theme/app_theme.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:arunika_app/firebase_options.dart';
import 'package:arunika_app/presentation/navigation/app_router.dart';
import 'package:arunika_app/services/billing_service.dart';
import 'package:arunika_app/services/push_notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:intl/date_symbol_data_local.dart';

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
        if (_isExpectedRuntimeError(details.exception)) {
          FirebaseCrashlytics.instance.recordFlutterError(details);
        } else {
          FirebaseCrashlytics.instance.recordFlutterFatalError(details);
        }
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

      // Reconcile any Google Play purchase the app never got to confirm
      // with the backend (killed/crashed/offline between the purchase
      // completing and calling verify) — Google auto-refunds an
      // unacknowledged purchase after 3 days, so this must run on every
      // app start, not only within the purchase flow that began it.
      if (!kIsWeb && Platform.isAndroid && locator<AuthNotifier>().isLoggedIn) {
        unawaited(locator<BillingService>().syncPendingPurchases());
      }

      // Apply the last-known feature switches before the first frame so a
      // feature hidden from the backoffice never flashes on screen, then
      // fetch the current ones in the background.
      final featureFlags = locator<FeatureFlagsNotifier>();
      await featureFlags.loadCached();
      unawaited(featureFlags.refresh());

      await initializeDateFormatting('id_ID');

      // Remove the splash screen now that the app is ready.
      FlutterNativeSplash.remove();

      runApp(const MyApp());

      // Asks for notification permission, so start it once the UI is up.
      unawaited(locator<PushNotificationService>().init());
    },
    (error, stackTrace) {
      AppLogger.error(
        'Unhandled async error',
        name: 'ZonedGuarded',
        error: error,
        stackTrace: stackTrace,
      );
      // Forward uncaught async errors to Crashlytics in release mode.
      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        fatal: !_isExpectedRuntimeError(error),
      );
    },
  );
}

/// Errors caused by the user's network, session or device rather than a bug:
/// failed/blocked requests (including ISPs that hijack TLS and cause a
/// hostname-mismatch handshake error), Google Fonts failing to download
/// (the app falls back to the default font), and AR calls racing a node
/// that was just removed. Still reported, but as non-fatal.
bool _isExpectedRuntimeError(Object error) {
  if (error is DioException || error is HandshakeException) return true;
  if (error is SocketException || error is TimeoutException) return true;
  if (error is MissingPluginException) return false;
  if (error is PlatformException && error.code == 'NODE_NOT_FOUND') return true;
  return error.toString().contains('Failed to load font');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Arunika World',
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
      // Lets widgets such as the date picker switch to Indonesian on request
      // (the app's own locale stays the default).
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
    );
  }
}
