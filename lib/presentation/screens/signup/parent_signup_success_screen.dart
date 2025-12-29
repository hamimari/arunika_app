import 'package:arunika_app/presentation/screens/signup/signup_bloc.dart';
import 'package:arunika_app/presentation/screens/signup/signup_event.dart';
import 'package:arunika_app/presentation/screens/signup/signup_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ParentRegistrationSuccessScreen extends StatelessWidget {
  const ParentRegistrationSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<SignupBloc, SignupState>(
      listener: (context, state) {
        if (state is SignupChildPage) {
          context.push('/signup/child-signup');
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFFCCBC), // Soft pink background
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.network(
                    'https://media-hosting.imagekit.io/930f10f515b7467f/ImageGen%20Apr%2010,%202025,%2006_13_18%20AM.png?Expires=1839246141&Key-Pair-Id=K2ZIVPTIP2VGHC&Signature=PxPqhx2MyUwoqgjzM--yQVqP1DTHu8OwjZizMq0owoal8FhnYJe-CIWpp23cUTWVWrLidBAu0fpr9kGG5UmuP9vi4055w4USUmMUw8VHosMtDklZ67rWaG35JgpydHrOfvjCY-58c5Ai0uVdCxiTE8I5K8AiPpvw-qidrQ2nbq648w8k0JJCmZj4hmaINYeU7QbeBgMCUMIpnCY0Kaejnwq7hoL6YMI8LaTGZ4vhADtkON14slLcWeTpWMld6puUcyMSWU3TUvo8DL2nPiwSMk2tH7atXyj~FjgTyDY14TSFqKFyQvF-w4qdikJPpwlJGm07rknS6X82vSd7FuJ7Og__',
                    // Replace with your own asset or image URL
                    width: 600,
                    height: 400,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'Registrasi kamu berhasil!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Ayo buat akun untuk buah hati dan\nmulai belajar bersama arunika',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        context
                            .read<SignupBloc>()
                            .add(ChildRegistrationButtonPressed());
                      },
                      child: const Text(
                        'Lengkapi Data Si Kecil',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
