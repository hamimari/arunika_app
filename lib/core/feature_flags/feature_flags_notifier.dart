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
  // Midtrans as Google Play's User Choice Billing alternative. Off unless
  // explicitly enabled — see FeatureFlagsNotifier.failClosed.
  static const String alternativeBilling = 'alternative_billing';
  // Tumbuh Kembang: the Tumbuh tab and the Beranda growth card. Off unless
  // enabled, so an app talking to a backend without the growth API never
  // shows it.
  static const String growthTracking = 'growth_tracking';
  // Belajar Huruf: the Huruf card on Belajar and the Beranda "Lanjutkan
  // belajar" row. Off unless enabled, like growth tracking.
  static const String belajarHuruf = 'belajar_huruf';
  // Belajar Angka: the Angka card on Belajar and on the Beranda "Lanjutkan
  // belajar" row. Off unless enabled, like Huruf.
  static const String belajarAngka = 'belajar_angka';
}

/// Holds the backoffice-controlled feature switches.
///
/// Starts from the last values cached on device so the UI doesn't flash a
/// hidden feature on launch, then refreshes from the backend. Flags the
/// backend doesn't know about (or that were never fetched) default to
/// enabled, so an unreachable backend never hides existing features —
/// except the [failClosed] ones, which default to disabled.
class FeatureFlagsNotifier extends ChangeNotifier {
  static const _cacheKey = 'feature_flags';

  final FeatureFlagApi _api;
  Map<String, bool> _flags = const {};
  Future<void>? _inFlight;

  FeatureFlagsNotifier(this._api);

  /// Flags that must default to off when unknown, because defaulting to on
  /// would re-open something only allowed when explicitly enabled — Midtrans
  /// is only permitted alongside Google Play under User Choice Billing.
  static const Set<String> failClosed = {
    FeatureFlag.alternativeBilling,
    FeatureFlag.growthTracking,
    FeatureFlag.belajarHuruf,
    FeatureFlag.belajarAngka,
  };

  bool isEnabled(String key) => _flags[key] ?? !failClosed.contains(key);

  bool get printableCardsEnabled => isEnabled(FeatureFlag.printableCards);
  bool get qrScanEnabled => isEnabled(FeatureFlag.qrScan);
  bool get alternativeBillingEnabled =>
      isEnabled(FeatureFlag.alternativeBilling);
  bool get growthTrackingEnabled => isEnabled(FeatureFlag.growthTracking);
  bool get belajarHurufEnabled => isEnabled(FeatureFlag.belajarHuruf);
  bool get belajarAngkaEnabled => isEnabled(FeatureFlag.belajarAngka);

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
