import 'package:arunika_app/core/angka/question_generator.dart';
import 'package:arunika_app/data/api/angka_api.dart';
import 'package:arunika_app/data/api/huruf_api.dart';
import 'package:dio/dio.dart';

/// In-memory `/learn/angka` backend for repository, cubit and widget tests.
/// It scores sessions with the real generator, as the server does.
class FakeAngkaApi implements AngkaApi {
  bool premium;
  final List<Map<String, dynamic>> numbers;
  final List<Map<String, dynamic>> levels;
  final Map<String, Map<String, dynamic>> progressRows = {};
  final Map<String, Map<String, dynamic>> sessions = {};
  final List<String> calls = [];

  /// When set, the next N writes (tries and completes) fail with
  /// [failStatus] (null = network error).
  int failWrites = 0;
  int? failStatus;

  /// When set, the next N completes fail with a network error.
  int failCompletes = 0;

  /// The seed handed to new sessions.
  int nextSeed = 42;

  String etag = '"v1"';

  FakeAngkaApi({
    this.premium = false,
    List<Map<String, dynamic>>? numbers,
    List<Map<String, dynamic>>? levels,
  }) : numbers = numbers ?? defaultNumbers(),
       levels = levels ?? defaultLevels();

  static const names = [
    'satu',
    'dua',
    'tiga',
    'empat',
    'lima',
    'enam',
    'tujuh',
    'delapan',
    'sembilan',
    'sepuluh',
  ];

  static List<Map<String, dynamic>> defaultNumbers() => [
    for (var v = 1; v <= 10; v++)
      {'value': v, 'name': names[v - 1], 'is_free': v <= 5},
  ];

  /// Level 1 (free, 1–5, rows so tests can tap pictures predictably),
  /// Level 2 (1–10, after Level 1) and Level 3 (11–20, after Level 2).
  static List<Map<String, dynamic>> defaultLevels() => [
    level('l1', 'Hitung 1 sampai 5', 1, 5, free: true, layout: 'rows'),
    level('l2', 'Hitung 1 sampai 10', 1, 10, prerequisite: 'l1'),
    level('l3', 'Hitung 11 sampai 20', 11, 20, prerequisite: 'l2'),
  ];

  static Map<String, dynamic> level(
    String id,
    String name,
    int min,
    int max, {
    bool free = false,
    String? prerequisite,
    String layout = 'scatter',
    int questions = 10,
  }) => {
    'id': id,
    'name': name,
    'range': {'min': min, 'max': max},
    'question_count': questions,
    'prerequisite_id': prerequisite,
    'is_free': free,
    'version': 1,
    'layout': layout,
    'object_ids': ['apel', 'bola'],
    'stars': {'three': 9, 'two': 7},
    'feedback': {
      'success': 'Hebat! Benar!',
      'retry': 'Hampir benar!',
      'hint': 'Sentuh {benda} satu per satu sambil menyebut 1, 2, 3…',
    },
  };

  static Map<String, dynamic> object(String id) => {
    'id': id,
    'name': id,
    'question_text': 'Ada berapa $id?',
    'image_url': '',
    'question_audio_url': 'https://media.test/$id.mp3',
    'hidden': false,
  };

  Map<String, String> countAudio(int max) => {
    for (var v = 1; v <= max; v++) '$v': 'https://media.test/count-$v.mp3',
  };

  DioException _error(String path, int? status, [String? code]) =>
      status == null
      ? DioException.connectionError(
          requestOptions: RequestOptions(path: path),
          reason: 'offline',
        )
      : DioException(
          requestOptions: RequestOptions(path: path),
          response: Response(
            requestOptions: RequestOptions(path: path),
            statusCode: status,
            data: {
              'code':
                  code ??
                  switch (status) {
                    402 => 'PREMIUM_REQUIRED',
                    409 => 'LEVEL_LOCKED',
                    _ => 'X',
                  },
            },
          ),
          type: DioExceptionType.badResponse,
        );

  Map<String, dynamic> _level(String id) =>
      levels.firstWhere((l) => l['id'] == id);

  bool _levelLocked(String id) => !(_level(id)['is_free'] as bool) && !premium;

  bool _numberLocked(int v) =>
      !(numbers.firstWhere((n) => n['value'] == v)['is_free'] as bool) &&
      !premium;

  void _maybeFail(String path) {
    if (failWrites > 0) {
      failWrites--;
      throw _error(path, failStatus);
    }
  }

  @override
  Dio get dio => throw UnimplementedError();

  @override
  Future<ManifestResponse> fetchManifest({String? etag}) async {
    calls.add('manifest ${etag ?? '-'}');
    final current = '${this.etag}-$premium';
    if (etag == current) return ManifestResponse(null, current);
    return ManifestResponse({
      'premium': premium,
      'numbers': [
        for (final n in numbers)
          {...n, 'locked': _numberLocked(n['value'] as int)},
      ],
      'levels': [
        for (final l in levels)
          {...l, 'locked': _levelLocked(l['id'] as String)},
      ],
    }, current);
  }

  @override
  Future<Map<String, dynamic>> fetchNumber(int value) async {
    calls.add('number $value');
    if (_numberLocked(value)) throw _error('$value', 402);
    return {
      'value': value,
      'name': names[value - 1],
      'audio_url': 'https://media.test/n-$value.mp3',
      'object': object('apel'),
      'count_audio': countAudio(value),
    };
  }

