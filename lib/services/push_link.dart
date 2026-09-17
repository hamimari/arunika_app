/// Where a tapped push notification should take the user, parsed from the
/// FCM data payload sent by backoffice campaigns
/// (`{"link_type": "dongeng", "link_id": "<uuid>"}`).
enum PushLinkType { none, arCard, dongeng }

class PushLink {
  final PushLinkType type;
  final String id;

  const PushLink(this.type, this.id);

  static const none = PushLink(PushLinkType.none, '');

  factory PushLink.fromData(Map<String, dynamic> data) {
    final id = (data['link_id'] as String? ?? '').trim();
    if (id.isEmpty) return none;
    switch (data['link_type']) {
      case 'ar_card':
        return PushLink(PushLinkType.arCard, id);
      case 'dongeng':
        return PushLink(PushLinkType.dongeng, id);
      default:
        return none;
    }
  }

  bool get isNone => type == PushLinkType.none;
}
