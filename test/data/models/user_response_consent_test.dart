import 'package:arunika_app/data/models/request/consent_request.dart';
import 'package:arunika_app/data/models/response/user_response.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> profileJson({Object? consentRequired = _absent}) => {
    'id': 'u1',
    'name': 'Budi',
    'phone_number': '081',
    'email_address': 'budi@example.com',
    'address': 'Jl.',
    'city': 'Jakarta',
    'children': <dynamic>[],
    'is_subscribed': false,
    if (consentRequired != _absent) 'consent_required': consentRequired,
  };

  group('UserResponse.consentRequired', () {
    test('should_read_the_flag_from_profile_json', () {
      expect(
        UserResponse.fromJson(
          profileJson(consentRequired: true),
        ).consentRequired,
        isTrue,
      );
      expect(
        UserResponse.fromJson(
          profileJson(consentRequired: false),
        ).consentRequired,
        isFalse,
      );
    });

    test('should_default_to_not_required_when_the_backend_omits_it', () {
      // A backend that predates consent must never lock users out.
      expect(UserResponse.fromJson(profileJson()).consentRequired, isFalse);
    });

    test('should_survive_the_local_profile_cache_round_trip', () {
      final cached = UserResponse.fromJson(
        UserResponse.fromJson(profileJson(consentRequired: true)).toJson(),
      );
      expect(cached.consentRequired, isTrue);
    });
  });

  test('should_serialise_consent_request_with_the_backend_field_names', () {
    expect(const ConsentRequest.current().toJson().keys, {
      'terms_version',
      'privacy_version',
      'parental_version',
    });
  });
}

const _absent = Object();
