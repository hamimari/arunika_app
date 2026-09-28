import 'package:arunika_app/core/feature_flags/feature_flags_notifier.dart';
import 'package:arunika_app/data/api/feature_flag_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockFeatureFlagApi extends Mock implements FeatureFlagApi {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockFeatureFlagApi api;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    api = MockFeatureFlagApi();
  });

  test('features default to enabled before anything is fetched', () {
    final notifier = FeatureFlagsNotifier(api);
    expect(notifier.qrScanEnabled, isTrue);
    expect(notifier.printableCardsEnabled, isTrue);
  });

  test('alternative billing fails closed while unknown', () async {
    final notifier = FeatureFlagsNotifier(api);
    expect(notifier.alternativeBillingEnabled, isFalse, reason: 'never fetched');

    when(() => api.fetchFlags()).thenAnswer((_) async => {'qr_scan': true});
    await notifier.refresh();
    expect(notifier.alternativeBillingEnabled, isFalse, reason: 'missing from the backend');

    when(() => api.fetchFlags()).thenAnswer((_) async => {'alternative_billing': true});
    await notifier.refresh();
    expect(notifier.alternativeBillingEnabled, isTrue, reason: 'explicitly enabled');
  });

  test('refresh applies backend flags, notifies, and caches them', () async {
    when(
      () => api.fetchFlags(),
    ).thenAnswer((_) async => {'qr_scan': false, 'printable_cards': true});
    final notifier = FeatureFlagsNotifier(api);
    var notified = 0;
    notifier.addListener(() => notified++);

    await notifier.refresh();

    expect(notifier.qrScanEnabled, isFalse);
    expect(notifier.printableCardsEnabled, isTrue);
    expect(notified, 1);

    // A fresh instance restores the cached values without the network.
    final restored = FeatureFlagsNotifier(MockFeatureFlagApi());
    await restored.loadCached();
    expect(restored.qrScanEnabled, isFalse);
  });

  test('refresh failure keeps the current flags', () async {
    when(() => api.fetchFlags()).thenAnswer((_) async => {'qr_scan': false});
    final notifier = FeatureFlagsNotifier(api);
    await notifier.refresh();

    when(() => api.fetchFlags()).thenThrow(Exception('offline'));
    await notifier.refresh();

    expect(notifier.qrScanEnabled, isFalse);
  });

  test('concurrent refreshes share one request', () async {
    when(() => api.fetchFlags()).thenAnswer((_) async => {'qr_scan': true});
    final notifier = FeatureFlagsNotifier(api);

    await Future.wait([notifier.refresh(), notifier.refresh()]);

    verify(() => api.fetchFlags()).called(1);
  });
}
