import 'package:arunika_app/data/api/animal_api.dart';
import 'package:arunika_app/data/models/response/animal_response.dart';

class AnimalRepository {
  final AnimalApi api;

  AnimalRepository(this.api);

  Future<List<AnimalResponse>> findAll({String category = ''}) async {
    final list = await api.findAll(category: category);
    return AnimalResponse.fromJsonList(list);
  }
}
