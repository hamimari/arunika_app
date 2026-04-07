import 'dart:async';
import 'dart:math' as math;
import 'package:ar_flutter_plugin_2/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin_2/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_2/datatypes/hittest_result_types.dart';
import 'package:ar_flutter_plugin_2/datatypes/node_types.dart';
import 'package:ar_flutter_plugin_2/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_2/models/ar_anchor.dart';
import 'package:ar_flutter_plugin_2/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin_2/models/ar_node.dart';
import 'package:arunika_app/data/repositories/ar_repository.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:arunika_app/presentation/screens/qrscanner/qr_scanner.dart';
import 'package:arunika_app/presentation/screens/qrscanner/qr_scanner_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

class ArCoreSurfacePlaceScreen extends StatefulWidget {
  final String modelUrl;
  const ArCoreSurfacePlaceScreen({required this.modelUrl, super.key});

  @override
  State<ArCoreSurfacePlaceScreen> createState() =>
      _ArCoreSurfacePlaceScreenState();
}

class _ArCoreSurfacePlaceScreenState extends State<ArCoreSurfacePlaceScreen> {
  // ── AR managers (nullable so dispose() is safe before onARViewCreated) ────
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  ARAnchorManager? arAnchorManager;

  List<ARNode> nodes = [];
  List<ARAnchor> anchors = [];

  // ── Placement / detection state ───────────────────────────────────────────
  bool _placed = false;
  bool _isPlacing = false;
  bool _planeDetected = false;
  // _tapped: set to true synchronously (via setState) the moment the user taps,
  // so the pulsing hand indicator disappears immediately — before any async
  // AR work begins. Reset to false if placement ultimately fails so the user
  // can try again.
  bool _tapped = false;
  // _showResizeHint: shown for a few seconds after a model is successfully
  // placed to tell the user they can pinch-to-resize while the GLB loads.
  bool _showResizeHint = false;

  // _glbReady: always true — we stream directly from the web URL.
  // SceneView's ModelLoader handles HTTP downloads and caches the result
  // internally, so no manual download step is needed.
  final bool _glbReady = true;

  // ── Scale / rotation state ────────────────────────────────────────────────
  // 0.5 m → 50 cm bounding box. Clearly visible on a floor from standing
  // height (~1.5 m) and on a table from arm's length.
  double _currentScale = 0.5;
  double _currentRotationY = 0.0;

  double _pendingScale = 0.5;
  double _pendingRotationY = 0.0;

  // ── Multi-touch tracking (Listener-based — does NOT enter gesture arena) ──
  // Using Listener instead of GestureDetector is critical: ScaleGestureRecognizer
  // in GestureDetector claims single-finger taps, preventing them from reaching
  // the native AR layer (onPlaneOrPointTap never fires). Listener receives raw
  // pointer events without competing in the gesture arena, so native taps work.
  final Map<int, Offset> _pointers = {};
  double _gestureBaseScale = 0.5;
  double _gestureBaseRotY = 0.0;
  double _initialPointerDistance = 1.0;
  Offset _initialFocalPoint = Offset.zero;

  // ── Debounce ──────────────────────────────────────────────────────────────
  bool _isUpdating = false;
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();

    // Replace callbacks with no-ops FIRST — onPlaneOrPointTap and onPlaneDetected
    // are 'late' non-nullable fields in the plugin (can't be set to null).
    // Swapping to no-ops prevents any late-arriving native events from calling
    // back into a disposed widget and triggering setState-after-dispose crashes.
    if (arSessionManager != null) {
      arSessionManager!.onPlaneOrPointTap = (_) {};
      arSessionManager!.onPlaneDetected = (_) {};
    }

    if (arAnchorManager != null) {
      for (final anchor in anchors) {
        arAnchorManager!.removeAnchor(anchor);
      }
    }
    if (arObjectManager != null) {
      for (final node in nodes) {
        arObjectManager!.removeNode(node);
      }
    }
    arSessionManager?.dispose();

