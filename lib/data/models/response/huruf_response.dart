import 'package:arunika_app/config/app_config.dart';
import 'package:arunika_app/core/tracing/stroke_evaluator.dart';
import 'package:equatable/equatable.dart';

/// Resolves a media URL against the API base URL. A development backend
/// returns relative `/media/...` paths, which the device must load from the
/// same host it calls the API on; absolute URLs pass through.
String resolveMediaUrl(Object? url, {String base = AppConfig.apiBaseUrl}) {
  final s = url as String? ?? '';
  if (s.isEmpty || Uri.parse(s).hasScheme) return s;
  return Uri.parse(base).resolve(s).toString();
}

/// One tile of the Belajar Huruf grid (`GET /learn/huruf/manifest`).
class HurufManifestLetter extends Equatable {
  final String id;
  final String upper;
  final String lower;
  final String word;
  final String imageUrl;
  final bool isFree;
  final bool locked;
  final int version;

  const HurufManifestLetter({
    required this.id,
    required this.upper,
    required this.lower,
    this.word = '',
    this.imageUrl = '',
    this.isFree = false,
    this.locked = false,
    this.version = 1,
  });

  factory HurufManifestLetter.fromJson(Map<String, dynamic> json) =>
      HurufManifestLetter(
        id: json['id'] as String,
        upper: json['upper'] as String,
        lower:
            json['lower'] as String? ?? (json['upper'] as String).toLowerCase(),
        word: json['word'] as String? ?? '',
        imageUrl: resolveMediaUrl(json['image_url']),
        isFree: json['is_free'] as bool? ?? false,
        locked: json['locked'] as bool? ?? false,
        version: (json['version'] as num?)?.toInt() ?? 1,
      );

  @override
  List<Object?> get props => [
    id,
    upper,
    word,
    imageUrl,
    isFree,
    locked,
    version,
  ];
}

class HurufManifest extends Equatable {
  final bool premium;
  final List<HurufManifestLetter> letters;
  final TracingThresholds thresholds;

  const HurufManifest({
    required this.premium,
    required this.letters,
    this.thresholds = const TracingThresholds(),
  });

  factory HurufManifest.fromJson(Map<String, dynamic> json) => HurufManifest(
    premium: json['premium'] as bool? ?? false,
    letters: [
      for (final l in (json['letters'] as List? ?? const []))
        HurufManifestLetter.fromJson(l as Map<String, dynamic>),
    ],
    thresholds: TracingThresholds.fromJson(
      json['tracing_thresholds'] as Map<String, dynamic>?,
    ),
  );

  @override
  List<Object?> get props => [premium, letters];
}

class HurufStroke extends Equatable {
  final int order;
  final String label;
  final String path;

  const HurufStroke({required this.order, this.label = '', required this.path});

  factory HurufStroke.fromJson(Map<String, dynamic> json) => HurufStroke(
    order: (json['order'] as num).toInt(),
    label: json['label'] as String? ?? '',
    path: json['path'] as String,
  );

  @override
  List<Object?> get props => [order, label, path];
}

/// A letter's published content (`GET /learn/huruf/letters/:id`).
class HurufLetter extends Equatable {
  final String id;
  final int version;
  final String upper;
  final String lower;
  final String word;
  final List<int> highlight;
  final String imageUrl;
  final String letterAudioUrl;
  final String wordAudioUrl;
  final bool lowerRequired;
  final List<HurufStroke> upperStrokes;
  final List<HurufStroke> lowerStrokes;
  final String successTitle;
  final String retryTitle;
  final String hint;

  const HurufLetter({
    required this.id,
    this.version = 1,
    required this.upper,
    required this.lower,
    required this.word,
    this.highlight = const [0],
    this.imageUrl = '',
    this.letterAudioUrl = '',
    this.wordAudioUrl = '',
    this.lowerRequired = false,
    this.upperStrokes = const [],
    this.lowerStrokes = const [],
    this.successTitle = '',
    this.retryTitle = '',
    this.hint = '',
  });

  factory HurufLetter.fromJson(Map<String, dynamic> json) {
    final kenali = json['kenali'] as Map<String, dynamic>? ?? const {};
    final dengar = json['dengar'] as Map<String, dynamic>? ?? const {};
    final tebalkan = json['tebalkan'] as Map<String, dynamic>? ?? const {};
    final feedback = json['feedback'] as Map<String, dynamic>? ?? const {};
    List<HurufStroke> strokes(String key) => [
      for (final s in (tebalkan[key] as List? ?? const []))
        HurufStroke.fromJson(s as Map<String, dynamic>),
    ]..sort((a, b) => a.order.compareTo(b.order));
    return HurufLetter(
      id: json['id'] as String,
      version: (json['version'] as num?)?.toInt() ?? 1,
      upper: json['upper'] as String,
      lower:
          json['lower'] as String? ?? (json['upper'] as String).toLowerCase(),
      word: kenali['word'] as String? ?? '',
      highlight: [
        for (final i in (kenali['highlight'] as List? ?? const []))
          (i as num).toInt(),
      ],
      imageUrl: resolveMediaUrl(kenali['image_url']),
      letterAudioUrl: resolveMediaUrl(dengar['letter_audio_url']),
      wordAudioUrl: resolveMediaUrl(dengar['word_audio_url']),
      lowerRequired: tebalkan['lower_required'] as bool? ?? false,
      upperStrokes: strokes('upper'),
      lowerStrokes: strokes('lower'),
      successTitle: feedback['success'] as String? ?? '',
      retryTitle: feedback['retry'] as String? ?? '',
      hint: feedback['hint'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [id, version];
}

/// One child's progress on one letter.
class HurufProgress extends Equatable {
  final String letterId;
  final bool kenaliDone;
  final bool dengarDone;
  final bool tebalkanDone;
  final double? bestScore;
  final int attempts;
  final DateTime? updatedAt;

  const HurufProgress({
    required this.letterId,
    this.kenaliDone = false,
    this.dengarDone = false,
    this.tebalkanDone = false,
    this.bestScore,
    this.attempts = 0,
    this.updatedAt,
  });

  /// Dengar is part of Kenali in the app, so it doesn't gate completion.
  bool get done => kenaliDone && tebalkanDone;
  bool get started => kenaliDone || dengarDone || tebalkanDone;

  factory HurufProgress.fromJson(Map<String, dynamic> json) => HurufProgress(
    letterId: json['letter_id'] as String,
    kenaliDone: json['kenali_done'] as bool? ?? false,
    dengarDone: json['dengar_done'] as bool? ?? false,
    tebalkanDone: json['tebalkan_done'] as bool? ?? false,
    bestScore: (json['best_score'] as num?)?.toDouble(),
    attempts: (json['attempts'] as num?)?.toInt() ?? 0,
    updatedAt: json['updated_at'] == null
        ? null
        : DateTime.tryParse(json['updated_at'] as String),
  );

  /// Local merge, mirroring the server's: flags only turn on.
  HurufProgress merge({
    bool kenali = false,
    bool dengar = false,
    bool tebalkan = false,
    double? score,
  }) => HurufProgress(
    letterId: letterId,
    kenaliDone: kenaliDone || kenali,
    dengarDone: dengarDone || dengar,
    tebalkanDone: tebalkanDone || tebalkan,
    bestScore: score == null
        ? bestScore
        : (bestScore == null || score > bestScore! ? score : bestScore),
    attempts: attempts,
    updatedAt: DateTime.now(),
  );

  @override
  List<Object?> get props => [
    letterId,
    kenaliDone,
    dengarDone,
    tebalkanDone,
    bestScore,
    attempts,
  ];
}
