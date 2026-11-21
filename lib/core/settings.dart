import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'i18n.dart';

/// Боевой сервер. Адрес можно сменить в «Настройках» приложения (для тестов — адрес компьютера).
const defaultBaseUrl = 'https://tjsafo.site';

/// Старые тестовые адреса (эмулятор/localhost) больше не используем.
String _initialBase(SharedPreferences p) {
  final v = p.getString('baseUrl');
  if (v == null || v.contains('10.0.2.2') || v.contains('localhost'))
    return defaultBaseUrl;
  return v;
}

class AppSettings extends ChangeNotifier {
  AppSettings._(this._prefs)
    : lang = _prefs.getString('lang') ?? 'tg',
      themeMode = ThemeMode.values.byName(_prefs.getString('theme') ?? 'dark'),
      baseUrl = _initialBase(_prefs),
      winter = _prefs.getBool('winter') ?? false;

  final SharedPreferences _prefs;
  String lang;
  ThemeMode themeMode;
  String baseUrl;

  /// Зимний режим (снег, ледяные цвета) — включается на сервере в админке; последнее значение запоминается.
  bool winter;

  /// Разделы, закрытые на обновление (hotels, cars …).
  Set<String> closedSections = const {};

  /// Токен входа (только в памяти; постоянно хранится в AuthStore).
  String? token;

  static Future<AppSettings> load() async =>
      AppSettings._(await SharedPreferences.getInstance());

  String t(String key, [Map<String, Object>? params]) => tr(lang, key, params);

  Future<void> setLang(String v) async {
    lang = v;
    await _prefs.setString('lang', v);
    notifyListeners();
  }

  Future<void> setTheme(ThemeMode v) async {
    themeMode = v;
    await _prefs.setString('theme', v.name);
    notifyListeners();
  }

  Future<void> setBaseUrl(String v) async {
    var s = v.trim();
    while (s.endsWith('/')) {
      s = s.substring(0, s.length - 1);
    }
    baseUrl = s.isEmpty ? defaultBaseUrl : s;
    await _prefs.setString('baseUrl', baseUrl);
    notifyListeners();
  }

  /// Настройки с сервера: зимний режим и закрытые разделы. Без интернета остаются прежние.
  Future<void> refreshConfig() async {
    try {
      final r = await http
          .get(Uri.parse('$baseUrl/api/mobile/config'))
          .timeout(const Duration(seconds: 10));
      if (r.statusCode != 200) return;
      final j = jsonDecode(utf8.decode(r.bodyBytes)) as Map;
      final w = j['winter'] == true;
      final closed = {for (final s in (j['closed'] as List? ?? [])) '$s'};
      if (w != winter || closed.length != closedSections.length || !closed.containsAll(closedSections)) {
        winter = w;
        closedSections = closed;
        await _prefs.setBool('winter', w);
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Иконка «Сафо» для экранов приложения (зимой — зимняя).
  String get iconAsset => winter ? 'assets/icon_winter.png' : 'assets/icon.png';

  /// Для кэша списка мест
  String? get cachedPlaces => _prefs.getString('places_cache');
  Future<void> cachePlaces(String json) =>
      _prefs.setString('places_cache', json);

  /// Для кэша заданий тозакунанда (чтобы видеть их без интернета)
  String? get cachedCleaner => _prefs.getString('cleaner_cache');
  Future<void> cacheCleaner(String json) =>
      _prefs.setString('cleaner_cache', json);
}

/// Доступ к настройкам из любого места дерева виджетов.
class AppScope extends InheritedNotifier<AppSettings> {
  const AppScope({
    super.key,
    required AppSettings settings,
    required super.child,
  }) : super(notifier: settings);

  static AppSettings of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}

extension AppX on BuildContext {
  AppSettings get app => AppScope.of(this);
  String t(String key, [Map<String, Object>? params]) => app.t(key, params);
}
