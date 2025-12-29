import 'dart:async';

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
import 'package:arunika_app/presentation/screens/arscanner/debug_logger.dart';
import 'package:arunika_app/presentation/screens/arscanner/qr_scanner.dart';
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
  ARNode? currentNode;
  bool isPlaneDetected = false;
  List<ARNode> nodes = [];
  List<ARAnchor> anchors = [];

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
          ARView(
            onARViewCreated: onARViewCreated,
            planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
          ),
          Align(
            alignment: FractionalOffset.bottomCenter,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => rotateObjectY(30), // Rotate 30 degrees
                  child: Text("Rotate Object"),
                ),
              ],
            ),
          ),

          // Instruction overlay
          // if (!isPlaneDetected)
          //   Positioned.fill(
          //     child: Container(
          //       color: Colors.black.withOpacity(0.5),
          //       child: Center(
          //         child: Column(
          //           mainAxisSize: MainAxisSize.min,
          //           children: [
          //             CircularProgressIndicator(
          //               color: Colors.white,
          //             ),
          //             const SizedBox(height: 16),
          //             const Text(
          //               "Scanning environment...\nPoint your camera at a flat surface",
          //               textAlign: TextAlign.center,
          //               style: TextStyle(color: Colors.white, fontSize: 16),
          //             ),
          //           ],
          //         ),
          //       ),
          //     ),
          //   ),
          Positioned(
            top: 40,
            right: 20,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black.withOpacity(0.7),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final log = await DebugLogger.readLog();
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text("Debug Log"),
                    content: SingleChildScrollView(child: Text(log)),
                    actions: [
                      TextButton(
                        onPressed: () async {
                          await DebugLogger.clearLog();
                          Navigator.pop(context);
                        },
                        child: Text("Clear"),
                      ),
                    ],
                  ),
                );
              },
              child: Text("Logs"),
            ),
          ),

          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => QRScannerPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.orange,
                ),
                child: const Text("Scan Again"),
              ),
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
      showFeaturePoints: true,
      showWorldOrigin: false,
      handleTaps: true,
      handlePans: true,
      handleRotation: true
    );
    await arObjectManager.onInitialize();
    arSessionManager.onPlaneOrPointTap = onPlaneOrPointTapped;

  }

  Future<void> onPlaneOrPointTapped(
    List<ARHitTestResult> hitTestResults,
  ) async {
    var singleHitTestResult = hitTestResults.firstWhere(
      (hitTestResult) => hitTestResult.type == ARHitTestResultType.plane,
    );

    if (anchors.isNotEmpty) {
      await arAnchorManager.removeAnchor(anchors.first);
      anchors.clear();
    }

    if (nodes.isNotEmpty) {
      await arObjectManager.removeNode(nodes.first);
      nodes.clear();
    }

    var newAnchor = ARPlaneAnchor(
      transformation: singleHitTestResult.worldTransform,
    );
    bool? didAddAnchor = await arAnchorManager.addAnchor(newAnchor);
    if (didAddAnchor!) {
      anchors.add(newAnchor);
      // Add note to anchor
      var newNode = ARNode(
        type: NodeType.webGLB,
        uri: widget.modelUrl,
        scale: vector.Vector3(0.5, 0.5, 0.5),
        position: vector.Vector3(0.0, 0.0, 0.0),
        rotation: vector.Vector4(1.0, 0.0, 0.0, 0.0),
      );
      bool? didAddNodeToAnchor = await arObjectManager.addNode(
        newNode,
        planeAnchor: newAnchor,
      );
      if (didAddNodeToAnchor!) {
        this.nodes.add(newNode);
      } else {
        DebugLogger.log("Adding Node to Anchor failed");
        AlertDialog(
          title: Text("Error"),
          content: Text("Adding Node to Anchor failed"),
        );
      }
    } else {
      DebugLogger.log("Adding Anchor failed");
      AlertDialog(title: Text("Error"), content: Text("Adding Anchor failed"));
    }
  }

  Future<void> rotateObjectY(double angleDegrees) async {
    if (nodes.isEmpty || anchors.isEmpty) return;

    final oldNode = nodes.removeLast();
    await arObjectManager.removeNode(oldNode);

    final anchor = anchors.last as ARPlaneAnchor;
    final newNode = ARNode(
      type: NodeType.webGLB,
      uri: oldNode.uri,
      position: vector.Vector3(0.0, 0.0, 0.0),
      rotation: vector.Vector4(0.0, 1.0, 0.0, vector.radians(angleDegrees)),
      scale: oldNode.scale,
    );

    final didAdd = await arObjectManager.addNode(newNode, planeAnchor: anchor);
    if (didAdd == true) {
      nodes.add(newNode);
    }
  }
}
