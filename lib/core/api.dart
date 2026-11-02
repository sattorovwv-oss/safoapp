import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models.dart';
import 'settings.dart';

class PlacesResult {
  PlacesResult(this.places, {this.fromCache = false});
  final List<Place> places;
  final bool fromCache;
}

class Api {
  Api(this.settings);
  final AppSettings settings;

  Uri _u(String path) => Uri.parse('${settings.baseUrl}$path');

  /// `/api/media/...` -> абсолютный URL на сервере.
  String media(String path) => path.startsWith('http') ? path : '${settings.baseUrl}$path';

  Future<PlacesResult> places() async {
    try {
      final r = await http.get(_u('/api/mobile/places')).timeout(const Duration(seconds: 15));
      if (r.statusCode != 200) throw Exception('http ${r.statusCode}');
      final body = utf8.decode(r.bodyBytes);
      await settings.cachePlaces(body);
      return PlacesResult(_parse(body));
    } catch (_) {
      final cached = settings.cachedPlaces;
      if (cached != null) return PlacesResult(_parse(cached), fromCache: true);
      rethrow;
    }
  }

  List<Place> _parse(String body) {
    final j = jsonDecode(body) as Map<String, dynamic>;
    return [for (final p in (j['places'] as List)) Place.fromJson(p as Map<String, dynamic>)];
  }

  Future<List<Review>> reviews(String slug) async {
    try {
      final r = await http.get(_u('/api/mobile/places/$slug')).timeout(const Duration(seconds: 15));
      if (r.statusCode != 200) return [];
      final j = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
      return [for (final x in (j['reviews'] as List)) Review.fromJson(x as Map<String, dynamic>)];
    } catch (_) {
      return [];
    }
  }

  Future<bool> ping() async {
    try {
      final r = await http.get(_u('/api/mobile/places')).timeout(const Duration(seconds: 8));
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
