import 'package:arunika_app/core/auth/auth_notifier.dart';
import 'package:arunika_app/data/repositories/premium_pack_repository.dart';
import 'package:arunika_app/data/repositories/profile_loader.dart';
import 'package:arunika_app/data/repositories/user_repository.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:arunika_app/services/billing_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Everything is registered lazily, so wiring the container touches no
/// platform code — this proves the graph resolves, catching a registration
/// that is missing or depends on something that isn't registered.
void main() {
  setUp(() async => locator.reset());
  tearDown(() async => locator.reset());

  test('wires the purchase and profile dependencies', () {
    setupLocator();

    final profiles = locator<ProfileLoader>();
    expect(profiles, isA<ProfileLoader>());
    expect(identical(profiles, locator<ProfileLoader>()), isTrue,
        reason: 'a lazy singleton, shared by every screen');
    expect(locator<UserRepository>(), isA<UserRepository>());
    expect(locator<AuthNotifier>(), isA<AuthNotifier>());
    expect(locator<PremiumPackRepository>(), isA<PremiumPackRepository>());
    expect(locator.isRegistered<BillingService>(), isTrue);
  });
}
