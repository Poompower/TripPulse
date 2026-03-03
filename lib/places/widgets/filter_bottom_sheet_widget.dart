import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

// Bottom sheet for selecting Geoapify category keys.
class FilterBottomSheetWidget extends StatefulWidget {
  final Set<String> selectedCategories;
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
  late Set<String> _tempSelected;

  // Uses category keys supported by Geoapify.
  final List<Map<String, dynamic>> _categoryGroups = [
    {
      'title': 'Cultural & Historic',
      'items': [
        {'label': 'Museum', 'value': 'tourism.museum'},
        {'label': 'Gallery', 'value': 'tourism.gallery'},
        {'label': 'Monument', 'value': 'tourism.monument'},
        {
          'label': 'Archaeological Site',
          'value': 'tourism.archaeological_site',
        },
        {'label': 'Attraction', 'value': 'tourism.attraction'},
      ],
    },
    {
      'title': 'Food & Dining',
      'items': [
        {'label': 'Restaurant', 'value': 'catering.restaurant'},
        {'label': 'Cafe', 'value': 'catering.cafe'},
        {'label': 'Fast Food', 'value': 'catering.fast_food'},
        {'label': 'Bar', 'value': 'catering.bar'},
        {'label': 'Pub', 'value': 'catering.pub'},
      ],
    },
    {
      'title': 'Nature & Outdoors',
      'items': [
        {'label': 'Park', 'value': 'leisure.park'},
        {'label': 'Nature Reserve', 'value': 'leisure.nature_reserve'},
        {'label': 'Beach', 'value': 'natural.beach'},
        {'label': 'Garden', 'value': 'leisure.garden'},
        {'label': 'Viewpoint', 'value': 'tourism.viewpoint'},
      ],
    },
    {
      'title': 'Entertainment',
      'items': [
        {'label': 'Cinema', 'value': 'entertainment.cinema'},
        {'label': 'Theatre', 'value': 'entertainment.theatre'},
        {'label': 'Mall', 'value': 'commercial.shopping_mall'},
        {'label': 'Nightclub', 'value': 'entertainment.nightclub'},
      ],
    },
    {
      'title': 'Activities',
      'items': [
        {'label': 'Sports Centre', 'value': 'sport.sports_centre'},
        {'label': 'Stadium', 'value': 'sport.stadium'},
        {'label': 'Swimming Pool', 'value': 'sport.swimming'},
        {'label': 'Zoo', 'value': 'tourism.zoo'},
        {'label': 'Theme Park', 'value': 'tourism.theme_park'},
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _tempSelected = Set.from(widget.selectedCategories);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: BoxConstraints(maxHeight: 80.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          SizedBox(height: 1.5.h),
          Container(
            width: 12.w,
            height: 0.6.h,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
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
                    setState(() => _tempSelected.clear());
                  },
                  child: const Text('Clear All'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: _categoryGroups.length,
              itemBuilder: (_, index) {
                final group = _categoryGroups[index];
                return _buildGroup(context, group['title'], group['items']);
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(4.w),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onApplyFilters(_tempSelected);
                  Navigator.pop(context);
                },
                child: Text('Apply Filters (${_tempSelected.length})'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroup(BuildContext context, String title, List items) {
    final theme = Theme.of(context);

    return ExpansionTile(
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      initiallyExpanded: true,
      children: items.map<Widget>((item) {
        final String label = item['label'];
        final String value = item['value'];
        final isSelected = _tempSelected.contains(value);

        return CheckboxListTile(
          title: Text(label),
          value: isSelected,
          onChanged: (checked) {
            setState(() {
              if (checked == true) {
                _tempSelected.add(value);
              } else {
                _tempSelected.remove(value);
              }
            });
          },
          controlAffinity: ListTileControlAffinity.leading,
        );
      }).toList(),
    );
  }
}
