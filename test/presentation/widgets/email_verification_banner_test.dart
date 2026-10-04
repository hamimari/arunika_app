import 'package:arunika_app/data/repositories/auth_repository.dart';
import 'package:arunika_app/presentation/screens/widgets/email_verification_banner.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repo;

  setUp(() => repo = _MockAuthRepository());

  Future<void> pumpBanner(WidgetTester tester, {required bool isVerified}) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmailVerificationBanner(
            isVerified: isVerified,
            repository: repo,
          ),
        ),
      ),
    );
  }

  DioException rateLimited() => DioException(
    requestOptions: RequestOptions(path: '/auth/resend-verification'),
    response: Response(
      requestOptions: RequestOptions(path: '/auth/resend-verification'),
      statusCode: 429,
    ),
  );

  testWidgets('should_show_prompt_when_email_is_unverified', (tester) async {
    await pumpBanner(tester, isVerified: false);

    expect(find.byKey(const Key('email-verification-banner')), findsOneWidget);
    // The prompt must say why verification matters, not just that it is missing.
    expect(find.textContaining('memulihkan kata sandi'), findsOneWidget);
  });

  testWidgets('should_show_nothing_when_email_is_verified', (tester) async {
    await pumpBanner(tester, isVerified: true);

    expect(find.byKey(const Key('email-verification-banner')), findsNothing);
  });

  testWidgets('should_hide_banner_when_dismissed', (tester) async {
    await pumpBanner(tester, isVerified: false);

    await tester.tap(find.byKey(const Key('email-verification-banner-dismiss')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('email-verification-banner')), findsNothing);
  });

  testWidgets('should_confirm_when_resend_succeeds', (tester) async {
    when(() => repo.resendVerification()).thenAnswer((_) async {});
    await pumpBanner(tester, isVerified: false);

    await tester.tap(find.byKey(const Key('email-verification-banner-resend')));
    await tester.pumpAndSettle();

    expect(find.textContaining('sudah dikirim'), findsOneWidget);
    // A confirmed send retires the action — nothing left to do.
    expect(
      find.byKey(const Key('email-verification-banner-resend')),
      findsNothing,
    );
  });

  testWidgets('should_explain_wait_when_resend_is_rate_limited', (tester) async {
    when(() => repo.resendVerification()).thenThrow(rateLimited());
    await pumpBanner(tester, isVerified: false);

    await tester.tap(find.byKey(const Key('email-verification-banner-resend')));
    await tester.pumpAndSettle();

    // Rate limiting is not a failure — the user is told to wait, and the
    // action stays available rather than showing a generic error.
    expect(find.textContaining('Terlalu sering'), findsOneWidget);
    expect(find.textContaining('Gagal'), findsNothing);
    expect(
      find.byKey(const Key('email-verification-banner-resend')),
      findsOneWidget,
    );
  });

  testWidgets('should_keep_action_available_when_resend_fails', (tester) async {
    when(() => repo.resendVerification()).thenThrow(
      DioException(requestOptions: RequestOptions(path: '/x')),
    );
    await pumpBanner(tester, isVerified: false);

    await tester.tap(find.byKey(const Key('email-verification-banner-resend')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Gagal mengirim'), findsOneWidget);
    // Never report success on failure, and leave a way to retry.
    expect(find.textContaining('sudah dikirim'), findsNothing);
    expect(
      find.byKey(const Key('email-verification-banner-resend')),
      findsOneWidget,
    );
  });

  testWidgets('should_not_obstruct_content_while_prompting', (tester) async {
    // Verification gates password recovery and nothing else. The prompt must
    // never sit between a parent and the content or purchases they came for,
    // so it is non-modal: surrounding UI stays fully interactive.
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              EmailVerificationBanner(isVerified: false, repository: repo),
              ElevatedButton(
                key: const Key('buy-button'),
                onPressed: () => tapped = true,
                child: const Text('Beli'),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('email-verification-banner')), findsOneWidget);

    await tester.tap(find.byKey(const Key('buy-button')));
    await tester.pumpAndSettle();

    expect(
      tapped,
      isTrue,
      reason: 'content behind the prompt must stay interactive',
    );
  });
}
