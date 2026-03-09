class Activity {
  final dynamic id;
  final dynamic tripId;
  final int dayNumber;
  final String title;
  final String? location;
  final String? time;
  final String? imageUrl;
  final String? category;
  final String? notes;
  final double? lat;
  final double? lon;

  Activity({
    this.id,
    required this.tripId,
    required this.dayNumber,
    required this.title,
    this.location,
    this.time,
    this.imageUrl,
    this.category,
    this.notes,
    this.lat,
    this.lon,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tripId': tripId,
      'dayNumber': dayNumber,
      'title': title,
      'location': location,
      'time': time,
      'imageUrl': imageUrl,
      'category': category,
      'notes': notes,
      'lat': lat,
      'lon': lon,
    };
  }

  factory Activity.fromMap(Map<String, dynamic> map) {
    return Activity(
      id: map['id'],
      tripId: map['tripId'],
      dayNumber: map['dayNumber'],
      title: map['title'],
      location: map['location'],
      time: map['time'],
      imageUrl: map['imageUrl'],
      category: map['category'],
      notes: map['notes'],
      lat: (map['lat'] as num?)?.toDouble(),
      lon: (map['lon'] as num?)?.toDouble(),
    );
  }
}
