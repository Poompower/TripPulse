import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Bottom sheet for category filtering
/// - UI layer only
/// - Returns Geoapify category keys
class FilterBottomSheetWidget extends StatefulWidget {
  /// Selected Geoapify categories (e.g. tourism.museum)
  final Set<String> selectedCategories;

  /// Callback returns Geoapify category keys
  final ValueChanged<Set<String>> onApplyFilters;

  const FilterBottomSheetWidget({
    super.key,
    required this.selectedCategories,
    required this.onApplyFilters,
  });

  @override
  State<FilterBottomSheetWidget> createState() =>
      _FilterBottomSheetWidgetState();
}

class _FilterBottomSheetWidgetState extends State<FilterBottomSheetWidget> {
  late Set<String> _tempSelectedCategories;

  /// Category groups
  /// label = UI text
  /// values = Geoapify categories
  final List<Map<String, dynamic>> _categoryGroups = [
    {
      'title': 'Cultural & Historic',
      'items': [
        {
          'label': 'Museums',
          'values': ['tourism.museum'],
        },
        {
          'label': 'Historic Sites',
          'values': ['heritage', 'tourism.attraction'],
        },
        {
          'label': 'Art Galleries',
          'values': ['tourism.gallery'],
        },
        {
          'label': 'Monuments',
          'values': ['tourism.monument'],
        },
      ],
    },
    {
      'title': 'Food & Dining',
      'items': [
        {
          'label': 'Restaurants',
          'values': ['catering.restaurant'],
        },
        {
          'label': 'Cafes',
          'values': ['catering.cafe'],
        },
        {
          'label': 'Bars',
          'values': ['catering.bar'],
        },
        {
          'label': 'Food Markets',
          'values': ['commercial.marketplace'],
        },
      ],
    },
    {
      'title': 'Nature & Outdoors',
      'items': [
        {
          'label': 'Parks',
          'values': ['leisure.park'],
        },
        {
          'label': 'Beaches',
          'values': ['natural.beach'],
        },
        {
          'label': 'Gardens',
          'values': ['leisure.garden'],
        },
        {
          'label': 'Viewpoints',
          'values': ['tourism.viewpoint'],
        },
      ],
    },
    {
      'title': 'Entertainment',
      'items': [
        {
          'label': 'Theaters',
          'values': ['entertainment.theatre'],
        },
        {
          'label': 'Cinemas',
          'values': ['entertainment.cinema'],
        },
        {
          'label': 'Shopping',
          'values': ['commercial.shopping_mall'],
        },
        {
          'label': 'Nightlife',
          'values': ['entertainment.nightclub'],
        },
      ],
    },
    {
      'title': 'Activities',
      'items': [
        {
          'label': 'Sports',
          'values': ['sport'],
        },
        {
          'label': 'Adventure',
          'values': ['tourism.attraction'],
        },
        {
          'label': 'Tours',
          'values': ['tourism.information'],
        },
        {
          'label': 'Workshops',
          'values': ['craft'],
        },
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _tempSelectedCategories = Set.from(widget.selectedCategories);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: BoxConstraints(maxHeight: 80.h ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: 2.h),
            width: 12.w,
            height: 0.5.h,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter Categories',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _tempSelectedCategories.clear();
                    });
                  },
                  child: const Text('Clear All'),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Category groups
          Flexible(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 2.h),
              itemCount: _categoryGroups.length,
              itemBuilder: (context, index) {
                final group = _categoryGroups[index];
                return _buildCategoryGroup(
                  context,
                  group['title'] as String,
                  group['items'] as List<Map<String, dynamic>>,
                );
              },
            ),
          ),

          // Apply button
          Container(
            padding: EdgeInsets.all(4.w),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApplyFilters(_tempSelectedCategories);
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Apply Filters${_tempSelectedCategories.isNotEmpty ? ' (${_tempSelectedCategories.length})' : ''}',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGroup(
    BuildContext context,
    String title,
    List<Map<String, dynamic>> items,
  ) {
    final theme = Theme.of(context);

    return ExpansionTile(
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      initiallyExpanded: true,
      children: items.map((item) {
        final label = item['label'] as String;
        final values = item['values'] as List<String>;

        final isSelected =
            values.any((v) => _tempSelectedCategories.contains(v));

        return CheckboxListTile(
          title: Text(label),
          value: isSelected,
          onChanged: (checked) {
            setState(() {
              if (checked == true) {
                _tempSelectedCategories.addAll(values);
              } else {
                _tempSelectedCategories.removeAll(values);
              }
            });
          },
          controlAffinity: ListTileControlAffinity.leading,
        );
      }).toList(),
    );
  }
}
