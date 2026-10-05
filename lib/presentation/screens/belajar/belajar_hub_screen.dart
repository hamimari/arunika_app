import 'package:arunika_app/constants/app_colors.dart';
import 'package:arunika_app/constants/app_strings.dart';
import 'package:arunika_app/constants/app_text_styles.dart';
import 'package:arunika_app/core/auth/auth_notifier.dart';
import 'package:arunika_app/core/feature_flags/feature_flags_notifier.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:arunika_app/presentation/screens/angka/angka_cubit.dart';
import 'package:arunika_app/presentation/screens/angka/angka_widgets.dart';
import 'package:arunika_app/presentation/screens/belajar/belajar_tab.dart';
import 'package:arunika_app/presentation/screens/huruf/huruf_cubit.dart';
import 'package:arunika_app/presentation/screens/huruf/huruf_widgets.dart';
import 'package:arunika_app/presentation/screens/widgets/login_required_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';

/// "Belajar — Pilih petualangan belajar hari ini!": one card per learning
/// feature. Stimulasi Bayi joins here when it ships.
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
            _AngkaCard(onOpen: () => onOpen(BelajarDestination.angka)),
            _HurufCard(onOpen: () => onOpen(BelajarDestination.huruf)),
          ],
        ),
      ),
    );
  }
}

/// Belajar Angka: shown when `belajar_angka` is on, with a "Premium" badge
/// for anyone without Akses Premium. Guests are asked to sign in first,
/// since progress belongs to a child.
class _AngkaCard extends StatelessWidget {
  final VoidCallback onOpen;

  const _AngkaCard({required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final flags = locator<FeatureFlagsNotifier>();
    final cubit = context.read<AngkaCubit?>();
    return ListenableBuilder(
      listenable: flags,
      builder: (context, _) {
        if (!flags.belajarAngkaEnabled) return const SizedBox.shrink();
        Widget card(bool premium) => Padding(
          padding: const EdgeInsets.only(top: 14),
          child: _BelajarCard(
            key: const ValueKey('belajar-angka-card'),
            title: AppStrings.angkaCardTitle,
            description: AppStrings.angkaCardDescription,
            action: AppStrings.angkaCardAction,
            background: AngkaColors.sky,
            accent: AngkaColors.blue,
            icon: Icons.numbers_rounded,
            badge: premium ? null : AppStrings.angkaPremium,
            onTap: () {
              if (!locator<AuthNotifier>().isLoggedIn) {
                showLoginRequiredDialog(
                  context,
                  featureLabel: AppStrings.angkaTitle,
                );
                return;
              }
              onOpen();
            },
          ),
        );
        if (cubit == null) return card(false);
        return BlocBuilder<AngkaCubit, AngkaState>(
          bloc: cubit,
          buildWhen: (a, b) => a.premium != b.premium,
          builder: (_, state) => card(state.premium),
        );
      },
    );
  }
}

/// Belajar Huruf: shown when `belajar_huruf` is on, with a "Premium" badge
/// for anyone without Akses Premium. Guests are asked to sign in first,
/// since progress belongs to a child.
class _HurufCard extends StatelessWidget {
  final VoidCallback onOpen;

  const _HurufCard({required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final flags = locator<FeatureFlagsNotifier>();
    final cubit = context.read<HurufCubit?>();
    return ListenableBuilder(
      listenable: flags,
      builder: (context, _) {
        if (!flags.belajarHurufEnabled) return const SizedBox.shrink();
        Widget card(bool premium) => Padding(
          padding: const EdgeInsets.only(top: 14),
          child: _BelajarCard(
            title: AppStrings.hurufCardTitle,
            description: AppStrings.hurufCardDescription,
            action: 'Buka',
            background: HurufColors.mint,
            accent: HurufColors.teal,
            icon: Icons.abc_rounded,
            badge: premium ? null : AppStrings.hurufPremium,
            onTap: () {
              if (!locator<AuthNotifier>().isLoggedIn) {
                showLoginRequiredDialog(
                  context,
                  featureLabel: AppStrings.hurufTitle,
                );
                return;
              }
              onOpen();
            },
          ),
        );
        if (cubit == null) return card(false);
        return BlocBuilder<HurufCubit, HurufState>(
          bloc: cubit,
          buildWhen: (a, b) => a.premium != b.premium,
          builder: (_, state) => card(state.premium),
        );
      },
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

  /// A small chip next to the title, e.g. "Premium".
  final String? badge;

  const _BelajarCard({
    super.key,
    required this.title,
    required this.description,
    required this.action,
    required this.background,
    required this.accent,
    required this.icon,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: badge == null
          ? '$title. $description'
          : '$title, $badge. $description',
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
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: AppTextStyles.heading.copyWith(
                                fontSize: 20,
                              ),
                            ),
                          ),
                          if (badge != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.premiumBadgeBg,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                badge!,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.mediumBrown,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
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
