import 'package:arunika_app/data/repositories/premium_pack_repository.dart';
import 'package:arunika_app/data/static/premium_packs.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ─── States ───────────────────────────────────────────────────────────────────

abstract class PremiumPackState {}

class PremiumPackInitial extends PremiumPackState {}

class PremiumPackLoading extends PremiumPackState {}

class PremiumPackLoaded extends PremiumPackState {
  final List<PremiumPack> packs;
  PremiumPackLoaded(this.packs);
}

class PremiumPackError extends PremiumPackState {
  final String message;
  PremiumPackError(this.message);
}

// ─── Cubit ────────────────────────────────────────────────────────────────────

class PremiumPackCubit extends Cubit<PremiumPackState> {
  final PremiumPackRepository _repo = locator<PremiumPackRepository>();
  final String _type;

  PremiumPackCubit(this._type) : super(PremiumPackInitial());

  Future<void> loadPacks({bool fresh = false}) async {
    if (fresh) _repo.clearCache();
    emit(PremiumPackLoading());
    try {
      final packs = await _repo.fetchPacks(type: _type);
      emit(PremiumPackLoaded(packs));
    } catch (e) {
      emit(PremiumPackError('Gagal memuat paket. Coba lagi.'));
    }
  }
}
