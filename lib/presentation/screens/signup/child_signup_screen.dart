import 'package:arunika_app/presentation/screens/signup/signup_bloc.dart';
import 'package:arunika_app/presentation/screens/signup/signup_event.dart';
import 'package:arunika_app/presentation/screens/signup/signup_state.dart';
import 'package:arunika_app/presentation/screens/widgets/app_button.dart';
import 'package:arunika_app/presentation/screens/widgets/date_field.dart';
import 'package:arunika_app/presentation/screens/widgets/dropdown_field.dart';
import 'package:arunika_app/presentation/screens/widgets/error_dialog.dart';
import 'package:arunika_app/presentation/screens/widgets/progress_bar.dart';
import 'package:arunika_app/presentation/screens/widgets/text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ChildSignupScreen extends StatelessWidget {
  final bool isEdit;
  final VoidCallback? onSuccess;

  const ChildSignupScreen({
    super.key,
    this.isEdit = false,
    this.onSuccess,
  });

  @override
  Widget build(BuildContext context) {
    return BlocListener<SignupBloc, SignupState>(
      listener: (context, state) {
        if (isEdit) {
          Navigator.pop(context);
          onSuccess?.call();
        } else {
          context.go('/home');
        }

        if (state.error != null) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => AppErrorSheet(
              title: isEdit ? 'Gagal Update' : 'Oops!',
              message: state.error!,
              onConfirm: () {},
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: const BackButton(color: Colors.black),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppProgress(value: 1.0),
              const SizedBox(height: 32),

              BlocBuilder<SignupBloc, SignupState>(
                buildWhen: (prev, curr) => prev.childNameError != curr.childNameError,
                builder: (context, state) {
                  return AppTextField(
                    label: 'Nama Anak',
                    hint: 'Contoh: Rafatar',
                    onChanged: (value) =>
                        context.read<SignupBloc>().add(ChildNameChanged(value)),
                    error: state.childNameError,
                  );
                },
              ),

              BlocBuilder<SignupBloc, SignupState>(
                buildWhen: (p, c) =>
                p.childBirthDate != c.childBirthDate ||
                    p.childBirthDateError != c.childBirthDateError,
                builder: (context, state) {
                  return AppDateField(
                    label: 'Tanggal Lahir Anak',
                    value: state.childBirthDate,
                    hint: '22/11/2022',
                    error: state.childBirthDateError,
                    onChanged: (date) {
                      context.read<SignupBloc>().add(ChildBirthDateChanged(date));
                    },
                  );
                },
              ),

              BlocBuilder<SignupBloc, SignupState>(
                buildWhen: (p, c) => p.childGenderError != c.childGenderError,
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
                    onChanged: (val) {
                      context.read<SignupBloc>().add(ChildGenderChanged(val));
                    },
                  );
                },
              ),

              // Checkbox
              BlocBuilder<SignupBloc, SignupState>(
                buildWhen: (prev, curr) => prev.tncAccepted != curr.tncAccepted,
                builder: (context, state) {
                  return Row(
                    children: [
                      Checkbox(
                        value: state.tncAccepted,
                        onChanged: (value) {
                          context.read<SignupBloc>().add(
                            TncToggled(value ?? false),
                          );
                        },
                      ),
                      const Expanded(
                        child: Text.rich(
                          TextSpan(
                            text: 'Dengan mendaftar, Kamu menyetujui ',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                            children: [
                              TextSpan(
                                text: 'Syarat & Ketentuan',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(text: ' dan '),
                              TextSpan(
                                text: 'Kebijakan Privasi',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(text: ' kami'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              BlocBuilder<SignupBloc, SignupState>(
                builder: (context, state) {
                  return AppButton(
                    text: 'Simpan',
                    enabled: state.tncAccepted,
                    loading: state.isSubmitting,
                    onPressed: () {
                      context.read<SignupBloc>().add(SignupSubmitted());
                    },
                  );
                },
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
