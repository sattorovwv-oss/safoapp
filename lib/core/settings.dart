import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'i18n.dart';

/// Адрес сервера по умолчанию: для эмулятора Android `10.0.2.2` — это localhost компьютера.
/// Для боевой версии замените на https://ваш-домен (или поменяйте в «Настройках» приложения).
final String defaultBaseUrl = kIsWeb ? 'http://localhost:3000' : 'http://10.0.2.2:3000';

class AppSettings extends ChangeNotifier {
  AppSettings._(this._prefs)
      : lang = _prefs.getString('lang') ?? 'tg',
        themeMode = ThemeMode.values.byName(_prefs.getString('theme') ?? 'dark'),
        baseUrl = _prefs.getString('baseUrl') ?? defaultBaseUrl;

  final SharedPreferences _prefs;
  String lang;
  ThemeMode themeMode;
  String baseUrl;

  static Future<AppSettings> load() async => AppSettings._(await SharedPreferences.getInstance());

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

  /// Для кэша списка мест
  String? get cachedPlaces => _prefs.getString('places_cache');
  Future<void> cachePlaces(String json) => _prefs.setString('places_cache', json);
}

/// Доступ к настройкам из любого места дерева виджетов.
class AppScope extends InheritedNotifier<AppSettings> {
  const AppScope({super.key, required AppSettings settings, required super.child}) : super(notifier: settings);

  static AppSettings of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}

extension AppX on BuildContext {
  AppSettings get app => AppScope.of(this);
  String t(String key, [Map<String, Object>? params]) => app.t(key, params);
}
