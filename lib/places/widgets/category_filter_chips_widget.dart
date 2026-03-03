import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Horizontal scrollable category filter chips
class CategoryFilterChipsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  final Set<String> selectedCategories;
  final ValueChanged<String> onCategoryToggle;

  const CategoryFilterChipsWidget({
    super.key,
    required this.categories,
    required this.selectedCategories,
    required this.onCategoryToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 6.h,
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        itemCount: categories.length,
        separatorBuilder: (context, index) => SizedBox(width: 2.w),
        itemBuilder: (context, index) {
          final category = categories[index];
          final categoryName = category['name'] as String;
          final count = category['count'] as int;
          final isSelected = selectedCategories.contains(categoryName);

          return FilterChip(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  categoryName,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                if (count > 0) ...[
                  SizedBox(width: 1.w),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 1.5.w,
                      vertical: 0.2.h,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.onPrimary.withValues(alpha: 0.2)
                          : theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      count.toString(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isSelected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            selected: isSelected,
            onSelected: (selected) => onCategoryToggle(categoryName),
            backgroundColor: theme.colorScheme.surface,
            selectedColor: theme.colorScheme.primary,
            side: BorderSide(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline,
              width: 1,
            ),
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          );
        },
      ),
    );
  }
}
