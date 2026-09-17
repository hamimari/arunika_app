import 'dart:async';
import 'dart:math' as math;
import 'package:ar_flutter_plugin_2/ar_flutter_plugin.dart';
import 'package:just_audio/just_audio.dart';
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
import 'package:arunika_app/core/media/media_cache.dart';
import 'package:arunika_app/data/repositories/ar_repository.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:arunika_app/presentation/screens/qrscanner/qr_scanner.dart';
import 'package:arunika_app/presentation/screens/qrscanner/qr_scanner_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

// ── Placement state machine ───────────────────────────────────────────────────
// Replaces the three independent boolean flags (_placed, _tapped, _planeDetected)
// that were prone to race conditions when multiple events arrived close together.
//
//   scanning → ready    : first onPlaneDetected with count > 0
//   ready    → placing  : first pointer-down (any number of simultaneous fingers)
//   placing  → placed   : addNode succeeds
//   placing  → ready    : placement fails (empty hits, AR error)
enum _PlacementState { scanning, ready, placing, placed }

class ArCoreSurfacePlaceScreen extends StatefulWidget {
  final String modelUrl;
  final String? soundUrl;

  /// When [true] (default), the bottom button is "Scan Again" which replaces
  /// this screen with a fresh [QRScannerPage].  Set to [false] when navigating
  /// from [ArCardDetailScreen] — the button becomes a plain "Back" that pops
  /// back to the detail screen.
  final bool showScanAgain;

  const ArCoreSurfacePlaceScreen({
    required this.modelUrl,
    this.soundUrl,
    this.showScanAgain = true,
    super.key,
  });

  @override
  State<ArCoreSurfacePlaceScreen> createState() =>
      _ArCoreSurfacePlaceScreenState();
}

