// Tap-to-place state machine for ArCoreSurfacePlaceScreen, kept free of
// Flutter and AR plugin types so its transitions can be unit tested.
//
//   scanning → ready    : first plane detected
//   ready    → placing  : finger down (instant feedback) or a tap result
//   placing  → ready    : no tap result in time, or placement failed
//   placing  → placed   : model added
enum PlacementState { scanning, ready, placing, placed }

class PlacementMachine {
  PlacementState _state = PlacementState.scanning;
  // True from the moment a tap result starts placing until it finishes.
  // Separate from `placing`, which is also shown right after finger-down
  // while no tap result has arrived yet.
  bool _inFlight = false;

  PlacementState get state => _state;

  /// Returns true when the state changed.
  bool planeDetected(int count) {
    if (_state != PlacementState.scanning || count <= 0) return false;
    _state = PlacementState.ready;
    return true;
  }

  /// Finger down while a surface is ready: show progress right away, before
  /// the native side confirms the tap.
  bool pointerDown() {
    if (_state != PlacementState.ready) return false;
    _state = PlacementState.placing;
    return true;
  }

  /// No tap result came back (a drag or pinch never becomes a tap). Reverts
  /// the banner only if no placement has started.
  bool tapTimedOut() {
    if (_state != PlacementState.placing || _inFlight) return false;
    _state = PlacementState.ready;
    return true;
  }

  /// Whether a native tap result should start a placement. A result that
  /// arrives after [tapTimedOut] already reset the screen to ready is still
  /// honoured — dropping it left the user tapping with nothing appearing.
  bool startPlacement() {
    if (_inFlight) return false;
    if (_state != PlacementState.ready && _state != PlacementState.placing) {
      return false;
    }
    _inFlight = true;
    _state = PlacementState.placing;
    return true;
  }

  void placementSucceeded() {
    _inFlight = false;
    _state = PlacementState.placed;
  }

  void placementFailed() {
    _inFlight = false;
    if (_state == PlacementState.placing) _state = PlacementState.ready;
  }
}
