const categories = ['HISTORICAL', 'NATURE', 'RECREATION', 'TEAHOUSE_RESTAURANT', 'MARKET_PARK'];
const regions = ['DUSHANBE', 'SUGHD', 'KHATLON', 'GBAO', 'RRP'];

class PlacePhoto {
  PlacePhoto({required this.thumb, required this.medium, required this.large, required this.author, required this.license, this.sourceUrl});

  final String thumb, medium, large, author, license;
  final String? sourceUrl;

  factory PlacePhoto.fromJson(Map<String, dynamic> j) => PlacePhoto(
        thumb: j['thumb'] as String,
        medium: j['medium'] as String,
        large: j['large'] as String,
        author: (j['author'] ?? '') as String,
        license: (j['license'] ?? '') as String,
        sourceUrl: j['sourceUrl'] as String?,
      );
}

class Place {
  Place({
    required this.id,
    required this.slug,
    required this.name,
    required this.desc,
    required this.bestTime,
    required this.category,
    required this.region,
    this.lat,
    this.lng,
    this.address,
    this.hours,
    this.price,
    this.mapsUrl,
    required this.ratingAvg,
    required this.ratingCount,
    required this.photos,
  });

  final String id, slug, category, region;
  final Map<String, String> name, desc;
  final Map<String, String?> bestTime;
  final double? lat, lng;
  final String? address, hours, price, mapsUrl;
  final double ratingAvg;
  final int ratingCount;
  final List<PlacePhoto> photos;

  String nameOf(String l) => name[l] ?? name['tg'] ?? slug;
  String descOf(String l) => desc[l] ?? desc['tg'] ?? '';
  String? bestOf(String l) => bestTime[l] ?? bestTime['tg'];
  bool get hasCoords => lat != null && lng != null;

  factory Place.fromJson(Map<String, dynamic> j) {
    Map<String, String> m(dynamic v) => {for (final e in (v as Map).entries) e.key as String: (e.value ?? '') as String};
    return Place(
      id: j['id'] as String,
      slug: j['slug'] as String,
      name: m(j['name']),
      desc: m(j['desc']),
      bestTime: {for (final e in (j['bestTime'] as Map).entries) e.key as String: e.value as String?},
      category: j['category'] as String,
      region: j['region'] as String,
      lat: (j['lat'] as num?)?.toDouble(),
      lng: (j['lng'] as num?)?.toDouble(),
      address: j['address'] as String?,
      hours: j['hours'] as String?,
      price: j['price'] as String?,
      mapsUrl: j['mapsUrl'] as String?,
      ratingAvg: (j['ratingAvg'] as num).toDouble(),
      ratingCount: (j['ratingCount'] as num).toInt(),
      photos: [for (final p in (j['photos'] as List)) PlacePhoto.fromJson(p as Map<String, dynamic>)],
    );
  }
}

class Review {
  Review({required this.rating, this.body, this.author, required this.createdAt});

  final int rating;
  final String? body, author;
  final DateTime createdAt;

  factory Review.fromJson(Map<String, dynamic> j) => Review(
        rating: (j['rating'] as num).toInt(),
        body: j['body'] as String?,
        author: j['author'] as String?,
        createdAt: DateTime.tryParse((j['createdAt'] ?? '') as String) ?? DateTime.now(),
      );
}
