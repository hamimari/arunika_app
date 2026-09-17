import 'dart:convert';

import 'package:arunika_app/core/logger/app_logger.dart';
import 'package:arunika_app/data/api/feature_flag_api.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keys of the remote on/off switches managed from the backoffice
/// (backend table `app_feature_flags`).
class FeatureFlag {
  static const String printableCards = 'printable_cards';
  static const String qrScan = 'qr_scan';
}

/// Holds the backoffice-controlled feature switches.
///
/// Starts from the last values cached on device so the UI doesn't flash a
/// hidden feature on launch, then refreshes from the backend. Flags the
/// backend doesn't know about (or that were never fetched) default to
/// enabled, so an unreachable backend never hides existing features.
class FeatureFlagsNotifier extends ChangeNotifier {
  static const _cacheKey = 'feature_flags';

  final FeatureFlagApi _api;
  Map<String, bool> _flags = const {};
  Future<void>? _inFlight;

  FeatureFlagsNotifier(this._api);

  bool isEnabled(String key) => _flags[key] ?? true;

  bool get printableCardsEnabled => isEnabled(FeatureFlag.printableCards);
  bool get qrScanEnabled => isEnabled(FeatureFlag.qrScan);

  Future<void> loadCached() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null) return;
      _setFlags((jsonDecode(raw) as Map<String, dynamic>).cast<String, bool>());
    } catch (e, st) {
      AppLogger.error(
        'Failed to read cached feature flags',
        name: 'FeatureFlags',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Fetches the latest flags. Concurrent calls share one request; failures
  /// keep the current values.
  Future<void> refresh() =>
      _inFlight ??= _refresh().whenComplete(() => _inFlight = null);

  Future<void> _refresh() async {
    try {
      final json = await _api.fetchFlags();
      final flags = {
        for (final e in json.entries)
          if (e.value is bool) e.key: e.value as bool,
      };
      _setFlags(flags);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(flags));
    } catch (e) {
      AppLogger.warning(
        'Failed to refresh feature flags',
        name: 'FeatureFlags',
        error: e,
      );
    }
  }

  void _setFlags(Map<String, bool> flags) {
    if (mapEquals(flags, _flags)) return;
    _flags = Map.unmodifiable(flags);
    notifyListeners();
  }
}
