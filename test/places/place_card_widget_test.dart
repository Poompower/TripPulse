import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trippulse/places/models/place.dart';
import 'package:trippulse/places/widgets/place_card_widget.dart';

void main() {
  testWidgets('PlaceCardWidget renders place data and reacts to actions', (
    tester,
  ) async {
    final place = Place(
      id: 'p-1',
      name: 'Lumpini Park',
      category: 'leisure.park',
      description: 'Large urban park in Bangkok',
      lat: 13.73,
      lon: 100.54,
      distanceKm: 1.25,
      imageUrl: 'https://example.com/park.jpg',
      categories: const ['leisure.park'],
    );

    var tapCount = 0;
    var addCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlaceCardWidget(
            place: place,
            onTap: () => tapCount++,
            onAdd: () => addCount++,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Lumpini Park'), findsOneWidget);
    expect(find.text('leisure.park'), findsOneWidget);
    expect(find.textContaining('km from center'), findsOneWidget);

    await tester.tap(find.text('Lumpini Park'));
    await tester.pumpAndSettle();
    expect(tapCount, 1);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(addCount, 1);
  });
}
