import 'dart:convert';

import 'package:arunika_app/core/storage/LocalProfileStorage.dart';
import 'package:arunika_app/data/models/response/user_response.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _key = 'user_profile';

final _profile = UserResponse(
  id: 'u1',
  name: 'Budi',
  phoneNumber: '0812',
  emailAddress: 'budi@example.test',
  address: 'Jl.',
  city: 'Jakarta',
  children: const [],
  isSubscribed: false,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'saves the profile to secure storage, never SharedPreferences',
    () async {
      await LocalProfileStorage.save(_profile);

      expect(
        (await LocalProfileStorage.get())?.emailAddress,
        'budi@example.test',
      );
      expect(await const FlutterSecureStorage().read(key: _key), isNotNull);
      expect((await SharedPreferences.getInstance()).getKeys(), isEmpty);
    },
  );

  test(
    'migrates a legacy SharedPreferences copy once, then deletes it',
    () async {
      SharedPreferences.setMockInitialValues({
        _key: jsonEncode(_profile.toJson()),
      });

      expect((await LocalProfileStorage.get())?.id, 'u1');

      expect((await SharedPreferences.getInstance()).getString(_key), isNull);
      expect(await const FlutterSecureStorage().read(key: _key), isNotNull);
    },
  );

  test('clear removes both the secure and the legacy copy', () async {
    await LocalProfileStorage.save(_profile);
    SharedPreferences.setMockInitialValues({
      _key: jsonEncode(_profile.toJson()),
    });

    await LocalProfileStorage.clear();

    expect(await LocalProfileStorage.get(), isNull);
    expect((await SharedPreferences.getInstance()).getString(_key), isNull);
  });

  test('returns null when nothing is cached', () async {
    expect(await LocalProfileStorage.get(), isNull);
  });
}
