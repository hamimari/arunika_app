import 'package:arunika_app/constants/app_colors.dart';
import 'package:arunika_app/constants/app_strings.dart';
import 'package:arunika_app/constants/app_text_styles.dart';
import 'package:arunika_app/presentation/screens/belajar/belajar_tab.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

/// "Belajar — Pilih petualangan belajar hari ini!": one card per learning
/// feature. Stimulasi Bayi, Angka and Huruf join here when they ship.
class BelajarHubScreen extends StatelessWidget {
  final ValueChanged<BelajarDestination> onOpen;

  const BelajarHubScreen({super.key, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmPage,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          children: [
            Text(AppStrings.navBelajar, style: AppTextStyles.displayLarge),
            const SizedBox(height: 2),
            Text(
              AppStrings.belajarSubtitle,
              style: AppTextStyles.body.copyWith(color: AppColors.textMedium),
            ),
            const SizedBox(height: 20),
            _BelajarCard(
              title: AppStrings.navCollection,
              description: 'Lihat hewan jadi nyata lewat kamera',
              action: 'Buka',
              background: const Color(0xFFFDE7D6),
              accent: AppColors.ctaRust,
              icon: Iconsax.box_1,
              onTap: () => onOpen(BelajarDestination.kartuAr),
            ),
            const SizedBox(height: 14),
            _BelajarCard(
              title: AppStrings.navDongeng,
              description: 'Cerita seru penuh pesan baik',
              action: 'Buka',
              background: const Color(0xFFEDE8F8),
              accent: const Color(0xFF6A4FB3),
              icon: Iconsax.book_1,
              onTap: () => onOpen(BelajarDestination.dongeng),
            ),
          ],
        ),
      ),
    );
  }
}

class _BelajarCard extends StatelessWidget {
  final String title;
  final String description;
  final String action;
  final Color background;
  final Color accent;
  final IconData icon;
  final VoidCallback onTap;

  const _BelajarCard({
    required this.title,
    required this.description,
    required this.action,
    required this.background,
    required this.accent,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title. $description',
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 14, 18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.heading.copyWith(fontSize: 20),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textDark.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            action,
                            style: AppTextStyles.button.copyWith(
                              color: accent,
                              fontSize: 15,
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, color: accent),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(icon, color: accent, size: 40),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
