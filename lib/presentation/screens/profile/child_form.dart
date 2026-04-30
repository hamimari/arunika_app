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
    childNameController = TextEditingController(
      text: state.user?.children.first.name,
    );
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
        // ── Section label: Orang Tua ──────────────────────────────────────
        const _SectionLabel(
          label: 'Data Orang Tua',
          icon: Icons.person_outline_rounded,
        ),
        const SizedBox(height: 12),

        // 1. Nama
        BlocBuilder<ProfileBloc, ProfileState>(
          buildWhen: (prev, curr) => prev.nameError != curr.nameError,
          builder: (context, state) {
            return AppTextField(
              controller: nameController,
              label: 'Nama Orang Tua',
              hint: 'Contoh: Nagita Slavina',
              prefix: const Icon(
                Icons.person_outline_rounded,
                color: Colors.orange,
                size: 20,
              ),
              onChanged: (value) =>
                  context.read<ProfileBloc>().add(NameChanged(value)),
              error: state.nameError,
            );
          },
        ),

        const SizedBox(height: 12),

        // 2. Email
        BlocBuilder<ProfileBloc, ProfileState>(
          buildWhen: (prev, curr) => prev.emailError != curr.emailError,
          builder: (context, state) {
            return AppTextField(
              controller: emailController,
              label: 'Email',
              hint: 'nagita.slavina@mail.com',
              prefix: const Icon(
                Icons.email_outlined,
                color: Colors.orange,
                size: 20,
              ),
              onChanged: (value) =>
                  context.read<ProfileBloc>().add(EmailChanged(value)),
              error: state.emailError,
            );
          },
        ),

        const SizedBox(height: 12),

        // 3. Nomor Telepon
        BlocBuilder<ProfileBloc, ProfileState>(
          buildWhen: (prev, curr) => prev.phoneError != curr.phoneError,
          builder: (context, state) {
            return AppPhoneTextField(
              controller: phoneController,
              label: 'Nomor Telepon',
              hint: '812356789',
              onChanged: (value) =>
                  context.read<ProfileBloc>().add(PhoneChanged(value)),
              error: state.phoneError,
            );
          },
        ),

        const SizedBox(height: 12),

        // 4. Kota Tinggal
        BlocBuilder<ProfileBloc, ProfileState>(
          buildWhen: (prev, curr) => prev.cityError != curr.cityError,
          builder: (context, state) {
            return AppTextField(
              controller: cityController,
              label: 'Kota Tinggal',
              hint: 'Jakarta',
              prefix: const Icon(
                Icons.location_city_outlined,
                color: Colors.orange,
                size: 20,
              ),
              onChanged: (value) =>
                  context.read<ProfileBloc>().add(CityChanged(value)),
              error: state.cityError,
            );
          },
        ),

        const SizedBox(height: 12),

        // 5. Alamat Lengkap
        BlocBuilder<ProfileBloc, ProfileState>(
          buildWhen: (prev, curr) => prev.addressError != curr.addressError,
          builder: (context, state) {
            return AppTextField(
              controller: addressController,
              label: 'Alamat Lengkap',
              hint: 'Jl. Mawar No. 123, Jakarta',
              prefix: const Icon(
                Icons.home_outlined,
                color: Colors.orange,
                size: 20,
              ),
              onChanged: (value) =>
                  context.read<ProfileBloc>().add(AddressChanged(value)),
              error: state.addressError,
            );
          },
        ),

        const SizedBox(height: 24),

        // ── Section label: Anak ───────────────────────────────────────────
        const _SectionLabel(label: 'Data Anak', icon: Icons.child_care_rounded),
        const SizedBox(height: 12),

        // 6. Nama Anak
        BlocBuilder<ProfileBloc, ProfileState>(
          buildWhen: (p, c) => p.childNameError != c.childNameError,
          builder: (context, state) {
            return AppTextField(
              controller: childNameController,
              label: 'Nama Anak',
              hint: 'Contoh: Rafatar',
              prefix: const Icon(
                Icons.face_rounded,
                color: Colors.orange,
                size: 20,
              ),
              error: state.childNameError,
              onChanged: (v) =>
                  context.read<ProfileBloc>().add(ChildNameChanged(v)),
            );
          },
        ),

        const SizedBox(height: 12),

        // 7. Tanggal Lahir
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

        const SizedBox(height: 12),

        // 8. Jenis Kelamin
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

        const SizedBox(height: 28),

        BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {
            return AppButton(
              text: 'Simpan Perubahan',
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

class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;

  const _SectionLabel({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.orange),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.orange.shade700,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}
