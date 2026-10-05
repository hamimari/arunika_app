import 'package:arunika_app/core/logger/app_logger.dart';
import 'package:arunika_app/data/models/response/huruf_response.dart';
import 'package:arunika_app/data/repositories/huruf_repository.dart';
import 'package:arunika_app/presentation/screens/growth/growth_cubit.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum HurufStatus {
  /// Logged out or `belajar_huruf` off: nothing Huruf-related shows.
  hidden,
  loading,
  loaded,

  /// Logged in but the account has no child to record progress for.
  noChild,
  error,
}

/// A grid tile's state. Locked wins over progress: a lapsed subscriber sees
/// the lock, and their progress returns when they subscribe again.
enum LetterTileState { locked, notStarted, inProgress, done }

/// The next activity of a letter, for "Lanjutkan belajar". Kenali also
/// holds the letter and word sounds (the server's `dengar_done` is recorded
/// with it), so there is no separate Dengar tab.
enum HurufActivity { kenali, tebalkan }

class HurufState extends Equatable {
  final HurufStatus status;
  final HurufManifest? manifest;
  final Map<String, HurufProgress> progress;

  const HurufState({
    this.status = HurufStatus.hidden,
    this.manifest,
    this.progress = const {},
  });

  bool get premium => manifest?.premium ?? false;
  List<HurufManifestLetter> get letters => manifest?.letters ?? const [];

  LetterTileState tileState(HurufManifestLetter l) {
    if (l.locked) return LetterTileState.locked;
    final p = progress[l.id];
    if (p == null || !p.started) return LetterTileState.notStarted;
    return p.done ? LetterTileState.done : LetterTileState.inProgress;
  }

  /// Done letters among the published ones ("x dari 26 selesai").
  int get doneCount =>
      letters.where((l) => progress[l.id]?.done ?? false).length;

  /// The most recently touched letter that is started but not done, and
  /// still open to this account.
  HurufManifestLetter? get continueLetter {
    HurufManifestLetter? best;
    DateTime? bestAt;
    for (final l in letters) {
      final p = progress[l.id];
      if (l.locked || p == null || !p.started || p.done) continue;
      final at = p.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      if (bestAt == null || at.isAfter(bestAt)) {
        best = l;
        bestAt = at;
      }
    }
    return best;
  }

  /// The first unfinished activity of [letterId].
  HurufActivity nextActivity(String letterId) {
    final p = progress[letterId];
    if (p == null || !p.kenaliDone) return HurufActivity.kenali;
    return HurufActivity.tebalkan;
  }

  /// The letter after [id] in display order, if any.
  HurufManifestLetter? nextLetter(String id) {
    final i = letters.indexWhere((l) => l.id == id);
    return i < 0 || i + 1 >= letters.length ? null : letters[i + 1];
  }

  HurufState copyWith({
    HurufStatus? status,
    HurufManifest? manifest,
    Map<String, HurufProgress>? progress,
  }) => HurufState(
    status: status ?? this.status,
    manifest: manifest ?? this.manifest,
    progress: progress ?? this.progress,
  );

  @override
  List<Object?> get props => [status, manifest, progress];
}

/// Belajar Huruf for the account's first child, shared by the Huruf screens
/// and the Beranda "Lanjutkan belajar" row.
class HurufCubit extends Cubit<HurufState> {
  final HurufRepository repository;
  final Future<String?> Function() _childId;
  final bool Function() _enabled;
  final Listenable? _trigger;

  String? _loadedChildId;

  /// [enabled] is "logged in and `belajar_huruf` on"; [trigger] fires when
  /// either may have changed.
  HurufCubit({
    required this.repository,
    required bool Function() enabled,
    Future<String?> Function()? childId,
    Listenable? trigger,
  }) : _enabled = enabled,
       _childId = childId ?? GrowthCubit.firstChildId,
       _trigger = trigger,
       super(const HurufState()) {
    _trigger?.addListener(_onTrigger);
    _onTrigger();
  }

  void _onTrigger() {
    if (isClosed) return;
    if (!_enabled()) {
      _loadedChildId = null;
      repository.clear();
      emit(const HurufState());
    } else if (state.status == HurufStatus.hidden) {
      load();
    }
  }

  String? get childId => _loadedChildId;

  /// Loads the manifest and the child's progress. [force] skips the
  /// manifest's 15-minute freshness window (pull-to-refresh, back from the
  /// paywall, after a 402).
  Future<void> load({bool force = false}) async {
    if (!_enabled()) return;
    if (state.manifest == null) {
      emit(state.copyWith(status: HurufStatus.loading));
    }
    try {
      final childId = await _childId();
      if (childId == null) {
        if (!isClosed) emit(const HurufState(status: HurufStatus.noChild));
        return;
      }
      final results = await Future.wait([
        repository.manifest(force: force),
        repository.progress(childId),
      ]);
      if (isClosed) return;
      _loadedChildId = childId;
      emit(
        HurufState(
          status: HurufStatus.loaded,
          manifest: results[0] as HurufManifest,
          progress: {
            for (final p in results[1] as List<HurufProgress>) p.letterId: p,
          },
        ),
      );
    } catch (e) {
      AppLogger.warning('Failed to load Huruf', name: 'Huruf', error: e);
      if (!isClosed) {
        emit(
          state.copyWith(
            status: state.manifest == null
                ? HurufStatus.error
                : HurufStatus.loaded,
          ),
        );
      }
    }
  }

  /// A letter's content. Throws [HurufLockedException] or [HurufException].
  Future<HurufLetter> letter(HurufManifestLetter l) async {
    try {
      return await repository.letter(l.id, version: l.version);
    } on HurufLockedException {
      await load(force: true);
      rethrow;
    }
  }

  /// Records progress: shown at once, then sent (with retries). A 402 means
  /// the subscription lapsed mid-letter — the write is dropped silently and
  /// the grid refreshes so the letter shows as locked next time.
  Future<void> record(
    String letterId, {
    bool kenali = false,
    bool dengar = false,
    bool tebalkan = false,
    double? score,
    bool attempt = false,
  }) async {
    final childId = _loadedChildId;
    if (childId == null) return;
    final current =
        state.progress[letterId] ?? HurufProgress(letterId: letterId);
    final merged = current.merge(
      kenali: kenali,
      dengar: dengar,
      tebalkan: tebalkan,
      score: score,
    );
    if (merged != current || state.progress[letterId] == null) {
      emit(state.copyWith(progress: {...state.progress, letterId: merged}));
    }
    try {
      final saved = await repository.saveProgress(
        childId,
        letterId,
        kenali: kenali,
        dengar: dengar,
        tebalkan: tebalkan,
        score: score,
        attempt: attempt,
      );
      if (!isClosed) {
        emit(state.copyWith(progress: {...state.progress, letterId: saved}));
      }
    } on HurufLockedException {
      await load(force: true);
    } on HurufException catch (e) {
      AppLogger.warning('Huruf progress not saved', name: 'Huruf', error: e);
    }
  }

  @override
  Future<void> close() {
    _trigger?.removeListener(_onTrigger);
    return super.close();
  }
}
