class Place {
  final String id;
  final String name;
  final String category;
  final String description;
  final double lat;
  final double lon;
  final String? imageUrl;
  final double? distanceKm;

  Place({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.lat,
    required this.lon,
    this.imageUrl,
    this.distanceKm,
  });


  /// ใช้ตอนดึงจาก Geoapify (Search)
factory Place.fromGeoapify(Map<String, dynamic> json) {
    final props = json['properties'] ?? {};
    final coords = json['geometry']['coordinates'];

    final categories = (props['categories'] as List?) ?? [];

    return Place(
      id: props['place_id'] ??
          props['osm_id']?.toString() ??
          '${coords[1]}_${coords[0]}',
      name: props['name'] ?? 'Unknown place',
      category: categories.isNotEmpty ? categories.first : 'Unknown',
      description: props['formatted'] ??
          props['address_line1'] ??
          '',
      lat: coords[1],
      lon: coords[0],
      imageUrl: null,
      distanceKm: props['distance'] != null
          ? (props['distance'] / 1000).toDouble()
          : null,
    );
  }

  /// ใช้ตอน save ลง Firebase / SQLite
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'description': description,
        'lat': lat,
        'lon': lon,
        'imageUrl': imageUrl,
        'distanceKm': distanceKm,
      };

  factory Place.fromJson(Map<String, dynamic> json) => Place(
        id: json['id'],
        name: json['name'],
        category: json['category'],
        description: json['description'],
        lat: json['lat'],
        lon: json['lon'],
        imageUrl: json['imageUrl'],
        distanceKm: json['distanceKm'],
      );
}