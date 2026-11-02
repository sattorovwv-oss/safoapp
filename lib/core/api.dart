import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'models.dart';
import 'models_social.dart';
import 'settings.dart';

class PlacesResult {
  PlacesResult(this.places, {this.fromCache = false});
  final List<Place> places;
  final bool fromCache;
}

/// Ошибка API: [code] — ключ с сервера (например `invalid_credentials`) или `network`.
class ApiException implements Exception {
  ApiException(this.code, [this.status]);
  final String code;
  final int? status;

  @override
  String toString() => 'ApiException($code, $status)';
}

class LoginResult {
  LoginResult(this.token, this.user);
  final String token;
  final AuthUser user;
}

class Api {
  Api(this.settings);
  final AppSettings settings;

  Uri _u(String path) => Uri.parse('${settings.baseUrl}$path');

  Map<String, String> get authHeaders => settings.token == null
      ? {}
      : {'authorization': 'Bearer ${settings.token}'};

  /// `/api/media/...` -> абсолютный URL на сервере.
  String media(String path) =>
      path.startsWith('http') ? path : '${settings.baseUrl}$path';

  Future<Map<String, dynamic>> _json(http.Response r) async {
    final body = utf8.decode(r.bodyBytes);
    Map<String, dynamic> j = {};
    try {
      j = (jsonDecode(body) as Map).cast<String, dynamic>();
    } catch (_) {}
    if (r.statusCode >= 400)
      throw ApiException((j['error'] ?? 'generic') as String, r.statusCode);
    return j;
  }

  Future<T> _guard<T>(Future<T> Function() f) async {
    try {
      return await f();
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException('network');
    } catch (_) {
      throw ApiException('network');
    }
  }

  // ---------------- Каталог ----------------

