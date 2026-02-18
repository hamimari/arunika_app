import 'package:equatable/equatable.dart';

abstract class QRScannerState extends Equatable {
  const QRScannerState();

  @override
  List<Object?> get props => [];
}

class ModelInitial extends QRScannerState {}

class ModelLoading extends QRScannerState {}

class ModelLoaded extends QRScannerState {
  final String modelUrl;

  const ModelLoaded(this.modelUrl);

  @override
  List<Object?> get props => [modelUrl];
}

class ModelError extends QRScannerState {
  final String message;

  const ModelError(this.message);

  @override
  List<Object?> get props => [message];
}