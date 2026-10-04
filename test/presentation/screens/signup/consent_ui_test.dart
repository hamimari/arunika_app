import 'package:arunika_app/core/legal/legal_versions.dart';
import 'package:arunika_app/data/repositories/auth_repository.dart';
import 'package:arunika_app/presentation/screens/signup/child_signup_screen.dart';
import 'package:arunika_app/presentation/screens/signup/privacy_policy_screen.dart';
import 'package:arunika_app/presentation/screens/signup/signup_bloc.dart';
import 'package:arunika_app/presentation/screens/signup/terms_and_condition_screen.dart';
import 'package:arunika_app/presentation/screens/widgets/app_button.dart';
import 'package:arunika_app/presentation/screens/widgets/consent_checkboxes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

Finder get _terms => find.byKey(const Key('consent_terms_checkbox'));
Finder get _parental => find.byKey(const Key('consent_parental_checkbox'));

bool _checked(WidgetTester t, Finder f) => t.widget<Checkbox>(f).value!;

void main() {
  group('ConsentCheckboxes', () {
    testWidgets('should_start_with_both_boxes_unticked', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConsentCheckboxes(
              termsAccepted: false,
              parentalAccepted: false,
              onTermsChanged: (_) {},
              onParentalChanged: (_) {},
            ),
          ),
        ),
      );

      expect(_checked(tester, _terms), isFalse);
      expect(_checked(tester, _parental), isFalse);
    });

    testWidgets('should_report_each_box_separately', (tester) async {
      bool? terms;
      bool? parental;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConsentCheckboxes(
              termsAccepted: false,
              parentalAccepted: false,
              onTermsChanged: (v) => terms = v,
              onParentalChanged: (v) => parental = v,
            ),
          ),
        ),
      );

      await tester.tap(_parental);
      expect((terms, parental), (null, true));

      await tester.tap(_terms);
      expect((terms, parental), (true, true));
    });
  });

  group('ChildSignupScreen consent', () {
    Future<void> pumpScreen(WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (_) => SignupBloc(repository: MockAuthRepository()),
            child: const ChildSignupScreen(),
          ),
        ),
      );
    }

    bool submitEnabled(WidgetTester t) =>
        t.widget<AppButton>(find.byType(AppButton)).enabled;

    testWidgets('should_keep_submit_disabled_until_both_boxes_are_ticked', (
      tester,
    ) async {
      await pumpScreen(tester);
      expect(_checked(tester, _terms), isFalse);
      expect(_checked(tester, _parental), isFalse);
      expect(submitEnabled(tester), isFalse);

      await tester.tap(_terms);
      await tester.pump();
      expect(
        submitEnabled(tester),
        isFalse,
        reason: 'terms alone is not enough',
      );

      await tester.tap(_parental);
      await tester.pump();
      expect(submitEnabled(tester), isTrue);
    });

    testWidgets('should_disable_submit_again_when_a_box_is_unticked', (
      tester,
    ) async {
      await pumpScreen(tester);
      await tester.tap(_terms);
      await tester.tap(_parental);
      await tester.pump();
      expect(submitEnabled(tester), isTrue);

      await tester.tap(_parental);
      await tester.pump();
      expect(submitEnabled(tester), isFalse);
    });
  });

  group('legal documents', () {
    testWidgets('should_show_the_privacy_version_the_app_sends', (t) async {
      await t.pumpWidget(const MaterialApp(home: PrivacyPolicyScreen()));
      expect(
        find.text(
          'Versi ${LegalVersions.privacy} · Berlaku sejak ${LegalVersions.effectiveDate}',
        ),
        findsOneWidget,
      );
    });

    testWidgets('should_show_the_terms_version_the_app_sends', (t) async {
      await t.pumpWidget(const MaterialApp(home: TermsAndConditionsScreen()));
      expect(
        find.text(
          'Versi ${LegalVersions.terms} · Berlaku sejak ${LegalVersions.effectiveDate}',
        ),
        findsOneWidget,
      );
    });

    testWidgets('should_list_the_uu_pdp_data_subject_rights', (t) async {
      t.view.physicalSize = const Size(800, 20000);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(const MaterialApp(home: PrivacyPolicyScreen()));

      expect(find.textContaining('Menarik persetujuan'), findsOneWidget);
      expect(
        find.textContaining('Menghapus data dan menutup akun'),
        findsOneWidget,
      );
      expect(
        find.textContaining('3 x 24 jam setelah kami mengetahuinya'),
        findsOneWidget,
      );
    });

    testWidgets('should_say_only_a_parent_or_guardian_can_register', (t) async {
      t.view.physicalSize = const Size(800, 20000);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(const MaterialApp(home: TermsAndConditionsScreen()));

      expect(find.textContaining('berusia 18 tahun ke atas'), findsOneWidget);
    });
  });
}
