import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Shows a premium upsell dialog. Call [PremiumDialog.show] from any tap handler.
class PremiumDialog {
  PremiumDialog._();

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => const _PremiumDialogContent(),
    );
  }
}

class _PremiumDialogContent extends StatelessWidget {
  const _PremiumDialogContent();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                size: 48,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Konten Premium',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6D4C41),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Konten ini hanya tersedia untuk pengguna premium. Upgrade sekarang untuk mengakses semua fitur!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF8D6E63)),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.push('/payment');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Upgrade Premium',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Nanti saja',
                  style: TextStyle(color: Color(0xFF8D6E63)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
