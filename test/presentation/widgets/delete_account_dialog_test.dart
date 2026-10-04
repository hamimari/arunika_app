import 'package:arunika_app/presentation/screens/widgets/delete_account_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<bool?> _openDialog(WidgetTester tester) async {
  bool? result;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showDialog<bool>(
                context: context,
                builder: (_) => const DeleteAccountDialog(),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return result;
}

void main() {
  testWidgets('confirm button is disabled until HAPUS is typed', (tester) async {
    await _openDialog(tester);

    final confirmButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Hapus Akun Permanen'),
    );
    expect(confirmButton.onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'wrong');
    await tester.pump();
    final stillDisabled = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Hapus Akun Permanen'),
    );
    expect(stillDisabled.onPressed, isNull);
  });

  testWidgets('typing HAPUS (case-insensitive) enables confirm and pops true', (tester) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showDialog<bool>(
                  context: context,
                  builder: (_) => const DeleteAccountDialog(),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'hapus');
    await tester.pump();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Hapus Akun Permanen'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
  });

  testWidgets('Batal pops false without requiring the confirm word', (tester) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showDialog<bool>(
                  context: context,
                  builder: (_) => const DeleteAccountDialog(),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();

    expect(result, isFalse);
  });
}
