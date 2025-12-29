import 'package:arunika_app/di/locator.dart';
import 'package:arunika_app/presentation/navigation/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';


void main() {
  FlutterNativeSplash.remove();
  setupLocator();
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