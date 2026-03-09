import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sizer/sizer.dart';
import 'package:trippulse/places/widgets/category_filter_chips_widget.dart';

Widget _wrapWithSizer(Widget child) {
  return Sizer(
    builder: (context, orientation, deviceType) {
      return MaterialApp(home: Scaffold(body: child));
    },
  );
}

void main() {
  testWidgets('CategoryFilterChipsWidget renders names and count badges', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrapWithSizer(
        CategoryFilterChipsWidget(
          categories: const [
            {'name': 'Museum', 'count': 3},
            {'name': 'Park', 'count': 0},
          ],
          selectedCategories: const {'Museum'},
          onCategoryToggle: (_) {},
        ),
      ),
    );

    expect(find.text('Museum'), findsOneWidget);
    expect(find.text('Park'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('CategoryFilterChipsWidget calls callback on chip tap', (
    tester,
  ) async {
    String? selected;

    await tester.pumpWidget(
      _wrapWithSizer(
        CategoryFilterChipsWidget(
          categories: const [
            {'name': 'Museum', 'count': 1},
            {'name': 'Cafe', 'count': 2},
          ],
          selectedCategories: const {},
          onCategoryToggle: (value) => selected = value,
        ),
      ),
    );

    await tester.tap(find.widgetWithText(FilterChip, 'Cafe'));
    await tester.pumpAndSettle();

    expect(selected, 'Cafe');
  });
}
