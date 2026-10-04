import 'package:arunika_app/data/models/response/payment_history_item.dart';
import 'package:arunika_app/data/repositories/order_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PaymentHistoryState extends Equatable {
  final List<PaymentHistoryItem> items;
  final int total;
  final int page;

  /// True while the first page is loading (or reloading after an error).
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;

  const PaymentHistoryState({
    this.items = const [],
    this.total = 0,
    this.page = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
  });

  bool get hasMore => items.length < total;

  PaymentHistoryState copyWith({
    List<PaymentHistoryItem>? items,
    int? total,
    int? page,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool clearError = false,
  }) {
    return PaymentHistoryState(
      items: items ?? this.items,
      total: total ?? this.total,
      page: page ?? this.page,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [
    items,
    total,
    page,
    isLoading,
    isLoadingMore,
    error,
  ];
}

class PaymentHistoryCubit extends Cubit<PaymentHistoryState> {
  static const int perPage = 20;
  static const String loadError = 'Gagal memuat riwayat pembayaran. Coba lagi.';

  final OrderRepository _repository;

  PaymentHistoryCubit(this._repository) : super(const PaymentHistoryState());

  /// Loads (or reloads) the first page. Keeps already-shown items visible
  /// during a pull-to-refresh.
  Future<void> load() async {
    emit(state.copyWith(isLoading: state.items.isEmpty, clearError: true));
    try {
      final result = await _repository.fetchPaymentHistory(
        page: 1,
        perPage: perPage,
      );
      emit(
        PaymentHistoryState(items: result.items, total: result.total, page: 1),
      );
    } catch (_) {
      emit(state.copyWith(isLoading: false, error: loadError));
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    emit(state.copyWith(isLoadingMore: true, clearError: true));
    try {
      final next = state.page + 1;
      final result = await _repository.fetchPaymentHistory(
        page: next,
        perPage: perPage,
      );
      // Orders placed since the first page shift later pages; skip repeats.
      final seen = state.items.map((i) => i.orderId).toSet();
      final items = [
        ...state.items,
        ...result.items.where((i) => !seen.contains(i.orderId)),
      ];
      emit(
        state.copyWith(
          items: items,
          // An empty page means the end was reached even if the count moved.
          total: result.items.isEmpty ? items.length : result.total,
          page: next,
          isLoadingMore: false,
        ),
      );
    } catch (_) {
      emit(state.copyWith(isLoadingMore: false, error: loadError));
    }
  }
}
