import 'package:arunika_app/constants/app_colors.dart';
import 'package:arunika_app/constants/app_text_styles.dart';
import 'package:arunika_app/core/growth/growth_format.dart';
import 'package:arunika_app/data/models/response/growth_response.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

/// "Hapus data pengukuran?" — resolves to true on "Ya, hapus".
Future<bool?> showDeleteMeasurementSheet(
  BuildContext context, {
  required GrowthMeasurement measurement,
  required String childName,
}) => showModalBottomSheet<bool>(
  context: context,
  useRootNavigator: true,
  // Sized to its content (with large text it is taller than the default
  // 9/16-screen cap), scrolling if it ever exceeds the screen.
  isScrollControlled: true,
  backgroundColor: AppColors.white,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
  ),
  builder: (_) =>
      DeleteMeasurementSheet(measurement: measurement, childName: childName),
);

class DeleteMeasurementSheet extends StatelessWidget {
  final GrowthMeasurement measurement;
  final String childName;

  const DeleteMeasurementSheet({
    super.key,
    required this.measurement,
    required this.childName,
  });

  @override
  Widget build(BuildContext context) {
    final values = [
      if (measurement.heightCm != null)
        '${formatDecimal(measurement.heightCm!)} cm',
      if (measurement.weightKg != null)
        '${formatDecimal(measurement.weightKg!)} kg',
    ].join(' · ');

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2DBD3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFFBE1DD),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Iconsax.trash, color: AppColors.discountRed),
              ),
              const SizedBox(height: 16),
              Text(
                'Hapus data pengukuran?',
                style: AppTextStyles.heading.copyWith(fontSize: 20),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              // The design's "Tindakan ini tidak bisa dibatalkan." is left out:
              // the delete can be undone from the "Urungkan" toast.
              Text(
                'Data ini akan dihapus dan grafik $childName diperbarui.',
                style: AppTextStyles.body.copyWith(color: AppColors.textMedium),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.warmPage,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            formatShortDate(measurement.measuredOn),
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            ageLabelShort(measurement.ageDays),
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      values,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFB3261E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    'Ya, hapus',
                    style: AppTextStyles.button.copyWith(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE2DBD3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'Batal',
                    style: AppTextStyles.button.copyWith(
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
