import 'dart:io';

import 'package:arunika_app/core/growth/growth_engine.dart';
import 'package:arunika_app/data/models/response/growth_response.dart';
import 'package:arunika_app/data/repositories/growth_repository.dart';
import 'package:arunika_app/presentation/screens/growth/growth_cubit.dart';
import 'package:arunika_app/presentation/screens/growth/growth_screen.dart';
import 'package:arunika_app/presentation/screens/growth/growth_widgets.dart';
import 'package:arunika_app/presentation/screens/growth/measurement_form_screen.dart';
import 'package:arunika_app/presentation/screens/home/home_growth_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';

class MockGrowthRepository extends Mock implements GrowthRepository {}

final _birth = DateTime(2023, 7, 12);

GrowthMeasurement _m(
  String id,
  DateTime on,
  double? h,
  double? w, {
  String hfa = 'normal',
  String wfa = 'normal',
}) => GrowthMeasurement(
  id: id,
  measuredOn: on,
  heightCm: h,
  weightKg: w,
  position: Position.standing,
  ageDays: ageInDays(_birth, on),
  hfaCategory: h == null ? null : hfa,
  wfaCategory: w == null ? null : wfa,
);

GrowthSummary _summary(List<GrowthMeasurement> ms, {bool complete = true}) =>
    GrowthSummary(
      profileComplete: complete,
      child: GrowthChild(
        id: 'c1',
        name: 'hamiz',
        sex: complete ? Sex.male : null,
        birthDate: complete ? _birth : null,
      ),
      measurements: ms,
    );

final _five = _summary([
  _m('m5', DateTime(2026, 9, 12), 94.8, 13.9),
  _m('m4', DateTime(2026, 6, 12), 92.6, 13.3),
  _m('m3', DateTime(2026, 3, 12), 90.5, 12.8),
  _m('m2', DateTime(2025, 12, 12), 88.2, 12.1),
  _m('m1', DateTime(2025, 9, 12), 86.0, 11.6),
]);

/// A signed decimal z-score as a parent might see it: "-0.68", "−2,00", "1.5 SD".
final _zScorePattern = RegExp(
  r'[-−+]\d+[.,]\d{2}\b|\bSD\b|z-?score',
  caseSensitive: false,
);

