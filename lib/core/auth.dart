import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
    notifyListeners();
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
