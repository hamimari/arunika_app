import 'dart:math';

import 'package:arunika_app/core/growth/growth_engine.dart';
import 'package:arunika_app/data/api/growth_api.dart';
import 'package:arunika_app/data/models/response/growth_response.dart';
import 'package:dio/dio.dart';

/// Values entered in the Tambah / Edit Pengukuran form.
class MeasurementInput {
  final DateTime measuredOn;
  final double? heightCm;
  final double? weightKg;
  final Position position;

  const MeasurementInput({
    required this.measuredOn,
    this.heightCm,
    this.weightKg,
    required this.position,
  });

  /// Edits send every field, so a cleared value is sent as null.
  Map<String, dynamic> toJson({bool confirmOutlier = false}) => {
    'measured_on':
        '${measuredOn.year.toString().padLeft(4, '0')}-'
        '${measuredOn.month.toString().padLeft(2, '0')}-'
        '${measuredOn.day.toString().padLeft(2, '0')}',
    'height_cm': heightCm,
    'weight_kg': weightKg,
    'position': position == Position.recumbent ? 'recumbent' : 'standing',
    'confirm_outlier': confirmOutlier,
  };
}

/// A save the backend refused (422), or a network failure (`code == null`).
class GrowthSaveException implements Exception {
  /// `PROFILE_INCOMPLETE`, `DATE_OUT_OF_RANGE`, `VALUE_REQUIRED`,
  /// `OUTLIER_NEEDS_CONFIRM`, … or null when the request never got an answer.
  final String? code;
  const GrowthSaveException(this.code);

  bool get needsOutlierConfirm => code == 'OUTLIER_NEEDS_CONFIRM';
  bool get isNetwork => code == null;

  @override
  String toString() => 'GrowthSaveException($code)';
}

class GrowthRepository {
  final GrowthApi api;

  GrowthRepository(this.api);

  Future<GrowthSummary> fetchSummary(String childId) async =>
      GrowthSummary.fromJson(await api.fetchSummary(childId));

  /// [clientId] makes a retried save idempotent: reuse it when the parent
  /// taps Simpan again after a failure.
  Future<GrowthMeasurement> create(
    String childId,
    MeasurementInput input, {
    required String clientId,
    bool confirmOutlier = false,
  }) => _guard(() async {
    final body = input.toJson(confirmOutlier: confirmOutlier)
      ..['client_id'] = clientId;
    return GrowthMeasurement.fromJson(await api.create(childId, body));
  });

  Future<GrowthMeasurement> update(
    String childId,
    String id,
    MeasurementInput input, {
    bool confirmOutlier = false,
  }) => _guard(
    () async => GrowthMeasurement.fromJson(
      await api.update(
        childId,
        id,
        input.toJson(confirmOutlier: confirmOutlier),
      ),
    ),
  );

  Future<void> delete(String childId, String id) =>
      _guard(() => api.delete(childId, id));

  Future<void> restore(String childId, String id) =>
      _guard(() => api.restore(childId, id));

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      final data = e.response?.data;
      if (e.response != null) {
        throw GrowthSaveException(
          data is Map && data['code'] is String
              ? data['code'] as String
              : 'HTTP_${e.response!.statusCode}',
        );
      }
      throw const GrowthSaveException(null);
    }
  }
}

/// A random RFC 4122 version-4 UUID, for `client_id`.
String newClientId([Random? random]) {
  final r = random ?? Random.secure();
  final b = List<int>.generate(16, (_) => r.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-'
      '${h.substring(16, 20)}-${h.substring(20)}';
}