  @override
  Future<List<dynamic>> fetchProgress(String childId) async {
    calls.add('progress $childId');
    return [
      for (final p in progressRows.values)
        {
          ...p,
          'current_session': p['current_session_id'] == null
              ? null
              : _currentSession(p['current_session_id'] as String),
        },
    ];
  }

  Map<String, dynamic> _currentSession(String id) {
    final s = sessions[id]!;
    final qs = questionsOf(id);
    var answered = 0;
    for (final a in s['answers'] as List) {
      final tries = (a['tries'] as List).cast<int>();
      if (tries.contains(qs[(a['q'] as int) - 1].count)) answered++;
    }
    return {
      'id': id,
      'answers': s['answers'],
      'question_count': qs.length,
      'answered': answered,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  /// A session's questions, as the server regenerates them.
  List<AngkaQuestion> questionsOf(String sessionId) {
    final s = sessions[sessionId]!;
    final l = _level(s['level_id'] as String);
    final range = l['range'] as Map<String, dynamic>;
    return AngkaGenerator.generate(
      min: range['min'] as int,
      max: range['max'] as int,
      count: l['question_count'] as int,
      objectIds: (s['object_ids'] as List).cast<String>(),
      layout: l['layout'] as String,
      seed: s['seed'] as int,
    );
  }

  @override
  Future<Map<String, dynamic>> startSession(
    String childId,
    String levelId, {
    bool restart = false,
  }) async {
    calls.add('start $levelId${restart ? ' restart' : ''}');
    if (_levelLocked(levelId)) throw _error(levelId, 402);
    final l = _level(levelId);
    final pre = l['prerequisite_id'] as String?;
    if (pre != null && progressRows[pre]?['completed'] != true) {
      throw _error(levelId, 409, 'LEVEL_LOCKED');
    }
    final prog = progressRows[levelId] ??= {
      'level_id': levelId,
      'best_stars': 0,
      'completed': false,
      'current_session_id': null,
    };
    var id = prog['current_session_id'] as String?;
    if (id == null || restart) {
      id = 's${sessions.length + 1}';
      sessions[id] = {
        'session_id': id,
        'level_id': levelId,
        'level_version': 1,
        'seed': nextSeed,
        'object_ids': l['object_ids'],
        'answers': <Map<String, dynamic>>[],
        'status': 'in_progress',
      };
      prog['current_session_id'] = id;
    }
    final s = sessions[id]!;
    final max = (l['range'] as Map)['max'] as int;
    return {
      ...s,
      'answers': [
        for (final a in s['answers'] as List)
          {'q': a['q'], 'tries': List<int>.from(a['tries'] as List)},
      ],
      'content': l,
      'objects': [for (final o in l['object_ids'] as List) object('$o')],
      'count_audio': countAudio(max),
    };
  }

  @override
  Future<Map<String, dynamic>> recordTry(
    String childId,
    String sessionId, {
    required int q,
    required int attempt,
    required int answer,
  }) async {
    calls.add('try $sessionId q$q #$attempt=$answer');
    _maybeFail(sessionId);
    final s = sessions[sessionId]!;
    final answers = s['answers'] as List<Map<String, dynamic>>;
    var a = answers.where((a) => a['q'] == q).firstOrNull;
    if (a == null) {
      a = {'q': q, 'tries': <int>[]};
      answers.add(a);
    }
    final tries = a['tries'] as List<int>;
    if (attempt != tries.length + 1) {
      throw _error(sessionId, 422, 'INVALID_TRY');
    }
    tries.add(answer);
    return {'q': q, 'try': attempt, 'correct': false, 'finished': false};
  }

  @override
  Future<Map<String, dynamic>> complete(
    String childId,
    String sessionId,
  ) async {
    calls.add('complete $sessionId');
    _maybeFail(sessionId);
    if (failCompletes > 0) {
      failCompletes--;
      throw _error(sessionId, null);
    }
    final s = sessions[sessionId]!;
    final qs = questionsOf(sessionId);
    final answers = s['answers'] as List<Map<String, dynamic>>;
    var finished = 0, first = 0;
    for (final a in answers) {
      final tries = a['tries'] as List<int>;
      final count = qs[(a['q'] as int) - 1].count;
      if (tries.contains(count)) finished++;
      if (tries.isNotEmpty && tries.first == count) first++;
    }
    if (finished < qs.length) {
      throw _error(sessionId, 422, 'SESSION_INCOMPLETE');
    }
    final stars = first >= 9
        ? 3
        : first >= 7
        ? 2
        : 1;
    final prog = progressRows[s['level_id']]!;
    final wasDone = prog['completed'] == true;
    final best = (prog['best_stars'] as int) > stars
        ? prog['best_stars'] as int
        : stars;
    prog
      ..['best_stars'] = best
      ..['completed'] = true
      ..['current_session_id'] = null;
    s['status'] = 'completed';
    return {
      'stars': stars,
      'first_correct': first,
      'best_stars': best,
      'unlocked_level_ids': wasDone
          ? <String>[]
          : [
              for (final o in levels)
                if (o['prerequisite_id'] == s['level_id']) o['id'],
            ],
    };
  }
}
