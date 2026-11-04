import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:app_links/app_links.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api.dart';
import 'models.dart';
import 'settings.dart';

/// Состояние входа. Токен хранится в защищённом хранилище телефона.
class AuthStore extends ChangeNotifier {
  AuthStore(this.settings) : api = Api(settings);

  final AppSettings settings;
  final Api api;
  final _secure = const FlutterSecureStorage();

  AuthUser? user;
  bool restoring = true;

  /// Вход через Google: ждём возврата из браузера; ошибка — ключ для перевода (`err_…`).
  bool googleWaiting = false;
  String? googleError;
  String? _verifier;
  StreamSubscription<Uri>? _links;

  bool get isCleaner => user?.role == 'CLEANER';
  bool get isCommittee => user?.role == 'COMMITTEE' || user?.role == 'ADMIN';
  bool get isResident => user?.role == 'RESIDENT';
  bool get isChairman => user?.role == 'CHAIRMAN';
  bool get isTourist => user?.role == 'TOURIST';
  bool get canChat => isResident || isChairman;

  Future<void> restore() async {
    try {
      final t = await _secure.read(key: 'token');
      if (t != null) {
        settings.token = t;
        try {
          user = await api.me();
        } on ApiException catch (e) {
          // Токен недействителен -> выходим; сеть недоступна -> оставляем токен
          if (e.code != 'network') await _clear();
        }
      }
    } catch (_) {
      // защищённое хранилище недоступно — работаем как гость
    }
    restoring = false;
    _listenLinks();
    notifyListeners();
  }

  void _listenLinks() {
    try {
      _links ??= AppLinks().uriLinkStream.listen(_onLink, onError: (_) {});
    } catch (_) {
      // на платформах без поддержки ссылок (веб, тесты) — просто без входа через Google
    }
  }

  /// Открываем вход Google в браузере. PKCE: секрет остаётся в приложении, на сервер — только отпечаток.
  Future<bool> startGoogle() async {
    final rnd = Random.secure();
    _verifier = base64Url
        .encode(List<int>.generate(32, (_) => rnd.nextInt(256)))
        .replaceAll('=', '');
    final challenge = base64Url
        .encode(sha256.convert(utf8.encode(_verifier!)).bytes)
        .replaceAll('=', '');
    try {
      await _secure.write(key: 'g_verifier', value: _verifier);
    } catch (_) {}
    googleError = null;
    googleWaiting = true;
    notifyListeners();
    final ok = await launchUrl(
      api.googleStart(challenge),
      mode: LaunchMode.externalApplication,
    );
    if (!ok) {
      googleWaiting = false;
      googleError = 'failed';
      notifyListeners();
    }
    return ok;
  }

  Future<void> _onLink(Uri u) async {
    if (u.scheme != 'safo' || u.host != 'auth') return;
    final code = u.queryParameters['code'];
    String? verifier = _verifier;
    try {
      // приложение могло быть выгружено из памяти, пока человек был в браузере
      verifier ??= await _secure.read(key: 'g_verifier');
      await _secure.delete(key: 'g_verifier');
    } catch (_) {}
    if (code == null || verifier == null) {
      googleWaiting = false;
      googleError = u.queryParameters['error'] ?? 'failed';
      notifyListeners();
      return;
    }
    try {
      final r = await api.loginGoogle(code, verifier);
      await _save(r);
      googleError = null;
    } on ApiException catch (e) {
      googleError = e.code;
    }
    _verifier = null;
    googleWaiting = false;
    notifyListeners();
  }

  Future<void> _save(LoginResult r) async {
    settings.token = r.token;
    user = r.user;
    try {
      await _secure.write(key: 'token', value: r.token);
    } catch (_) {}
  }

  @override
  void dispose() {
    _links?.cancel();
    super.dispose();
  }

  /// Возвращает ключ ошибки или null при успехе.
  Future<String?> login(String login, String password) async {
    try {
      final r = await api.login(login.trim(), password);
      settings.token = r.token;
      user = r.user;
      try {
        await _secure.write(key: 'token', value: r.token);
      } catch (_) {}
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.code;
    }
  }

  Future<String?> loginResident(
    String mahallaId,
    String house,
    String password,
  ) async {
    try {
      final r = await api.loginResident(mahallaId, house, password);
      settings.token = r.token;
      user = r.user;
      try {
        await _secure.write(key: 'token', value: r.token);
      } catch (_) {}
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.code;
    }
  }

  Future<void> logout() async {
    await api.logout();
    await _clear();
    notifyListeners();
  }

  Future<void> _clear() async {
    settings.token = null;
    user = null;
    try {
      await _secure.delete(key: 'token');
    } catch (_) {}
  }
}

class AuthScope extends InheritedNotifier<AuthStore> {
  const AuthScope({super.key, required AuthStore auth, required super.child})
    : super(notifier: auth);

  static AuthStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AuthScope>()!.notifier!;
}

extension AuthX on BuildContext {
  AuthStore get auth => AuthScope.of(this);
}
