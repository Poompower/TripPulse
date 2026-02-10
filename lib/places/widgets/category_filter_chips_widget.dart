// หน้าที่ของไฟล์นี้:

// แสดง category เป็น chips

// เลือกหลายอันได้

// ไม่รู้จัก API / service

// ส่งผลกลับไปให้ screen จัดการเอง
import 'package:flutter/material.dart';

class CategoryFilterChipsWidget extends StatelessWidget {
  final Set<String> selectedCategories;
  final ValueChanged<Set<String>> onChanged;

  const CategoryFilterChipsWidget({
    super.key,
    required this.selectedCategories,
    required this.onChanged,
  });

  static const List<String> _categories = [
    'Museums',
    'Historic',
    'Restaurants',
    'Parks',
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: _categories.map((cat) {
          final selected = selectedCategories.contains(cat);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(cat),
              selected: selected,
              onSelected: (v) {
                final next = Set<String>.from(selectedCategories);
                v ? next.add(cat) : next.remove(cat);
                onChanged(next);
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}
