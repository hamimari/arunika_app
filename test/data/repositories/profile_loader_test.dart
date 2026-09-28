import 'package:arunika_app/core/auth/auth_notifier.dart';
import 'package:arunika_app/data/models/response/subscription_info.dart';
import 'package:arunika_app/data/models/response/user_response.dart';
import 'package:arunika_app/data/repositories/profile_loader.dart';
import 'package:arunika_app/data/repositories/user_repository.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockUsers extends Mock implements UserRepository {}

class _StubAuth extends Mock implements AuthNotifier {
  _StubAuth(this._loggedIn);
  final bool _loggedIn;
  @override
  bool get isLoggedIn => _loggedIn;
}

UserResponse _user({bool subscribed = false, SubscriptionInfo? subscription}) =>
    UserResponse(
      id: 'u1',
      name: 'Budi',
      phoneNumber: '0812',
      emailAddress: 'budi@example.test',
      address: 'Jl.',
      city: 'Jakarta',
      children: const [],
      isSubscribed: subscribed,
      subscription: subscription,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _MockUsers users;
  String? storedUserId;

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (call) async => call.method == 'read' ? storedUserId : null,
        );
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    users = _MockUsers();
    storedUserId = 'u1';
  });

  test('returns nothing when logged out', () async {
    final loader = ProfileLoader(users, _StubAuth(false));

    expect(await loader.load(), isNull);
    verifyNever(() => users.findById(any()));
  });

  test('fetches the fresh profile by the stored user id', () async {
    when(() => users.findById('u1')).thenAnswer((_) async => _user());

    final profile = await ProfileLoader(users, _StubAuth(true)).load();

    expect(profile?.id, 'u1');
  });

  test('falls back to the cached profile when the network fails', () async {
    when(() => users.findById('u1')).thenAnswer((_) async => _user(subscribed: true));
    final loader = ProfileLoader(users, _StubAuth(true));
    await loader.load(); // caches it

    when(() => users.findById('u1')).thenThrow(Exception('offline'));
    final cached = await loader.load();

    expect(cached?.isSubscribed, isTrue);
  });

  test('reports the active subscription, or null without one', () async {
    const sub = SubscriptionInfo(planName: 'Bulanan', status: 'premium', canRenew: true);
    when(() => users.findById('u1')).thenAnswer(
      (_) async => _user(subscribed: true, subscription: sub),
    );
    expect((await ProfileLoader(users, _StubAuth(true)).activeSubscription())?.canRenew, isTrue);

    when(() => users.findById('u1')).thenAnswer((_) async => _user());
    expect(await ProfileLoader(users, _StubAuth(true)).activeSubscription(), isNull);
  });
}
