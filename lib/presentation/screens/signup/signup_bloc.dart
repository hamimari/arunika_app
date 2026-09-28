import 'package:arunika_app/core/auth/auth_notifier.dart';
import 'package:arunika_app/core/storage/LocalProfileStorage.dart';
import 'package:arunika_app/core/storage/SecureStorageToken.dart';
import 'package:arunika_app/data/models/converter/user_response_converter.dart';
import 'package:arunika_app/data/models/request/consent_request.dart';
import 'package:arunika_app/data/models/request/signup_request.dart';
import 'package:arunika_app/data/models/response/signup_response.dart';
import 'package:arunika_app/data/repositories/auth_repository.dart';
import 'package:arunika_app/di/locator.dart';
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

      emit(
        state.copyWith(
          childName: child.name,
          childBirthDate: DateTime.parse(child.dateOfBirth),
          childGender: child.gender,
        ),
      );
    });

    on<ChildPrefilled>((event, emit) {
      emit(
        state.copyWith(
          childName: event.name,
          childGender: event.gender,
          childBirthDate: event.birthDate,
        ),
      );
    });

    on<NextButtonPressed>((event, emit) async {
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
      final addressError = state.address.isEmpty
          ? 'Alamat tidak boleh kosong'
          : null;

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
        return;
      }

      emit(state.copyWith(isCheckingAvailability: true));
      try {
        final (emailTaken, phoneTaken) = await repository.checkAvailability(
          email: state.email,
          phone: state.phone,
        );
        if (emailTaken || phoneTaken) {
          emit(
            state.copyWith(
              isCheckingAvailability: false,
              emailError: emailTaken ? 'Email sudah terdaftar' : null,
              phoneError: phoneTaken
                  ? 'Nomor telepon sudah terdaftar'
                  : null,
            ),
          );
          return;
        }
        emit(
          state.copyWith(isCheckingAvailability: false, navigateToChild: true),
        );
      } catch (_) {
        // Best-effort check — if the availability endpoint itself fails
        // (network blip, server error), don't block the user from
        // proceeding; the final submit's own uniqueness check is still
        // there as a backstop.
        emit(
          state.copyWith(isCheckingAvailability: false, navigateToChild: true),
        );
      }
    });

    on<TncToggled>((e, emit) => emit(state.copyWith(tncAccepted: e.accepted)));
    on<ParentalConsentToggled>(
      (e, emit) => emit(state.copyWith(parentalConsentAccepted: e.accepted)),
    );
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
      // The button is disabled until both boxes are ticked; this keeps the
      // rule true for any other way of dispatching the event.
      if (!state.consentGiven) return;

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
            consent: const ConsentRequest.current(),
          );

          final SignUpResponse response = await repository.signup(request);
          if (response.token.isEmpty) {
            emit(
              state.copyWith(
                isSubmitting: false,
                error:
                    'Sedang terjadi kesalahan, silakan coba beberapa saat lagi',
                isSuccess: false,
              ),
            );
            return;
          }
          await SecureTokenStorage.saveToken(response.token);
          await SecureTokenStorage.saveRefreshToken(response.refreshToken);
          // Stored like sign-in does, so screens that fetch the fresh profile
          // by user id (home, premium, payment) work without signing in again.
          // Older backends don't return the id; skip rather than store "".
          if (response.id.isNotEmpty) {
            await SecureTokenStorage.saveUserId(response.id);
          }
          await LocalProfileStorage.save(
            UserResponseConverter.toUserResponse(response),
          );
          // Notify AuthNotifier so isLoggedIn becomes true immediately —
          // without this the shell would still treat the user as a guest
          // right after registration. Best-effort: the account is already
          // created and the token/profile are already saved above, so a
          // failure here (e.g. a network blip) must not be reported as a
          // failed signup — AuthNotifier will pick up the saved token the
          // next time something checks auth state.
          try {
            await locator<AuthNotifier>().checkAuth();
          } catch (_) {}

          emit(state.copyWith(isSubmitting: false, isSuccess: true));
        } on DioException catch (e) {
          final message =
              e.response?.data['error'] ??
              'Sedang terjadi kesalahan, silakan coba beberapa saat lagi';
          emit(
            state.copyWith(
              isSubmitting: false,
              error: message,
              isSuccess: false,
            ),
          );
        } catch (e) {
          emit(
            state.copyWith(
              isSubmitting: false,
              error:
                  'Sedang terjadi kesalahan, silakan coba beberapa saat lagi',
              isSuccess: false,
            ),
          );
        }
      }
    });
  }
}
