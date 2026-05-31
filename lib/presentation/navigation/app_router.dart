import 'package:arunika_app/core/auth/auth_notifier.dart';
import 'package:arunika_app/core/storage/SecureStorageToken.dart';
import 'package:arunika_app/data/models/response/dongeng_response.dart';
import 'package:arunika_app/data/repositories/auth_repository.dart';
import 'package:arunika_app/data/repositories/fairy_tales_repository.dart';
import 'package:arunika_app/data/repositories/user_repository.dart';
import 'package:arunika_app/data/static/premium_packs.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:arunika_app/presentation/navigation/main_shell.dart';
import 'package:arunika_app/presentation/navigation/signup_navigator.dart';
import 'package:arunika_app/presentation/screens/animal_detail/animal_detail_screen.dart';
import 'package:arunika_app/presentation/screens/arscanner/ar_scan_shell.dart';
import 'package:arunika_app/presentation/screens/dongeng/detail/dongeng_detail_bloc.dart';
import 'package:arunika_app/presentation/screens/dongeng/detail/dongeng_detail_screen.dart';
import 'package:arunika_app/presentation/screens/dongeng/dongeng_list_bloc.dart';
import 'package:arunika_app/presentation/screens/dongeng/dongeng_list_event.dart';
import 'package:arunika_app/presentation/screens/dongeng/new_dongeng_list_screen.dart';
import 'package:arunika_app/presentation/screens/forgotpassword/forgot_password_bloc.dart';
import 'package:arunika_app/presentation/screens/forgotpassword/forgot_password_screen.dart';
import 'package:arunika_app/presentation/screens/home/new_home_screen.dart';
import 'package:arunika_app/presentation/screens/landing/new_landing_screen.dart';
import 'package:arunika_app/presentation/screens/otp/otp_bloc.dart';
import 'package:arunika_app/presentation/screens/otp/otp_screen.dart';
import 'package:arunika_app/presentation/screens/payment/payment_screen.dart';
import 'package:arunika_app/presentation/screens/premium/premium_upgrade_screen.dart';
import 'package:arunika_app/presentation/screens/profile/profile_bloc.dart';
import 'package:arunika_app/presentation/screens/profile/profile_event.dart';
import 'package:arunika_app/presentation/screens/profile/profile_screen.dart';
import 'package:arunika_app/presentation/screens/reward/reward_screen.dart';
import 'package:arunika_app/presentation/screens/signin/signin_bloc.dart';
import 'package:arunika_app/presentation/screens/signin/signin_screen.dart';
import 'package:arunika_app/presentation/screens/signup/terms_and_condition_screen.dart';
import 'package:arunika_app/presentation/screens/signup/trial_screen.dart';
import 'package:arunika_app/presentation/screens/signup/signup_bloc.dart';
import 'package:arunika_app/presentation/screens/signup/parent_signup_success_screen.dart';
import 'package:arunika_app/presentation/screens/signup/privacy_policy_screen.dart';
import 'package:arunika_app/presentation/screens/unlock_success/unlock_success_screen.dart';
import 'package:arunika_app/presentation/screens/vocab/collection_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

final authNotifier = locator<AuthNotifier>();

