import 'package:arunika_app/constants/app_colors.dart';
import 'package:arunika_app/constants/app_text_styles.dart';
import 'package:arunika_app/core/utils/price_format.dart';
import 'package:arunika_app/data/models/response/subscription_info.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const _androidPackageName = 'com.arunika';

/// Opens [sub]'s page in Google Play's subscription center, where a user who
/// cancelled auto-renew can resubscribe. Google keeps the current expiry and
/// bills the next period from it, so no paid days are lost.
Future<void> openPlaySubscription(SubscriptionInfo sub) {
  final sku = sub.playProductId;
  final uri = Uri.https('play.google.com', '/store/account/subscriptions', {
    if (sku != null && sku.isNotEmpty) 'sku': sku,
    'package': _androidPackageName,
  });
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}

/// Shown instead of packages, prices and "Bayar" to a user whose active
/// subscription already unlocks all paid content. A Google Play subscriber
/// inside the renewal window gets a button to resubscribe in Google Play.
class ActiveSubscriptionView extends StatelessWidget {
  /// Null when the backend reported an active subscription (409) but the
  /// profile hasn't loaded its details.
  final SubscriptionInfo? subscription;
  final VoidCallback onBack;

  const ActiveSubscriptionView({
    super.key,
    required this.subscription,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final sub = subscription;
    final expiresAt = sub?.expiresAt;
    final String? expiryLine = expiresAt == null
        ? null
        : sub!.autoRenew
        ? 'Diperpanjang otomatis pada ${formatLongDate(expiresAt)}'
        : 'Berlaku sampai ${formatLongDate(expiresAt)}';
    final showPlayRenew = sub != null && sub.canRenew && sub.isGooglePlay;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.successGreen.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: AppColors.successGreen,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Langganan aktif',
              style: AppTextStyles.subheading.copyWith(
                color: AppColors.deepBrown,
              ),
            ),
            const SizedBox(height: 6),
            if (sub != null)
              Text(
                sub.planName,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.primaryOrange,
                  fontWeight: FontWeight.w700,
                ),
              ),
            if (expiryLine != null) ...[
              const SizedBox(height: 4),
              Text(
                expiryLine,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.mediumBrown,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 12),
            Text(
              'Semua kartu AR dan dongeng sudah terbuka untukmu. '
              'Tidak ada yang perlu dibayar.',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.mediumBrown,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            if (showPlayRenew) ...[
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => openPlaySubscription(sub),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Perpanjang di Google Play',
                    style: AppTextStyles.button,
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: onBack,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                    color: AppColors.primaryOrange,
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Kembali',
                  style: AppTextStyles.button.copyWith(
                    color: AppColors.primaryOrange,
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
