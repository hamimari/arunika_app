import 'package:arunika_app/data/api/huruf_api.dart';
import 'package:dio/dio.dart';

/// In-memory `/learn/huruf` backend for repository, cubit and widget tests.
class FakeHurufApi implements HurufApi {
  bool premium;
  final List<Map<String, dynamic>> letters;
  final Map<String, Map<String, dynamic>> content;
  final Map<String, Map<String, dynamic>> progressRows = {};
  final List<String> calls = [];
  final List<Map<String, dynamic>> progressBodies = [];

  /// When set, the next N progress writes fail with this status (null =
  /// network error).
  int failProgressWrites = 0;
  int? failStatus;

  String etag = '"v1"';

  FakeHurufApi({
    this.premium = false,
    List<Map<String, dynamic>>? letters,
    Map<String, Map<String, dynamic>>? content,
  }) : letters = letters ?? defaultLetters(),
       content = content ?? {};

  static List<Map<String, dynamic>> defaultLetters() => [
    for (final (i, u) in ['A', 'B', 'C'].indexed)
      {
        'id': 'id-$u',
        'upper': u,
        'lower': u.toLowerCase(),
        'word': ['Apel', 'Bola', 'Cicak'][i],
        'image_url': '',
        'is_free': u == 'A',
        'version': 1,
      },
  ];

  /// A one-stroke letter, easy to trace in widget tests.
  static Map<String, dynamic> letterContent(String upper, {String? word}) => {
    'id': 'id-$upper',
    'version': 1,
    'upper': upper,
    'lower': upper.toLowerCase(),
    'kenali': {
      'word': word ?? 'Apel',
      'highlight': [0],
      'image_url': '',
    },
    'dengar': {
      'letter_audio_url': 'https://media.test/$upper.mp3',
      'word_audio_url': 'https://media.test/$upper-word.mp3',
    },
    'tebalkan': {
      'grid': 300,
      'lower_required': false,
      'upper': [
        {'order': 1, 'label': 'Garis', 'path': 'M40 150 L260 150'},
      ],
      'lower': [],
    },
    'feedback': {
      'success': 'Keren! Huruf $upper rapi!',
      'retry': 'Belum pas, ayo lagi!',
      'hint': 'Mulai dari angka 1, lalu ikuti titik-titik sampai ujung.',
    },
  };

  DioException _error(String path, int? status) => status == null
      ? DioException.connectionError(
          requestOptions: RequestOptions(path: path),
          reason: 'offline',
        )
      : DioException(
          requestOptions: RequestOptions(path: path),
          response: Response(
            requestOptions: RequestOptions(path: path),
            statusCode: status,
            data: {'code': status == 402 ? 'PREMIUM_REQUIRED' : 'X'},
          ),
          type: DioExceptionType.badResponse,
        );

  bool _locked(String id) {
    final l = letters.firstWhere((l) => l['id'] == id);
    return !(l['is_free'] as bool) && !premium;
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
      'letters': [
        for (final l in letters) {...l, 'locked': _locked(l['id'] as String)},
      ],
      'tracing_thresholds': {'radius': 22, 'max_failures': 3},
    }, current);
  }

  @override
  Future<Map<String, dynamic>> fetchLetter(String id) async {
    calls.add('letter $id');
    if (_locked(id)) throw _error(id, 402);
    final upper = id.replaceFirst('id-', '');
    return content[id] ?? letterContent(upper);
  }

  @override
  Future<List<dynamic>> fetchProgress(String childId) async {
    calls.add('progress $childId');
    return progressRows.values.toList();
  }

  @override
  Future<Map<String, dynamic>> saveProgress(
    String childId,
    String letterId,
    Map<String, dynamic> body,
  ) async {
    calls.add('save $letterId');
    progressBodies.add(body);
    if (failProgressWrites > 0) {
      failProgressWrites--;
      throw _error(letterId, failStatus);
    }
    if (_locked(letterId)) throw _error(letterId, 402);
    final row =
        progressRows[letterId] ??
        {
          'letter_id': letterId,
          'kenali_done': false,
          'dengar_done': false,
          'tebalkan_done': false,
          'best_score': null,
          'attempts': 0,
        };
    for (final k in ['kenali_done', 'dengar_done', 'tebalkan_done']) {
      if (body[k] == true) row[k] = true;
    }
    if (body['score'] != null) {
      final s = (body['score'] as num).toDouble();
      final best = row['best_score'] as num?;
      if (best == null || s > best) row['best_score'] = s;
    }
    if (body['attempt'] == true) {
      row['attempts'] = (row['attempts'] as int? ?? 0) + 1;
    }
    row['updated_at'] = DateTime.now().toIso8601String();
    progressRows[letterId] = row;
    return Map<String, dynamic>.from(row);
  }
}
