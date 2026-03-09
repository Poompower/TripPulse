import 'package:flutter_test/flutter_test.dart';
import 'package:trippulse/trips/models/trip.dart';

void main() {
  test('Trip.toMap returns expected fields', () {
    final trip = Trip(
      id: 'trip-1',
      title: 'Summer Holiday',
      destination: 'Tokyo, Japan',
      city: 'Tokyo',
      country: 'Japan',
      countryCode: 'JP',
      lat: 35.6762,
      lon: 139.6503,
      startDate: 'Mar 10, 2026',
      endDate: 'Mar 15, 2026',
      currency: 'JPY',
      budget: 50000,
      isFavorite: true,
      userId: 'user-1',
    );

    final map = trip.toMap();

    expect(map['title'], 'Summer Holiday');
    expect(map['destination'], 'Tokyo, Japan');
    expect(map['countryCode'], 'JP');
    expect(map['budget'], 50000);
    expect(map['isFavorite'], isTrue);
    expect(map['userId'], 'user-1');
  });
}
