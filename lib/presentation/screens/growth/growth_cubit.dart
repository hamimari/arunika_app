import 'package:arunika_app/core/growth/growth_engine.dart';
import 'package:arunika_app/core/logger/app_logger.dart';
import 'package:arunika_app/core/storage/LocalProfileStorage.dart';
import 'package:arunika_app/core/storage/SecureStorageToken.dart';
import 'package:arunika_app/data/models/response/growth_response.dart';
import 'package:arunika_app/data/repositories/growth_repository.dart';
import 'package:arunika_app/data/repositories/user_repository.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum GrowthStatus {
  /// Logged out, feature flag off, or no child: nothing growth-related shows.
  hidden,
  loading,
  loaded,
  error,
}

/// The newest value of one indicator and its change from the one before.
class LatestValue extends Equatable {
  final double value;
  final String? category;
  final DateTime measuredOn;
  final int ageDays;
  final double? delta;

  const LatestValue({
    required this.value,
    required this.category,
    required this.measuredOn,
    required this.ageDays,
    this.delta,
  });

  @override
  List<Object?> get props => [value, category, measuredOn, ageDays, delta];
}

class GrowthState extends Equatable {
  final GrowthStatus status;
  final GrowthSummary? summary;
  final WhoGrowthStandard? standard;

  /// Rows deleted in the UI whose server round trip has not finished; hidden
  /// at once so the delete feels instant, and brought back if it fails.
  final Set<String> pendingDeletes;

  const GrowthState({
    this.status = GrowthStatus.hidden,
    this.summary,
    this.standard,
    this.pendingDeletes = const {},
  });

  GrowthChild? get child => summary?.child;
  bool get profileComplete => summary?.profileComplete ?? false;

  /// Newest first, without rows being deleted.
  List<GrowthMeasurement> get measurements => [
    for (final m in summary?.measurements ?? const <GrowthMeasurement>[])
      if (!pendingDeletes.contains(m.id)) m,
  ];

  LatestValue? get latestHeight =>
      _latest((m) => m.heightCm, (m) => m.hfaCategory);
  LatestValue? get latestWeight =>
      _latest((m) => m.weightKg, (m) => m.wfaCategory);

  /// The newest measurement date and its age, for the Beranda card.
  GrowthMeasurement? get newest =>
      measurements.isEmpty ? null : measurements.first;

  LatestValue? _latest(
    double? Function(GrowthMeasurement) value,
    String? Function(GrowthMeasurement) category,
  ) {
    LatestValue? out;
    for (final m in measurements) {
      final v = value(m);
      if (v == null) continue;
      if (out == null) {
        out = LatestValue(
          value: v,
          category: category(m),
          measuredOn: m.measuredOn,
          ageDays: m.ageDays,
        );
        continue;
      }
      return LatestValue(
        value: out.value,
        category: out.category,
        measuredOn: out.measuredOn,
        ageDays: out.ageDays,
        delta: roundTo(out.value - v, 1),
      );
    }
    return out;
  }

  GrowthState copyWith({
    GrowthStatus? status,
    GrowthSummary? summary,
    WhoGrowthStandard? standard,
    Set<String>? pendingDeletes,
  }) => GrowthState(
    status: status ?? this.status,
    summary: summary ?? this.summary,
    standard: standard ?? this.standard,
    pendingDeletes: pendingDeletes ?? this.pendingDeletes,
  );

  @override
  List<Object?> get props => [status, summary, standard, pendingDeletes];
}

/// Growth data for the account's first child, shared by the Tumbuh tab and the
/// Beranda card so both stay in step after every change.
class GrowthCubit extends Cubit<GrowthState> {
  final GrowthRepository repository;
  final Future<String?> Function() _childId;
  final bool Function() _enabled;
  final Future<WhoGrowthStandard> Function() _loadStandard;
  final Listenable? _trigger;

  String? _loadedChildId;

