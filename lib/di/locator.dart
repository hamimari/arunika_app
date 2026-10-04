import 'package:arunika_app/data/api/ar_api.dart';
import 'package:arunika_app/data/api/auth_api.dart';
import 'package:arunika_app/data/api/banner_api.dart';
import 'package:arunika_app/data/api/category_api.dart';
import 'package:arunika_app/data/api/dongeng_history_api.dart';
import 'package:arunika_app/data/api/fairy_tales_api.dart';
import 'package:arunika_app/data/api/feature_flag_api.dart';
import 'package:arunika_app/data/api/notification_api.dart';
import 'package:arunika_app/data/api/order_api.dart';
import 'package:arunika_app/data/api/play_billing_api.dart';
import 'package:arunika_app/data/api/premium_pack_api.dart';
import 'package:arunika_app/data/api/user_api.dart';
import 'package:arunika_app/data/repositories/ar_repository.dart';
import 'package:arunika_app/data/repositories/auth_repository.dart';
import 'package:arunika_app/data/repositories/banner_repository.dart';
import 'package:arunika_app/data/repositories/category_repository.dart';
import 'package:arunika_app/data/repositories/dongeng_history_repository.dart';
import 'package:arunika_app/data/repositories/fairy_tales_repository.dart';
import 'package:arunika_app/data/repositories/order_repository.dart';
import 'package:arunika_app/data/repositories/premium_pack_repository.dart';
import 'package:arunika_app/data/repositories/profile_loader.dart';
import 'package:arunika_app/data/repositories/user_repository.dart';
import 'package:arunika_app/core/auth/auth_notifier.dart';
import 'package:arunika_app/core/feature_flags/feature_flags_notifier.dart';
import 'package:arunika_app/services/billing_service.dart';
import 'package:arunika_app/services/google_play_billing_service.dart';
import 'package:arunika_app/services/push_notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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
  locator.registerLazySingleton(() => BannerRepository(BannerApi()));
  locator.registerLazySingleton(() => CategoryRepository(CategoryApi()));
  locator.registerLazySingleton(
    () => DongengHistoryRepository(DongengHistoryApi()),
  );
  locator.registerLazySingleton(() => PremiumPackRepository(PremiumPackApi()));
  locator.registerLazySingleton(() => OrderRepository(OrderApi()));
  locator.registerLazySingleton(
    () => ProfileLoader(locator<UserRepository>(), locator<AuthNotifier>()),
  );
  locator.registerLazySingleton(() => PlayBillingApi());
  locator.registerLazySingleton<BillingService>(
    () => GooglePlayBillingService(
      locator<PlayBillingApi>(),
      alternativeBillingAllowed: () =>
          locator<FeatureFlagsNotifier>().alternativeBillingEnabled,
    ),
  );
  locator.registerLazySingleton(() => FeatureFlagsNotifier(FeatureFlagApi()));
  locator.registerLazySingleton(
    () => PushNotificationService(
      FirebaseMessaging.instance,
      NotificationApi(),
      locator<AuthNotifier>(),
    ),
  );
}
