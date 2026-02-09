class Activity {
  final dynamic id;
  final dynamic tripId;
  final int dayNumber; // วันที่ 1, 2, 3...
  final String title;
  final String? location;
  final String? time;

  Activity({
    this.id,
    required this.tripId,
    required this.dayNumber,
    required this.title,
    this.location,
    this.time,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tripId': tripId,
      'dayNumber': dayNumber,
      'title': title,
      'location': location,
      'time': time,
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
    );
  }
}