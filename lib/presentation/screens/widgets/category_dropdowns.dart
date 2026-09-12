import 'package:flutter/material.dart';
import 'package:arunika_app/constants/app_colors.dart';
import 'package:arunika_app/constants/app_text_styles.dart';

/// Minimal, model-agnostic shape the shared dropdown row needs — callers map
/// their own category type (e.g. `ArCardCategory`, `DongengCategory`) into
/// this instead of the widget depending on either domain model directly.
class CategoryOption {
  final String id;
  final String name;
  final String emoji;
  final List<CategoryOption> children;

  const CategoryOption({
    required this.id,
    required this.name,
    this.emoji = '',
    this.children = const [],
  });
}

/// Two-level category filter row: a "Semua Kategori" dropdown, plus a second
/// dropdown for sub-categories that only appears once the selected top-level
/// category has children. Shared by the collection (AR card) screen and the
/// dongeng screen so both filter the same way.
class CategoryDropdowns extends StatelessWidget {
  final List<CategoryOption> categories;
  final String? activeCategoryId;
  final String? activeSubCategoryId;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String?> onSubCategoryChanged;

  const CategoryDropdowns({
    super.key,
    required this.categories,
    required this.activeCategoryId,
    required this.activeSubCategoryId,
    required this.onCategoryChanged,
    required this.onSubCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    CategoryOption? activeCat;
    try {
      activeCat = activeCategoryId != null
          ? categories.firstWhere((c) => c.id == activeCategoryId)
          : null;
    } catch (_) {}
    final hasSubs = activeCat != null && activeCat.children.isNotEmpty;

    return Row(
      children: [
        Expanded(
          child: _StyledDropdown<String?>(
            value: activeCategoryId,
            hint: 'Semua Kategori',
            items: [
              const DropdownMenuItem(value: null, child: Text('Semua')),
              ...categories.map(
                (cat) => DropdownMenuItem(
                  value: cat.id,
                  child: Text('${cat.emoji} ${cat.name}'.trim()),
                ),
              ),
            ],
            onChanged: onCategoryChanged,
          ),
        ),
        if (hasSubs) ...[
          const SizedBox(width: 8),
          Expanded(
            child: _StyledDropdown<String?>(
              value: activeSubCategoryId,
              hint: 'Semua Sub',
              items: [
                const DropdownMenuItem(value: null, child: Text('Semua')),
                ...activeCat.children.map(
                  (sub) => DropdownMenuItem(
                    value: sub.id,
                    child: Text('${sub.emoji} ${sub.name}'.trim()),
                  ),
                ),
              ],
              onChanged: onSubCategoryChanged,
            ),
          ),
        ],
      ],
    );
  }
}

class _StyledDropdown<T> extends StatelessWidget {
  final T value;
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _StyledDropdown({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.lockGrey, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(
            hint,
            style: AppTextStyles.caption.copyWith(color: AppColors.textMedium),
          ),
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.primaryOrange,
            size: 20,
          ),
          style: AppTextStyles.caption.copyWith(color: AppColors.textDark),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

/// Gear/settings icon button placed beside [CategoryDropdowns] to open the
/// ownership filter bottom sheet (see `ownership_filter_sheet.dart`).
class FilterIconButton extends StatelessWidget {
  final VoidCallback onTap;

  const FilterIconButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.lockGrey, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.settings_rounded,
          color: AppColors.primaryOrange,
          size: 22,
        ),
      ),
    );
  }
}
