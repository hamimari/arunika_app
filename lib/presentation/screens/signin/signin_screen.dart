import 'package:arunika_app/constants/app_colors.dart';
import 'package:arunika_app/constants/app_text_styles.dart';
import 'package:arunika_app/presentation/screens/signin/signin_bloc.dart';
import 'package:arunika_app/presentation/screens/signin/signin_event.dart';
import 'package:arunika_app/presentation/screens/signin/signin_state.dart';
import 'package:arunika_app/presentation/screens/widgets/error_dialog.dart';
import 'package:arunika_app/presentation/screens/widgets/text_field.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<SigninBloc, SigninState>(
      listener: (context, state) {
        if (state.isSuccess) {
          context.go('/shell');
        }

        if (state.error != null) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) {
              return AppErrorSheet(
                message: state.error!,
                onConfirm: () {},
                title: 'Oops!',
              );
            },
          );
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
              height: 240,
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
            // Decorative bubble
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryOrange.withValues(alpha: 0.08),
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
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),

                          // Heading
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
                                //       '👋',
                                //       style: TextStyle(fontSize: 28),
                                //     ),
                                //   ),
                                // ),
                                const SizedBox(height: 16),
                                Text(
                                  'Selamat Datang',
                                  style: AppTextStyles.heading.copyWith(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Masuk untuk melanjutkan perjalanan\nbelajar si kecil',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.body.copyWith(
                                    color: AppColors.textMedium,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Form card
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
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                BlocBuilder<SigninBloc, SigninState>(
                                  buildWhen: (prev, curr) =>
                                      prev.emailError != curr.emailError,
                                  builder: (context, state) {
                                    return AppTextField(
                                      label: 'Email',
                                      hint: 'nagita.slavina@mail.com',
                                      onChanged: (value) => context
                                          .read<SigninBloc>()
                                          .add(EmailChanged(value)),
                                      error: state.emailError,
                                    );
                                  },
                                ),

                                const SizedBox(height: 12),

                                BlocBuilder<SigninBloc, SigninState>(
                                  buildWhen: (prev, curr) =>
                                      prev.passwordError !=
                                          curr.passwordError ||
                                      prev.obscurePassword !=
                                          curr.obscurePassword,
                                  builder: (context, state) {
                                    return AppTextField(
                                      label: 'Kata Sandi',
                                      hint: 'Masukkan kata sandi',
                                      onChanged: (value) => context
                                          .read<SigninBloc>()
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
                                          context.read<SigninBloc>().add(
                                            ObscurePasswordToggled(
                                              !state.obscurePassword,
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  },
                                ),

                                const SizedBox(height: 8),

                                Align(
                                  alignment: Alignment.centerRight,
                                  child: GestureDetector(
                                    onTap: () =>
                                        context.push('/forgot-password'),
                                    child: Text(
                                      'Lupa kata sandi?',
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.primaryOrange,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Sign in button
                                GestureDetector(
                                  onTap: () => context.read<SigninBloc>().add(
                                    SigninSubmitted(),
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
                                        'Masuk',
                                        style: AppTextStyles.button,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          Center(
                            child: Text.rich(
                              TextSpan(
                                text: 'Belum punya akun? ',
                                style: AppTextStyles.body.copyWith(
                                  color: AppColors.textMedium,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Daftar di sini',
                                    style: AppTextStyles.body.copyWith(
                                      color: AppColors.primaryOrange,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () => context.go('/signup'),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