class _ArCoreSurfacePlaceScreenState extends State<ArCoreSurfacePlaceScreen>
    with SingleTickerProviderStateMixin {
  // ── AR managers (nullable so dispose() is safe before onARViewCreated) ────
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  ARAnchorManager? arAnchorManager;

  List<ARNode> nodes = [];
  List<ARAnchor> anchors = [];
  ARNode? _modelNode;
  ARNode? _platformNode;

  static const _platformAsset = 'assets/models/ar_base_platform.glb';
  // Platform diameter relative to the model's largest dimension.
  static const _platformSizeRatio = 1.0;

  // ── State machine ─────────────────────────────────────────────────────────
  _PlacementState _state = _PlacementState.scanning;

  // ── Ripple entrance animation ─────────────────────────────────────────────
  // A screen-space ripple plays at the tap position the moment the user taps.
  // It runs entirely in Flutter (no AR layer involvement), so it's immediate
  // and smooth regardless of how long the native placement call takes.
  late final AnimationController _rippleCtrl;
  late final Animation<double> _rippleScale;
  late final Animation<double> _rippleOpacity;
  Offset _tapPosition = Offset.zero;
  bool _showRipple = false;

  // _showResizeHint: shown for a few seconds after placement.
  bool _showResizeHint = false;

  // ── Scale / rotation state ────────────────────────────────────────────────
  // Android (SceneView) treats scale as "fit the model's largest dimension to
  // N meters", so this is a real-world size. It's recomputed from the tap
  // distance on placement so the model looks proportionate on screen.
  double _currentScale = 0.3;
  double _currentRotationY = 0.0;

  Timer? _holdRotateTimer;

  // A pointer-down that never becomes a native single tap (drag, pinch, long
  // press) would otherwise leave the screen stuck showing "Placing model…".
  Timer? _tapResultTimeout;

  // ── Multi-touch tracking (Listener-based) ─────────────────────────────────
  final Map<int, Offset> _pointers = {};
  double _gestureBaseScale = 0.3;
  double _gestureBaseRotY = 0.0;
  double _initialPointerDistance = 1.0;
  Offset _initialFocalPoint = Offset.zero;

  // ── Audio ─────────────────────────────────────────────────────────────────
  // Initialised only when soundUrl is provided; null otherwise so no resources
  // are allocated when the feature is not in use.
  AudioPlayer? _audioPlayer;

  @override
  void initState() {
    super.initState();
    _rippleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _rippleScale = Tween<double>(
      begin: 0.0,
      end: 2.8,
    ).animate(CurvedAnimation(parent: _rippleCtrl, curve: Curves.easeOut));
    _rippleOpacity = Tween<double>(
      begin: 0.7,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _rippleCtrl, curve: Curves.easeIn));
    _rippleCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _showRipple = false);
        _rippleCtrl.reset();
      }
    });

    final url = widget.soundUrl;
    if (url != null && url.isNotEmpty) {
      _audioPlayer = AudioPlayer();
      // When audio finishes naturally, reset to idle so the button icon
      // snaps back to the play state without requiring a manual stop.
      _audioPlayer!.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          _audioPlayer!.stop();
          _audioPlayer!.seek(Duration.zero);
        }
      });
    }
  }

  @override
  void dispose() {
    _holdRotateTimer?.cancel();
    _tapResultTimeout?.cancel();
    _rippleCtrl.dispose();
    _audioPlayer?.dispose();

    // Replace callbacks with no-ops FIRST — onPlaneOrPointTap and onPlaneDetected
    // are 'late' non-nullable fields in the plugin (can't be set to null).
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

          // ── Ripple at tap point ───────────────────────────────────────────
          // Plays immediately on pointer-down (before any async AR work),
          // giving instant visual feedback that the tap was registered.
          if (_showRipple)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _rippleCtrl,
                  builder: (_, __) {
                    const baseRadius = 44.0;
                    final radius = baseRadius * _rippleScale.value;
                    return CustomPaint(
                      painter: _RipplePainter(
                        center: _tapPosition,
                        radius: radius,
                        opacity: _rippleOpacity.value,
                      ),
                    );
                  },
                ),
              ),
            ),

          // ── Pulsing tap indicator (center) ────────────────────────────────
          // Visible only when a plane is found AND the user hasn't tapped yet.
          if (_state == _PlacementState.ready)
            const Positioned.fill(
              child: IgnorePointer(
                child: Center(child: _PulsingTapIndicator()),
              ),
            ),

          // ── Status banner ─────────────────────────────────────────────────
          if (_state != _PlacementState.placed)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 168,
              left: 24,
              right: 24,
              child: IgnorePointer(child: _StatusBanner(state: _state)),
            ),

          // ── Post-placement resize hint ────────────────────────────────────
          if (_state == _PlacementState.placed && _showResizeHint)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 168,
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.open_with,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Pinch to resize \u2022 Use the buttons to rotate',
                          style: const TextStyle(
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

          // ── Bottom control row: rotate left • sound • rotate right ────────
          // Kept at the bottom so a zoomed-in model in the middle of the
          // screen isn't covered. Empty slots keep each button in place.
          // The sound button is visible before placement so the user can
          // listen while scanning for a surface.
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 88,
            left: 24,
            right: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_state == _PlacementState.placed)
                  _RotateButton(
                    icon: Icons.rotate_left_rounded,
                    tooltip: 'Rotate left',
                    onTap: () => _rotateBy(-math.pi / 4),
                    onHoldStart: () => _startHoldRotate(-1),
                    onHoldEnd: _stopHoldRotate,
                  )
                else
                  const SizedBox.shrink(),
                if (_audioPlayer != null)
                  _SoundButton(
                    player: _audioPlayer!,
                    soundUrl: widget.soundUrl!,
                  )
                else
                  const SizedBox.shrink(),
                if (_state == _PlacementState.placed)
                  _RotateButton(
                    icon: Icons.rotate_right_rounded,
                    tooltip: 'Rotate right',
                    onTap: () => _rotateBy(math.pi / 4),
                    onHoldStart: () => _startHoldRotate(1),
                    onHoldEnd: _stopHoldRotate,
                  )
                else
                  const SizedBox.shrink(),
              ],
            ),
          ),

          // ── Bottom action button ──────────────────────────────────────────
          // "Scan Again"  — when opened from the QR scanner (default).
          // "Back"        — when opened from ArCardDetailScreen; pops back.
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 16,
            left: 24,
            right: 24,
            child: widget.showScanAgain
                ? ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BlocProvider(
                            create: (_) => QRScannerBloc(
                              repository: locator<ArRepository>(),
                            ),
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
                    label: const Text('Scan Again'),
                  )
                : ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('Back'),
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

    // showAnimatedGuide: true on the first call only — adds the native hand-rotate
    // guide view once. The native session update callback auto-removes it as soon
    // as ARCore detects the first tracked plane (no Dart involvement needed).
    // Feature points stay off: they draw a cloud of dots that ends up under
    // the placed model. The plane overlay alone is enough to guide placement.
    await arSessionManager!.onInitialize(
      showAnimatedGuide: true,
      showPlanes: true,
      showFeaturePoints: false,
      showWorldOrigin: false,
      handleTaps: true,
    );
    await arObjectManager!.onInitialize();

    // Retry after 800ms — the native session is often not ready immediately and
    // plane finding mode defaults to DISABLED until session.configure() runs.
    // showAnimatedGuide: false here so we don't add a second guide on top of
    // the first one (the native field check requires BOTH the arg AND the class
    // field to be true, but after the first call the view is already present).
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted || arSessionManager == null) return;

    await arSessionManager!.onInitialize(
      showAnimatedGuide: false,
      showPlanes: true,
      showFeaturePoints: false,
      showWorldOrigin: false,
      handleTaps: true,
    );
    arSessionManager!.onPlaneOrPointTap = _onPlaneTapped;
    arSessionManager!.onPlaneDetected = _onPlaneDetected;
  }

  // ── Plane detection feedback ──────────────────────────────────────────────

  void _onPlaneDetected(int count) {
    if (!mounted) return;
    if (_state == _PlacementState.scanning && count > 0) {
      setState(() => _state = _PlacementState.ready);
    }
  }

  // ── Tap-to-place ──────────────────────────────────────────────────────────

  Future<void> _onPlaneTapped(List<ARHitTestResult> hits) async {
    // Only act when we're in the 'placing' state (pointer-down already fired).
    if (_state != _PlacementState.placing || !mounted) return;
    _tapResultTimeout?.cancel();

    if (hits.isEmpty) {
      if (mounted) setState(() => _state = _PlacementState.ready);
      return;
    }

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
    hit ??= hits.first;

    bool placementSucceeded = false;
    try {
      if (anchors.isNotEmpty) {
        await arAnchorManager!.removeAnchor(anchors.first);
        if (!mounted) return;
        anchors.clear();
      }
      for (final node in nodes) {
        arObjectManager!.removeNode(node);
      }
      nodes.clear();
      _modelNode = null;
      _platformNode = null;

      final anchor = ARPlaneAnchor(transformation: hit.worldTransform);
      final didAddAnchor = await arAnchorManager!.addAnchor(anchor);
      if (!mounted) return;

      if (didAddAnchor != false) {
        anchors.add(anchor);

        _currentScale = _sizeForDistance(hit.distance);
        _gestureBaseScale = _currentScale;

        // The platform is a tiny bundled asset, so it appears right away and
        // shows where the model will land while the model downloads.
        final platform = _buildPlatformNode();
        final didAddPlatform = await arObjectManager!.addNode(
          platform,
          planeAnchor: anchor,
        );
        if (!mounted) return;
        if (didAddPlatform != false) {
          nodes.add(platform);
          _platformNode = platform;
        }

        final node = _buildNode();

        final didAddNode = await arObjectManager!.addNode(
          node,
          planeAnchor: anchor,
        );
        if (!mounted) return;

        if (didAddNode != false) {
          nodes.add(node);
          _modelNode = node;
          placementSucceeded = true;
          arSessionManager?.showPlanes(false);
          setState(() {
            _state = _PlacementState.placed;
            _showResizeHint = true;
          });
          Future.delayed(const Duration(seconds: 5), () {
            if (mounted) setState(() => _showResizeHint = false);
          });
        }
      }
    } finally {
      if (!placementSucceeded && mounted) {
        final platform = _platformNode;
        if (platform != null) {
          arObjectManager?.removeNode(platform);
          nodes.remove(platform);
          _platformNode = null;
        }
        if (_state == _PlacementState.placing) {
          setState(() => _state = _PlacementState.ready);
        }
      }
    }
  }

  // ── Listener-based multi-touch handlers ──────────────────────────────────

  void _handlePointerDown(PointerDownEvent event) {
    _pointers[event.pointer] = event.localPosition;

    // Transition to 'placing' the instant the first finger touches down while
    // the surface is ready. This hides the pulsing indicator immediately —
    // no _pointers.length guard needed (any touch counts).
    if (_state == _PlacementState.ready) {
      setState(() {
        _state = _PlacementState.placing;
        _tapPosition = event.localPosition;
        _showRipple = true;
      });
      _rippleCtrl.forward();
      _tapResultTimeout?.cancel();
      _tapResultTimeout = Timer(const Duration(milliseconds: 1500), () {
        if (mounted && _state == _PlacementState.placing) {
          setState(() => _state = _PlacementState.ready);
        }
      });
    }

    if (_pointers.length >= 2) {
      final pts = _pointers.values.toList();
      _initialPointerDistance = math.max(1.0, (pts[0] - pts[1]).distance);
      _initialFocalPoint = (pts[0] + pts[1]) / 2;
      _gestureBaseScale = _currentScale;
      _gestureBaseRotY = _currentRotationY;
    }
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (_state != _PlacementState.placed || nodes.isEmpty) return;
    if (!_pointers.containsKey(event.pointer)) return;
    _pointers[event.pointer] = event.localPosition;

    if (_pointers.length < 2) return;

    final pts = _pointers.values.toList();
    final dist = (pts[0] - pts[1]).distance;
    final focal = (pts[0] + pts[1]) / 2;

    final newScale = (_gestureBaseScale * dist / _initialPointerDistance).clamp(
      0.05,
      2.0,
    );
    final newRotY =
        _gestureBaseRotY + (focal.dx - _initialFocalPoint.dx) * 0.01;

    final scaleDelta = (newScale - _currentScale).abs();
    final rotDelta = (newRotY - _currentRotationY).abs();
    if (scaleDelta < _currentScale * 0.01 && rotDelta < 0.5 * math.pi / 180) {
      return;
    }

    _currentScale = newScale;
    _currentRotationY = newRotY;
    if (scaleDelta >= _currentScale * 0.01) {
      _applyScale();
    } else {
      _applyTransform();
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    _pointers.remove(event.pointer);
    if (_pointers.length < 2) {
      _gestureBaseScale = _currentScale;
      _gestureBaseRotY = _currentRotationY;
    }
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    _pointers.remove(event.pointer);
    _gestureBaseScale = _currentScale;
    _gestureBaseRotY = _currentRotationY;
  }

  // ── In-place transform ────────────────────────────────────────────────────
  // Assigning ARNode.transform notifies the plugin's `transformationChanged`
  // channel, which updates the already-loaded model on the native side.
  // Removing and re-adding the node instead re-downloads the GLB, which made
  // the model vanish for 10–20s on every resize.

  void _applyTransform() {
    if (!mounted) return;
    _modelNode?.transform = _composeTransform();
  }

  void _applyScale() {
    _applyTransform();
    _platformNode?.transform = _composePlatformTransform();
  }

  void _rotateBy(double radians) {
    if (_state != _PlacementState.placed) return;
    _currentRotationY += radians;
    _gestureBaseRotY = _currentRotationY;
    _applyTransform();
  }

  void _startHoldRotate(double direction) {
    _holdRotateTimer?.cancel();
    // ~90°/s while held.
    _holdRotateTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      _rotateBy(direction * (math.pi / 2) * 0.016);
    });
  }

  void _stopHoldRotate() {
    _holdRotateTimer?.cancel();
    _holdRotateTimer = null;
  }

  // ── Node helpers ──────────────────────────────────────────────────────────

  // Roughly a third of the visible height at the tapped distance, clamped so
  // a very close or far surface still gives a sensible tabletop-sized model.
  double _sizeForDistance(double distance) {
    if (distance.isNaN || distance <= 0) return 0.3;
    return (distance * 0.35).clamp(0.15, 0.5);
  }

  ARNode _buildNode() {
    return ARNode(
      type: NodeType.webGLB,
      uri: widget.modelUrl,
      transformation: _composeTransform(),
      // Handled by the vendored plugin patch: rests the model's bounding-box
      // bottom on the anchor (i.e. on top of the platform) instead of its
      // authored origin, which is often the model's center.
      data: {'alignBottom': true},
    );
  }

  // Built from a real quaternion: the plugin's `rotation:` parameter is
  // axis-angle and a zero-length axis turns the whole matrix into NaN.
  vector.Matrix4 _composeTransform() {
    return vector.Matrix4.compose(
      vector.Vector3.zero(),
      vector.Quaternion.axisAngle(vector.Vector3(0, 1, 0), _currentRotationY),
      vector.Vector3.all(_currentScale),
    );
  }

  // The platform asset is 100 units across, which both platforms map to
  // `scale` meters (Android fits the largest dimension; iOS applies 0.01).
  ARNode _buildPlatformNode() {
    return ARNode(
      type: NodeType.localGLTF2,
      uri: _platformAsset,
      transformation: _composePlatformTransform(),
    );
  }

  vector.Matrix4 _composePlatformTransform() {
    return vector.Matrix4.compose(
      vector.Vector3.zero(),
      vector.Quaternion.identity(),
      vector.Vector3.all(_currentScale * _platformSizeRatio),
    );
  }
}

