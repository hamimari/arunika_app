import 'package:arunika_app/core/storage/LocalProfileStorage.dart';
import 'package:arunika_app/core/storage/SecureStorageToken.dart';
import 'package:arunika_app/data/models/converter/user_response_converter.dart';
import 'package:arunika_app/data/models/request/signup_request.dart';
import 'package:arunika_app/data/models/response/child_response.dart';
import 'package:arunika_app/data/models/response/signup_response.dart';
import 'package:arunika_app/data/repositories/auth_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'signup_event.dart';
import 'signup_state.dart';

class SignupBloc extends Bloc<SignupEvent, SignupState> {
  final AuthRepository repository;

  SignupBloc({required this.repository}) : super(SignupInitial()) {
    on<NameChanged>((event, emit) {
      emit(state.copyWith(name: event.name, nameError: null));
    });

    on<PhoneChanged>((event, emit) {
      emit(state.copyWith(phone: event.phone, phoneError: null));
    });

    on<EmailChanged>((event, emit) {
      emit(state.copyWith(email: event.email, emailError: null));
    });

    on<CityChanged>((event, emit) {
      emit(state.copyWith(city: event.city, cityError: null));
    });

    on<AddressChanged>((event, emit) {
      emit(state.copyWith(address: event.address, cityError: null));
    });

    on<PasswordChanged>((event, emit) {
      emit(state.copyWith(password: event.password, passwordError: null));
    });

    on<PrefillChildData>((event, emit) {
      final child = event.child;

      emit(state.copyWith(
        childName: child.name,
        childBirthDate: DateTime.parse(child.dateOfBirth),
        childGender: child.gender,
      ));
    });

    on<ChildPrefilled>((event, emit) {
      emit(state.copyWith(
        childName: event.name,
        childGender: event.gender,
        childBirthDate: event.birthDate,
      ));
    });

    on<NextButtonPressed>((event, emit) {
      final nameError = state.name.isEmpty ? 'Nama tidak boleh kosong' : null;
      final phoneError = state.phone.isEmpty
          ? 'Nomor telepon tidak boleh kosong'
          : null;
      final emailError = state.email.isEmpty
          ? 'Email tidak boleh kosong'
          : !RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(state.email)
          ? 'Format email tidak valid'
          : null;
      final passwordError = state.password.isEmpty
          ? 'Kata sandi tidak boleh kosong'
          : null;
      final cityError = state.city.isEmpty ? 'Kota tidak boleh kosong' : null;
      final addressError = state.address.isEmpty ? 'Alamat tidak boleh kosong' : null;

      final hasError = [
        nameError,
        phoneError,
        emailError,
        passwordError,
        cityError,
        addressError,
      ].any((error) => error != null);

      if (hasError) {
        emit(
          state.copyWith(
            nameError: nameError,
            phoneError: phoneError,
            emailError: emailError,
            passwordError: passwordError,
            cityError: cityError,
            addressError: addressError,
          ),
        );
      } else {
        emit(state.copyWith(navigateToChild: true));
      }
    });

    on<TncToggled>((e, emit) => emit(state.copyWith(tncAccepted: e.accepted)));
    on<ChildNameChanged>((e, emit) => emit(state.copyWith(childName: e.name)));
    on<ChildBirthDateChanged>(
      (e, emit) => emit(state.copyWith(childBirthDate: e.birthDate)),
    );
    on<ChildGenderChanged>(
      (e, emit) => emit(state.copyWith(childGender: e.gender)),
    );
    on<ObscurePasswordToggled>((event, emit) {
      emit(state.copyWith(obscurePassword: event.obscure));
    });
    on<NavigateToChildReset>((event, emit) {
      emit(state.copyWith(navigateToChild: event.navigateToChild));
    });

    on<SignupSubmitted>((e, emit) async {
      final childNameError = state.childName.isEmpty
          ? 'Nama anak wajib diisi'
          : null;
      final bodError = state.childBirthDate == null
          ? 'Tanggal lahir wajib diisi'
          : null;
      final genderError = state.childGender == null
          ? 'Jenis kelamin wajib diisi'
          : null;

      final hasError = [
        childNameError,
        bodError,
        genderError,
      ].any((error) => error != null);

      if (hasError) {
        emit(
          state.copyWith(
            childNameError: childNameError,
            childBirthDateError: bodError,
            childGenderError: genderError,
          ),
        );
      } else {
        emit(state.copyWith(isSubmitting: true));
        try {
          final request = SignUpRequest(
            name: state.name,
            phoneNumber: state.phone,
            email: state.email,
            address: state.address,
            city: state.city,
            password: state.password,
            child: ChildRequest(
              name: state.childName,
              gender: state.childGender!,
              dateOfBirth: state.childBirthDate!.toIso8601String(),
            ),
          );

          final SignUpResponse response = await repository.signup(request);
          if (response.token.isEmpty) {
            emit(state.copyWith(
              isSubmitting: false,
              error: 'Sedang terjadi kesalahan, silakan coba beberapa saat lagi',
              isSuccess: false,
            ));
            return;
          }
          await SecureTokenStorage.saveToken(response.token);
          await SecureTokenStorage.saveRefreshToken(response.refreshToken);
          await LocalProfileStorage.save(UserResponseConverter.toUserResponse(response));

          emit(state.copyWith(
            isSubmitting: false,
            isSuccess: true,
          ));
        } on DioException catch (e) {
          final message = e.response?.data['error'] ?? 'Sedang terjadi kesalahan, silakan coba beberapa saat lagi';
          emit(state.copyWith(
            isSubmitting: false,
            error: message,
            isSuccess: false,
          ));
        } catch (e) {
          emit(state.copyWith(
            isSubmitting: false,
            error: 'Sedang terjadi kesalahan, silakan coba beberapa saat lagi',
            isSuccess: false,
          ));
        }
      }
    });
  }
}