    super.dispose();
  }

  // ── Widget ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── AR view ──────────────────────────────────────────────────────
          // Listener (not GestureDetector) so that single-finger taps are NOT
          // consumed by Flutter's gesture arena and can reach the native AR
          // layer → onPlaneOrPointTap fires → model gets placed.
          Listener(
            onPointerDown: _handlePointerDown,
            onPointerMove: _handlePointerMove,
            onPointerUp: _handlePointerUp,
            onPointerCancel: _handlePointerCancel,
            child: ARView(
              onARViewCreated: _onARViewCreated,
              planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
            ),
          ),

          // ── Pulsing tap indicator (center) — visible once a plane is found
          // and before the user has tapped. Hidden immediately on tap (_tapped).
          if (_planeDetected && !_placed && !_tapped)
            const Positioned.fill(
              child: IgnorePointer(
                child: Center(child: _PulsingTapIndicator()),
              ),
            ),

          // ── Status banner — visible until the model is placed ─────────────
          if (!_placed)
            Positioned(
              bottom: 110,
              left: 24,
              right: 24,
              child: IgnorePointer(
                child: _StatusBanner(
                  planeDetected: _planeDetected,
                  tapped: _tapped,
                ),
              ),
            ),

          // ── Post-placement resize hint ────────────────────────────────────
          // Shown briefly after placement so the user knows what to do while
          // the GLB model is loading over the network.
          if (_placed && _showResizeHint)
            Positioned(
              bottom: 110,
              left: 24,
              right: 24,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.70),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.open_with, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Model loading \u2014 Pinch to resize \u2022 Drag to rotate',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── Scan Again button ─────────────────────────────────────────────
          Positioned(
            bottom: 30,
            left: 24,
            right: 24,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider(
                      create: (_) =>
                          QRScannerBloc(repository: locator<ArRepository>()),
                      child: QRScannerPage(),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text("Scan Again"),
            ),
          ),
        ],
      ),
    );
  }

  // ── AR setup ──────────────────────────────────────────────────────────────

  void _onARViewCreated(
    ARSessionManager sessionManager,
    ARObjectManager objectManager,
    ARAnchorManager anchorManager,
    ARLocationManager locationManager,
  ) async {
    arSessionManager = sessionManager;
    arObjectManager = objectManager;
    arAnchorManager = anchorManager;

    await arSessionManager!.onInitialize(
      showPlanes: true,
      showFeaturePoints: true,
      showWorldOrigin: false,
      handleTaps: true,
    );
    await arObjectManager!.onInitialize();

    // The native sessionConfiguration closure hard-codes planeFindingMode =
    // DISABLED. handleInit overrides this via session.configure(), but
    // sceneView.session is often null right after the view is created (ARCore
    // starts asynchronously). Retry after a short delay so the session is
    // available and plane detection actually gets enabled.
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted || arSessionManager == null) return;

    await arSessionManager!.onInitialize(
      showPlanes: true,
      showFeaturePoints: true,
      showWorldOrigin: false,
      handleTaps: true,
    );
    arSessionManager!.onPlaneOrPointTap = _onPlaneTapped;
    arSessionManager!.onPlaneDetected = _onPlaneDetected;
  }

  // ── Plane detection feedback ──────────────────────────────────────────────

  void _onPlaneDetected(int count) {
    if (!mounted) return;
    if (!_planeDetected && count > 0) {
      setState(() => _planeDetected = true);
    }
  }

  // ── Tap-to-place ──────────────────────────────────────────────────────────

  Future<void> _onPlaneTapped(List<ARHitTestResult> hits) async {
    // Guard: ignore if already placing, model not ready, or widget disposed.
    if (_isPlacing || !_glbReady || !mounted) return;

    // Prefer a plane hit; fall back to a point (feature-point) hit.
    // ARHitTestResultType values: plane, point, undefined.
    // Early in a session only "point" hits exist (white dots); planes appear
    // after the user sweeps the camera over the surface for a few seconds.
    if (hits.isEmpty) return;

    ARHitTestResult? hit;
    for (final h in hits) {
      if (h.type == ARHitTestResultType.plane) {
        hit = h;
        break;
      }
    }
    if (hit == null) {
      for (final h in hits) {
        if (h.type == ARHitTestResultType.point) {
          hit = h;
          break;
        }
      }
    }
    hit ??= hits.first; // last resort: accept any hit type

    _isPlacing = true;
    bool placementSucceeded = false;
    try {
      // Remove previous anchor + node so the user can re-tap to reposition.
      if (anchors.isNotEmpty) {
        await arAnchorManager!.removeAnchor(anchors.first);
        if (!mounted) return;
        anchors.clear();
      }
      if (nodes.isNotEmpty) {
        await arObjectManager!.removeNode(nodes.first);
        if (!mounted) return;
        nodes.clear();
      }

      final anchor = ARPlaneAnchor(transformation: hit.worldTransform);
      final didAddAnchor = await arAnchorManager!.addAnchor(anchor);
      if (!mounted) return;

      // Treat null as success — some ar_flutter_plugin_2 builds return null
      // instead of true when the call actually succeeded.
      if (didAddAnchor != false) {
        anchors.add(anchor);

        final node = ARNode(
          type: NodeType.webGLB,
          uri: widget.modelUrl,
          scale: vector.Vector3.all(_currentScale),
          position: vector.Vector3.zero(),
          rotation: quaternionFromY(_currentRotationY),
        );

        final didAddNode = await arObjectManager!.addNode(
          node,
          planeAnchor: anchor,
        );
        if (!mounted) return;

        if (didAddNode != false) {
          nodes.add(node);
          placementSucceeded = true;
          setState(() {
            _placed = true;
            _showResizeHint = true;
          });
          // Auto-dismiss the resize hint after 5 seconds.
          Future.delayed(const Duration(seconds: 5), () {
            if (mounted) setState(() => _showResizeHint = false);
          });
        }
      }
    } finally {
      _isPlacing = false;
      // If placement failed for any reason, reset _tapped so the user can
      // try again and the pulsing indicator comes back.
      if (!placementSucceeded && mounted && !_placed) {
        setState(() => _tapped = false);
      }
    }
  }

  // ── Listener-based multi-touch handlers ──────────────────────────────────
  // Using raw Listener (not GestureDetector) so single-finger taps are NOT
  // consumed by Flutter's ScaleGestureRecognizer and can reach the native AR
  // layer. onPlaneOrPointTap only fires if Flutter doesn't win the gesture arena.

  void _handlePointerDown(PointerDownEvent event) {
    _pointers[event.pointer] = event.localPosition;

    // Single-finger touch while waiting to place: hide the pulsing indicator
    // immediately — this fires via Flutter's Listener before the native AR
    // layer processes anything, so the response is instant.
    // If placement ultimately doesn't happen (empty hit list, AR failure),
    // a 3-second timer brings the indicator back so the user can try again.
    if (_pointers.length == 1 && _planeDetected && !_placed && !_tapped) {
      setState(() => _tapped = true);
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && !_placed) setState(() => _tapped = false);
      });
    }

    if (_pointers.length >= 2) {
      // Re-initialise baseline whenever a new finger touches down.
      final pts = _pointers.values.toList();
      _initialPointerDistance = math.max(1.0, (pts[0] - pts[1]).distance);
      _initialFocalPoint = (pts[0] + pts[1]) / 2;
      _gestureBaseScale = _currentScale;
      _gestureBaseRotY = _currentRotationY;
    }
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (!_placed || nodes.isEmpty) return;
    if (!_pointers.containsKey(event.pointer)) return;
    _pointers[event.pointer] = event.localPosition;

    if (_pointers.length < 2) return; // ignore single-finger drags

    final pts = _pointers.values.toList();
    final dist = (pts[0] - pts[1]).distance;
    final focal = (pts[0] + pts[1]) / 2;

    final newScale = (_gestureBaseScale * dist / _initialPointerDistance).clamp(
      0.05,
      2.0,
    );
    final newRotY =
        _gestureBaseRotY + (focal.dx - _initialFocalPoint.dx) * 0.01;

    final scaleDelta = (newScale - _pendingScale).abs();
    final rotDelta = (newRotY - _pendingRotationY).abs();
    if (scaleDelta < _pendingScale * 0.01 && rotDelta < 0.5 * math.pi / 180) {
      return;
    }

    _pendingScale = newScale;
    _pendingRotationY = newRotY;
    _scheduleApply();
  }

  void _handlePointerUp(PointerUpEvent event) {
    _pointers.remove(event.pointer);
    if (_pointers.length < 2) {
      // Gesture ended — update base for next gesture.
      _gestureBaseScale = _currentScale;
      _gestureBaseRotY = _currentRotationY;
    }
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    _pointers.remove(event.pointer);
    _gestureBaseScale = _currentScale;
    _gestureBaseRotY = _currentRotationY;
  }

  // ── Debounced apply ───────────────────────────────────────────────────────

  void _scheduleApply() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 50), _applyUpdate);
  }

  Future<void> _applyUpdate() async {
    if (nodes.isEmpty || _isUpdating || _isPlacing) return;
    if (arObjectManager == null || arAnchorManager == null) return;
    if (!mounted) return;

    _isUpdating = true;
    _currentScale = _pendingScale;
    _currentRotationY = _pendingRotationY;

    final oldNode = nodes.removeLast();
    final anchor = anchors.last as ARPlaneAnchor;

    await arObjectManager!.removeNode(oldNode);
    if (!mounted) {
      _isUpdating = false;
      return;
    }

    final newNode = ARNode(
      type: NodeType.webGLB,
      uri: widget.modelUrl,
      scale: vector.Vector3.all(_currentScale),
      position: vector.Vector3.zero(),
      rotation: quaternionFromY(_currentRotationY),
    );

    final didAdd = await arObjectManager!.addNode(newNode, planeAnchor: anchor);
    if (!mounted) {
      _isUpdating = false;
      return;
    }

    if (didAdd != false) {
      nodes.add(newNode);
    }

    _isUpdating = false;
  }

  // ── Quaternion helper ─────────────────────────────────────────────────────

  vector.Vector4 quaternionFromY(double angle) {
    final half = angle / 2;
    return vector.Vector4(0.0, math.sin(half), 0.0, math.cos(half));
  }
}

