import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sizer/sizer.dart';
import 'package:trippulse/places/widgets/filter_bottom_sheet_widget.dart';

Widget _wrapWithSizer(Widget child) {
  return Sizer(
    builder: (context, orientation, deviceType) {
      return MaterialApp(home: Scaffold(body: child));
    },
  );
}

void main() {
  testWidgets('FilterBottomSheetWidget clears and applies selected filters', (
    tester,
  ) async {
    Set<String>? applied;

    await tester.pumpWidget(
      _wrapWithSizer(
        FilterBottomSheetWidget(
          selectedCategories: const {'tourism.museum'},
          onApplyFilters: (value) => applied = value,
        ),
      ),
    );

    expect(find.text('Apply Filters (1)'), findsOneWidget);

    await tester.tap(find.text('Clear All'));
    await tester.pumpAndSettle();
    expect(find.text('Apply Filters (0)'), findsOneWidget);

    await tester.tap(find.text('Apply Filters (0)'));
    await tester.pumpAndSettle();

    expect(applied, isNotNull);
    expect(applied, isEmpty);
  });
}
