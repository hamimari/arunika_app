import 'package:arunika_app/presentation/screens/profile/profile_bloc.dart';
import 'package:arunika_app/presentation/screens/profile/profile_event.dart';
import 'package:arunika_app/presentation/screens/profile/profile_state.dart';
import 'package:arunika_app/presentation/screens/widgets/app_button.dart';
import 'package:arunika_app/presentation/screens/widgets/date_field.dart';
import 'package:arunika_app/presentation/screens/widgets/dropdown_field.dart';
import 'package:arunika_app/presentation/screens/widgets/phone_text_field.dart';
import 'package:arunika_app/presentation/screens/widgets/text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChildForm extends StatefulWidget {
  final VoidCallback onSubmit;

  const ChildForm({super.key, required this.onSubmit});

  @override
  State<ChildForm> createState() => _ChildFormState();
}

class _ChildFormState extends State<ChildForm> {
  late final TextEditingController nameController;
  late final TextEditingController phoneController;
  late final TextEditingController emailController;
  late final TextEditingController cityController;
  late final TextEditingController addressController;
  late final TextEditingController childNameController;

  @override
  void initState() {
    super.initState();

    final state = context.read<ProfileBloc>().state;
    nameController = TextEditingController(text: state.user?.name);
    phoneController = TextEditingController(text: state.user?.phoneNumber);
    emailController = TextEditingController(text: state.user?.emailAddress);
    cityController = TextEditingController(text: state.user?.city);
    addressController = TextEditingController(text: state.user?.address);
    childNameController = TextEditingController(text: state.user?.children.first.name);
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    cityController.dispose();
    addressController.dispose();
    childNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BlocBuilder<ProfileBloc, ProfileState>(
          buildWhen: (prev, curr) => prev.nameError != curr.nameError,
          builder: (context, state) {
            return AppTextField(
              controller: nameController,
              label: 'Nama Kamu (Orang Tua)',
              hint: 'Contoh : Nagita Slavina',
              onChanged: (value) =>
                  context.read<ProfileBloc>().add(NameChanged(value)),
              error: state.nameError,
            );
          },
        ),

        BlocBuilder<ProfileBloc, ProfileState>(
          buildWhen: (prev, curr) => prev.phoneError != curr.phoneError,
          builder: (context, state) {
            return AppPhoneTextField(
              controller: phoneController,
              label: 'Nomor Telepon',
              hint: '812356789',
              onChanged: (value) => context.read<ProfileBloc>()
                  .add(PhoneChanged(value)),
              error: state.phoneError,
            );
          },
        ),

        BlocBuilder<ProfileBloc, ProfileState>(
          buildWhen: (prev, curr) => prev.emailError != curr.emailError,
          builder: (context, state) {
            return AppTextField(
              controller: emailController,
              label: 'Email',
              hint: 'nagita.slavina@mail.com',
              onChanged: (value) => context.read<ProfileBloc>()
                  .add(EmailChanged(value)),
              error: state.emailError,
            );
          },
        ),

        BlocBuilder<ProfileBloc, ProfileState>(
          buildWhen: (prev, curr) => prev.cityError != curr.cityError,
          builder: (context, state) {
            return AppTextField(
              controller: cityController,
              label: 'Kota Tinggal',
              hint: 'Jakarta',
              onChanged: (value) => context.read<ProfileBloc>()
                  .add(CityChanged(value)),
              error: state.cityError,
            );
          },
        ),

        BlocBuilder<ProfileBloc, ProfileState>(
          buildWhen: (prev, curr) => prev.addressError != curr.addressError,
          builder: (context, state) {
            return AppTextField(
              controller: addressController,
              label: 'Alamat Lengkap',
              hint: 'Jl. Mawar No. 123, Jakarta',
              onChanged: (value) => context.read<ProfileBloc>()
                  .add(AddressChanged(value)),
              error: state.addressError,
            );
          },
        ),

        BlocBuilder<ProfileBloc, ProfileState>(
          buildWhen: (p, c) => p.childNameError != c.childNameError,
          builder: (context, state) {
            return AppTextField(
              controller: childNameController,
              label: 'Nama Anak',
              hint: 'Contoh: Rafatar',
              error: state.childNameError,
              onChanged: (v) =>
                  context.read<ProfileBloc>().add(ChildNameChanged(v)),
            );
          },
        ),

        BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {
            return AppDateField(
              label: 'Tanggal Lahir Anak',
              value: state.childBirthDate,
              hint: '22/11/2022',
              error: state.childBirthDateError,
              onChanged: (d) =>
                  context.read<ProfileBloc>().add(ChildBirthDateChanged(d)),
            );
          },
        ),

        BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {
            return AppDropdownField(
              label: 'Jenis Kelamin',
              value: state.childGender,
              hint: 'Pilih Jenis Kelamin',
              error: state.childGenderError,
              items: const [
                DropdownMenuItem(value: 'Laki-Laki', child: Text('Laki-Laki')),
                DropdownMenuItem(value: 'Perempuan', child: Text('Perempuan')),
              ],
              onChanged: (v) =>
                  context.read<ProfileBloc>().add(ChildGenderChanged(v)),
            );
          },
        ),

        const SizedBox(height: 24),
        BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {
            return AppButton(
              text: 'Simpan',
              loading: state.isSubmitting,
              enabled: true,
              onPressed: widget.onSubmit,
            );
          },
        ),
      ],
    );
  }
}
