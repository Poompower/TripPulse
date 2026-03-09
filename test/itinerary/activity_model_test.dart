import 'package:flutter_test/flutter_test.dart';
import 'package:trippulse/itenaries/models/activity.dart';

void main() {
  test('Activity map roundtrip keeps key fields', () {
    final activity = Activity(
      id: 'a1',
      tripId: 't1',
      dayNumber: 2,
      title: 'Visit Museum',
      location: 'City Center',
      time: '10:30',
      imageUrl: 'https://example.com/image.jpg',
      category: 'Museum',
      lat: 13.7563,
      lon: 100.5018,
    );

    final map = activity.toMap();
    final restored = Activity.fromMap(map);

    expect(restored.id, 'a1');
    expect(restored.tripId, 't1');
    expect(restored.dayNumber, 2);
    expect(restored.title, 'Visit Museum');
    expect(restored.category, 'Museum');
    expect(restored.lat, 13.7563);
    expect(restored.lon, 100.5018);
  });
}
