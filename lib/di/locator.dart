import 'package:arunika_app/data/api/ar_api.dart';
import 'package:arunika_app/data/api/auth_api.dart';
import 'package:arunika_app/data/api/badge_api.dart';
import 'package:arunika_app/data/api/counting_api.dart';
import 'package:arunika_app/data/api/fairy_tales_api.dart';
import 'package:arunika_app/data/api/growth_api.dart';
import 'package:arunika_app/data/api/notification_api.dart';
import 'package:arunika_app/data/api/payment_api.dart';
import 'package:arunika_app/data/api/tracing_api.dart';
import 'package:arunika_app/data/api/user_api.dart';
import 'package:arunika_app/data/repositories/ar_repository.dart';
import 'package:arunika_app/data/repositories/auth_repository.dart';
import 'package:arunika_app/data/repositories/badge_repository.dart';
import 'package:arunika_app/data/repositories/counting_repository.dart';
import 'package:arunika_app/data/repositories/fairy_tales_repository.dart';
import 'package:arunika_app/data/repositories/growth_repository.dart';
import 'package:arunika_app/data/repositories/notification_repository.dart';
import 'package:arunika_app/data/repositories/payment_repository.dart';
import 'package:arunika_app/data/repositories/tracing_repository.dart';
import 'package:arunika_app/data/repositories/user_repository.dart';
import 'package:arunika_app/core/auth/auth_notifier.dart';
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';

final locator = GetIt.instance;

void setupLocator() {
  locator.registerLazySingleton(() => Dio());

  locator.registerLazySingleton(() => AuthRepository(AuthApi()));

  locator.registerLazySingleton(() => UserRepository(UserApi()));

  locator.registerLazySingleton(() => FairyTalesRepository(FairyTalesApi()));

  locator.registerLazySingleton(() => AuthNotifier());
  locator.registerLazySingleton(() => ArRepository(ArApi()));

  // Education module
  locator.registerLazySingleton(() => TracingRepository(TracingApi()));
  locator.registerLazySingleton(() => CountingRepository(CountingApi()));
  locator.registerLazySingleton(() => BadgeRepository(BadgeApi()));
  locator.registerLazySingleton(() => PaymentRepository(PaymentApi()));
  locator.registerLazySingleton(
    () => NotificationRepository(NotificationApi()),
  );
  locator.registerLazySingleton(() => GrowthRepository(GrowthApi()));
}
