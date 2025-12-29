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
          context.go('/home');
        }

        if (state.error != null) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) {
              return AppErrorSheet(
                message: state.error!,
                onConfirm: () {  },
                title: "Oops!",
              );
            },
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: BackButton(color: Colors.black),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.network(
                  'https://raw.githubusercontent.com/hamimari/arunika_assets/main/login_icon_transparent.png',
                  width: 600,
                  height: 400,
                ),

                BlocBuilder<SigninBloc, SigninState>(
                  buildWhen: (prev, curr) => prev.emailError != curr.emailError,
                  builder: (context, state) {
                    return AppTextField(
                      label: 'Email',
                      hint: 'nagita.slavina@mail.com',
                      onChanged: (value) =>
                          context.read<SigninBloc>().add(EmailChanged(value)),
                      error: state.emailError,
                    );
                  },
                ),

                BlocBuilder<SigninBloc, SigninState>(
                  buildWhen: (prev, curr) =>
                      prev.passwordError != curr.passwordError ||
                      prev.obscurePassword != curr.obscurePassword,
                  builder: (context, state) {
                    return AppTextField(
                      label: 'Kata Sandi',
                      hint: 'Masukkan kata sandi',
                      onChanged: (value) => context.read<SigninBloc>().add(
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
                          context.read<SigninBloc>().add(
                            ObscurePasswordToggled(!state.obscurePassword),
                          );
                        },
                      ),
                    );
                  },
                ),

                // Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      context.read<SigninBloc>().add(SigninSubmitted());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Masuk',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Bottom link
                Center(
                  child: Text.rich(
                    TextSpan(
                      text: 'Belum punya akun? ',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                      children: [
                        TextSpan(
                          text: 'Daftar',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              context.push('/signup');
                            },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
