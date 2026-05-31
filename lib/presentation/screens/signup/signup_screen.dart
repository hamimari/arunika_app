import 'package:arunika_app/constants/app_colors.dart';
import 'package:arunika_app/constants/app_text_styles.dart';
import 'package:arunika_app/presentation/screens/signup/signup_bloc.dart';
import 'package:arunika_app/presentation/screens/signup/signup_event.dart';
import 'package:arunika_app/presentation/screens/signup/signup_state.dart';
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
          // Use the local Navigator (inside SignupNavigator) so SignupBloc
          // remains in scope — do NOT use go_router context.push here.
          Navigator.of(context).pushNamed('/child-signup');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.pageBackground,
        body: Stack(
          children: [
            // Decorative gradient top
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 200,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFFEDD5), AppColors.pageBackground],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Positioned(
              top: -20,
              left: -40,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.premiumPurple.withValues(alpha: 0.06),
                ),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  // Back button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 0, 0),
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: AppColors.textDark,
                        ),
                        onPressed: () => context.go('/landing'),
                      ),
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Progress bar
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 8,
                            ),
                            child: const AppProgress(value: 0.5),
                          ),
                          const SizedBox(height: 20),

                          // Header
                          Center(
                            child: Column(
                              children: [
                                // Container(
                                //   width: 60,
                                //   height: 60,
                                //   decoration: BoxDecoration(
                                //     color: AppColors.primaryOrange.withValues(
                                //       alpha: 0.1,
                                //     ),
                                //     borderRadius: BorderRadius.circular(20),
                                //   ),
                                //   child: const Center(
                                //     child: Text(
                                //       '👨‍👩‍👧',
                                //       style: TextStyle(fontSize: 26),
                                //     ),
                                //   ),
                                // ),
                                const SizedBox(height: 16),
                                Text(
                                  'Daftar Akun Orang Tua',
                                  style: AppTextStyles.heading.copyWith(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Lengkapi data untuk memulai perjalanan\nbelajar si kecil bersama Arunika',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.body.copyWith(
                                    color: AppColors.textMedium,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 28),

                          // Form Card
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryOrange.withValues(
                                    alpha: 0.08,
                                  ),
                                  blurRadius: 24,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                BlocBuilder<SignupBloc, SignupState>(
                                  buildWhen: (p, c) =>
                                      p.nameError != c.nameError,
                                  builder: (context, state) {
                                    return AppTextField(
                                      label: 'Nama Orang Tua',
                                      hint: 'Contoh: Nagita Slavina',
                                      onChanged: (value) => context
                                          .read<SignupBloc>()
                                          .add(NameChanged(value)),
                                      error: state.nameError,
                                    );
                                  },
                                ),

                                const SizedBox(height: 12),

                                BlocBuilder<SignupBloc, SignupState>(
                                  buildWhen: (p, c) =>
                                      p.phoneError != c.phoneError,
                                  builder: (context, state) {
                                    return AppPhoneTextField(
                                      label: 'Nomor Telepon',
                                      hint: '812356789',
                                      onChanged: (value) => context
                                          .read<SignupBloc>()
                                          .add(PhoneChanged(value)),
                                      error: state.phoneError,
                                    );
                                  },
                                ),

                                const SizedBox(height: 12),

                                BlocBuilder<SignupBloc, SignupState>(
                                  buildWhen: (p, c) =>
                                      p.emailError != c.emailError,
                                  builder: (context, state) {
                                    return AppTextField(
                                      label: 'Email',
                                      hint: 'nagita.slavina@mail.com',
                                      onChanged: (value) => context
                                          .read<SignupBloc>()
                                          .add(EmailChanged(value)),
                                      error: state.emailError,
                                    );
                                  },
                                ),

                                const SizedBox(height: 12),

                                BlocBuilder<SignupBloc, SignupState>(
                                  buildWhen: (p, c) =>
                                      p.cityError != c.cityError,
                                  builder: (context, state) {
                                    return AppTextField(
                                      label: 'Kota Tinggal',
                                      hint: 'Jakarta',
                                      onChanged: (value) => context
                                          .read<SignupBloc>()
                                          .add(CityChanged(value)),
                                      error: state.cityError,
                                    );
                                  },
                                ),

                                const SizedBox(height: 12),

                                BlocBuilder<SignupBloc, SignupState>(
                                  buildWhen: (p, c) =>
                                      p.addressError != c.addressError,
                                  builder: (context, state) {
                                    return AppTextField(
                                      label: 'Alamat Lengkap',
                                      hint: 'Jl. Mawar No. 123, Jakarta',
                                      onChanged: (value) => context
                                          .read<SignupBloc>()
                                          .add(AddressChanged(value)),
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
                                      onChanged: (value) => context
                                          .read<SignupBloc>()
                                          .add(PasswordChanged(value)),
                                      error: state.passwordError,
                                      obscure: state.obscurePassword,
                                      suffix: IconButton(
                                        icon: Icon(
                                          state.obscurePassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          color: AppColors.primaryOrange,
                                        ),
                                        onPressed: () {
                                          context.read<SignupBloc>().add(
                                            ObscurePasswordToggled(
                                              !state.obscurePassword,
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  },
                                ),

                                const SizedBox(height: 24),

                                // Next Button
                                GestureDetector(
                                  onTap: () => context.read<SignupBloc>().add(
                                    NextButtonPressed(),
                                  ),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryOrange,
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primaryOrange
                                              .withValues(alpha: 0.35),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Selanjutnya',
                                        style: AppTextStyles.button,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Bottom link
                          Center(
                            child: Text.rich(
                              TextSpan(
                                text: 'Sudah punya akun? ',
                                style: AppTextStyles.body.copyWith(
                                  color: AppColors.textMedium,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Masuk',
                                    style: AppTextStyles.body.copyWith(
                                      color: AppColors.primaryOrange,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () => context.push('/signin'),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
