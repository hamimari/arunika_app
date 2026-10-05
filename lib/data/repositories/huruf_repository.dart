import 'package:arunika_app/data/api/huruf_api.dart';
import 'package:arunika_app/data/models/response/huruf_response.dart';
import 'package:dio/dio.dart';

/// The letter needs Akses Premium (402 PREMIUM_REQUIRED). Never shown as an
/// error: the UI shows the letter as locked.
class HurufLockedException implements Exception {
  const HurufLockedException();
}

/// Anything else that went wrong; [isNetwork] when no answer came back.
class HurufException implements Exception {
  final int? status;
  const HurufException(this.status);

  bool get isNetwork => status == null;

  @override
  String toString() => 'HurufException($status)';
}

class HurufRepository {
  final HurufApi api;
  final DateTime Function() _now;
  final Future<void> Function(Duration) _sleep;

  /// The manifest is refetched at most every [manifestMaxAge] unless forced,
  /// which is how a backoffice publish reaches devices within 15 minutes.
  static const manifestMaxAge = Duration(minutes: 15);

  /// Delays between progress-write retries.
  static const retryDelays = [
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 4),
  ];

  HurufRepository(
    this.api, {
    DateTime Function()? now,
    Future<void> Function(Duration)? sleep,
  }) : _now = now ?? DateTime.now,
       _sleep = sleep ?? Future<void>.delayed;

  HurufManifest? _manifest;
  String? _etag;
  DateTime? _fetchedAt;
  final Map<String, HurufLetter> _letters = {};

  HurufManifest? get cachedManifest => _manifest;

  /// The manifest, from memory when fresh. [force] (pull-to-refresh, back
  /// from the paywall) always asks the server, sending the ETag so an
  /// unchanged manifest costs a 304.
  Future<HurufManifest> manifest({bool force = false}) async {
    final fresh =
        _fetchedAt != null && _now().difference(_fetchedAt!) < manifestMaxAge;
    if (!force && fresh && _manifest != null) return _manifest!;
    final res = await _guard(
      () => api.fetchManifest(etag: _manifest == null ? null : _etag),
    );
    _fetchedAt = _now();
    if (res.body != null) {
      _manifest = HurufManifest.fromJson(res.body!);
      _etag = res.etag;
    }
    return _manifest!;
  }

  /// A letter's content, cached by (id, version).
  Future<HurufLetter> letter(String id, {required int version}) async {
    final key = '$id@$version';
    final cached = _letters[key];
    if (cached != null) return cached;
    final l = HurufLetter.fromJson(await _guard(() => api.fetchLetter(id)));
    _letters['$id@${l.version}'] = l;
    return l;
  }

  Future<List<HurufProgress>> progress(String childId) async {
    final rows = await _guard(() => api.fetchProgress(childId));
    return [
      for (final r in rows) HurufProgress.fromJson(r as Map<String, dynamic>),
    ];
  }

  /// Sends a progress update, retrying network and server errors with
  /// backoff. Throws [HurufLockedException] on 402 (the caller drops the
  /// write silently) and [HurufException] when every retry failed.
  Future<HurufProgress> saveProgress(
    String childId,
    String letterId, {
    bool kenali = false,
    bool dengar = false,
    bool tebalkan = false,
    double? score,
    bool attempt = false,
  }) async {
    final body = {
      if (kenali) 'kenali_done': true,
      if (dengar) 'dengar_done': true,
      if (tebalkan) 'tebalkan_done': true,
      if (score != null) 'score': score,
      if (attempt) 'attempt': true,
    };
    for (var i = 0; ; i++) {
      try {
        return HurufProgress.fromJson(
          await _guard(() => api.saveProgress(childId, letterId, body)),
        );
      } on HurufException catch (e) {
        final retryable = e.isNetwork || (e.status ?? 0) >= 500;
        if (!retryable || i >= retryDelays.length) rethrow;
        await _sleep(retryDelays[i]);
      }
    }
  }

  /// Drops cached data, e.g. after logout.
  void clear() {
    _manifest = null;
    _etag = null;
    _fetchedAt = null;
    _letters.clear();
  }

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 402) throw const HurufLockedException();
      throw HurufException(status);
    }
  }
}
