import 'package:arunika_app/data/models/response/dongeng_page.dart';
import 'package:arunika_app/data/models/response/dongeng_response.dart';
import 'package:arunika_app/presentation/screens/dongeng/detail/dongeng_detail_bloc.dart';
import 'package:arunika_app/presentation/screens/dongeng/detail/dongeng_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

DongengResponse _story() => DongengResponse(
  id: 'story-1',
  title: 'Test Story',
  ageStart: 3,
  ageEnd: 6,
  isFree: true,
  imageUrl: '',
  audioUrl: '',
  duration: '5 min',
  pages: [
    for (var n = 1; n <= 3; n++)
      DongengPage(
        id: 'page-$n',
        dongengId: 'story-1',
        pageNumber: n,
        imageUrl: '', // fails fast to the error placeholder
        text: 'Text $n',
      ),
  ],
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
  isDeleted: false,
);

void main() {
  late DongengDetailBloc bloc;

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 420);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    bloc = DongengDetailBloc(dongeng: _story());
    addTearDown(bloc.close);
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: bloc,
          child: DongengDetailScreen(dongeng: _story()),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('swiping the picture turns the page once the curl lands', (
    tester,
  ) async {
    await pump(tester);

    final gesture = await tester.startGesture(const Offset(600, 200));
    await gesture.moveBy(const Offset(-40, 0));
    await gesture.moveBy(const Offset(-300, 0));
    await tester.pump();
    expect(bloc.state.currentPageIndex, 0, reason: 'not before release');
    expect(find.text('Text 1'), findsOneWidget);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(bloc.state.currentPageIndex, 1);
    expect(find.text('Text 2'), findsOneWidget);
    expect(find.text('2 / 3'), findsOneWidget);
  });

  testWidgets('tapping next twice quickly turns exactly one page', (
    tester,
  ) async {
    await pump(tester);

    final next = find.byIcon(Icons.arrow_forward_ios_rounded);
    await tester.tap(next);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(next);
    await tester.pumpAndSettle();

    expect(bloc.state.currentPageIndex, 1);
  });

  testWidgets('a drag that starts on the subtitle does not turn the page', (
    tester,
  ) async {
    await pump(tester);

    final start = tester.getCenter(find.text('Text 1'));
    final gesture = await tester.startGesture(start);
    await gesture.moveBy(const Offset(-40, 0));
    await gesture.moveBy(const Offset(-400, 0));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(bloc.state.currentPageIndex, 0);
  });
}
