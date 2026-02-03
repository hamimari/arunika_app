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
          context.push('/signup/child');
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFBF5),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: const BackButton(color: Colors.black),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Progress
                const AppProgress(value: 0.5),
                const SizedBox(height: 28),

                // Header
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 48,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.orange.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Daftar Akun Orang Tua',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          'Lengkapi data untuk memulai perjalanan belajar si kecil bersama Arunika',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14.5,
                            height: 1.5,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Form Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.08),
                        blurRadius: 25,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [

                      BlocBuilder<SignupBloc, SignupState>(
                        buildWhen: (p, c) => p.nameError != c.nameError,
                        builder: (context, state) {
                          return AppTextField(
                            label: 'Nama Orang Tua',
                            hint: 'Contoh: Nagita Slavina',
                            onChanged: (value) =>
                                context.read<SignupBloc>().add(NameChanged(value)),
                            error: state.nameError,
                          );
                        },
                      ),

                      const SizedBox(height: 12),

                      BlocBuilder<SignupBloc, SignupState>(
                        buildWhen: (p, c) => p.phoneError != c.phoneError,
                        builder: (context, state) {
                          return AppPhoneTextField(
                            label: 'Nomor Telepon',
                            hint: '812356789',
                            onChanged: (value) =>
                                context.read<SignupBloc>().add(PhoneChanged(value)),
                            error: state.phoneError,
                          );
                        },
                      ),

                      const SizedBox(height: 12),

                      BlocBuilder<SignupBloc, SignupState>(
                        buildWhen: (p, c) => p.emailError != c.emailError,
                        builder: (context, state) {
                          return AppTextField(
                            label: 'Email',
                            hint: 'nagita.slavina@mail.com',
                            onChanged: (value) =>
                                context.read<SignupBloc>().add(EmailChanged(value)),
                            error: state.emailError,
                          );
                        },
                      ),

                      const SizedBox(height: 12),

                      BlocBuilder<SignupBloc, SignupState>(
                        buildWhen: (p, c) => p.cityError != c.cityError,
                        builder: (context, state) {
                          return AppTextField(
                            label: 'Kota Tinggal',
                            hint: 'Jakarta',
                            onChanged: (value) =>
                                context.read<SignupBloc>().add(CityChanged(value)),
                            error: state.cityError,
                          );
                        },
                      ),

                      const SizedBox(height: 12),

                      BlocBuilder<SignupBloc, SignupState>(
                        buildWhen: (p, c) => p.addressError != c.addressError,
                        builder: (context, state) {
                          return AppTextField(
                            label: 'Alamat Lengkap',
                            hint: 'Jl. Mawar No. 123, Jakarta',
                            onChanged: (value) =>
                                context.read<SignupBloc>().add(AddressChanged(value)),
                            error: state.addressError,
                          );
                        },
                      ),

                      const SizedBox(height: 12),

                      BlocBuilder<SignupBloc, SignupState>(
                        buildWhen: (p, c) =>
                        p.passwordError != c.passwordError ||
                            p.obscurePassword != c.obscurePassword,
                        builder: (context, state) {
                          return AppTextField(
                            label: 'Kata Sandi',
                            hint: 'Minimal 8 karakter',
                            onChanged: (value) =>
                                context.read<SignupBloc>().add(PasswordChanged(value)),
                            error: state.passwordError,
                            obscure: state.obscurePassword,
                            suffix: IconButton(
                              icon: Icon(
                                state.obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: Colors.orange,
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

                      const SizedBox(height: 24),

                      // Next Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            context.read<SignupBloc>().add(NextButtonPressed());
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Selanjutnya',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Bottom link
                Center(
                  child: Text.rich(
                    TextSpan(
                      text: 'Sudah punya akun? ',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
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

