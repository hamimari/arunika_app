import 'package:arunika_app/presentation/screens/arscanner/ar_core_screen.dart';
import 'package:arunika_app/presentation/screens/qrscanner/qr_scanner_bloc.dart';
import 'package:arunika_app/presentation/screens/qrscanner/qr_scanner_event.dart';
import 'package:arunika_app/presentation/screens/qrscanner/qr_scanner_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

class QRScannerPage extends StatefulWidget {
  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool scanned = false;

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;

    controller.scannedDataStream.listen((scanData) {
      if (scanned) return;

      scanned = true;
      controller.pauseCamera();

      final id = scanData.code ?? '';

      if (id.isEmpty) {
        _resetScanner();
        return;
      }

      context.read<QRScannerBloc>().add(FetchModelById(id));
    });
  }

  void _resetScanner() {
    scanned = false;
    controller?.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<QRScannerBloc, QRScannerState>(
        listener: (context, state) {
          if (state is ModelLoaded) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => ArCoreSurfacePlaceScreen(
                  modelUrl: state.modelUrl,
                  soundUrl: state.soundUrl,
                ),
              ),
            );
          }

          if (state is ModelError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
            _resetScanner();
          }
        },
        child: Stack(
          children: [
            QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
              overlay: QrScannerOverlayShape(
                borderColor: Colors.orange,
                cutOutSize: 250,
              ),
            ),
            BlocBuilder<QRScannerBloc, QRScannerState>(
              builder: (context, state) {
                if (state is ModelLoading) {
                  return Container(
                    color: Colors.black45,
                    child: const Center(child: CircularProgressIndicator()),
                  );
                }
                return const SizedBox();
              },
            ),
          ],
        ),
      ),
    );
  }
}
