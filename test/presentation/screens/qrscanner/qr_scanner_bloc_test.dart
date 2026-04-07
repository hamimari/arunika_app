// ignore_for_file: inference_failure_on_function_invocation

import 'package:arunika_app/data/models/response/ar_card_response.dart';
import 'package:arunika_app/data/repositories/ar_repository.dart';
import 'package:arunika_app/presentation/screens/qrscanner/qr_scanner_bloc.dart';
import 'package:arunika_app/presentation/screens/qrscanner/qr_scanner_event.dart';
import 'package:arunika_app/presentation/screens/qrscanner/qr_scanner_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// ── Mocks ─────────────────────────────────────────────────────────────────────

class MockArRepository extends Mock implements ArRepository {}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late MockArRepository mockRepository;
  late QRScannerBloc bloc;

  setUp(() {
    mockRepository = MockArRepository();
    bloc = QRScannerBloc(repository: mockRepository);
  });

  tearDown(() {
    bloc.close();
  });

  group('QRScannerBloc', () {
    // ── Task 5.1: success path ───────────────────────────────────────────────

    blocTest<QRScannerBloc, QRScannerState>(
      'emits [ModelLoading, ModelLoaded] when FetchModelById succeeds with a file URL',
      build: () {
        when(() => mockRepository.findById(any())).thenAnswer(
          (_) async => ArCardResponse(fileUrl: 'https://example.com/model.glb'),
        );
        return bloc;
      },
      act: (b) => b.add(const FetchModelById('abc123')),
      expect: () => [
        isA<ModelLoading>(),
        isA<ModelLoaded>().having(
          (s) => s.modelUrl,
          'modelUrl',
          'https://example.com/model.glb',
        ),
      ],
    );

    blocTest<QRScannerBloc, QRScannerState>(
      'emits [ModelLoading, ModelError] when repository returns null fileUrl',
      build: () {
        when(
          () => mockRepository.findById(any()),
        ).thenAnswer((_) async => ArCardResponse(fileUrl: null));
        return bloc;
      },
      act: (b) => b.add(const FetchModelById('abc123')),
      expect: () => [
        isA<ModelLoading>(),
        isA<ModelError>().having(
          (s) => s.message,
          'message',
          'Model not found',
        ),
      ],
    );

    // ── Task 5.1: failure path ───────────────────────────────────────────────

    blocTest<QRScannerBloc, QRScannerState>(
      'emits [ModelLoading, ModelError] when repository throws',
      build: () {
        when(
          () => mockRepository.findById(any()),
        ).thenThrow(Exception('network error'));
        return bloc;
      },
      act: (b) => b.add(const FetchModelById('abc123')),
      expect: () => [
        isA<ModelLoading>(),
        isA<ModelError>().having((s) => s.message, 'message', 'Server error'),
      ],
    );

    // ── Task 5.2: guard flag — second scan is handled by the QRScannerPage ──
    // The BLoC itself has no guard; the page's `scanned` bool prevents a
    // second `add()`. We verify that if two events ARE dispatched in sequence,
    // the bloc processes both independently (no internal double-dispatch block).
    blocTest<QRScannerBloc, QRScannerState>(
      'processes two sequential FetchModelById events independently',
      build: () {
        when(() => mockRepository.findById('first')).thenAnswer(
          (_) async => ArCardResponse(fileUrl: 'https://example.com/a.glb'),
        );
        when(() => mockRepository.findById('second')).thenAnswer(
          (_) async => ArCardResponse(fileUrl: 'https://example.com/b.glb'),
        );
        return bloc;
      },
      act: (b) async {
        b.add(const FetchModelById('first'));
        await Future<void>.delayed(const Duration(milliseconds: 50));
        b.add(const FetchModelById('second'));
      },
      expect: () => [
        isA<ModelLoading>(),
        isA<ModelLoaded>().having(
          (s) => s.modelUrl,
          'modelUrl first',
          'https://example.com/a.glb',
        ),
        isA<ModelLoading>(),
        isA<ModelLoaded>().having(
          (s) => s.modelUrl,
          'modelUrl second',
          'https://example.com/b.glb',
        ),
      ],
    );
  });
}
