import 'package:arunika_app/data/api/badge_api.dart';
import 'package:arunika_app/data/models/response/badge_item.dart';

class BadgeRepository {
  final BadgeApi api;
  BadgeRepository(this.api);

  Future<List<BadgeItem>> getBadges() async {
    final json = await api.getBadges();
    return BadgeItem.fromJsonList(json['data'] as List<dynamic>);
  }
}
