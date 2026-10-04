import 'package:arunika_app/data/repositories/auth_repository.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:arunika_app/presentation/screens/signup/child_signup_screen.dart';
import 'package:arunika_app/presentation/screens/signup/signup_bloc.dart';
import 'package:arunika_app/presentation/screens/signup/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SignupNavigator extends StatelessWidget {
  const SignupNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SignupBloc(repository: locator<AuthRepository>()),
      child: Navigator(
        initialRoute: '/',
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/':
              return MaterialPageRoute(builder: (_) => const SignupScreen());
            case '/child-signup':
              return MaterialPageRoute(
                builder: (_) => const ChildSignupScreen(),
              );
            default:
              return null;
          }
        },
      ),
    );
  }
}
