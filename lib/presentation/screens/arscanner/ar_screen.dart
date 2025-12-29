import 'package:ar_flutter_plugin_2/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin_2/datatypes/node_types.dart';
import 'package:ar_flutter_plugin_2/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_session_manager.dart';
import 'package:flutter/material.dart';
import 'package:ar_flutter_plugin_2/models/ar_node.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

class ARQRCombinedScreen extends StatefulWidget {
  @override
  _ARQRCombinedScreenState createState() => _ARQRCombinedScreenState();
}

class _ARQRCombinedScreenState extends State<ARQRCombinedScreen> {
  late ARSessionManager arSessionManager;
  late ARObjectManager arObjectManager;
  QRViewController? qrController;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  bool scanned = false;

  @override
  void dispose() {
    qrController?.dispose();
    arSessionManager.dispose();
    super.dispose();
  }

  void onQRViewCreated(QRViewController controller) {
    qrController = controller;
    controller.scannedDataStream.listen((scanData) async {
      if (scanned) return;
      scanned = true;

      String modelUrl = scanData.code ?? "";

      final node = ARNode(
        type: NodeType.webGLB,
        uri: modelUrl,
        scale: vector.Vector3(0.2, 0.2, 0.2),
        position: vector.Vector3(0, 0, -1.0),
        rotation: vector.Vector4(1, 0, 0, 0),
      );

      await arObjectManager.addNode(node);

      // Optionally hide QR overlay
      setState(() {});
    });
  }

  void onARViewCreated(
      ARSessionManager sessionManager,
      ARObjectManager objectManager,
      ARAnchorManager anchorManager,
      ARLocationManager locationManager) async {
    arSessionManager = sessionManager;
    arObjectManager = objectManager;

    await arSessionManager.onInitialize(
      showAnimatedGuide: false, // 👈 hides the hand guide
      showFeaturePoints: false,
      showPlanes: true,
      handleTaps: false,
    );
    await arObjectManager.onInitialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          ARView(onARViewCreated: onARViewCreated),
          if (!scanned)
            Positioned(
              top: 50,
              right: 20,
              width: 200,
              height: 200,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white),
                ),
                child: QRView(
                  key: qrKey,
                  overlay: QrScannerOverlayShape(
                    borderColor: Colors.white,
                    borderRadius: 10,
                    borderLength: 30,
                    borderWidth: 10,
                    cutOutSize: 200,
                  ),
                  onQRViewCreated: onQRViewCreated,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
