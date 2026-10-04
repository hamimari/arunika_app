import 'package:arunika_app/constants/app_colors.dart';
import 'package:arunika_app/constants/app_text_styles.dart';
import 'package:arunika_app/core/growth/growth_format.dart';
import 'package:arunika_app/data/models/response/growth_response.dart';
import 'package:arunika_app/presentation/screens/growth/delete_measurement_sheet.dart';
import 'package:arunika_app/presentation/screens/growth/growth_cubit.dart';
import 'package:arunika_app/presentation/screens/growth/measurement_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Status chip: the category label on its colour. Never colour alone.
class CategoryChip extends StatelessWidget {
  final String? category;
  const CategoryChip({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final c = category;
    if (c == null) return const SizedBox.shrink();
    final style = categoryStyle(c);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        style.label,
        style: AppTextStyles.caption.copyWith(
          color: style.foreground,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

/// Two-option pill switch (chart indicator, measuring position).
class GrowthSegmentedSwitch extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;

  const GrowthSegmentedSwitch({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF2ECE5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: Semantics(
                button: true,
                selected: i == selected,
                child: GestureDetector(
                  onTap: () => onChanged(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i == selected ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Text(
                      labels[i],
                      style: AppTextStyles.body.copyWith(
                        fontWeight: i == selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: i == selected
                            ? AppColors.textDark
                            : AppColors.textMedium,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// White rounded card used throughout the growth screens.
class GrowthCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const GrowthCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Opens Tambah Pengukuran, or Edit Pengukuran for [existing]. A delete chosen
/// from the edit form runs [deleteMeasurementWithUndo] on return.
Future<void> openMeasurementForm(
  BuildContext context, {
  GrowthMeasurement? existing,
}) async {
  final cubit = context.read<GrowthCubit>();
  final result = await Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<MeasurementFormResult>(
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: MeasurementFormScreen(existing: existing),
      ),
    ),
  );
  if (result == MeasurementFormResult.deleteRequested &&
      existing != null &&
      context.mounted) {
    await deleteMeasurementWithUndo(context, existing, confirmed: true);
  }
}

/// Confirms (unless [confirmed]), deletes at once, and offers "Urungkan" for
/// 5 seconds.
Future<void> deleteMeasurementWithUndo(
  BuildContext context,
  GrowthMeasurement m, {
  bool confirmed = false,
}) async {
  final cubit = context.read<GrowthCubit>();
  final childName = cubit.state.child?.name ?? '';
  if (!confirmed) {
    final ok = await showDeleteMeasurementSheet(
      context,
      measurement: m,
      childName: childName,
    );
    if (ok != true || !context.mounted) return;
  }
  final messenger = ScaffoldMessenger.of(context);
  final deleted = cubit.delete(m.id);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: const Text('Data pengukuran dihapus'),
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Urungkan',
          textColor: AppColors.navActivePill,
          onPressed: () async {
            if (await deleted) await cubit.restore(m.id);
          },
        ),
      ),
    );
  if (!await deleted) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Gagal menghapus. Periksa koneksi, lalu coba lagi.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}

/// "94,8 cm".
String valueWithUnit(double? v, String unit) =>
    v == null ? '–' : '${formatDecimal(v)} $unit';
