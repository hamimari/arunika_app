import 'package:arunika_app/presentation/screens/forgotpassword/forgot_password_bloc.dart';
import 'package:arunika_app/presentation/screens/forgotpassword/forgot_password_event.dart';
import 'package:arunika_app/presentation/screens/forgotpassword/forgot_password_state.dart';
import 'package:arunika_app/presentation/screens/widgets/error_dialog.dart';
import 'package:arunika_app/presentation/screens/widgets/text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final emailController = TextEditingController();

    return BlocListener<ForgotPasswordBloc, ForgotPasswordState>(
      listener: (context, state) {
        if (state.isSubmitted) {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            builder: (_) => AppErrorSheet(
              title: "Cek Email",
              message:
                  "Link reset kata sandi telah dikirim ke email ${state.email}.",
              onConfirm: () {
                Navigator.of(context).pop();
              },
            ),
          );
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),

                const Text(
                  'Lupa Kata Sandi',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
                ),

                const SizedBox(height: 12),

                Text(
                  'Masukkan email Anda. Kami akan mengirimkan link untuk reset kata sandi.',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 32),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      AppTextField(
                        label: 'Email',
                        hint: 'email@example.com',
                        onChanged: (v) => emailController.text = v,
                      ),

                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            context.read<ForgotPasswordBloc>().add(
                              ForgotPasswordSubmitted(emailController.text),
                            );
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
                            'Kirim Link Reset',
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
