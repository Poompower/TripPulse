import 'package:flutter_test/flutter_test.dart';
import 'package:trippulse/maps/screens/general_map_screen.dart';
import 'package:trippulse/trips/models/trip.dart';

void main() {
  test('GeneralMapArgs stores trip and dayNumber', () {
    final trip = Trip(
      id: 'trip-9',
      title: 'Road Trip',
      destination: 'Chiang Mai',
      startDate: 'Apr 01, 2026',
      endDate: 'Apr 03, 2026',
      currency: 'THB',
      budget: 10000,
    );

    final args = GeneralMapArgs(trip: trip, dayNumber: 2);

    expect(args.trip?.id, 'trip-9');
    expect(args.dayNumber, 2);
  });
}
