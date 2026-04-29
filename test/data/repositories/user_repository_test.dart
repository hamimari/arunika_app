// ignore_for_file: inference_failure_on_function_invocation

import 'package:arunika_app/data/api/user_api.dart';
import 'package:arunika_app/data/models/request/update_user_request.dart';
import 'package:arunika_app/data/repositories/user_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockUserApi extends Mock implements UserApi {}

Map<String, dynamic> _userJson(String id) => {
  'data': {
    'id': id,
    'name': 'Test User',
    'phone_number': '08123456789',
    'email_address': 'test@example.com',
    'address': 'Jl. Test',
    'city': 'Jakarta',
    'children': <dynamic>[],
  },
};

void main() {
  late MockUserApi mockApi;
  late UserRepository repo;

  setUp(() {
    mockApi = MockUserApi();
    repo = UserRepository(mockApi);
    registerFallbackValue(<String, dynamic>{});
  });

  group('UserRepository', () {
    test('findById returns UserResponse on success', () async {
      when(
        () => mockApi.findById('u1'),
      ).thenAnswer((_) async => _userJson('u1'));

      final result = await repo.findById('u1');

      expect(result.id, 'u1');
      expect(result.name, 'Test User');
    });

    test('findById propagates exception on failure', () async {
      when(() => mockApi.findById(any())).thenThrow(Exception('not found'));

      expect(() => repo.findById('bad'), throwsException);
    });

    test('update returns updated UserResponse on success', () async {
      when(
        () => mockApi.update(any()),
      ).thenAnswer((_) async => _userJson('u1'));

      final result = await repo.update(
        UpdateUserRequest(
          id: 'u1',
          name: 'Updated',
          phoneNumber: '081',
          emailAddress: 'updated@example.com',
          address: 'Jl.',
          city: 'Jkt',
          child: [],
        ),
      );

      expect(result.name, 'Test User');
    });

    test('update propagates exception on failure', () async {
      when(() => mockApi.update(any())).thenThrow(Exception('server error'));

      expect(
        () => repo.update(
          UpdateUserRequest(
            id: 'u1',
            name: '',
            phoneNumber: '',
            emailAddress: '',
            address: '',
            city: '',
            child: [],
          ),
        ),
        throwsException,
      );
    });
  });
}
