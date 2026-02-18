import 'package:arunika_app/core/auth/auth_notifier.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:arunika_app/presentation/navigation/app_router.dart';
import 'package:flutter/material.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  setupLocator();

  await locator<AuthNotifier>().checkAuth();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Arunika App',
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      routerConfig: AppRouter.router,
    );
  }
}