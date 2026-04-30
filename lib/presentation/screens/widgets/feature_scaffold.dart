import 'package:arunika_app/data/repositories/ar_repository.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:arunika_app/presentation/screens/qrscanner/qr_scanner.dart';
import 'package:arunika_app/presentation/screens/qrscanner/qr_scanner_bloc.dart';
import 'package:arunika_app/presentation/screens/widgets/bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

/// Shared scaffold used by all main feature screens.
/// Provides the orange gradient header, consistent bottom nav and FAB.
class FeatureScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final int navIndex;
  final List<Widget>? headerActions;
  final Widget? tabBar; // optional tab bar rendered below the title

  const FeatureScaffold({
    super.key,
    required this.title,
    required this.body,
    this.navIndex = 0,
    this.headerActions,
    this.tabBar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF5),
      bottomNavigationBar: BottomNav(currentIndex: navIndex),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton(
          elevation: 0,
          backgroundColor: Colors.orange,
          onPressed: () {
            Navigator.push(
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
          child: const Icon(Iconsax.scan, size: 28),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      body: SafeArea(
        child: Column(
          children: [
            // ── Gradient header ──────────────────────────────────────────
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFF4E6), Color(0xFFFFE0B2)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: tabBar == null
                    ? const BorderRadius.only(
                        bottomLeft: Radius.circular(28),
                        bottomRight: Radius.circular(28),
                      )
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 12, 16),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              color: Color(0xFF6D4C41),
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6D4C41),
                            ),
                          ),
                        ),
                        if (headerActions != null) ...headerActions!,
                      ],
                    ),
                  ),
                  if (tabBar != null) tabBar!,
                ],
              ),
            ),
            if (tabBar != null)
              Container(
                height: 4,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFFE0B2), Color(0xFFFFFBF5)],
                  ),
                ),
              ),

            // ── Body ────────────────────────────────────────────────────
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}
