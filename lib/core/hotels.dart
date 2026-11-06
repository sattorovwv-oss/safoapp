import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'api.dart';
import 'settings.dart';

/// Строка на трёх языках (tg/ru/en) с запасным вариантом.
class Tri {
  const Tri(this.tg, this.ru, this.en);
  final String tg, ru, en;

  factory Tri.from(dynamic j) {
    final m = (j is Map) ? j : const {};
    return Tri(
      (m['tg'] ?? '') as String,
      (m['ru'] ?? '') as String,
      (m['en'] ?? '') as String,
    );
  }

  String of(String lang) {
    final order = lang == 'tg'
        ? [tg, ru, en]
        : lang == 'en'
        ? [en, ru, tg]
        : [ru, en, tg];
    return order.firstWhere((s) => s.trim().isNotEmpty, orElse: () => '');
  }
}

class HPhoto {
  HPhoto(this.thumb, this.medium, this.large);
  final String thumb, medium, large;
  factory HPhoto.from(dynamic j) => HPhoto(
    j['thumb'] as String,
    j['medium'] as String,
    j['large'] as String,
  );
}

class HRoom {
  HRoom(Map<String, dynamic> j)
    : code = j['code'] as String? ?? '',
      name = Tri.from(j['name']),
      desc = Tri.from(j['desc']),
      sizeFrom = j['sizeFrom'] as int?,
      sizeTo = j['sizeTo'] as int?,
      maxAdults = (j['maxAdults'] ?? 2) as int,
      maxGuests = (j['maxGuests'] ?? 2) as int,
      fromPrice = j['fromPrice'] as int?,
      amenities = [for (final a in (j['amenities'] as List? ?? [])) Tri.from(a)],
      photos = [for (final p in (j['photos'] as List? ?? [])) HPhoto.from(p)];
  final String code;
  final Tri name, desc;
  final int? sizeFrom, sizeTo, fromPrice;
  final int maxAdults, maxGuests;
  final List<Tri> amenities;
  final List<HPhoto> photos;
}

class HService {
  HService(Map<String, dynamic> j)
    : key = j['key'] as String,
      title = Tri.from(j['title']),
      text = Tri.from(j['text']),
      hours = j['hours'] as String?,
      photos = [for (final p in (j['photos'] as List? ?? [])) HPhoto.from(p)];
  final String key;
  final Tri title, text;
  final String? hours;
  final List<HPhoto> photos;
}

class HFeature {
  HFeature(Map<String, dynamic> j)
    : icon = j['icon'] as String? ?? '',
      text = Tri.from(j);
  final String icon;
  final Tri text;
}

class Hotel {
  Hotel(Map<String, dynamic> j)
    : slug = j['slug'] as String,
      name = j['name'] as String,
      stars = (j['stars'] ?? 5) as int,
      tagline = Tri.from(j['tagline']),
      desc = Tri.from(j['desc']),
      address = Tri.from(j['address']),
      lat = (j['lat'] as num?)?.toDouble(),
      lng = (j['lng'] as num?)?.toDouble(),
      phone = j['phone'] as String?,
      whatsapp = j['whatsapp'] as String?,
      telegram = j['telegram'] as String?,
      email = j['email'] as String?,
      bookingUrl = j['bookingUrl'] as String?,
      checkIn = j['checkIn'] as String? ?? '14:00',
      checkOut = j['checkOut'] as String? ?? '12:00',
      currency = j['currency'] as String? ?? 'TJS',
      fromPrice = j['fromPrice'] as int?,
      features = [
        for (final f in (j['features'] as List? ?? []))
          HFeature((f as Map).cast<String, dynamic>()),
      ],
      services = [
        for (final s in (j['services'] as List? ?? []))
          HService((s as Map).cast<String, dynamic>()),
      ],
      photos = [for (final p in (j['photos'] as List? ?? [])) HPhoto.from(p)],
      rooms = [
        for (final r in (j['rooms'] as List? ?? []))
          HRoom((r as Map).cast<String, dynamic>()),
      ];
  final String slug, name, checkIn, checkOut, currency;
  final int stars;
  final Tri tagline, desc, address;
  final double? lat, lng;
  final String? phone, whatsapp, telegram, email, bookingUrl;
  final int? fromPrice;
  final List<HFeature> features;
  final List<HService> services;
  final List<HPhoto> photos;
  final List<HRoom> rooms;
}

