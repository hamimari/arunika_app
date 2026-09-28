import 'package:arunika_app/core/auth/auth_notifier.dart';
import 'package:arunika_app/core/auth/consent_gate.dart';
import 'package:arunika_app/data/repositories/profile_loader.dart';
import 'package:arunika_app/data/repositories/user_repository.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/consent_test_setup.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockUserRepository users;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockSecureStorage();
    ConsentGate.reset();
    users = MockUserRepository();
    locator.registerSingleton<UserRepository>(users);
    locator.registerSingleton<AuthNotifier>(SignedInAuthNotifier());
    locator.registerSingleton<ProfileLoader>(
      ProfileLoader(users, locator<AuthNotifier>()),
    );
  });

  tearDown(locator.reset);

  test(
    'should_send_a_user_with_outdated_consent_to_the_consent_screen',
    () async {
      when(
        () => users.findById('u1'),
      ).thenAnswer((_) async => profile(consentRequired: true));

      expect(await ConsentGate.redirect(), '/consent');
    },
  );

  test('should_let_a_user_with_current_consent_through', () async {
    when(
      () => users.findById('u1'),
    ).thenAnswer((_) async => profile(consentRequired: false));

    expect(await ConsentGate.redirect(), isNull);
  });

  test('should_load_the_profile_once_per_session_after_passing', () async {
    when(
      () => users.findById('u1'),
    ).thenAnswer((_) async => profile(consentRequired: false));

    await ConsentGate.redirect();
    await ConsentGate.redirect();

    verify(() => users.findById('u1')).called(1);
  });

  test('should_keep_asking_until_consent_is_given', () async {
    when(
      () => users.findById('u1'),
    ).thenAnswer((_) async => profile(consentRequired: true));

    expect(await ConsentGate.redirect(), '/consent');
    expect(await ConsentGate.redirect(), '/consent');
  });

  test('should_stop_redirecting_once_marked_accepted', () async {
    when(
      () => users.findById('u1'),
    ).thenAnswer((_) async => profile(consentRequired: true));

    await ConsentGate.markAccepted();

    expect(await ConsentGate.redirect(), isNull);
  });

  test('should_fail_open_when_the_profile_cannot_be_loaded', () async {
    // Offline with nothing cached: don't lock the user out of the app.
    when(() => users.findById('u1')).thenThrow(Exception('offline'));

    expect(await ConsentGate.redirect(), isNull);
  });

  test('should_check_again_for_a_different_user', () async {
    when(
      () => users.findById('u1'),
    ).thenAnswer((_) async => profile(consentRequired: false));
    await ConsentGate.redirect();

    mockSecureStorage(userId: 'u2');
    when(
      () => users.findById('u2'),
    ).thenAnswer((_) async => profile(consentRequired: true));

    expect(await ConsentGate.redirect(), '/consent');
  });
}
