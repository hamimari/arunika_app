import 'package:arunika_app/core/utils/price_format.dart';

class SubscriptionInfo {
  final String planName;
  final String status;
  final DateTime? expiresAt;
  final int? daysLeft;
  // Renewal state, computed by the backend: 'midtrans' | 'google_play'.
  final String provider;
  final bool autoRenew;
  final DateTime? renewableFrom;
  // True only in the last days before expiry of a subscription that won't
  // renew by itself — the only time a subscriber may buy again.
  final bool canRenew;
  // Set for Google Play subscriptions: the SKU whose Play Store page
  // "Perpanjang" opens.
  final String? playProductId;

  const SubscriptionInfo({
    required this.planName,
    required this.status,
    this.expiresAt,
    this.daysLeft,
    this.provider = 'midtrans',
    this.autoRenew = false,
    this.renewableFrom,
    this.canRenew = false,
    this.playProductId,
  });

  bool get isGooglePlay => provider == 'google_play';

  factory SubscriptionInfo.fromJson(Map<String, dynamic> json) {
    return SubscriptionInfo(
      planName: json['plan_name'] as String,
      status: json['status'] as String,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      daysLeft: (json['days_left'] as num?)?.toInt(),
      provider: json['provider'] as String? ?? 'midtrans',
      autoRenew: json['auto_renew'] as bool? ?? false,
      renewableFrom: parseOptionalDate(json['renewable_from']),
      canRenew: json['can_renew'] as bool? ?? false,
      playProductId: json['play_product_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'plan_name': planName,
      'status': status,
      'expires_at': expiresAt?.toIso8601String(),
      'days_left': daysLeft,
      'provider': provider,
      'auto_renew': autoRenew,
      'renewable_from': renewableFrom?.toIso8601String(),
      'can_renew': canRenew,
      'play_product_id': playProductId,
    };
  }
}
