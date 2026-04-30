import 'package:arunika_app/core/storage/SecureStorageToken.dart';
import 'package:arunika_app/data/models/response/counting_question.dart';
import 'package:arunika_app/data/models/response/dongeng_response.dart';
import 'package:arunika_app/data/models/response/tracing_item.dart';
import 'package:arunika_app/data/repositories/auth_repository.dart';
import 'package:arunika_app/data/repositories/fairy_tales_repository.dart';
import 'package:arunika_app/data/repositories/user_repository.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:arunika_app/presentation/navigation/signup_navigator.dart';
import 'package:arunika_app/presentation/screens/badge/badge_gallery_screen.dart';
import 'package:arunika_app/presentation/screens/counting/counting_exercise_screen.dart';
import 'package:arunika_app/presentation/screens/counting/counting_list_screen.dart';
import 'package:arunika_app/presentation/screens/dongeng/detail/dongeng_detail_bloc.dart';
import 'package:arunika_app/presentation/screens/dongeng/detail/dongeng_detail_screen.dart';
import 'package:arunika_app/presentation/screens/dongeng/dongeng_list_bloc.dart';
import 'package:arunika_app/presentation/screens/dongeng/dongeng_list_event.dart';
import 'package:arunika_app/presentation/screens/dongeng/dongeng_list_screen.dart';
import 'package:arunika_app/presentation/screens/forgotpassword/forgot_password_bloc.dart';
import 'package:arunika_app/presentation/screens/forgotpassword/forgot_password_screen.dart';
import 'package:arunika_app/presentation/screens/growth/growth_screen.dart';
import 'package:arunika_app/presentation/screens/home/home_bloc.dart';
import 'package:arunika_app/presentation/screens/home/home_event.dart';
import 'package:arunika_app/presentation/screens/home/home_screen.dart';
import 'package:arunika_app/presentation/screens/home/home_state.dart';
import 'package:arunika_app/presentation/screens/landing/landing_bloc.dart';
import 'package:arunika_app/presentation/screens/landing/landing_screen.dart';
import 'package:arunika_app/presentation/screens/notification/notification_list_screen.dart';
import 'package:arunika_app/presentation/screens/otp/otp_bloc.dart';
import 'package:arunika_app/presentation/screens/otp/otp_screen.dart';
import 'package:arunika_app/presentation/screens/payment/payment_webview_screen.dart';
import 'package:arunika_app/presentation/screens/profile/profile_bloc.dart';
import 'package:arunika_app/presentation/screens/profile/profile_event.dart';
import 'package:arunika_app/presentation/screens/signin/signin_bloc.dart';
import 'package:arunika_app/presentation/screens/signin/signin_screen.dart';
import 'package:arunika_app/presentation/screens/signup/child_signup_screen.dart';
import 'package:arunika_app/presentation/screens/signup/parent_signup_success_screen.dart';
import 'package:arunika_app/presentation/screens/signup/privacy_policy_screen.dart';
import 'package:arunika_app/presentation/screens/signup/signup_bloc.dart';
import 'package:arunika_app/presentation/screens/signup/signup_screen.dart';
import 'package:arunika_app/presentation/screens/signup/terms_and_condition_screen.dart';
import 'package:arunika_app/presentation/screens/signup/trial_screen.dart';
import 'package:arunika_app/presentation/screens/tracing/tracing_exercise_screen.dart';
import 'package:arunika_app/presentation/screens/tracing/tracing_list_screen.dart';
import 'package:arunika_app/core/auth/auth_notifier.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../screens/profile/profile_screen.dart';

final authNotifier = locator<AuthNotifier>();

class AppRouter {
  static final _publicPaths = [
    '/landing',
    '/signin',
    '/signup',
    '/otp',
    '/trial',
    '/forgot-password',
    '/terms',
    '/privacy',
    '/parent-signup-success',
  ];

  static bool _isPublicPath(String location) =>
      _publicPaths.any((p) => location.startsWith(p));