class HQuote {
  HQuote(Map<String, dynamic> j)
    : code = j['code'] as String,
      total = (j['total'] as num).round(),
      perNight = (j['perNight'] as num).round(),
      currency = j['currency'] as String? ?? 'TJS';
  final String code, currency;
  final int total, perNight;
}

class HotelsApi {
  HotelsApi(this.settings, this.api);
  final AppSettings settings;
  final Api api;

  Uri _u(String path, [Map<String, String>? q]) =>
      Uri.parse('${settings.baseUrl}$path').replace(queryParameters: q);

  Future<List<Hotel>> list() async {
    try {
      final r = await http
          .get(_u('/api/mobile/hotels'))
          .timeout(const Duration(seconds: 15));
      if (r.statusCode != 200) throw Exception('http ${r.statusCode}');
      final j = jsonDecode(utf8.decode(r.bodyBytes)) as Map;
      return [
        for (final h in (j['hotels'] as List))
          Hotel((h as Map).cast<String, dynamic>()),
      ];
    } catch (_) {
      throw ApiException('network');
    }
  }

  /// Живые цены из системы бронирования отеля на выбранные даты.
  Future<List<HQuote>> quotes(
    String slug,
    DateTime from,
    DateTime to,
    int adults,
  ) async {
    try {
      final r = await http
          .get(
            _u('/api/hotels/$slug/availability', {
              'checkIn': fmtDate(from),
              'checkOut': fmtDate(to),
              'adults': '$adults',
            }),
          )
          .timeout(const Duration(seconds: 25));
      if (r.statusCode != 200) throw Exception('http ${r.statusCode}');
      final j = jsonDecode(utf8.decode(r.bodyBytes)) as Map;
      return [
        for (final q in (j['quotes'] as List))
          HQuote((q as Map).cast<String, dynamic>()),
      ];
    } catch (_) {
      throw ApiException('network');
    }
  }

  /// Запрос на бронь: сервер передаёт его отелю.
  Future<void> request(
    String slug, {
    required String name,
    required String phone,
    required DateTime from,
    required DateTime to,
    required int adults,
    required int children,
    String? roomCode,
    String? comment,
    int? quotedTotal,
  }) async {
    try {
      final r = await http
          .post(
            _u('/api/hotels/$slug/request'),
            headers: {'content-type': 'application/json', ...api.authHeaders},
            body: jsonEncode({
              'name': name,
              'phone': phone,
              'checkIn': fmtDate(from),
              'checkOut': fmtDate(to),
              'adults': adults,
              'children': children,
              'roomCode': ?roomCode,
              if (comment != null && comment.trim().isNotEmpty)
                'comment': comment.trim(),
              'quotedTotal': ?quotedTotal,
            }),
          )
          .timeout(const Duration(seconds: 20));
      if (r.statusCode >= 400) {
        String code = 'generic';
        try {
          code = (jsonDecode(utf8.decode(r.bodyBytes)) as Map)['error']
              as String;
        } catch (_) {}
        throw ApiException(code, r.statusCode);
      }
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException('network');
    }
  }

  /// Статистика нажатий для отеля (не критична).
  void track(String slug, String type) {
    unawaited(
      http
          .post(
            _u('/api/hotels/$slug/event'),
            headers: {'content-type': 'application/json'},
            body: jsonEncode({'type': type}),
          )
          .timeout(const Duration(seconds: 8))
          .then((_) {}, onError: (_) {}),
    );
  }

  static String fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

/// Иконки из данных отеля (имена совпадают с сайтом).
IconData hotelIcon(String name) => switch (name) {
  'utensils' => Icons.restaurant_rounded,
  'waves' => Icons.pool_rounded,
  'dumbbell' => Icons.fitness_center_rounded,
  'briefcase' => Icons.business_center_rounded,
  'bell' => Icons.room_service_rounded,
  'wifi' => Icons.wifi_rounded,
  'car' => Icons.local_parking_rounded,
  'plane' => Icons.flight_rounded,
  'users' => Icons.translate_rounded,
  'building' => Icons.apartment_rounded,
  'bed' => Icons.bed_rounded,
  _ => Icons.check_circle_outline_rounded,
};
