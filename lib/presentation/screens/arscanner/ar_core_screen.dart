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
import 'package:arunika_app/presentation/screens/qrscanner/qr_scanner.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

class ArCoreSurfacePlaceScreen extends StatefulWidget {
  final String modelUrl;
  const ArCoreSurfacePlaceScreen({required this.modelUrl, super.key});

  @override
  State<ArCoreSurfacePlaceScreen> createState() =>
      _ArCoreSurfacePlaceScreenState();
}

class _ArCoreSurfacePlaceScreenState extends State<ArCoreSurfacePlaceScreen> {
  late ARSessionManager arSessionManager;
  late ARObjectManager arObjectManager;
  late ARAnchorManager arAnchorManager;

  List<ARNode> nodes = [];
  List<ARAnchor> anchors = [];

  double _currentScale = 0.5;
  double _currentRotationY = 0.0;

  bool _isUpdating = false;

  @override
  void dispose() {
    for (final anchor in anchors) {
      arAnchorManager.removeAnchor(anchor);
    }
    for (final node in nodes) {
      arObjectManager.removeNode(node);
    }
    arSessionManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GestureDetector(
            onScaleUpdate: _onScaleUpdate,
            child: ARView(
              onARViewCreated: onARViewCreated,
              planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
            ),
          ),

          /// ✅ Scan button only (center bottom)
          Positioned(
            bottom: 30,
            left: 24,
            right: 24,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => QRScannerPage()),
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

  void onARViewCreated(
      ARSessionManager sessionManager,
      ARObjectManager objectManager,
      ARAnchorManager anchorManager,
      ARLocationManager locationManager,
      ) async {
    arSessionManager = sessionManager;
    arObjectManager = objectManager;
    arAnchorManager = anchorManager;

    await arSessionManager.onInitialize(
      showPlanes: true,
      showFeaturePoints: false,
      showWorldOrigin: false,
      handleTaps: true,
    );
    await arObjectManager.onInitialize();
    arSessionManager.onPlaneOrPointTap = onPlaneOrPointTapped;

  }

  Future<void> onPlaneOrPointTapped(
      List<ARHitTestResult> hitTestResults,
      ) async {
    final hit = hitTestResults.firstWhere(
          (h) => h.type == ARHitTestResultType.plane,
    );

    if (anchors.isNotEmpty) {
      await arAnchorManager.removeAnchor(anchors.first);
      anchors.clear();
    }

    if (nodes.isNotEmpty) {
      await arObjectManager.removeNode(nodes.first);
      nodes.clear();
    }

    final anchor = ARPlaneAnchor(transformation: hit.worldTransform);
    final didAddAnchor = await arAnchorManager.addAnchor(anchor);

    if (didAddAnchor == true) {
      anchors.add(anchor);

      final node = ARNode(
        type: NodeType.webGLB,
        uri: widget.modelUrl,
        scale: vector.Vector3.all(_currentScale),
        position: vector.Vector3.zero(),
        rotation: quaternionFromY(_currentRotationY),
      );

      final didAddNode =
      await arObjectManager.addNode(node, planeAnchor: anchor);

      if (didAddNode == true) {
        nodes.add(node);
      }
    }
  }

  /// ===============================
  /// GESTURES
  /// ===============================

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (nodes.isEmpty || _isUpdating) return;

    // scale
    _currentScale *= details.scale;
    _currentScale = _currentScale.clamp(0.2, 2.5);

    // swipe rotate
    _currentRotationY += details.focalPointDelta.dx * 0.01;

    _throttledApply();
  }

  /// ===============================
  /// SAFE UPDATE (THROTTLED)
  /// ===============================
  void _throttledApply() async {
    _isUpdating = true;

    final oldNode = nodes.removeLast();
    final anchor = anchors.last as ARPlaneAnchor;

    await arObjectManager.removeNode(oldNode);

    final newNode = ARNode(
      type: NodeType.webGLB,
      uri: oldNode.uri,
      scale: vector.Vector3.all(_currentScale),
      position: vector.Vector3.zero(),
      rotation: quaternionFromY(_currentRotationY),
    );

    final didAdd =
    await arObjectManager.addNode(newNode, planeAnchor: anchor);

    if (didAdd == true) {
      nodes.add(newNode);
    }

    await Future.delayed(const Duration(milliseconds: 30)); // smooth throttle
    _isUpdating = false;
  }

  /// ===============================
  /// QUATERNION
  /// ===============================
  vector.Vector4 quaternionFromY(double angle) {
    final half = angle / 2;
    return vector.Vector4(
      0.0,
      math.sin(half),
      0.0,
      math.cos(half),
    );
  }
}
