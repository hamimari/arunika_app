import 'package:arunika_app/data/api/ar_api.dart';
import 'package:arunika_app/data/models/response/ar_card_response.dart';

class ArRepository {
  final ArApi api;

  ArRepository(this.api);

  Future<ArCardResponse> findById(String userId) async {
    final json = await api.getById(userId);
    return ArCardResponse.fromJson(json);
  }
}
