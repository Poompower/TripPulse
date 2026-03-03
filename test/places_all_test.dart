import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sizer/sizer.dart';

// 👉 แก้ชื่อ package ให้ตรง pubspec.yaml ของคุณ
import 'package:trippulse/places/models/place.dart';
import 'package:trippulse/places/widgets/place_card_widget.dart';
import 'package:trippulse/places/widgets/search_bar_widget.dart';
import 'package:trippulse/places/widgets/filter_bottom_sheet_widget.dart';

void main() {
  // =========================
  // Place model test
  // =========================
  test('Place model stores values correctly', () {
    final place = Place(
      id: '1',
      name: 'Tokyo Tower',
      category: 'Monument',
      description: 'Landmark',
      lat: 35.0,
      lon: 139.0,
      country: 'Japan',
      imageUrl: null,
      distanceKm: 2.5,
    );

    expect(place.name, 'Tokyo Tower');
    expect(place.country, 'Japan');
    expect(place.distanceKm, 2.5);
  });

  // =========================
  // PlaceCardWidget test
  // =========================
  testWidgets('PlaceCardWidget shows name and add button',
    (WidgetTester tester) async {
  final place = Place(
    id: '1',
    name: 'Louvre Museum',
    category: 'Museum',
    description: '',
    lat: 0,
    lon: 0,
    country: 'France',
  );

  bool added = false;

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: PlaceCardWidget(
          place: place,
          onTap: () {},
          onAdd: () => added = true,
        ),
      ),
    ),
  );

  // ตรวจชื่อ
  expect(find.text('Louvre Museum'), findsOneWidget);

  // ตรวจว่ามี IconButton (ปุ่ม add)
  final addButton = find.byType(IconButton);
  expect(addButton, findsOneWidget);

  await tester.tap(addButton);
  expect(added, true);
});

  // =========================
  // SearchBarWidget test
  // =========================
  testWidgets('SearchBarWidget renders TextField',
      (WidgetTester tester) async {
    final controller = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchBarWidget(
            controller: controller,
            onSearch: () {},
            onOpenFilter: () {},
          ),
        ),
      ),
    );

    expect(find.byType(TextField), findsOneWidget);
  });

  // =========================
  // FilterBottomSheetWidget test
  // =========================
testWidgets('FilterBottomSheetWidget selects category',
    (WidgetTester tester) async {
    Set<String> result = {};

    await tester.pumpWidget(
      Sizer(
        builder: (context, orientation, deviceType) {
          return MaterialApp(
            home: Scaffold(
              body: FilterBottomSheetWidget(
                selectedCategories: {},
                onApplyFilters: (v) => result = v,
              ),
            ),
          );
        },
      ),
    );

    await tester.pumpAndSettle();

    // หา checkbox ตัวแรก (Museums)
    final checkbox = find.byType(CheckboxListTile).first;
    expect(checkbox, findsOneWidget);

    await tester.tap(checkbox);
    await tester.pumpAndSettle();

    // กด Apply
    await tester.tap(find.textContaining('Apply Filters'));
    await tester.pumpAndSettle();

    expect(result.isNotEmpty, true);
  });


}
