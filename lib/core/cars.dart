import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api.dart';
import 'hotels.dart' show HPhoto, HotelsApi;
import 'settings.dart';

/// Машина партнёра (раздел «Аренда авто» на сайте).
class Car {
  Car(Map<String, dynamic> j)
    : slug = j['slug'] as String,
      name = j['name'] as String,
      category = j['category'] as String? ?? '',
      description = j['description'] as String? ?? '',
      pricePerDay = j['pricePerDay'] as int?,
      photos = [for (final p in (j['photos'] as List? ?? [])) HPhoto.from(p)];
  final String slug, name, category, description;
  final int? pricePerDay;
  final List<HPhoto> photos;
}

class CarsList {
  CarsList(this.cars, this.phone, this.whatsapp);
  final List<Car> cars;
  final String? phone, whatsapp;
}

class CarsApi {
  CarsApi(this.settings, this.api);
  final AppSettings settings;
  final Api api;

  Uri _u(String path) => Uri.parse('${settings.baseUrl}$path');

  Future<CarsList> list() async {
    try {
      final r = await http.get(_u('/api/mobile/cars')).timeout(const Duration(seconds: 15));
      if (r.statusCode == 503) throw ApiException('section_closed', 503);
      if (r.statusCode != 200) throw Exception('http ${r.statusCode}');
      final j = jsonDecode(utf8.decode(r.bodyBytes)) as Map;
      final contact = (j['contact'] as Map?) ?? const {};
      return CarsList(
        [for (final c in (j['cars'] as List)) Car((c as Map).cast<String, dynamic>())],
        contact['phone'] as String?,
        contact['whatsapp'] as String?,
      );
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException('network');
    }
  }

  /// Заявка на аренду: приходит администратору «Сафо», он связывается с клиентом и владельцем.
  Future<void> book(
    String slug, {
    required String name,
    required String phone,
    required DateTime from,
    required DateTime to,
    String? comment,
  }) async {
    try {
      final r = await http
          .post(
            _u('/api/cars/$slug/book'),
            headers: {'content-type': 'application/json', ...api.authHeaders},
            body: jsonEncode({
              'name': name,
              'phone': phone,
              'dateFrom': HotelsApi.fmtDate(from),
              'dateTo': HotelsApi.fmtDate(to),
              if (comment != null && comment.trim().isNotEmpty) 'comment': comment.trim(),
            }),
          )
          .timeout(const Duration(seconds: 20));
      if (r.statusCode >= 400) {
        String code = 'generic';
        try {
          code = (jsonDecode(utf8.decode(r.bodyBytes)) as Map)['error'] as String;
        } catch (_) {}
        throw ApiException(code, r.statusCode);
      }
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException('network');
    }
  }
}