  static final GoRouter router = GoRouter(
    refreshListenable: authNotifier,
    initialLocation: '/',
    redirect: (context, state) {
      // Only redirect after auth state is initialized (avoids startup false-redirect)
      if (!authNotifier.initialized) return null;
      if (!authNotifier.isLoggedIn && !_isPublicPath(state.matchedLocation)) {
        return '/signin';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        redirect: (context, state) async {
          final token = await SecureTokenStorage.getToken();
          final isLoggedIn = token != null && token.isNotEmpty;

          final goingToAuth =
              state.matchedLocation == '/landing' ||
              state.matchedLocation == '/signin';

          if (!isLoggedIn && !goingToAuth) {
            return '/landing';
          }

          if (isLoggedIn) {
            return '/home';
          }
        },
      ),

      ShellRoute(
        builder: (context, state, child) {
          return BlocProvider(
            create: (_) => SignupBloc(repository: locator<AuthRepository>()),
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/signup',
            builder: (context, state) => const SignupScreen(),
            routes: [
              GoRoute(
                path: 'child',
                builder: (context, state) => ChildSignupScreen(),
              ),
            ],
          ),
        ],
      ),

      GoRoute(
        path: '/landing',
        builder: (context, state) => BlocProvider(
          create: (_) => LandingBloc(),
          child: const LandingScreen(),
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
        path: '/home',
        builder: (context, state) => BlocProvider(
          create: (_) =>
              HomeBloc(repository: locator<FairyTalesRepository>())
                ..add(HomeInitial() as HomeEvent),
          child: const HomeScreen(),
        ),
      ),
      GoRoute(
        path: '/dongeng-list',
        builder: (context, state) => BlocProvider(
          create: (_) =>
              DongengListBloc(repository: locator<FairyTalesRepository>())
                ..add(LoadDongengList()),
          child: const DongengListScreen(),
        ),
      ),

      GoRoute(
        path: '/profile',
        builder: (context, state) => BlocProvider(
          create: (_) =>
              ProfileBloc(repository: locator<UserRepository>())
                ..add(ProfileInitial()),
          child: const ProfileScreen(),
        ),
      ),

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
      GoRoute(
        path: '/signin',
        builder: (context, state) {
          return BlocProvider(
            create: (_) => SigninBloc(
              repository: locator<AuthRepository>(),
              userRepository: locator<UserRepository>(),
            ),
            child: const SignInScreen(),
          );
        },
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) {
          return BlocProvider(
            create: (_) =>
                ForgotPasswordBloc(repository: locator<AuthRepository>()),
            child: const ForgotPasswordScreen(),
          );
        },
      ),
      GoRoute(
        path: '/terms',
        builder: (context, state) => const TermsAndConditionsScreen(),
      ),
      GoRoute(
        path: '/privacy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),

      // ── Education routes ─────────────────────────────────────────────────
      GoRoute(
        path: '/tracing',
        builder: (context, state) => const TracingListScreen(),
      ),
      GoRoute(
        path: '/tracing/exercise',
        builder: (context, state) {
          final item = state.extra as TracingItem;
          return TracingExerciseScreen(item: item);
        },
      ),
      GoRoute(
        path: '/counting',
        builder: (context, state) => const CountingListScreen(),
      ),
      GoRoute(
        path: '/counting/exercise',
        builder: (context, state) {
          final questions = state.extra as List<CountingQuestion>;
          return CountingExerciseScreen(questions: questions);
        },
      ),
      GoRoute(
        path: '/badges',
        builder: (context, state) => const BadgeGalleryScreen(),
      ),
      GoRoute(
        path: '/payment',
        builder: (context, state) => const PaymentScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationListScreen(),
      ),
      GoRoute(
        path: '/growth',
        builder: (context, state) {
          final childId = state.extra as String;
          return GrowthScreen(childId: childId);
        },
      ),
    ],
  );
}
