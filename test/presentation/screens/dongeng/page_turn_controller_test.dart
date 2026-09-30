import 'package:arunika_app/presentation/screens/dongeng/detail/page_curl/page_turn_controller.dart';
import 'package:flutter_test/flutter_test.dart';

const _width = 1000.0;

void main() {
  group('PageTurnController', () {
    test('should_turn_forward_when_dragged_right_to_left_past_the_threshold', () {
      final c = PageTurnController(pageCount: 5, index: 1);

      expect(c.dragUpdate(-400, _width), isTrue);
      expect(c.direction, TurnDirection.forward);
      expect(c.progress, closeTo(0.4, 1e-9));
      expect(c.dragEnd(0), isTrue);

      expect(c.settle(completed: true), TurnDirection.forward);
      expect(c.index, 2);
      expect(c.isTurning, isFalse);
    });

    test('should_turn_back_when_dragged_left_to_right_past_the_threshold', () {
      final c = PageTurnController(pageCount: 5, index: 2)
        ..dragUpdate(360, _width);

      expect(c.direction, TurnDirection.backward);
      expect(c.dragEnd(0), isTrue);
      expect(c.settle(completed: true), TurnDirection.backward);
      expect(c.index, 1);
    });

    test('should_spring_back_after_a_short_slow_drag', () {
      final c = PageTurnController(pageCount: 5, index: 1)
        ..dragUpdate(-340, _width);

      expect(c.dragEnd(-799), isFalse);
      expect(c.settle(completed: false), isNull);
      expect(c.index, 1);
    });

    test('should_complete_exactly_at_the_threshold', () {
      final c = PageTurnController(pageCount: 3)..dragUpdate(-350, _width);

      expect(c.dragEnd(0), isTrue);
    });

    test('should_turn_on_a_fast_fling_even_after_a_short_drag', () {
      final forward = PageTurnController(pageCount: 3)..dragUpdate(-50, _width);
      expect(forward.dragEnd(-800), isTrue);

      final back = PageTurnController(pageCount: 3, index: 1)
        ..dragUpdate(50, _width);
      expect(back.dragEnd(800), isTrue);
    });

    test('should_not_count_a_fling_against_the_turn_direction', () {
      final c = PageTurnController(pageCount: 3)
        ..dragUpdate(-300, _width)
        ..dragUpdate(100, _width); // dragged part of the way back

      expect(c.progress, closeTo(0.2, 1e-9));
      expect(c.dragEnd(2000), isFalse);
    });

    test('should_not_start_a_turn_past_the_ends_of_the_book', () {
      final first = PageTurnController(pageCount: 3);
      expect(first.dragUpdate(200, _width), isFalse);
      expect(first.isTurning, isFalse);
      expect(first.dragEnd(2000), isNull);
      expect(first.startTurn(TurnDirection.backward), isFalse);

      final last = PageTurnController(pageCount: 3, index: 2);
      expect(last.dragUpdate(-200, _width), isFalse);
      expect(last.startTurn(TurnDirection.forward), isFalse);
    });

    test('should_ignore_input_while_a_turn_animates', () {
      final c = PageTurnController(pageCount: 5, index: 1);

      expect(c.startTurn(TurnDirection.forward), isTrue);
      expect(c.startTurn(TurnDirection.forward), isFalse);
      expect(c.dragUpdate(-300, _width), isFalse);
      expect(c.dragEnd(0), isNull);

      c.settle(completed: true);
      expect(c.index, 2, reason: 'one turn, not two');
      expect(c.startTurn(TurnDirection.forward), isTrue);
    });

    test('should_keep_progress_within_0_and_1', () {
      final c = PageTurnController(pageCount: 3)..dragUpdate(-5000, _width);
      expect(c.progress, 1);

      c.dragUpdate(9000, _width);
      expect(c.progress, 0);
      expect(c.direction, TurnDirection.forward, reason: 'direction is fixed');
    });

    test('should_ignore_a_first_update_with_no_movement', () {
      final c = PageTurnController(pageCount: 3);

      expect(c.dragUpdate(0, _width), isFalse);
      expect(c.isTurning, isFalse);
    });
  });
}