class AppRouter {
  static final GoRouter router = GoRouter(
    refreshListenable: authNotifier,
    initialLocation: '/',
    routes: [
      // ── Root redirect ──────────────────────────────────────────────────────
      GoRoute(
        path: '/',
        redirect: (context, state) async {
          final token = await SecureTokenStorage.getToken();
          final isLoggedIn = token != null && token.isNotEmpty;
          if (!isLoggedIn) return '/landing';
          return '/shell';
        },
      ),

      // ── Landing ────────────────────────────────────────────────────────────
      GoRoute(path: '/landing', builder: (_, __) => const NewLandingScreen()),

      // ── Main Shell (5 tabs) ────────────────────────────────────────────────
      GoRoute(
        path: '/shell',
        builder: (context, state) {
          return MainShell(
            key: MainShell.shellKey,
            homeScreen: const NewHomeScreen(),
            scanScreen: const ArScanShell(),
            collectionScreen: const CollectionScreen(),
            dongengScreen: BlocProvider(
              create: (_) =>
                  DongengListBloc(repository: locator<FairyTalesRepository>())
                    ..add(LoadDongengList()),
              child: const NewDongengListScreen(),
            ),
            parentScreen: BlocProvider(
              create: (_) =>
                  ProfileBloc(repository: locator<UserRepository>())
                    ..add(ProfileInitial()),
              child: const ProfileScreen(),
            ),
          );
        },
      ),

      // ── Auth flow ──────────────────────────────────────────────────────────
      // SignupNavigator is self-contained: it owns a BlocProvider<SignupBloc>
      // and an inner Navigator for the multi-step signup flow. This avoids the
      // ShellRoute nested-navigator context mismatch that caused
      // "Provider<SignupBloc> not found" when pushing from dialogs.
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupNavigator(),
      ),

      GoRoute(
        path: '/signin',
        builder: (context, state) => BlocProvider(
          create: (_) => SigninBloc(
            repository: locator<AuthRepository>(),
            userRepository: locator<UserRepository>(),
          ),
          child: const SignInScreen(),
        ),
      ),
      GoRoute(
        path: '/otp',
        builder: (context, state) =>
            BlocProvider(create: (_) => OtpBloc(), child: const OtpScreen()),
      ),
      GoRoute(
        path: '/parent-signup-success',
        builder: (context, state) => BlocProvider(
          create: (_) => SignupBloc(repository: locator<AuthRepository>()),
          child: const ParentRegistrationSuccessScreen(),
        ),
      ),
      GoRoute(
        path: '/trial',
        builder: (context, state) => BlocProvider(
          create: (_) => SignupBloc(repository: locator<AuthRepository>()),
          child: const TrialScreen(),
        ),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => BlocProvider(
          create: (_) =>
              ForgotPasswordBloc(repository: locator<AuthRepository>()),
          child: const ForgotPasswordScreen(),
        ),
      ),
      GoRoute(
        path: '/terms',
        builder: (context, state) => const TermsAndConditionsScreen(),
      ),
      GoRoute(
        path: '/privacy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),

      // ── Dongeng player (keep unchanged) ────────────────────────────────────
      GoRoute(
        path: '/dongeng-player',
        builder: (context, state) {
          final dongeng = state.extra as DongengResponse;
          return BlocProvider(
            create: (_) => DongengDetailBloc(dongeng: dongeng),
            child: DongengDetailScreen(dongeng: dongeng),
          );
        },
      ),

      // ── Animal detail ──────────────────────────────────────────────────────
      GoRoute(
        path: '/animal-detail',
        builder: (context, state) {
          final animal = state.extra as AnimalData;
          return AnimalDetailScreen(animal: animal);
        },
      ),

      // ── AR scan shell ──────────────────────────────────────────────────────
      GoRoute(path: '/ar-scan', builder: (_, __) => const ArScanShell()),

      // ── Reward screen ──────────────────────────────────────────────────────
      GoRoute(
        path: '/reward',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return RewardScreen(
            animalName: extra?['animalName'] as String? ?? 'Hewan',
            stars: extra?['stars'] as int? ?? 10,
          );
        },
      ),

      // ── Standalone Koleksi with optional category filter ──────────────────
      GoRoute(
        path: '/koleksi',
        builder: (context, state) {
          final categoryId = state.uri.queryParameters['categoryId'];
          return CollectionScreen(initialCategoryId: categoryId);
        },
      ),

      // ── Premium upgrade ────────────────────────────────────────────────────
      GoRoute(
        path: '/premium',
        builder: (_, __) => const PremiumUpgradeScreen(),
      ),

      // ── Payment ────────────────────────────────────────────────────────────
      GoRoute(
        path: '/payment',
        builder: (context, state) {
          final pack = state.extra as PremiumPack;
          return PaymentScreen(pack: pack);
        },
      ),

      // ── Unlock success ─────────────────────────────────────────────────────
      GoRoute(
        path: '/unlock-success',
        builder: (context, state) {
          final packName = state.extra as String? ?? 'Paket Premium';
          return UnlockSuccessScreen(packName: packName);
        },
      ),
    ],
  );
}
