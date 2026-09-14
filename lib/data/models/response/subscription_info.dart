class SubscriptionInfo {
  final String planName;
  final String status;
  final DateTime? expiresAt;
  final int? daysLeft;

  const SubscriptionInfo({
    required this.planName,
    required this.status,
    this.expiresAt,
    this.daysLeft,
  });

  factory SubscriptionInfo.fromJson(Map<String, dynamic> json) {
    return SubscriptionInfo(
      planName: json['plan_name'] as String,
      status: json['status'] as String,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      daysLeft: (json['days_left'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'plan_name': planName,
      'status': status,
      'expires_at': expiresAt?.toIso8601String(),
      'days_left': daysLeft,
    };
  }
}
