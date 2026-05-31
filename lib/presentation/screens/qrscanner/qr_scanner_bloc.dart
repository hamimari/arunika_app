import 'package:arunika_app/data/repositories/ar_repository.dart';
import 'package:arunika_app/presentation/screens/qrscanner/qr_scanner_event.dart';
import 'package:arunika_app/presentation/screens/qrscanner/qr_scanner_state.dart';
import 'package:dio/dio.dart';
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
        final soundUrl = (response.audioUrl?.isNotEmpty == true)
            ? response.audioUrl
            : null;
        emit(ModelLoaded(response.fileUrl!, soundUrl: soundUrl));
      } else {
        emit(const ModelError("Model not found"));
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        emit(const ModelUnauthorized());
      } else {
        emit(const ModelError("Server error"));
      }
    } catch (e) {
      emit(const ModelError("Server error"));
    }
  }
}
