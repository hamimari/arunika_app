import 'package:arunika_app/data/api/fairy_tales_api.dart';
import 'package:arunika_app/data/models/response/dongeng_response.dart';

class FairyTalesRepository {
  final FairyTalesApi api;

  FairyTalesRepository(this.api);

  Future<List<DongengResponse>> findAll() async {
    final json = await api.findAll();
    return DongengResponse.fromJsonList(json["data"]);
  }

}