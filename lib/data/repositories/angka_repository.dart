import 'package:arunika_app/data/api/angka_api.dart';
import 'package:arunika_app/data/models/response/angka_response.dart';
import 'package:dio/dio.dart';

/// The number or level needs Akses Premium (402 PREMIUM_REQUIRED). Never
/// shown as an error: the UI shows it as locked.
class AngkaLockedException implements Exception {
  const AngkaLockedException();
}

/// The level's prerequisite isn't completed yet (409 LEVEL_LOCKED).
class AngkaLevelLockedException implements Exception {
  const AngkaLevelLockedException();
}

/// Anything else that went wrong; [isNetwork] when no answer came back.
class AngkaException implements Exception {
  final int? status;
  final String? code;
  const AngkaException(this.status, [this.code]);

  bool get isNetwork => status == null;
  bool get retryable => isNetwork || (status ?? 0) >= 500;

  @override
  String toString() => 'AngkaException($status, $code)';
}

class AngkaRepository {
  final AngkaApi api;
  final DateTime Function() _now;
  final Future<void> Function(Duration) _sleep;

  /// The manifest is refetched at most every [manifestMaxAge] unless forced,
  /// which is how a backoffice publish reaches devices within 15 minutes.
  static const manifestMaxAge = Duration(minutes: 15);

  /// Delays between write retries.
  static const retryDelays = [
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 4),
  ];

  AngkaRepository(
    this.api, {
    DateTime Function()? now,
    Future<void> Function(Duration)? sleep,
  }) : _now = now ?? DateTime.now,
       _sleep = sleep ?? Future<void>.delayed;

  AngkaManifest? _manifest;
  String? _etag;
  DateTime? _fetchedAt;
  final Map<int, AngkaNumberCard> _numbers = {};

  /// Sessions that reached the end but whose complete call failed, as
  /// (childId, sessionId); retried on the next load.
  final Set<(String, String)> _pendingCompletes = {};

  AngkaManifest? get cachedManifest => _manifest;
  Set<(String, String)> get pendingCompletes => {..._pendingCompletes};

  /// The manifest, from memory when fresh. [force] (pull-to-refresh, back
  /// from the paywall) always asks the server, sending the ETag so an
  /// unchanged manifest costs a 304.
  Future<AngkaManifest> manifest({bool force = false}) async {
    final fresh =
        _fetchedAt != null && _now().difference(_fetchedAt!) < manifestMaxAge;
    if (!force && fresh && _manifest != null) return _manifest!;
    final res = await _guard(
      () => api.fetchManifest(etag: _manifest == null ? null : _etag),
    );
    _fetchedAt = _now();
    if (res.body != null) {
      _manifest = AngkaManifest.fromJson(res.body!);
      _etag = res.etag;
      // A new manifest may carry edited numbers.
      _numbers.clear();
    }
    return _manifest!;
  }

  /// A Kenal Angka card, cached until the manifest changes.
  Future<AngkaNumberCard> number(int value) async {
    final cached = _numbers[value];
    if (cached != null) return cached;
    final n = AngkaNumberCard.fromJson(
      await _guard(() => api.fetchNumber(value)),
    );
    return _numbers[value] = n;
  }

  Future<List<AngkaLevelProgress>> progress(String childId) async {
    final rows = await _guard(() => api.fetchProgress(childId));
    return [
      for (final r in rows)
        AngkaLevelProgress.fromJson(r as Map<String, dynamic>),
    ];
  }

  /// Starts a level, or resumes the child's session on it. Throws
  /// [AngkaLockedException], [AngkaLevelLockedException] or
  /// [AngkaException].
  Future<AngkaSession> startSession(
    String childId,
    String levelId, {
    bool restart = false,
  }) async => AngkaSession.fromJson(
    await _guard(() => api.startSession(childId, levelId, restart: restart)),
  );

  /// Records a try, retrying network and server errors with backoff.
  Future<void> recordTry(
    String childId,
    String sessionId, {
    required int q,
    required int attempt,
    required int answer,
  }) => _retry(
    () => api.recordTry(
      childId,
      sessionId,
      q: q,
      attempt: attempt,
      answer: answer,
    ),
  );

  /// Scores a finished session on the server. When every retry fails the
  /// session is remembered and retried by [retryPendingCompletes].
  Future<AngkaCompleteResult> complete(String childId, String sessionId) async {
    try {
      final r = AngkaCompleteResult.fromJson(
        await _retry(() => api.complete(childId, sessionId)),
      );
      _pendingCompletes.remove((childId, sessionId));
      return r;
    } on AngkaException catch (e) {
      if (e.retryable) _pendingCompletes.add((childId, sessionId));
      rethrow;
    }
  }

  /// Retries completes that failed earlier. A session the server still sees
  /// as unfinished (a try was lost) is dropped: "Lanjut" resumes it.
  Future<void> retryPendingCompletes(String childId) async {
    for (final p in pendingCompletes.where((p) => p.$1 == childId)) {
      try {
        await _guard(() => api.complete(p.$1, p.$2));
        _pendingCompletes.remove(p);
      } on AngkaException catch (e) {
        if (!e.retryable) _pendingCompletes.remove(p);
      }
    }
  }

  /// Drops cached data, e.g. after logout.
  void clear() {
    _manifest = null;
    _etag = null;
    _fetchedAt = null;
    _numbers.clear();
    _pendingCompletes.clear();
  }

  Future<T> _retry<T>(Future<T> Function() call) async {
    for (var i = 0; ; i++) {
      try {
        return await _guard(call);
      } on AngkaException catch (e) {
        if (!e.retryable || i >= retryDelays.length) rethrow;
        await _sleep(retryDelays[i]);
      }
    }
  }

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;
      final code = data is Map ? data['code'] as String? : null;
      if (status == 402) throw const AngkaLockedException();
      if (status == 409 && code == 'LEVEL_LOCKED') {
        throw const AngkaLevelLockedException();
      }
      throw AngkaException(status, code);
    }
  }
}
