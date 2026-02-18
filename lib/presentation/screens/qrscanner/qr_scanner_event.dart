import 'package:equatable/equatable.dart';

abstract class QRScannerEvent extends Equatable {
  const QRScannerEvent();

  @override
  List<Object> get props => [];
}

class FetchModelById extends QRScannerEvent {
  final String id;

  const FetchModelById(this.id);

  @override
  List<Object> get props => [id];
}