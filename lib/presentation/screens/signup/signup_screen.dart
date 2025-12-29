import 'package:arunika_app/presentation/screens/signup/signup_bloc.dart';
import 'package:arunika_app/presentation/screens/signup/signup_event.dart';
import 'package:arunika_app/presentation/screens/signup/signup_state.dart';
import 'package:arunika_app/presentation/screens/widgets/app_button.dart';
import 'package:arunika_app/presentation/screens/widgets/phone_text_field.dart';
import 'package:arunika_app/presentation/screens/widgets/progress_bar.dart';
import 'package:arunika_app/presentation/screens/widgets/text_field.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<SignupBloc, SignupState>(
      listener: (context, state) {
        if (state.navigateToChild) {
          context.read<SignupBloc>().add(
            NavigateToChildReset(!state.navigateToChild),
          );
          Navigator.of(context).pushNamed('/child-signup');
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(backgroundColor: Colors.transparent),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppProgress(value: 0.5),
                const SizedBox(height: 32),

                BlocBuilder<SignupBloc, SignupState>(
                  buildWhen: (prev, curr) => prev.nameError != curr.nameError,
                  builder: (context, state) {
                    return AppTextField(
                      label: 'Nama Kamu (Orang Tua)',
                      hint: 'Contoh : Nagita Slavina',
                      onChanged: (value) =>
                          context.read<SignupBloc>().add(NameChanged(value)),
                      error: state.nameError,
                    );
                  },
                ),

                BlocBuilder<SignupBloc, SignupState>(
                  buildWhen: (prev, curr) => prev.phoneError != curr.phoneError,
                  builder: (context, state) {
                    return AppPhoneTextField(
                      label: 'Nomor Telepon',
                      hint: '812356789',
                      onChanged: (value) => context.read<SignupBloc>()
                          .add(PhoneChanged(value)),
                      error: state.phoneError,
                    );
                  },
                ),

                BlocBuilder<SignupBloc, SignupState>(
                  buildWhen: (prev, curr) => prev.emailError != curr.emailError,
                  builder: (context, state) {
                    return AppTextField(
                      label: 'Email',
                      hint: 'nagita.slavina@mail.com',
                      onChanged: (value) => context.read<SignupBloc>()
                          .add(EmailChanged(value)),
                      error: state.emailError,
                    );
                  },
                ),

                BlocBuilder<SignupBloc, SignupState>(
                  buildWhen: (prev, curr) => prev.cityError != curr.cityError,
                  builder: (context, state) {
                    return AppTextField(
                      label: 'Kota Tinggal',
                      hint: 'Jakarta',
                      onChanged: (value) => context.read<SignupBloc>()
                          .add(CityChanged(value)),
                      error: state.cityError,
                    );
                  },
                ),

                BlocBuilder<SignupBloc, SignupState>(
                  buildWhen: (prev, curr) => prev.addressError != curr.addressError,
                  builder: (context, state) {
                    return AppTextField(
                      label: 'Alamat Lengkap',
                      hint: 'Jl. Mawar No. 123, Jakarta',
                      onChanged: (value) => context.read<SignupBloc>()
                          .add(AddressChanged(value)),
                      error: state.addressError,
                    );
                  },
                ),

                BlocBuilder<SignupBloc, SignupState>(
                  buildWhen: (prev, curr) =>
                  prev.passwordError != curr.passwordError ||
                      prev.obscurePassword != curr.obscurePassword,
                  builder: (context, state) {
                    return AppTextField(
                      label: 'Kata Sandi',
                      hint: 'Masukkan kata sandi',
                      onChanged: (value) => context.read<SignupBloc>().add(
                        PasswordChanged(value),
                      ),
                      error: state.passwordError,
                      obscure: state.obscurePassword,
                      suffix: IconButton(
                        icon: Icon(
                          state.obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          context.read<SignupBloc>().add(
                            ObscurePasswordToggled(!state.obscurePassword),
                          );
                        },
                      ),
                    );
                  },
                ),

                // Button
                AppButton(
                  text: 'Selanjutnya',
                  onPressed: () {
                    context.read<SignupBloc>().add(NextButtonPressed());
                  },
                ),
                const SizedBox(height: 24),

                // Bottom link
                Center(
                  child: Text.rich(
                    TextSpan(
                      text: 'Sudah punya akun? ',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                      children: [
                        TextSpan(
                          text: 'Masuk',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              context.push('/signin');
                            },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
