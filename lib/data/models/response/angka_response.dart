import 'package:arunika_app/core/angka/question_generator.dart';
import 'package:arunika_app/data/models/response/huruf_response.dart';
import 'package:equatable/equatable.dart';

int _int(Object? v, [int fallback = 0]) => (v as num?)?.toInt() ?? fallback;

/// A Kenal Angka tile (`GET /learn/angka/manifest`).
class AngkaManifestNumber extends Equatable {
  final int value;
  final String name;
  final bool isFree;
  final bool locked;

  const AngkaManifestNumber({
    required this.value,
    this.name = '',
    this.isFree = false,
    this.locked = false,
  });

  factory AngkaManifestNumber.fromJson(Map<String, dynamic> json) =>
      AngkaManifestNumber(
        value: _int(json['value']),
        name: json['name'] as String? ?? '',
        isFree: json['is_free'] as bool? ?? false,
        locked: json['locked'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [value, name, isFree, locked];
}

/// A Hitung Benda level card. [prerequisiteId] is only set when the
/// prerequisite is itself visible (a hidden one counts as met).
class AngkaManifestLevel extends Equatable {
  final String id;
  final String name;
  final int min;
  final int max;
  final int questionCount;
  final String? prerequisiteId;
  final bool isFree;
  final bool locked;
  final int version;

  const AngkaManifestLevel({
    required this.id,
    required this.name,
    this.min = 1,
    this.max = 5,
    this.questionCount = 10,
    this.prerequisiteId,
    this.isFree = false,
    this.locked = false,
    this.version = 1,
  });

  factory AngkaManifestLevel.fromJson(Map<String, dynamic> json) {
    final range = json['range'] as Map<String, dynamic>? ?? const {};
    return AngkaManifestLevel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      min: _int(range['min'], 1),
      max: _int(range['max'], 1),
      questionCount: _int(json['question_count'], 10),
      prerequisiteId: json['prerequisite_id'] as String?,
      isFree: json['is_free'] as bool? ?? false,
      locked: json['locked'] as bool? ?? false,
      version: _int(json['version'], 1),
    );
  }

  /// "1–10", the range badge.
  String get rangeLabel => '$min–$max';

  @override
  List<Object?> get props => [
    id,
    name,
    min,
    max,
    questionCount,
    prerequisiteId,
    isFree,
    locked,
    version,
  ];
}

class AngkaManifest extends Equatable {
  final bool premium;
  final List<AngkaManifestNumber> numbers;
  final List<AngkaManifestLevel> levels;

  const AngkaManifest({
    required this.premium,
    this.numbers = const [],
    this.levels = const [],
  });

  factory AngkaManifest.fromJson(Map<String, dynamic> json) => AngkaManifest(
    premium: json['premium'] as bool? ?? false,
    numbers: [
      for (final n in (json['numbers'] as List? ?? const []))
        AngkaManifestNumber.fromJson(n as Map<String, dynamic>),
    ],
    levels: [
      for (final l in (json['levels'] as List? ?? const []))
        AngkaManifestLevel.fromJson(l as Map<String, dynamic>),
    ],
  );

  @override
  List<Object?> get props => [premium, numbers, levels];
}

/// A library object ("apel") with its media resolved.
class AngkaObject extends Equatable {
  final String id;
  final String name;
  final String questionText;
  final String imageUrl;
  final String questionAudioUrl;

  const AngkaObject({
    required this.id,
    required this.name,
    this.questionText = '',
    this.imageUrl = '',
    this.questionAudioUrl = '',
  });

  factory AngkaObject.fromJson(Map<String, dynamic> json) => AngkaObject(
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    questionText: json['question_text'] as String? ?? '',
    imageUrl: resolveMediaUrl(json['image_url']),
    questionAudioUrl: resolveMediaUrl(json['question_audio_url']),
  );

  @override
  List<Object?> get props => [id, name, questionText, imageUrl];
}

/// The published audio of each number, for counting aloud.
Map<int, String> _countAudio(Object? json) => {
  for (final e in (json as Map<String, dynamic>? ?? const {}).entries)
    int.parse(e.key): resolveMediaUrl(e.value),
};

/// A Kenal Angka card (`GET /learn/angka/numbers/:value`).
class AngkaNumberCard extends Equatable {
  final int value;
  final String name;
  final String audioUrl;
  final AngkaObject? object;
  final Map<int, String> countAudio;

  const AngkaNumberCard({
    required this.value,
    required this.name,
    this.audioUrl = '',
    this.object,
    this.countAudio = const {},
  });

  factory AngkaNumberCard.fromJson(Map<String, dynamic> json) =>
      AngkaNumberCard(
        value: _int(json['value']),
        name: json['name'] as String? ?? '',
        audioUrl: resolveMediaUrl(json['audio_url']),
        object: json['object'] == null
            ? null
            : AngkaObject.fromJson(json['object'] as Map<String, dynamic>),
        countAudio: _countAudio(json['count_audio']),
      );

  @override
  List<Object?> get props => [value, name, audioUrl, object, countAudio];
}

/// A level version's settings, as a session plays them.
class AngkaLevelContent extends Equatable {
  final String name;
  final int min;
  final int max;
  final int questionCount;
  final String layout;
  final int threeStars;
  final int twoStars;
  final String successTitle;
  final String retryTitle;
  final String hint;

  const AngkaLevelContent({
    required this.name,
    this.min = 1,
    this.max = 5,
    this.questionCount = 10,
    this.layout = AngkaGenerator.layoutScatter,
    this.threeStars = 9,
    this.twoStars = 7,
    this.successTitle = 'Hebat! Benar!',
    this.retryTitle = 'Hampir benar!',
    this.hint = '',
  });

