import 'package:arunika_app/data/api/auth_api.dart';
import 'package:arunika_app/data/api/user_api.dart';
import 'package:arunika_app/data/repositories/auth_repository.dart';
import 'package:arunika_app/data/repositories/user_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';


final locator = GetIt.instance;

void setupLocator() {
  locator.registerLazySingleton(() => Dio());

  locator.registerLazySingleton(
        () => AuthRepository(AuthApi()));

  locator.registerLazySingleton(
          () => UserRepository(UserApi()));
}