  Future<PlacesResult> places() async {
    try {
      final r = await http
          .get(_u('/api/mobile/places'))
          .timeout(const Duration(seconds: 15));
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
    return [
      for (final p in (j['places'] as List))
        Place.fromJson(p as Map<String, dynamic>),
    ];
  }

  Future<List<Review>> reviews(String slug) async {
    try {
      final r = await http
          .get(_u('/api/mobile/places/$slug'))
          .timeout(const Duration(seconds: 15));
      if (r.statusCode != 200) return [];
      final j = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
      return [
        for (final x in (j['reviews'] as List))
          Review.fromJson(x as Map<String, dynamic>),
      ];
    } catch (_) {
      return [];
    }
  }

  Future<bool> ping() async {
    try {
      final r = await http
          .get(_u('/api/mobile/places'))
          .timeout(const Duration(seconds: 8));
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ---------------- Вуруд ----------------

  Future<LoginResult> login(String login, String password) => _guard(() async {
    final r = await http
        .post(
          _u('/api/mobile/auth/login'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({
            'mode': 'staff',
            'login': login,
            'password': password,
          }),
        )
        .timeout(const Duration(seconds: 20));
    final j = await _json(r);
    return LoginResult(
      j['token'] as String,
      AuthUser.fromJson((j['user'] as Map).cast<String, dynamic>()),
    );
  });

  Future<AuthUser> me() => _guard(() async {
    final r = await http
        .get(_u('/api/mobile/me'), headers: authHeaders)
        .timeout(const Duration(seconds: 15));
    return AuthUser.fromJson(await _json(r));
  });

  Future<void> logout() async {
    try {
      await http
          .post(_u('/api/mobile/auth/logout'), headers: authHeaders)
          .timeout(const Duration(seconds: 8));
    } catch (_) {}
  }

  // ---------------- Тозакунанда ----------------

  Future<CleanerData> cleanerReports() => _guard(() async {
    final r = await http
        .get(_u('/api/mobile/cleaner/reports'), headers: authHeaders)
        .timeout(const Duration(seconds: 20));
    return CleanerData.fromJson(await _json(r));
  });

  Future<void> claim(String id) => _guard(() async {
    await _json(
      await http
          .post(_u('/api/reports/$id/claim'), headers: authHeaders)
          .timeout(const Duration(seconds: 20)),
    );
  });

  Future<void> release(String id) => _guard(() async {
    await _json(
      await http
          .delete(_u('/api/reports/$id/claim'), headers: authHeaders)
          .timeout(const Duration(seconds: 20)),
    );
  });

  /// Тозакунанда: то 4 акси «баъд».
  Future<void> complete(String id, List<XFile> photos, {String? note}) =>
      _guard(() async {
        final req = http.MultipartRequest(
          'POST',
          _u('/api/reports/$id/complete'),
        )..headers.addAll(authHeaders);
        for (final p in photos) {
          req.files.add(
            http.MultipartFile.fromBytes(
              'photo',
              await p.readAsBytes(),
              filename: 'after.jpg',
            ),
          );
        }
        if (note != null && note.trim().isNotEmpty) {
          req.fields['note'] = note.trim();
        }
        final res = await http.Response.fromStream(
          await req.send().timeout(const Duration(seconds: 120)),
        );
        await _json(res);
      });

  // ---------------- Сокин, раис, сайёҳ ----------------

  Future<List<MahallaItem>> mahallas() => _guard(() async {
    final r = await http
        .get(_u('/api/mahallas'))
        .timeout(const Duration(seconds: 15));
    if (r.statusCode != 200) throw ApiException('generic', r.statusCode);
    return [
      for (final m in (jsonDecode(utf8.decode(r.bodyBytes)) as List))
        MahallaItem.fromJson((m as Map).cast<String, dynamic>()),
    ];
  });

  Future<LoginResult> loginResident(
    String mahallaId,
    String house,
    String password,
  ) => _guard(() async {
    final r = await http
        .post(
          _u('/api/mobile/auth/login'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({
            'mode': 'resident',
            'mahallaId': mahallaId,
            'house': house.trim(),
            'password': password,
          }),
        )
        .timeout(const Duration(seconds: 20));
    final j = await _json(r);
    return LoginResult(
      j['token'] as String,
      AuthUser.fromJson((j['user'] as Map).cast<String, dynamic>()),
    );
  });

  /// Гузориш дар бораи ахлот: то 4 акс.
  Future<void> createReport({
    required String description,
    required double lat,
    required double lng,
    required bool manual,
    required List<XFile> photos,
  }) => _guard(() async {
    final req = http.MultipartRequest('POST', _u('/api/reports'))
      ..headers.addAll(authHeaders)
      ..fields.addAll({
        'description': description,
        'lat': '$lat',
        'lng': '$lng',
        'locSource': manual ? 'manual' : 'device',
      });
    for (final p in photos) {
      req.files.add(
        http.MultipartFile.fromBytes(
          'photo',
          await p.readAsBytes(),
          filename: 'photo.jpg',
        ),
      );
    }
    await _json(
      await http.Response.fromStream(
        await req.send().timeout(const Duration(seconds: 120)),
      ),
    );
  });

  Future<void> postReview(String placeId, int rating, String? body) =>
      _guard(() async {
        final r = await http
            .post(
              _u('/api/places/$placeId/reviews'),
              headers: {'content-type': 'application/json', ...authHeaders},
              body: jsonEncode({
                'rating': rating,
                if (body != null && body.trim().isNotEmpty) 'body': body.trim(),
              }),
            )
            .timeout(const Duration(seconds: 20));
        await _json(r);
      });

  Future<SubbotnikData> subbotniks() => _guard(() async {
    final r = await http
        .get(_u('/api/mobile/subbotniks'), headers: authHeaders)
        .timeout(const Duration(seconds: 20));
    return SubbotnikData.fromJson(await _json(r));
  });

  Future<void> respondSubbotnik(
    String id,
    bool participate, {
    String? reason,
  }) => _guard(() async {
    final r = await http
        .post(
          _u('/api/subbotniks/$id/respond'),
          headers: {'content-type': 'application/json', ...authHeaders},
          body: jsonEncode({
            'response': participate ? 'PARTICIPATE' : 'REFUSE',
            if (reason != null && reason.trim().isNotEmpty)
              'reason': reason.trim(),
          }),
        )
        .timeout(const Duration(seconds: 20));
    await _json(r);
  });

  Future<void> sendSubbotnikPhotos(String id, List<XFile> photos) =>
      _guard(() async {
        for (final p in photos) {
          final req =
              http.MultipartRequest('POST', _u('/api/subbotniks/$id/photo'))
                ..headers.addAll(authHeaders)
                ..files.add(
                  http.MultipartFile.fromBytes(
                    'photo',
                    await p.readAsBytes(),
                    filename: 'photo.jpg',
                  ),
                );
          await _json(
            await http.Response.fromStream(
              await req.send().timeout(const Duration(seconds: 90)),
            ),
          );
        }
      });

  Future<ChatData> chat() => _guard(() async {
    final r = await http
        .get(_u('/api/chat/messages'), headers: authHeaders)
        .timeout(const Duration(seconds: 15));
    return ChatData.fromJson(await _json(r));
  });

  Future<void> sendChat(String body) => _guard(() async {
    final r = await http
        .post(
          _u('/api/chat/messages'),
          headers: {'content-type': 'application/json', ...authHeaders},
          body: jsonEncode({'body': body}),
        )
        .timeout(const Duration(seconds: 15));
    await _json(r);
  });
}
