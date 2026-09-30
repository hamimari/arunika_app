import 'package:arunika_app/presentation/screens/dongeng/detail/page_curl/page_curl.dart';
import 'package:arunika_app/presentation/screens/dongeng/detail/page_curl/page_turn_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _size = Size(800, 400);
final _flap = find.byKey(const ValueKey('page-curl-flap'));

/// Plays the bloc's part: moves the page index when a turn completes.
class _Host extends StatefulWidget {
  const _Host({
    required this.curlKey,
    required this.turns,
    this.start = 0,
    this.reduceMotion = false,
  });

  final GlobalKey<PageCurlState> curlKey;
  final List<TurnDirection> turns;
  final int start;
  final bool reduceMotion;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late int index = widget.start;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQueryData(size: _size, disableAnimations: widget.reduceMotion),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: PageCurl(
          key: widget.curlKey,
          pageCount: 3,
          index: index,
          pageBuilder: (_, i) => ColoredBox(
            color: Colors.primaries[i],
            child: Center(child: Text('page $i')),
          ),
          onTurned: (d) {
            widget.turns.add(d);
            setState(() => index += d == TurnDirection.forward ? 1 : -1);
          },
        ),
      ),
    );
  }
}

void main() {
  late GlobalKey<PageCurlState> curlKey;
  late List<TurnDirection> turns;

  setUp(() {
    curlKey = GlobalKey<PageCurlState>();
    turns = [];
  });

  Future<void> pump(
    WidgetTester tester, {
    int start = 0,
    bool reduceMotion = false,
  }) async {
    tester.view.physicalSize = _size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _Host(
        curlKey: curlKey,
        turns: turns,
        start: start,
        reduceMotion: reduceMotion,
      ),
    );
  }

  // Slow enough (<800 px/s) that only distance decides.
  Future<void> slowDrag(WidgetTester tester, double dx) => tester.timedDrag(
    find.byType(PageCurl),
    Offset(dx, 0),
    const Duration(seconds: 1),
  );

  testWidgets('a drag past the threshold turns to the next page', (
    tester,
  ) async {
    await pump(tester);

    await slowDrag(tester, -400);
    await tester.pumpAndSettle();

    expect(turns, [TurnDirection.forward]);
    expect(find.text('page 1'), findsOneWidget);
    expect(_flap, findsNothing);
  });

  testWidgets('dragging left to right turns back', (tester) async {
    await pump(tester, start: 2);

    await slowDrag(tester, 400);
    await tester.pumpAndSettle();

    expect(turns, [TurnDirection.backward]);
    expect(find.text('page 1'), findsOneWidget);
  });

  testWidgets('a short slow drag springs back without turning', (
    tester,
  ) async {
    await pump(tester);

    await slowDrag(tester, -150);
    await tester.pumpAndSettle();

    expect(turns, isEmpty);
    expect(find.text('page 0'), findsOneWidget);
    expect(_flap, findsNothing);
  });

  testWidgets('a quick fling turns the page', (tester) async {
    await pump(tester);

    await tester.fling(find.byType(PageCurl), const Offset(-120, 0), 2000);
    await tester.pumpAndSettle();

    expect(turns, [TurnDirection.forward]);
  });

  testWidgets('the page curls under the finger mid-drag', (tester) async {
    await pump(tester);

    final gesture = await tester.startGesture(const Offset(700, 200));
    await gesture.moveBy(const Offset(-40, 0)); // past touch slop
    await gesture.moveBy(const Offset(-200, 0));
    await tester.pump();

    expect(_flap, findsOneWidget);
    expect(find.text('page 1'), findsOneWidget, reason: 'next page underneath');
    expect(turns, isEmpty, reason: 'nothing lands until release');

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('dragging back on the first page does nothing', (
    tester,
  ) async {
    await pump(tester);

    final gesture = await tester.startGesture(const Offset(100, 200));
    await gesture.moveBy(const Offset(300, 0));
    await tester.pump();
    expect(_flap, findsNothing);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(turns, isEmpty);
  });

  testWidgets('dragging forward on the last page does nothing', (
    tester,
  ) async {
    await pump(tester, start: 2);
    await slowDrag(tester, -400);
    await tester.pumpAndSettle();
    expect(turns, isEmpty);
    expect(find.text('page 2'), findsOneWidget);
  });

  testWidgets('an arrow tap curls for about 450 ms and turns one page', (
    tester,
  ) async {
    await pump(tester);

    curlKey.currentState!.turn(TurnDirection.forward);
    curlKey.currentState!.turn(TurnDirection.forward); // double tap
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(_flap, findsOneWidget);
    expect(turns, isEmpty);

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(turns, [TurnDirection.forward]);
    expect(find.text('page 1'), findsOneWidget);
  });

  testWidgets('with reduce motion a swipe cross-fades and draws no curl', (
    tester,
  ) async {
    await pump(tester, reduceMotion: true);

    final gesture = await tester.startGesture(const Offset(700, 200));
    await gesture.moveBy(const Offset(-40, 0));
    await gesture.moveBy(const Offset(-360, 0));
    await tester.pump();
    expect(_flap, findsNothing);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(turns, [TurnDirection.forward]);
    expect(find.text('page 1'), findsOneWidget);
  });

  testWidgets('with reduce motion an arrow turns the page at once', (
    tester,
  ) async {
    await pump(tester, reduceMotion: true);

    curlKey.currentState!.turn(TurnDirection.forward);
    await tester.pumpAndSettle();

    expect(turns, [TurnDirection.forward]);
    expect(_flap, findsNothing);
  });
}