// ── Pulsing tap indicator ─────────────────────────────────────────────────────
// Shown in the center of the screen once a flat surface is detected, prompting
// the user to tap. Pulses continuously to draw attention.

class _PulsingTapIndicator extends StatefulWidget {
  const _PulsingTapIndicator();

  @override
  State<_PulsingTapIndicator> createState() => _PulsingTapIndicatorState();
}

class _PulsingTapIndicatorState extends State<_PulsingTapIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _scale = Tween<double>(
      begin: 0.88,
      end: 1.12,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          color: Colors.green.shade600.withValues(alpha: 0.90),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.green.shade400.withValues(alpha: 0.5),
              blurRadius: 20,
              spreadRadius: 4,
            ),
          ],
        ),
        child: const Icon(Icons.touch_app, color: Colors.white, size: 44),
      ),
    );
  }
}

// ── Status banner ─────────────────────────────────────────────────────────────
// Shown at the bottom of the AR view (above the Scan Again button) to guide
// the user through three phases: scanning, ready-to-tap, and placing.

class _StatusBanner extends StatelessWidget {
  final bool planeDetected;
  final bool tapped;

  const _StatusBanner({required this.planeDetected, required this.tapped});

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Widget leading;
    final String message;

    if (tapped) {
      // User tapped — async placement in progress.
      bg = Colors.orange.shade800.withValues(alpha: 0.92);
      leading = const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
      );
      message = 'Placing model\u2026';
    } else if (planeDetected) {
      // Plane found — prompt to tap.
      bg = Colors.green.shade700.withValues(alpha: 0.92);
      leading = const Icon(
        Icons.check_circle_outline,
        color: Colors.white,
        size: 20,
      );
      message = 'Flat surface found! Tap to place';
    } else {
      // Still scanning.
      bg = Colors.black.withValues(alpha: 0.60);
      leading = const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
      );
      message = 'Slowly move your camera to find a flat surface';
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          leading,
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
