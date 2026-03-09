class Place {
  final String id;
  final String name;
  final String category;
  final String description;
  final double lat;
  final double lon;
  final String? country;
  final String? countryCode;
  final String? imageUrl;
  final String? wikipediaTitle;
  final String? wikimediaCommons;
  final String? wikidataId;
  final double? distanceKm;
  final List<String> categories;

  Place({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.lat,
    required this.lon,
    this.country,
    this.countryCode,
    this.imageUrl,
    this.wikipediaTitle,
    this.wikimediaCommons,
    this.wikidataId,
    this.distanceKm,
    required this.categories,
  });

  // Build model from Geoapify Places search result.
  factory Place.fromGeoapify(Map<String, dynamic> json) {
    final props = json['properties'] as Map<String, dynamic>;

    // Defensive parse for datasource.raw structure.
    Map<String, dynamic>? raw;
    final datasource = props['datasource'];

    if (datasource is Map<String, dynamic>) {
      final rawValue = datasource['raw'];
      if (rawValue is Map<String, dynamic>) {
        raw = rawValue;
      }
    }

    final wikipediaTitle = (raw?['wikipedia'] ?? props['wikipedia'])
        ?.toString();
    final wikimediaCommons =
        (raw?['wikimedia_commons'] ?? props['wikimedia_commons'])?.toString();
    final wikidataId = (raw?['wikidata'] ?? props['wikidata'])?.toString();

    return Place(
      id: props['place_id'] ?? '',
      name: props['name'] ?? '',
      category: (props['categories'] as List?)?.first ?? '',
      description: props['formatted'] ?? '',
      lat: (props['lat'] as num).toDouble(),
      lon: (props['lon'] as num).toDouble(),
      country: props['country'],
      countryCode: (props['country_code'] as String?)?.toUpperCase(),
      imageUrl: props['image']?.toString(),
      wikipediaTitle: wikipediaTitle,
      wikimediaCommons: wikimediaCommons,
      wikidataId: wikidataId,
      distanceKm: props['distance'] != null
          ? (props['distance'] as num).toDouble() / 1000
          : null,
      categories:
          (props['categories'] as List?)?.map((e) => e.toString()).toList() ??
          [],
    );
  }

  // Serialize for local/Firebase persistence.
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
    'countryCode': countryCode,
    'wikipediaTitle': wikipediaTitle,
    'wikimediaCommons': wikimediaCommons,
    'wikidataId': wikidataId,
    'categories': categories,
  };

  factory Place.fromJson(Map<String, dynamic> json) => Place(
    id: json['id'],
    name: json['name'],
    category: json['category'],
    description: json['description'],
    lat: json['lat'],
    lon: json['lon'],
    country: json['country'],
    countryCode: json['countryCode'],
    imageUrl: json['imageUrl'],
    wikipediaTitle: json['wikipediaTitle'],
    wikimediaCommons: json['wikimediaCommons'],
    wikidataId: json['wikidataId'],
    distanceKm: json['distanceKm'],
    categories: (json['categories'] as List? ?? const [])
        .map((e) => e.toString())
        .toList(),
  );
}
