// ไฟล์นี้ทำหน้าที่:

// search text

// กด enter เพื่อ search

// ปุ่ม filter แยกชัดเจน (ไม่ยิง search มั่ว)

// ไม่มี logic ธุรกิจ ปล่อยให้ screen คุม
import 'package:flutter/material.dart';

class SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSearch;
  final VoidCallback onOpenFilter;

  const SearchBarWidget({
    super.key,
    required this.controller,
    required this.onSearch,
    required this.onOpenFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => onSearch(),
        decoration: InputDecoration(
          hintText: 'Search attractions',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: onOpenFilter,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
