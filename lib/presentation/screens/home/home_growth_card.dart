import 'package:arunika_app/constants/app_colors.dart';
import 'package:arunika_app/constants/app_text_styles.dart';
import 'package:arunika_app/core/growth/growth_format.dart';
import 'package:arunika_app/presentation/navigation/main_shell.dart';
import 'package:arunika_app/presentation/screens/growth/growth_cubit.dart';
import 'package:arunika_app/presentation/screens/growth/growth_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Beranda's "Tumbuh kembang {nama}" card. Renders nothing for guests, while
/// `growth_tracking` is off, before the first load, or outside the shell.
class HomeGrowthCard extends StatelessWidget {
  const HomeGrowthCard({super.key});

  @override
  Widget build(BuildContext context) {
    // Nullable lookup: the card is optional wherever no GrowthCubit exists.
    final cubit = context.read<GrowthCubit?>();
    if (cubit == null) return const SizedBox.shrink();
    return BlocBuilder<GrowthCubit, GrowthState>(
      bloc: cubit,
      builder: (context, state) {
        final child = state.child;
        if (state.status == GrowthStatus.hidden || child == null) {
          return const SizedBox.shrink();
        }
        final newest = state.newest;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: newest == null || !state.profileComplete
              ? _EmptyGrowthCard(
                  childName: child.name,
                  // An incomplete profile is explained on the Tumbuh tab.
                  onTap: state.profileComplete
                      ? () => openMeasurementForm(context)
                      : _openTumbuh,
                )
              : _GrowthSummaryCard(state: state),
        );
      },
    );
  }
}

void _openTumbuh() =>
    MainShell.shellKey.currentState?.switchTab(MainShellTab.tumbuh);

class _GrowthSummaryCard extends StatelessWidget {
  final GrowthState state;
  const _GrowthSummaryCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final newest = state.newest!;
    final h = state.latestHeight, w = state.latestWeight;
    return Semantics(
      button: true,
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: _openTumbuh,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    const _SproutIcon(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tumbuh kembang ${state.child!.name}',
                            style: AppTextStyles.subheading,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Diukur ${formatShortDate(newest.measuredOn)} · '
                            '${ageLabelShort(newest.ageDays)}',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _MiniTile(
                        label: 'Tinggi',
                        value: valueWithUnit(h?.value, 'cm'),
                        category: h?.category,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MiniTile(
                        label: 'Berat',
                        value: valueWithUnit(w?.value, 'kg'),
                        category: w?.category,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniTile extends StatelessWidget {
  final String label;
  final String value;
  final String? category;
  const _MiniTile({
    required this.label,
    required this.value,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warmPage,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textMedium,
                  ),
                ),
              ),
              Flexible(child: CategoryChip(category: category)),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.heading.copyWith(fontSize: 20)),
        ],
      ),
    );
  }
}

class _EmptyGrowthCard extends StatelessWidget {
  final String childName;
  final VoidCallback onTap;
  const _EmptyGrowthCard({required this.childName, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SproutIcon(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pantau tumbuh kembang $childName',
                        style: AppTextStyles.subheading,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Catat tinggi dan berat pertama untuk melihat grafik '
                        'sesuai standar WHO.',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.ctaRustSoft,
                  side: const BorderSide(color: AppColors.ctaRust, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: onTap,
                icon: const Icon(Icons.add_rounded, color: AppColors.ctaRust),
                label: Text(
                  'Catat pengukuran pertama',
                  style: AppTextStyles.button.copyWith(
                    color: AppColors.ctaRust,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SproutIcon extends StatelessWidget {
  const _SproutIcon();

  @override
  Widget build(BuildContext context) => Container(
    width: 44,
    height: 44,
    decoration: BoxDecoration(
      color: GrowthPalette.greenSoft,
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Icon(Icons.spa_outlined, color: GrowthPalette.green),
  );
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(22),
    );
    canvas.drawRRect(rrect, Paint()..color = AppColors.white);
    final path = Path()..addRRect(rrect.deflate(0.75));
    final paint = Paint()
      ..color = const Color(0xFFB9DCC4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 10) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
