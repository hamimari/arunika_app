import 'package:flutter/material.dart';
import 'package:arunika_app/constants/app_colors.dart';
import 'package:arunika_app/constants/app_text_styles.dart';
import 'package:arunika_app/core/auth/auth_notifier.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:go_router/go_router.dart';

/// Guard for premium-locked features.
///
/// - If the user is not logged in: shows a dialog prompting login or register.
///   After successful auth, navigates to `/premium`.
/// - If the user is already logged in: navigates directly to `/premium`.
Future<void> guardPremium(BuildContext context) async {
  final auth = locator<AuthNotifier>();
  if (auth.isLoggedIn) {
    context.push('/premium');
    return;
  }

  await showDialog<void>(
    context: context,
    builder: (ctx) => _PremiumAuthGuardDialog(),
  );
}

class _PremiumAuthGuardDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: AppColors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primaryOrange.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('⭐', style: TextStyle(fontSize: 34)),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Akses Konten Premium',
              style: AppTextStyles.subheading,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Masuk atau daftar terlebih dahulu untuk mengakses fitur premium.',
              style: AppTextStyles.body.copyWith(color: AppColors.mediumBrown),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
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
                onPressed: () async {
                  Navigator.of(context).pop();
                  await context.push('/signin');
                  if (context.mounted && locator<AuthNotifier>().isLoggedIn) {
                    context.push('/premium');
                  }
                },
                child: Text('Login', style: AppTextStyles.button),
              ),
            ),
            const SizedBox(height: 10),
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
                onPressed: () async {
                  Navigator.of(context).pop();
                  await context.push('/signup');
                  if (context.mounted && locator<AuthNotifier>().isLoggedIn) {
                    context.push('/premium');
                  }
                },
                child: Text(
                  'Daftar Akun',
                  style: AppTextStyles.button.copyWith(
                    color: AppColors.primaryOrange,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
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
    );
  }
}
