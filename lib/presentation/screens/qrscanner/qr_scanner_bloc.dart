import 'dart:convert';

import 'package:arunika_app/data/repositories/ar_repository.dart';
import 'package:arunika_app/presentation/screens/qrscanner/qr_scanner_event.dart';
import 'package:arunika_app/presentation/screens/qrscanner/qr_scanner_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class QRScannerBloc extends Bloc<QRScannerEvent, QRScannerState> {
  final ArRepository repository;

  QRScannerBloc({required this.repository}) : super(ModelInitial()) {
    on<FetchModelById>(_onFetchModelById);
  }

  Future<void> _onFetchModelById(
      FetchModelById event,
      Emitter<QRScannerState> emit,
      ) async {
    emit(ModelLoading());

    try {
      final response = await repository.findById(event.id);
      if (response.fileUrl != null) {
        emit(ModelLoaded(response.fileUrl!));
      } else {
        emit(const ModelError("Model not found"));
      }
    } catch (e) {
      emit(const ModelError("Server error"));
    }
  }
}