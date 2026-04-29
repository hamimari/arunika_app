import 'package:arunika_app/data/models/response/dongeng_page.dart';
import 'package:arunika_app/data/models/response/dongeng_response.dart';
import 'package:arunika_app/presentation/screens/dongeng/detail/dongeng_detail_bloc.dart';
import 'package:arunika_app/presentation/screens/dongeng/detail/dongeng_detail_event.dart';
import 'package:arunika_app/presentation/screens/dongeng/detail/dongeng_detail_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

DongengPage _page(int n) => DongengPage(
  id: 'page-$n',
  dongengId: 'story-1',
  pageNumber: n,
  imageUrl: 'https://img/$n.png',
  text: 'Text $n',
);

DongengResponse _story({int pageCount = 3}) => DongengResponse(
  id: 'story-1',
  title: 'Test Story',
  ageStart: 3,
  ageEnd: 6,
  isFree: true,
  imageUrl: 'https://img/cover.png',
  audioUrl: '',
  duration: '5 min',
  pages: List.generate(pageCount, (i) => _page(i + 1)),
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
  isDeleted: false,
);

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('DongengDetailBloc', () {
    test('initial state has currentPageIndex 0', () {
      final bloc = DongengDetailBloc(dongeng: _story());
      expect(bloc.state.currentPageIndex, 0);
      expect(bloc.state.isFirstPage, isTrue);
      bloc.close();
    });

    blocTest<DongengDetailBloc, DongengDetailState>(
      'NextPage advances page index',
      build: () => DongengDetailBloc(dongeng: _story()),
      act: (b) => b.add(NextPage()),
      expect: () => [
        isA<DongengDetailState>().having((s) => s.currentPageIndex, 'index', 1),
      ],
    );

    blocTest<DongengDetailBloc, DongengDetailState>(
      'PreviousPage decrements page index',
      build: () => DongengDetailBloc(dongeng: _story()),
      seed: () => DongengDetailState(dongeng: _story(), currentPageIndex: 1),
      act: (b) => b.add(PreviousPage()),
      expect: () => [
        isA<DongengDetailState>().having((s) => s.currentPageIndex, 'index', 0),
      ],
    );

    blocTest<DongengDetailBloc, DongengDetailState>(
      'NextPage is a no-op on the last page',
      build: () => DongengDetailBloc(dongeng: _story(pageCount: 2)),
      seed: () => DongengDetailState(
        dongeng: _story(pageCount: 2),
        currentPageIndex: 1,
      ),
      act: (b) => b.add(NextPage()),
      expect: () => <DongengDetailState>[],
    );

    blocTest<DongengDetailBloc, DongengDetailState>(
      'PreviousPage is a no-op on the first page',
      build: () => DongengDetailBloc(dongeng: _story()),
      act: (b) => b.add(PreviousPage()),
      expect: () => <DongengDetailState>[],
    );

    blocTest<DongengDetailBloc, DongengDetailState>(
      'GoToPage jumps to the specified index',
      build: () => DongengDetailBloc(dongeng: _story()),
      act: (b) => b.add(GoToPage(2)),
      expect: () => [
        isA<DongengDetailState>().having((s) => s.currentPageIndex, 'index', 2),
      ],
    );

    blocTest<DongengDetailBloc, DongengDetailState>(
      'GoToPage clamps index to valid range',
      build: () => DongengDetailBloc(dongeng: _story(pageCount: 3)),
      act: (b) => b.add(GoToPage(99)),
      expect: () => [
        isA<DongengDetailState>().having((s) => s.currentPageIndex, 'index', 2),
      ],
    );

    blocTest<DongengDetailBloc, DongengDetailState>(
      'isLastPage is true on last page',
      build: () => DongengDetailBloc(dongeng: _story(pageCount: 2)),
      act: (b) => b.add(GoToPage(1)),
      expect: () => [
        isA<DongengDetailState>().having(
          (s) => s.isLastPage,
          'isLastPage',
          true,
        ),
      ],
    );
  });
}