  /// [enabled] is "logged in and `growth_tracking` on"; [trigger] fires when
  /// either may have changed.
  GrowthCubit({
    required this.repository,
    required bool Function() enabled,
    Future<String?> Function()? childId,
    Future<WhoGrowthStandard> Function()? loadStandard,
    Listenable? trigger,
  }) : _enabled = enabled,
       _childId = childId ?? firstChildId,
       _loadStandard = loadStandard ?? WhoGrowthStandard.load,
       _trigger = trigger,
       super(const GrowthState()) {
    _trigger?.addListener(_onTrigger);
    _onTrigger();
  }

  void _onTrigger() {
    if (isClosed) return;
    if (!_enabled()) {
      _loadedChildId = null;
      emit(const GrowthState());
    } else if (state.status == GrowthStatus.hidden) {
      load();
    }
  }

  String? get childId => _loadedChildId;

  /// Fetches the summary. Keeps showing the current data while refreshing.
  Future<void> load() async {
    if (!_enabled()) return;
    if (state.summary == null) {
      emit(state.copyWith(status: GrowthStatus.loading));
    }
    try {
      final childId = await _childId();
      if (childId == null) {
        if (!isClosed) emit(const GrowthState());
        return;
      }
      final results = await Future.wait([
        repository.fetchSummary(childId),
        if (state.standard == null) _loadStandard(),
      ]);
      if (isClosed) return;
      _loadedChildId = childId;
      emit(
        GrowthState(
          status: GrowthStatus.loaded,
          summary: results[0] as GrowthSummary,
          standard: results.length > 1
              ? results[1] as WhoGrowthStandard
              : state.standard,
        ),
      );
    } catch (e) {
      AppLogger.warning('Failed to load growth', name: 'Growth', error: e);
      if (!isClosed) emit(state.copyWith(status: GrowthStatus.error));
    }
  }

  /// Throws [GrowthSaveException]; the form shows the matching message.
  Future<void> create(
    MeasurementInput input, {
    required String clientId,
    bool confirmOutlier = false,
  }) async {
    await repository.create(
      _requireChild(),
      input,
      clientId: clientId,
      confirmOutlier: confirmOutlier,
    );
    await load();
  }

  Future<void> update(
    String id,
    MeasurementInput input, {
    bool confirmOutlier = false,
  }) async {
    await repository.update(
      _requireChild(),
      id,
      input,
      confirmOutlier: confirmOutlier,
    );
    await load();
  }

  /// Hides the row at once, then deletes it. Returns false (and brings the row
  /// back) when the server could not be reached.
  Future<bool> delete(String id) async {
    emit(state.copyWith(pendingDeletes: {...state.pendingDeletes, id}));
    try {
      await repository.delete(_requireChild(), id);
      await load();
      return true;
    } on GrowthSaveException {
      if (!isClosed) {
        emit(
          state.copyWith(pendingDeletes: {...state.pendingDeletes}..remove(id)),
        );
      }
      return false;
    }
  }

  /// "Urungkan": undoes a delete.
  Future<void> restore(String id) async {
    await repository.restore(_requireChild(), id);
    await load();
  }

  String _requireChild() {
    final id = _loadedChildId;
    if (id == null) throw const GrowthSaveException('CHILD_NOT_LOADED');
    return id;
  }

  @override
  Future<void> close() {
    _trigger?.removeListener(_onTrigger);
    return super.close();
  }

  /// The id of the signed-in parent's first child: from the cached profile,
  /// else fetched.
  static Future<String?> firstChildId() async {
    final cached = await LocalProfileStorage.get();
    if (cached != null && cached.children.isNotEmpty) {
      return cached.children.first.id;
    }
    final userId = await SecureTokenStorage.getUserId();
    if (userId == null) return null;
    final fresh = await locator<UserRepository>().findById(userId);
    return fresh.children.isEmpty ? null : fresh.children.first.id;
  }
}
