import 'package:arunika_app/constants/app_colors.dart';
import 'package:arunika_app/constants/app_text_styles.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:arunika_app/data/repositories/ar_repository.dart';
import 'package:arunika_app/presentation/screens/arscanner/ar_core_screen.dart';
import 'package:arunika_app/presentation/screens/qrscanner/qr_scanner_bloc.dart';
import 'package:arunika_app/presentation/screens/qrscanner/qr_scanner_event.dart';
import 'package:arunika_app/presentation/screens/qrscanner/qr_scanner_state.dart';
import 'package:arunika_app/presentation/screens/widgets/login_required_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

/// The scan tab in the main shell.
/// Shows the camera with a QR overlay. Once a QR code is detected, shows a
/// confirmation card. On confirm, fetches the AR model and launches the AR view.
class ArScanShell extends StatelessWidget {
  const ArScanShell({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => QRScannerBloc(repository: locator<ArRepository>()),
      child: const _ArScanView(),
    );
  }
}

class _ArScanView extends StatefulWidget {
  const _ArScanView();

  @override
  State<_ArScanView> createState() => _ArScanViewState();
}

class _ArScanViewState extends State<_ArScanView> with WidgetsBindingObserver {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool scanned = false;
  bool _qrDetected = false;
  String _detectedCode = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (controller == null) return;
    if (state == AppLifecycleState.paused) {
      controller!.pauseCamera();
    } else if (state == AppLifecycleState.resumed) {
      controller!.resumeCamera();
    }
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (scanned) return;
      final id = scanData.code ?? '';
      if (id.isEmpty) return;
      setState(() {
        _qrDetected = true;
        _detectedCode = id;
      });
      scanned = true;
      controller.pauseCamera();
    });
  }

  void _confirmScan() {
    if (_detectedCode.isEmpty) return;
    context.read<QRScannerBloc>().add(FetchModelById(_detectedCode));
  }

  void _resetScanner() {
    setState(() {
      scanned = false;
      _qrDetected = false;
      _detectedCode = '';
    });
    controller?.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocListener<QRScannerBloc, QRScannerState>(
        listener: (context, state) {
          if (state is ModelLoaded) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ArCoreSurfacePlaceScreen(
                  modelUrl: state.modelUrl,
                  soundUrl: state.soundUrl,
                ),
              ),
            ).then((_) => _resetScanner());
          }
          if (state is ModelError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red.shade700,
              ),
            );
            _resetScanner();
          }
          if (state is ModelUnauthorized) {
            _resetScanner();
            showLoginRequiredDialog(context, featureLabel: 'fitur AR');
          }
        },
        child: Stack(
          children: [
            // Camera + QR overlay
            QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
              overlay: QrScannerOverlayShape(
                borderColor: AppColors.primaryOrange,
                borderRadius: 16,
                borderWidth: 4,
                cutOutSize: 260,
                overlayColor: Colors.black.withValues(alpha: 0.65),
              ),
            ),

            // Top instruction card
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('📷', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 10),
                          Text(
                            'Scan Kartu AR',
                            style: AppTextStyles.subheading.copyWith(
                              color: AppColors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Arahkan kamera ke QR kartu hewan',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),

            // Loading overlay
            BlocBuilder<QRScannerBloc, QRScannerState>(
              builder: (context, state) {
                if (state is ModelLoading) {
                  return Container(
                    color: Colors.black.withValues(alpha: 0.6),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(
                              color: AppColors.primaryOrange,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Memuat model AR...',
                              style: AppTextStyles.body,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            // Bottom confirmation card — shown after QR detected
            if (_qrDetected)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 20,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.lockGrey,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.categoryGreenBg,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Center(
                                  child: Text(
                                    '✅',
                                    style: TextStyle(fontSize: 22),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Kartu Terdeteksi!',
                                      style: AppTextStyles.bodyLarge.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      'Siap untuk lihat hewan AR-mu?',
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.textMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: _resetScanner,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.pageBackground,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Scan Ulang',
                                        style: AppTextStyles.buttonSmall
                                            .copyWith(
                                              color: AppColors.textDark,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: GestureDetector(
                                  onTap: _confirmScan,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryOrange,
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primaryOrange
                                              .withValues(alpha: 0.4),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // const Text(
                                          //   '🦌',
                                          //   style: TextStyle(fontSize: 16),
                                          // ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Lihat AR',
                                            style: AppTextStyles.buttonSmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
