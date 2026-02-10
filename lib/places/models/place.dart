class Place {
  final String id;
  final String name;
  final String category;
  final String description;
  final double lat;
  final double lon;
  final String? country;
  final String? imageUrl;
  final double? distanceKm;

  Place({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.lat,
    required this.lon,
    this.country,
    this.imageUrl,
    this.distanceKm,
  });


  /// ใช้ตอนดึงจาก Geoapify (Search)
/// ใช้ตอนดึงจาก Geoapify (Search)
factory Place.fromGeoapify(Map<String, dynamic> json) {
  final props = json['properties'] as Map<String, dynamic>;

  // 🔒 defensive: datasource ไม่ได้เป็น Map เสมอ
  Map<String, dynamic>? raw;
  final datasource = props['datasource'];

  if (datasource is Map<String, dynamic>) {
    final rawValue = datasource['raw'];
    if (rawValue is Map<String, dynamic>) {
      raw = rawValue;
    }
  }

  // wikipedia image (ถ้ามีจริง)
  String? wikiImage;
  final wiki = raw?['wikipedia'];
  if (wiki is Map<String, dynamic>) {
    wikiImage = wiki['image'];
  }

  return Place(
    id: props['place_id'] ?? '',
    name: props['name'] ?? '',
    category: (props['categories'] as List?)?.first ?? '',
    description: props['formatted'] ?? '',
    lat: (props['lat'] as num).toDouble(),
    lon: (props['lon'] as num).toDouble(),
    country: props['country'],

    // ใช้ image จาก Geoapify ก่อน ถ้าไม่มีค่อย fallback wikipedia
    imageUrl: props['image'] ?? wikiImage,

    distanceKm: props['distance'] != null
        ? (props['distance'] as num).toDouble() / 1000
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
        'country': country,
      };

  factory Place.fromJson(Map<String, dynamic> json) => Place(
        id: json['id'],
        name: json['name'],
        category: json['category'],
        description: json['description'],
        lat: json['lat'],
        lon: json['lon'],
        country: json['country'],
        imageUrl: json['imageUrl'],
        distanceKm: json['distanceKm'],
      );
}