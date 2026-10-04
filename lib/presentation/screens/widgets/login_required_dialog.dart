import 'package:flutter/material.dart';
import 'package:arunika_app/constants/app_colors.dart';
import 'package:arunika_app/constants/app_text_styles.dart';
import 'package:go_router/go_router.dart';

/// Show a dialog prompting the user to sign in before accessing a gated feature.
/// [featureLabel] is a short description shown in the message, e.g. "koleksi hewan".
Future<void> showLoginRequiredDialog(
  BuildContext context, {
  String featureLabel = 'fitur ini',
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: AppColors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primaryOrange.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🔒', style: TextStyle(fontSize: 34)),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              'Masuk Dulu, Yuk!',
              style: AppTextStyles.subheading,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),

            // Body
            Text(
              'Untuk mengakses $featureLabel, kamu perlu masuk atau daftar terlebih dahulu.',
              style: AppTextStyles.body.copyWith(color: AppColors.mediumBrown),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),

            // Sign in button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  ctx.push('/signin');
                },
                child: Text('Masuk', style: AppTextStyles.button),
              ),
            ),
            const SizedBox(height: 10),

            // Register button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                    color: AppColors.primaryOrange,
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  ctx.push('/signup');
                },
                child: Text(
                  'Daftar Gratis',
                  style: AppTextStyles.button.copyWith(
                    color: AppColors.primaryOrange,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Cancel
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Nanti Saja',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.mediumBrown,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
