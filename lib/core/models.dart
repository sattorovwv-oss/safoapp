const categories = [
  'HISTORICAL',
  'NATURE',
  'RECREATION',
  'TEAHOUSE_RESTAURANT',
  'MARKET_PARK',
];
const regions = ['DUSHANBE', 'SUGHD', 'KHATLON', 'GBAO', 'RRP'];

class PlacePhoto {
  PlacePhoto({
    required this.thumb,
    required this.medium,
    required this.large,
    required this.author,
    required this.license,
    this.sourceUrl,
  });

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
    Map<String, String> m(dynamic v) => {
      for (final e in (v as Map).entries)
        e.key as String: (e.value ?? '') as String,
    };
    return Place(
      id: j['id'] as String,
      slug: j['slug'] as String,
      name: m(j['name']),
      desc: m(j['desc']),
      bestTime: {
        for (final e in (j['bestTime'] as Map).entries)
          e.key as String: e.value as String?,
      },
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
      photos: [
        for (final p in (j['photos'] as List))
          PlacePhoto.fromJson(p as Map<String, dynamic>),
      ],
    );
  }
}

class Review {
  Review({
    required this.rating,
    this.body,
    this.author,
    required this.createdAt,
  });

  final int rating;
  final String? body, author;
  final DateTime createdAt;

  factory Review.fromJson(Map<String, dynamic> j) => Review(
    rating: (j['rating'] as num).toInt(),
    body: j['body'] as String?,
    author: j['author'] as String?,
    createdAt:
        DateTime.tryParse((j['createdAt'] ?? '') as String) ?? DateTime.now(),
  );
}

// ---------------- Тозакунанда ----------------

class AuthUser {
  AuthUser({required this.id, required this.role, required this.name});
  final String id, role, name;

  factory AuthUser.fromJson(Map<String, dynamic> j) => AuthUser(
    id: j['id'] as String,
    role: j['role'] as String,
    name: (j['name'] ?? '') as String,
  );
}

class ReportPhoto {
  ReportPhoto({required this.kind, required this.url, required this.thumb});
  final String kind, url, thumb;

  factory ReportPhoto.fromJson(Map<String, dynamic> j) => ReportPhoto(
    kind: j['kind'] as String,
    url: j['url'] as String,
    thumb: j['thumb'] as String,
  );
}

class CleanerReport {
  CleanerReport({
    required this.id,
    required this.status,
    required this.description,
    required this.lat,
    required this.lng,
    this.mahalla,
    required this.createdAt,
    this.claimedAt,
    this.cleanedAt,
    this.note,
    required this.photos,
  });

  final String id, status, description;
  final double lat, lng;
  final String? mahalla, note;
  final DateTime createdAt;
  final DateTime? claimedAt, cleanedAt;
  final List<ReportPhoto> photos;

  ReportPhoto? get firstPhoto => photos.isEmpty ? null : photos.first;

  factory CleanerReport.fromJson(Map<String, dynamic> j) {
    DateTime? d(dynamic v) =>
        v == null ? null : DateTime.tryParse(v as String)?.toLocal();
    return CleanerReport(
      id: j['id'] as String,
      status: j['status'] as String,
      description: (j['description'] ?? '') as String,
      lat: (j['lat'] as num).toDouble(),
      lng: (j['lng'] as num).toDouble(),
      mahalla: j['mahalla'] as String?,
      createdAt: d(j['createdAt']) ?? DateTime.now(),
      claimedAt: d(j['claimedAt']),
      cleanedAt: d(j['cleanedAt']),
      note: j['note'] as String?,
      photos: [
        for (final p in (j['photos'] as List))
          ReportPhoto.fromJson(p as Map<String, dynamic>),
      ],
    );
  }
}

class CleanerData {
  CleanerData({
    required this.today,
    required this.total,
    required this.open,
    required this.mine,
    required this.done,
  });
  final int today, total;
  final List<CleanerReport> open, mine, done;

  factory CleanerData.fromJson(Map<String, dynamic> j) {
    List<CleanerReport> l(dynamic v) => [
      for (final x in (v as List))
        CleanerReport.fromJson(x as Map<String, dynamic>),
    ];
    final s = j['stats'] as Map<String, dynamic>;
    return CleanerData(
      today: (s['today'] as num).toInt(),
      total: (s['total'] as num).toInt(),
      open: l(j['open']),
      mine: l(j['mine']),
      done: l(j['done']),
    );
  }
}
