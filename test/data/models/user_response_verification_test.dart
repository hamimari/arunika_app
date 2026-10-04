import 'package:arunika_app/data/models/converter/user_response_converter.dart';
import 'package:arunika_app/data/models/response/signup_response.dart';
import 'package:arunika_app/data/models/response/user_response.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> profileJson({Object? emailVerified = _absent}) => {
    'id': 'u1',
    'name': 'Budi',
    'phone_number': '081',
    'email_address': 'budi@example.com',
    'address': 'Jl.',
    'city': 'Jakarta',
    'children': <dynamic>[],
    'is_subscribed': false,
    if (emailVerified != _absent) 'email_verified': emailVerified,
  };

  group('UserResponse.emailVerified', () {
    test('should_read_verification_state_from_profile_json', () {
      expect(
        UserResponse.fromJson(profileJson(emailVerified: false)).emailVerified,
        isFalse,
      );
      expect(
        UserResponse.fromJson(profileJson(emailVerified: true)).emailVerified,
        isTrue,
      );
    });

    test('should_default_to_verified_when_field_is_absent', () {
      // A profile from a backend that predates the field must never make an
      // existing user look unverified and get nagged by the banner.
      expect(UserResponse.fromJson(profileJson()).emailVerified, isTrue);
    });

    test('should_round_trip_through_toJson', () {
      final user = UserResponse.fromJson(profileJson(emailVerified: false));
      expect(user.toJson()['email_verified'], isFalse);
    });
  });

  test('should_treat_a_freshly_registered_account_as_unverified', () {
    // The converter builds the profile cached right after signup. Defaulting
    // it to verified would hide the prompt from exactly the users who need it.
    final converted = UserResponseConverter.toUserResponse(
      SignUpResponse(
        id: 'u1',
        name: 'Budi',
        phoneNumber: '081',
        email: 'budi@example.com',
        address: 'Jl.',
        city: 'Jakarta',
        children: const [],
        token: 't',
        refreshToken: 'r',
      ),
    );

    expect(converted.emailVerified, isFalse);
  });
}

const _absent = Object();
