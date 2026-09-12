import 'package:flutter/material.dart';
import 'package:arunika_app/constants/app_colors.dart';
import 'package:arunika_app/constants/app_text_styles.dart';

/// Opens the shared "Filter" bottom sheet — a single "Kepemilikan" (ownership)
/// choice between "Semua" and "Koleksiku" — used by both the collection (AR
/// card) and dongeng screens in place of the old "Sudah dibeli saja" chip.
/// The choice only takes effect when the user taps "Terapkan".
Future<void> showOwnershipFilterSheet(
  BuildContext context, {
  required bool currentOwnedOnly,
  required ValueChanged<bool> onApply,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _OwnershipFilterSheet(
      currentOwnedOnly: currentOwnedOnly,
      onApply: onApply,
    ),
  );
}

class _OwnershipFilterSheet extends StatefulWidget {
  final bool currentOwnedOnly;
  final ValueChanged<bool> onApply;

  const _OwnershipFilterSheet({
    required this.currentOwnedOnly,
    required this.onApply,
  });

  @override
  State<_OwnershipFilterSheet> createState() => _OwnershipFilterSheetState();
}

class _OwnershipFilterSheetState extends State<_OwnershipFilterSheet> {
  late bool _selected = widget.currentOwnedOnly;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filter', style: AppTextStyles.subheading),
            const SizedBox(height: 16),
            Text(
              'Kepemilikan',
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            RadioListTile<bool>(
              contentPadding: EdgeInsets.zero,
              title: Text('Semua', style: AppTextStyles.body),
              value: false,
              groupValue: _selected,
              activeColor: AppColors.primaryOrange,
              onChanged: (v) => setState(() => _selected = v ?? false),
            ),
            RadioListTile<bool>(
              contentPadding: EdgeInsets.zero,
              title: Text('Koleksiku', style: AppTextStyles.body),
              value: true,
              groupValue: _selected,
              activeColor: AppColors.primaryOrange,
              onChanged: (v) => setState(() => _selected = v ?? false),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  widget.onApply(_selected);
                  Navigator.of(context).pop();
                },
                child: Text('Terapkan', style: AppTextStyles.button),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
