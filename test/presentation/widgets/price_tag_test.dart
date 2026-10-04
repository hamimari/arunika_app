import 'package:arunika_app/presentation/screens/widgets/price_tag.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> _pump(WidgetTester tester, Widget child) =>
    tester.pumpWidget(MaterialApp(home: Scaffold(body: Center(child: child))));

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting('id_ID');
  });

  testWidgets('shows only the price without a promo', (tester) async {
    await _pump(tester, const PriceTag(price: 39000));

    expect(find.text('Rp 39.000'), findsOneWidget);
    expect(find.textContaining('%'), findsNothing);
  });

  testWidgets('shows the crossed-out strike price, badge and promo end', (tester) async {
    await _pump(
      tester,
      PriceTag(
        price: 39000,
        strikePrice: 49000,
        discountPercent: 20,
        promoEndsAt: DateTime(2026, 10, 31, 12),
        showPromoEnd: true,
      ),
    );

    expect(find.text('Rp 39.000'), findsOneWidget);
    final strike = tester.widget<Text>(find.text('Rp 49.000'));
    expect(strike.style?.decoration, TextDecoration.lineThrough);
    expect(find.text('-20%'), findsOneWidget);
    expect(find.text('Promo s/d 31 Okt'), findsOneWidget);
  });

  testWidgets('ignores a strike price that is not above the price', (tester) async {
    await _pump(tester, const PriceTag(price: 39000, strikePrice: 39000, discountPercent: 0));

    expect(find.text('Rp 39.000'), findsOneWidget);
    expect(find.text('-0%'), findsNothing);
  });

  testWidgets('compact chip shows price and strike price only', (tester) async {
    await _pump(
      tester,
      const PriceTag(price: 15000, strikePrice: 19000, discountPercent: 21, compact: true),
    );

    expect(find.text('Rp 15.000'), findsOneWidget);
    expect(find.text('Rp 19.000'), findsOneWidget);
    expect(find.text('-21%'), findsNothing);
  });
}