void main() {
  late MockGrowthRepository repo;
  late WhoGrowthStandard who;

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    who = WhoGrowthStandard.parse(
      File(WhoGrowthStandard.assetPath).readAsStringSync(),
    );
    registerFallbackValue(
      MeasurementInput(measuredOn: DateTime(2026), position: Position.standing),
    );
  });

  setUp(() => repo = MockGrowthRepository());

  Future<GrowthCubit> pump(
    WidgetTester tester,
    GrowthSummary summary, {
    Widget child = const GrowthScreen(),
  }) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    when(() => repo.fetchSummary('c1')).thenAnswer((_) async => summary);
    final cubit = GrowthCubit(
      repository: repo,
      enabled: () => true,
      childId: () async => 'c1',
      loadStandard: () async => who,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: Scaffold(body: child),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return cubit;
  }

  List<String> allText(WidgetTester tester) => tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data ?? t.textSpan?.toPlainText() ?? '')
      .toList();

  testWidgets('shows tiles, deltas, chart and history', (tester) async {
    await pump(tester, _five);

    expect(find.text('Tumbuh Kembang'), findsOneWidget);
    expect(find.text('hamiz'), findsWidgets);
    expect(find.textContaining('94,8'), findsWidgets);
    expect(find.textContaining('13,9'), findsWidgets);
    expect(find.text('+2,2 cm dari pengukuran lalu'), findsOneWidget);
    expect(find.text('+0,6 kg dari pengukuran lalu'), findsOneWidget);
    expect(find.text('Tinggi badan menurut umur'), findsOneWidget);
    expect(find.text('Tinggi hamiz normal untuk usianya'), findsOneWidget);
    expect(
      find.textContaining('Acuan: WHO Child Growth Standards'),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(find.text('5 data'), 300);
    expect(find.text('Riwayat Pengukuran'), findsOneWidget);
    expect(find.text('12 Des 2025'), findsOneWidget);
    expect(find.text('2 th 5 bln'), findsOneWidget);
  });

  testWidgets('switching to weight redraws the weight chart', (tester) async {
    await pump(tester, _five);
    await tester.tap(
      find.descendant(
        of: find.byType(GrowthSegmentedSwitch),
        matching: find.text('Berat badan'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Berat badan menurut umur'), findsOneWidget);
    expect(find.text('Berat hamiz normal untuk usianya'), findsOneWidget);
  });

  testWidgets('a single measurement hides the change line', (tester) async {
    await pump(tester, _summary([_m('m1', DateTime(2026, 9, 12), 94.8, 13.9)]));
    expect(find.textContaining('dari pengukuran lalu'), findsNothing);
  });

  testWidgets('every category shows its chip and advice, never a z-score', (
    tester,
  ) async {
    await pump(
      tester,
      _summary([
        _m(
          'm1',
          DateTime(2026, 9, 12),
          85.0,
          9.5,
          hfa: 'stunted',
          wfa: 'severely_underweight',
        ),
      ]),
    );
    expect(find.text('Pendek'), findsWidgets);
    expect(find.text('Berat badan sangat kurang'), findsWidgets);
    expect(
      find.text(
        'Coba konsultasikan ke posyandu atau dokter anak saat kunjungan berikutnya.',
      ),
      findsOneWidget,
    );
    for (final text in allText(tester)) {
      expect(_zScorePattern.hasMatch(text), isFalse, reason: text);
    }
  });

  testWidgets('incomplete profile shows the setup prompt and no chart', (
    tester,
  ) async {
    await pump(tester, _summary([], complete: false));
    expect(find.text('Lengkapi profil anak'), findsOneWidget);
    expect(find.text('Lengkapi profil'), findsOneWidget);
    expect(find.text('Tinggi badan menurut umur'), findsNothing);
  });

  testWidgets('delete asks first, then Urungkan restores', (tester) async {
    when(() => repo.delete('c1', 'm5')).thenAnswer((_) async {});
    when(() => repo.restore('c1', 'm5')).thenAnswer((_) async {});
    await pump(tester, _five);
    await tester.scrollUntilVisible(find.text('12 Sep 2026'), 300);

    await tester.tap(find.byTooltip('Hapus pengukuran 12 Sep 2026'));
    await tester.pumpAndSettle();
    expect(find.text('Hapus data pengukuran?'), findsOneWidget);
    expect(find.text('94,8 cm · 13,9 kg'), findsOneWidget);
    expect(find.textContaining('tidak bisa dibatalkan'), findsNothing);

    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    verifyNever(() => repo.delete(any(), any()));

    await tester.tap(find.byTooltip('Hapus pengukuran 12 Sep 2026'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ya, hapus'));
    // The sheet closes, then the toast slides in.
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    verify(() => repo.delete('c1', 'm5')).called(1);
    expect(find.text('Urungkan'), findsOneWidget);

    await tester.tap(find.text('Urungkan'));
    await tester.pumpAndSettle();
    verify(() => repo.restore('c1', 'm5')).called(1);
  });

  group('measurement form', () {
    Future<void> openAdd(WidgetTester tester) async {
      await pump(tester, _five);
      await tester.tap(find.text('Tambah Pengukuran'));
      await tester.pumpAndSettle();
    }

    testWidgets('previews the WHO result on the device', (tester) async {
      await openAdd(tester);
      expect(find.text('Hasil menurut standar WHO'), findsOneWidget);
      expect(find.textContaining('tahun'), findsWidgets);

      await tester.enterText(find.byType(TextField).first, '94,8');
      await tester.pump(const Duration(milliseconds: 300));

      final normalChips = find.descendant(
        of: find.ancestor(
          of: find.text('Tinggi badan / umur'),
          matching: find.byType(Row),
        ),
        matching: find.text('Normal'),
      );
      expect(normalChips, findsOneWidget);
      verifyNever(
        () => repo.create(any(), any(), clientId: any(named: 'clientId')),
      );
    });

    testWidgets('save is disabled while both values are empty', (tester) async {
      await openAdd(tester);
      final save = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text('Simpan'),
          matching: find.byType(FilledButton),
        ),
      );
      expect(save.onPressed, isNull);
    });

    testWidgets('an unusual value needs Tetap simpan', (tester) async {
      when(
        () => repo.create(
          'c1',
          any(),
          clientId: any(named: 'clientId'),
          confirmOutlier: true,
        ),
      ).thenAnswer((_) async => _five.measurements.first);
      await openAdd(tester);

      await tester.enterText(find.byType(TextField).first, '9,5');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();

      expect(
        find.text('Angka ini tidak biasa. Periksa lagi, ya.'),
        findsOneWidget,
      );
      verifyNever(
        () => repo.create(
          any(),
          any(),
          clientId: any(named: 'clientId'),
          confirmOutlier: any(named: 'confirmOutlier'),
        ),
      );

      await tester.tap(find.text('Tetap simpan'));
      await tester.pumpAndSettle();
      verify(
        () => repo.create(
          'c1',
          any(),
          clientId: any(named: 'clientId'),
          confirmOutlier: true,
        ),
      ).called(1);
      expect(find.byType(MeasurementFormScreen), findsNothing);
    });

    testWidgets('a network failure keeps the form and reuses the client id', (
      tester,
    ) async {
      final ids = <String>[];
      when(
        () => repo.create(
          'c1',
          any(),
          clientId: any(named: 'clientId'),
          confirmOutlier: false,
        ),
      ).thenAnswer((inv) async {
        ids.add(inv.namedArguments[#clientId] as String);
        throw const GrowthSaveException(null);
      });
      await openAdd(tester);
      await tester.enterText(find.byType(TextField).last, '14,1');
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();
      expect(
        find.text('Gagal menyimpan. Periksa koneksi, lalu coba lagi.'),
        findsOneWidget,
      );
      expect(find.text('14,1'), findsOneWidget, reason: 'values kept');

      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();
      expect(ids, hasLength(2));
      expect(ids[0], ids[1]);
    });

    testWidgets('edit is pre-filled and offers Hapus data ini', (tester) async {
      await pump(tester, _five);
      await tester.scrollUntilVisible(find.text('12 Sep 2026'), 300);
      await tester.tap(find.byTooltip('Edit pengukuran 12 Sep 2026'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Pengukuran'), findsOneWidget);
      expect(find.text('hamiz · Laki-laki'), findsOneWidget);
      expect(find.text('12 September 2026'), findsOneWidget);
      expect(find.text('94,8'), findsOneWidget);
      expect(find.text('Simpan Perubahan'), findsOneWidget);
      expect(find.text('Hapus data ini'), findsOneWidget);
    });
  });

  group('Beranda card', () {
    testWidgets('shows the latest values', (tester) async {
      await pump(tester, _five, child: const HomeGrowthCard());
      expect(find.text('Tumbuh kembang hamiz'), findsOneWidget);
      expect(find.text('Diukur 12 Sep 2026 · 3 th 2 bln'), findsOneWidget);
      expect(find.text('94,8 cm'), findsOneWidget);
      expect(find.text('13,9 kg'), findsOneWidget);
      expect(find.text('Normal'), findsNWidgets(2));
    });

    testWidgets('new parent sees the first-measurement prompt', (tester) async {
      await pump(tester, _summary([]), child: const HomeGrowthCard());
      expect(find.text('Pantau tumbuh kembang hamiz'), findsOneWidget);
      await tester.tap(find.text('Catat pengukuran pertama'));
      await tester.pumpAndSettle();
      expect(find.text('Tambah Pengukuran'), findsOneWidget);
    });

    testWidgets('renders nothing without a GrowthCubit', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeGrowthCard()));
      expect(find.byType(Text), findsNothing);
    });
  });

  testWidgets('fits a 360 dp phone with 140% text', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.4;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pump(tester, _five);
    tester.view.physicalSize = const Size(1080, 2400);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Tambah Pengukuran'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('12 Sep 2026'), 300);
    await tester.tap(find.byTooltip('Hapus pengukuran 12 Sep 2026'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
