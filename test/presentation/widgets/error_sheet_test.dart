import 'package:arunika_app/presentation/screens/widgets/error_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpSheet(
  WidgetTester tester, {
  required String message,
  String? title,
  Size surfaceSize = const Size(360, 640),
}) async {
  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => AppErrorSheet(
                title: title,
                message: message,
                onConfirm: () {},
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'a long message on a narrow phone does not overflow the sheet',
    (tester) async {
      // Mirrors the real "Cek Email" copy with a long email address, on a
      // small phone width — this combination overflowed the old fixed-
      // height (28% of screen) sheet by wrapping onto an extra line.
      await _pumpSheet(
        tester,
        title: 'Cek Email',
        message:
            'Link reset kata sandi telah dikirim ke email '
            'a.very.long.example.address+testing@subdomain.example.co.id.',
        surfaceSize: const Size(320, 568),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Cek Email'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsWidgets);
    },
  );

  testWidgets('a short message still renders correctly', (tester) async {
    await _pumpSheet(
      tester,
      title: 'Gagal Mengirim',
      message: 'Coba lagi.',
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Gagal Mengirim'), findsOneWidget);
    expect(find.text('Coba lagi.'), findsOneWidget);
  });

  testWidgets('confirming pops the sheet and calls onConfirm', (
    tester,
  ) async {
    var confirmed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => AppErrorSheet(
                  message: 'Done',
                  onConfirm: () => confirmed = true,
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mengerti'));
    await tester.pumpAndSettle();

    expect(confirmed, isTrue);
    expect(find.text('Done'), findsNothing);
  });
}
