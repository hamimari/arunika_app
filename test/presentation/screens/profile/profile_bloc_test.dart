// ignore_for_file: inference_failure_on_function_invocation

import 'package:arunika_app/data/models/request/update_user_request.dart';
import 'package:arunika_app/data/models/response/child_response.dart';
import 'package:arunika_app/data/models/response/user_response.dart';
import 'package:arunika_app/data/repositories/user_repository.dart';
import 'package:arunika_app/presentation/screens/profile/profile_bloc.dart';
import 'package:arunika_app/presentation/screens/profile/profile_event.dart';
import 'package:arunika_app/presentation/screens/profile/profile_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockUserRepository extends Mock implements UserRepository {}

UserResponse _user() => UserResponse(
  id: 'u1',
  name: 'Test User',
  phoneNumber: '08123456789',
  emailAddress: 'test@example.com',
  address: 'Jl. Test',
  city: 'Jakarta',
  children: [
    ChildResponse(
      id: 'c1',
      name: 'Child',
      gender: 'male',
      dateOfBirth: '2020-01-01',
    ),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockUserRepository mockRepo;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockRepo = MockUserRepository();
    registerFallbackValue(
      UpdateUserRequest(
        id: 'u1',
        name: '',
        phoneNumber: '',
        emailAddress: '',
        address: '',
        city: '',
        child: [],
      ),
    );
  });

  group('ProfileBloc', () {
    blocTest<ProfileBloc, ProfileState>(
      'update success emits isSuccess=true',
      build: () {
        when(() => mockRepo.update(any())).thenAnswer((_) async => _user());
        return ProfileBloc(repository: mockRepo);
      },
      seed: () => ProfileState(
        user: _user(),
        name: 'New Name',
        phone: '08123456789',
        email: 'test@example.com',
        address: 'Jl. Test',
        city: 'Jakarta',
        childName: 'Child',
        childGender: 'male',
        childBirthDate: DateTime(2020, 1, 1),
      ),
      act: (b) => b.add(EditSubmitted()),
      expect: () => [
        isA<ProfileState>().having((s) => s.isSuccess, 'success', false),
        isA<ProfileState>().having((s) => s.isSuccess, 'success', true),
      ],
    );

    blocTest<ProfileBloc, ProfileState>(
      'update failure emits error',
      build: () {
        when(() => mockRepo.update(any())).thenThrow(Exception('fail'));
        return ProfileBloc(repository: mockRepo);
      },
      seed: () => ProfileState(
        user: _user(),
        name: 'Name',
        phone: '081',
        email: 'test@example.com',
        address: 'Jl.',
        city: 'Jkt',
        childName: 'Kid',
        childGender: 'male',
        childBirthDate: DateTime(2020),
      ),
      act: (b) => b.add(EditSubmitted()),
      expect: () => [
        isA<ProfileState>().having((s) => s.isSuccess, 'success', false),
        isA<ProfileState>().having((s) => s.error, 'error', isNotNull),
      ],
    );

    blocTest<ProfileBloc, ProfileState>(
      'EditSubmitted with empty fields emits validation errors',
      build: () => ProfileBloc(repository: mockRepo),
      act: (b) => b.add(EditSubmitted()),
      expect: () => [
        isA<ProfileState>().having((s) => s.nameError, 'nameError', isNotNull),
      ],
    );

    blocTest<ProfileBloc, ProfileState>(
      'NameChanged clears nameError',
      build: () => ProfileBloc(repository: mockRepo),
      act: (b) => b.add(NameChanged('Alice')),
      expect: () => [
        isA<ProfileState>().having((s) => s.name, 'name', 'Alice'),
      ],
    );
  });
}