  factory AngkaLevelContent.fromJson(Map<String, dynamic> json) {
    final range = json['range'] as Map<String, dynamic>? ?? const {};
    final stars = json['stars'] as Map<String, dynamic>? ?? const {};
    final feedback = json['feedback'] as Map<String, dynamic>? ?? const {};
    return AngkaLevelContent(
      name: json['name'] as String? ?? '',
      min: _int(range['min'], 1),
      max: _int(range['max'], 1),
      questionCount: _int(json['question_count'], 10),
      layout: json['layout'] as String? ?? AngkaGenerator.layoutScatter,
      threeStars: _int(stars['three'], 9),
      twoStars: _int(stars['two'], 7),
      successTitle: feedback['success'] as String? ?? '',
      retryTitle: feedback['retry'] as String? ?? '',
      hint: feedback['hint'] as String? ?? '',
    );
  }

  /// Stars for [firstCorrect] first-try correct answers (provisional until
  /// the server's complete answers).
  int starsFor(int firstCorrect) {
    if (firstCorrect >= threeStars) return 3;
    if (firstCorrect >= twoStars) return 2;
    return 1;
  }

  @override
  List<Object?> get props => [
    name,
    min,
    max,
    questionCount,
    layout,
    threeStars,
    twoStars,
    successTitle,
    retryTitle,
    hint,
  ];
}

/// Every try on one question (1-based [q]).
class AngkaAnswer extends Equatable {
  final int q;
  final List<int> tries;

  const AngkaAnswer(this.q, this.tries);

  factory AngkaAnswer.fromJson(Map<String, dynamic> json) => AngkaAnswer(
    _int(json['q']),
    [for (final t in (json['tries'] as List? ?? const [])) _int(t)],
  );

  @override
  List<Object?> get props => [q, tries];
}

/// A started or resumed session, pinned to the version it began on
/// (`POST /children/:childId/angka/sessions`).
class AngkaSession extends Equatable {
  final String id;
  final String levelId;
  final int levelVersion;
  final int seed;
  final List<String> objectIds;
  final List<AngkaAnswer> answers;
  final AngkaLevelContent content;
  final Map<String, AngkaObject> objects;
  final Map<int, String> countAudio;

  const AngkaSession({
    required this.id,
    required this.levelId,
    required this.levelVersion,
    required this.seed,
    required this.objectIds,
    required this.content,
    this.answers = const [],
    this.objects = const {},
    this.countAudio = const {},
  });

  factory AngkaSession.fromJson(Map<String, dynamic> json) => AngkaSession(
    id: json['session_id'] as String,
    levelId: json['level_id'] as String,
    levelVersion: _int(json['level_version'], 1),
    seed: _int(json['seed']),
    objectIds: [
      for (final o in (json['object_ids'] as List? ?? const [])) '$o',
    ],
    answers: [
      for (final a in (json['answers'] as List? ?? const []))
        AngkaAnswer.fromJson(a as Map<String, dynamic>),
    ],
    content: AngkaLevelContent.fromJson(
      json['content'] as Map<String, dynamic>? ?? const {},
    ),
    objects: {
      for (final o in (json['objects'] as List? ?? const []))
        (o as Map<String, dynamic>)['id'] as String: AngkaObject.fromJson(o),
    },
    countAudio: _countAudio(json['count_audio']),
  );

  /// The session's questions, regenerated exactly as the server does.
  List<AngkaQuestion> questions() => AngkaGenerator.generate(
    min: content.min,
    max: content.max,
    count: content.questionCount,
    objectIds: objectIds,
    layout: content.layout,
    seed: seed,
  );

  @override
  List<Object?> get props => [id, levelVersion, seed, answers];
}

/// The server's scoring of a finished session.
class AngkaCompleteResult extends Equatable {
  final int stars;
  final int firstCorrect;
  final int bestStars;
  final List<String> unlockedLevelIds;

  const AngkaCompleteResult({
    required this.stars,
    required this.firstCorrect,
    required this.bestStars,
    this.unlockedLevelIds = const [],
  });

  factory AngkaCompleteResult.fromJson(Map<String, dynamic> json) =>
      AngkaCompleteResult(
        stars: _int(json['stars'], 1),
        firstCorrect: _int(json['first_correct']),
        bestStars: _int(json['best_stars']),
        unlockedLevelIds: [
          for (final id in (json['unlocked_level_ids'] as List? ?? const []))
            '$id',
        ],
      );

  @override
  List<Object?> get props => [stars, firstCorrect, bestStars, unlockedLevelIds];
}

/// One level's progress (`GET /children/:childId/angka/progress`).
class AngkaLevelProgress extends Equatable {
  final String levelId;
  final int bestStars;
  final bool completed;

  /// The in-progress session: its id, answered and total questions.
  final String? sessionId;
  final int answered;
  final int questionCount;
  final DateTime? updatedAt;

  const AngkaLevelProgress({
    required this.levelId,
    this.bestStars = 0,
    this.completed = false,
    this.sessionId,
    this.answered = 0,
    this.questionCount = 0,
    this.updatedAt,
  });

  factory AngkaLevelProgress.fromJson(Map<String, dynamic> json) {
    final cur = json['current_session'] as Map<String, dynamic>?;
    return AngkaLevelProgress(
      levelId: json['level_id'] as String,
      bestStars: _int(json['best_stars']),
      completed: json['completed'] as bool? ?? false,
      sessionId: cur?['id'] as String?,
      answered: _int(cur?['answered']),
      questionCount: _int(cur?['question_count']),
      updatedAt: DateTime.tryParse(cur?['updated_at'] as String? ?? ''),
    );
  }

  bool get inProgress => sessionId != null;

  @override
  List<Object?> get props => [
    levelId,
    bestStars,
    completed,
    sessionId,
    answered,
    questionCount,
    updatedAt,
  ];
}
