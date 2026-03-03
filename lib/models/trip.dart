class Trip {
  final dynamic id;
  final String title;
  final String destination;
  final String? city;
  final String? country;
  final String? countryCode;
  final double? lat;
  final double? lon;
  final String startDate;
  final String endDate;
  final String currency;
  final double budget;

  Trip({
    this.id,
    required this.title,
    required this.destination,
    this.city,
    this.country,
    this.countryCode,
    this.lat,
    this.lon,
    required this.startDate,
    required this.endDate,
    required this.currency,
    required this.budget,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'destination': destination,
      'city': city,
      'country': country,
      'countryCode': countryCode,
      'lat': lat,
      'lon': lon,
      'startDate': startDate,
      'endDate': endDate,
      'currency': currency,
      'budget': budget,
    };
  }
}
