import 'package:arunika_app/core/utils/parental_gate_session.dart';
import 'package:arunika_app/presentation/screens/widgets/parental_gate_guard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpGuard(WidgetTester tester) async {
  await tester.pumpWidget(
    const MaterialApp(
      home: ParentalGateGuard(child: Text('protected content')),
    ),
  );
}

/// Reads the "$a  ×  $b  =  ?" challenge text and returns its answer.
int _readAnswer(WidgetTester tester) {
  final textWidgets = tester.widgetList<Text>(find.byType(Text));
  final match = RegExp(r'^(\d+)\s*×\s*(\d+)').firstMatch(
    textWidgets.map((w) => w.data ?? '').firstWhere((s) => s.contains('×')),
  );
  final a = int.parse(match!.group(1)!);
  final b = int.parse(match.group(2)!);
  return a * b;
}

void main() {
  setUp(() => ParentalGateSession.passed = false);
  tearDown(() => ParentalGateSession.passed = false);

  testWidgets('shows the challenge and hides the child on first access', (tester) async {
    await _pumpGuard(tester);

    expect(find.text('protected content'), findsNothing);
    expect(find.text('Verifikasi Orang Tua'), findsOneWidget);
  });

  testWidgets('wrong answer keeps the gate and shows an error', (tester) async {
    await _pumpGuard(tester);

    await tester.enterText(find.byType(TextField), '999999');
    await tester.tap(find.text('Lanjutkan'));
    await tester.pump();

    expect(find.text('protected content'), findsNothing);
    expect(find.text('Jawaban kurang tepat. Coba lagi.'), findsOneWidget);
    expect(ParentalGateSession.passed, isFalse);
  });

  testWidgets('correct answer reveals the child and marks the session passed', (tester) async {
    await _pumpGuard(tester);

    final answer = _readAnswer(tester);
    await tester.enterText(find.byType(TextField), '$answer');
    await tester.tap(find.text('Lanjutkan'));
    await tester.pump();

    expect(find.text('protected content'), findsOneWidget);
    expect(ParentalGateSession.passed, isTrue);
  });

  testWidgets('gate is skipped once already passed this session', (tester) async {
    ParentalGateSession.passed = true;

    await _pumpGuard(tester);

    expect(find.text('protected content'), findsOneWidget);
    expect(find.text('Verifikasi Orang Tua'), findsNothing);
  });
}
