import 'package:arunika_app/presentation/screens/arscanner/placement_machine.dart';
import 'package:flutter_test/flutter_test.dart';

/// A machine that has found a surface and is waiting for a tap.
PlacementMachine _ready() => PlacementMachine()..planeDetected(1);

void main() {
  group('PlacementMachine', () {
    test('should_start_scanning_and_become_ready_on_the_first_plane', () {
      final m = PlacementMachine();
      expect(m.state, PlacementState.scanning);

      expect(m.planeDetected(0), isFalse);
      expect(m.state, PlacementState.scanning);

      expect(m.planeDetected(1), isTrue);
      expect(m.state, PlacementState.ready);

      expect(m.planeDetected(2), isFalse, reason: 'already ready');
    });

    test('should_not_place_before_a_surface_is_found', () {
      final m = PlacementMachine();

      expect(m.pointerDown(), isFalse);
      expect(m.startPlacement(), isFalse);
      expect(m.state, PlacementState.scanning);
    });

    test('should_place_on_finger_down_then_tap_result', () {
      final m = _ready();

      expect(m.pointerDown(), isTrue);
      expect(m.state, PlacementState.placing);
      expect(m.startPlacement(), isTrue);
      m.placementSucceeded();

      expect(m.state, PlacementState.placed);
    });

    test('should_still_place_when_the_tap_result_arrives_after_the_timeout', () {
      // The reported bug: the 1.5s timer reset the screen to ready, then the
      // native tap result arrived and was dropped, so nothing appeared.
      final m = _ready()..pointerDown();

      expect(m.tapTimedOut(), isTrue);
      expect(m.state, PlacementState.ready);

      expect(m.startPlacement(), isTrue);
      expect(m.state, PlacementState.placing);
      m.placementSucceeded();
      expect(m.state, PlacementState.placed);
    });

    test('should_place_on_a_tap_result_without_a_seen_finger_down', () {
      final m = _ready();

      expect(m.startPlacement(), isTrue);
      m.placementSucceeded();

      expect(m.state, PlacementState.placed);
    });

    test('should_not_let_the_timeout_interrupt_a_placement_in_progress', () {
      // The model download can take far longer than the tap timeout.
      final m = _ready()
        ..pointerDown()
        ..startPlacement();

      expect(m.tapTimedOut(), isFalse);
      expect(m.state, PlacementState.placing);
    });

    test('should_ignore_a_second_tap_while_a_placement_is_in_progress', () {
      final m = _ready()..startPlacement();

      expect(m.startPlacement(), isFalse);
    });

    test('should_return_to_ready_and_accept_a_retry_after_a_failure', () {
      final m = _ready()..startPlacement();

      m.placementFailed();
      expect(m.state, PlacementState.ready);

      expect(m.startPlacement(), isTrue);
    });

    test('should_ignore_taps_once_placed', () {
      final m = _ready()..startPlacement();
      m.placementSucceeded();

      expect(m.pointerDown(), isFalse);
      expect(m.startPlacement(), isFalse);
      expect(m.tapTimedOut(), isFalse);
      expect(m.state, PlacementState.placed);
    });
  });
}