// ── Rotate button ─────────────────────────────────────────────────────────────
// Tap rotates by a fixed step; press and hold keeps rotating until released.

class _RotateButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final VoidCallback onHoldStart;
  final VoidCallback onHoldEnd;

  const _RotateButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.onHoldStart,
    required this.onHoldEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        onLongPressStart: (_) => onHoldStart(),
        onLongPressEnd: (_) => onHoldEnd(),
        onLongPressCancel: onHoldEnd,
        child: Material(
          color: Colors.orange,
          shape: const CircleBorder(),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
        ),
      ),
    );
  }
}

// ── Sound button ──────────────────────────────────────────────────────────────
// Reacts to just_audio's playerStateStream so icon updates are immediate and
// don't require any extra setState calls in the parent widget.

class _SoundButton extends StatelessWidget {
  final AudioPlayer player;
  final String soundUrl;

  const _SoundButton({required this.player, required this.soundUrl});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PlayerState>(
      stream: player.playerStateStream,
      builder: (context, snapshot) {
        final playerState = snapshot.data;
        final playing = playerState?.playing ?? false;
        final processingState =
            playerState?.processingState ?? ProcessingState.idle;

        final bool isLoading =
            processingState == ProcessingState.loading ||
            processingState == ProcessingState.buffering;

        final Widget icon;
        if (isLoading) {
          icon = const SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2.5,
            ),
          );
        } else if (playing) {
          icon = const Icon(Icons.stop_rounded, color: Colors.white, size: 30);
        } else {
          icon = const Icon(
            Icons.volume_up_rounded,
            color: Colors.white,
            size: 30,
          );
        }

