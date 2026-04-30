class CountingQuestion {
  final String id;
  final String level;
  final Map<String, dynamic> questionJson;
  final int answer;

  const CountingQuestion({
    required this.id,
    required this.level,
    required this.questionJson,
    required this.answer,
  });

  factory CountingQuestion.fromJson(Map<String, dynamic> json) =>
      CountingQuestion(
        id: json['id'] as String,
        level: json['level'] as String,
        questionJson: json['question_json'] as Map<String, dynamic>? ?? {},
        answer: (json['answer'] as num).toInt(),
      );

  static List<CountingQuestion> fromJsonList(List<dynamic> list) => list
      .map((e) => CountingQuestion.fromJson(e as Map<String, dynamic>))
      .toList();
}
