import 'package:arunika_app/data/models/response/order_response.dart';
import 'package:arunika_app/data/models/response/payment_history_item.dart';
import 'package:arunika_app/presentation/screens/payment_history/payment_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting('id_ID');
  });

  Widget wrap(PaymentHistoryItem item) => MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(child: PaymentHistoryCard(item: item)),
    ),
  );

  testWidgets('shows product, price, status, method, time and order id', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        PaymentHistoryItem(
          orderId: '3f1c2a9e-0000-4000-8000-000000000001',
          itemType: PaymentItemType.arCard,
          itemName: 'Harimau Sumatera',
          amountIdr: 15000,
          status: OrderStatus.paid,
          paymentMethod: 'BCA Virtual Account',
          createdAt: DateTime(2026, 9, 1, 10, 30),
          updatedAt: DateTime(2026, 9, 1, 10, 35),
        ),
      ),
    );

    expect(find.text('Harimau Sumatera'), findsOneWidget);
    expect(find.text('Kartu AR'), findsOneWidget);
    expect(find.text('Rp 15.000'), findsOneWidget);
    expect(find.text('Berhasil'), findsOneWidget);
    expect(find.text('BCA Virtual Account'), findsOneWidget);
    expect(find.text('1 Sep 2026, 10:30'), findsOneWidget);
    expect(find.text('Waktu Bayar'), findsOneWidget);
    expect(find.text('3f1c2a9e-0000-4000-8000-000000000001'), findsOneWidget);
  });

  testWidgets('pending order hides paid time and shows a dash for method', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        PaymentHistoryItem(
          orderId: 'o-2',
          itemType: PaymentItemType.package,
          packageType: 'subscription',
          itemName: 'Langganan Bulanan',
          amountIdr: 29900,
          status: OrderStatus.pending,
          paymentMethod: '',
          createdAt: DateTime(2026, 9, 2, 8),
          updatedAt: DateTime(2026, 9, 2, 8),
        ),
      ),
    );

    expect(find.text('Menunggu'), findsOneWidget);
    expect(find.text('Paket Langganan'), findsOneWidget);
    expect(find.text('-'), findsOneWidget);
    expect(find.text('Waktu Bayar'), findsNothing);
  });

  testWidgets('copy button puts the order id on the clipboard', (tester) async {
    final copied = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied.add((call.arguments as Map)['text'] as String);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await tester.pumpWidget(
      wrap(
        PaymentHistoryItem(
          orderId: 'order-to-copy',
          itemType: PaymentItemType.dongeng,
          itemName: 'Kancil',
          amountIdr: 10000,
          status: OrderStatus.failed,
          paymentMethod: 'GoPay',
          createdAt: DateTime(2026, 9, 3),
          updatedAt: DateTime(2026, 9, 3),
        ),
      ),
    );

    await tester.tap(find.byIcon(Iconsax.copy));
    await tester.pump();

    expect(copied, ['order-to-copy']);
    expect(find.text('ID pesanan disalin'), findsOneWidget);
  });
}
