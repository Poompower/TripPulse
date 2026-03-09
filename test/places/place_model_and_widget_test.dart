import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trippulse/places/models/place.dart';
import 'package:trippulse/places/widgets/empty_search_state_widget.dart';

void main() {
  test('Place fromGeoapify parses key fields', () {
    final place = Place.fromGeoapify({
      'properties': {
        'place_id': 'p1',
        'name': 'Louvre Museum',
        'formatted': 'Paris, France',
        'lat': 48.8606,
        'lon': 2.3376,
        'country': 'France',
        'country_code': 'fr',
        'categories': ['tourism.museum', 'tourism.attraction'],
      },
    });

    expect(place.id, 'p1');
    expect(place.name, 'Louvre Museum');
    expect(place.category, 'tourism.museum');
    expect(place.countryCode, 'FR');
    expect(place.categories, contains('tourism.attraction'));
  });

  test('Place json roundtrip keeps categories', () {
    final place = Place(
      id: '2',
      name: 'Temple',
      category: 'tourism.attraction',
      description: 'Historic temple',
      lat: 10.0,
      lon: 20.0,
      categories: const ['tourism.attraction'],
    );

    final restored = Place.fromJson(place.toJson());
    expect(restored.categories, ['tourism.attraction']);
    expect(restored.name, 'Temple');
  });

  testWidgets('EmptySearchStateWidget shows guidance text', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: EmptySearchStateWidget())),
    );

    expect(find.text('Search for attractions or places'), findsOneWidget);
    expect(find.byIcon(Icons.travel_explore), findsOneWidget);
  });
}
