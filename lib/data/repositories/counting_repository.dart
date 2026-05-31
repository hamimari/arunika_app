import 'package:arunika_app/data/api/counting_api.dart';
import 'package:arunika_app/data/models/response/counting_question.dart';

class CountingRepository {
  final CountingApi api;
  CountingRepository(this.api);

  Future<List<CountingQuestion>> getQuestions({String? level}) async {
    final json = await api.getQuestions(level: level);
    return CountingQuestion.fromJsonList(json['data'] as List<dynamic>);
  }

  Future<void> saveProgress({
    required String childId,
    required String questionId,
    required bool isCorrect,
  }) async {
    await api.saveProgress({
      'child_id': childId,
      'question_id': questionId,
      'is_correct': isCorrect,
    });
  }
}
