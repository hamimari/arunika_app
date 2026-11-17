import 'package:arunika_app/constants/app_colors.dart';
import 'package:arunika_app/constants/app_text_styles.dart';
import 'package:flutter/material.dart';

/// Safety warning shown immediately when the AR section launches, before the
/// AR camera session starts. Required by Google Play Families Policy
/// (Special restrictions: Augmented Reality): it must remind users about
/// parental supervision and being aware of their surroundings.
class ArSafetyWarning extends StatelessWidget {
  final VoidCallback onAccept;
  final VoidCallback onCancel;

  const ArSafetyWarning({
    required this.onAccept,
    required this.onCancel,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('⚠️', style: TextStyle(fontSize: 44)),
                  const SizedBox(height: 12),
                  Text(
                    'Peringatan Keselamatan AR',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.subheading.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    'AR Safety Warning',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMedium,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const _SafetyPoint(
                    emoji: '👨‍👩‍👧',
                    title: 'Gunakan dengan pengawasan orang tua',
                    subtitle:
                        'Anak-anak harus didampingi orang tua atau orang dewasa '
                        'saat menggunakan fitur AR.',
                    english:
                        'Children should use AR only with parental supervision.',
                  ),
                  const SizedBox(height: 14),
                  const _SafetyPoint(
                    emoji: '👀',
                    title: 'Perhatikan sekitarmu',
                    subtitle:
                        'Pastikan area sekitar aman dan bebas rintangan. Jangan '
                        'berjalan sambil melihat layar.',
                    english:
                        'Be aware of your surroundings. Do not walk while '
                        'looking at the screen.',
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onAccept,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryOrange,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Saya Mengerti',
                        style: AppTextStyles.buttonSmall,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: onCancel,
                    child: Text(
                      'Kembali',
                      style: AppTextStyles.buttonSmall.copyWith(
                        color: AppColors.textMedium,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SafetyPoint extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final String english;

  const _SafetyPoint({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.english,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 26)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textMedium,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                english,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textMedium,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
