import 'package:arunika_app/core/storage/LocalProfileStorage.dart';
import 'package:arunika_app/data/models/request/update_user_request.dart';
import 'package:arunika_app/data/models/response/user_response.dart';
import 'package:arunika_app/data/repositories/user_repository.dart';
import 'package:arunika_app/presentation/screens/profile/profile_event.dart';
import 'package:arunika_app/presentation/screens/profile/profile_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final UserRepository repository;

  ProfileBloc({required this.repository}) : super(ProfileState()) {
    on<ProfileInitial>((event, emit) async {
      final profile = await LocalProfileStorage.get();
      if (profile != null) {
        emit(state.copyWith(user: profile));
        emit(state.copyWith(name: profile.name));
        emit(state.copyWith(phone: profile.phoneNumber));
        emit(state.copyWith(email: profile.emailAddress));
        emit(state.copyWith(city: profile.city));
        emit(state.copyWith(address: profile.address));
        emit(
          state.copyWith(
            childBirthDate: profile.children.isNotEmpty
                ? DateTime.parse(profile.children.first.dateOfBirth)
                : null,
          ),
        );
        emit(state.copyWith(childGender: profile.children.first.gender));
      }
    });
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
    on<ChildNameChanged>((e, emit) => emit(state.copyWith(childName: e.name)));
    on<ChildBirthDateChanged>(
      (e, emit) => emit(state.copyWith(childBirthDate: e.birthDate)),
    );
    on<ChildGenderChanged>(
      (e, emit) => emit(state.copyWith(childGender: e.gender)),
    );

    on<ChildPrefilled>((event, emit) {
      emit(state.copyWith(childName: event.name));
    });

    on<EditSubmitted>((e, emit) async {
      final nameError = state.name.isEmpty ? 'Nama tidak boleh kosong' : null;
      final phoneError = state.phone.isEmpty
          ? 'Nomor telepon tidak boleh kosong'
          : null;
      final emailError = state.email.isEmpty
          ? 'Email tidak boleh kosong'
          : !RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(state.email)
          ? 'Format email tidak valid'
          : null;
      final cityError = state.city.isEmpty ? 'Kota tidak boleh kosong' : null;
      final addressError = state.address.isEmpty
          ? 'Alamat tidak boleh kosong'
          : null;
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
        nameError,
        phoneError,
        emailError,
        cityError,
        addressError,
        childNameError,
        bodError,
        genderError,
      ].any((error) => error != null);

      if (hasError) {
        emit(
          state.copyWith(
            nameError: nameError,
            phoneError: phoneError,
            emailError: emailError,
            cityError: cityError,
            addressError: addressError,
            childNameError: childNameError,
            childBirthDateError: bodError,
            childGenderError: genderError,
          ),
        );
      } else {
        emit(state.copyWith(isSuccess: false));
        final request = UpdateUserRequest(
          id: state.user!.id,
          name: state.name,
          phoneNumber: state.phone,
          emailAddress: state.email,
          city: state.city,
          address: state.address,
          child: [
            UpdateChildRequest(
              name: state.childName,
              gender: state.childGender!,
              birthDate: state.childBirthDate!.toIso8601String(),
              id: state.user!.children.first.id
            ),
          ],
        );
        try {
          final UserResponse response = await repository.update(request);
          await LocalProfileStorage.save(response);
          emit(state.copyWith(
            isSuccess: true,
            user: response,
          ));
        } catch (_) {
          emit(state.copyWith(
            error: 'Sedang terjadi kesalahan, silakan coba beberapa saat lagi',
            isSuccess: false,
          ));
          return;
        }


      }
    });
  }
}
