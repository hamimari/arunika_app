import 'package:arunika_app/data/api/banner_api.dart';
import 'package:arunika_app/data/models/response/banner_item.dart';

class BannerRepository {
  final BannerApi api;

  BannerRepository(this.api);

  Future<List<BannerItem>> getActiveBanners() async {
    try {
      final list = await api.getActiveBanners();
      return BannerItem.fromJsonList(list);
    } catch (_) {
      return [];
    }
  }
}
