import 'package:arunika_app/core/auth/auth_notifier.dart';
import 'package:arunika_app/data/models/response/dongeng_response.dart';
import 'package:arunika_app/data/repositories/dongeng_history_repository.dart';
import 'package:arunika_app/data/repositories/fairy_tales_repository.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ─── State ────────────────────────────────────────────────────────────────────

abstract class HomeDongengState {}

class HomeDongengLoading extends HomeDongengState {}

class HomeDongengLoaded extends HomeDongengState {
  final List<DongengResponse> items;
  final Map<String, double> progressMap; // dongengId -> progress 0..1
  HomeDongengLoaded(this.items, {this.progressMap = const {}});
}

class HomeDongengError extends HomeDongengState {}

// ─── Bloc ─────────────────────────────────────────────────────────────────────

class HomeDongengSectionBloc extends Cubit<HomeDongengState> {
  final FairyTalesRepository _talesRepo = locator<FairyTalesRepository>();
  final DongengHistoryRepository _historyRepo =
      locator<DongengHistoryRepository>();
  final AuthNotifier _auth = locator<AuthNotifier>();

  HomeDongengSectionBloc() : super(HomeDongengLoading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      // Fetch popular list from fairy tales repository
      final page = await _talesRepo.findAll();
      final allItems = page.items;

      Map<String, double> progressMap = {};

      if (_auth.isLoggedIn) {
        // Fetch watch history and build progress map
        final history = await _historyRepo.getHistory();
        for (final h in history) {
          progressMap[h.dongengId] = h.progress;
        }
      }

      if (isClosed) return;
      emit(
        HomeDongengLoaded(allItems.take(6).toList(), progressMap: progressMap),
      );
    } catch (_) {
      if (!isClosed) emit(HomeDongengError());
    }
  }
}
