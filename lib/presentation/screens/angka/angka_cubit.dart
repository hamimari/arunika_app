import 'package:arunika_app/core/logger/app_logger.dart';
import 'package:arunika_app/data/models/response/angka_response.dart';
import 'package:arunika_app/data/repositories/angka_repository.dart';
import 'package:arunika_app/presentation/screens/growth/growth_cubit.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum AngkaStatus {
  /// Logged out or `belajar_angka` off: nothing Angka-related shows.
  hidden,
  loading,
  loaded,

  /// Logged in but the account has no child to record progress for.
  noChild,
  error,
}

/// A level card's state. Premium wins over everything: a lapsed subscriber
/// sees the lock, and their stars return when they subscribe again.
enum AngkaLevelState {
  premiumLocked,
  prerequisiteLocked,
  notStarted,
  inProgress,
  done,
}

class AngkaState extends Equatable {
  final AngkaStatus status;
  final AngkaManifest? manifest;
  final Map<String, AngkaLevelProgress> progress;

  const AngkaState({
    this.status = AngkaStatus.hidden,
    this.manifest,
    this.progress = const {},
  });

  bool get premium => manifest?.premium ?? false;
  List<AngkaManifestNumber> get numbers => manifest?.numbers ?? const [];
  List<AngkaManifestLevel> get levels => manifest?.levels ?? const [];

  AngkaLevelState levelState(AngkaManifestLevel l) {
    if (l.locked) return AngkaLevelState.premiumLocked;
    final pre = l.prerequisiteId;
    if (pre != null && !(progress[pre]?.completed ?? false)) {
      return AngkaLevelState.prerequisiteLocked;
    }
    final p = progress[l.id];
    if (p == null) return AngkaLevelState.notStarted;
    if (p.inProgress) return AngkaLevelState.inProgress;
    return p.completed ? AngkaLevelState.done : AngkaLevelState.notStarted;
  }

  /// "Level n": the level's position in display order.
  int levelNumber(String id) => levels.indexWhere((l) => l.id == id) + 1;

  /// The most recently played level with a session in progress, still open
  /// to this account.
  AngkaManifestLevel? get continueLevel {
    AngkaManifestLevel? best;
    DateTime? bestAt;
    for (final l in levels) {
      final p = progress[l.id];
      if (p == null || !p.inProgress) continue;
      if (levelState(l) != AngkaLevelState.inProgress) continue;
      final at = p.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      if (bestAt == null || at.isAfter(bestAt)) {
        best = l;
        bestAt = at;
      }
    }
    return best;
  }

  /// The level after [id] in display order, if it is open to play.
  AngkaManifestLevel? nextOpenLevel(String id) {
    final i = levels.indexWhere((l) => l.id == id);
    if (i < 0 || i + 1 >= levels.length) return null;
    final next = levels[i + 1];
    final s = levelState(next);
    return s == AngkaLevelState.premiumLocked ||
            s == AngkaLevelState.prerequisiteLocked
        ? null
        : next;
  }

  AngkaState copyWith({
    AngkaStatus? status,
    AngkaManifest? manifest,
    Map<String, AngkaLevelProgress>? progress,
  }) => AngkaState(
    status: status ?? this.status,
    manifest: manifest ?? this.manifest,
    progress: progress ?? this.progress,
  );

  @override
  List<Object?> get props => [status, manifest, progress];
}

/// Belajar Angka for the account's first child, shared by the Angka screens
/// and the Beranda "Lanjutkan belajar" row.
class AngkaCubit extends Cubit<AngkaState> {
  final AngkaRepository repository;
  final Future<String?> Function() _childId;
  final bool Function() _enabled;
  final Listenable? _trigger;

  String? _loadedChildId;

  /// [enabled] is "logged in and `belajar_angka` on"; [trigger] fires when
  /// either may have changed.
  AngkaCubit({
    required this.repository,
    required bool Function() enabled,
    Future<String?> Function()? childId,
    Listenable? trigger,
  }) : _enabled = enabled,
       _childId = childId ?? GrowthCubit.firstChildId,
       _trigger = trigger,
       super(const AngkaState()) {
    _trigger?.addListener(_onTrigger);
    _onTrigger();
  }

  void _onTrigger() {
    if (isClosed) return;
    if (!_enabled()) {
      _loadedChildId = null;
      repository.clear();
      emit(const AngkaState());
    } else if (state.status == AngkaStatus.hidden) {
      load();
    }
  }

  String? get childId => _loadedChildId;

  /// Loads the manifest and the child's progress, first retrying any level
  /// whose complete failed. [force] skips the manifest's 15-minute window
  /// (pull-to-refresh, back from the paywall or a level).
  Future<void> load({bool force = false}) async {
    if (!_enabled()) return;
    if (state.manifest == null) {
      emit(state.copyWith(status: AngkaStatus.loading));
    }
    try {
      final childId = await _childId();
      if (childId == null) {
        if (!isClosed) emit(const AngkaState(status: AngkaStatus.noChild));
        return;
      }
      await repository.retryPendingCompletes(childId);
      final results = await Future.wait([
        repository.manifest(force: force),
        repository.progress(childId),
      ]);
      if (isClosed) return;
      _loadedChildId = childId;
      emit(
        AngkaState(
          status: AngkaStatus.loaded,
          manifest: results[0] as AngkaManifest,
          progress: {
            for (final p in results[1] as List<AngkaLevelProgress>)
              p.levelId: p,
          },
        ),
      );
    } catch (e) {
      AppLogger.warning('Failed to load Angka', name: 'Angka', error: e);
      if (!isClosed) {
        emit(
          state.copyWith(
            status: state.manifest == null
                ? AngkaStatus.error
                : AngkaStatus.loaded,
          ),
        );
      }
    }
  }

  /// A Kenal Angka card. Throws [AngkaLockedException] or [AngkaException].
  Future<AngkaNumberCard> number(int value) async {
    try {
      return await repository.number(value);
    } on AngkaLockedException {
      await load(force: true);
      rethrow;
    }
  }

  @override
  Future<void> close() {
    _trigger?.removeListener(_onTrigger);
    return super.close();
  }
}
