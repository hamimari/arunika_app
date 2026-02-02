import 'package:arunika_app/presentation/screens/signup/child_signup_screen.dart';
import 'package:arunika_app/presentation/screens/signup/signup_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SignupNavigator extends StatelessWidget {
  const SignupNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(
              builder: (_) => const SignupScreen(),
            );
          case '/child-signup':
            return MaterialPageRoute(
              builder: (_) => ChildSignupScreen(),
            );
          default:
            return null;
        }
      },
    );
  }
}
