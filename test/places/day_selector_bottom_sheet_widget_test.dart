import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trippulse/places/models/place.dart';
import 'package:trippulse/places/widgets/day_selector_bottom_sheet_widget.dart';
import 'package:trippulse/trips/models/trip.dart';

void main() {
  Place buildPlace() {
    return Place(
      id: 'place-1',
      name: 'Wat Arun',
      category: 'tourism.attraction',
      description: 'Temple in Bangkok',
      lat: 13.7437,
      lon: 100.4889,
      categories: const ['tourism.attraction'],
    );
  }

  test('DaySelectorBottomSheetWidget.totalDays supports ISO date format', () {
    final widget = DaySelectorBottomSheetWidget(
      place: buildPlace(),
      trip: Trip(
        title: 'Bangkok',
        destination: 'Bangkok, Thailand',
        startDate: '2026-03-10',
        endDate: '2026-03-12',
        currency: 'THB',
        budget: 1000,
      ),
    );

    expect(widget.totalDays, 3);
  });

  test('DaySelectorBottomSheetWidget.totalDays supports formatted date', () {
    final widget = DaySelectorBottomSheetWidget(
      place: buildPlace(),
      trip: Trip(
        title: 'Tokyo',
        destination: 'Tokyo, Japan',
        startDate: 'Mar 10, 2026',
        endDate: 'Mar 13, 2026',
        currency: 'JPY',
        budget: 2000,
      ),
    );

    expect(widget.totalDays, 4);
  });

  testWidgets('DaySelectorBottomSheetWidget builds list items by day count', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DaySelectorBottomSheetWidget(
            place: buildPlace(),
            trip: Trip(
              title: 'Paris',
              destination: 'Paris, France',
              startDate: '2026-03-10',
              endDate: '2026-03-11',
              currency: 'EUR',
              budget: 3000,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Add to itinerary'), findsOneWidget);
    expect(find.text('Day 1'), findsOneWidget);
    expect(find.text('Day 2'), findsOneWidget);
  });
}
