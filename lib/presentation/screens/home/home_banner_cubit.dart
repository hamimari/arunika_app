import 'package:arunika_app/data/models/response/banner_item.dart';
import 'package:arunika_app/data/repositories/banner_repository.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ─── States ───────────────────────────────────────────────────────────────────

abstract class HomeBannerState {}

class HomeBannerLoading extends HomeBannerState {}

class HomeBannerLoaded extends HomeBannerState {
  final List<BannerItem> banners;
  HomeBannerLoaded(this.banners);
}

class HomeBannerEmpty extends HomeBannerState {}

// ─── Cubit ────────────────────────────────────────────────────────────────────

class HomeBannerCubit extends Cubit<HomeBannerState> {
  final BannerRepository _repo = locator<BannerRepository>();

  HomeBannerCubit() : super(HomeBannerLoading()) {
    _load();
  }

  Future<void> _load() async {
    final banners = await _repo.getActiveBanners();
    if (isClosed) return;
    if (banners.isEmpty) {
      emit(HomeBannerEmpty());
    } else {
      emit(HomeBannerLoaded(banners));
    }
  }
}
