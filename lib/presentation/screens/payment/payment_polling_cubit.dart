import 'dart:async';

import 'package:arunika_app/data/models/response/order_response.dart';
import 'package:arunika_app/data/repositories/order_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ─── States ───────────────────────────────────────────────────────────────────

abstract class PaymentPollingState {}

class PaymentPollingIdle extends PaymentPollingState {}

class PaymentPollingWaiting extends PaymentPollingState {}

class PaymentPollingPaid extends PaymentPollingState {}

class PaymentPollingFailed extends PaymentPollingState {}

// ─── Cubit ────────────────────────────────────────────────────────────────────

/// Polls `GET /orders/:id` until the backend confirms the order outcome,
/// instead of trusting the payment webview's own success callback.
class PaymentPollingCubit extends Cubit<PaymentPollingState> {
  final OrderRepository _repository;
  final Duration pollInterval;
  final int maxAttempts;

  Timer? _timer;
  int _attempts = 0;

  PaymentPollingCubit(
    this._repository, {
    this.pollInterval = const Duration(seconds: 2),
    this.maxAttempts = 15, // 15 * 2s = 30s timeout
  }) : super(PaymentPollingIdle());

  void start(String orderId) {
    _timer?.cancel();
    _attempts = 0;
    emit(PaymentPollingWaiting());
    _timer = Timer.periodic(pollInterval, (_) => _poll(orderId));
  }

  Future<void> _poll(String orderId) async {
    _attempts++;
    try {
      final order = await _repository.fetchOrderStatus(orderId);
      if (order.status == OrderStatus.paid) {
        _timer?.cancel();
        emit(PaymentPollingPaid());
        return;
      }
      if (order.status == OrderStatus.failed ||
          order.status == OrderStatus.expired) {
        _timer?.cancel();
        emit(PaymentPollingFailed());
        return;
      }
    } catch (_) {
      // Transient network error — keep polling until the timeout below.
    }
    if (_attempts >= maxAttempts) {
      _timer?.cancel();
      emit(PaymentPollingFailed());
    }
  }

  void reset() {
    _timer?.cancel();
    emit(PaymentPollingIdle());
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
