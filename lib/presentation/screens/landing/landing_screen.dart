import 'package:arunika_app/presentation/screens/landing/landing_bloc.dart';
import 'package:arunika_app/presentation/screens/landing/landing_event.dart';
import 'package:arunika_app/presentation/screens/landing/landing_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<LandingBloc, LandingState>(
      listener: (context, state) {
        if (state is NavigateToSignUpPage) {
          context.go('/signup');
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFBF5), // soft cream
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                children: [

                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withValues(alpha: 0.15),
                                blurRadius: 30,
                                offset: const Offset(0, 15),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: Image.network(
                              'https://raw.githubusercontent.com/hamimari/arunika_assets/main/landing_icon_transparent.png',
                              width: double.infinity,
                              height: 280,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  const Text(
                    'Halo! Selamat datang di Arunika 👋',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'Aplikasi belajar berbasis bermain untuk anak usia 1–10 tahun.\n'
                        'Dilengkapi karakter favorit, AR flashcard, dan dongeng interaktif.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.5,
                      height: 1.6,
                      color: Colors.black54,
                    ),
                  ),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        elevation: 6,
                        shadowColor: Colors.orange.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        context.read<LandingBloc>().add(SignupButtonPressed());
                      },
                      child: const Text(
                        'Daftar Sekarang',
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: Divider(color: Colors.grey.shade300),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'atau',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                      Expanded(
                        child: Divider(color: Colors.grey.shade300),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.orange, width: 1.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        context.push('/signin');
                      },
                      child: const Text(
                        'Sudah punya akun? Masuk',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  Text(
                    'Belajar • Bermain • Bertumbuh bersama Arunika',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