        return ElevatedButton(
          onPressed: () async {
            try {
              if (playing) {
                await player.stop();
              } else {
                await MediaCache.setAudioUrl(player, soundUrl);
                await player.play();
              }
            } catch (_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Could not play audio. Check your connection.',
                    ),
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(18),
            elevation: 4,
          ),
          child: icon,
        );
      },
    );
  }
}

// ── Ripple painter ────────────────────────────────────────────────────────────
// Draws a single expanding circle at [center] with [radius] and [opacity].
// Used as a screen-space feedback overlay at the tap position.

class _RipplePainter extends CustomPainter {
  final Offset center;
  final double radius;
  final double opacity;

  const _RipplePainter({
    required this.center,
    required this.radius,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green.shade400.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_RipplePainter old) =>
      old.radius != radius || old.opacity != opacity || old.center != center;
}

// ── Pulsing tap indicator ─────────────────────────────────────────────────────

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

class _StatusBanner extends StatelessWidget {
  final _PlacementState state;

  const _StatusBanner({required this.state});

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Widget leading;
    final String message;

    switch (state) {
      case _PlacementState.placing:
        bg = Colors.orange.shade800.withValues(alpha: 0.92);
        leading = const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: Colors.white,
          ),
        );
        message = 'Placing model\u2026';
      case _PlacementState.ready:
        bg = Colors.green.shade700.withValues(alpha: 0.92);
        leading = const Icon(
          Icons.check_circle_outline,
          color: Colors.white,
          size: 20,
        );
        message = 'Flat surface found! Tap to place';
      case _PlacementState.scanning:
      case _PlacementState.placed:
        bg = Colors.black.withValues(alpha: 0.60);
        leading = const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: Colors.white,
          ),
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
